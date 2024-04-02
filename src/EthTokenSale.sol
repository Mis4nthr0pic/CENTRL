// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Whitelist.sol";

contract ETHTokenSale is Whitelist {
    uint8 public tokenDecimals;
    using SafeERC20 for ERC20;
    ERC20 public saleToken;
    bool public saleActive;
    bool public paused;
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

    event TokensPurchased(
        address indexed buyer,
        uint256 ethAmount,
        uint256 tokenAmount
    );
    event RefundIssued(address indexed buyer, uint256 ethAmount);
    event SaleParametersUpdated(
        uint256 start,
        uint256 duration,
        uint256 softcap,
        uint256 hardcap,
        uint256 minPurchase,
        uint256 maxPurchase
    );
    event TokensInserted(uint256 amount);
    event SaleActiveStatusChanged(bool newStatus);
    event SalePausedStatusChanged(bool newStatus);
    event TokensClaimed(address indexed claimer, uint256 amount);

    error SaleNotActive();
    error ZeroAddress();
    error ZeroValue();
    error InvalidHardcap();
    error SaleStillActive();
    error InvalidSoftcap();
    error InsufficientBalance();
    error TransferFailed();
    error InsufficientTokens();
    error SaleNotEnded();
    error InvalidDuration();

    modifier saleIsActive() {
        if (
            !saleActive ||
            paused ||
            block.timestamp < start ||
            block.timestamp > end
        ) {
            revert SaleNotActive();
        }

        // require(saleActive && !paused && block.timestamp >= start && block.timestamp <= end, "Sale is not currently active");
        _;
    }


    function initialize(
        ERC20 _saleToken,
        uint256 _rate,
        uint256 _start,
        uint256 _duration,
        uint256 _softcap,
        uint256 _hardcap,
        uint256 _minPurchase,
        uint256 _maxPurchase,
        address _owner
    ) external initializer {
        OwnableUpgradeable.__Ownable_init(_owner);
        if (address(_saleToken) == address(0) || _owner == address(0))
            revert ZeroAddress();
        saleToken = _saleToken;
        rate = _rate;
        start = _start;
        end = _start + _duration;
        softcap = _softcap;
        hardcap = _hardcap;
        minPurchase = _minPurchase;
        maxPurchase = _maxPurchase;

        tokenDecimals = IERC20Metadata(address(_saleToken)).decimals();
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
        saleToken.safeTransferFrom(msg.sender, address(this), amount);
    }

    // Assuming `saleIsActive` is a modifier that checks both `saleActive` and `!paused`.
    function buyTokens() external payable saleIsActive {
        if (msg.value == 0) revert ZeroValue();

        uint256 tokensToTransfer = ((msg.value * rate * (10 * (tokenDecimals - 18))) / 10) * 18;

        uint _hardcap = hardcap;

        if (totalTokensSold + tokensToTransfer > _hardcap)
            revert InvalidHardcap();

        // Check if adding this purchase would still respect the total ETH collected limit (if you're using a limit like hardcap for ETH)

        if (totalETHCollected + msg.value > _hardcap) revert('aff');// InvalidHardcap();

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
    function refund() external {
        if (saleActive) revert SaleStillActive();
        if (totalETHCollected < softcap) revert InvalidSoftcap();

        uint256 tokensToRefund = tokensPurchased[msg.sender];
        if (tokensToRefund == 0) revert ZeroValue();

        // Calculate ETH to refund. This calculation assumes rate is tokens per ETH,
        // so we divide the number of tokens by the rate to find the ETH spent.
        // Adjust the formula based on how 'rate' is defined and consider decimals.
        uint256 ethToRefund = (tokensToRefund * (10 ** 18)) /
            (rate * 10 ** (tokenDecimals - 18));

        if (ethToRefund > address(this).balance) revert InsufficientBalance();

        tokensPurchased[msg.sender] = 0;

        // Refund ETH to msg.sender

        (bool success, ) = msg.sender.call{value: ethToRefund}("");
        if (!success) revert TransferFailed();
    }

    function claimTokens() external {
        if (saleActive) revert SaleStillActive();
        if (totalETHCollected > softcap) revert InvalidSoftcap();
        uint256 amountToClaim = tokensPurchased[msg.sender];

        if (amountToClaim == 0) revert ZeroValue();

        // It's a good practice to clear the user's claimable tokens before the transfer
        // to prevent a reentrancy attack even though we're using nonReentrant modifier.
        tokensPurchased[msg.sender] = 0;

        // Attempt to transfer tokens to the msg.sender.
        // safeTransfer will revert the transaction if the transfer fails.
        saleToken.safeTransfer(msg.sender, amountToClaim);

        // Emit an event after a successful transfer.
        emit TokensClaimed(msg.sender, amountToClaim);
    }

    function withdrawUnsoldTokens() external onlyOwner {
        if (block.timestamp < end) revert SaleNotEnded();

        uint256 unsoldTokens = saleToken.balanceOf(address(this)) -
            totalTokensSold;
        if (unsoldTokens == 0) revert InsufficientTokens();
        saleToken.safeTransfer(owner(), unsoldTokens);
    }

    // Function to update the rate of the token sale
    function updateRate(uint256 _rate) external onlyOwner {
        if (_rate == 0) revert ZeroValue();
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
        // require(amount > 0, "Amount must be positive");
        if (amount == 0) revert ZeroValue();
        saleToken.safeTransferFrom(owner(), address(this), amount);
        emit TokensInserted(amount);
    }

    // Allows the owner to update the sale's start and end times
    // This might be needed to extend the sale duration or to postpone its start
    function updateSaleTiming(
        uint256 newStart,
        uint256 newEnd
    ) external onlyOwner {
        // require(newEnd > newStart, "End must be after start");
        if (newEnd <= newStart) revert InvalidDuration();
        start = newStart;
        end = newEnd;
        emit SaleParametersUpdated(
            start,
            end - start,
            softcap,
            hardcap,
            minPurchase,
            maxPurchase
        );
    }

    // Function for the owner to withdraw collected ETH after the sale
    function withdrawCollectsedETH() external onlyOwner {
        uint256 amount = address(this).balance;
        (bool success, ) = owner().call{value: amount}("");
        if (!success) revert TransferFailed();
    }

    //create a function to see the remaing tokens to be bought based on eth in the contract
    function remainingTokens() external view returns (uint256) {
        return saleToken.balanceOf(address(this));
    }

    // Ensuring proper handling of token decimals for refunds and purchases
    function getEthAmountForTokens(
        uint256 tokenAmount
    ) private view returns (uint256) {
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

/*
    // Allows withdrawal of ETH in case of sale failure or after reaching the softcap
    function withdrawCollectedETH() external onlyOwner nonReentrant {
        require(saleActive == false, "Sale must be concluded");
        require(totalETHCollected >= softcap, "Cannot withdraw before reaching softcap or if sale is active");

        uint256 amountToWithdraw = address(this).balance;
        (bool success, ) = owner().call{value: amountToWithdraw}("");
        require(success, "Failed to withdraw ETH");
    }

    // Handling ETH refunds in case the sale does not reach softcap
    function initiateRefunds() external onlyOwner {
        require(saleActive == false, "Sale must be concluded");
        require(totalETHCollected < softcap, "Refunds not available, softcap reached");

        // Logic to enable refunds for participants
        // Note: Implementation details for enabling participants to claim refunds need to be added
    }

    // Modifier to ensure operations can only occur after the sale has ended
    modifier afterSale() {
        require(block.timestamp > end, "Operation not available until after the sale has ended");
        _;
    }

    // Checks and balances for token and ETH withdrawals
    function checkBalances() external view onlyOwner returns (uint256 ethBalance, uint256 tokenBalance) {
        return (address(this).balance, saleToken.balanceOf(address(this)));
    }

    // Extend sale duration in special circumstances
    function extendSaleDuration(uint256 newEnd) external onlyOwner {
        require(newEnd > end, "New end time must be after current end time");
        end = newEnd;
    }

    // Emergency stop function in case of critical issues
    function emergencyStopSale() external onlyOwner {
        paused = true;
        saleActive = false;
    }

    // Reactivate the sale in case it was paused or stopped
    function reactivateSale() external onlyOwner {
        require(paused == true, "Sale is not paused");
        paused = false;
        saleActive = true;
    }

    // Update token decimals in case of incorrect initial setting
    function updateTokenDecimals(uint8 newDecimals) external onlyOwner {
        tokenDecimals = newDecimals;
    }
}
*/
