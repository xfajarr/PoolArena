// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@fhenix/FHE.sol";

interface IPoolArena {
    /// @notice Tournament state enumeration
    enum TournamentState {
        CREATED,      // Tournament created but not started
        ACTIVE,       // Tournament is running
        ENDED,        // Tournament ended, results can be revealed
        FINALIZED     // Tournament finalized, rewards distributed
    }

    /// @notice Tournament configuration structure
    struct TournamentConfig {
        uint256 entryFee;           // Entry fee in ETH (e.g., 0.002 ETH)
        uint256 maxParticipants;    // Maximum participants (default: 12)
        uint256 duration;           // Tournament duration in seconds
        uint256 treasuryFee;        // Fee percentage for treasury (1% = 100)
        uint256[3] prizeDistribution; // [70%, 20%, 10%] * 100 for precision
    }

    /// @notice Tournament information structure
    struct Tournament {
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
        mapping(address => euint64) encryptedScores; // FHE encrypted scores
        mapping(address => uint256) tokenIds; // LP NFT token IDs
        bool resultsDecrypted;
        address[3] winners; // Top 3 winners
        uint256[3] finalScores; // Decrypted final scores for winners
    }

    /// @notice Participant performance data
    struct ParticipantData {
        address participant;
        uint256 tokenId;        // LP NFT token ID
        euint64 encryptedPnL;   // Encrypted PnL percentage
        euint64 encryptedFees;  // Encrypted fees earned
        euint64 totalScore;     // Encrypted combined score
        uint256 initialValue;   // Initial LP position value (for reference)
        bool active;
    }

    /// @notice Events
    event TournamentCreated(
        uint256 indexed tournamentId,
        address indexed creator,
        uint256 entryFee,
        uint256 maxParticipants,
        uint256 duration
    );

    event ParticipantJoined(
        uint256 indexed tournamentId,
        address indexed participant,
        uint256 tokenId
    );

    event TournamentStarted(uint256 indexed tournamentId, uint256 startTime);

    event TournamentEnded(uint256 indexed tournamentId, uint256 endTime);

    event ScoreUpdated(
        uint256 indexed tournamentId,
        address indexed participant,
        euint64 newScore
    );

    event DecryptionRequested(uint256 indexed tournamentId);

    event TournamentFinalized(
        uint256 indexed tournamentId,
        address[3] winners,
        uint256[3] prizes
    );

    event RewardsDistributed(
        uint256 indexed tournamentId,
        address indexed winner,
        uint256 prize
    );

    /// @notice Create a new tournament
    function createTournament(TournamentConfig calldata config) external returns (uint256 tournamentId);

    /// @notice Join a tournament with LP NFT
    function joinTournament(uint256 tournamentId, uint256 tokenId) external payable;

    /// @notice Start a tournament (when max participants reached or creator starts)
    function startTournament(uint256 tournamentId) external;

    /// @notice End a tournament (after duration expires)
    function endTournament(uint256 tournamentId) external;

    /// @notice Request decryption of tournament results
    function requestDecryption(uint256 tournamentId) external;

    /// @notice Finalize tournament and distribute rewards
    function finalizeTournament(uint256 tournamentId) external;

    /// @notice Withdraw LP NFT after tournament
    function withdrawLP(uint256 tournamentId) external;

    /// @notice Get tournament information
    function getTournament(uint256 tournamentId) external view returns (
        uint256 id,
        address creator,
        TournamentConfig memory config,
        TournamentState state,
        uint256 startTime,
        uint256 endTime,
        uint256 prizePool,
        uint256 participantCount
    );

    /// @notice Get participant data
    function getParticipantData(uint256 tournamentId, address participant) 
        external view returns (ParticipantData memory);

    /// @notice Check if address is participant in tournament
    function isParticipant(uint256 tournamentId, address participant) external view returns (bool);
}
