// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ETHTokenSale is ReentrancyGuard, Ownable {
    using SafeERC20 for ERC20;

    ERC20 public saleToken;
    bool public saleActive;
    uint8 public tokenDecimals;
    uint256 public rate; // Ensure this rate considers the desired conversion accurately
    uint256 public start;
    uint256 public end;
    uint256 public totalETHCollected;
    uint256 public totalTokensSold;

    // Metrics
    mapping(address => uint256) public tokensPurchased;

    //can decimals be a problem?
    //do we need a hard end date
    //how to control to hardcap
    //should we always wrap ether?
    //should we use a more elaborated role scheme?
    //what information should be upgradable?
    //feed tokens into contract
    //should we control token balances internally

    constructor(
        ERC20 _saleToken,
        uint256 _rate,
        uint256 _duration,
        address _owner
    ) Ownable(_owner) {
        require(address(_saleToken) != address(0), "Sale token cannot be the zero address");
        require(_owner != address(0), "Owner cannot be the zero address");
        saleToken = _saleToken;
        rate = _rate;
        start = block.timestamp;
        end = start + _duration;
        tokenDecimals = _saleToken.decimals();
        saleActive = true;
    }

    function buyTokens() external payable nonReentrant {
        require(saleActive, "Sale is not active");
        require(block.timestamp >= start && block.timestamp <= end, "Sale period has ended");
        require(msg.value > 0, "No ETH sent");

        uint256 tokensToTransfer = (msg.value * rate) / (10**18) * (10**tokenDecimals);

        tokensPurchased[msg.sender] += tokensToTransfer;

        totalETHCollected += msg.value;
        totalTokensSold += tokensToTransfer;
    }

    function claimTokens() external nonReentrant {
        uint256 amount = tokensPurchased[msg.sender];
        require(amount > 0, "No tokens to claim");

        tokensPurchased[msg.sender] = 0;
        saleToken.safeTransfer(msg.sender, amount);
        
        // Optional: Emit an event for the claim
    }

    function insertTokens(uint256 amount) external onlyOwner {

    }

    function toggleSaleActive() external onlyOwner {
        saleActive = !saleActive;
    }

    function withdrawETH() external onlyOwner {
        //use call
        payable(owner()).transfer(address(this).balance);
    }

    // General withdrawal function for ERC20 tokens
    function withdrawTokens(ERC20 token) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.safeTransfer(owner(), balance);
    }

}
