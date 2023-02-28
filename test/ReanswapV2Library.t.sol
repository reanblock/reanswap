// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/ReanswapV2Library.sol";
import "../src/ReanswapV2Factory.sol";
import "../src/ReanswapV2Pair.sol";
import "./mocks/ERC20Mintable.sol";

contract ReanswapV2LibraryTest is Test {
    ReanswapV2Factory factory;

    ERC20Mintable tokenA;
    ERC20Mintable tokenB;
    ERC20Mintable tokenC;
    ERC20Mintable tokenD;

    ReanswapV2Pair pair;
    ReanswapV2Pair pair2;
    ReanswapV2Pair pair3;

    function encodeError(string memory error)
        internal
        pure
        returns (bytes memory encoded)
    {
        encoded = abi.encodeWithSignature(error);
    }

    function setUp() public {
        factory = new ReanswapV2Factory();

        tokenA = new ERC20Mintable("TokenA", "TKNA");
        tokenB = new ERC20Mintable("TokenB", "TKNB");
        tokenC = new ERC20Mintable("TokenC", "TKNC");
        tokenD = new ERC20Mintable("TokenD", "TKND");

        tokenA.mint(10 ether, address(this));
        tokenB.mint(10 ether, address(this));
        tokenC.mint(10 ether, address(this));
        tokenD.mint(10 ether, address(this));

        address pairAddress = factory.createPair(
            address(tokenA),
            address(tokenB)
        );
        pair = ReanswapV2Pair(pairAddress);

        pairAddress = factory.createPair(address(tokenB), address(tokenC));
        pair2 = ReanswapV2Pair(pairAddress);

        pairAddress = factory.createPair(address(tokenC), address(tokenD));
        pair3 = ReanswapV2Pair(pairAddress);
    }

    function testGetReserves() public {
        tokenA.transfer(address(pair), 1.1 ether);
        tokenB.transfer(address(pair), 0.8 ether);

        ReanswapV2Pair(address(pair)).mint(address(this));

        (uint256 reserve0, uint256 reserve1) = ReanswapV2Library.getReserves(
            address(factory),
            address(tokenA),
            address(tokenB)
        );

        assertEq(reserve0, 1.1 ether);
        assertEq(reserve1, 0.8 ether);
    }

    function testQuote() public {
        uint256 amountOut = ReanswapV2Library.quote(1 ether, 1 ether, 1 ether);
        assertEq(amountOut, 1 ether);

        amountOut = ReanswapV2Library.quote(1 ether, 2 ether, 1 ether);
        assertEq(amountOut, 0.5 ether);

        amountOut = ReanswapV2Library.quote(1 ether, 1 ether, 2 ether);
        assertEq(amountOut, 2 ether);
    }

    function testPairFor() public {
        address pairAddress = ReanswapV2Library.pairFor(
            address(factory),
            address(tokenA),
            address(tokenB)
        );

        assertEq(pairAddress, factory.pairs(address(tokenA), address(tokenB)));
    }

    function testPairForTokensSorting() public {
        address pairAddress = ReanswapV2Library.pairFor(
            address(factory),
            address(tokenB),
            address(tokenA)
        );

        assertEq(pairAddress, factory.pairs(address(tokenA), address(tokenB)));
    }

    function testPairForNonexistentFactory() public {
        address pairAddress = ReanswapV2Library.pairFor(
            address(0xaabbcc),
            address(tokenB),
            address(tokenA)
        );

        assertEq(pairAddress, 0x4a311C1e8ad8BeA8Cb696b7d82a5f276A71dc589);
    }

    function testGetAmountOut() public {
        uint256 amountOut = ReanswapV2Library.getAmountOut(
            1000,
            1 ether,
            1.5 ether
        );
        assertEq(amountOut, 1495);
    }    
}