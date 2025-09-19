// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {BaseHook} from "v4-periphery/src/utils/BaseHook.sol";
import {Hooks} from "v4-core/libraries/Hooks.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "v4-core/types/PoolId.sol";
import {BalanceDelta} from "v4-core/types/BalanceDelta.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "v4-core/types/BeforeSwapDelta.sol";
import {Currency} from "v4-core/types/Currency.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IPyth} from "@pythnetwork/pyth-sdk-solidity/IPyth.sol";
import {PythStructs} from "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";
import {PoolArenaHook} from "./PoolArenaHook.sol";

interface IPoolArena {
    function checkLiquidityModification(PoolId poolId, address sender) external view;
    function trackSwapFees(PoolId poolId, BalanceDelta delta) external;
}

/**
 * @title PoolArena
 * @dev Main tournament contract for LP trading competitions
 */
contract PoolArena is IERC721Receiver, ReentrancyGuard, Ownable, IPoolArena {
    using PoolIdLibrary for PoolKey;

    // Pyth oracle for price feeds
    IPyth public immutable pyth;
    
    // Uniswap V4 Position Manager (ERC721 for LP NFTs)
    IERC721 public immutable positionManager;
    
    // Our custom hook contract
    PoolArenaHook public immutable hook;
    
    enum TournamentType { DAILY, WEEKLY }
    enum TournamentStatus { PENDING, ACTIVE, FINISHED, CANCELLED }
    
    struct Tournament {
        uint256 id;
        TournamentType tournamentType;
        TournamentStatus status;
        uint256 entryFee;
        uint256 maxParticipants;
        uint256 currentParticipants;
        uint256 startTime;
        uint256 endTime;
        uint256 prizePool;
        address[] participants;
        mapping(address => uint256) participantTokenIds;
        mapping(address => uint256) initialFeeSnapshot;
        mapping(address => uint256) finalFeeSnapshot;
        address[3] winners;
        uint256[3] winnerReturns;
    }
    
    uint256 public nextTournamentId = 1;
    mapping(uint256 => Tournament) public tournaments;
    mapping(address => uint256) public activeParticipations; // user -> tournament ID
    mapping(PoolId => mapping(address => bool)) public lockedPositions;
    
    // Platform fee (1%)
    uint256 public constant PLATFORM_FEE_BPS = 100; // 1%
    uint256 public constant BASIS_POINTS = 10000;
    
    // Events
    event TournamentCreated(uint256 indexed tournamentId, TournamentType tournamentType, uint256 entryFee, uint256 maxParticipants);
    event TournamentJoined(uint256 indexed tournamentId, address indexed participant, uint256 tokenId);
    event TournamentStarted(uint256 indexed tournamentId, uint256 startTime);
    event TournamentFinished(uint256 indexed tournamentId, address[3] winners, uint256[3] prizes);
    event FeesTracked(uint256 indexed tournamentId, address indexed participant, uint256 fees);
    
    constructor(
        address _positionManager,
        address _pyth,
        address _hookAddress
    ) Ownable(msg.sender) {
        positionManager = IERC721(_positionManager);
        pyth = IPyth(_pyth);
        hook = PoolArenaHook(_hookAddress);
    }
    
    /**
     * @dev Admin creates a new tournament
     */
    function createTournament(
        TournamentType _type,
        uint256 _entryFee,
        uint256 _maxParticipants
    ) external onlyOwner {
        require(_maxParticipants >= 2 && _maxParticipants <= 12, "Invalid participant count");
        require(_entryFee > 0, "Entry fee must be positive");
        
        Tournament storage tournament = tournaments[nextTournamentId];
        tournament.id = nextTournamentId;
        tournament.tournamentType = _type;
        tournament.status = TournamentStatus.PENDING;
        tournament.entryFee = _entryFee;
        tournament.maxParticipants = _maxParticipants;
        tournament.currentParticipants = 0;
        
        emit TournamentCreated(nextTournamentId, _type, _entryFee, _maxParticipants);
        nextTournamentId++;
    }
    
    /**
     * @dev User joins tournament with their LP NFT
     */
    function joinTournament(uint256 _tournamentId, uint256 _tokenId) external payable nonReentrant {
        Tournament storage tournament = tournaments[_tournamentId];
        
        require(tournament.status == TournamentStatus.PENDING, "Tournament not accepting participants");
        require(tournament.currentParticipants < tournament.maxParticipants, "Tournament full");
        require(msg.value == tournament.entryFee, "Incorrect entry fee");
        require(activeParticipations[msg.sender] == 0, "Already in active tournament");
        
        // Transfer LP NFT to contract
        positionManager.safeTransferFrom(msg.sender, address(this), _tokenId);
        
        // Record participation
        tournament.participants.push(msg.sender);
        tournament.participantTokenIds[msg.sender] = _tokenId;
        tournament.currentParticipants++;
        tournament.prizePool += (msg.value * (BASIS_POINTS - PLATFORM_FEE_BPS)) / BASIS_POINTS;
        
        activeParticipations[msg.sender] = _tournamentId;
        
        emit TournamentJoined(_tournamentId, msg.sender, _tokenId);
        
        // Auto-start if tournament is full
        if (tournament.currentParticipants == tournament.maxParticipants) {
            _startTournament(_tournamentId);
        }
    }
    
    /**
     * @dev Start tournament (can be called by admin or auto-triggered when full)
     */
    function startTournament(uint256 _tournamentId) external onlyOwner {
        Tournament storage tournament = tournaments[_tournamentId];
        require(tournament.status == TournamentStatus.PENDING, "Tournament not pending");
        require(tournament.currentParticipants >= 2, "Need at least 2 participants");
        
        _startTournament(_tournamentId);
    }
    
    function _startTournament(uint256 _tournamentId) internal {
        Tournament storage tournament = tournaments[_tournamentId];
        
        tournament.status = TournamentStatus.ACTIVE;
        tournament.startTime = block.timestamp;
        
        // Set end time based on tournament type
        if (tournament.tournamentType == TournamentType.DAILY) {
            tournament.endTime = block.timestamp + 1 days;
        } else {
            tournament.endTime = block.timestamp + 7 days;
        }
        
        // Lock all participants' positions and take fee snapshots
        for (uint256 i = 0; i < tournament.participants.length; i++) {
            address participant = tournament.participants[i];
            uint256 tokenId = tournament.participantTokenIds[participant];
            
            // Take initial fee snapshot (simplified - in practice you'd get this from position manager)
            tournament.initialFeeSnapshot[participant] = _getPositionFees(tokenId);
            
            // Mark position as locked (prevents modifications via hook)
            _lockPosition(participant, tokenId);
        }
        
        emit TournamentStarted(_tournamentId, tournament.startTime);
    }
    
    /**
     * @dev Finish tournament and distribute prizes
     */
    function finishTournament(uint256 _tournamentId) external {
        Tournament storage tournament = tournaments[_tournamentId];
        
        require(tournament.status == TournamentStatus.ACTIVE, "Tournament not active");
        require(block.timestamp >= tournament.endTime, "Tournament not ended");
        
        // Take final fee snapshots and calculate returns
        address[] memory participants = tournament.participants;
        uint256[] memory returnValues = new uint256[](participants.length);
        
        for (uint256 i = 0; i < participants.length; i++) {
            address participant = participants[i];
            uint256 tokenId = tournament.participantTokenIds[participant];
            
            uint256 finalFees = _getPositionFees(tokenId);
            uint256 initialFees = tournament.initialFeeSnapshot[participant];
            
            // Calculate percentage return (scaled by 1e18 for precision)
            uint256 initialValue = _getPositionValue(tokenId);
            if (initialValue > 0 && finalFees > initialFees) {
                returnValues[i] = ((finalFees - initialFees) * 1e18) / initialValue;
            }
            
            tournament.finalFeeSnapshot[participant] = finalFees;
            
            // Unlock and return NFT
            _unlockPosition(participant, tokenId);
            positionManager.safeTransferFrom(address(this), participant, tokenId);
            activeParticipations[participant] = 0;
        }
        
        // Determine winners (top 3 returns)
        _determineWinners(_tournamentId, participants, returnValues);
        
        // Distribute prizes
        _distributePrizes(_tournamentId);
        
        tournament.status = TournamentStatus.FINISHED;
        
        emit TournamentFinished(_tournamentId, tournament.winners, [
            (tournament.prizePool * 50) / 100, // 50% to 1st
            (tournament.prizePool * 30) / 100, // 30% to 2nd  
            (tournament.prizePool * 20) / 100  // 20% to 3rd
        ]);
    }
    
    function _determineWinners(
        uint256 _tournamentId,
        address[] memory participants,
        uint256[] memory returnValues
    ) internal {
        Tournament storage tournament = tournaments[_tournamentId];
        
        // Simple bubble sort to find top 3 (fine for small arrays)
        for (uint256 i = 0; i < participants.length - 1; i++) {
            for (uint256 j = 0; j < participants.length - i - 1; j++) {
                if (returnValues[j] < returnValues[j + 1]) {
                    // Swap returns
                    uint256 tempReturn = returnValues[j];
                    returnValues[j] = returnValues[j + 1];
                    returnValues[j + 1] = tempReturn;

                    // Swap participants
                    address tempParticipant = participants[j];
                    participants[j] = participants[j + 1];
                    participants[j + 1] = tempParticipant;
                }
            }
        }
        
        // Set winners (top 3)
        tournament.winners[0] = participants[0];
        tournament.winners[1] = participants[1];
        tournament.winners[2] = participants[2];
        tournament.winnerReturns[0] = returnValues[0];
        tournament.winnerReturns[1] = returnValues[1];
        tournament.winnerReturns[2] = returnValues[2];
    }
    
    function _distributePrizes(uint256 _tournamentId) internal {
        Tournament storage tournament = tournaments[_tournamentId];
        uint256 prizePool = tournament.prizePool;
        
        // 50% to 1st place
        payable(tournament.winners[0]).transfer((prizePool * 50) / 100);
        
        // 30% to 2nd place  
        payable(tournament.winners[1]).transfer((prizePool * 30) / 100);
        
        // 20% to 3rd place
        payable(tournament.winners[2]).transfer((prizePool * 20) / 100);
    }
    
    function _lockPosition(address participant, uint256 tokenId) internal {
        // Mark position as locked (this would interact with the position data)
        // For now, we'll track this in our mapping
        // In practice, you'd need to get the pool ID from the position
        lockedPositions[PoolId.wrap(bytes32(tokenId))][participant] = true;
    }
    
    function _unlockPosition(address participant, uint256 tokenId) internal {
        lockedPositions[PoolId.wrap(bytes32(tokenId))][participant] = false;
    }
    
    function _getPositionFees(uint256 tokenId) internal view returns (uint256) {
        // This would interact with Uniswap V4 Position Manager to get accumulated fees
        // Simplified for demo - in practice you'd call the position manager
        return tokenId * 1000; // Mock value
    }
    
    function _getPositionValue(uint256 tokenId) internal view returns (uint256) {
        // This would calculate position value using Pyth price feeds
        // Simplified for demo
        return tokenId * 1000000; // Mock value
    }
    
    /**
     * @dev Hook interface - check if liquidity modification is allowed
     */
    function checkLiquidityModification(PoolId poolId, address sender) external view override {
        if (lockedPositions[poolId][sender]) {
            revert("Position locked in tournament");
        }
    }
    
    /**
     * @dev Hook interface - track swap fees
     */
    function trackSwapFees(PoolId poolId, BalanceDelta delta) external override {
        // Track fees generated by swaps in this pool
        // This would update fee tracking for active tournaments
        // Simplified implementation
    }
    
    /**
     * @dev Emergency functions
     */
    function cancelTournament(uint256 _tournamentId) external onlyOwner {
        Tournament storage tournament = tournaments[_tournamentId];
        require(tournament.status == TournamentStatus.PENDING, "Can only cancel pending tournaments");
        
        // Refund all participants
        for (uint256 i = 0; i < tournament.participants.length; i++) {
            address participant = tournament.participants[i];
            uint256 tokenId = tournament.participantTokenIds[participant];
            
            positionManager.safeTransferFrom(address(this), participant, tokenId);
            payable(participant).transfer(tournament.entryFee);
            activeParticipations[participant] = 0;
        }
        
        tournament.status = TournamentStatus.CANCELLED;
    }
    
    function withdrawPlatformFees() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
    
    // View functions
    function getTournament(uint256 _tournamentId) external view returns (
        uint256 id,
        TournamentType tournamentType,
        TournamentStatus status,
        uint256 entryFee,
        uint256 maxParticipants,
        uint256 currentParticipants,
        uint256 startTime,
        uint256 endTime,
        uint256 prizePool
    ) {
        Tournament storage tournament = tournaments[_tournamentId];
        return (
            tournament.id,
            tournament.tournamentType,
            tournament.status,
            tournament.entryFee,
            tournament.maxParticipants,
            tournament.currentParticipants,
            tournament.startTime,
            tournament.endTime,
            tournament.prizePool
        );
    }
    
    function getTournamentParticipants(uint256 _tournamentId) external view returns (address[] memory) {
        return tournaments[_tournamentId].participants;
    }
    
    function getTournamentWinners(uint256 _tournamentId) external view returns (
        address[3] memory winners,
        uint256[3] memory returnValues
    ) {
        Tournament storage tournament = tournaments[_tournamentId];
        return (tournament.winners, tournament.winnerReturns);
    }
    
    // Required for receiving NFTs
    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
    
    // Fallback to receive ETH
    receive() external payable {}
}
