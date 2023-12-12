// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

// forge
import "forge-std/Test.sol";

// Interfaces
import {IHooks} from "@uniswap/v4-core/contracts/interfaces/IHooks.sol";
import {IPoolManager} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
// Libraries
import {Hooks} from "@uniswap/v4-core/contracts/libraries/Hooks.sol";
import {TickMath} from "@uniswap/v4-core/contracts/libraries/TickMath.sol";
import {PoolKey} from "@uniswap/v4-core/contracts/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/contracts/types/PoolId.sol";
import {BalanceDelta} from "@uniswap/v4-core/contracts/types/BalanceDelta.sol";
import {CurrencyLibrary, Currency} from "v4-core/types/Currency.sol";

// Constants
import {Constants} from "@uniswap/v4-core/contracts/../test/utils/Constants.sol";
//Utils
import {HookTest} from "./utils/HookTest.sol";
import {HookMiner} from "./utils/HookMiner.sol";
// Our contracts
import {GasSubsidy} from "../src/GasSubsidy.sol";

contract GasSubsidyTest is HookTest {
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;

    GasSubsidy gasSubsidy;
    PoolKey poolKey;
    PoolId poolId;

    uint256 subsidyAmount = 0.005 ether;

    function setUp() public {
        // creates the pool manager, test tokens, and other utility routers
        HookTest.initHookTestEnv();

        // Deploy the hook to an address with the correct flags
        uint160 flags = uint160(Hooks.AFTER_SWAP_FLAG | Hooks.AFTER_MODIFY_POSITION_FLAG);
        (address hookAddress, bytes32 salt) =
            HookMiner.find(address(this), flags, type(GasSubsidy).creationCode, abi.encode(address(manager)));
        gasSubsidy = new GasSubsidy{salt: salt}(IPoolManager(address(manager)));
        require(address(gasSubsidy) == hookAddress, "CounterTest: hook address mismatch");

        // Create the pool
        poolKey = PoolKey(Currency.wrap(address(token0)), Currency.wrap(address(token1)), 3000, 60, IHooks(gasSubsidy));
        poolId = poolKey.toId();
        initializeRouter.initialize(poolKey, Constants.SQRT_RATIO_1_1, ZERO_BYTES);

        // Provide liquidity to the pool
        vm.txGasPrice(30 gwei); // As to not trigger afterModifyPosition transfer of subsidy
        modifyPositionRouter.modifyPosition(poolKey, IPoolManager.ModifyPositionParams(-60, 60, 10 ether), ZERO_BYTES);
        modifyPositionRouter.modifyPosition(poolKey, IPoolManager.ModifyPositionParams(-120, 120, 10 ether), ZERO_BYTES);
        modifyPositionRouter.modifyPosition(
            poolKey,
            IPoolManager.ModifyPositionParams(TickMath.minUsableTick(60), TickMath.maxUsableTick(60), 10 ether),
            ZERO_BYTES
        );
    }

    // Note - Contract context goes: --> Swap Router --> Manager --> Swap Router --> Manager --> Gas Subsidy Hook.
    function testAfterSwapLowGasPrice() public {
        vm.txGasPrice(5 gwei); // Use Foundry's VM to set a low gas price

        uint256 beforeBalTest = address(this).balance;
        uint256 balBeforeHook = address(gasSubsidy).balance;
        uint256 balBeforeManager = address(manager).balance;
        uint256 beforeRouter = address(swapRouter).balance;

        // Perform a test swap
        int256 amount = 100;
        bool zeroForOne = true;
        BalanceDelta swapDelta = swap(poolKey, amount, zeroForOne, ZERO_BYTES, subsidyAmount);

        assertEq(int256(swapDelta.amount0()), amount);
        assertEq(address(this).balance, beforeBalTest - subsidyAmount, "Sender fail");
        assertEq(address(gasSubsidy).balance, balBeforeHook + subsidyAmount, "Hook fail");

        // Sanity checks - the ETH should be going from the sender to the hook
        // But the passing back and forth between contracts is finicky
        assertEq(address(swapRouter).balance, beforeRouter, "Router fail");
        assertEq(address(manager).balance, balBeforeManager, "Manager fail");
    }

    // function testAfterSwapHighGasPrice() public {
    //     vm.txGasPrice(50 gwei); // Use Foundry's VM to set a low gas price

    //     uint256 beforeBalTest = address(this).balance;
    //     uint256 balBeforeHook = address(gasSubsidy).balance;
    //     uint256 balBeforeManager = address(manager).balance;
    //     uint256 beforeRouter = address(swapRouter).balance;

    //     // Perform a test swap
    //     int256 amount = 100;
    //     bool zeroForOne = true;
    //     BalanceDelta swapDelta = swap(poolKey, amount, zeroForOne, ZERO_BYTES, subsidyAmount);

    //     assertEq(int256(swapDelta.amount0()), amount);
    //     assertEq(address(this).balance, beforeBalTest - subsidyAmount, "Sender fail");
    //     assertEq(address(gasSubsidy).balance, balBeforeHook + subsidyAmount, "Hook fail");

    //     // Sanity checks - the ETH should be going from the sender to the hook
    //     // But the passing back and forth between contracts is finicky
    //     assertEq(address(swapRouter).balance, beforeRouter, "Router fail");
    //     assertEq(address(manager).balance, balBeforeManager, "Manager fail");
    // }

    function testAfterSwapNormalGasPrice() public {
        vm.txGasPrice(30 gwei); // Use Foundry's VM to set gas right in the middle

        uint256 beforeBalTest = address(msg.sender).balance;
        uint256 balBeforeHook = address(gasSubsidy).balance;
        uint256 balBeforeManager = address(manager).balance;
        uint256 beforeRouter = address(swapRouter).balance;

        // Perform a test swap
        int256 amount = 100;
        bool zeroForOne = true;
        BalanceDelta swapDelta = swap(poolKey, amount, zeroForOne, ZERO_BYTES, subsidyAmount);

        assertEq(int256(swapDelta.amount0()), amount);
        assertEq(address(msg.sender).balance, beforeBalTest, "Sender fail");
        assertEq(address(gasSubsidy).balance, balBeforeHook, "Hook fail");

        // Sanity checks - the ETH should be going from the sender to the hook
        // But the passing back and forth between contracts is finicky
        assertEq(address(swapRouter).balance, beforeRouter, "Router fail");
        assertEq(address(manager).balance, balBeforeManager, "Manager fail");
    }

    // function testAfterModifyPosition() public {
    //     // Similar to testAfterSwap, implement tests for afterModifyPosition
    //     // You will need to simulate different gas price scenarios and check the Ether transfers
    // }
}
