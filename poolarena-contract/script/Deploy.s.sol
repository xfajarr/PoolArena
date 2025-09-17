// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import "../src/PoolArena.sol";
import "../src/PoolArenaHookV2.sol";
import "../src/libraries/TournamentLib.sol";

contract DeployScript is Script {
    // Deployment addresses (update these for your specific network)
    address constant UNISWAP_V4_POOL_MANAGER = 0x0000000000000000000000000000000000000000; // Replace with actual
    address constant LP_NFT_CONTRACT = 0x0000000000000000000000000000000000000000; // Replace with actual
    address constant TREASURY_ADDRESS = 0x0000000000000000000000000000000000000000; // Replace with actual

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);
        
        console.log("Deploying PoolArena contracts...");
        console.log("Deployer address:", deployerAddress);
        console.log("Deployer balance:", deployerAddress.balance);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy PoolArenaHookV2 first
        PoolArenaHookV2 hook = new PoolArenaHookV2(
            IPoolManager(UNISWAP_V4_POOL_MANAGER)
        );
        
        console.log("PoolArenaHook deployed at:", address(hook));

        // Deploy PoolArena main contract
        PoolArena poolArena = new PoolArena(
            address(hook),
            LP_NFT_CONTRACT,
            TREASURY_ADDRESS
        );
        
        console.log("PoolArena deployed at:", address(poolArena));

        // Set PoolArena contract address in hook
        hook.setPoolArenaContract(address(poolArena));
        
        console.log("Hook configuration completed");

        vm.stopBroadcast();

        // Log deployment summary
        console.log("\n=== DEPLOYMENT SUMMARY ===");
        console.log("PoolArenaHook:", address(hook));
        console.log("PoolArena:", address(poolArena));
        console.log("Treasury:", TREASURY_ADDRESS);
        console.log("LP NFT Contract:", LP_NFT_CONTRACT);
        console.log("Pool Manager:", UNISWAP_V4_POOL_MANAGER);
        
        // Create a simple test tournament to verify deployment
        console.log("\n=== CREATING TEST TOURNAMENT ===");
        
        IPoolArena.TournamentConfig memory config = IPoolArena.TournamentConfig({
            entryFee: 0.002 ether,
            maxParticipants: 12,
            duration: 7 days,
            treasuryFee: 100, // 1%
            prizeDistribution: [uint256(7000), uint256(2000), uint256(1000)] // 70%, 20%, 10%
        });
        
        uint256 tournamentId = poolArena.createTournament(config);
        console.log("Test tournament created with ID:", tournamentId);
        
        console.log("\n=== DEPLOYMENT COMPLETED SUCCESSFULLY ===");
    }
}

contract DeployWithMocks is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);
        
        console.log("Deploying PoolArena contracts with mocks...");
        console.log("Deployer address:", deployerAddress);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy mock contracts for testing
        MockPoolManager mockPoolManager = new MockPoolManager();
        MockLPNFT mockLPNFT = new MockLPNFT();
        
        console.log("Mock Pool Manager deployed at:", address(mockPoolManager));
        console.log("Mock LP NFT deployed at:", address(mockLPNFT));

        // Deploy PoolArenaHookV2
        PoolArenaHookV2 hook = new PoolArenaHookV2(
            IPoolManager(address(mockPoolManager))
        );
        
        console.log("PoolArenaHook deployed at:", address(hook));

        // Deploy PoolArena main contract
        PoolArena poolArena = new PoolArena(
            address(hook),
            address(mockLPNFT),
            deployerAddress // Use deployer as treasury for testing
        );
        
        console.log("PoolArena deployed at:", address(poolArena));

        // Configure hook
        hook.setPoolArenaContract(address(poolArena));
        
        vm.stopBroadcast();

        console.log("\n=== MOCK DEPLOYMENT COMPLETED ===");
        console.log("PoolArenaHook:", address(hook));
        console.log("PoolArena:", address(poolArena));
        console.log("Mock Pool Manager:", address(mockPoolManager));
        console.log("Mock LP NFT:", address(mockLPNFT));
        console.log("Treasury (Deployer):", deployerAddress);
    }
}

// Simple mock contracts for testing
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
