// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "./MockPoolArenaHook.sol";
import "../src/PoolArena.sol";
import "../src/interfaces/IPoolArena.sol";
import "../src/interfaces/IPoolArenaHook.sol";
import "../src/libraries/TournamentLib.sol";
import "@uniswap/v4-core/src/types/PoolOperation.sol";

contract PoolArenaHookV2Test is Test {
    PoolArena public poolArena;
    MockPoolArenaHook public hook;
    MockPoolManager public mockPoolManager;
    MockLPNFT public mockLPNFT;
    
    address public owner = address(this);
    address public treasury = address(0x123);
    address public user1 = address(0x456);
    address public user2 = address(0x789);
    address public user3 = address(0xabc);
    
    uint256 public constant ENTRY_FEE = 0.002 ether;
    uint256 public constant MAX_PARTICIPANTS = 12;
    uint256 public constant DURATION = 7 days;
    uint256 public constant TREASURY_FEE = 100; // 1%

    event PositionRegistered(
        uint256 indexed tournamentId,
        address indexed participant,
        uint256 indexed tokenId,
        uint128 initialLiquidity
    );

    event PerformanceCalculated(
        uint256 indexed tournamentId,
        address indexed participant,
        euint64 pnlPercentage,
        euint64 feesEarned
    );

    function setUp() public {
        // Deploy mock contracts
        mockPoolManager = new MockPoolManager();
        mockLPNFT = new MockLPNFT();
        
        // Deploy hook with mock implementation
        hook = new MockPoolArenaHook(IPoolManager(address(mockPoolManager)));
        
        // Deploy main contract
        poolArena = new PoolArena(
            address(hook),
            address(mockLPNFT),
            treasury
        );
        
        // Configure hook
        hook.setPoolArenaContract(address(poolArena));
        
        // Set up test users with ETH and NFTs
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);
        vm.deal(user3, 10 ether);
        
        // Mint NFTs to users
        uint256 tokenId1 = mockLPNFT.mint(user1);
        uint256 tokenId2 = mockLPNFT.mint(user2);
        uint256 tokenId3 = mockLPNFT.mint(user3);
        
        // Approve PoolArena to transfer NFTs
        vm.prank(user1);
        mockLPNFT.approve(address(poolArena), tokenId1);
        vm.prank(user2);
        mockLPNFT.approve(address(poolArena), tokenId2);
        vm.prank(user3);
        mockLPNFT.approve(address(poolArena), tokenId3);
    }

    function testHookPermissions() public {
        // Test that hook has correct permissions
        Hooks.Permissions memory perms = hook.getHookPermissions();
        
        assertFalse(perms.beforeInitialize);
        assertFalse(perms.afterInitialize);
        assertFalse(perms.beforeAddLiquidity);
        assertFalse(perms.afterAddLiquidity);
        assertFalse(perms.beforeRemoveLiquidity);
        assertFalse(perms.afterRemoveLiquidity);
        assertFalse(perms.beforeSwap);
        assertTrue(perms.afterSwap); // Should be true - we track fees from swaps
        assertFalse(perms.beforeDonate);
        assertFalse(perms.afterDonate);
    }

    function testRegisterPositionInHook() public {
        // Create tournament
        IPoolArena.TournamentConfig memory config = IPoolArena.TournamentConfig({
            entryFee: ENTRY_FEE,
            maxParticipants: MAX_PARTICIPANTS,
            duration: DURATION,
            treasuryFee: TREASURY_FEE,
            prizeDistribution: [uint256(7000), uint256(2000), uint256(1000)]
        });
        
        uint256 tournamentId = poolArena.createTournament(config);
        uint256 tokenId = 1;
        
        // Join tournament (this should register position in hook)
        vm.expectEmit(true, true, true, true);
        emit PositionRegistered(tournamentId, user1, tokenId, 0);
        
        vm.prank(user1);
        poolArena.joinTournament{value: ENTRY_FEE}(tournamentId, tokenId);
        
        // Verify position is registered in hook
        assertTrue(hook.isPositionRegistered(tournamentId, tokenId));
        
        // Check position data
        IPoolArenaHook.PositionData memory posData = hook.getPositionData(tournamentId, user1);
        assertEq(posData.tournamentId, tournamentId);
        assertEq(posData.participant, user1);
        assertEq(posData.tokenId, tokenId);
        assertTrue(posData.isActive);
        assertEq(posData.liquidityAtStart, 0); // Not yet captured
    }

    function testCapturePositionSnapshot() public {
        // Create tournament and join
        IPoolArena.TournamentConfig memory config = IPoolArena.TournamentConfig({
            entryFee: ENTRY_FEE,
            maxParticipants: MAX_PARTICIPANTS,
            duration: DURATION,
            treasuryFee: TREASURY_FEE,
            prizeDistribution: [uint256(7000), uint256(2000), uint256(1000)]
        });
        
        uint256 tournamentId = poolArena.createTournament(config);
        
        vm.prank(user1);
        poolArena.joinTournament{value: ENTRY_FEE}(tournamentId, 1);
        
        // Create mock PoolKey for testing
        PoolKey memory key = PoolKey({
            currency0: Currency.wrap(address(0x111)),
            currency1: Currency.wrap(address(0x222)),
            fee: 3000,
            tickSpacing: 60,
            hooks: IHooks(hook)
        });
        
        // Capture position snapshot
        hook.capturePositionSnapshot(tournamentId, user1, key);
        
        // Verify snapshot was captured
        MockPoolArenaHook.PositionSnapshot memory snapshot = hook.getPositionSnapshot(tournamentId, user1);
        assertEq(snapshot.initialLiquidity, 100000);
        assertEq(snapshot.initialToken0Balance, 1000000);
        assertEq(snapshot.initialToken1Balance, 1000000);
        assertEq(snapshot.snapshotTime, block.timestamp);
        
        // Verify position data was updated
        IPoolArenaHook.PositionData memory posData = hook.getPositionData(tournamentId, user1);
        assertEq(posData.liquidityAtStart, 100000);
        assertEq(posData.token0AmountAtStart, 1000000);
        assertEq(posData.token1AmountAtStart, 1000000);
    }

    function testPerformanceCalculation() public {
        // Create tournament and join
        IPoolArena.TournamentConfig memory config = IPoolArena.TournamentConfig({
            entryFee: ENTRY_FEE,
            maxParticipants: MAX_PARTICIPANTS,
            duration: DURATION,
            treasuryFee: TREASURY_FEE,
            prizeDistribution: [uint256(7000), uint256(2000), uint256(1000)]
        });
        
        uint256 tournamentId = poolArena.createTournament(config);
        
        vm.prank(user1);
        poolArena.joinTournament{value: ENTRY_FEE}(tournamentId, 1);
        
        // Capture position snapshot
        PoolKey memory key = PoolKey({
            currency0: Currency.wrap(address(0x111)),
            currency1: Currency.wrap(address(0x222)),
            fee: 3000,
            tickSpacing: 60,
            hooks: IHooks(hook)
        });
        
        hook.capturePositionSnapshot(tournamentId, user1, key);
        
        // Start tournament
        poolArena.startTournament(tournamentId);
        
        // Wait some time
        vm.warp(block.timestamp + 1 days);
        
        // Update performance
        euint64 score = hook.updatePerformance(tournamentId, user1);
        
        // Verify performance metrics were calculated
        IPoolArenaHook.PerformanceMetrics memory metrics = hook.getPerformanceMetrics(tournamentId, user1);
        assertEq(euint64.unwrap(metrics.totalScore), euint64.unwrap(score));
        assertEq(metrics.lastCalculated, block.timestamp);
    }

    function testEmergencyUpdatePerformance() public {
        // Create tournament and join
        IPoolArena.TournamentConfig memory config = IPoolArena.TournamentConfig({
            entryFee: ENTRY_FEE,
            maxParticipants: MAX_PARTICIPANTS,
            duration: DURATION,
            treasuryFee: TREASURY_FEE,
            prizeDistribution: [uint256(7000), uint256(2000), uint256(1000)]
        });
        
        uint256 tournamentId = poolArena.createTournament(config);
        
        vm.prank(user1);
        poolArena.joinTournament{value: ENTRY_FEE}(tournamentId, 1);
        
        // Emergency update performance (admin only)
        uint256 pnlPercentage = 15000; // 150% (profitable)
        uint256 feesEarned = 50000; // 0.05 ETH worth of fees
        
        hook.emergencyUpdatePerformance(tournamentId, user1, pnlPercentage, feesEarned);
        
        // Verify the update
        IPoolArenaHook.PerformanceMetrics memory metrics = hook.getPerformanceMetrics(tournamentId, user1);
        assertEq(hook.getAccumulatedFees(tournamentId, user1), feesEarned);
        assertEq(metrics.lastCalculated, block.timestamp);
    }

    function testAfterSwapHook() public {
        // Create mock swap parameters
        PoolKey memory key = PoolKey({
            currency0: Currency.wrap(address(0x111)),
            currency1: Currency.wrap(address(0x222)),
            fee: 3000,
            tickSpacing: 60,
            hooks: IHooks(hook)
        });
        
        SwapParams memory params = SwapParams({
            zeroForOne: true,
            amountSpecified: -1000000,
            sqrtPriceLimitX96: 0
        });
        
        BalanceDelta delta = BalanceDelta.wrap(-1000000);
        bytes memory hookData = "";
        
        // Call afterSwap hook
        (bytes4 selector, int128 hookReturn) = hook.afterSwap(
            address(this),
            key,
            params,
            delta,
            hookData
        );
        
        // Verify hook returned correct selector
        assertEq(selector, MockPoolArenaHook.afterSwap.selector);
        assertEq(hookReturn, 0);
    }

    function testTournamentParticipantTracking() public {
        // Create tournament
        IPoolArena.TournamentConfig memory config = IPoolArena.TournamentConfig({
            entryFee: ENTRY_FEE,
            maxParticipants: MAX_PARTICIPANTS,
            duration: DURATION,
            treasuryFee: TREASURY_FEE,
            prizeDistribution: [uint256(7000), uint256(2000), uint256(1000)]
        });
        
        uint256 tournamentId = poolArena.createTournament(config);
        
        // Join multiple users
        vm.prank(user1);
        poolArena.joinTournament{value: ENTRY_FEE}(tournamentId, 1);
        
        vm.prank(user2);
        poolArena.joinTournament{value: ENTRY_FEE}(tournamentId, 2);
        
        vm.prank(user3);
        poolArena.joinTournament{value: ENTRY_FEE}(tournamentId, 3);
        
        // Verify tournament participants
        address[] memory participants = hook.getTournamentParticipants(tournamentId);
        assertEq(participants.length, 3);
        assertEq(participants[0], user1);
        assertEq(participants[1], user2);
        assertEq(participants[2], user3);
    }

    function testDeactivatePosition() public {
        // Create tournament and join
        IPoolArena.TournamentConfig memory config = IPoolArena.TournamentConfig({
            entryFee: ENTRY_FEE,
            maxParticipants: MAX_PARTICIPANTS,
            duration: DURATION,
            treasuryFee: TREASURY_FEE,
            prizeDistribution: [uint256(7000), uint256(2000), uint256(1000)]
        });
        
        uint256 tournamentId = poolArena.createTournament(config);
        
        vm.prank(user1);
        poolArena.joinTournament{value: ENTRY_FEE}(tournamentId, 1);
        
        // Verify position is active
        IPoolArenaHook.PositionData memory posData = hook.getPositionData(tournamentId, user1);
        assertTrue(posData.isActive);
        
        // Deactivate position (admin only)
        hook.deactivatePosition(tournamentId, user1);
        
        // Verify position is deactivated
        posData = hook.getPositionData(tournamentId, user1);
        assertFalse(posData.isActive);
    }

    function testHookIntegrationWithTournamentLifecycle() public {
        // Create tournament
        IPoolArena.TournamentConfig memory config = IPoolArena.TournamentConfig({
            entryFee: ENTRY_FEE,
            maxParticipants: MAX_PARTICIPANTS,
            duration: DURATION,
            treasuryFee: TREASURY_FEE,
            prizeDistribution: [uint256(7000), uint256(2000), uint256(1000)]
        });
        
        uint256 tournamentId = poolArena.createTournament(config);
        
        // Join tournament
        vm.prank(user1);
        poolArena.joinTournament{value: ENTRY_FEE}(tournamentId, 1);
        
        vm.prank(user2);
        poolArena.joinTournament{value: ENTRY_FEE}(tournamentId, 2);
        
        vm.prank(user3);
        poolArena.joinTournament{value: ENTRY_FEE}(tournamentId, 3);
        
        // Start tournament
        poolArena.startTournament(tournamentId);
        
        // Capture snapshots for all participants
        PoolKey memory key = PoolKey({
            currency0: Currency.wrap(address(0x111)),
            currency1: Currency.wrap(address(0x222)),
            fee: 3000,
            tickSpacing: 60,
            hooks: IHooks(hook)
        });
        
        hook.capturePositionSnapshot(tournamentId, user1, key);
        hook.capturePositionSnapshot(tournamentId, user2, key);
        hook.capturePositionSnapshot(tournamentId, user3, key);
        
        // Simulate some time passing and performance updates
        vm.warp(block.timestamp + 3 days);
        
        // Update performances
        hook.updatePerformance(tournamentId, user1);
        hook.updatePerformance(tournamentId, user2);
        hook.updatePerformance(tournamentId, user3);
        
        // End tournament
        vm.warp(block.timestamp + DURATION);
        poolArena.endTournament(tournamentId);
        
        // Verify all participants have performance data
        for (uint i = 0; i < 3; i++) {
            address participant = i == 0 ? user1 : (i == 1 ? user2 : user3);
            IPoolArenaHook.PerformanceMetrics memory metrics = hook.getPerformanceMetrics(tournamentId, participant);
            assertTrue(euint64.unwrap(metrics.totalScore) > 0);
        }
    }

    function testOnlyAuthorizedAccess() public {
        // Create tournament
        IPoolArena.TournamentConfig memory config = IPoolArena.TournamentConfig({
            entryFee: ENTRY_FEE,
            maxParticipants: MAX_PARTICIPANTS,
            duration: DURATION,
            treasuryFee: TREASURY_FEE,
            prizeDistribution: [uint256(7000), uint256(2000), uint256(1000)]
        });
        
        uint256 tournamentId = poolArena.createTournament(config);
        
        // Try to register position directly (should fail)
        vm.expectRevert("Not authorized");
        hook.registerPosition(tournamentId, user1, 1);
        
        // Try to update performance directly (should fail)  
        vm.expectRevert("Not authorized");
        hook.updatePerformance(tournamentId, user1);
    }
}

// Mock contracts for testing
contract MockPoolManager {
    function getSlot0(bytes32) external pure returns (uint160, int24) {
        return (0, 0);
    }
}

contract MockLPNFT {
    mapping(uint256 => address) private owners;
    mapping(address => mapping(address => bool)) private approvals;
    uint256 private nextTokenId = 1;

    function ownerOf(uint256 tokenId) external view returns (address) {
        return owners[tokenId];
    }

    function approve(address to, uint256 tokenId) external {
        approvals[msg.sender][to] = true;
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) external {
        require(owners[tokenId] == from, "Not owner");
        owners[tokenId] = to;
    }

    function mint(address to) external returns (uint256) {
        owners[nextTokenId] = to;
        return nextTokenId++;
    }
}
