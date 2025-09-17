// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@fhenix/FHE.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./interfaces/IPoolArena.sol";
import "./interfaces/IPoolArenaHook.sol";
import "./libraries/TournamentLib.sol";

/// @title PoolArena - Private LP Tournament Platform
/// @notice A competitive DeFi tournament platform using Fhenix FHE for privacy
contract PoolArena is IPoolArena, ReentrancyGuard, Ownable, IERC721Receiver {
    using TournamentLib for *;

    /// @notice Tournament storage with internal mappings
    struct TournamentStorage {
        uint256 id;
        address creator;
        TournamentConfig config;
        TournamentState state;
        uint256 startTime;
        uint256 endTime;
        uint256 prizePool;
        uint256 participantCount;
        mapping(address => bool) isParticipant;
        mapping(address => uint256) participantIndex;
        address[] participants;
        mapping(address => euint64) encryptedScores;
        mapping(address => uint256) tokenIds;
        mapping(address => ParticipantData) participantData;
        bool resultsDecrypted;
        address[3] winners;
        uint256[3] finalScores;
        mapping(address => bool) hasWithdrawn;
    }

    /// @notice State variables
    uint256 public tournamentCounter;
    address public treasury;
    address public immutable hookContract;
    IERC721 public immutable lpNFT;
    
    /// @notice FHE encrypted constants for calculations
    euint64 private ENCRYPTED_ZERO;
    euint64 private ENCRYPTED_HUNDRED;

    /// @notice Tournament storage mapping
    mapping(uint256 => TournamentStorage) private tournaments;
    
    /// @notice User participation tracking
    mapping(address => uint256[]) public userTournaments;
    mapping(address => mapping(uint256 => bool)) public userParticipation;

    /// @notice Modifiers
    modifier onlyValidTournament(uint256 tournamentId) {
        require(tournamentId > 0 && tournamentId <= tournamentCounter, "Invalid tournament");
        _;
    }

    modifier onlyTournamentCreator(uint256 tournamentId) {
        require(tournaments[tournamentId].creator == msg.sender, "Not tournament creator");
        _;
    }

    modifier onlyParticipant(uint256 tournamentId) {
        require(tournaments[tournamentId].isParticipant[msg.sender], "Not a participant");
        _;
    }

    /// @notice Constructor
    /// @param _hookContract Address of the PoolArenaHook contract
    /// @param _lpNFT Address of the Uniswap v4 LP NFT contract
    /// @param _treasury Address for collecting treasury fees
    constructor(
        address _hookContract,
        address _lpNFT,
        address _treasury
    ) Ownable(msg.sender) {
        require(_hookContract != address(0), "Invalid hook contract");
        require(_lpNFT != address(0), "Invalid LP NFT contract");
        require(_treasury != address(0), "Invalid treasury address");
        
        hookContract = _hookContract;
        lpNFT = IERC721(_lpNFT);
        treasury = _treasury;

        // Initialize FHE constants
        ENCRYPTED_ZERO = FHE.asEuint64(0);
        ENCRYPTED_HUNDRED = FHE.asEuint64(100);
        
        // Grant contract access to constants
        FHE.allowThis(ENCRYPTED_ZERO);
        FHE.allowThis(ENCRYPTED_HUNDRED);
    }

    /// @inheritdoc IPoolArena
    function createTournament(
        TournamentConfig calldata config
    ) external override returns (uint256 tournamentId) {
        // Validate configuration
        TournamentLib.validateTournamentConfig(
            config.entryFee,
            config.maxParticipants,
            config.duration,
            config.treasuryFee,
            config.prizeDistribution
        );

        tournamentCounter++;
        tournamentId = tournamentCounter;

        TournamentStorage storage tournament = tournaments[tournamentId];
        tournament.id = tournamentId;
        tournament.creator = msg.sender;
        tournament.config = config;
        tournament.state = TournamentState.CREATED;
        tournament.startTime = 0;
        tournament.endTime = 0;
        tournament.prizePool = 0;
        tournament.participantCount = 0;
        tournament.resultsDecrypted = false;

        emit TournamentCreated(
            tournamentId,
            msg.sender,
            config.entryFee,
            config.maxParticipants,
            config.duration
        );
    }

    /// @inheritdoc IPoolArena
    function joinTournament(
        uint256 tournamentId,
        uint256 tokenId
    ) external payable override onlyValidTournament(tournamentId) nonReentrant {
        TournamentStorage storage tournament = tournaments[tournamentId];
        
        require(tournament.state == TournamentState.CREATED, "Tournament not open for joining");
        require(!tournament.isParticipant[msg.sender], "Already joined");
        require(tournament.participantCount < tournament.config.maxParticipants, "Tournament full");
        require(msg.value == tournament.config.entryFee, "Incorrect entry fee");

        // Verify LP NFT ownership and transfer
        require(lpNFT.ownerOf(tokenId) == msg.sender, "Not LP NFT owner");
        lpNFT.safeTransferFrom(msg.sender, address(this), tokenId);

        // Add participant
        tournament.isParticipant[msg.sender] = true;
        tournament.participantIndex[msg.sender] = tournament.participantCount;
        tournament.participants.push(msg.sender);
        tournament.tokenIds[msg.sender] = tokenId;
        tournament.participantCount++;

        // Initialize encrypted score
        euint64 initialScore = FHE.asEuint64(0);
        tournament.encryptedScores[msg.sender] = initialScore;
        
        // Grant access to encrypted score
        FHE.allowThis(initialScore);
        FHE.allow(initialScore, msg.sender);

        // Initialize participant data
        tournament.participantData[msg.sender] = ParticipantData({
            participant: msg.sender,
            tokenId: tokenId,
            encryptedPnL: ENCRYPTED_ZERO,
            encryptedFees: ENCRYPTED_ZERO,
            totalScore: initialScore,
            initialValue: 0, // Will be set when tournament starts
            active: true
        });

        // Handle entry fee distribution
        (uint256 treasuryAmount, uint256 prizeAmount) = TournamentLib.calculateFeeDistribution(
            tournament.config.entryFee,
            tournament.config.treasuryFee
        );
        
        tournament.prizePool += prizeAmount;
        
        if (treasuryAmount > 0) {
            payable(treasury).transfer(treasuryAmount);
        }

        // Track user participation
        userTournaments[msg.sender].push(tournamentId);
        userParticipation[msg.sender][tournamentId] = true;

        emit ParticipantJoined(tournamentId, msg.sender, tokenId);

        // Auto-start if max participants reached
        if (tournament.participantCount == tournament.config.maxParticipants) {
            _startTournament(tournamentId);
        }
    }

    /// @inheritdoc IPoolArena
    function startTournament(
        uint256 tournamentId
    ) external override onlyValidTournament(tournamentId) onlyTournamentCreator(tournamentId) {
        require(tournaments[tournamentId].participantCount >= 3, "Need at least 3 participants");
        _startTournament(tournamentId);
    }

    /// @notice Internal function to start a tournament
    function _startTournament(uint256 tournamentId) internal {
        TournamentStorage storage tournament = tournaments[tournamentId];
        require(tournament.state == TournamentState.CREATED, "Tournament already started");

        tournament.state = TournamentState.ACTIVE;
        tournament.startTime = block.timestamp;
        tournament.endTime = block.timestamp + tournament.config.duration;

        // Register positions with hook contract
        for (uint i = 0; i < tournament.participantCount; i++) {
            address participant = tournament.participants[i];
            uint256 tokenId = tournament.tokenIds[participant];
            
            IPoolArenaHook(hookContract).registerPosition(
                tournamentId,
                participant,
                tokenId
            );
        }

        emit TournamentStarted(tournamentId, tournament.startTime);
    }

    /// @inheritdoc IPoolArena
    function endTournament(
        uint256 tournamentId
    ) external override onlyValidTournament(tournamentId) {
        TournamentStorage storage tournament = tournaments[tournamentId];
        require(tournament.state == TournamentState.ACTIVE, "Tournament not active");
        require(block.timestamp >= tournament.endTime, "Tournament not finished");

        tournament.state = TournamentState.ENDED;

        // Update final scores from hook
        for (uint i = 0; i < tournament.participantCount; i++) {
            address participant = tournament.participants[i];
            euint64 finalScore = IPoolArenaHook(hookContract).updatePerformance(
                tournamentId,
                participant
            );
            
            tournament.encryptedScores[participant] = finalScore;
            tournament.participantData[participant].totalScore = finalScore;
            
            // Maintain access permissions
            FHE.allowThis(finalScore);
            FHE.allow(finalScore, participant);
        }

        emit TournamentEnded(tournamentId, block.timestamp);
    }

    /// @inheritdoc IPoolArena
    function requestDecryption(
        uint256 tournamentId
    ) external override onlyValidTournament(tournamentId) {
        TournamentStorage storage tournament = tournaments[tournamentId];
        require(tournament.state == TournamentState.ENDED, "Tournament not ended");
        require(!tournament.resultsDecrypted, "Results already decrypted");

        // Request decryption of all participant scores
        for (uint i = 0; i < tournament.participantCount; i++) {
            address participant = tournament.participants[i];
            euint64 score = tournament.encryptedScores[participant];
            FHE.decrypt(score);
        }

        emit DecryptionRequested(tournamentId);
    }

    /// @inheritdoc IPoolArena
    function finalizeTournament(
        uint256 tournamentId
    ) external override onlyValidTournament(tournamentId) nonReentrant {
        TournamentStorage storage tournament = tournaments[tournamentId];
        require(tournament.state == TournamentState.ENDED, "Tournament not ended");
        require(!tournament.resultsDecrypted, "Already finalized");

        // Get decrypted scores and determine winners
        uint256[] memory decryptedScores = new uint256[](tournament.participantCount);
        bool allDecrypted = true;

        for (uint i = 0; i < tournament.participantCount; i++) {
            address participant = tournament.participants[i];
            euint64 encryptedScore = tournament.encryptedScores[participant];
            
            (uint64 score, bool decrypted) = FHE.getDecryptResultSafe(encryptedScore);
            if (!decrypted) {
                allDecrypted = false;
                break;
            }
            decryptedScores[i] = uint256(score);
        }

        require(allDecrypted, "Decryption not completed");

        // Find top 3 winners
        uint256[3] memory topScores;
        address[3] memory topParticipants;
        
        for (uint i = 0; i < tournament.participantCount; i++) {
            address participant = tournament.participants[i];
            uint256 score = decryptedScores[i];
            
            // Insert in top 3 if score is high enough
            for (uint j = 0; j < 3; j++) {
                if (score > topScores[j]) {
                    // Shift lower scores down
                    for (uint k = 2; k > j; k--) {
                        topScores[k] = topScores[k-1];
                        topParticipants[k] = topParticipants[k-1];
                    }
                    topScores[j] = score;
                    topParticipants[j] = participant;
                    break;
                }
            }
        }

        tournament.winners = topParticipants;
        tournament.finalScores = topScores;
        tournament.resultsDecrypted = true;
        tournament.state = TournamentState.FINALIZED;

        // Calculate and distribute prizes
        uint256[3] memory prizes = TournamentLib.calculatePrizes(
            tournament.prizePool,
            tournament.config.prizeDistribution
        );

        for (uint i = 0; i < 3; i++) {
            if (topParticipants[i] != address(0) && prizes[i] > 0) {
                payable(topParticipants[i]).transfer(prizes[i]);
                emit RewardsDistributed(tournamentId, topParticipants[i], prizes[i]);
            }
        }

        emit TournamentFinalized(tournamentId, topParticipants, prizes);
    }

    /// @inheritdoc IPoolArena
    function withdrawLP(
        uint256 tournamentId
    ) external override onlyValidTournament(tournamentId) onlyParticipant(tournamentId) {
        TournamentStorage storage tournament = tournaments[tournamentId];
        require(
            tournament.state == TournamentState.FINALIZED || 
            tournament.state == TournamentState.ENDED,
            "Tournament not finished"
        );
        require(!tournament.hasWithdrawn[msg.sender], "Already withdrawn");

        tournament.hasWithdrawn[msg.sender] = true;
        uint256 tokenId = tournament.tokenIds[msg.sender];
        
        lpNFT.safeTransferFrom(address(this), msg.sender, tokenId);
    }

    /// @inheritdoc IPoolArena
    function getTournament(
        uint256 tournamentId
    ) external view override onlyValidTournament(tournamentId) returns (
        uint256 id,
        address creator,
        TournamentConfig memory config,
        TournamentState state,
        uint256 startTime,
        uint256 endTime,
        uint256 prizePool,
        uint256 participantCount
    ) {
        TournamentStorage storage tournament = tournaments[tournamentId];
        return (
            tournament.id,
            tournament.creator,
            tournament.config,
            tournament.state,
            tournament.startTime,
            tournament.endTime,
            tournament.prizePool,
            tournament.participantCount
        );
    }

    /// @inheritdoc IPoolArena
    function getParticipantData(
        uint256 tournamentId,
        address participant
    ) external view override onlyValidTournament(tournamentId) returns (ParticipantData memory) {
        return tournaments[tournamentId].participantData[participant];
    }

    /// @inheritdoc IPoolArena
    function isParticipant(
        uint256 tournamentId,
        address participant
    ) external view override onlyValidTournament(tournamentId) returns (bool) {
        return tournaments[tournamentId].isParticipant[participant];
    }

    /// @notice Get tournament winners (after finalization)
    function getTournamentWinners(
        uint256 tournamentId
    ) external view onlyValidTournament(tournamentId) returns (
        address[3] memory winners,
        uint256[3] memory scores
    ) {
        TournamentStorage storage tournament = tournaments[tournamentId];
        require(tournament.resultsDecrypted, "Results not decrypted");
        return (tournament.winners, tournament.finalScores);
    }

    /// @notice Get all tournaments for a user
    function getUserTournaments(address user) external view returns (uint256[] memory) {
        return userTournaments[user];
    }

    /// @notice Get current tournament count
    function getTournamentCount() external view returns (uint256) {
        return tournamentCounter;
    }

    /// @notice Update treasury address (owner only)
    function updateTreasury(address newTreasury) external onlyOwner {
        require(newTreasury != address(0), "Invalid treasury address");
        treasury = newTreasury;
    }

    /// @notice Emergency withdraw (owner only)
    function emergencyWithdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /// @notice Required for receiving NFTs
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    /// @notice Receive function to accept ETH
    receive() external payable {}
}
