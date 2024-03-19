// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import './ETHTokenSale.sol'; 

contract SaleFactory is Ownable {
    // Keeping a record of all sales
    address[] public allSales;

    event SaleCreated(address indexed saleContract, string saleType);

    constructor(address initialOwner) Ownable(initialOwner) {}

    /*
          uint64 _startTime,
        uint64 _endTime,
        uint8 _liquidityPortion,
        uint256 _saleRate, 
        uint256 _listingRate,
        uint256 _hardCap,
        uint256 _softCap,
        uint256 _maxBuy,
        uint256 _minBuy*/

    // Function to create a new ETHTokenSale
    function createETHTokenSale(
        ERC20 saleToken,
        uint256 rate,
        uint256 duration,
        uint256 softcap,
        uint256 hardcap,
        address owner
    ) external onlyOwner {
        ETHTokenSale newSale = new ETHTokenSale(saleToken, rate, duration, owner);
        allSales.push(address(newSale));
        emit SaleCreated(address(newSale), "ETH");
    }

    /*
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
        */
    // Additional factory management functions as needed...
}
