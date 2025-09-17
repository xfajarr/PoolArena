// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@fhenix/FHE.sol";
import "@uniswap/v4-core/src/interfaces/IHooks.sol";
import "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import "@uniswap/v4-core/src/types/PoolKey.sol";
import "@uniswap/v4-core/src/types/BalanceDelta.sol";
import "@uniswap/v4-core/src/types/BeforeSwapDelta.sol";
import "@uniswap/v4-core/src/libraries/Hooks.sol";
import "@uniswap/v4-core/src/types/PoolOperation.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../src/interfaces/IPoolArenaHook.sol";
import "../src/libraries/TournamentLib.sol";

/// @title TestablePoolArenaHook - Testing version that bypasses address validation
/// @notice Hook that implements the same logic as PoolArenaHookV2 but for testing purposes
/// @dev This version doesn't inherit from BaseHook to avoid address validation issues in tests
contract TestablePoolArenaHook is IHooks, IPoolArenaHook, Ownable {
    using TournamentLib for *;

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

    /// @notice FHE Constants for calculations
    euint64 private ENCRYPTED_ZERO;
    euint64 private ENCRYPTED_HUNDRED;
    euint64 private ENCRYPTED_PRECISION;

    /// @notice Pool manager access modifier
    modifier onlyPoolManager() {
        require(msg.sender == address(poolManager), "Not pool manager");
        _;
    }

    /// @notice Constructor
    constructor(IPoolManager _poolManager) Ownable(msg.sender) {
        poolManager = _poolManager;

        // Initialize FHE constants
        ENCRYPTED_ZERO = FHE.asEuint64(0);
        ENCRYPTED_HUNDRED = FHE.asEuint64(100);
        ENCRYPTED_PRECISION = FHE.asEuint64(1e18);
        
        // Grant contract access to constants
        FHE.allowThis(ENCRYPTED_ZERO);
        FHE.allowThis(ENCRYPTED_HUNDRED);
        FHE.allowThis(ENCRYPTED_PRECISION);
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

        // Initialize encrypted performance metrics
        performanceMetrics[tournamentId][participant] = PerformanceMetrics({
            pnlPercentage: ENCRYPTED_ZERO,
            feesEarned: ENCRYPTED_ZERO,
            totalScore: ENCRYPTED_ZERO,
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

        // Calculate current performance using real position data
        newScore = _calculatePerformance(tournamentId, participant);
        
        // Update performance metrics
        PerformanceMetrics storage metrics = performanceMetrics[tournamentId][participant];
        metrics.totalScore = newScore;
        metrics.lastCalculated = block.timestamp;

        // Grant access permissions for FHE
        FHE.allowThis(newScore);
        FHE.allow(newScore, poolArenaContract);
        FHE.allow(newScore, participant);

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

    /// @notice Calculate performance metrics for a participant
    function _calculatePerformance(
        uint256 tournamentId,
        address participant
    ) private returns (euint64 totalScore) {
        PositionData storage position = positionData[tournamentId][participant];
        PositionSnapshot storage snapshot = positionSnapshots[tournamentId][participant];
        
        // Mock performance calculation for testing
        // In real implementation, this would fetch actual liquidity position data
        uint256 mockCurrentLiquidity = snapshot.initialLiquidity + 50000; // Simulate growth
        uint256 mockFeesCollected = accumulatedFees[tournamentId][participant] + 1000;
        
        // Calculate PnL percentage (encrypted)
        euint64 liquidityGrowth = FHE.asEuint64(mockCurrentLiquidity > snapshot.initialLiquidity ? 
            ((mockCurrentLiquidity - snapshot.initialLiquidity) * 10000) / snapshot.initialLiquidity : 0);
        
        // Calculate fees earned (encrypted)
        euint64 feesEarned = FHE.asEuint64(mockFeesCollected);
        
        // Combined score: 70% PnL + 30% fees
        euint64 pnlWeight = FHE.asEuint64(7000); // 70%
        euint64 feesWeight = FHE.asEuint64(3000); // 30%
        euint64 divisor = FHE.asEuint64(10000);
        
        euint64 pnlScore = FHE.mul(liquidityGrowth, pnlWeight);
        euint64 feeScore = FHE.mul(feesEarned, feesWeight);
        
        totalScore = FHE.div(FHE.add(pnlScore, feeScore), divisor);
        
        // Update performance metrics
        PerformanceMetrics storage metrics = performanceMetrics[tournamentId][participant];
        metrics.pnlPercentage = liquidityGrowth;
        metrics.feesEarned = feesEarned;
        
        // Grant access permissions
        FHE.allowThis(liquidityGrowth);
        FHE.allowThis(feesEarned);
        FHE.allowThis(totalScore);
        
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
        
        euint64 encPnl = FHE.asEuint64(pnlPercentage);
        euint64 encFees = FHE.asEuint64(feesEarned);
        
        PerformanceMetrics storage metrics = performanceMetrics[tournamentId][participant];
        metrics.pnlPercentage = encPnl;
        metrics.feesEarned = encFees;
        metrics.lastCalculated = block.timestamp;
        
        // Update accumulated fees
        accumulatedFees[tournamentId][participant] = feesEarned;
        
        // Grant permissions
        FHE.allowThis(encPnl);
        FHE.allowThis(encFees);
    }

    /// @notice Capture position snapshot for tournament start
    function capturePositionSnapshot(
        uint256 tournamentId,
        address participant,
        PoolKey memory key
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
        address sender,
        PoolKey calldata key,
        SwapParams calldata params,
        BalanceDelta delta,
        bytes calldata hookData
    ) external onlyPoolManager returns (bytes4, int128) {
        // Mock fee tracking logic for testing
        // In real implementation, would extract fees from the swap delta
        
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
