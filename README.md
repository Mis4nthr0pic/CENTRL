

# BaseSale Contract
A smart contract for managing ERC-20 token sales.

The BaseSale contract is an abstract contract that provides the foundational functionality for creating and managing ERC-20 token sales. It accepts payment tokens, records contributions, and integrates with a vesting contract for token claiming. Only approved addresses can contribute to the sale.

## Contract Functions

### initialize(BaseSaleConfig memory baseSaleConfig)
Initializes the sale contract with the provided configuration.

**Parameters:**
- `baseSaleConfig`: The configuration for the sale.

**Details:**
- Sets up sale parameters, including payment token, vesting factory, sale beneficiary, fee recipient, admin, and rounds.
- Configures token allocations for approved addresses.
- Can only be called once.

### getSaleData()
Returns the sale's static config data.

**Returns:**
- `SaleData`: The sale data struct.

### getSaleRounds()
Returns the sale rounds config data.

**Returns:**
- `RoundConfig[]`: An array of structs with the rounds start and end times.

### getGroupIndex(address contributorAddress)
Gets the address group index by contributor.

**Parameters:**
- `contributorAddress`: The address of the contributor.

**Returns:**
- `uint256`: The address group index.

### getIndividualAllocation(address contributorAddress)
Gets individual allocation by address.

**Parameters:**
- `contributorAddress`: The address of the contributor.

**Returns:**
- `uint256`: The individual allocation.

### getContributor(address contributorAddress)
Returns the contributor info by address.

**Parameters:**
- `contributorAddress`: The address of the contributor.

**Returns:**
- `Contributor`: The contributor struct.

### getContributors()
Queries the sale's contributors.

**Returns:**
- `Contributor[]`: An array of contributors.

### getContributedAmount(address contributor)
Gets the tokens contributed by address.

**Parameters:**
- `contributor`: The address of the contributor.

**Returns:**
- `uint256`: The tokens contributed by the address.

### getApprovedAddresses()
Gets approved addresses.

**Returns:**
- `address[]`: An array of approved addresses.

### withdrawContributions(address beneficiary)
Allows to withdraw contributed tokens when the sale is completed and soft cap is reached.

**Parameters:**
- `beneficiary`: The address to withdraw the contributions to.

**Details:**
- Can only be called by the sale admin or beneficiary.
- The sale must be completed and the soft cap reached.
- Can only be called once.
- Emits a `ContributionWithdrawnLog` event.

### withdrawFee()
Allows to withdraw the admin fee when the sale is completed and soft cap is reached.

**Details:**
- Can only be called by the sale admin.
- Can only be called once.
- Emits a `FeeWithdrawnLog` event.

### isSoftCapReached()
Checks if the sale soft cap is reached.

**Returns:**
- `bool`: True if the soft cap is reached.

### cancel()
Used to cancel the sale in case of an emergency.

**Details:**
- Can only be called by an address with the `ADMIN_ROLE`.
- The sale must be active.
- Can only be called once.
- Emits a `SaleCancelledLog` event.
- If the sale is cancelled and the vesting contract is set, the vesting contract is cancelled as well.

### refund()
Used to refund the contribution of a contributor in case the sale is cancelled or the soft cap is not reached.

**Details:**
- Can be called only if the sale is completed and soft cap is not reached, or the sale is cancelled.
- Can be called by anyone.
- Can only be called once per contributor.
- Emits a `ContributionRefundedLog` event.
- Full contribution amount is refunded. No admin fee is taken.

### setVestingId(bytes16 _vestingId)
Links the vesting contract to the sale.

**Parameters:**
- `_vestingId`: The vesting contract ID.

**Details:**
- Can only be called by an address with the `ADMIN_ROLE`.
- Can only be called before the sale starts or after the sale is completed.
- Can only be called once.
- Emits a `VestingLinkedLog` event.

### isVestingSet()
Checks if the vesting contract is set.

**Returns:**
- `bool`: True if the vesting contract is set.

### buy(uint256 maxPaymentTokenAmount)
Allows buying tokens by contributing the payment tokens.

**Parameters:**
- `maxPaymentTokenAmount`: The maximum amount of payment tokens to be used for the purchase.

**Details:**
- Can only be called if the sale is not cancelled.
- The sale must be active.
- If the sale is fixed token amount sale, buys the fixed amount of tokens.
- In the first round, buys up to the individual allocation.
- In the last round, buys up to the sale allocation.
- In the second round but not last round, buys up to the group allocation.
- If the soft cap is reached and vesting is set, enables the vesting contract claiming.

## Contract Events

### TokensContributedLog
Emitted when a contributor contributes to the sale.

**Parameters:**
- `address indexed contributor`: The address of the contributor.
- `uint256 currentContributedAmount`: The amount of tokens contributed in the current buy.
- `uint256 totalContributedAmount`: The total amount of tokens contributed.

### VestingLinkedLog
Emitted when a vesting contract is linked to the sale.

**Parameters:**
- `bytes16 indexed vestingId`: The ID of the vesting contract.

### ContributionWithdrawnLog
Emitted when the contributed funds are withdrawn to the beneficiary.

**Parameters:**
- `address indexed beneficiary`: The address of the beneficiary.
- `uint256 beneficiaryAmount`: The amount of tokens withdrawn.

### FeeWithdrawnLog
Emitted when the admin fee is withdrawn to the fee recipient.

**Parameters:**
- `address indexed beneficiary`: The address of the fee recipient.
- `uint256 beneficiaryAmount`: The amount of tokens withdrawn.

### ContributionRefundedLog
Emitted when a contributor refunds their contribution.

**Parameters:**
- `address indexed contributor`: The address of the contributor.
- `uint256 amount`: The amount of tokens refunded.

### SaleCancelledLog
Emitted when the sale is cancelled.


# SaleFactory Contract
A factory contract for creating different types of token sales.

The SaleFactory contract is designed to create and manage instances of various token sale contracts, such as PrivateSale, TierBasedSale, and UnlimitedSale. The contract is upgradable, allowing for the addition of new sale types in the future. It uses sale-specific factory contracts to create sales, thereby reducing the size of the SaleFactory contract itself.

## Contract Functions

### initialize(address _privateSaleFactory, address _tierBasedSaleFactory, address _unlimitedSaleFactory)
Initializes the contract with the addresses of the specific sale factory contracts.

**Parameters:**
- `_privateSaleFactory`: The address of the PrivateSaleFactory contract.
- `_tierBasedSaleFactory`: The address of the TierBasedSaleFactory contract.
- `_unlimitedSaleFactory`: The address of the UnlimitedSaleFactory contract.

**Details:**
- Sets the DEFAULT_ADMIN_ROLE and ADMIN_ROLE to the deployer.
- Can only be called once.

### createPrivateSale(PrivateSaleConfig memory privateSaleConfig)
Creates a new PrivateSale contract.

**Parameters:**
- `privateSaleConfig`: The configuration for the new PrivateSale contract.

**Details:**
- Can only be called by the ADMIN_ROLE.
- The saleId must be unique.
- Adds the saleId to the saleIds array.
- Adds the sale address to the saleInstances mapping.
- Emits a `SaleCreatedLog` event.

### createTierBasedSale(TierBasedSaleConfig memory tierBasedSaleConfig)
Creates a new TierBasedSale contract.

**Parameters:**
- `tierBasedSaleConfig`: The configuration for the new TierBasedSale contract.

**Details:**
- Can only be called by the ADMIN_ROLE.
- The saleId must be unique.
- Adds the saleId to the saleIds array.
- Adds the sale address to the saleInstances mapping.
- Emits a `SaleCreatedLog` event.

### createUnlimitedSale(UnlimitedSaleConfig memory unlimitedSaleConfig)
Creates a new UnlimitedSale contract.

**Parameters:**
- `unlimitedSaleConfig`: The configuration for the new UnlimitedSale contract.

**Details:**
- Can only be called by the ADMIN_ROLE.
- The saleId must be unique.
- Adds the saleId to the saleIds array.
- Adds the sale address to the saleInstances mapping.
- Emits a `SaleCreatedLog` event.

### getSaleIds()
Returns the ids of all sales.

**Returns:**
- `bytes16[]`: An array of sale IDs.

## Contract Events

### SaleCreatedLog
Emitted when a new sale contract is created.

**Parameters:**
- `bytes16 indexed saleId`: The ID of the sale.
- `address indexed saleAddress`: The address of the sale contract.

## Internal Functions

### _checkIfSaleExists(bytes16 id)
Checks if a sale with the given ID already exists.

**Parameters:**
- `id`: The ID to check.

**Details:**
- Requires that the ID is not empty.
- Requires that the sale does not already exist.

### _addSale(bytes16 saleId, address saleAddress)
Adds a new sale to the saleInstances mapping and the saleIds array.

**Parameters:**
- `saleId`: The ID of the sale.
- `saleAddress`: The address of the sale contract.

**Details:**
- Adds the sale ID to the saleIds array.
- Adds the sale address to the saleInstances mapping.
- Emits a `SaleCreatedLog` event.


# PrivateSale Contract
A smart contract for managing a private sale of ERC-20 tokens.

The PrivateSale contract allows for the management of a private token sale, where approved contributors can participate by making a single contribution up to their individual allocation. Additional contributors can be added by the admin before the sale ends.

## Contract Functions

### initialize(PrivateSaleConfig memory privateSaleConfig)
Initializes the private sale contract with the provided configuration.

**Parameters:**
- `privateSaleConfig`: The configuration for the private sale.

**Details:**
- Sets up sale parameters, including payment token, vesting factory, sale beneficiary, fee recipient, admin, and rounds.
- Configures token allocations for approved addresses.
- Can only be called once.

### addContributors(Contributor[] memory newContributors)
Adds contributors to the private sale.

**Parameters:**
- `newContributors`: The contributors to add.

**Details:**
- Can only be called by the admin.
- The contributor address must not be 0x0.
- The contributor allocation must be greater than 0.
- The contributor address must not already be added.
- The contributor address group ID must be the 16 bytes 0-left-padded hex of 'privateSale'.
- The sum of individual allocations must not be greater than the max raise amount.
- Contributors can be added before the sale end time.
- Emits a `ContributorsAddedLog` event.

## Contract Events

### ContributorsAddedLog
Emitted when new contributors are added to the private sale.

**Parameters:**
- `Contributor[] newContributors`: The array of new contributors.


# TierBasedSale Contract
A smart contract for managing a tier-based sale of ERC-20 tokens.

The TierBasedSale contract allows for the management of a tier-based token sale, where contributors are grouped into tiers based on off-chain criteria (such as NFT ownership). The sale consists of 2 or 3 rounds, with specific contribution rules for each round.

## Contract Functions

### initialize(TierBasedSaleConfig memory config)
Initializes the tier-based sale contract with the provided configuration.

**Parameters:**
- `config`: The configuration for the tier-based sale.

**Details:**
- The sale must have 2 or 3 rounds defined.
- The sale must have at least 1 address group defined for 2 rounds, and at least 2 address groups defined for 3 rounds.
- Sets the `isFixedTokenAmountSale` flag to `false`.
- Calls the `initialize` function of the `BaseSale` contract with the provided configuration.

## Contract Configuration

### TierBasedSaleConfig
The configuration structure for the tier-based sale.

**Parameters:**
- `bytes16 id`: The unique identifier for the sale.
- `uint256 maxRaiseAmount`: The maximum amount to be raised.
- `address paymentToken`: The address of the payment token.
- `address vestingFactory`: The address of the vesting factory.
- `address saleBeneficiary`: The address of the sale beneficiary.
- `address feeRecipient`: The address of the fee recipient.
- `address admin`: The address of the admin.
- `uint16 adminFee`: The admin fee percentage.
- `uint256 startTime`: The start time of the sale.
- `address[] approvedAddress`: The array of approved addresses.
- `uint256[] addressGroupEndIndexes`: The array of address group end indexes.
- `bytes16[] addressGroupIds`: The array of address group IDs.
- `uint256[] tokenAllocationPerAddress`: The array of token allocations per address.
- `uint256[] roundEndTimes`: The array of round end times.
- `uint256 minimumContributionLeft`: The minimum contribution left.
- `uint256 softCap`: The soft cap for the sale.

## Sale Rounds

### Round 1
In the first round, contributions are allowed up to the individual address allocation.

### Round 2
If there are 2 rounds, contributions are allowed up to the max raise amount. If there are 3 rounds, contributions are allowed up to the address group allocation.

### Round 3
If there are 3 rounds, contributions are allowed up to the max raise amount.



# UnlimitedSale Contract
A smart contract for managing an unlimited sale of ERC-20 tokens.

The UnlimitedSale contract allows for the management of a token sale with unlimited contributions. The sale consists of 2 rounds, with specific contribution rules for each round.

## Contract Functions

### initialize(UnlimitedSaleConfig memory config)
Initializes the UnlimitedSale contract with the provided configuration.

**Parameters:**
- `config`: The configuration for the UnlimitedSale contract.

**Details:**
- The sale must have 2 rounds defined.
- The sale must have 1 address group defined.
- Sets the `isFixedTokenAmountSale` flag to `false`.
- Calls the `initialize` function of the `BaseSale` contract with the provided configuration.

## Contract Configuration

### UnlimitedSaleConfig
The configuration structure for the unlimited sale.

**Parameters:**
- `bytes16 id`: The unique identifier for the sale.
- `uint256 maxRaiseAmount`: The maximum amount to be raised.
- `address paymentToken`: The address of the payment token.
- `address vestingFactory`: The address of the vesting factory.
- `address saleBeneficiary`: The address of the sale beneficiary.
- `address feeRecipient`: The address of the fee recipient.
- `address admin`: The address of the admin.
- `uint16 adminFee`: The admin fee percentage.
- `uint256 startTime`: The start time of the sale.
- `address[] approvedAddress`: The array of approved addresses.
- `uint256[] addressGroupEndIndexes`: The array of address group end indexes.
- `bytes16[] addressGroupIds`: The array of address group IDs.
- `uint256[] tokenAllocationPerAddress`: The array of token allocations per address.
- `uint256[] roundEndTimes`: The array of round end times.
- `uint256 minimumContributionLeft`: The minimum contribution left.
- `uint256 softCap`: The soft cap for the sale.

## Sale Rounds

### Round 1
In the first round, contributions are allowed up to the individual address allocation.

### Round 2
In the second round, contributions are allowed up to the max raise amount.


# LMPool Contract
A smart contract for managing liquidity mining pools.

The LMPool contract is a smart contract that allows for the creation and management of liquidity mining pools. Users can stake ERC20 tokens to earn rewards in the form of other tokens. The contract is designed to handle staking, reward distribution, and administrative functions securely and efficiently.

## Contract Functions

### initialize(LMPoolConfig memory config)
This function initializes the contract with the configuration for the liquidity mining pool. It takes as a parameter a structure called `LMPoolConfig`, which contains the following information:
- `id`: Unique ID for the pool.
- `admin`: Admin account. Only the admin can withdraw reward tokens, cancel the pool, withdraw the fee, increase the end time, and increase reward amounts.
- `stakingEnabledTime`: Time when staking is enabled.
- `rewardsAccrualStartTime`: Time when rewards start accruing.
- `endTime`: Time when staking ends.
- `baseToken`: Token that is staked.
- `rewardTokens`: Tokens that are rewarded.
- `initialRewardAmounts`: Initial reward amounts for each reward token.
- `fee`: Staking fee which goes to the fee recipient.
- `feeRecipient`: Address that receives the staking fee.

This function can only be called once and only by the contract creator.

### depositRewardTokens(TokenAmount[] memory rewardAmounts)
This function allows depositing reward tokens into the pool. It takes as a parameter an array of `TokenAmount` structures, each containing:
- `token`: The address of the reward token.
- `amount`: The amount of the reward token to deposit.

This function can be called by any account and emits the `RewardsDepositedLog` event.

### stake(uint256 _amount)
This function allows users to stake the base token into the pool. It takes as a parameter the amount of base tokens to stake. The function:
- Verifies the staking conditions.
- Transfers the staked tokens to the pool.
- Updates the staker's data.
- Emits the `StakedLog` event.

### unstake(uint256 _amount, bool _claimRewards)
This function allows users to unstake their base tokens from the pool. It takes as parameters the amount of base tokens to unstake and a flag indicating whether to claim the rewards. The function:
- Verifies the unstaking conditions.
- Transfers the unstaked tokens back to the user.
- Updates the staker's data.
- Optionally claims rewards.
- Emits the `UnstakedLog` event.

### claimRewards()
This function allows users to claim their accumulated rewards. It:
- Verifies the reward claiming conditions.
- Transfers the reward tokens to the user.
- Updates the staker's data.
- Emits the `RewardsClaimedLog` event.

### withdrawFee()
This function allows the admin to withdraw the accumulated staking fees. It:
- Transfers the fee balance to the fee recipient.
- Emits the `FeeWithdrawnLog` event.

### withdrawRewardTokens()
This function allows the admin to withdraw excess reward tokens from the pool. It:
- Verifies the withdrawal conditions.
- Transfers the excess reward tokens to the admin.
- Emits the `RewardsWithdrawnLog` event.

### increaseEndTime(uint256 newEndTime)
This function allows the admin to extend the staking end time. It takes as a parameter the new end time. The function:
- Verifies the conditions for increasing the end time.
- Updates the end time and reward amounts.
- Emits the `EndTimeIncreasedLog` event.

### increaseRewards(TokenAmount[] memory additionalRewardAmounts)
This function allows the admin to increase the rewards in the pool. It takes as a parameter an array of `TokenAmount` structures, each containing:
- `token`: The address of the reward token.
- `amount`: The amount of the reward token to add.

The function:
- Verifies the conditions for increasing rewards.
- Updates the reward rates and total reward amounts.
- Emits the `RewardsIncreasedLog` event.

### cancel()
This function allows the admin to cancel the pool. It:
- Sets the pool’s end time to the current block timestamp.
- Emits the `LMPoolCancelledLog` event.

## Contract Events

### RewardsDepositedLog(TokenAmount[] tokenAmount)
Emitted by the `depositRewardTokens` function. It logs the deposited reward tokens.

### StakedLog(address indexed staker, uint256 amount)
Emitted by the `stake` function. It logs the staking activity.

### UnstakedLog(address staker, uint256 amount)
Emitted by the `unstake` function. It logs the unstaking activity.

### RewardsClaimedLog(address indexed staker, TokenAmount[] tokenAmount)
Emitted by the `claimRewards` function. It logs the rewards claimed by the staker.

### FeeWithdrawnLog(address indexed beneficiary, uint256 beneficiaryAmount)
Emitted by the `withdrawFee` function. It logs the withdrawal of the staking fee.

### RewardsWithdrawnLog(TokenAmount[] tokenAmount)
Emitted by the `withdrawRewardTokens` function. It logs the withdrawal of reward tokens by the admin.

### EndTimeIncreasedLog(uint256 indexed newEndTime)
Emitted by the `increaseEndTime` function. It logs the new end time for the pool.

### RewardsIncreasedLog(TokenAmount[] newTotalTokenAmounts, TokenAmount[] newRewardRates)
Emitted by the `increaseRewards` function. It logs the increased reward amounts and rates.

### LMPoolCancelledLog()
Emitted by the `cancel` function. It logs the cancellation of the pool.

# Interval Vesting Contract

## Overview
The Interval Vesting contract allows the claiming of sale tokens at regular time intervals. It is designed to manage the distribution of tokens over a specific period, with an initial claim available after a cliff period.

## Contract Structure

### IntervalVestingConfig
This struct contains the configuration for the vesting contract:
- `id`: Unique identifier for the vesting contract.
- `saleToken`: Address of the ERC20 token being vested.
- `saleTokenDecimals`: Number of decimals for the sale token.
- `startTime`: Timestamp when the vesting starts.
- `duration`: Total duration of the vesting period.
- `cliffDuration`: Initial period during which no tokens are vested.
- `initialClaim`: Percentage of tokens that can be claimed after the cliff period.
- `claimInterval`: Interval at which tokens can be claimed after the cliff period.
- `saleTokenPrice`: Price of the sale token.
- `admin`: Address of the admin.
- `enableClaimingAccounts`: List of addresses that can enable claiming.

### Events
- `TokensDepositedLog(depositor, tokenAmount)`: Emitted when tokens are deposited to the vesting contract.
- `TokensLockedLog(beneficiary, vestingId, tokenAmount)`: Emitted when tokens are locked for a beneficiary.
- `TokensClaimedLog(beneficiary, claimedAmount)`: Emitted when tokens are claimed by a beneficiary.
- `VestingCancelledLog()`: Emitted when the vesting is cancelled.
- `SaleTokensWithdrawnLog(beneficiary, tokenAmount)`: Emitted when tokens are withdrawn by the admin from a cancelled vesting contract.
- `ClaimingEnabledLog()`: Emitted when claiming is enabled.
- `ClaimingDisabledLog()`: Emitted when claiming is disabled.

### Functions

#### Initialization
```solidity
function initialize(IntervalVestingConfig memory config) external initializer
Initializes the vesting contract with the provided configuration. Sets up roles and calculates the cliff end time and vesting end time.

Get Vesting Data
function getVestingData() external view returns (VestingData memory vestingData)
Returns the static configuration data of the vesting contract.

Enable Claiming
function enableClaiming() external
Enables token claiming. Only callable by addresses in the enableClaimingAccounts list.

Disable Claiming
function disableClaiming() external
Disables token claiming. Only callable by addresses in the enableClaimingAccounts list.

Cancel Vesting
function cancel() external onlyRole(ADMIN_ROLE)
Cancels the vesting contract, preventing further token deposits and locks. Can only be called once by an admin.

Withdraw Tokens
function withdraw() external onlyRole(ADMIN_ROLE)
Allows the admin to withdraw tokens from a cancelled vesting contract. Can only be called once and only if the vesting is cancelled.

Deposit Tokens
function deposit(uint256 amount) external
Deposits sale tokens into the vesting contract. Can be called by anyone but not when the vesting is cancelled.

Lock Tokens
function lockTokens(address beneficiary, uint256 amount) external onlyRole(ADMIN_ROLE)
Locks tokens for a beneficiary. Only callable by an admin before the vesting start time.

Get Claimable Amount
function getClaimableAmount(address beneficiary) public view returns (uint256)
Calculates the amount of claimable tokens for a beneficiary based on the current time and vesting schedule.

Claim Tokens
function claimTokens() external
Claims vested tokens. Transfers the claimable amount to the caller.

Get Locked Amount
function getLockedAmount(address beneficiary) public view returns (uint256)
Calculates the amount of tokens that are locked and not yet claimable for a beneficiary.

Get Vesting Progress
function getVestingProgress(address beneficiary) external view returns (VestingProgress memory vestingProgress)
Returns the vesting progress for a beneficiary, including total locked amount, claimed amount, claimable amount, and locked amount.

# Tier Contract

## Overview
The Tier contract represents a user's tier and grants access to tier-specific features such as access to tier-specific sales. By default, NFT transfers are paused for addresses that are not the owner, but whitelisted addresses in the tierFactory can transfer the NFT.

## Contract Structure

### State Variables
- `WHITELISTED_ROLE`: Role for addresses allowed to transfer NFTs even when paused.
- `tierFactory`: AccessControl contract managing roles for this contract.
- `tierId`: Unique identifier for the tier.
- `basePrice`: Base price of the tier.
- `priceMultiplier`: Price multiplier of the tier.
- `totalAmount`: Total number of NFTs available for this tier.
- `actualAmount`: Number of NFTs currently minted.
- `unusedIds`: Array of unused token IDs.
- `baseURI`: Base URI for NFT metadata.

### Structs
- `TierData`: Contains the static data for the tier.

### Constructor
```solidity
constructor(
    address _tierFactory,
    string memory name,
    string memory symbol,
    string memory nftStorageURI,
    bytes16 _tierId,
    uint256 _basePrice,
    uint256 _priceMultiplier,
    uint256 _totalAmount
)
Initializes the contract with the given parameters and pauses NFT transfers by default.

Functions
Pause
function pause() public onlyOwner
Pauses the NFT transfers. Only callable by the owner.

Unpause
function unpause() public onlyOwner
Unpauses the NFT transfers. Only callable by the owner.

Get Tier Data
function getTierData() external view returns (TierData memory tierData)
Returns the static data of the tier.

Get My Token URI
function getMyTokenURI() external view returns (string memory)
Returns the URI of the NFT owned by the caller.

Buy
function buy(address buyer) external onlyOwner returns (uint256)
Allows the owner to mint a new NFT for the given buyer. Ensures the buyer does not already own an NFT and that the tier is not sold out.

Return NFT
function returnNft(address tokenOwner) external onlyOwner
Allows the owner to return an NFT when upgrading. Transfers the NFT from the token owner to the contract owner and adds the token ID to the unused IDs.

Overridden Functions
_beforeTokenTransfer: Ensures transfers can only be done by the owner, when not paused, or by whitelisted addresses.
supportsInterface: Indicates the interfaces supported by this contract.

