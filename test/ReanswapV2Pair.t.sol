// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/ReanswapV2Pair.sol";
import "../src/interfaces/IReanswapV2Pair.sol";
import "./mocks/ERC20Mintable.sol";

contract ReanswapV2PairTest is Test {
    ERC20Mintable token0;
    ERC20Mintable token1;
    ReanswapV2Pair pair;
    TestUser testUser;

    function setUp() public {
        testUser = new TestUser();

        token0 = new ERC20Mintable("Token A", "TKNA");
        token1 = new ERC20Mintable("Token B", "TKNB");
        pair = new ReanswapV2Pair();
        IReanswapV2Pair(address(pair)).initialize(address(token0), address(token1));

        token0.mint(10 ether, address(this));
        token1.mint(10 ether, address(this));

        token0.mint(10 ether, address(testUser));
        token1.mint(10 ether, address(testUser));
    }

    function testMintBootstrap() public {
        token0.transfer(address(pair), 1 ether);
        token1.transfer(address(pair), 1 ether);

        pair.mint(address(this));

        assertEq(pair.balanceOf(address(this)), 1 ether - 1000);
        assertReserves(1 ether, 1 ether);
        assertEq(pair.totalSupply(), 1 ether);
    }

    function testMintWhenTheresLiquidity() public {
        token0.transfer(address(pair), 1 ether);
        token1.transfer(address(pair), 1 ether);

        pair.mint(address(this)); // + 1 LP

        token0.transfer(address(pair), 2 ether);
        token1.transfer(address(pair), 2 ether);

        pair.mint(address(this)); // + 2 LP

        assertEq(pair.balanceOf(address(this)), 3 ether - 1000);
        assertEq(pair.totalSupply(), 3 ether);
        assertReserves(3 ether, 3 ether);
    }

    function testMintUnbalanced() public {
        token0.transfer(address(pair), 1 ether);
        token1.transfer(address(pair), 1 ether);

        pair.mint(address(this)); // + 1 LP
        assertEq(pair.balanceOf(address(this)), 1 ether - 1000);
        assertReserves(1 ether, 1 ether);

        token0.transfer(address(pair), 2 ether);
        token1.transfer(address(pair), 1 ether);

        pair.mint(address(this)); // + 1 LP
        assertEq(pair.balanceOf(address(this)), 2 ether - 1000);
        assertReserves(3 ether, 2 ether);
    }

    function testMintZeroLiquidity() public {
        token0.transfer(address(pair), 1000);
        token1.transfer(address(pair), 1000);

        vm.expectRevert(encodeError("InsufficientLiquidityMinted()"));
        pair.mint(address(this));
    }

    function testBurn() public {
        token0.transfer(address(pair), 1 ether);
        token1.transfer(address(pair), 1 ether);

        pair.mint(address(this));
        uint256 liquidity = pair.balanceOf(address(this));
        pair.transfer(address(pair), liquidity);
        pair.burn(address(this));

        assertEq(pair.balanceOf(address(this)), 0);
        assertReserves(1000, 1000);
        assertEq(pair.totalSupply(), 1000);
        assertEq(token0.balanceOf(address(this)), 10 ether - 1000);
        assertEq(token1.balanceOf(address(this)), 10 ether - 1000);
    }

    function testBurnUnbalanced() public {
        token0.transfer(address(pair), 1 ether);
        token1.transfer(address(pair), 1 ether);

        pair.mint(address(this));

        token0.transfer(address(pair), 2 ether);
        token1.transfer(address(pair), 1 ether);

        pair.mint(address(this)); // + 1 LP

        uint256 liquidity = pair.balanceOf(address(this));
        pair.transfer(address(pair), liquidity);
        pair.burn(address(this));

        assertEq(pair.balanceOf(address(this)), 0);
        assertReserves(1500, 1000);
        assertEq(pair.totalSupply(), 1000);
        assertEq(token0.balanceOf(address(this)), 10 ether - 1500);
        assertEq(token1.balanceOf(address(this)), 10 ether - 1000);
    }

    function testBurnUnbalancedDifferentUsers() public {
        testUser.provideLiquidity(
            address(pair),
            address(token0),
            address(token1),
            1 ether,
            1 ether
        );

        assertEq(pair.balanceOf(address(this)), 0);
        assertEq(pair.balanceOf(address(testUser)), 1 ether - 1000);
        assertEq(pair.totalSupply(), 1 ether);

        token0.transfer(address(pair), 2 ether);
        token1.transfer(address(pair), 1 ether);

        pair.mint(address(this)); // + 1 LP

        assertEq(pair.balanceOf(address(this)), 1 ether);

        uint256 liquidity = pair.balanceOf(address(this));
        pair.transfer(address(pair), liquidity);
        pair.burn(address(this));

        assertEq(pair.balanceOf(address(this)), 0);
        assertReserves(1.5 ether, 1 ether);
        assertEq(pair.totalSupply(), 1 ether);
        assertEq(token0.balanceOf(address(this)), 10 ether - 0.5 ether);
        assertEq(token1.balanceOf(address(this)), 10 ether);

        // console.log("TestUser Token0 balance (before): ", token0.balanceOf(address(testUser)));

        // confirm the test user gets the 0.5 ether lost by the bad lp actor!
        changePrank(address(testUser));
        liquidity = pair.balanceOf(address(testUser));
        // console.log("TestUser transfers liquidity: ", liquidity);
        pair.transfer(address(pair), liquidity);
        pair.burn(address(testUser));

        assertEq(token0.balanceOf(address(testUser)), 10 ether + 0.5 ether - 1500);

        // console.log("TestUser Token0 balance (after): ", token0.balanceOf(address(testUser)));
    }

    function testSwapBasicScenario() public {
        token0.transfer(address(pair), 1 ether);
        token1.transfer(address(pair), 2 ether);
        pair.mint(address(this));

        uint256 amountOut = 0.181322178776029826 ether;
        token0.transfer(address(pair), 0.1 ether);
        pair.swap(0, amountOut, address(this), "");

        assertEq(
            token0.balanceOf(address(this)),
            10 ether - 1 ether - 0.1 ether,
            "unexpected token0 balance"
        );
        assertEq(
            token1.balanceOf(address(this)),
            10 ether - 2 ether + amountOut,
            "unexpected token1 balance"
        );
        assertReserves(1 ether + 0.1 ether, 2 ether - amountOut);
    }

    function testSwapBasicScenarioReverseDirection() public {
        token0.transfer(address(pair), 1 ether);
        token1.transfer(address(pair), 2 ether);
        pair.mint(address(this));

        uint256 amountOut = 0.09 ether;
        token1.transfer(address(pair), 0.2 ether);
        pair.swap(amountOut, 0, address(this), "");

        assertEq(
            token0.balanceOf(address(this)),
            10 ether - 1 ether + amountOut,
            "unexpected token0 balance"
        );
        assertEq(
            token1.balanceOf(address(this)),
            10 ether - 2 ether - 0.2 ether,
            "unexpected token1 balance"
        );
        assertReserves(1 ether - amountOut, 2 ether + 0.2 ether);
    }

    function testSwapBidirectional() public {
        token0.transfer(address(pair), 1 ether);
        token1.transfer(address(pair), 2 ether);
        pair.mint(address(this));

        token0.transfer(address(pair), 0.1 ether);
        token1.transfer(address(pair), 0.2 ether);
        pair.swap(0.09 ether, 0.18 ether, address(this), "");

        assertEq(
            token0.balanceOf(address(this)),
            10 ether - 1 ether - 0.01 ether,
            "unexpected token0 balance"
        );
        assertEq(
            token1.balanceOf(address(this)),
            10 ether - 2 ether - 0.02 ether,
            "unexpected token1 balance"
        );
        assertReserves(1 ether + 0.01 ether, 2 ether + 0.02 ether);
    }

    function testSwapZeroOut() public {
        token0.transfer(address(pair), 1 ether);
        token1.transfer(address(pair), 2 ether);
        pair.mint(address(this));

        vm.expectRevert(encodeError("InsufficientOutputAmount()"));
        pair.swap(0, 0, address(this), "");
    }

    function testSwapInsufficientLiquidity() public {
        token0.transfer(address(pair), 1 ether);
        token1.transfer(address(pair), 2 ether);
        pair.mint(address(this));

        vm.expectRevert(encodeError("InsufficientLiquidity()"));
        pair.swap(0, 2.1 ether, address(this), "");

        vm.expectRevert(encodeError("InsufficientLiquidity()"));
        pair.swap(1.1 ether, 0, address(this), "");
    }

    function testSwapUnderpriced() public {
        token0.transfer(address(pair), 1 ether);
        token1.transfer(address(pair), 2 ether);
        pair.mint(address(this));

        token0.transfer(address(pair), 0.1 ether);
        pair.swap(0, 0.09 ether, address(this), "");

        assertEq(
            token0.balanceOf(address(this)),
            10 ether - 1 ether - 0.1 ether,
            "unexpected token0 balance"
        );
        assertEq(
            token1.balanceOf(address(this)),
            10 ether - 2 ether + 0.09 ether,
            "unexpected token1 balance"
        );
        assertReserves(1 ether + 0.1 ether, 2 ether - 0.09 ether);
    }

    function testSwapOverpriced() public {
        token0.transfer(address(pair), 1 ether);
        token1.transfer(address(pair), 2 ether);
        pair.mint(address(this));

        token0.transfer(address(pair), 0.1 ether);

        vm.expectRevert(encodeError("InvalidK()"));
        pair.swap(0, 0.36 ether, address(this), "");

        assertEq(
            token0.balanceOf(address(this)),
            10 ether - 1 ether - 0.1 ether,
            "unexpected token0 balance"
        );
        assertEq(
            token1.balanceOf(address(this)),
            10 ether - 2 ether,
            "unexpected token1 balance"
        );
        assertReserves(1 ether, 2 ether);
    }

    function testSwapUnpaidFee() public {
        token0.transfer(address(pair), 1 ether);
        token1.transfer(address(pair), 2 ether);
        pair.mint(address(this));

        token0.transfer(address(pair), 0.1 ether);

        vm.expectRevert(encodeError("InvalidK()"));
        pair.swap(0, 0.181322178776029827 ether, address(this), "");
    }

    function testFlashloan() public {
        token0.transfer(address(pair), 1 ether);
        token1.transfer(address(pair), 2 ether);
        pair.mint(address(this));

        uint256 flashloanAmount = 0.1 ether;
        uint256 flashloanFee = (flashloanAmount * 1000) / 997 - flashloanAmount + 1;

        Flashloaner fl = new Flashloaner();

        token1.transfer(address(fl), flashloanFee);

        fl.flashloan(address(pair), 0, flashloanAmount, address(token1));

        assertEq(token1.balanceOf(address(fl)), 0);
        assertEq(token1.balanceOf(address(pair)), 2 ether + flashloanFee);
    }

    // helper functions

    function assertReserves(uint256 expectedReserve0, uint256 expectedReserve1)
        internal
    {
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        assertEq(reserve0, expectedReserve0, "unexpected reserve0");
        assertEq(reserve1, expectedReserve1, "unexpected reserve1");
    }

    function encodeError(string memory error)
        internal
        pure
        returns (bytes memory encoded)
    {
        encoded = abi.encodeWithSignature(error);
    }
}

contract TestUser {
    function provideLiquidity(
        address pairAddress_,
        address token0Address_,
        address token1Address_,
        uint256 amount0_,
        uint256 amount1_
    ) public {
        ERC20(token0Address_).transfer(pairAddress_, amount0_);
        ERC20(token1Address_).transfer(pairAddress_, amount1_);

        ReanswapV2Pair(pairAddress_).mint(address(this));
    }

    function removeLiquidity(address pairAddress_) public {
        uint256 liquidity = ERC20(pairAddress_).balanceOf(address(this));
        ERC20(pairAddress_).transfer(pairAddress_, liquidity);
        ReanswapV2Pair(pairAddress_).burn(address(this));
    }
}

contract Flashloaner {
    error InsufficientFlashLoanAmount();

    uint256 expectedLoanAmount;

    function flashloan(
        address pairAddress,
        uint256 amount0Out,
        uint256 amount1Out,
        address tokenAddress
    ) public {
        if (amount0Out > 0) {
            expectedLoanAmount = amount0Out;
        }
        if (amount1Out > 0) {
            expectedLoanAmount = amount1Out;
        }

        ReanswapV2Pair(pairAddress).swap(
            amount0Out,
            amount1Out,
            address(this),
            abi.encode(tokenAddress)
        );
    }

    function reanswapV2Call(
        address sender,
        uint256 amount0Out,
        uint256 amount1Out,
        bytes calldata data
    ) public {
        address tokenAddress = abi.decode(data, (address));
        uint256 balance = ERC20(tokenAddress).balanceOf(address(this));

        if (balance < expectedLoanAmount) revert InsufficientFlashLoanAmount();

        ERC20(tokenAddress).transfer(msg.sender, balance);
    }
}