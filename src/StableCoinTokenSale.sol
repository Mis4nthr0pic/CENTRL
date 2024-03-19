// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

//https://github.com/kirilradkov14/presale-contract/blob/main/contracts/Presale.sol

abstract contract StablecoinTokenSale is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    IERC20 public saleToken;
    IERC20 public paymentToken;
    uint256 public rate; // Number of tokens per payment token unit, considering decimals
    uint256 public start;
    uint256 public end;
    bool public saleActive;

    mapping(address => uint256) public tokensPurchased; // Tracks tokens each participant can claim
    uint256 public totalPaymentTokensCollected;
    uint256 public totalTokensSold;

    constructor(
        IERC20 _saleToken,
        IERC20 _paymentToken,
        uint256 _rate,
        uint256 _duration
    ) {
        saleToken = _saleToken;
        paymentToken = _paymentToken;
        rate = _rate; // Ensure this rate already considers the token's decimals
        start = block.timestamp;
        end = start + _duration;
        saleActive = true;
    }

    function buyTokens(uint256 paymentTokenAmount) external nonReentrant {
        require(saleActive, "Sale is not active");
        require(block.timestamp >= start && block.timestamp <= end, "Sale period has ended");
        require(paymentTokenAmount > 0, "No payment token sent");

        uint256 tokenAmount = paymentTokenAmount * rate / (10 ** IERC20Metadata(paymentToken).decimals()) * (10 ** IERC20Metadata(saleToken).decimals());
        tokensPurchased[msg.sender] += tokenAmount; // Update claimable amount

        paymentToken.safeTransferFrom(msg.sender, address(this), paymentTokenAmount);
        // Delayed token transfer; participants must claim tokens later

        // Update metrics
        totalPaymentTokensCollected += paymentTokenAmount;
        totalTokensSold += tokenAmount;
    }

    function claimTokens() external nonReentrant {
        uint256 amount = tokensPurchased[msg.sender];
        require(amount > 0, "No tokens to claim");

        tokensPurchased[msg.sender] = 0; // Reset claimable amount to prevent re-claiming
        saleToken.safeTransfer(msg.sender, amount); // Transfer claimed tokens
    }

    function toggleSaleActive() external onlyOwner {
        saleActive = !saleActive;
    }
    
    // Generalized withdraw function for any ERC20 token
    function withdrawTokens(IERC20 token) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "No tokens to withdraw");
        token.safeTransfer(owner(), balance);
    }

    // Specific function to withdraw payment tokens (stablecoins)
    function withdrawPaymentTokens() external onlyOwner {
        uint256 balance = paymentToken.balanceOf(address(this));
        require(balance > 0, "No payment tokens to withdraw");
        paymentToken.safeTransfer(owner(), balance);
    }
    
    // Function to get sale metrics
    function getSaleMetrics() external view returns (uint256, uint256, uint256) {
        return (
            totalPaymentTokensCollected,
            totalTokensSold,
            paymentToken.balanceOf(address(this))
        );
    }
}
