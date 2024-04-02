// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {ETHTokenSale} from "../src/EthTokenSale.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SaleToken} from "../src/SaleToken.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract ETHTokenSaleTest is Test {
    ETHTokenSale tokenSale;

    using SafeERC20 for ERC20;

    SaleToken public saleToken;
    bool public saleActive;
    bool public paused;
    uint8 public tokenDecimals = 18;
    uint256 public rate = 2; // Ensure this rate considers the desired conversion accurately
    uint256 public start = block.timestamp;
    uint256 public end = 1 days;
    uint256 public totalETHCollected;
    uint256 public totalTokensSold;
    uint256 public softcap = 2 ether;
    uint256 public hardcap = 100 ether;
    uint256 public minPurchase = 1 ether;
    uint256 public maxPurchase = 10 ether;

    // Addresses for testing purposes
    address owner = address(this);
    address user = makeAddr("user");
    address u_one = address(1);
    address u_two = address(2);
    address u_three = address(3);
    address u_four = address(4);
    function setUp() public {
        saleToken = new SaleToken(owner); // owner will be test contract
        tokenSale = new ETHTokenSale();
        tokenSale.initialize(
            saleToken,
            rate,
            start,
            end,
            softcap,
            hardcap,
            minPurchase,
            maxPurchase,
            owner
        );

        // initializing Mock address with balance
        vm.deal(owner, 100 ether);
        vm.deal(user, 10 ether);
        vm.deal(u_one, 10 ether);
        vm.deal(u_two, 10 ether);
        vm.deal(u_three, 10 ether);
        vm.deal(u_four, 10 ether);
    }

    ////////////////////////
    ////    BUY        /////
    ///////////////////////
    function testUserCanBuyTokens() public {
        vm.startPrank(owner);
        saleToken.mint(100 ether);
        saleToken.approve(address(tokenSale), 100 ether);
        tokenSale.addMoreTokensToSale(100 ether);
        tokenSale.toggleSaleActive();
        vm.stopPrank();

        vm.prank(user);
        tokenSale.buyTokens{value: 2 ether}();

        assert(tokenSale.totalTokensSold() == 2 ether);
        assert(tokenSale.totalETHCollected() == 1 ether);
        assert(tokenSale.tokensPurchased(user) == 2 ether);
        assert(tokenSale.ethContributed(user) == 1 ether);
    }
}
