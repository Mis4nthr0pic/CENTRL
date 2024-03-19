// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ETHTokenSale.sol";
import "./StablecoinTokenSale.sol";

contract TokenSaleFactory is Ownable {
    // Keeping a record of all sales
    address[] public allSales;

    event SaleCreated(address indexed saleContract, string saleType);

    // Function to create a new ETHTokenSale
    function createETHTokenSale(
        IERC20 saleToken,
        uint256 rate,
        uint256 duration,
        address owner
    ) external onlyOwner {
        ETHTokenSale newSale = new ETHTokenSale(saleToken, rate, duration, owner);
        allSales.push(address(newSale));
        emit SaleCreated(address(newSale), "ETH");
    }

    // Function to create a new StablecoinTokenSale
    function createStablecoinTokenSale(
        IERC20 saleToken,
        IERC20 paymentToken,
        uint256 rate,
        uint256 duration,
        address owner
    ) external onlyOwner {
        StablecoinTokenSale newSale = new StablecoinTokenSale(saleToken, paymentToken, rate, duration, owner);
        allSales.push(address(newSale));
        emit SaleCreated(address(newSale), "Stablecoin");
    }

    // Additional factory management functions as needed...
}
