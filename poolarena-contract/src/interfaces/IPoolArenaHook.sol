// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@fhenix/FHE.sol";

interface IPoolArenaHook {
    /// @notice Position tracking data for tournament participants
    struct PositionData {
        uint256 tournamentId;
        address participant;
        uint256 tokenId;
        uint128 liquidityAtStart;
        uint256 feesEarnedAtStart;
        uint256 token0AmountAtStart;
        uint256 token1AmountAtStart;
        uint256 lastUpdateTime;
        bool isActive;
    }

    /// @notice Performance metrics (encrypted)
    struct PerformanceMetrics {
        euint64 pnlPercentage;    // Encrypted PnL percentage
        euint64 feesEarned;       // Encrypted fees earned
        euint64 totalScore;       // Encrypted combined performance score
        uint256 lastCalculated;   // Timestamp of last calculation
    }

    /// @notice Events
    event PositionRegistered(
        uint256 indexed tournamentId,
        address indexed participant,
        uint256 indexed tokenId,
        uint128 initialLiquidity
    );

    event PositionUpdated(
        uint256 indexed tournamentId,
        address indexed participant,
        uint256 indexed tokenId,
        euint64 newScore
    );

    event PerformanceCalculated(
        uint256 indexed tournamentId,
        address indexed participant,
        euint64 pnlPercentage,
        euint64 feesEarned
    );

    /// @notice Register a position for tournament tracking
    function registerPosition(
        uint256 tournamentId,
        address participant,
        uint256 tokenId
    ) external;

    /// @notice Update performance metrics for a participant
    function updatePerformance(
        uint256 tournamentId,
        address participant
    ) external returns (euint64 newScore);

    /// @notice Get encrypted performance metrics
    function getPerformanceMetrics(
        uint256 tournamentId,
        address participant
    ) external view returns (PerformanceMetrics memory);

    /// @notice Check if position is registered for tournament
    function isPositionRegistered(
        uint256 tournamentId,
        uint256 tokenId
    ) external view returns (bool);

    /// @notice Get position data
    function getPositionData(
        uint256 tournamentId,
        address participant
    ) external view returns (PositionData memory);

    /// @notice Calculate current performance (view function)
    function calculateCurrentPerformance(
        uint256 tournamentId,
        address participant
    ) external view returns (euint64 currentScore);
}
