# CTMRWA1Dividend Contract Documentation

## Overview

**Contract Name:** CTMRWA1Dividend  
**Author:** @Selqui ContinuumDAO  
**License:** BSL-1.1  
**Solidity Version:** 0.8.27

The CTMRWA1Dividend contract manages dividend distribution to holders of tokenIds in a CTMRWA1 contract. It stores funds deposited by the tokenAdmin (Issuer) and allows holders to claim their dividends based on their token balances at specific funding checkpoints.

This contract is deployed by CTMRWADeployer once for every CTMRWA1 contract on each chain. Its ID matches the ID in CTMRWA1, and there are no cross-chain functions in this contract - it operates independently on each chain.

## Key Features

- **Dividend Management:** Manages dividend distribution to CTMRWA1 token holders
- **Slot-based Dividends:** Supports different dividend rates per asset class (slot)
- **Flexible Dividend Scaling:** Configurable dividend scaling per slot for precise dividend calculations
- **Checkpoint System:** Uses funding checkpoints for historical balance tracking
- **Pausable Operations:** Can pause dividend claiming during emergencies
- **Reentrancy Protection:** Uses ReentrancyGuard for claim security
- **Historical Rate Tracking:** Uses Checkpoints for dividend rate history
- **Investment Contract Integration:** Excludes investment contract balances from dividends
- **Midnight Alignment:** Aligns funding times to midnight for consistency
- **Decimal Handling:** Proper handling of different token decimal configurations
- **Overflow Protection:** Built-in protection against calculation overflows

## Public Variables

### Contract Addresses
- **`dividendToken`** (address): ERC20 token contract address used to distribute dividends
- **`tokenAddr`** (address): CTMRWA1 contract address linked to this contract
- **`tokenAdmin`** (address): TokenAdmin (Issuer) address (same as in CTMRWA1)
- **`ctmRwa1X`** (address): Address of the CTMRWA1X contract
- **`ctmRwa1Map`** (address): CTMRWAMap address

### Token Identification
- **`ID`** (uint256): ID for this contract (same as in linked CTMRWA1)
- **`RWA_TYPE`** (uint256, immutable): RWA type defining CTMRWA1
- **`VERSION`** (uint256, immutable): Single integer version of this RWA type

### Global Tracking
- **`totalDividendPayable`** (uint256): Total amount of dividends that have been funded
- **`totalDividendClaimed`** (uint256): Total amount of dividends that have been claimed

### Constants
- **`ONE_DAY`** (uint48, constant): One day in seconds (1 days)

## Data Structures

### DividendFunding
```solidity
struct DividendFunding {
    uint256 slot;           // The slot number for this funding
    uint48 fundingTime;     // The funding timestamp (aligned to midnight)
    uint256 fundingAmount;  // The amount of dividend tokens funded
}
```

## Core Functions

### Constructor

#### `constructor(uint256 _ID, address _tokenAddr, uint256 _rwaType, uint256 _version, address _map)`
- **Purpose:** Initializes a new CTMRWA1Dividend contract instance
- **Parameters:**
  - `_ID`: ID for this contract (same as CTMRWA1)
  - `_tokenAddr`: CTMRWA1 contract address
  - `_rwaType`: RWA type defining CTMRWA1
  - `_version`: Version of this RWA type
  - `_map`: CTMRWAMap contract address
- **Initialization:**
  - Sets token address and retrieves tokenAdmin from CTMRWA1
  - Sets ctmRwa1X address from CTMRWA1
  - Sets contract identification parameters
  - Establishes integration with CTMRWA ecosystem

### Administrative Functions

#### `setTokenAdmin(address _tokenAdmin)`
- **Access:** Only callable by CTMRWA1X or existing tokenAdmin
- **Purpose:** Change the tokenAdmin address
- **Parameters:** `_tokenAdmin` - New tokenAdmin address
- **Returns:** True if successful
- **Use Case:** Allows CTMRWA1X to update tokenAdmin across contracts

#### `setDividendToken(address _dividendToken)`
- **Access:** Only callable by tokenAdmin
- **Purpose:** Set the ERC20 dividend token used to pay holders
- **Parameters:** `_dividendToken` - Address of new ERC20 dividend token
- **Validation:** Can only be called once (dividendToken must be address(0))
- **Returns:** True if successful
- **Events:** Emits NewDividendToken event
- **Use Case:** Allows tokenAdmin to set the initial dividend token

#### `setDividendScaleBySlot(uint256 _slot, uint256 _dividendScale)`
- **Access:** Only callable by tokenAdmin
- **Purpose:** Set the dividend scale for a specific slot
- **Parameters:**
  - `_slot`: Asset Class (slot) number
  - `_dividendScale`: Dividend scale for the slot (default is 18)
- **Validation:** 
  - Can only be called once per slot
  - Cannot be called after dividend rate has been set for that slot
  - Scale must be greater than 0
- **Returns:** True if successful
- **Use Case:** Allows precise control over dividend calculations per slot

#### `changeDividendRate(uint256 _slot, uint256 _dividendPerUnit)`
- **Access:** Only callable by tokenAdmin
- **Purpose:** Set a new dividend rate for an Asset Class (slot)
- **Parameters:**
  - `_slot`: Asset Class (slot) number
  - `_dividendPerUnit`: New dividend rate per unit of this slot
- **Validation:** Ensures slot exists in CTMRWA1
- **Logic:** Adds new checkpoint with current timestamp and dividend rate
- **Returns:** True if successful
- **Events:** Emits ChangeDividendRate event
- **Note:** Must be called on each chain separately (not cross-chain)

### Query Functions

#### `getDividendRateBySlotAt(uint256 _slot, uint48 _timestamp)`
- **Purpose:** Returns the dividend rate for a slot at a specific timestamp
- **Parameters:**
  - `_slot`: Slot number in CTMRWA1
  - `_timestamp`: Timestamp to query rate for
- **Returns:** Dividend rate for the slot at the specified timestamp
- **Validation:** Ensures slot exists in CTMRWA1

#### `getDividendRateBySlot(uint256 _slot)`
- **Purpose:** Returns the current dividend rate for a slot
- **Parameters:** `_slot` - Slot number in CTMRWA1
- **Returns:** Current dividend rate for the slot
- **Validation:** Ensures slot exists in CTMRWA1

#### `getStoredDividendRateBySlotAt(uint256 _slot, uint48 _timestamp)`
- **Purpose:** Returns the stored dividend rate for a slot at a specific timestamp
- **Parameters:**
  - `_slot`: Slot number in CTMRWA1
  - `_timestamp`: Timestamp to query rate for
- **Returns:** Stored dividend rate for the slot at the specified timestamp
- **Use Case:** Internal calculations and external queries

#### `getDecimalInfo()`
- **Purpose:** Get decimal information for both CTMRWA1 and dividend token
- **Returns:** 
  - `ctmRwaDecimals`: Decimals of the CTMRWA1 token
  - `dividendDecimals`: Decimals of the dividend token
- **Use Case:** Understanding token decimal configurations for calculations

#### `getDividendPayableBySlot(uint256 _slot, address _holder)`
- **Purpose:** Get dividend payable for a specific slot to a holder since last claim
- **Parameters:**
  - `_slot`: Asset Class (slot)
  - `_holder`: Holder of the tokenId
- **Logic:** Calculates dividend based on historical balances and rates
- **Returns:** Dividend amount payable for the slot

#### `getDividendPayable(address _holder)`
- **Purpose:** Get total dividend payable for all Asset Classes (slots) to a holder
- **Parameters:** `_holder` - Holder of the tokenId
- **Logic:** Sums dividends across all slots for the holder
- **Returns:** Total dividend payable across all slots

#### `lastFundingBySlot(uint256 _slot)`
- **Purpose:** Returns the last funding timestamp for a given slot
- **Parameters:** `_slot` - Slot to get last funding timestamp for
- **Returns:** Last funding timestamp for the slot (0 if no funding)

### Dividend Management Functions

#### `getDividendToFund(uint256 _slot, uint256 _fundingTime)`
- **Purpose:** Calculate the dividend amount needed to fund for a specific slot and time
- **Parameters:**
  - `_slot`: Asset Class (slot) to calculate funding for
  - `_fundingTime`: Time to use for dividend calculation
- **Returns:** Amount of dividend tokens needed to fund
- **Logic:** 
  - Calculates supply excluding investment contract and tokenAdmin
  - Applies dividend rate and scaling
  - Returns calculated dividend amount

#### `fundDividend(uint256 _slot, uint256 _fundingTime)`
- **Access:** Only callable by tokenAdmin
- **Purpose:** Add new checkpoint and fund dividends for an Asset Class (slot)
- **Parameters:**
  - `_slot`: Asset Class (slot) to add dividends for
  - `_fundingTime`: Time to use for dividend calculation
- **Logic:**
  - Aligns funding time to midnight
  - Validates funding time constraints
  - Calculates total supply excluding investment contract and tokenAdmin
  - Calculates dividend payable based on rate, supply, and scaling
  - Transfers funds from tokenAdmin to contract
  - Adds new funding checkpoint
- **Validation:**
  - Ensures dividend token is set
  - Validates funding time is not in future
  - Ensures funding time is after last funding
  - Enforces 30-day minimum between fundings
- **Returns:** Amount of dividend funded
- **Events:** Emits FundDividend event
- **Security:** Uses nonReentrant modifier

#### `claimDividend()`
- **Purpose:** Allows a holder to claim all unclaimed dividends
- **Logic:**
  - Calculates total dividend payable across all slots
  - Updates lastClaimedIndex for all slots
  - Transfers dividend tokens to claimant
- **Validation:** Ensures sufficient balance in contract
- **Returns:** Amount of dividend claimed
- **Events:** Emits ClaimDividend event
- **Security:** Uses nonReentrant and whenDividendNotPaused modifiers

### Pause Functions

#### `pause()`
- **Access:** Only callable by tokenAdmin
- **Purpose:** Pause the contract (prevents dividend claiming)
- **Use Case:** Emergency pause during issues

#### `unpause()`
- **Access:** Only callable by tokenAdmin
- **Purpose:** Unpause the contract (resumes dividend claiming)
- **Use Case:** Resume operations after emergency

## Internal Functions

### Utility Functions
- **`_midnightBefore(uint256 _timestamp)`**: Returns timestamp of midnight (00:00:00 UTC) before input timestamp
  - Used to align funding times to midnight for consistency
- **`_calculateDividendAmount(uint256 _balance, uint256 _rate, uint256 _slot)`**: Calculates dividend amount with proper decimal handling
  - Applies dividend scaling and prevents overflow
  - Returns dividend amount in dividend token wei

## Access Control Modifiers

- **`onlyTokenAdmin`**: Restricts access to tokenAdmin or CTMRWA1X
  - Ensures only authorized parties can perform administrative functions
  - Allows CTMRWA1X to update tokenAdmin across contracts

- **`whenDividendNotPaused`**: Ensures contract is not paused
  - Prevents dividend claiming when contract is paused
  - Provides emergency control mechanism

## Events

- **`NewDividendToken(address newToken, address currentAdmin)`**: Emitted when dividend token is set
- **`ChangeDividendRate(uint256 slot, uint256 newDividend, address currentAdmin)`**: Emitted when dividend rate is changed
- **`FundDividend(uint256 dividendPayable, address dividendToken, address currentAdmin)`**: Emitted when dividends are funded
- **`ClaimDividend(address claimant, uint256 dividend, address dividendToken)`**: Emitted when dividends are claimed

## Security Features

1. **Access Control:** Only tokenAdmin can perform administrative functions
2. **Reentrancy Protection:** Uses ReentrancyGuard for claim and fund functions
3. **Pausable Operations:** Can pause dividend claiming during emergencies
4. **Balance Validation:** Ensures sufficient balance before transfers
5. **Time Validation:** Validates funding times and intervals
6. **Slot Validation:** Ensures slots exist in CTMRWA1 before operations
7. **Investment Contract Exclusion:** Excludes investment contract and tokenAdmin balances from dividends
8. **Checkpoint System:** Uses historical checkpoints for accurate dividend calculation
9. **Overflow Protection:** Built-in protection against calculation overflows
10. **One-time Operations:** Critical functions can only be called once

## Integration Points

- **CTMRWA1**: Core semi-fungible token contract providing balance data
- **CTMRWAMap**: Contract address registry for investment contract lookup
- **CTMRWA1X**: Cross-chain coordination contract for tokenAdmin updates
- **Investment Contracts**: Excluded from dividend calculations
- **ERC20 Tokens**: Used for dividend distribution

## Error Handling

The contract uses custom error types for efficient gas usage:

- **`CTMRWA1Dividend_OnlyAuthorized(CTMRWAErrorParam.Sender, CTMRWAErrorParam.TokenAdmin)`**: Thrown when unauthorized address tries to perform admin functions
- **`CTMRWA1Dividend_InvalidDividend(CTMRWAErrorParam.Balance)`**: Thrown when insufficient balance for operations
- **`CTMRWA1Dividend_InvalidDividendScale(uint256 scale)`**: Thrown when invalid dividend scale is provided
- **`CTMRWA1Dividend_ScaleAlreadySetOrRateSet(uint256 slot)`**: Thrown when trying to set scale after it's already set or rate is set
- **`CTMRWA1Dividend_CalculationOverflow(uint256 balance, uint256 rate)`**: Thrown when dividend calculation would overflow
- **`CTMRWA1Dividend_EnforcedPause()`**: Thrown when trying to claim dividends while paused
- **`CTMRWA1Dividend_InvalidSlot(uint256 slot)`**: Thrown when slot doesn't exist in CTMRWA1
- **`CTMRWA1Dividend_FundTokenNotSet()`**: Thrown when trying to fund without setting dividend token
- **`CTMRWA1Dividend_FundingTimeLow()`**: Thrown when funding time is not after last funding
- **`CTMRWA1Dividend_FundingTooFrequent()`**: Thrown when funding is attempted too frequently
- **`CTMRWA1Dividend_FundingTimeFuture()`**: Thrown when funding time is in the future
- **`CTMRWA1Dividend_FailedTransaction()`**: Thrown when token transfer fails

## Dividend Process

### 1. Dividend Token Setup
- **Step:** TokenAdmin sets dividend token (one-time operation)
- **Method:** Call setDividendToken with ERC20 token address
- **Result:** Dividend token is established for the contract

### 2. Dividend Scale Configuration
- **Step:** TokenAdmin sets dividend scale for specific slots
- **Method:** Call setDividendScaleBySlot with slot and scale
- **Result:** Dividend scaling is configured for precise calculations
- **Note:** Can only be called once per slot before rates are set

### 3. Dividend Rate Setting
- **Step:** TokenAdmin sets dividend rate for specific slot
- **Method:** Call changeDividendRate with slot and rate
- **Result:** New checkpoint added with current timestamp and rate

### 4. Dividend Funding
- **Step:** TokenAdmin funds dividends for specific slot
- **Method:** Call fundDividend with slot and funding time
- **Logic:** Calculate supply, determine dividend amount, transfer funds
- **Result:** New funding checkpoint added

### 5. Dividend Calculation
- **Step:** Calculate dividend payable for holder
- **Method:** Use getDividendPayable or getDividendPayableBySlot
- **Logic:** Sum dividends across funding checkpoints since last claim
- **Result:** Total dividend amount payable

### 6. Dividend Claiming
- **Step:** Holder claims dividends
- **Method:** Call claimDividend
- **Logic:** Transfer dividend tokens to holder, update claim indices
- **Result:** Dividend tokens transferred to holder

## Use Cases

### Regular Dividend Distribution
- **Scenario:** Issuer distributes regular dividends to token holders
- **Process:** Set dividend rates, fund dividends, holders claim
- **Benefit:** Provides regular income to RWA token holders

### Slot-based Dividends with Custom Scaling
- **Scenario:** Different dividend rates and scaling for different asset classes
- **Process:** Set different rates and scales per slot, fund per slot
- **Benefit:** Flexible and precise dividend structure based on asset performance

### Historical Dividend Tracking
- **Scenario:** Track dividend history for accounting and compliance
- **Process:** Use checkpoint system to maintain historical data
- **Benefit:** Accurate dividend tracking and reporting

### Emergency Pause
- **Scenario:** Pause dividend operations during issues
- **Process:** Use pause/unpause functions
- **Benefit:** Emergency control over dividend operations

### Precise Dividend Calculations
- **Scenario:** Handle different token decimal configurations
- **Process:** Use dividend scaling and decimal handling
- **Benefit:** Accurate dividend calculations regardless of token decimals

## Best Practices

1. **Initial Setup:** Set dividend token and scales before setting rates
2. **Regular Funding:** Fund dividends regularly to maintain consistent payouts
3. **Rate Planning:** Plan dividend rates based on asset performance
4. **Time Alignment:** Use consistent funding times (midnight alignment)
5. **Balance Monitoring:** Monitor contract balance for sufficient dividend funds
6. **Cross-chain Coordination:** Coordinate funding across all chains
7. **Scale Configuration:** Set appropriate dividend scales for each slot

## Limitations

- **Single Chain:** No cross-chain dividend functions
- **Investment Exclusion:** Investment contract and tokenAdmin balances excluded from dividends
- **Funding Frequency:** Minimum 30 days between fundings per slot
- **Token Dependency:** Requires dividend token to be set before funding
- **Historical Balance:** Requires CTMRWA1 to support historical balance queries
- **One-time Operations:** Dividend token and scales can only be set once
- **Scale Restrictions:** Cannot change dividend scale after rate is set

## Future Enhancements

Potential improvements to the dividend system:

1. **Cross-chain Dividends:** Implement cross-chain dividend distribution
2. **Automated Funding:** Add automated dividend funding mechanisms
3. **Dividend Analytics:** Add dividend tracking and analytics features
4. **Multi-token Support:** Support multiple dividend tokens simultaneously
5. **Dividend Streaming:** Implement continuous dividend streaming
6. **Dynamic Scaling:** Allow dynamic adjustment of dividend scales
7. **Batch Operations:** Support batch dividend operations for efficiency

## Checkpoint System

### Historical Rate Tracking
- **Method:** Uses OpenZeppelin Checkpoints for efficient historical data
- **Storage:** Stores dividend rates with timestamps
- **Query:** Enables efficient historical rate lookups
- **Benefits:** Gas-efficient historical data storage and retrieval

### Funding Checkpoints
- **Structure:** DividendFunding array with slot, timestamp, and amount
- **Purpose:** Track when dividends were funded for each slot
- **Usage:** Calculate dividends based on historical balances
- **Alignment:** Timestamps aligned to midnight for consistency

## Investment Contract Integration

### Balance Exclusion
- **Purpose:** Exclude investment contract and tokenAdmin balances from dividend calculations
- **Method:** Query investment contract balance and tokenAdmin balance, subtract from total supply
- **Benefit:** Ensures only active holders receive dividends
- **Logic:** `supplyInSlot = totalSupplyInSlot - supplyInInvestContract - tokenAdminBalance`

### Investment Contract Lookup
- **Method:** Use CTMRWAMap to find investment contract address
- **Validation:** Check if investment contract exists
- **Fallback:** Handle cases where investment contract doesn't exist

## Dividend Scaling System

### Purpose
- **Flexibility:** Allows different dividend scaling per slot
- **Precision:** Enables precise dividend calculations
- **Compatibility:** Handles different token decimal configurations

### Configuration
- **Default:** 18 decimals (standard for most tokens)
- **Custom:** Can be set to any value greater than 0
- **Restriction:** Can only be set once per slot before rates are set

### Calculation
- **Formula:** `dividendAmount = (balance * rate) / scale`
- **Scale:** Uses configured scale or CTMRWA1 decimals as fallback
- **Overflow Protection:** Built-in checks prevent calculation overflows

## Gas Optimization

### Claim Optimization
- **Batch Updates:** Update all slot claim indices in single transaction
- **Efficient Calculation:** Use optimized dividend calculation algorithms
- **Gas Estimation:** Always estimate gas before claiming

### Funding Optimization
- **Midnight Alignment:** Reduces timestamp calculation complexity
- **Checkpoint Efficiency:** Use efficient checkpoint storage
- **Validation Optimization:** Optimize validation checks

### Query Optimization
- **Cached Lookups:** Use efficient checkpoint lookups
- **Batch Operations:** Support batch dividend queries
- **Index-based Access:** Use array indices for efficient access

## Security Considerations

### Access Control
- **TokenAdmin Authorization:** Only authorized parties can perform admin functions
- **CTMRWA1X Integration:** Allows cross-contract tokenAdmin updates
- **Function Validation:** Validate all function parameters

### Financial Security
- **Balance Validation:** Ensure sufficient balance before transfers
- **Transfer Safety:** Use SafeERC20 for token transfers
- **Reentrancy Protection:** Prevent reentrancy attacks

### Time-based Security
- **Funding Time Validation:** Prevent future and invalid funding times
- **Frequency Limits:** Prevent excessive funding frequency
- **Historical Integrity:** Maintain accurate historical data

### Data Integrity
- **One-time Operations:** Critical functions can only be called once
- **Scale Validation:** Ensure dividend scales are valid
- **Overflow Protection:** Prevent calculation overflows

## Dividend Token Management

### Token Selection
- **One-time Setup:** Can only be set once
- **Flexibility:** Support any ERC20 token for dividends
- **Validation:** Ensure token is properly configured

### Token Operations
- **Funding:** Transfer tokens from tokenAdmin to contract
- **Distribution:** Transfer tokens from contract to holders
- **Balance Tracking:** Monitor contract balance for sufficient funds

### Decimal Handling
- **Automatic Detection:** Automatically detect token decimals
- **Scale Integration:** Integrate with dividend scaling system
- **Calculation Accuracy:** Ensure accurate dividend calculations
