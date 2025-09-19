// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/PoolArena.sol";

contract InteractWithPoolArena is Script {
    PoolArena poolArena;
    PoolArenaHook hook;
    address positionManager;
    address pyth;
    
    // Test users (will be generated from private keys)
    address user1;
    address user2;
    address user3;
    
    function run() external {
        // Load deployed contract addresses from environment
        address poolArenaAddress = vm.envAddress("POOL_ARENA");
        address hookAddress = vm.envAddress("POOL_ARENA_HOOK");
        positionManager = vm.envAddress("POSITION_MANAGER");
        pyth = vm.envAddress("PYTH_ORACLE");
        
        // Connect to deployed contracts
        poolArena = PoolArena(payable(poolArenaAddress));
        hook = PoolArenaHook(hookAddress);
        
        console.log("=== POOL ARENA CONTRACT INTERACTION ===");
        console.log("PoolArena Address:", poolArenaAddress);
        console.log("Hook Address:", hookAddress);
        console.log("Position Manager:", positionManager);
        console.log("Pyth Oracle:", pyth);
        
        // Generate test users
        user1 = vm.addr(1001);
        user2 = vm.addr(1002);
        user3 = vm.addr(1003);
        
        console.log("\nTest Users:");
        console.log("User1:", user1);
        console.log("User2:", user2);
        console.log("User3:", user3);
        
        // Start the interaction flow
        testFullWorkflow();
    }
    
    function testFullWorkflow() internal {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerKey);
        
        console.log("\n=== STEP 1: CREATE TOURNAMENT ===");
        vm.startBroadcast(deployerKey);
        
        // Create a tournament with 2 participants, 0.01 ETH entry fee
        uint256 entryFee = 0.01 ether;
        uint256 maxParticipants = 2;
        
        console.log("Creating tournament with:");
        console.log("- Type: DAILY");
        console.log("- Entry Fee: 0.01 ETH");
        console.log("- Max Participants: 2");
        
        poolArena.createTournament(
            PoolArena.TournamentType.DAILY,
            entryFee,
            maxParticipants
        );
        
        uint256 tournamentId = poolArena.nextTournamentId() - 1;
        console.log("Tournament created with ID:", tournamentId);
        
        vm.stopBroadcast();
        
        // Check tournament details
        console.log("\n=== STEP 2: VERIFY TOURNAMENT DETAILS ===");
        (
            uint256 id,
            PoolArena.TournamentType tournamentType,
            PoolArena.TournamentStatus status,
            uint256 fee,
            uint256 maxPart,
            uint256 currentPart,
            uint256 startTime,
            uint256 endTime,
            uint256 prizePool
        ) = poolArena.getTournament(tournamentId);
        
        console.log("Tournament Details:");
        console.log("- ID:", id);
        console.log("- Type:", uint8(tournamentType) == 0 ? "DAILY" : "WEEKLY");
        console.log("- Status:", getStatusString(status));
        console.log("- Entry Fee:", fee);
        console.log("- Max Participants:", maxPart);
        console.log("- Current Participants:", currentPart);
        console.log("- Prize Pool:", prizePool);
        
        console.log("\n=== STEP 3: FUND TEST USERS ===");
        // Fund test users with ETH
        vm.deal(user1, 1 ether);
        vm.deal(user2, 1 ether);
        vm.deal(user3, 1 ether);
        
        console.log("Funded users with 1 ETH each");
        
        console.log("\n=== STEP 4: MINT LP NFTS FOR USERS ===");
        // We need to mint LP NFTs for users to join the tournament
        // This would normally come from adding liquidity to Uniswap V4 pools
        // For testing, we'll use the mock position manager
        
        vm.startBroadcast(deployerKey);
        
        // Since we're using mock contracts, we can mint directly
        // In reality, users would need to add liquidity to pools first
        MockPositionManagerForDeploy mockPM = MockPositionManagerForDeploy(positionManager);
        
        uint256 tokenId1 = mockPM.mint(user1, 10 ether); // 10 ETH liquidity
        uint256 tokenId2 = mockPM.mint(user2, 15 ether); // 15 ETH liquidity
        uint256 tokenId3 = mockPM.mint(user3, 8 ether);  // 8 ETH liquidity
        
        console.log("Minted LP NFTs:");
        console.log("- User1 TokenId:", tokenId1, "with 10 ETH liquidity");
        console.log("- User2 TokenId:", tokenId2, "with 15 ETH liquidity");
        console.log("- User3 TokenId:", tokenId3, "with 8 ETH liquidity");
        
        vm.stopBroadcast();
        
        console.log("\n=== STEP 5: USERS JOIN TOURNAMENT ===");
        
        // User1 joins tournament
        vm.startBroadcast(1001); // Use test key directly
        vm.deal(user1, 1 ether); // Ensure user1 has ETH
        
        console.log("User1 joining tournament...");
        console.log("User1 balance before:", user1.balance);
        
        // First approve the NFT transfer
        mockPM.approve(address(poolArena), tokenId1);
        
        // Join tournament
        try poolArena.joinTournament{value: entryFee}(tournamentId, tokenId1) {
            console.log("User1 successfully joined tournament");
        } catch Error(string memory reason) {
            console.log("User1 failed to join:", reason);
        }
        
        vm.stopBroadcast();
        
        // User2 joins tournament
        vm.startBroadcast(1002); // Use test key directly
        vm.deal(user2, 1 ether); // Ensure user2 has ETH
        
        console.log("User2 joining tournament...");
        mockPM.approve(address(poolArena), tokenId2);
        
        try poolArena.joinTournament{value: entryFee}(tournamentId, tokenId2) {
            console.log("User2 successfully joined tournament");
            console.log("Tournament should now be full and auto-started!");
        } catch Error(string memory reason) {
            console.log("User2 failed to join:", reason);
        }
        
        vm.stopBroadcast();
        
        console.log("\n=== STEP 6: VERIFY TOURNAMENT STATUS AFTER JOINING ===");
        (, , status, , , currentPart, startTime, endTime, prizePool) = poolArena.getTournament(tournamentId);
        
        console.log("Tournament Status After Joining:");
        console.log("- Status:", getStatusString(status));
        console.log("- Current Participants:", currentPart);
        console.log("- Start Time:", startTime > 0 ? "Started" : "Not Started");
        console.log("- End Time:", endTime);
        console.log("- Prize Pool:", prizePool, "wei");
        
        // Try User3 joining full tournament (should fail)
        console.log("\n=== STEP 7: TEST JOINING FULL TOURNAMENT ===");
        vm.startBroadcast(1003); // Use test key directly
        vm.deal(user3, 1 ether);
        
        console.log("User3 trying to join full tournament...");
        mockPM.approve(address(poolArena), tokenId3);
        
        try poolArena.joinTournament{value: entryFee}(tournamentId, tokenId3) {
            console.log("User3 unexpectedly joined full tournament");
        } catch Error(string memory reason) {
            console.log("User3 correctly rejected:", reason);
        }
        
        vm.stopBroadcast();
        
        console.log("\n=== STEP 8: SIMULATE TIME PASSING ===");
        // Fast forward time to end of tournament
        vm.warp(block.timestamp + 1 days + 1);
        console.log("Fast-forwarded time by 1 day + 1 second");
        console.log("Current timestamp:", block.timestamp);
        
        console.log("\n=== STEP 9: FINISH TOURNAMENT ===");
        vm.startBroadcast(deployerKey);
        
        console.log("Attempting to finish tournament...");
        try poolArena.finishTournament(tournamentId) {
            console.log("Tournament finished successfully!");
        } catch Error(string memory reason) {
            console.log("Failed to finish tournament:", reason);
        }
        
        vm.stopBroadcast();
        
        console.log("\n=== STEP 10: VERIFY FINAL STATE ===");
        (, , status, , , , , , ) = poolArena.getTournament(tournamentId);
        
        console.log("Final Tournament Status:", getStatusString(status));
        console.log("User1 balance after:", user1.balance);
        console.log("User2 balance after:", user2.balance);
        
        // Check if NFTs were returned
        console.log("NFT ownership after tournament:");
        try mockPM.ownerOf(tokenId1) returns (address owner1) {
            console.log("- TokenId1 owner:", owner1, owner1 == user1 ? "(returned to user1)" : "(not returned)");
        } catch {
            console.log("- TokenId1: Error getting owner");
        }
        
        try mockPM.ownerOf(tokenId2) returns (address owner2) {
            console.log("- TokenId2 owner:", owner2, owner2 == user2 ? "(returned to user2)" : "(not returned)");
        } catch {
            console.log("- TokenId2: Error getting owner");
        }
        
        console.log("\n=== WORKFLOW COMPLETED ===");
        console.log("Check the logs above to see how the PoolArena contract works!");
    }
    
    function getStatusString(PoolArena.TournamentStatus status) internal pure returns (string memory) {
        if (status == PoolArena.TournamentStatus.PENDING) return "PENDING";
        if (status == PoolArena.TournamentStatus.ACTIVE) return "ACTIVE";
        if (status == PoolArena.TournamentStatus.FINISHED) return "FINISHED";
        if (status == PoolArena.TournamentStatus.CANCELLED) return "CANCELLED";
        return "UNKNOWN";
    }
}

// Import the mock contract from deployment script
contract MockPositionManagerForDeploy {
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    
    uint256 public nextTokenId = 1;
    
    function mint(address to, uint256 liquidity) external returns (uint256) {
        uint256 tokenId = nextTokenId++;
        _owners[tokenId] = to;
        _balances[to]++;
        return tokenId;
    }
    
    function ownerOf(uint256 tokenId) external view returns (address) {
        return _owners[tokenId];
    }
    
    function approve(address to, uint256 tokenId) external {
        _tokenApprovals[tokenId] = to;
    }
    
    function safeTransferFrom(address from, address to, uint256 tokenId) external {
        require(_owners[tokenId] == from, "Not owner");
        require(_tokenApprovals[tokenId] == msg.sender || msg.sender == from, "Not approved");
        
        _balances[from]--;
        _balances[to]++;
        _owners[tokenId] = to;
        delete _tokenApprovals[tokenId];
    }
}