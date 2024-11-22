# Reanswap

Reanswap - a Uniswap V2 clone for educational purposes only.

Based on the [Programming DeFi: Uniswap V2](https://jeiwan.net/posts/programming-defi-uniswapv2-1/) series.

## Installation

1. `git clone git@github.com:reanblock/reanswap.git`
1. Install Rust and Cargo as per the [Install Rust](https://www.rust-lang.org/tools/install) documentation.
1. Install Foundry using [these instructions](https://getfoundry.sh/)
1. Install dependency contracts: `forge install`
1. Run all tests to ensure everything is setup correctly: `forge test`

## Review

To run audit review tools first, change into `src`:

```
cd src
```

### Test

[Foundry Github](https://github.com/foundry-rs/foundry)

Use Fountry -> forge to build and run tests:

```
forge test
```

### SHA

Genearate `shasum` for all contracts:

```
find . -iname '*.sol' -exec shasum -a 256 {} \;
```

### Solhint

https://github.com/protofire/solhint

Run `solhint` for all contracts:

```
 solhint src/*.sol
```

### Slither

https://github.com/crytic/slither

```
docker run -it -v $(pwd):/share trailofbits/eth-security-toolbox
slither /share/src/ReanswapV2Factory.sol
```

### Mythril

https://github.com/ConsenSys/mythril

```
docker run -v $(pwd):/tmp mythril/myth analyze /tmp/src/ReanswapV2Factory.sol
```
