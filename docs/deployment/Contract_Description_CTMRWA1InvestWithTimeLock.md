# CTMRWA1InvestWithTimeLock Contract Documentation

## Overview

**Contract Name:** CTMRWA1InvestWithTimeLock  
**Author:** @Selqui ContinuumDAO  
**License:** BSL-1.1  
**Solidity Version:** 0.8.27

The CTMRWA1InvestWithTimeLock contract allows an Issuer (tokenAdmin) to raise finance from investors. It can be deployed once on each chain that the RWA token is deployed to. The Issuer can create Offerings with start and end dates, min and max amounts to invest, and with a lock-up escrow period.

The investors can still claim rewards, sent to them by the Issuer, whilst their investments are locked up. Once the lockup period is over, the investors can withdraw their tokenIds. Issuers can create multiple simultaneous Offerings.

## Key Features

- **Investment Offerings:** Allows issuers to create investment opportunities with specific parameters
- **Time-locked Escrow:** Investors' tokens are held in escrow for a specified duration
- **Reward Distribution:** Supports reward token distribution to investors during lockup
- **Multi-offering Support:** Issuers can create multiple simultaneous offerings
- **Cross-chain Integration:** Works with the broader CTMRWA cross-chain architecture
- **Fee Management:** Integrated fee system for operations
- **Access Control:** Comprehensive permission system for different roles

## Public Variables

### Core Identifiers
- **`ID`** (uint256): Unique ID of the CTMRWA token contract
- **`RWA_TYPE`** (uint256, constant): RWA type defining CTMRWA1 (value: 1)
- **`VERSION`** (uint256, constant): Single integer version of this RWA type (value: 1)

### Contract Addresses
- **`ctmRwaToken`** (address): The token contract address corresponding to this ID
- **`ctmRwaDividend`** (address): The Dividend contract address corresponding to this ID
- **`ctmRwaSentry`** (address): The Sentry contract address corresponding to this ID
- **`ctmRwa1X`** (address): The CTMRWA1X contract address corresponding to this ID
- **`ctmRwaMap`** (address): Address of the CTMRWAMap contract
- **`feeManager`** (address): Address of the FeeManager contract
- **`tokenAdmin`** (address): The Token Admin of this CTMRWA

### Configuration
- **`decimalsRwa`** (uint8): The decimals of the CTMRWA1
- **`commissionRate`** (uint256): The commission rate payable to FeeManager 0-10000 (0.01%)
- **`cIdStr`** (string): String representation of the local chainID

### Offerings and Holdings
- **`offerings`** (Offering[]): A list of offerings to investors
- **`MAX_OFFERINGS`** (uint256, constant): Limit the number of Offerings to stop DDoS attacks (value: 100)
- **`holdingsByAddress`** (mapping(address => Holding[])): Mapping of address to holdings

### Escrow Management
- **`tokensInEscrow`** (uint256[]): Arrays of tokenIds in escrow
- **`ownersInEscrow`** (address[]): Arrays of owners in escrow

### Pause State
- **`_isOfferingPaused`** (mapping(uint256 => bool)): Mapping to track pause state for each offering index

## Data Structures

### Offering
```solidity
struct Offering {
    uint256 tokenId;              // Token ID used for the offering
    uint256 balTotal;             // Total balance available
    uint256 balRemaining;         // Remaining balance
    uint256 price;                // Price per unit
    address currency;             // Investment currency (ERC20)
    uint256 minInvestment;        // Minimum investment amount
    uint256 maxInvestment;        // Maximum investment amount
    uint256 investment;           // Total investment received
    string regulatorCountry;      // 2-letter country code of regulator
    string regulatorAcronym;      // Regulator acronym
    string offeringType;          // AssetX description of offering
    uint256 startTime;            // Start time for investments
    uint256 endTime;              // End time for investments
    uint256 lockDuration;         // Lock duration for escrow
    address rewardToken;          // Reward token address (0 for no rewards)
    Holding[] holdings;           // Array of holdings
}
```

### Holding
```solidity
struct Holding {
    uint256 offerIndex;           // Index of the offering
    address investor;             // Investor address
    uint256 tokenId;              // Token ID held in escrow
    uint256 escrowTime;           // Time when escrow ends
    uint256 rewardAmount;         // Accumulated reward amount
}
```

## Core Functions

### Constructor

#### `constructor(uint256 _ID, address _ctmRwaMap, uint256 _commissionRate, address _feeManager)`
- **Purpose:** Initializes the CTMRWA1InvestWithTimeLock contract instance
- **Parameters:**
  - `_ID`: Unique ID of the CTMRWA token contract
  - `_ctmRwaMap`: Address of the CTMRWAMap contract
  - `_commissionRate`: Commission rate payable to FeeManager (0-10000)
  - `_feeManager`: Address of the FeeManager contract
- **Initialization:**
  - Sets contract addresses and configuration
  - Retrieves related contract addresses from CTMRWAMap
  - Sets decimals and chain ID string
  - Validates contract existence

### Administrative Functions

#### `setTokenAdmin(address _tokenAdmin, bool _force)`
- **Access:** Only callable by tokenAdmin or CTMRWA1X
- **Purpose:** Changes the tokenAdmin address
- **Parameters:**
  - `_tokenAdmin`: New tokenAdmin address
  - `_force`: Whether to force the change even if there are Offerings
- **Security:** Prevents admin change if there are active offerings (unless forced)
- **Returns:** True if tokenAdmin was changed successfully

#### `pauseOffering(uint256 _indx)` / `unpauseOffering(uint256 _indx)` / `isOfferingPaused(uint256 _indx)`
- **Access:** Only callable by tokenAdmin
- **Purpose:** Controls the pause state of specific offerings
- **Parameters:**
  - `_indx`: Index of the offering to control
- **Events:** Emits OfferingPaused/OfferingUnpaused events

### Offering Management Functions

#### `createOffering(uint256 _tokenId, uint256 _price, address _currency, uint256 _minInvestment, uint256 _maxInvestment, string memory _regulatorCountry, string memory _regulatorAcronym, string memory _offeringType, uint256 _startTime, uint256 _endTime, uint256 _lockDuration, address _rewardToken, address _feeToken)`
- **Access:** Only callable by tokenAdmin
- **Purpose:** Creates a new investment offering
- **Parameters:**
  - `_tokenId`: Token ID of the tokenAdmin that is transferred to this contract
  - `_price`: Price of 1 unit of value in the tokenId
  - `_currency`: ERC20 address of the token required for investment
  - `_minInvestment`: Minimum allowable investment
  - `_maxInvestment`: Maximum allowable investment
  - `_regulatorCountry`: 2-letter country code of the regulator
  - `_regulatorAcronym`: Acronym of the regulator
  - `_offeringType`: Short AssetX description of the offering
  - `_startTime`: Time after which offers will be accepted
  - `_endTime`: End time after which offers will no longer be allowed
  - `_lockDuration`: Time for which investors' tokenIds will be held in escrow
  - `_rewardToken`: Address of ERC20 token used for rewards (0 for no rewards)
  - `_feeToken`: Address of ERC20 token used to pay fees
- **Requirements:**
  - Token ID must exist
  - Maximum offerings limit not exceeded
  - Valid parameter lengths
  - Valid investment amounts
- **Logic:**
  - Pays offering fee
  - Transfers token to contract
  - Creates new offering
  - Emits CreateOffering event

### Investment Functions

#### `investInOffering(uint256 _indx, uint256 _investment, address _feeToken)`
- **Purpose:** Allows an investor to make an investment in an offering
- **Parameters:**
  - `_indx`: Zero-based index of the offering
  - `_investment`: Investment amount being made
  - `_feeToken`: Address of ERC20 token used to pay fees
- **Requirements:**
  - Offering must exist and not be paused
  - Investment must be within time window
  - Investment must meet min/max requirements
  - Investor must have sufficient balance
  - Investor must be whitelisted
- **Logic:**
  - Pays investment fee
  - Calculates token value based on price and decimals
  - Transfers investment currency from investor
  - Creates new token ID for investor
  - Creates holding record
  - Adds token to escrow
- **Returns:** New token ID that was created

### Withdrawal Functions

#### `withdraw(address _contractAddr, uint256 _amount)`
- **Access:** Only callable by tokenAdmin
- **Purpose:** Emergency function to withdraw any ERC20 token held by contract
- **Parameters:**
  - `_contractAddr`: Address of the ERC20 token
  - `_amount`: Amount to withdraw
- **Note:** Emergency only function, normal route is withdrawInvested
- **Returns:** Balance of token withdrawn

#### `withdrawInvested(uint256 _indx)`
- **Access:** Only callable by tokenAdmin
- **Purpose:** Allows tokenAdmin to withdraw funds invested in an offering
- **Parameters:**
  - `_indx`: Zero-based index of the offering
- **Logic:**
  - Calculates commission
  - Transfers commission to fee manager
  - Transfers remaining funds to tokenAdmin
- **Returns:** Amount of funds withdrawn

#### `unlockTokenId(uint256 _myIndx, address _feeToken)`
- **Purpose:** Allows investor to withdraw their tokenId from escrow
- **Parameters:**
  - `_myIndx`: Zero-based index of the holding
  - `_feeToken`: Address of ERC20 token used to pay fees
- **Requirements:**
  - Escrow lock time must have passed
  - Token must still be in escrow
- **Logic:**
  - Removes token from escrow
  - Transfers token to investor
- **Returns:** Token ID that was unlocked

### Reward Functions

#### `fundRewardTokenForOffering(uint256 _offeringIndex, uint256 _fundAmount, uint256 _rewardMultiplier, uint256 _rateDivisor)`
- **Access:** Only callable by tokenAdmin
- **Purpose:** Funds reward tokens for an offering and distributes to holders
- **Parameters:**
  - `_offeringIndex`: Index of the offering to fund
  - `_fundAmount`: Amount of reward tokens to transfer
  - `_rewardMultiplier`: Reward rate per CTMRWA1 token
  - `_rateDivisor`: Scaling divisor to normalize decimals
- **Logic:**
  - Transfers reward tokens from tokenAdmin
  - Distributes rewards to all current holders
  - Updates reward amounts in holdings

#### `claimReward(uint256 offerIndex, uint256 holdingIndex)`
- **Purpose:** Allows holder to claim their reward for a specific holding
- **Parameters:**
  - `offerIndex`: Index of the offering
  - `holdingIndex`: Index of the holding for msg.sender
- **Requirements:**
  - Holding must exist
  - Reward amount must be greater than 0
- **Logic:**
  - Resets reward amount to 0
  - Transfers reward tokens to holder
- **Events:** Emits RewardClaimed event

### Query Functions

#### `getTokenIdsInEscrow()`
- **Purpose:** Gets the tokenIds and owners in escrow
- **Returns:** Arrays of token IDs and owners in escrow

#### `offeringCount()` / `listOfferings()` / `listOffering(uint256 _offerIndx)`
- **Purpose:** Returns offering information
- **Returns:** Number of offerings, all offerings, or specific offering

#### `escrowHoldingCount(address _holder)` / `listEscrowHoldings(address _holder)` / `listEscrowHolding(address _holder, uint256 _myIndx)`
- **Purpose:** Returns holding information for an address
- **Returns:** Number of holdings, all holdings, or specific holding

#### `getRewardInfo(address holder, uint256 offerIndex, uint256 holdingIndex)`
- **Purpose:** Returns reward information for a specific holding
- **Returns:** Reward token address and reward amount

## Internal Functions

### Escrow Management
- **`_addTokenIdInEscrow(uint256 _tokenId, address _owner)`**: Adds token to escrow arrays
- **`_removeTokenIdInEscrow(uint256 _tokenId)`**: Removes token from escrow arrays

### Access Control
- **`_checkTokenAdmin(address _ctmRwaToken)`**: Validates tokenAdmin permissions

### Fee Management
- **`_payFee(FeeType _feeType, address _feeToken)`**: Pays fees for operations

## Access Control Modifiers

- **`onlyTokenAdmin(address _ctmRwaToken)`**: Restricts access to tokenAdmin or CTMRWA1X
- **`nonReentrant`**: Prevents reentrancy attacks

## Events

The contract emits various events for tracking operations:

- **`CreateOffering(uint256 indexed ID, uint256 indx, uint256 slot, uint256 offer)`**: New offering created
- **`OfferingPaused(uint256 indexed ID, uint256 indexed indx, address account)`**: Offering paused
- **`OfferingUnpaused(uint256 indexed ID, uint256 indexed indx, address account)`**: Offering unpaused
- **`InvestInOffering(uint256 indexed ID, uint256 indx, uint256 holdingIndx, uint256 investment)`**: Investment made
- **`WithdrawFunds(uint256 indexed ID, uint256 indx, uint256 funds)`**: Funds withdrawn
- **`UnlockInvestmentToken(uint256 indexed ID, address holder, uint256 holdingIndx)`**: Token unlocked
- **`ClaimDividendInEscrow(uint256 indexed ID, address holder, uint256 unclaimed)`**: Dividend claimed
- **`FundedRewardToken(uint256 indexed offeringIndex, uint256 fundAmount, uint256 rewardMultiplier)`**: Rewards funded
- **`RewardClaimed(address indexed holder, uint256 indexed offerIndex, uint256 indexed holdingIndex, uint256 amount)`**: Reward claimed

## Security Features

1. **Reentrancy Protection:** Uses OpenZeppelin's ReentrancyGuard
2. **Access Control:** Comprehensive modifier system for different roles
3. **Input Validation:** Extensive validation of input parameters
4. **Escrow Management:** Secure token escrow with time-based unlocking
5. **Fee Integration:** Integrated fee system for operations
6. **Whitelist Support:** Integration with Sentry contract for access control
7. **Pause Functionality:** Ability to pause individual offerings

## Integration Points

- **CTMRWA1**: Main RWA token contract
- **CTMRWA1X**: Cross-chain coordinator
- **CTMRWA1Dividend**: Dividend distribution system
- **CTMRWA1Sentry**: Access control and whitelisting
- **CTMRWAMap**: Multi-chain address mapping
- **FeeManager**: Fee calculation and payment
- **C3Caller**: Cross-chain communication system

## Error Handling

The contract uses custom error types for efficient gas usage and clear error messages:

- Authorization errors
- Invalid offering index errors
- Invalid amount errors
- Invalid timestamp errors
- Contract existence errors
- Whitelist validation errors
- Escrow management errors

## Investment Process

### 1. Offering Creation
- **Step:** TokenAdmin creates offering with specific parameters
- **Requirements:** Valid token ID, parameters, and fee payment
- **Result:** New offering available for investment

### 2. Investment
- **Step:** Investor invests in offering
- **Requirements:** Sufficient balance, whitelist approval, valid timing
- **Result:** New token ID created and held in escrow

### 3. Reward Distribution
- **Step:** TokenAdmin funds rewards for offering
- **Requirements:** Valid offering and reward token
- **Result:** Rewards distributed to all current holders

### 4. Token Unlocking
- **Step:** Investor unlocks token after escrow period
- **Requirements:** Escrow time must have passed
- **Result:** Token transferred to investor's wallet

## Use Cases

### Capital Raising
- **Scenario:** Issuer needs to raise capital for RWA project
- **Process:** Create offering with specific terms and conditions
- **Benefit:** Structured capital raising with investor protection

### Investor Participation
- **Scenario:** Investors want to participate in RWA opportunities
- **Process:** Invest in offerings and receive tokens in escrow
- **Benefit:** Secure investment with time-locked protection

### Reward Distribution
- **Scenario:** Issuer wants to reward investors during lockup
- **Process:** Fund reward tokens and distribute to holders
- **Benefit:** Maintains investor engagement during lockup period

### Cross-chain Investment
- **Scenario:** Investment opportunities across multiple chains
- **Process:** Deploy investment contract on each chain
- **Benefit:** Access to broader investor base

## Best Practices

1. **Due Diligence:** Investors should thoroughly review offering terms
2. **Timing Management:** Monitor offering start/end times carefully
3. **Escrow Awareness:** Understand lockup periods before investing
4. **Reward Monitoring:** Track reward accumulation during lockup
5. **Fee Planning:** Account for fees in investment calculations

## Limitations

- **Single Chain:** Each contract operates on a single chain
- **Manual Management:** Requires manual offering creation and management
- **Fixed Terms:** Offering terms cannot be modified after creation
- **Gas Costs:** Cross-chain operations incur additional gas costs

## Future Enhancements

Potential improvements to the investment system:

1. **Automated Offerings:** Implement automated offering creation mechanisms
2. **Dynamic Terms:** Allow modification of offering terms under certain conditions
3. **Enhanced Rewards:** Implement more sophisticated reward distribution models
4. **Liquidity Features:** Add secondary market for locked tokens
5. **Analytics Integration:** Add comprehensive analytics and reporting features
