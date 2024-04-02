// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./EthTokenSale.sol";

contract SaleFactory is Ownable {
    // Keeping a record of all sales
    address[] public allSales;
    address immutable ETH_TOKEN_SALE;

    event SaleCreated(address indexed saleContract, string saleType);

    constructor(address initialOwner) Ownable(initialOwner) {
        ETH_TOKEN_SALE = address(new ETHTokenSale());
    }

    /*
           ERC20 _saleToken,
        uint256 _rate,
        uint256 _start,
        uint256 _duration,
        uint256 _softcap,
        uint256 _hardcap,
        uint256 _minPurchase,
        uint256 _maxPurchase,
        address _owner
        */

    // Function to create a new ETHTokenSale
    function createETHTokenSale(
        ERC20 saleToken,
        uint256 rate,
        uint256 start,
        uint256 duration,
        uint256 softcap,
        uint256 hardcap,
        uint256 minPurchase,
        uint256 maxPurchase,
        address owner
    ) external onlyOwner {
        // ETHTokenSale newSale = new ETHTokenSale();

        ETHTokenSale newSale = ETHTokenSale(
            createClone(ETH_TOKEN_SALE, bytes32(0))
        );

        newSale.initialize(
            saleToken,
            rate,
            start,
            duration,
            softcap,
            hardcap,
            minPurchase,
            maxPurchase,
            owner
        );
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

    function createClone(
        address target,
        bytes32 salt
    ) internal returns (address result) {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(
                clone,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(clone, 0x14), targetBytes)
            mstore(
                add(clone, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            result := create2(callvalue(), clone, 0x37, salt)
        }
    }
}
