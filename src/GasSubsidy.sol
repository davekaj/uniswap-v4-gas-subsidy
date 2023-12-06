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

    // Lets say the average swap costs $10 in USD from the bottom of https://dune.com/KARTOD/Uniswap-Gas-price
    // Then at 2300 USD per ETH, that is 0.004347826 ETH per swap
    // Lets round up to 0.005 ETH
    uint256 subsidyAmount = 0.005 ether;

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
        _transferSubsidy();
        return BaseHook.afterSwap.selector;
    }

    function afterModifyPosition(
        address,
        PoolKey calldata key,
        IPoolManager.ModifyPositionParams calldata,
        BalanceDelta,
        bytes calldata
    ) external override returns (bytes4) {
        _transferSubsidy();
        return BaseHook.afterModifyPosition.selector;
    }

    // ---------------------------------- Helper Functions ----------------------------------
    // Function to handle Ether transfer based on gas price
    function _transferSubsidy() internal payable {
        uint256 gasPrice = tx.gasprice;

        if (gasPrice < bottom20Percent) {
            // If gas price is less than bottom 20%, transfer 0.005 ETH from sender to contract
            require(msg.value >= subsidyAmount, "Insufficient ETH sent");
        } else if (gasPrice > top20Percent) {
            // If gas price is greater than top 20%, transfer 0.005 ETH from contract to sender
            require(address(this).balance >= subsidyAmount, "Insufficient contract balance");
            payable(msg.sender).transfer(subsidyAmount);
        }
        // If gas price is between bottom20Percent and top20Percent, do nothing
    }

    // Function to allow the contract to receive Ether
    receive() external payable {}

    function gasPrice() public {
        return tx.gasprice;
    }

    // don't think I need gasLeft()

    // function getGasPriceInEther() public view returns (uint256) {
    //     return lastGasPrice / 1e18;
    // }
}
