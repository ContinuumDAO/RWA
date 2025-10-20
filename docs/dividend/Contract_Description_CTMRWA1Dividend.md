# CTMRWA1Dividend Contract Documentation

## Overview

**Contract Name:** CTMRWA1Dividend  
**File:** `src/dividend/CTMRWA1Dividend.sol`  
**License:** BSL-1.1  
**Author:** @Selqui ContinuumDAO

## Contract Description

This contract manages the dividend distribution to holders of tokenIds in a CTMRWA1 contract. It stores the funds deposited here by the tokenAdmin (Issuer) and allows holders to claim their dividends.

This contract is deployed by CTMRWADeployer on each chain once for every CTMRWA1 contract. Its ID matches the ID in CTMRWA1. There are no cross-chain functions in this contract.

### Key Features
- Dividend distribution to CTMRWA1 token holders
- Slot-based dividend management with different rates per asset class
- Flexible dividend scaling configuration per slot
- Checkpoint system for historical rate tracking
- Pausable operations for emergency control
- Reentrancy protection for claim security
- Investment contract balance exclusion
- Midnight alignment for consistent funding times
- Decimal handling for different token configurations
- Overflow protection for calculations

## State Variables

- `ONE_DAY (uint48, constant = 1 days)`: One day in seconds
- `dividendToken (address)`: The ERC20 token contract address used to distribute dividends
- `tokenAddr (address)`: The CTMRWA1 contract address linked to this contract
- `tokenAdmin (address)`: The tokenAdmin (Issuer) address. Same as in CTMRWA1
- `ctmRwa1X (address)`: The address of the CTMRWA1X contract
- `ctmRwa1Map (address)`: The CTMRWAMap address
- `ID (uint256)`: The ID for this contract. Same as in the linked CTMRWA1
- `RWA_TYPE (uint256, immutable)`: rwaType is the RWA type defining CTMRWA1
- `VERSION (uint256, immutable)`: version is the single integer version of this RWA type
- `totalDividendPayable (uint256)`: Global tracking variables
- `totalDividendClaimed (uint256)`: Global tracking variables
- `dividendFundings (DividendFunding[])`: Tracks the dividend fundings for each slot
- `lastClaimedIndex (mapping(uint256 => mapping(address => uint256)))`: Tracks the last claimed index for each holder and slot
- `_dividendRate (mapping(uint256 => Checkpoints.Trace208))`: slot => dividend rate
- `dividendScale (mapping(uint256 => uint256))`: slot => dividend scale

## Data Structures

### DividendFunding
```solidity
struct DividendFunding {
    uint256 slot;                        // The slot number for this funding
    uint48 fundingTime;                  // The funding timestamp (aligned to midnight)
    uint256 fundingAmount;               // The amount of dividend tokens funded
    string bnbGreenfieldObjectName;     // BNB Greenfield object name
}
```

## Constructor

```solidity
constructor(uint256 _ID, address _tokenAddr, uint256 _rwaType, uint256 _version, address _map)
```
- Initializes the CTMRWA1Dividend contract instance
- Sets token address and retrieves tokenAdmin from CTMRWA1
- Sets ctmRwa1X address from CTMRWA1
- Sets contract identification parameters
- Establishes integration with CTMRWA ecosystem

## Access Control

- `onlyTokenAdmin`: Restricts access to tokenAdmin or CTMRWA1X
- `whenDividendNotPaused`: Ensures contract is not paused

## Administrative Functions

### setTokenAdmin()
```solidity
function setTokenAdmin(address _tokenAdmin) external onlyTokenAdmin returns (bool)
```
Change the tokenAdmin address.

**Note:** This function can only be called by CTMRWA1X, or the existing tokenAdmin.

### setDividendToken()
```solidity
function setDividendToken(address _dividendToken) external onlyTokenAdmin returns (bool)
```
Set the ERC20 dividend token used to pay holders.

**Parameters:**
- `_dividendToken`: The address of the ERC20 token used to fund/pay for dividends

**Note:** This can only be called once. This function can only be called by the tokenAdmin (Issuer).

### setDividendScaleBySlot()
```solidity
function setDividendScaleBySlot(uint256 _slot, uint256 _dividendScale) external onlyTokenAdmin returns (bool)
```
Set the dividend scale for an Asset Class (slot).

**Parameters:**
- `_slot`: The Asset Class (slot) to set the dividend scale for
- `_dividendScale`: The dividend scale for the slot. Default is 18. Set to 0 to use per wei of the CTMRWA1 scaling

**Returns:** True if the dividend scale was set successfully

**Note:** This function can only be called once per slot and cannot be called after changeDividendRate has been called for that slot.

### changeDividendRate()
```solidity
function changeDividendRate(uint256 _slot, uint256 _dividendPerUnit) external onlyTokenAdmin returns (bool)
```
Change the dividend rate for an Asset Class (slot).

**Parameters:**
- `_slot`: The Asset Class (slot) to change the dividend rate for
- `_dividendPerUnit`: The dividend rate per CTMRWA1 unit. A unit is 10^18 CTMRWA1 base units by default, unless set to a different value in setDividendScaleBySlot

**Returns:** True if the dividend rate was changed successfully

## Query Functions

### getDividendRateBySlotAt()
```solidity
function getDividendRateBySlotAt(uint256 _slot, uint48 _timestamp) public view returns (uint256)
```
Returns the dividend rate for a slot in this CTMRWA1.

**Parameters:**
- `_slot`: The slot number in this CTMRWA1
- `_timestamp`: Timestamp to query rate for

**Returns:** The dividend rate for the slot

### getDividendRateBySlot()
```solidity
function getDividendRateBySlot(uint256 _slot) public view returns (uint256)
```
Returns the dividend rate for a slot in this CTMRWA1.

**Parameters:**
- `_slot`: The slot number in this CTMRWA1

**Returns:** The dividend rate for the slot

### getStoredDividendRateBySlotAt()
```solidity
function getStoredDividendRateBySlotAt(uint256 _slot, uint48 _timestamp) public view returns (uint256)
```
Public function to get the stored dividend rate.

**Parameters:**
- `_slot`: The slot number in this CTMRWA1
- `_timestamp`: Timestamp to query rate for

**Returns:** The stored dividend rate for the slot at the specified timestamp

### getDecimalInfo()
```solidity
function getDecimalInfo() public view returns (uint8 ctmRwaDecimals, uint8 dividendDecimals)
```
Get the decimal information for both CTMRWA1 and dividend token.

**Returns:**
- `ctmRwaDecimals`: The decimals of the CTMRWA1 token
- `dividendDecimals`: The decimals of the dividend token

### getDividendPayableBySlot()
```solidity
function getDividendPayableBySlot(uint256 _slot, address _holder) public view returns (uint256)
```
Get the dividend to be paid out for an Asset Class (slot) to a holder since the last claim.

**Parameters:**
- `_slot`: The Asset Class (slot)
- `_holder`: The holder of the tokenId

**Returns:** The dividend to be paid out

### getDividendPayable()
```solidity
function getDividendPayable(address _holder) public view returns (uint256)
```
Get the total dividend payable for all Asset Classes (slots) in the RWA.

**Parameters:**
- `_holder`: The holder of the tokenId

**Returns:** The total dividend payable

### lastFundingBySlot()
```solidity
function lastFundingBySlot(uint256 _slot) public view returns (uint48)
```
Returns the last funding timestamp for a given slot.

**Parameters:**
- `_slot`: The slot to get the last funding timestamp for

**Returns:** The last funding timestamp for the slot (0 if no funding)

## Dividend Management Functions

### getDividendToFund()
```solidity
function getDividendToFund(uint256 _slot, uint256 _fundingTime) public view returns(uint256)
```
Get the dividend to fund for a given slot and funding time.

**Parameters:**
- `_slot`: The slot to get the dividend to fund for
- `_fundingTime`: The time to get the dividend to fund for

**Returns:** The dividend to fund

### fundDividend()
```solidity
function fundDividend(uint256 _slot, uint256 _fundingTime, string memory _bnbGreenfieldObjectName) public onlyTokenAdmin nonReentrant returns (uint256)
```
Add a new checkpoint for claiming dividends for an Asset Class (slot). The function then calculates how much dividend is needed to transfer to this contract to pay the dividends and then transfers the funds to this contract ready for claiming by all holders of tokenIds in the RWA token. It takes payment in the current dividend token.

**Parameters:**
- `_slot`: The Asset Class (slot) to add dividends for
- `_fundingTime`: The time to use to calculate the dividend
- `_bnbGreenfieldObjectName`: BNB Greenfield object name

**Note:** The actual funding time is calculated to be at midnight prior to _fundingTime. The actual funding time must be a time after the previous time (dividendFundedAt). This is not a cross-chain function. It must be called on each chain in the RWA. Use Multicall with the same _fundingTime to prevent arbitrage.

### claimDividend()
```solidity
function claimDividend() public nonReentrant whenDividendNotPaused returns (uint256)
```
This allows a holder to claim all of their unclaimed dividends.

**Returns:** The amount of dividend claimed

**Note:** The holder can see the dividendtoken address using the dividendToken() function.

## Pause Functions

### pause()
```solidity
function pause() external onlyTokenAdmin
```
Pause the contract. Only callable by tokenAdmin.

### unpause()
```solidity
function unpause() external onlyTokenAdmin
```
Unpause the contract. Only callable by tokenAdmin.

## Internal Functions

### _midnightBefore()
```solidity
function _midnightBefore(uint256 _timestamp) internal pure returns (uint48)
```
Returns the timestamp of midnight (00:00:00 UTC) before the input timestamp.

### _calculateDividendAmount()
```solidity
function _calculateDividendAmount(uint256 _balance, uint256 _rate, uint256 _slot) internal view returns (uint256)
```
Calculate dividend amount with proper decimal handling.

**Parameters:**
- `_balance`: The amount of CTMRWA1 in wei
- `_rate`: The dividend rate (already adjusted for decimals of CTMRWA1)
- `_slot`: The slot to calculate the dividend amount for

**Returns:** The calculated dividend amount in dividend token wei

## Events

- `NewDividendToken(address newToken, address currentAdmin)`: Emitted when dividend token is set
- `ChangeDividendRate(uint256 slot, uint256 newDividend, address currentAdmin)`: Emitted when dividend rate is changed
- `FundDividend(uint256 dividendPayable, address dividendToken, address currentAdmin)`: Emitted when dividends are funded
- `ClaimDividend(address claimant, uint256 dividend, address dividendToken)`: Emitted when dividends are claimed

## Security Features

- Access control via onlyTokenAdmin modifier
- Reentrancy protection for claim and fund functions
- Pausable operations for emergency control
- Balance validation before transfers
- Time validation for funding times and intervals
- Slot validation ensures slots exist in CTMRWA1
- Investment contract exclusion from dividend calculations
- Checkpoint system for accurate dividend calculation
- Overflow protection for calculations
- One-time operations for critical functions

## Integration Points

- `CTMRWA1`: Core semi-fungible token contract providing balance data
- `CTMRWAMap`: Contract address registry for investment contract lookup
- `CTMRWA1X`: Cross-chain coordination contract for tokenAdmin updates
- `Investment Contracts`: Excluded from dividend calculations
- `ERC20 Tokens`: Used for dividend distribution

## Error Handling

The contract uses custom error types for efficient gas usage:

- `CTMRWA1Dividend_OnlyAuthorized(CTMRWAErrorParam.Sender, CTMRWAErrorParam.TokenAdmin)`: Thrown when unauthorized address tries to perform admin functions
- `CTMRWA1Dividend_InvalidDividend(CTMRWAErrorParam.Balance)`: Thrown when insufficient balance for operations
- `CTMRWA1Dividend_InvalidDividendScale(uint256 scale)`: Thrown when invalid dividend scale is provided
- `CTMRWA1Dividend_ScaleAlreadySetOrRateSet(uint256 slot)`: Thrown when trying to set scale after it's already set or rate is set
- `CTMRWA1Dividend_CalculationOverflow(uint256 balance, uint256 rate)`: Thrown when dividend calculation would overflow
- `CTMRWA1Dividend_EnforcedPause()`: Thrown when trying to claim dividends while paused
- `CTMRWA1Dividend_InvalidSlot(uint256 slot)`: Thrown when slot doesn't exist in CTMRWA1
- `CTMRWA1Dividend_FundTokenNotSet()`: Thrown when trying to fund without setting dividend token
- `CTMRWA1Dividend_FundingTimeLow()`: Thrown when funding time is not after last funding
- `CTMRWA1Dividend_FundingTooFrequent()`: Thrown when funding is attempted too frequently
- `CTMRWA1Dividend_FundingTimeFuture()`: Thrown when funding time is in the future
- `CTMRWA1Dividend_FailedTransfer()`: Thrown when token transfer fails

## Dividend Process

### 1. Dividend Token Setup
- TokenAdmin sets dividend token (one-time operation)
- Call setDividendToken with ERC20 token address
- Dividend token is established for the contract

### 2. Dividend Scale Configuration
- TokenAdmin sets dividend scale for specific slots
- Call setDividendScaleBySlot with slot and scale
- Dividend scaling is configured for precise calculations
- Can only be called once per slot before rates are set

### 3. Dividend Rate Setting
- TokenAdmin sets dividend rate for specific slot
- Call changeDividendRate with slot and rate
- New checkpoint added with current timestamp and rate

### 4. Dividend Funding
- TokenAdmin funds dividends for specific slot
- Call fundDividend with slot, funding time, and BNB Greenfield object name
- Calculate supply, determine dividend amount, transfer funds
- New funding checkpoint added

### 5. Dividend Calculation
- Calculate dividend payable for holder
- Use getDividendPayable or getDividendPayableBySlot
- Sum dividends across funding checkpoints since last claim
- Total dividend amount payable

### 6. Dividend Claiming
- Holder claims dividends
- Call claimDividend
- Transfer dividend tokens to holder, update claim indices
- Dividend tokens transferred to holder

## Use Cases

### Regular Dividend Distribution
- Issuer distributes regular dividends to token holders
- Set dividend rates, fund dividends, holders claim
- Provides regular income to RWA token holders

### Slot-based Dividends with Custom Scaling
- Different dividend rates and scaling for different asset classes
- Set different rates and scales per slot, fund per slot
- Flexible and precise dividend structure based on asset performance

### Historical Dividend Tracking
- Track dividend history for accounting and compliance
- Use checkpoint system to maintain historical data
- Accurate dividend tracking and reporting

### Emergency Pause
- Pause dividend operations during issues
- Use pause/unpause functions
- Emergency control over dividend operations

### Precise Dividend Calculations
- Handle different token decimal configurations
- Use dividend scaling and decimal handling
- Accurate dividend calculations regardless of token decimals

## Best Practices

1. **Initial Setup**: Set dividend token and scales before setting rates
2. **Regular Funding**: Fund dividends regularly to maintain consistent payouts
3. **Rate Planning**: Plan dividend rates based on asset performance
4. **Time Alignment**: Use consistent funding times (midnight alignment)
5. **Balance Monitoring**: Monitor contract balance for sufficient dividend funds
6. **Cross-chain Coordination**: Coordinate funding across all chains
7. **Scale Configuration**: Set appropriate dividend scales for each slot

## Limitations

- Single Chain: No cross-chain dividend functions
- Investment Exclusion: Investment contract and tokenAdmin balances excluded from dividends
- Funding Frequency: Minimum 30 days between fundings per slot
- Token Dependency: Requires dividend token to be set before funding
- Historical Balance: Requires CTMRWA1 to support historical balance queries
- One-time Operations: Dividend token and scales can only be set once
- Scale Restrictions: Cannot change dividend scale after rate is set

## Checkpoint System

### Historical Rate Tracking
- Uses OpenZeppelin Checkpoints for efficient historical data
- Stores dividend rates with timestamps
- Enables efficient historical rate lookups
- Gas-efficient historical data storage and retrieval

### Funding Checkpoints
- DividendFunding array with slot, timestamp, amount, and BNB Greenfield object name
- Track when dividends were funded for each slot
- Calculate dividends based on historical balances
- Timestamps aligned to midnight for consistency

## Investment Contract Integration

### Balance Exclusion
- Exclude investment contract and tokenAdmin balances from dividend calculations
- Query investment contract balance and tokenAdmin balance, subtract from total supply
- Ensures only active holders receive dividends
- Logic: `supplyInSlot = totalSupplyInSlot - supplyInInvestContract - tokenAdminBalance`

### Investment Contract Lookup
- Use CTMRWAMap to find investment contract address
- Check if investment contract exists
- Handle cases where investment contract doesn't exist

## Dividend Scaling System

### Purpose
- Flexibility: Allows different dividend scaling per slot
- Precision: Enables precise dividend calculations
- Compatibility: Handles different token decimal configurations

### Configuration
- Default: 18 decimals (standard for most tokens)
- Custom: Can be set to any value greater than 0
- Restriction: Can only be set once per slot before rates are set

### Calculation
- Formula: `dividendAmount = (balance * rate) / scale`
- Scale: Uses configured scale or CTMRWA1 decimals as fallback
- Overflow Protection: Built-in checks prevent calculation overflows

## Gas Optimization

### Claim Optimization
- Batch Updates: Update all slot claim indices in single transaction
- Efficient Calculation: Use optimized dividend calculation algorithms
- Gas Estimation: Always estimate gas before claiming

### Funding Optimization
- Midnight Alignment: Reduces timestamp calculation complexity
- Checkpoint Efficiency: Use efficient checkpoint storage
- Validation Optimization: Optimize validation checks

### Query Optimization
- Cached Lookups: Use efficient checkpoint lookups
- Batch Operations: Support batch dividend queries
- Index-based Access: Use array indices for efficient access

## Security Considerations

### Access Control
- TokenAdmin Authorization: Only authorized parties can perform admin functions
- CTMRWA1X Integration: Allows cross-contract tokenAdmin updates
- Function Validation: Validate all function parameters

### Financial Security
- Balance Validation: Ensure sufficient balance before transfers
- Transfer Safety: Use SafeERC20 for token transfers
- Reentrancy Protection: Prevent reentrancy attacks

### Time-based Security
- Funding Time Validation: Prevent future and invalid funding times
- Frequency Limits: Prevent excessive funding frequency
- Historical Integrity: Maintain accurate historical data

### Data Integrity
- One-time Operations: Critical functions can only be called once
- Scale Validation: Ensure dividend scales are valid
- Overflow Protection: Prevent calculation overflows

## Dividend Token Management

### Token Selection
- One-time Setup: Can only be set once
- Flexibility: Support any ERC20 token for dividends
- Validation: Ensure token is properly configured

### Token Operations
- Funding: Transfer tokens from tokenAdmin to contract
- Distribution: Transfer tokens from contract to holders
- Balance Tracking: Monitor contract balance for sufficient funds

### Decimal Handling
- Automatic Detection: Automatically detect token decimals
- Scale Integration: Integrate with dividend scaling system
- Calculation Accuracy: Ensure accurate dividend calculations