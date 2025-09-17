// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@uniswap/v4-core/src/interfaces/IHooks.sol";
import "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import "@uniswap/v4-core/src/types/PoolKey.sol";
import "@uniswap/v4-core/src/types/BalanceDelta.sol";
import "@uniswap/v4-core/src/types/BeforeSwapDelta.sol";
import "@uniswap/v4-core/src/libraries/Hooks.sol";
import "@uniswap/v4-core/src/types/PoolOperation.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../src/interfaces/IPoolArenaHook.sol";

/// @title MockPoolArenaHook - Testing version that mocks FHE operations
/// @notice Hook that simulates encrypted operations for testing without requiring FHE infrastructure
contract MockPoolArenaHook is IHooks, IPoolArenaHook, Ownable {
    
    /// @notice Pool manager instance
    IPoolManager public immutable poolManager;
    
    /// @notice Authorized PoolArena contract
    address public poolArenaContract;

    /// @notice Position tracking storage for tournament participants
    mapping(uint256 => mapping(address => PositionData)) private positionData;
    mapping(uint256 => mapping(address => PerformanceMetrics)) private performanceMetrics;
    mapping(uint256 => mapping(uint256 => bool)) private registeredTokens;
    
    /// @notice Tournament participant tracking
    mapping(uint256 => address[]) public tournamentParticipants;
    mapping(uint256 => mapping(address => bool)) public isRegisteredParticipant;
    
    /// @notice Position snapshots for PnL calculation
    mapping(uint256 => mapping(address => PositionSnapshot)) private positionSnapshots;
    
    /// @notice Fee collection tracking per position
    mapping(uint256 => mapping(address => uint256)) private accumulatedFees;

    /// @notice Position snapshot data for accurate tracking
    struct PositionSnapshot {
        uint128 initialLiquidity;
        uint256 initialToken0Balance;
        uint256 initialToken1Balance;
        uint256 initialFeesCollected0;
        uint256 initialFeesCollected1;
        uint160 initialSqrtPriceX96;
        int24 initialTick;
        uint256 snapshotTime;
    }

    /// @notice Pool manager access modifier
    modifier onlyPoolManager() {
        require(msg.sender == address(poolManager), "Not pool manager");
        _;
    }

    /// @notice Constructor
    constructor(IPoolManager _poolManager) Ownable(msg.sender) {
        poolManager = _poolManager;
    }

    /// @notice Hook permissions - specify which hooks this contract implements
    function getHookPermissions() public pure returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: false,
            beforeAddLiquidity: false,
            afterAddLiquidity: false,
            beforeRemoveLiquidity: false,
            afterRemoveLiquidity: false,
            beforeSwap: false,
            afterSwap: true,              // Track fees earned from swaps
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: false,
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }

    /// @notice Set the authorized PoolArena contract
    function setPoolArenaContract(address _poolArenaContract) external onlyOwner {
        require(_poolArenaContract != address(0), "Invalid contract address");
        poolArenaContract = _poolArenaContract;
    }

    /// @notice Modifier to restrict access to PoolArena contract
    modifier onlyPoolArena() {
        require(msg.sender == poolArenaContract, "Not authorized");
        _;
    }

    /// @inheritdoc IPoolArenaHook
    function registerPosition(
        uint256 tournamentId,
        address participant,
        uint256 tokenId
    ) external override onlyPoolArena {
        require(!isRegisteredParticipant[tournamentId][participant], "Already registered");
        
        // Initialize position data
        positionData[tournamentId][participant] = PositionData({
            tournamentId: tournamentId,
            participant: participant,
            tokenId: tokenId,
            liquidityAtStart: 0, // Will be populated when we capture actual position
            feesEarnedAtStart: 0,
            token0AmountAtStart: 0,
            token1AmountAtStart: 0,
            lastUpdateTime: block.timestamp,
            isActive: true
        });

        // Initialize mock encrypted performance metrics using euint64.wrap for testing
        performanceMetrics[tournamentId][participant] = PerformanceMetrics({
            pnlPercentage: euint64.wrap(0), // Mock encrypted zero
            feesEarned: euint64.wrap(0),    // Mock encrypted zero
            totalScore: euint64.wrap(0),    // Mock encrypted zero
            lastCalculated: block.timestamp
        });

        // Initialize position snapshot
        positionSnapshots[tournamentId][participant] = PositionSnapshot({
            initialLiquidity: 0,
            initialToken0Balance: 0,
            initialToken1Balance: 0,
            initialFeesCollected0: 0,
            initialFeesCollected1: 0,
            initialSqrtPriceX96: 0,
            initialTick: 0,
            snapshotTime: block.timestamp
        });

        // Track registration
        tournamentParticipants[tournamentId].push(participant);
        isRegisteredParticipant[tournamentId][participant] = true;
        registeredTokens[tournamentId][tokenId] = true;
        accumulatedFees[tournamentId][participant] = 0;

        emit PositionRegistered(tournamentId, participant, tokenId, 0);
    }

    /// @inheritdoc IPoolArenaHook
    function updatePerformance(
        uint256 tournamentId,
        address participant
    ) external override onlyPoolArena returns (euint64 newScore) {
        require(isRegisteredParticipant[tournamentId][participant], "Participant not registered");
        
        PositionData storage position = positionData[tournamentId][participant];
        require(position.isActive, "Position not active");

        // Calculate mock performance score
        newScore = _calculateMockPerformance(tournamentId, participant);
        
        // Update performance metrics
        PerformanceMetrics storage metrics = performanceMetrics[tournamentId][participant];
        metrics.totalScore = newScore;
        metrics.lastCalculated = block.timestamp;

        emit PerformanceCalculated(
            tournamentId, 
            participant, 
            metrics.pnlPercentage, 
            metrics.feesEarned
        );

        return newScore;
    }

    /// @inheritdoc IPoolArenaHook
    function getPerformanceMetrics(
        uint256 tournamentId,
        address participant
    ) external view override returns (PerformanceMetrics memory) {
        return performanceMetrics[tournamentId][participant];
    }

    /// @inheritdoc IPoolArenaHook
    function calculateCurrentPerformance(
        uint256 tournamentId,
        address participant
    ) external view override returns (euint64 currentScore) {
        require(isRegisteredParticipant[tournamentId][participant], "Participant not registered");
        
        // Return the current total score from performance metrics
        PerformanceMetrics memory metrics = performanceMetrics[tournamentId][participant];
        return metrics.totalScore;
    }

    /// @notice Calculate mock performance metrics for a participant
    function _calculateMockPerformance(
        uint256 tournamentId,
        address participant
    ) private returns (euint64 totalScore) {
        PositionSnapshot storage snapshot = positionSnapshots[tournamentId][participant];
        
        // Mock performance calculation for testing
        uint256 mockCurrentLiquidity = snapshot.initialLiquidity + 50000; // Simulate growth
        uint256 mockFeesCollected = accumulatedFees[tournamentId][participant] + 1000;
        
        // Calculate mock PnL percentage
        uint256 liquidityGrowth = mockCurrentLiquidity > snapshot.initialLiquidity ? 
            ((mockCurrentLiquidity - snapshot.initialLiquidity) * 10000) / snapshot.initialLiquidity : 0;
        
        // Combined score: 70% PnL + 30% fees (simplified calculation)
        uint256 pnlScore = (liquidityGrowth * 7000) / 10000;
        uint256 feeScore = (mockFeesCollected * 3000) / 10000;
        uint256 score = pnlScore + feeScore;
        
        // Create mock encrypted values using euint64.wrap
        euint64 mockPnl = euint64.wrap(liquidityGrowth);
        euint64 mockFees = euint64.wrap(mockFeesCollected);
        totalScore = euint64.wrap(score);
        
        // Update performance metrics
        PerformanceMetrics storage metrics = performanceMetrics[tournamentId][participant];
        metrics.pnlPercentage = mockPnl;
        metrics.feesEarned = mockFees;
        
        return totalScore;
    }

    /// @notice Emergency update performance metrics (admin only)
    function emergencyUpdatePerformance(
        uint256 tournamentId,
        address participant,
        uint256 pnlPercentage,
        uint256 feesEarned
    ) external onlyOwner {
        require(isRegisteredParticipant[tournamentId][participant], "Participant not registered");
        
        // Create mock encrypted values
        euint64 encPnl = euint64.wrap(pnlPercentage);
        euint64 encFees = euint64.wrap(feesEarned);
        
        PerformanceMetrics storage metrics = performanceMetrics[tournamentId][participant];
        metrics.pnlPercentage = encPnl;
        metrics.feesEarned = encFees;
        metrics.lastCalculated = block.timestamp;
        
        // Update accumulated fees
        accumulatedFees[tournamentId][participant] = feesEarned;
    }

    /// @notice Capture position snapshot for tournament start
    function capturePositionSnapshot(
        uint256 tournamentId,
        address participant,
        PoolKey memory /* key */
    ) external {
        require(isRegisteredParticipant[tournamentId][participant], "Participant not registered");
        
        // Mock position data for testing
        uint128 mockLiquidity = 100000;
        uint256 mockToken0Balance = 1000000;
        uint256 mockToken1Balance = 1000000;
        
        PositionSnapshot storage snapshot = positionSnapshots[tournamentId][participant];
        snapshot.initialLiquidity = mockLiquidity;
        snapshot.initialToken0Balance = mockToken0Balance;
        snapshot.initialToken1Balance = mockToken1Balance;
        snapshot.snapshotTime = block.timestamp;
        
        // Update position data
        PositionData storage position = positionData[tournamentId][participant];
        position.liquidityAtStart = mockLiquidity;
        position.token0AmountAtStart = mockToken0Balance;
        position.token1AmountAtStart = mockToken1Balance;
    }

    /// @notice Get position snapshot
    function getPositionSnapshot(
        uint256 tournamentId,
        address participant
    ) external view returns (PositionSnapshot memory) {
        return positionSnapshots[tournamentId][participant];
    }

    /// @notice Get position data
    function getPositionData(
        uint256 tournamentId,
        address participant
    ) external view returns (PositionData memory) {
        return positionData[tournamentId][participant];
    }

    /// @notice Check if position is registered
    function isPositionRegistered(
        uint256 tournamentId,
        uint256 tokenId
    ) external view returns (bool) {
        return registeredTokens[tournamentId][tokenId];
    }

    /// @notice Get tournament participants
    function getTournamentParticipants(
        uint256 tournamentId
    ) external view returns (address[] memory) {
        return tournamentParticipants[tournamentId];
    }

    /// @notice Get accumulated fees for participant
    function getAccumulatedFees(
        uint256 tournamentId,
        address participant
    ) external view returns (uint256) {
        return accumulatedFees[tournamentId][participant];
    }

    /// @notice Deactivate position (admin only)
    function deactivatePosition(
        uint256 tournamentId,
        address participant
    ) external onlyOwner {
        require(isRegisteredParticipant[tournamentId][participant], "Participant not registered");
        positionData[tournamentId][participant].isActive = false;
    }

    // IHooks implementation - most functions revert since we only implement afterSwap
    function beforeInitialize(address, PoolKey calldata, uint160) external pure returns (bytes4) {
        revert("Not implemented");
    }

    function afterInitialize(address, PoolKey calldata, uint160, int24) external pure returns (bytes4) {
        revert("Not implemented");
    }

    function beforeAddLiquidity(address, PoolKey calldata, ModifyLiquidityParams calldata, bytes calldata) 
        external pure returns (bytes4) {
        revert("Not implemented");
    }

    function afterAddLiquidity(
        address, PoolKey calldata, ModifyLiquidityParams calldata, 
        BalanceDelta, BalanceDelta, bytes calldata
    ) external pure returns (bytes4, BalanceDelta) {
        revert("Not implemented");
    }

    function beforeRemoveLiquidity(address, PoolKey calldata, ModifyLiquidityParams calldata, bytes calldata) 
        external pure returns (bytes4) {
        revert("Not implemented");
    }

    function afterRemoveLiquidity(
        address, PoolKey calldata, ModifyLiquidityParams calldata, 
        BalanceDelta, BalanceDelta, bytes calldata
    ) external pure returns (bytes4, BalanceDelta) {
        revert("Not implemented");
    }

    function beforeSwap(address, PoolKey calldata, SwapParams calldata, bytes calldata) 
        external pure returns (bytes4, BeforeSwapDelta, uint24) {
        revert("Not implemented");
    }

    /// @notice afterSwap implementation - tracks swap fees for tournament participants
    function afterSwap(
        address /* sender */,
        PoolKey calldata /* key */,
        SwapParams calldata /* params */,
        BalanceDelta /* delta */,
        bytes calldata /* hookData */
    ) external view onlyPoolManager returns (bytes4, int128) {
        // Mock fee tracking logic for testing
        return (this.afterSwap.selector, 0);
    }

    function beforeDonate(address, PoolKey calldata, uint256, uint256, bytes calldata) 
        external pure returns (bytes4) {
        revert("Not implemented");
    }

    function afterDonate(address, PoolKey calldata, uint256, uint256, bytes calldata) 
        external pure returns (bytes4) {
        revert("Not implemented");
    }
}
