# CTMRWA1InvestWithTimeLock Contract Documentation

## Overview

**Contract Name:** CTMRWA1InvestWithTimeLock  
**File:** `src/deployment/CTMRWA1InvestWithTimeLock.sol`  
**License:** BSL-1.1  
**Author:** @Selqui ContinuumDAO

## Contract Description

This is a contract to allow an Issuer (tokenAdmin) to raise finance from investors. It can be deployed once on each chain that the RWA token is deployed to. The Issuer can create Offerings with start and end dates, min and max amounts to invest and with a lock up escrow period. The investors can still claim rewards, sent to them by the Issuer, whilst their investments are locked up. Once the lockup period is over, the investors can withdraw their tokenIds.

Issuers can create multiple simultaneous Offerings.

### Key Features
- Investment platform for RWA token issuers to raise capital
- Time-locked escrow system for investor tokens
- Reward distribution during lockup periods
- Multiple simultaneous offerings support
- Cross-chain integration with CTMRWA ecosystem
- Fee management and commission system
- BNB Greenfield storage object references
- Comprehensive access control and whitelisting

## State Variables

- `ID (uint256)`: Unique ID of the CTMRWA token contract
- `RWA_TYPE (uint256, constant = 1)`: RWA type defining CTMRWA1
- `VERSION (uint256, constant = 1)`: Version of this RWA type
- `offerings (Offering[])`: A list of offerings to investors
- `MAX_OFFERINGS (uint256, constant = 100)`: Limit the number of Offerings to stop DDoS attacks
- `holdingsByAddress (mapping(address => Holding[]))`: Mapping of address to holdings
- `ctmRwaToken (address)`: The token contract address corresponding to this ID
- `decimalsRwa (uint8)`: The decimals of the CTMRWA1
- `ctmRwaDividend (address)`: The Dividend contract address corresponding to this ID
- `ctmRwaSentry (address)`: The Sentry contract address corresponding to this ID
- `ctmRwa1X (address)`: The CTMRWA1X contract address corresponding to this ID
- `ctmRwaMap (address)`: Address of the CTMRWAMap contract
- `commissionRate (uint256)`: The commission rate payable to FeeManager 0-10000 (0.01%)
- `feeManager (address)`: Address of the FeeManager contract
- `tokenAdmin (address)`: The Token Admin of this CTMRWA
- `cIdStr (string)`: String representation of the local chainID
- `tokensInEscrow (uint256[])`: Arrays of tokenIds in escrow
- `ownersInEscrow (address[])`: Arrays of owners in escrow

## Constructor

```solidity
constructor(uint256 _ID, address _ctmRwaMap, uint256 _commissionRate, address _feeManager)
```
- Initializes the contract with essential parameters and validates dependencies
- Sets contract identifiers and addresses
- Retrieves related contract addresses from CTMRWAMap
- Validates contract existence and permissions
- Sets configuration parameters

## Access Control

- `onlyTokenAdmin(address _ctmRwaToken)`: Restricts access to authorized administrators
- `nonReentrant`: Prevents reentrancy attacks using OpenZeppelin's ReentrancyGuard

## Administrative Functions

### setTokenAdmin()
```solidity
function setTokenAdmin(address _tokenAdmin, bool _force) public onlyTokenAdmin(ctmRwaToken) returns (bool)
```
Change the tokenAdmin address. This function can only be called by CTMRWA1X, or the existing tokenAdmin. If the CTMRWA1 is being locked and there are Offerings, DO NOT change tokenAdmin for this Investment contract. The tokenAdmin can manually set to address(0) with the override _force == true.

### pauseOffering()
```solidity
function pauseOffering(uint256 _indx) public onlyTokenAdmin(ctmRwaToken)
```
Pause a specific offering (only tokenAdmin).

### unpauseOffering()
```solidity
function unpauseOffering(uint256 _indx) public onlyTokenAdmin(ctmRwaToken)
```
Unpause a specific offering (only tokenAdmin).

### isOfferingPaused()
```solidity
function isOfferingPaused(uint256 _indx) public view returns (bool)
```
Check if a specific offering is paused.

## Investment Management

### createOffering()
```solidity
function createOffering(
    uint256 _tokenId,
    uint256 _price,
    address _currency,
    uint256 _minInvestment,
    uint256 _maxInvestment,
    string memory _regulatorCountry,
    string memory _regulatorAcronym,
    string memory _offeringType,
    string memory _bnbGreenfieldObjectName,
    uint256 _startTime,
    uint256 _endTime,
    uint256 _lockDuration,
    address _rewardToken,
    address _feeToken
) public onlyTokenAdmin(ctmRwaToken)
```
Allow an Issuer(tokenAdmin) to create a new investment Offering, with all parameters. One of the tokenAdmin's tokenIds is transferred to the contract and then when an investor invests, they get a tokenId, which is held by this contract for an escrow period, after which they can withdraw it.

**Parameters:**
- `_tokenId`: This is the tokenId of the tokenAdmin that is transferred to this contract. Its balance is the amount of the Offering and its Asset Class(slot) defines what is being offered
- `_price`: The price of 1 unit of value in the tokenId
- `_currency`: The ERC20 address of the token required to be invested
- `_minInvestment`: The minimum allowable investment
- `_maxInvestment`: The maximum allowable investment
- `_regulatorCountry`: The 2 letter Country Code of the Regulator
- `_regulatorAcronym`: The acronym of the Regulator
- `_offeringType`: The short AssetX description of the offering
- `_bnbGreenfieldObjectName`: The name of the object describing the offering in the BNB Greenfield Storage
- `_startTime`: The time after which offers will be accepted
- `_endTime`: The end time, after which offers will no longer be allowed
- `_lockDuration`: The time for which the investors tokenId will be held in escrow for. After this time they may unlock their tokenId into their own wallet. They may claim rewards during the escrow period
- `_rewardToken`: The address of the ERC20 token used for rewards. address(0) means no rewards
- `_feeToken`: The address of the ERC20 token used to pay fees to AssetX. See getFeeTokenList in the FeeManager contract for allowable fee addresses

### investInOffering()
```solidity
function investInOffering(uint256 _indx, uint256 _investment, address _feeToken) public nonReentrant returns (uint256)
```
An investor makes an investment for an Offering and is given a tokenId with a value corresponding to their investment and with the same Asset Class (slot). This is held in escrow in the contract for a period, during which they may still receive dividends.

### withdrawInvested()
```solidity
function withdrawInvested(uint256 _indx) public onlyTokenAdmin(ctmRwaToken) nonReentrant returns (uint256)
```
Allow an Issuer (tokenAdmin) to withdraw funds that have been invested in an Offering. The tokenAdmin can withdraw funds whenever there are funds to withdraw. No need to wait until after the Offering is over.

### unlockTokenId()
```solidity
function unlockTokenId(uint256 _myIndx, address _feeToken) public nonReentrant returns (uint256)
```
A holder of an investment can withdraw their tokenId from escrow into their possession.

## Reward System

### fundRewardTokenForOffering()
```solidity
function fundRewardTokenForOffering(uint256 _offeringIndex, uint256 _fundAmount, uint256 _rewardMultiplier, uint256 _rateDivisor) external nonReentrant onlyTokenAdmin(ctmRwaToken)
```
Allows the tokenAdmin to fund the ERC20 rewardToken for an offering and distribute rewards to all current holders. This function can only be called before the offering ends.

### getRewardInfo()
```solidity
function getRewardInfo(address holder, uint256 offerIndex, uint256 holdingIndex) external view returns (address rewardToken, uint256 rewardAmount)
```
Returns the rewardToken contract address for an offering and the rewardAmount for a specific Holding of a holder.

### claimReward()
```solidity
function claimReward(uint256 offerIndex, uint256 holdingIndex) external nonReentrant
```
Allows a holder to claim their reward for a specific holding.

**Restrictions for Claiming Rewards:**
- **Valid Offering Index**: The `offerIndex` must be less than the total number of offerings
- **Valid Holding Index**: The `holdingIndex` must be less than the holder's total holdings
- **Reward Token Required**: The offering must have a reward token set (not address(0))
- **Holding Must Exist**: The holding must exist in both the offering's holdings array and the holder's holdings mapping
- **Token ID Match**: The token ID in the offering's holdings must match the token ID in the holder's holdings
- **Reward Amount Available**: The holding must have a reward amount greater than 0
- **One-Time Claim**: Each reward can only be claimed once - the reward amount is set to 0 after claiming
- **Reentrancy Protection**: Function is protected against reentrancy attacks
- **Balance Validation**: The contract validates that the reward transfer was successful by checking balance changes

**Timing for Reward Operations:**
- **Reward Funding**: Can only be done BEFORE the offering ends (during the offering period)
- **Reward Claiming**: Can be done at ANY TIME after rewards have been funded (even after the offering ends)
- **No Time Restrictions**: Unlike funding, there are no timestamp restrictions on when rewards can be claimed
- **Persistent Rewards**: Once funded, rewards remain claimable indefinitely until claimed

## Remaining Balance Management

### removeRemainingTokenId()
```solidity
function removeRemainingTokenId(uint256 _indx, address _feeToken) public onlyTokenAdmin(ctmRwaToken) nonReentrant returns (uint256)
```
Allows the tokenAdmin to remove the remaining balance of a tokenId in an Offering after the end time. This function can only be called after the offering has ended and only if there is remaining balance.

## View Functions

### getTokenIdsInEscrow()
```solidity
function getTokenIdsInEscrow() public view returns (uint256[] memory, address[] memory)
```
Get the tokenIds and owners in escrow.

### offeringCount()
```solidity
function offeringCount() public view returns (uint256)
```
Get the total number of Offerings generated by the Issuer (tokenAdmin).

### listOfferings()
```solidity
function listOfferings() public view returns (Offering[] memory)
```
Return all the Offerings generated by the Issuer (tokenAdmin).

### listOffering()
```solidity
function listOffering(uint256 _offerIndx) public view returns (Offering memory)
```
Return the Offering made by the Issuer (tokenAdmin) at an index.

### escrowHoldingCount()
```solidity
function escrowHoldingCount(address _holder) public view returns (uint256)
```
Return the number of Holdings held by an address in this contract.

### listEscrowHoldings()
```solidity
function listEscrowHoldings(address _holder) public view returns (Holding[] memory)
```
Return all the Holding records held by an address.

### listEscrowHolding()
```solidity
function listEscrowHolding(address _holder, uint256 _myIndx) public view returns (Holding memory)
```
Return a Holding record of an address at an index.

## Internal Functions

### onCTMRWA1Received()
```solidity
function onCTMRWA1Received(address, uint256, uint256, uint256, bytes calldata) external pure override returns (bytes4)
```
Handle receipt of CTMRWA1 value when this contract holds escrowed tokenIds. Return the required magic value to accept transfers. No state changes here.

### _addTokenIdInEscrow()
```solidity
function _addTokenIdInEscrow(uint256 _tokenId, address _owner) internal
```
Add a tokenId and owner to the escrow arrays.

### _removeTokenIdInEscrow()
```solidity
function _removeTokenIdInEscrow(uint256 _tokenId) internal
```
Remove a tokenId and owner from the escrow arrays.

### _checkTokenAdmin()
```solidity
function _checkTokenAdmin(address _ctmRwaToken) internal
```
Check that msg.sender is the tokenAdmin of a CTMRWA1 address.

### _payFee()
```solidity
function _payFee(FeeType _feeType, address _feeToken) internal returns (bool)
```
Pay offering fees.

## Data Structures

### Offering
```solidity
struct Offering {
    uint256 tokenId;              // Token ID for the offering
    uint256 offerAmount;          // Total amount offered
    uint256 balRemaining;         // Remaining balance
    uint256 price;                // Price per unit
    address currency;             // Investment currency (ERC20)
    uint256 minInvestment;        // Minimum investment amount
    uint256 maxInvestment;        // Maximum investment amount
    uint256 investment;            // Total investment received
    string regulatorCountry;      // 2-letter country code
    string regulatorAcronym;      // Regulator identifier
    string offeringType;          // Offering description
    string bnbGreenfieldObjectName; // BNB Greenfield object name
    uint256 startTime;            // Investment start time
    uint256 endTime;              // Investment end time
    uint256 lockDuration;         // Escrow lock duration
    address rewardToken;          // Reward token address
    Holding[] holdings;           // Array of holdings
}
```

### Holding
```solidity
struct Holding {
    uint256 offerIndex;           // Offering index reference
    address investor;             // Investor address
    uint256 tokenId;              // Escrowed token ID
    uint256 escrowTime;           // Escrow end timestamp
    uint256 rewardAmount;         // Accumulated reward amount
}
```

## Events

- `CreateOffering(uint256 ID, uint256 indx, uint256 slot, uint256 offer)`: New offering creation
- `OfferingPaused(uint256 ID, uint256 indx, address account)`: Offering pause action
- `OfferingUnpaused(uint256 ID, uint256 indx, address account)`: Offering resume action
- `InvestInOffering(uint256 ID, uint256 indx, uint256 holdingIndx, uint256 investment)`: Investment completion
- `WithdrawFunds(uint256 ID, uint256 indx, uint256 funds)`: Fund withdrawal
- `UnlockInvestmentToken(uint256 ID, address holder, uint256 holdingIndx)`: Token unlocking
- `FundedRewardToken(uint256 offeringIndex, uint256 fundAmount, uint256 rewardMultiplier)`: Reward funding
- `RewardClaimed(address holder, uint256 offerIndex, uint256 holdingIndex, uint256 amount)`: Reward claiming
- `RemoveRemainingBalance(uint256 ID, uint256 indx, uint256 remainingBalance)`: Remaining balance removal
- `LateRewardFunding(uint256 offeringIndex)`: Late reward funding attempt

## Security Features

- ReentrancyGuard for state-changing flows
- Comprehensive input validation and parameter checks
- Access control via onlyTokenAdmin modifier
- Escrow security with time-based token locking
- Fee payment validation with balance checks
- Whitelist integration via Sentry contract
- Commission rate management
- Pause functionality for individual offerings

## Integration Points

- `CTMRWA1`: Main token contract for operations
- `CTMRWA1X`: Cross-chain coordinator for token transfers
- `CTMRWA1Dividend`: Dividend distribution system
- `CTMRWA1Sentry`: Access control and whitelisting
- `CTMRWAMap`: Multi-chain address mapping
- `FeeManager`: Fee calculation and collection
- `C3Caller`: Cross-chain communication system
- `BNB Greenfield`: Storage object references

## Error Handling

The contract uses custom error types for efficient gas usage:

- `CTMRWA1InvestWithTimeLock_OnlyAuthorized(CTMRWAErrorParam.Sender, CTMRWAErrorParam.TokenAdmin)`: Thrown when unauthorized address tries to perform action
- `CTMRWA1InvestWithTimeLock_InvalidContract(CTMRWAErrorParam.Token/Dividend/Sentry)`: Thrown when contract validation fails
- `CTMRWA1InvestWithTimeLock_OutOfBounds()`: Thrown when index is out of bounds
- `CTMRWA1InvestWithTimeLock_NonExistentToken(uint256 _tokenId)`: Thrown when token doesn't exist
- `CTMRWA1InvestWithTimeLock_MaxOfferings()`: Thrown when maximum offerings limit reached
- `CTMRWA1InvestWithTimeLock_InvalidLength(CTMRWAErrorParam.CountryCode/Offering/MinInvestment)`: Thrown when parameter length is invalid
- `CTMRWA1InvestWithTimeLock_Paused()`: Thrown when offering is paused
- `CTMRWA1InvestWithTimeLock_InvalidTimestamp(CTMRWAErrorParam.Early/Late)`: Thrown when timestamp is invalid
- `CTMRWA1InvestWithTimeLock_InvalidAmount(CTMRWAErrorParam.Value/Balance/InvestmentLow/InvestmentHigh/Commission)`: Thrown when amount is invalid
- `CTMRWA1InvestWithTimeLock_NotWhiteListed(address)`: Thrown when address is not whitelisted
- `CTMRWA1InvestWithTimeLock_AlreadyWithdrawn(uint256)`: Thrown when token already withdrawn
- `CTMRWA1InvestWithTimeLock_InvalidOfferingIndex()`: Thrown when offering index is invalid
- `CTMRWA1InvestWithTimeLock_InvalidHoldingIndex()`: Thrown when holding index is invalid
- `CTMRWA1InvestWithTimeLock_NoRewardToken()`: Thrown when no reward token set
- `CTMRWA1InvestWithTimeLock_NoRewardsToClaim()`: Thrown when no rewards to claim
- `CTMRWA1InvestWithTimeLock_HoldingNotFound()`: Thrown when holding not found
- `CTMRWA1InvestWithTimeLock_OfferingNotEnded()`: Thrown when offering hasn't ended
- `CTMRWA1InvestWithTimeLock_NoRemainingBalance()`: Thrown when no remaining balance
- `CTMRWA1InvestWithTimeLock_OfferingEnded(uint256)`: Thrown when offering has ended
- `CTMRWA1InvestWithTimeLock_FailedTransfer()`: Thrown when transfer fails

## Use Cases

### Investment Platform Setup
- Setting up investment capabilities for RWA tokens
- Creating structured investment offerings
- Managing multiple simultaneous offerings

### Capital Raising
- Raising capital through tokenized RWA offerings
- Managing investor relationships and holdings
- Processing investments with escrow protection

### Reward Distribution
- Distributing rewards to investors during lockup
- Managing reward token funding and distribution
- Enabling ongoing investor engagement

### Post-Offering Management
- Removing remaining balances after offerings end
- Managing offering lifecycle and cleanup
- Handling post-investment operations

## Best Practices

1. **Offering Planning**: Carefully plan offering parameters and timing
2. **Reward Management**: Design sustainable reward distribution models
3. **Fee Planning**: Account for all applicable fees in calculations
4. **Escrow Awareness**: Understand lockup periods and implications
5. **Regulatory Compliance**: Ensure all regulatory requirements are met
6. **Storage Management**: Properly reference BNB Greenfield objects

## Limitations

- Single Chain Operation: Each contract operates on a single blockchain
- Manual Management: Requires manual offering creation and management
- Fixed Terms: Offering terms cannot be modified after creation
- Gas Costs: Cross-chain operations incur additional gas expenses
- Market Liquidity: No secondary market for locked tokens
- Storage Dependency: BNB Greenfield object references required