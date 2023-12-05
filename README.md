# Uniswap V4 Gas Subsidy
This contract will take charge swappers and liquidity providers more gas when gas is cheap, and this gas will be stored and saved to be used when gas is high.

**Why is this useful?**
- A DEX is a product, and when the product becomes MORE expensive to use at the peak time, it makes for a bad user experience.
- It could also potentially drive more trading to this DEX.
- Most traders do not care about the gas fees unless they are insanely high. If a swap costs on average $3, and they are getting it for $1 on a sunday in the middle of the night, they won't care if it's $1.25. 

**Why am I building it**
- This will not go into production, I want to build a hook that is small enough to implement in a few days, that has some benefit. Not sure if it would have real use, as there are problems (see below)  

**Problems**
- Bots will just take advantage of the gas subsidy and drain it pretty quick during high times
- In an extreme event, months of subsidy could be drained in a few minutes or hours, or it could be such a small subsidy that it is almost unnoticable, making the whole design moot. The math could be worked out to try to optimize if, but if the event is extreme enough it probably wouldn't matter

## Design
- Get the average gas price cost on ethereum since the launch of uniswao v2, for a long enough average.
- The bottom 20% of transactions must pay a 10% premium of ETH in gas
- The top 20% of transactions get a 10% reduction in gas on their costs, until the subsidy runs out
- The numbers I chose are arbitrary, nothing concrete behind them, as this is not going to be production code. 

## Set up

*requires [foundry](https://book.getfoundry.sh)*

```
forge install
forge test
```

## Local Development (Anvil)

Because v4 depends on TSTORE and its *business licensed*, you can only deploy & test hooks on [anvil](https://book.getfoundry.sh/anvil/)

```bash
# start anvil with TSTORE support
# (`foundryup`` to update if cancun is not an option)
anvil --hardfork cancun

# in a new terminal
forge script script/Anvil.s.sol \
    --rpc-url http://localhost:8545 \
    --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
    --broadcast
```


## v4-template Information
[`Use this Template`](https://github.com/saucepoint/v4-template/generate)

1. The example hook [Counter.sol](src/Counter.sol) demonstrates the `beforeSwap()` and `afterSwap()` hooks
2. The test template [Counter.t.sol](test/Counter.t.sol) preconfigures the v4 pool manager, test tokens, and test liquidity.
3. The scripts in the v4-template are written so that you can
   - Designed for Goerli, but usable for other networks
   - Deploy a hook contract
   - Create a liquidity pool on V4
   - Add liquidity to a pool
   - Swap tokens on a pool
4. This template is built using Foundry

### Updating to v4-template:latest

This template is actively maintained -- you can update the v4 dependencies, scripts, and helpers: 
```bash
git remote add template https://github.com/uniswapfoundation/v4-template
git fetch template
git merge template/main <BRANCH> --allow-unrelated-histories
```

