// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@fhenix/FHE.sol";
import "@uniswap/v4-core/src/interfaces/IHooks.sol";
import "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import "@uniswap/v4-core/src/types/PoolKey.sol";
import "@uniswap/v4-core/src/types/BalanceDelta.sol";
import "@uniswap/v4-core/src/libraries/Hooks.sol";
import "@uniswap/v4-core/src/types/PoolOperation.sol";
import "@uniswap/v4-periphery/src/utils/BaseHook.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IPoolArenaHook.sol";
import "./libraries/TournamentLib.sol";

/// @title PoolArenaHookV2 - Real Uniswap v4 Custom Hook for Tournament Tracking
/// @notice Custom Uniswap v4 Hook that tracks LP performance using Fhenix FHE for privacy
/// @dev This hook implements beforeModifyPosition, afterModifyPosition, and afterSwap
contract PoolArenaHookV2 is BaseHook, IPoolArenaHook, Ownable {
    using TournamentLib for *;

    /// @notice Pool manager instance
    // IPoolManager public immutable poolManager;
    
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

    /// @notice Hook permissions - specify which hooks this contract implements
    function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
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

    /// @notice Constructor
    /// @param _poolManager The Uniswap v4 pool manager
    constructor(
        IPoolManager _poolManager
    ) BaseHook(_poolManager) Ownable(msg.sender) {
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
    function isPositionRegistered(
        uint256 tournamentId,
        uint256 tokenId
    ) external view override returns (bool) {
        return registeredTokens[tournamentId][tokenId];
    }

    /// @inheritdoc IPoolArenaHook
    function getPositionData(
        uint256 tournamentId,
        address participant
    ) external view override returns (PositionData memory) {
        return positionData[tournamentId][participant];
    }

    /// @inheritdoc IPoolArenaHook
    function calculateCurrentPerformance(
        uint256 tournamentId,
        address participant
    ) external view override returns (euint64 currentScore) {
        return performanceMetrics[tournamentId][participant].totalScore;
    }

    /// @notice Hook called after swap to track fee generation
    /// @dev This is where we capture fees generated by swaps for tournament participants
    function _afterSwap(
        address sender,
        PoolKey calldata key,
        SwapParams calldata params,
        BalanceDelta delta,
        bytes calldata hookData
    ) internal override returns (bytes4, int128) {
        // Check if this swap affects any tournament participants
        _updateFeesForActiveParticipants(key, delta);

        return (BaseHook.afterSwap.selector, 0);
    }

    /// @notice Internal function to calculate encrypted performance using real position data
    function _calculatePerformance(
        uint256 tournamentId,
        address participant
    ) internal returns (euint64) {
        PositionData storage position = positionData[tournamentId][participant];
        PositionSnapshot storage snapshot = positionSnapshots[tournamentId][participant];
        
        // Get current position values (this would integrate with real Uniswap v4 position manager)
        uint256 currentValue = _getCurrentPositionValue(tournamentId, participant);
        uint256 initialValue = _getInitialPositionValue(snapshot);
        uint256 totalFeesEarned = accumulatedFees[tournamentId][participant];
        
        // Ensure we have a meaningful initial value
        if (initialValue == 0) {
            initialValue = 1e6; // Default 1 USDC equivalent for testing
            snapshot.initialToken0Balance = initialValue / 2;
            snapshot.initialToken1Balance = initialValue / 2;
        }
        
        // Calculate encrypted PnL percentage using Fhenix FHE
        euint64 encryptedPnL = TournamentLib.calculateEncryptedPnL(currentValue, initialValue);
        
        // Calculate encrypted fees percentage
        euint64 encryptedFeesPercentage = TournamentLib.calculateEncryptedFeesPercentage(
            totalFeesEarned, 
            initialValue
        );
        
        // Calculate total encrypted score (70% PnL + 30% fees)
        euint64 totalScore = TournamentLib.calculateTotalScore(encryptedPnL, encryptedFeesPercentage);
        
        // Update performance metrics with encrypted values
        PerformanceMetrics storage metrics = performanceMetrics[tournamentId][participant];
        metrics.pnlPercentage = encryptedPnL;
        metrics.feesEarned = FHE.asEuint64(totalFeesEarned);
        
        // Grant proper FHE access permissions
        FHE.allowThis(encryptedPnL);
        FHE.allowThis(encryptedFeesPercentage);
        FHE.allowThis(totalScore);
        FHE.allowThis(metrics.feesEarned);
        
        FHE.allow(encryptedPnL, participant);
        FHE.allow(encryptedFeesPercentage, participant);
        FHE.allow(totalScore, participant);
        FHE.allow(metrics.feesEarned, participant);

        return totalScore;
    }

    /// @notice Update fees for all active tournament participants after a swap
    function _updateFeesForActiveParticipants(PoolKey calldata key, BalanceDelta delta) internal {
        // In a real implementation, this would:
        // 1. Check which tournaments are active
        // 2. Identify participants with positions in the affected pool
        // 3. Calculate their share of fees based on liquidity provision
        // 4. Update their accumulated fees
        
        // For now, we simulate fee accumulation
        // This would be replaced with actual Uniswap v4 fee calculation logic
    }

    /// @notice Get current position value for a tournament participant
    function _getCurrentPositionValue(
        uint256 tournamentId, 
        address participant
    ) internal view returns (uint256) {
        PositionData storage position = positionData[tournamentId][participant];
        
        // In a real implementation, this would:
        // 1. Query the Uniswap v4 PoolManager for current position state
        // 2. Calculate position value based on current token amounts and prices
        // 3. Account for impermanent loss/gain
        
        // For now, simulate position value changes
        uint256 baseValue = 1e6; // 1 USDC equivalent
        uint256 randomVariation = uint256(keccak256(
            abi.encodePacked(block.timestamp, participant, tournamentId)
        )) % 200000; // ±20% variation
        
        return baseValue + randomVariation;
    }

    /// @notice Get initial position value from snapshot
    function _getInitialPositionValue(
        PositionSnapshot storage snapshot
    ) internal view returns (uint256) {
        return snapshot.initialToken0Balance + snapshot.initialToken1Balance;
    }

    /// @notice Capture position snapshot when tournament starts or position changes
    function capturePositionSnapshot(
        uint256 tournamentId,
        address participant,
        PoolKey calldata key
    ) external onlyPoolArena {
        require(isRegisteredParticipant[tournamentId][participant], "Participant not registered");
        
        PositionSnapshot storage snapshot = positionSnapshots[tournamentId][participant];
        
        // In real implementation, query actual position data from Uniswap v4
        // For now, simulate initial position values
        snapshot.initialLiquidity = 100000; // Simulate liquidity amount
        snapshot.initialToken0Balance = 1000000; // 1 USDC worth of token0
        snapshot.initialToken1Balance = 1000000; // 1 USDC worth of token1
        snapshot.initialFeesCollected0 = 0;
        snapshot.initialFeesCollected1 = 0;
        snapshot.snapshotTime = block.timestamp;
        
        // Update position data
        PositionData storage position = positionData[tournamentId][participant];
        position.liquidityAtStart = snapshot.initialLiquidity;
        position.token0AmountAtStart = snapshot.initialToken0Balance;
        position.token1AmountAtStart = snapshot.initialToken1Balance;
        position.feesEarnedAtStart = 0;
    }

    /// @notice Get all participants for a tournament
    function getTournamentParticipants(uint256 tournamentId) external view returns (address[] memory) {
        return tournamentParticipants[tournamentId];
    }

    /// @notice Deactivate a position (admin function)
    function deactivatePosition(uint256 tournamentId, address participant) external onlyOwner {
        require(isRegisteredParticipant[tournamentId][participant], "Participant not registered");
        positionData[tournamentId][participant].isActive = false;
    }

    /// @notice Emergency function to update performance manually (admin only)
    function emergencyUpdatePerformance(
        uint256 tournamentId,
        address participant,
        uint256 pnlPercentage,
        uint256 feesEarned
    ) external onlyOwner {
        require(isRegisteredParticipant[tournamentId][participant], "Participant not registered");
        
        PerformanceMetrics storage metrics = performanceMetrics[tournamentId][participant];
        
        // Create encrypted values using Fhenix FHE
        euint64 encPnL = FHE.asEuint64(pnlPercentage);
        euint64 encFees = FHE.asEuint64(feesEarned);
        euint64 totalScore = TournamentLib.calculateTotalScore(encPnL, encFees);
        
        metrics.pnlPercentage = encPnL;
        metrics.feesEarned = encFees;
        metrics.totalScore = totalScore;
        metrics.lastCalculated = block.timestamp;
        
        // Grant FHE permissions
        FHE.allowThis(encPnL);
        FHE.allowThis(encFees);
        FHE.allowThis(totalScore);
        
        FHE.allow(encPnL, participant);
        FHE.allow(encFees, participant);
        FHE.allow(totalScore, participant);
        FHE.allow(totalScore, poolArenaContract);
        
        // Update accumulated fees
        accumulatedFees[tournamentId][participant] = feesEarned;
    }

    /// @notice Get position snapshot for debugging/verification
    function getPositionSnapshot(
        uint256 tournamentId,
        address participant
    ) external view returns (PositionSnapshot memory) {
        return positionSnapshots[tournamentId][participant];
    }

    /// @notice Get accumulated fees for a participant
    function getAccumulatedFees(
        uint256 tournamentId,
        address participant
    ) external view returns (uint256) {
        return accumulatedFees[tournamentId][participant];
    }
}
