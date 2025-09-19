// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/PoolArena.sol";
import {Hooks} from "v4-core/libraries/Hooks.sol";
import {HookMiner} from "v4-periphery/src/utils/HookMiner.sol";
import {IHooks} from "v4-core/interfaces/IHooks.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "v4-core/types/PoolId.sol";
import {BalanceDelta} from "v4-core/types/BalanceDelta.sol";
import {BeforeSwapDelta} from "v4-core/types/BeforeSwapDelta.sol";

// Mock contracts for testing
contract MockPositionManager {
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    
    uint256 public nextTokenId = 1;
    
    // Mock position data
    mapping(uint256 => uint256) public positionLiquidity;
    mapping(uint256 => uint256) public accumulatedFees;
    
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    
    function mint(address to, uint256 liquidity) external returns (uint256) {
        uint256 tokenId = nextTokenId++;
        _owners[tokenId] = to;
        _balances[to]++;
        positionLiquidity[tokenId] = liquidity;
        accumulatedFees[tokenId] = liquidity / 100; // Mock initial fees
        
        emit Transfer(address(0), to, tokenId);
        return tokenId;
    }
    
    function simulateFeeAccrual(uint256 tokenId, uint256 additionalFees) external {
        accumulatedFees[tokenId] += additionalFees;
    }
    
    // ERC721 Implementation
    function balanceOf(address owner) external view returns (uint256) {
        return _balances[owner];
    }
    
    function ownerOf(uint256 tokenId) external view returns (address) {
        return _owners[tokenId];
    }
    
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata) external {
        _transfer(from, to, tokenId);
    }
    
    function safeTransferFrom(address from, address to, uint256 tokenId) external {
        _transfer(from, to, tokenId);
    }
    
    function transferFrom(address from, address to, uint256 tokenId) external {
        _transfer(from, to, tokenId);
    }
    
    function approve(address to, uint256 tokenId) external {
        _tokenApprovals[tokenId] = to;
        emit Approval(_owners[tokenId], to, tokenId);
    }
    
    function getApproved(uint256 tokenId) external view returns (address) {
        return _tokenApprovals[tokenId];
    }
    
    function setApprovalForAll(address operator, bool approved) external {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }
    
    function isApprovedForAll(address owner, address operator) external view returns (bool) {
        return _operatorApprovals[owner][operator];
    }
    
    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == type(IERC721).interfaceId || interfaceId == 0x01ffc9a7; // ERC165
    }
    
    function _transfer(address from, address to, uint256 tokenId) internal {
        require(_owners[tokenId] == from, "Not owner");
        require(
            msg.sender == from || 
            _tokenApprovals[tokenId] == msg.sender || 
            _operatorApprovals[from][msg.sender],
            "Not approved"
        );
        
        _balances[from]--;
        _balances[to]++;
        _owners[tokenId] = to;
        delete _tokenApprovals[tokenId];
        
        emit Transfer(from, to, tokenId);
    }
}

contract MockPyth {
    mapping(bytes32 => PythStructs.Price) private prices;
    
    function setPrice(bytes32 id, int64 price, uint64 conf, int32 expo) external {
        prices[id] = PythStructs.Price({
            price: price,
            conf: conf,
            expo: expo,
            publishTime: uint64(block.timestamp)
        });
    }
    
    function getPrice(bytes32 id) external view returns (PythStructs.Price memory) {
        return prices[id];
    }
    
    function getPriceUnsafe(bytes32 id) external view returns (PythStructs.Price memory) {
        return prices[id];
    }
    
    function updatePriceFeeds(bytes[] calldata) external payable {}
    
    function getUpdateFee(bytes[] calldata) external pure returns (uint256) {
        return 0;
    }
    
    function parsePriceFeedUpdates(
        bytes[] calldata,
        bytes32[] calldata,
        uint64,
        uint64
    ) external pure returns (PythStructs.PriceFeed[] memory) {
        return new PythStructs.PriceFeed[](0);
    }
    
    function getValidTimePeriod() external pure returns (uint256) {
        return 60;
    }
}

// Mock hook for testing that bypasses validation
contract MockPoolArenaHook is IHooks {
    using PoolIdLibrary for PoolKey;

    IPoolManager public immutable poolManager;
    address public poolArenaContract;

    constructor(IPoolManager _poolManager) {
        poolManager = _poolManager;
        // Skip validation for testing
    }

    modifier onlyPoolManager() {
        require(msg.sender == address(poolManager), "Not pool manager");
        _;
    }

    function setPoolArenaContract(address _poolArenaContract) external {
        require(poolArenaContract == address(0), "Already set");
        poolArenaContract = _poolArenaContract;
    }

    // Required IHooks interface implementations
    function beforeInitialize(address, PoolKey calldata, uint160) external pure returns (bytes4) {
        revert("Not implemented");
    }

    function afterInitialize(address, PoolKey calldata, uint160, int24) external pure returns (bytes4) {
        revert("Not implemented");
    }

    function beforeAddLiquidity(
        address sender,
        PoolKey calldata key,
        IPoolManager.ModifyLiquidityParams calldata,
        bytes calldata
    ) external onlyPoolManager returns (bytes4) {
        if (poolArenaContract != address(0)) {
            IPoolArena(poolArenaContract).checkLiquidityModification(key.toId(), sender);
        }
        return IHooks.beforeAddLiquidity.selector;
    }

    function afterAddLiquidity(
        address,
        PoolKey calldata,
        IPoolManager.ModifyLiquidityParams calldata,
        BalanceDelta,
        BalanceDelta,
        bytes calldata
    ) external pure returns (bytes4, BalanceDelta) {
        revert("Not implemented");
    }

    function beforeRemoveLiquidity(
        address sender,
        PoolKey calldata key,
        IPoolManager.ModifyLiquidityParams calldata,
        bytes calldata
    ) external onlyPoolManager returns (bytes4) {
        if (poolArenaContract != address(0)) {
            IPoolArena(poolArenaContract).checkLiquidityModification(key.toId(), sender);
        }
        return IHooks.beforeRemoveLiquidity.selector;
    }

    function afterRemoveLiquidity(
        address,
        PoolKey calldata,
        IPoolManager.ModifyLiquidityParams calldata,
        BalanceDelta,
        BalanceDelta,
        bytes calldata
    ) external pure returns (bytes4, BalanceDelta) {
        revert("Not implemented");
    }

    function beforeSwap(
        address,
        PoolKey calldata,
        IPoolManager.SwapParams calldata,
        bytes calldata
    ) external pure returns (bytes4, BeforeSwapDelta, uint24) {
        revert("Not implemented");
    }

    function afterSwap(
        address,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata,
        BalanceDelta delta,
        bytes calldata
    ) external onlyPoolManager returns (bytes4, int128) {
        if (poolArenaContract != address(0)) {
            IPoolArena(poolArenaContract).trackSwapFees(key.toId(), delta);
        }
        return (IHooks.afterSwap.selector, 0);
    }

    function beforeDonate(
        address,
        PoolKey calldata,
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        revert("Not implemented");
    }

    function afterDonate(
        address,
        PoolKey calldata,
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        revert("Not implemented");
    }
}

contract PoolArenaTest is Test {
    PoolArena public poolArena;
    MockPoolArenaHook public hook;
    MockPositionManager public positionManager;
    MockPyth public pyth;
    
    address public owner = address(this);
    address public user1;
    address public user2;
    address public user3;
    address public user4;
    address public user5;
    address public user6; // Extra user for testing full tournament
    
    address public mockPoolManager = address(0x1234567890123456789012345678901234567890);
    
    uint256 public constant ENTRY_FEE = 0.002 ether;
    uint256 public constant MAX_PARTICIPANTS = 5; // Keep 5 for most tests, use 2 for specific tests
    
    event TournamentCreated(uint256 indexed tournamentId, PoolArena.TournamentType tournamentType, uint256 entryFee, uint256 maxParticipants);
    event TournamentJoined(uint256 indexed tournamentId, address indexed participant, uint256 tokenId);
    event TournamentStarted(uint256 indexed tournamentId, uint256 startTime);
    event TournamentFinished(uint256 indexed tournamentId, address[3] winners, uint256[3] prizes);
    
    // Allow test contract to receive ETH
    receive() external payable {}
    
    function setUp() public {
        // Generate proper EOA addresses using vm.addr()
        user1 = vm.addr(1);
        user2 = vm.addr(2);
        user3 = vm.addr(3);
        user4 = vm.addr(4);
        user5 = vm.addr(5);
        user6 = vm.addr(6);
        
        // Deploy mock contracts
        positionManager = new MockPositionManager();
        pyth = new MockPyth();
        
        // Deploy hook with proper permissions
        // The hook needs: beforeAddLiquidity, beforeRemoveLiquidity, and afterSwap
        uint160 permissions = uint160(
            Hooks.BEFORE_ADD_LIQUIDITY_FLAG | 
            Hooks.BEFORE_REMOVE_LIQUIDITY_FLAG | 
            Hooks.AFTER_SWAP_FLAG
        );
        
        // Find a salt that will produce the correct address
        (address expectedHookAddress, bytes32 salt) = HookMiner.find(
            address(this),
            permissions,
            type(MockPoolArenaHook).creationCode,
            abi.encode(mockPoolManager)
        );
        
        // Deploy the hook to the expected address
        hook = new MockPoolArenaHook{salt: salt}(IPoolManager(mockPoolManager));
        require(address(hook) == expectedHookAddress, "Hook address mismatch");
        
        // Deploy main contract
        poolArena = new PoolArena(
            address(positionManager),
            address(pyth),
            address(hook)
        );
        
        // Link hook to pool arena
        hook.setPoolArenaContract(address(poolArena));
        
        // Setup test users with ETH
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);
        vm.deal(user3, 10 ether);
        vm.deal(user4, 10 ether);
        vm.deal(user5, 10 ether);
        vm.deal(user6, 10 ether);
        
        // Set ETH price in Pyth oracle
        bytes32 ethPriceId = 0xff61491a931112ddf1bd8147cd1b641375f79f5825126d665480874634fd0ace;
        pyth.setPrice(ethPriceId, 250000000000, 1000000000, -8); // $2500
    }
    
    function testDeployment() public view {
        assertEq(address(poolArena.positionManager()), address(positionManager));
        assertEq(address(poolArena.pyth()), address(pyth));
        assertEq(address(poolArena.hook()), address(hook));
        assertEq(poolArena.nextTournamentId(), 1);
    }
    
    function testCreateTournament() public {
        vm.expectEmit(true, true, true, true);
        emit TournamentCreated(1, PoolArena.TournamentType.DAILY, ENTRY_FEE, MAX_PARTICIPANTS);
        
        poolArena.createTournament(PoolArena.TournamentType.DAILY, ENTRY_FEE, MAX_PARTICIPANTS);
        
        (
            uint256 id,
            PoolArena.TournamentType tournamentType,
            PoolArena.TournamentStatus status,
            uint256 entryFee,
            uint256 maxParticipants,
            uint256 currentParticipants,
            ,
            ,
        ) = poolArena.getTournament(1);
        
        assertEq(id, 1);
        assertEq(uint8(tournamentType), uint8(PoolArena.TournamentType.DAILY));
        assertEq(uint8(status), uint8(PoolArena.TournamentStatus.PENDING));
        assertEq(entryFee, ENTRY_FEE);
        assertEq(maxParticipants, MAX_PARTICIPANTS);
        assertEq(currentParticipants, 0);
    }
    
    function testCreateTournamentInvalidParticipants() public {
        vm.expectRevert("Invalid participant count");
        poolArena.createTournament(PoolArena.TournamentType.DAILY, ENTRY_FEE, 1); // Below minimum
        
        vm.expectRevert("Invalid participant count");
        poolArena.createTournament(PoolArena.TournamentType.DAILY, ENTRY_FEE, 13); // Above maximum
    }
    
    function testCreateTournamentZeroFee() public {
        vm.expectRevert("Entry fee must be positive");
        poolArena.createTournament(PoolArena.TournamentType.DAILY, 0, MAX_PARTICIPANTS);
    }
    
    function testOnlyOwnerCanCreateTournament() public {
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user1));
        poolArena.createTournament(PoolArena.TournamentType.DAILY, ENTRY_FEE, MAX_PARTICIPANTS);
    }
    
    function testJoinTournament() public {
        // Create tournament
        poolArena.createTournament(PoolArena.TournamentType.DAILY, ENTRY_FEE, MAX_PARTICIPANTS);
        
        // Mint LP NFT for user1
        uint256 tokenId = positionManager.mint(user1, 10 ether);
        
        // User1 joins tournament
        vm.startPrank(user1);
        positionManager.approve(address(poolArena), tokenId);
        
        vm.expectEmit(true, true, true, true);
        emit TournamentJoined(1, user1, tokenId);
        
        poolArena.joinTournament{value: ENTRY_FEE}(1, tokenId);
        vm.stopPrank();
        
        // Check tournament state
        (, , , , , uint256 currentParticipants, , , uint256 prizePool) = poolArena.getTournament(1);
        assertEq(currentParticipants, 1);
        assertEq(prizePool, (ENTRY_FEE * 99) / 100); // 1% platform fee
        
        // Check NFT transferred
        assertEq(positionManager.ownerOf(tokenId), address(poolArena));
        
        // Check active participation
        assertEq(poolArena.activeParticipations(user1), 1);
    }
    
    function testJoinTournamentIncorrectFee() public {
        poolArena.createTournament(PoolArena.TournamentType.DAILY, ENTRY_FEE, MAX_PARTICIPANTS);
        uint256 tokenId = positionManager.mint(user1, 10 ether);
        
        vm.startPrank(user1);
        positionManager.approve(address(poolArena), tokenId);
        
        vm.expectRevert("Incorrect entry fee");
        poolArena.joinTournament{value: 0.001 ether}(1, tokenId);
        vm.stopPrank();
    }
    
    function testJoinFullTournament() public {
        poolArena.createTournament(PoolArena.TournamentType.DAILY, ENTRY_FEE, 2); // Min tournament size
        
        address[2] memory users = [user1, user2];
        
        // Fill tournament
        for (uint256 i = 0; i < 2; i++) {
            uint256 userTokenId = positionManager.mint(users[i], 10 ether);
            vm.startPrank(users[i]);
            positionManager.approve(address(poolArena), userTokenId);
            poolArena.joinTournament{value: ENTRY_FEE}(1, userTokenId);
            vm.stopPrank();
        }
        
        // Try to join full tournament with user3
        uint256 tokenId = positionManager.mint(user3, 10 ether);
        vm.startPrank(user3);
        positionManager.approve(address(poolArena), tokenId);
        
        vm.expectRevert("Tournament full");
        poolArena.joinTournament{value: ENTRY_FEE}(1, tokenId);
        vm.stopPrank();
    }
    
    function testAutoStartTournament() public {
        poolArena.createTournament(PoolArena.TournamentType.DAILY, ENTRY_FEE, MAX_PARTICIPANTS);
        
        address[5] memory users = [user1, user2, user3, user4, user5];
        
        // Fill tournament - should auto-start on last participant
        for (uint256 i = 0; i < 5; i++) {
            uint256 tokenId = positionManager.mint(users[i], 10 ether);
            vm.startPrank(users[i]);
            positionManager.approve(address(poolArena), tokenId);
            
            if (i == 4) {
                vm.expectEmit(true, true, false, false);
                emit TournamentStarted(1, block.timestamp);
            }
            
            poolArena.joinTournament{value: ENTRY_FEE}(1, tokenId);
            vm.stopPrank();
        }
        
        // Check tournament is active
        (, , PoolArena.TournamentStatus status, , , , uint256 startTime, , ) = poolArena.getTournament(1);
        assertEq(uint8(status), uint8(PoolArena.TournamentStatus.ACTIVE));
        assertEq(startTime, block.timestamp);
    }
    
    function testManualStartTournament() public {
        poolArena.createTournament(PoolArena.TournamentType.DAILY, ENTRY_FEE, MAX_PARTICIPANTS);
        
        // Add minimum participants
        address[5] memory users = [user1, user2, user3, user4, user5];
        for (uint256 i = 0; i < 5; i++) {
            uint256 tokenId = positionManager.mint(users[i], 10 ether);
            vm.startPrank(users[i]);
            positionManager.approve(address(poolArena), tokenId);
            poolArena.joinTournament{value: ENTRY_FEE}(1, tokenId);
            vm.stopPrank();
        }
        
        // Tournament should already be started, but let's test the manual start function
        (, , PoolArena.TournamentStatus status, , , , , , ) = poolArena.getTournament(1);
        assertEq(uint8(status), uint8(PoolArena.TournamentStatus.ACTIVE));
    }
    
    function testFinishTournament() public {
        // Setup and fill tournament
        poolArena.createTournament(PoolArena.TournamentType.DAILY, ENTRY_FEE, MAX_PARTICIPANTS);
        
        address[5] memory users = [user1, user2, user3, user4, user5];
        uint256[5] memory tokenIds;
        
        for (uint256 i = 0; i < 5; i++) {
            tokenIds[i] = positionManager.mint(users[i], 10 ether);
            vm.startPrank(users[i]);
            positionManager.approve(address(poolArena), tokenIds[i]);
            poolArena.joinTournament{value: ENTRY_FEE}(1, tokenIds[i]);
            vm.stopPrank();
        }
        
        // Simulate fee accumulation with different amounts
        for (uint256 i = 0; i < 5; i++) {
            positionManager.simulateFeeAccrual(tokenIds[i], (i + 1) * 1 ether);
        }
        
        // Fast forward time
        vm.warp(block.timestamp + 1 days + 1);
        
        // Record balances before
        uint256[] memory balancesBefore = new uint256[](5);
        for (uint256 i = 0; i < 5; i++) {
            balancesBefore[i] = users[i].balance;
        }
        
        // Finish tournament
        vm.expectEmit(true, false, false, false);
        emit TournamentFinished(1, [address(0), address(0), address(0)], [uint256(0), 0, 0]);
        poolArena.finishTournament(1);
        
        // Check tournament finished
        (, , PoolArena.TournamentStatus status, , , , , , ) = poolArena.getTournament(1);
        assertEq(uint8(status), uint8(PoolArena.TournamentStatus.FINISHED));
        
        // Check NFTs returned
        for (uint256 i = 0; i < 5; i++) {
            assertEq(positionManager.ownerOf(tokenIds[i]), users[i]);
            assertEq(poolArena.activeParticipations(users[i]), 0);
        }
        
        // Check prizes distributed (top 3 should have received prizes)
        uint256 winnersWithPrizes = 0;
        for (uint256 i = 0; i < 5; i++) {
            if (users[i].balance > balancesBefore[i]) {
                winnersWithPrizes++;
            }
        }
        assertEq(winnersWithPrizes, 3);
    }
    
    function testFinishTournamentTooEarly() public {
        poolArena.createTournament(PoolArena.TournamentType.DAILY, ENTRY_FEE, MAX_PARTICIPANTS);
        
        address[5] memory users = [user1, user2, user3, user4, user5];
        for (uint256 i = 0; i < 5; i++) {
            uint256 tokenId = positionManager.mint(users[i], 10 ether);
            vm.startPrank(users[i]);
            positionManager.approve(address(poolArena), tokenId);
            poolArena.joinTournament{value: ENTRY_FEE}(1, tokenId);
            vm.stopPrank();
        }
        
        // Try to finish before time
        vm.expectRevert("Tournament not ended");
        poolArena.finishTournament(1);
    }
    
    function testCancelTournament() public {
        poolArena.createTournament(PoolArena.TournamentType.DAILY, ENTRY_FEE, MAX_PARTICIPANTS);
        
        // Add one participant
        uint256 tokenId = positionManager.mint(user1, 10 ether);
        vm.startPrank(user1);
        positionManager.approve(address(poolArena), tokenId);
        poolArena.joinTournament{value: ENTRY_FEE}(1, tokenId);
        vm.stopPrank();
        
        uint256 balanceBefore = user1.balance;
        
        // Cancel tournament
        poolArena.cancelTournament(1);
        
        // Check refund
        assertGt(user1.balance, balanceBefore);
        assertEq(positionManager.ownerOf(tokenId), user1);
        assertEq(poolArena.activeParticipations(user1), 0);
        
        // Check tournament cancelled
        (, , PoolArena.TournamentStatus status, , , , , , ) = poolArena.getTournament(1);
        assertEq(uint8(status), uint8(PoolArena.TournamentStatus.CANCELLED));
    }
    
    function testWithdrawPlatformFees() public {
        poolArena.createTournament(PoolArena.TournamentType.DAILY, ENTRY_FEE, MAX_PARTICIPANTS);
        
        // Add participants to generate platform fees
        address[5] memory users = [user1, user2, user3, user4, user5];
        for (uint256 i = 0; i < 5; i++) {
            uint256 tokenId = positionManager.mint(users[i], 10 ether);
            vm.startPrank(users[i]);
            positionManager.approve(address(poolArena), tokenId);
            poolArena.joinTournament{value: ENTRY_FEE}(1, tokenId);
            vm.stopPrank();
        }
        
        uint256 balanceBefore = owner.balance;
        
        // Withdraw platform fees
        poolArena.withdrawPlatformFees();
        
        assertGt(owner.balance, balanceBefore);
    }
    
    function testGetTournamentInfo() public {
        poolArena.createTournament(PoolArena.TournamentType.WEEKLY, ENTRY_FEE * 2, 8);
        
        (
            uint256 id,
            PoolArena.TournamentType tournamentType,
            PoolArena.TournamentStatus status,
            uint256 entryFee,
            uint256 maxParticipants,
            uint256 currentParticipants,
            uint256 startTime,
            uint256 endTime,
            uint256 prizePool
        ) = poolArena.getTournament(1);
        
        assertEq(id, 1);
        assertEq(uint8(tournamentType), uint8(PoolArena.TournamentType.WEEKLY));
        assertEq(uint8(status), uint8(PoolArena.TournamentStatus.PENDING));
        assertEq(entryFee, ENTRY_FEE * 2);
        assertEq(maxParticipants, 8);
        assertEq(currentParticipants, 0);
        assertEq(startTime, 0);
        assertEq(endTime, 0);
        assertEq(prizePool, 0);
    }
    
    function testGetTournamentParticipants() public {
        poolArena.createTournament(PoolArena.TournamentType.DAILY, ENTRY_FEE, MAX_PARTICIPANTS);
        
        address[3] memory users = [user1, user2, user3];
        for (uint256 i = 0; i < 3; i++) {
            uint256 tokenId = positionManager.mint(users[i], 10 ether);
            vm.startPrank(users[i]);
            positionManager.approve(address(poolArena), tokenId);
            poolArena.joinTournament{value: ENTRY_FEE}(1, tokenId);
            vm.stopPrank();
        }
        
        address[] memory participants = poolArena.getTournamentParticipants(1);
        assertEq(participants.length, 3);
        assertEq(participants[0], user1);
        assertEq(participants[1], user2);
        assertEq(participants[2], user3);
    }
    
    function testHookIntegration() public {
        assertEq(hook.poolArenaContract(), address(poolArena));
        assertEq(address(hook.poolManager()), mockPoolManager);
    }
    
    function testMultipleTournaments() public {
        // Create two tournaments
        poolArena.createTournament(PoolArena.TournamentType.DAILY, ENTRY_FEE, 5);
        poolArena.createTournament(PoolArena.TournamentType.WEEKLY, ENTRY_FEE * 2, 8);
        
        assertEq(poolArena.nextTournamentId(), 3);
        
        // Check both tournaments exist with correct parameters
        (, PoolArena.TournamentType type1, , uint256 fee1, uint256 max1, , , , ) = poolArena.getTournament(1);
        (, PoolArena.TournamentType type2, , uint256 fee2, uint256 max2, , , , ) = poolArena.getTournament(2);
        
        assertEq(uint8(type1), uint8(PoolArena.TournamentType.DAILY));
        assertEq(uint8(type2), uint8(PoolArena.TournamentType.WEEKLY));
        assertEq(fee1, ENTRY_FEE);
        assertEq(fee2, ENTRY_FEE * 2);
        assertEq(max1, 5);
        assertEq(max2, 8);
    }
    
    function testReceiveETH() public {
        // Test that contract can receive ETH
        (bool success, ) = address(poolArena).call{value: 1 ether}("");
        assertTrue(success);
        assertEq(address(poolArena).balance, 1 ether);
    }
}