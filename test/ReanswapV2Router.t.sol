// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/ReanswapV2Factory.sol";
import "../src/ReanswapV2Pair.sol";
import "../src/ReanswapV2Router.sol";
import "./mocks/ERC20Mintable.sol";

contract ReanswapV2RouterTest is Test {
    ReanswapV2Factory factory;
    ReanswapV2Router router;

    ERC20Mintable tokenA;
    ERC20Mintable tokenB;
    ERC20Mintable tokenC;

    function setUp() public {
        factory = new ReanswapV2Factory();
        router = new ReanswapV2Router(address(factory));

        tokenA = new ERC20Mintable("Token A", "TKNA");
        tokenB = new ERC20Mintable("Token B", "TKNB");
        tokenC = new ERC20Mintable("Token C", "TKNC");

        tokenA.mint(20 ether, address(this));
        tokenB.mint(20 ether, address(this));
        tokenC.mint(20 ether, address(this));
    }

    function encodeError(string memory error)
        internal
        pure
        returns (bytes memory encoded)
    {
        encoded = abi.encodeWithSignature(error);
    }

    function testAddLiquidityCreatesPair() public {
        tokenA.approve(address(router), 1 ether);
        tokenB.approve(address(router), 1 ether);

        router.addLiquidity(
            address(tokenA),
            address(tokenB),
            1 ether,
            1 ether,
            1 ether,
            1 ether,
            address(this)
        );

        address pairAddress = factory.pairs(address(tokenA), address(tokenB));
        assertEq(pairAddress, 0xED7394184D1bd12E5fE23e076A6940EA905ED338);
    }
}