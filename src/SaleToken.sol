// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract SaleToken is ERC20, Ownable {
    event SaleCreated(address indexed saleContract, string saleType);

    constructor(address _owner) ERC20("Sale Token", "STK") Ownable(_owner) {}

    function mint(uint256 _value) external onlyOwner {
        _mint(msg.sender, _value);
    }
}
