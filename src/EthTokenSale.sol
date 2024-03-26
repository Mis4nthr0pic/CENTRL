// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Whitelist} from "./Whitelist.sol";

contract ETHTokenSale is Ownable, Whitelist, ReentrancyGuard {
    using SafeERC20 for ERC20;

    ERC20 public saleToken;
    bool public saleActive;
    bool public paused;
    uint8 public tokenDecimals;
    uint256 public rate; // Ensure this rate considers the desired conversion accurately
    uint256 public start;
    uint256 public end;
    uint256 public totalETHCollected;
    uint256 public totalTokensSold;
    uint256 public softcap;
    uint256 public hardcap;
    uint256 public minPurchase;
    uint256 public maxPurchase;

    // Metrics
    mapping(address => uint256) public tokensPurchased;
    mapping(address => uint256) public ethContributed;

    event TokensPurchased(address indexed buyer, uint256 ethAmount, uint256 tokenAmount);
    event RefundIssued(address indexed buyer, uint256 ethAmount);
    event SaleParametersUpdated(
        uint256 start, uint256 duration, uint256 softcap, uint256 hardcap, uint256 minPurchase, uint256 maxPurchase
    );
    event TokensInserted(uint256 amount);
    event SaleActiveStatusChanged(bool newStatus);
    event SalePausedStatusChanged(bool newStatus);
    event TokensClaimed(address _sender, uint256 _amountToClaim);

    modifier saleIsActive() {
        require(
            saleActive && !paused && block.timestamp >= start && block.timestamp <= end, "Sale is not currently active"
        );
        _;
    }

    constructor(
        ERC20 _saleToken,
        uint256 _rate,
        uint256 _start,
        uint256 _duration,
        uint256 _softcap,
        uint256 _hardcap,
        uint256 _minPurchase,
        uint256 _maxPurchase,
        address _owner
    ) Ownable(_owner) {
        require(address(_saleToken) != address(0), "Sale token cannot be the zero address");
        require(_owner != address(0), "Owner cannot be the zero address");
        saleToken = _saleToken;
        rate = _rate;
        start = _start;
        end = _start + _duration;
        softcap = _softcap;
        hardcap = _hardcap;
        minPurchase = _minPurchase;
        maxPurchase = _maxPurchase;
        transferOwnership(_owner);
    }

    //create a pause modifier
    function pause(bool _status) external onlyOwner {
        paused = _status;
    }

    function updateSaleParameters(
        uint256 _start,
        uint256 _duration,
        uint256 _softcap,
        uint256 _hardcap,
        uint256 _minPurchase,
        uint256 _maxPurchase
    ) external onlyOwner {
        start = _start;
        end = _start + _duration;
        softcap = _softcap;
        hardcap = _hardcap;
        minPurchase = _minPurchase;
        maxPurchase = _maxPurchase;
    }

    // Function for the owner to insert tokens into the contract for the sale
    function addTokensToSale(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than 0");
        saleToken.safeTransferFrom(msg.sender, address(this), amount);
    }

    // Assuming `saleIsActive` is a modifier that checks both `saleActive` and `!paused`.
    function buyTokens() external payable nonReentrant saleIsActive {
        require(msg.value > 0, "No ETH sent");

        uint256 tokensToTransfer = msg.value * rate * (10 ** tokenDecimals - 18)/ 10 ** 18;        
        require(totalTokensSold + tokensToTransfer <= hardcap, "Purchase would exceed hardcap");

        // Check if adding this purchase would still respect the total ETH collected limit (if you're using a limit like hardcap for ETH)
        require(totalETHCollected + msg.value <= hardcap, "Total purchase would exceed ETH hardcap");

        tokensPurchased[msg.sender] += tokensToTransfer;

        //gotta check and minus this around
        ethContributed[msg.sender] += msg.value;
        totalETHCollected += msg.value;
        totalTokensSold += tokensToTransfer;

        // Transfer tokens immediately to buyer or allow them to claim later
        saleToken.safeTransfer(msg.sender, tokensToTransfer);

        emit TokensPurchased(msg.sender, msg.value, tokensToTransfer);
    }

   
    //CHECK GOOD
    function refund() external nonReentrant {
        require(!saleActive, "Sale is still active");
        require(totalETHCollected < softcap, "Softcap reached, refunds not available");

        uint256 tokensToRefund = tokensPurchased[msg.sender];
        require(tokensToRefund > 0, "No tokens to refund");

        // Calculate ETH to refund. This calculation assumes rate is tokens per ETH,
        // so we divide the number of tokens by the rate to find the ETH spent.
        // Adjust the formula based on how 'rate' is defined and consider decimals.
        // Assuming tokenDecimals, rate, and tokensToRefund are already defined appropriately
        uint256 ethToRefund = tokensToRefund * (10 ** 18)) / (rate * 10**(tokenDecimals - 18));        
        require(ethToRefund <= address(this).balance, "Not enough ETH in contract");

        tokensPurchased[msg.sender] = 0; // Prevent re-entrancy

        // Refund ETH to msg.sender
        (bool success,) = msg.sender.call{value: ethToRefund}("");
        require(success, "ETH refund failed");
    }

    //admin withdraws eth, before releasing claim or refunds (gotta be careful here, people can only get tokens after admin gets eth)
    //ONLY after end & release clain function
    function claimTokens() external nonReentrant {
        require(!saleActive, "Sale is still active");
        uint256 amountToClaim = tokensPurchased[msg.sender];
        require(amountToClaim > 0, "No tokens to claim");

        // It's a good practice to clear the user's claimable tokens before the transfer
        // to prevent a reentrancy attack even though we're using nonReentrant modifier.
        tokensPurchased[msg.sender] = 0;

        // Attempt to transfer tokens to the msg.sender.
        // safeTransfer will revert the transaction if the transfer fails.
        saleToken.safeTransfer(msg.sender, amountToClaim);

        // Emit an event after a successful transfer.
        emit TokensClaimed(msg.sender, amountToClaim);
    }

    function withdrawUnsoldTokens() external onlyOwner nonReentrant {
        require(block.timestamp > end, "Sale has not ended yet");
        uint256 unsoldTokens = saleToken.balanceOf(address(this)) - totalTokensSold;
        require(unsoldTokens > 0, "No unsold tokens to withdraw");
        saleToken.safeTransfer(owner(), unsoldTokens);
    }

    // Function to update the rate of the token sale
    function updateRate(uint256 _rate) external onlyOwner {
        require(_rate > 0, "Rate must be greater than 0");
        rate = _rate;
    }

    // Toggle pause status of the sale
    function togglePause() external onlyOwner {
        paused = !paused;
    }

    function toggleSaleActive() external onlyOwner {
        saleActive = !saleActive;
    }

    function withdrawTokens(ERC20 token) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.safeTransfer(owner(), balance);
    }

    // This function allows the owner to add more tokens to the sale
    // Useful in case the initial amount is sold out but the sale is still active
    function addMoreTokensToSale(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be positive");
        saleToken.safeTransferFrom(owner(), address(this), amount);
        emit TokensInserted(amount);
    }

    // Allows the owner to update the sale's start and end times
    // This might be needed to extend the sale duration or to postpone its start
    function updateSaleTiming(uint256 newStart, uint256 newEnd) external onlyOwner {
        require(newEnd > newStart, "End must be after start");
        start = newStart;
        end = newEnd;
        emit SaleParametersUpdated(start, end - start, softcap, hardcap, minPurchase, maxPurchase);
    }

    // Function for the owner to withdraw collected ETH after the sale
    function withdrawCollectedETH() external onlyOwner nonReentrant {
        uint256 amount = address(this).balance;
        (bool success,) = owner().call{value: amount}("");
        require(success, "Failed to send Ether");
    }

    //create a function to see the remaing tokens to be bought based on eth in the contract
    function remainingTokens() external view returns (uint256) {
        return saleToken.balanceOf(address(this));
    }

    // Ensuring proper handling of token decimals for refunds and purchases
    function getEthAmountForTokens(uint256 tokenAmount) private view returns (uint256) {
        return (tokenAmount * (10 ** 18)) / (rate * (10 ** tokenDecimals));
    }
}

//whitelist
//can decimals be a problem?
//how to control to hardcap
//should we always wrap ether?
//feed tokens into contract
//should we accept eth straight into the contract?

//max buy, min buy?
//remove all whitelisting at once?
//do we need a mincap
//do we need a hard end date
//should we use a more elaborated role scheme?
//what information should be upgradable?
//should we control token balances internally
//set total tokens
//where do we control whitelist behaviour
