// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// TODO: update to v4-periphery/BaseHook.sol when its compatible
import {BaseHook} from "./forks/BaseHook.sol";

import {Hooks} from "@uniswap/v4-core/contracts/libraries/Hooks.sol";
import {IPoolManager} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/contracts/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/contracts/types/PoolId.sol";
import {BalanceDelta} from "@uniswap/v4-core/contracts/types/BalanceDelta.sol";

contract GasSubsidy is BaseHook {
    using PoolIdLibrary for PoolKey;

    // NOTE - Might need to import these libraries
    // using CurrencyLibrary for Currency;
    // using FixedPointMathLib for uint256;

    // NOTE: ---------------------------------------------------------
    // state variables should typically be unique to a pool
    // a single hook contract should be able to service multiple pools
    // ---------------------------------------------------------------

    uint256 averageGas = 30 gwei; // TODO - get the actual number from glassnode or something
    uint256 bottom20Percent = averageGas * 20 / 100; // 6 gwei, fyi I don't really need to store average gas
    uint256 top20Percent = averageGas * 80 / 100; // 24 gwei;

    mapping(PoolId => uint256) public subsidy; // the amount of subsidized ETH gas collected for a pool


    constructor(IPoolManager _poolManager) BaseHook(_poolManager) {}

    function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: false,
            beforeModifyPosition: false,
            afterModifyPosition: true,
            beforeSwap: false,
            afterSwap: true,
            beforeDonate: false,
            afterDonate: false,
            noOp: false, // QUESTION: what is this?
            accessLock: false // QUESTION: what is this?
        });
    }

    function afterSwap(address, PoolKey calldata key, IPoolManager.SwapParams calldata, BalanceDelta, bytes calldata)
        external
        override
        returns (bytes4)
    {
        
        return BaseHook.afterSwap.selector;
    }

    function afterModifyPosition(
        address,
        PoolKey calldata key,
        IPoolManager.ModifyPositionParams calldata,
        BalanceDelta,
        bytes calldata
    ) external override returns (bytes4) {
        // TODO
        return BaseHook.afterModifyPosition.selector;
    }
}
