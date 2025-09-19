// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {BaseHook} from "v4-periphery/src/utils/BaseHook.sol";
import {BeforeSwapDelta} from "v4-core/types/BeforeSwapDelta.sol";
import {Hooks} from "v4-core/libraries/Hooks.sol";
import {IHooks} from "v4-core/interfaces/IHooks.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "v4-core/types/PoolId.sol";
import {BalanceDelta} from "v4-core/types/BalanceDelta.sol";

interface IPoolArena {
    function checkLiquidityModification(PoolId poolId, address sender) external view;
    function trackSwapFees(PoolId poolId, BalanceDelta delta) external;
}

/**
 * @title PoolArenaHook
 * @dev Custom Uniswap V4 Hook for tracking LP fee generation during tournaments
 */
contract PoolArenaHook is IHooks {
    using PoolIdLibrary for PoolKey;

    IPoolManager public immutable poolManager;
    address public poolArenaContract;

    // Track fee accumulation per pool per tournament
    mapping(PoolId => mapping(uint256 => mapping(address => uint256))) public tournamentFees;

    event FeeTracked(PoolId indexed poolId, uint256 indexed tournamentId, address indexed participant, uint256 fees);

    constructor(IPoolManager _poolManager) {
        poolManager = _poolManager;

        // Validate hook permissions in the constructor
        Hooks.validateHookPermissions(
            this,
            Hooks.Permissions({
                beforeInitialize: false,
                afterInitialize: false,
                beforeAddLiquidity: true,
                afterAddLiquidity: false,
                beforeRemoveLiquidity: true,
                afterRemoveLiquidity: false,
                beforeSwap: false,
                afterSwap: true,
                beforeDonate: false,
                afterDonate: false,
                beforeSwapReturnDelta: false,
                afterSwapReturnDelta: false,
                afterAddLiquidityReturnDelta: false,
                afterRemoveLiquidityReturnDelta: false
            })
        );
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
        BalanceDelta, // feesAccrued
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
        BalanceDelta, // feesAccrued
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
