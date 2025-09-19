// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/PoolArena.sol";
import {Hooks} from "v4-core/libraries/Hooks.sol";
import {HookMiner} from "v4-periphery/src/utils/HookMiner.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {PythStructs} from "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";

contract DeployPoolArena is Script {
    // Unichain Sepolia addresses
    address constant UNICHAIN_SEPOLIA_POOL_MANAGER = 0x38EB8B22Df3Ae7fb21e92881151B365Df14ba967;
    address constant UNICHAIN_SEPOLIA_POSITION_MANAGER = 0x1B1C77B606d13b09C84d1c7394B96b147bC03147;
    address constant UNICHAIN_SEPOLIA_PYTH = 0xA2aa501b19aff244D90cc15a4Cf739D2725B5729;
    
    // If the above addresses don't exist, use mock addresses for testing
    bool constant USE_MOCK_ADDRESSES = true;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Deploying contracts with deployer:", deployer);
        console.log("Deployer balance:", deployer.balance);
        
        vm.startBroadcast(deployerPrivateKey);
        
        address poolManager;
        address positionManager;
        address pyth;
        
        if (USE_MOCK_ADDRESSES) {
            // Deploy mock contracts for testing
            console.log("Deploying mock contracts...");
            
            // Deploy mock position manager (simple ERC721-like contract)
            positionManager = address(new MockPositionManagerForDeploy());
            console.log("Mock Position Manager deployed at:", positionManager);
            
            // Deploy mock Pyth oracle
            pyth = address(new MockPythForDeploy());
            console.log("Mock Pyth deployed at:", pyth);
            
            // Use a mock pool manager address
            poolManager = address(0x1234567890123456789012345678901234567890);
            console.log("Using mock Pool Manager at:", poolManager);
        } else {
            // Use real Unichain Sepolia addresses
            poolManager = UNICHAIN_SEPOLIA_POOL_MANAGER;
            positionManager = UNICHAIN_SEPOLIA_POSITION_MANAGER;
            pyth = UNICHAIN_SEPOLIA_PYTH;
            
            console.log("Using real Unichain Sepolia addresses:");
            console.log("Pool Manager:", poolManager);
            console.log("Position Manager:", positionManager);
            console.log("Pyth Oracle:", pyth);
        }
        
        // Calculate the correct hook address with required permissions
        uint160 permissions = uint160(
            Hooks.BEFORE_ADD_LIQUIDITY_FLAG | 
            Hooks.BEFORE_REMOVE_LIQUIDITY_FLAG | 
            Hooks.AFTER_SWAP_FLAG
        );
        
        console.log("Calculating hook address with permissions:", permissions);
        
        // Find a salt that will produce the correct address
        (address expectedHookAddress, bytes32 salt) = HookMiner.find(
            deployer,
            permissions,
            type(PoolArenaHook).creationCode,
            abi.encode(poolManager)
        );
        
        console.log("Expected hook address:", expectedHookAddress);
        console.log("Salt:", vm.toString(salt));
        
        // Deploy the hook to the expected address
        PoolArenaHook hook = new PoolArenaHook{salt: salt}(IPoolManager(poolManager));
        console.log("PoolArenaHook deployed at:", address(hook));
        require(address(hook) == expectedHookAddress, "Hook address mismatch");
        
        // Deploy main PoolArena contract
        PoolArena poolArena = new PoolArena(
            positionManager,
            pyth,
            address(hook)
        );
        console.log("PoolArena deployed at:", address(poolArena));
        
        // Link hook to pool arena
        hook.setPoolArenaContract(address(poolArena));
        console.log("Hook linked to PoolArena");
        
        vm.stopBroadcast();
        
        // Save deployment addresses
        console.log("\n=== DEPLOYMENT SUMMARY ===");
        console.log("Deployer:", deployer);
        console.log("PoolArena:", address(poolArena));
        console.log("PoolArenaHook:", address(hook));
        console.log("Position Manager:", positionManager);
        console.log("Pyth Oracle:", pyth);
        console.log("Pool Manager:", poolManager);
        console.log("\n=== SAVE THESE ADDRESSES ===");
        
        // Write addresses to file for later use
        string memory addresses = string.concat(
            "POOL_ARENA=", vm.toString(address(poolArena)), "\n",
            "POOL_ARENA_HOOK=", vm.toString(address(hook)), "\n",
            "POSITION_MANAGER=", vm.toString(positionManager), "\n",
            "PYTH_ORACLE=", vm.toString(pyth), "\n",
            "POOL_MANAGER=", vm.toString(poolManager), "\n",
            "DEPLOYER=", vm.toString(deployer), "\n"
        );
        
        vm.writeFile("./deployment-addresses.env", addresses);
        console.log("Addresses written to deployment-addresses.env");
    }
}

// Mock contracts for testing deployment
contract MockPositionManagerForDeploy {
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    
    uint256 public nextTokenId = 1;
    mapping(uint256 => uint256) public positionLiquidity;
    mapping(uint256 => uint256) public accumulatedFees;
    
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    
    function mint(address to, uint256 liquidity) external returns (uint256) {
        uint256 tokenId = nextTokenId++;
        _owners[tokenId] = to;
        _balances[to]++;
        positionLiquidity[tokenId] = liquidity;
        accumulatedFees[tokenId] = liquidity / 100;
        
        emit Transfer(address(0), to, tokenId);
        return tokenId;
    }
    
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
    
    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == 0x80ac58cd || interfaceId == 0x01ffc9a7; // ERC721 + ERC165
    }
    
    function _transfer(address from, address to, uint256 tokenId) internal {
        require(_owners[tokenId] == from, "Not owner");
        require(
            msg.sender == from || 
            _tokenApprovals[tokenId] == msg.sender,
            "Not approved"
        );
        
        _balances[from]--;
        _balances[to]++;
        _owners[tokenId] = to;
        delete _tokenApprovals[tokenId];
        
        emit Transfer(from, to, tokenId);
    }
}

contract MockPythForDeploy {
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
    
    function getValidTimePeriod() external pure returns (uint256) {
        return 60;
    }
}