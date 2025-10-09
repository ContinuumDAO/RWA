# CTMRWA1InvestWithTimeLock Contract Documentation

## Table of Contents
1. [Overview](#overview)
2. [Contract Specifications](#contract-specifications)
3. [Architecture & Design](#architecture--design)
4. [Core Functions](#core-functions)
5. [Data Structures](#data-structures)
6. [Security & Access Control](#security--access-control)
7. [Integration Points](#integration-points)
8. [Investment Workflow](#investment-workflow)
9. [Error Handling](#error-handling)
10. [Best Practices & Limitations](#best-practices--limitations)

## Overview

**Contract Name:** CTMRWA1InvestWithTimeLock  
**Author:** @Selqui ContinuumDAO  
**License:** BSL-1.1  
**Solidity Version:** 0.8.27  
**Contract Type:** Investment & Escrow Management

The CTMRWA1InvestWithTimeLock contract is a sophisticated investment platform that enables Real World Asset (RWA) token issuers to raise capital through structured offerings with time-locked escrow functionality. This contract serves as a bridge between issuers seeking capital and investors looking for RWA opportunities.

### Key Capabilities
- **Investment Offerings:** Create and manage multiple simultaneous investment opportunities
- **Time-locked Escrow:** Secure token holding with configurable lockup periods
- **Reward Distribution:** Distribute rewards to investors during lockup periods
- **Cross-chain Integration:** Seamless integration with the CTMRWA cross-chain ecosystem
- **Fee Management:** Integrated fee system for sustainable operations
- **Access Control:** Comprehensive permission system with role-based security
- **BNB Greenfield Integration:** Support for BNB Greenfield storage object references

## Contract Specifications

### Core Identifiers
| Variable | Type | Value | Description |
|----------|------|-------|-------------|
| `ID` | `uint256` | Dynamic | Unique identifier of the CTMRWA token contract |
| `RWA_TYPE` | `uint256` | `1` | RWA type defining CTMRWA1 (constant) |
| `VERSION` | `uint256` | `1` | Version of this RWA type (constant) |

### Contract Addresses
| Variable | Type | Description |
|----------|------|-------------|
| `ctmRwaToken` | `address` | Main RWA token contract address |
| `ctmRwaDividend` | `address` | Dividend distribution contract address |
| `ctmRwaSentry` | `address` | Access control and whitelisting contract |
| `ctmRwa1X` | `address` | Cross-chain coordinator contract |
| `ctmRwaMap` | `address` | Multi-chain address mapping contract |
| `feeManager` | `address` | Fee calculation and collection contract |
| `tokenAdmin` | `address` | Administrative account for this contract |

### Configuration Parameters
| Variable | Type | Description |
|----------|------|-------------|
| `decimalsRwa` | `uint8` | Decimal precision of the RWA token |
| `commissionRate` | `uint256` | Fee commission rate (0-10000, representing 0.01% increments) |
| `cIdStr` | `string` | String representation of the local chain ID |
| `MAX_OFFERINGS` | `uint256` | Maximum number of simultaneous offerings (100) |

## Architecture & Design

### Core Components
```
CTMRWA1InvestWithTimeLock
├── Offering Management
│   ├── Creation & Configuration
│   ├── Investment Processing
│   └── Pause/Resume Controls
├── Escrow System
│   ├── Token Locking
│   ├── Time-based Unlocking
│   └── Security Validation
├── Reward Distribution
│   ├── Funding Mechanisms
│   ├── Distribution Logic
│   └── Claim Processing
├── BNB Greenfield Integration
│   ├── Object Reference Storage
│   └── Metadata Management
└── Access Control
    ├── Role-based Permissions
    ├── Whitelist Integration
    └── Security Modifiers
```

### State Management
- **Offerings Array:** Dynamic array of investment opportunities
- **Holdings Mapping:** Address-based holding records
- **Escrow Arrays:** Parallel arrays for token and owner tracking
- **Pause States:** Individual offering pause controls

## Core Functions

### Constructor
```solidity
constructor(
    uint256 _ID,
    address _ctmRwaMap,
    uint256 _commissionRate,
    address _feeManager
)
```

**Purpose:** Initializes the contract with essential parameters and validates dependencies.

**Initialization Flow:**
1. Sets contract identifiers and addresses
2. Retrieves related contract addresses from CTMRWAMap
3. Validates contract existence and permissions
4. Sets configuration parameters

### Administrative Functions

#### Token Admin Management
```solidity
function setTokenAdmin(address _tokenAdmin, bool _force) external returns (bool)
```

**Security Features:**
- Prevents admin changes during active offerings (unless forced)
- Only callable by current tokenAdmin or CTMRWA1X
- Emits events for transparency

#### Offering Controls
```solidity
function pauseOffering(uint256 _indx) external
function unpauseOffering(uint256 _indx) external
function isOfferingPaused(uint256 _indx) external view returns (bool)
```

**Use Cases:**
- Emergency pause for security incidents
- Regulatory compliance requirements
- Market condition adjustments

### Investment Management

#### Offering Creation
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
) external
```

**Parameters:**
- `_tokenId`: Token ID of the tokenAdmin that is transferred to this contract
- `_price`: Price of 1 unit of value in the tokenId
- `_currency`: ERC20 address of the token required for investment
- `_minInvestment`: Minimum allowable investment amount
- `_maxInvestment`: Maximum allowable investment amount
- `_regulatorCountry`: 2-letter country code of the regulator (max 2 characters)
- `_regulatorAcronym`: Acronym of the regulator
- `_offeringType`: Short description of the offering (max 128 characters)
- `_bnbGreenfieldObjectName`: Name of the object describing the offering in BNB Greenfield Storage
- `_startTime`: Time after which offers will be accepted
- `_endTime`: End time after which offers will no longer be allowed
- `_lockDuration`: Time for which investors' tokenIds will be held in escrow
- `_rewardToken`: Address of ERC20 token used for rewards (address(0) for no rewards)
- `_feeToken`: Address of ERC20 token used to pay fees

**Validation Requirements:**
- Token ID existence verification
- Maximum offerings limit check
- Parameter length validation (regulatorCountry ≤ 2 chars, offeringType ≤ 128 chars)
- Investment amount validation
- Fee payment verification
- Reward token contract validation (if not address(0))

#### Investment Processing
```solidity
function investInOffering(
    uint256 _indx,
    uint256 _investment,
    address _feeToken
) external returns (uint256)
```

**Investment Flow:**
1. **Validation:** Offering existence, timing, and investor eligibility
2. **Fee Payment:** Investment fee collection
3. **Token Creation:** New token ID generation for investor
4. **Escrow Setup:** Token placement in time-locked escrow
5. **Record Creation:** Holding record establishment

### Escrow Management

#### Token Unlocking
```solidity
function unlockTokenId(uint256 _myIndx, address _feeToken) external returns (uint256)
```

**Unlocking Process:**
1. **Time Validation:** Ensures escrow period has elapsed
2. **Escrow Verification:** Confirms token is still in escrow
3. **Token Transfer:** Moves token from escrow to investor
4. **State Update:** Removes token from escrow arrays

### Reward System

#### Reward Funding
```solidity
function fundRewardTokenForOffering(
    uint256 _offeringIndex,
    uint256 _fundAmount,
    uint256 _rewardMultiplier,
    uint256 _rateDivisor
) external
```

**Distribution Logic:**
- Transfers reward tokens from tokenAdmin
- Calculates rewards based on holding amounts
- Updates reward amounts in holdings
- Supports dynamic reward rates

#### Reward Claiming
```solidity
function claimReward(uint256 offerIndex, uint256 holdingIndex) external
```

**Claim Process:**
1. **Validation:** Holding existence and reward amount verification
2. **Reward Transfer:** Token transfer to holder
3. **State Reset:** Reward amount reset to zero
4. **Event Emission:** Claim confirmation event

### New Functions

#### Remaining Balance Management
```solidity
function removeRemainingTokenId(uint256 _indx, address _feeToken) external returns (uint256)
```

**Purpose:** Allows tokenAdmin to remove remaining balance after offering ends

**Requirements:**
- Offering must have ended
- Must have remaining balance
- Fee payment required

**Process:**
1. Validates offering has ended
2. Checks for remaining balance
3. Pays removal fee
4. Creates new token ID for remaining balance
5. Transfers to tokenAdmin
6. Sets remaining balance to zero

## Data Structures

### Offering Structure
```solidity
struct Offering {
    uint256 tokenId;              // Token ID for the offering
    uint256 offerAmount;          // Total amount offered (NEW: renamed from balTotal)
    uint256 balRemaining;         // Remaining balance
    uint256 price;                // Price per unit
    address currency;             // Investment currency (ERC20)
    uint256 minInvestment;        // Minimum investment amount
    uint256 maxInvestment;        // Maximum investment amount
    uint256 investment;           // Total investment received
    string regulatorCountry;      // 2-letter country code
    string regulatorAcronym;      // Regulator identifier
    string offeringType;          // Offering description
    string bnbGreenfieldObjectName; // BNB Greenfield object name (NEW)
    uint256 startTime;            // Investment start time
    uint256 endTime;              // Investment end time
    uint256 lockDuration;         // Escrow lock duration
    address rewardToken;          // Reward token address
    Holding[] holdings;           // Array of holdings
}
```


### Holding Structure
```solidity
struct Holding {
    uint256 offerIndex;           // Offering index reference
    address investor;             // Investor address
    uint256 tokenId;              // Escrowed token ID
    uint256 escrowTime;           // Escrow end timestamp
    uint256 rewardAmount;         // Accumulated reward amount
}
```

## Security & Access Control

### Access Control Modifiers
- **`onlyTokenAdmin(address _ctmRwaToken)`**: Restricts access to authorized administrators
- **`nonReentrant`**: Prevents reentrancy attacks using OpenZeppelin's ReentrancyGuard

### Security Features
1. **Reentrancy Protection:** Comprehensive guard against reentrancy attacks
2. **Input Validation:** Extensive parameter validation and sanitization
3. **Access Restrictions:** Role-based permission system
4. **Escrow Security:** Time-based token locking with validation
5. **Fee Integration:** Secure fee collection and distribution
6. **Whitelist Support:** Integration with Sentry contract for access control

### Pause Functionality
- **Individual Offering Control:** Each offering can be paused independently
- **Emergency Response:** Quick response to security incidents
- **Selective Operation:** Maintains functionality for other offerings

## Integration Points

### Core System Integration
```
CTMRWA1InvestWithTimeLock
├── CTMRWA1 (Main Token)
├── CTMRWA1X (Cross-chain)
├── CTMRWA1Dividend (Rewards)
├── CTMRWA1Sentry (Security)
├── CTMRWAMap (Addresses)
├── FeeManager (Fees)
├── C3Caller (Cross-chain)
└── BNB Greenfield (Storage)
```

### Integration Benefits
- **Seamless Token Operations:** Direct integration with main token contract
- **Cross-chain Capabilities:** Support for multi-chain deployments
- **Unified Fee System:** Consistent fee management across ecosystem
- **Security Integration:** Comprehensive access control and whitelisting
- **Storage Integration:** BNB Greenfield object reference support

## Investment Workflow

### 1. Offering Creation Phase
```
TokenAdmin → Create Offering → Set Parameters → Pay Fees → Activate
```

**Key Parameters:**
- Investment terms and conditions
- Regulatory compliance information
- Timing and lockup specifications
- Reward token configuration
- BNB Greenfield object reference

### 2. Investment Phase
```
Investor → Validate Eligibility → Invest → Receive Tokens → Escrow Lock
```

**Eligibility Checks:**
- Whitelist verification
- Balance sufficiency
- Investment amount validation
- Timing compliance

### 3. Reward Distribution Phase
```
TokenAdmin → Fund Rewards → Calculate Distribution → Update Balances
```

**Distribution Logic:**
- Proportional to holding amounts
- Dynamic reward rate support
- Automatic balance updates

### 4. Token Unlocking Phase
```
Investor → Wait Lockup → Pay Unlock Fee → Receive Tokens
```

**Unlocking Requirements:**
- Escrow period completion
- Fee payment verification
- State validation

### 5. Post-Offering Management Phase
```
TokenAdmin → Remove Remaining Balance → Create New Token → Cleanup
```

**Management Process:**
- Wait for offering to end
- Remove remaining balance
- Create new token for remaining amount
- Clean up offering state

## Error Handling

### Custom Error Types
The contract uses custom errors for efficient gas usage and clear error messages:

```solidity
error CTMRWA1InvestWithTimeLock_OnlyAuthorized(Address, Address);
error CTMRWA1InvestWithTimeLock_InvalidContract(Address);
error CTMRWA1InvestWithTimeLock_OutOfBounds();
error CTMRWA1InvestWithTimeLock_NonExistentToken(uint256);
error CTMRWA1InvestWithTimeLock_MaxOfferings();
error CTMRWA1InvestWithTimeLock_InvalidLength(Uint);
error CTMRWA1InvestWithTimeLock_Paused();
error CTMRWA1InvestWithTimeLock_InvalidTimestamp(Time);
error CTMRWA1InvestWithTimeLock_InvalidAmount(Uint);
error CTMRWA1InvestWithTimeLock_NotWhiteListed(address);
error CTMRWA1InvestWithTimeLock_AlreadyWithdrawn(uint256);
error CTMRWA1InvestWithTimeLock_InvalidOfferingIndex();
error CTMRWA1InvestWithTimeLock_InvalidHoldingIndex();
error CTMRWA1InvestWithTimeLock_NoRewardToken();
error CTMRWA1InvestWithTimeLock_NoRewardsToClaim();
error CTMRWA1InvestWithTimeLock_HoldingNotFound();
error CTMRWA1InvestWithTimeLock_OfferingNotEnded();
error CTMRWA1InvestWithTimeLock_NoRemainingBalance();
```

### Error Categories
1. **Authorization Errors:** Access control violations
2. **Validation Errors:** Parameter and state validation failures
3. **Business Logic Errors:** Investment and escrow rule violations
4. **System Errors:** Contract integration and state issues

## Best Practices & Limitations

### Best Practices

#### For Issuers
1. **Due Diligence:** Thoroughly validate all offering parameters
2. **Timing Management:** Carefully plan offering start/end times
3. **Reward Planning:** Design sustainable reward distribution models
4. **Regulatory Compliance:** Ensure all regulatory requirements are met
5. **Storage Management:** Properly reference BNB Greenfield objects

#### For Investors
1. **Investment Analysis:** Review offering terms and conditions
2. **Escrow Awareness:** Understand lockup periods and implications
3. **Reward Monitoring:** Track reward accumulation during lockup
4. **Fee Planning:** Account for all applicable fees in calculations

### Current Limitations

1. **Single Chain Operation:** Each contract operates on a single blockchain
2. **Manual Management:** Requires manual offering creation and management
3. **Fixed Terms:** Offering terms cannot be modified after creation
4. **Gas Costs:** Cross-chain operations incur additional gas expenses
5. **Market Liquidity:** No secondary market for locked tokens
6. **Storage Dependency:** BNB Greenfield object references required

### Future Enhancement Opportunities

1. **Automated Offerings:** Implement automated offering creation mechanisms
2. **Dynamic Terms:** Allow modification of offering terms under certain conditions
3. **Enhanced Rewards:** Implement more sophisticated reward distribution models
4. **Liquidity Features:** Add secondary market for locked tokens
5. **Analytics Integration:** Add comprehensive analytics and reporting features
6. **Multi-token Support:** Extend to support multiple investment currencies
7. **Advanced Escrow:** Implement more flexible escrow mechanisms
8. **Storage Flexibility:** Support for multiple storage providers

## Events

### Core Events
| Event | Parameters | Description |
|-------|------------|-------------|
| `CreateOffering` | `ID, indx, slot, offer` | New offering creation |
| `OfferingPaused` | `ID, indx, account` | Offering pause action |
| `OfferingUnpaused` | `ID, indx, account` | Offering resume action |
| `InvestInOffering` | `ID, indx, holdingIndx, investment` | Investment completion |
| `WithdrawFunds` | `ID, indx, funds` | Fund withdrawal |
| `UnlockInvestmentToken` | `ID, holder, holdingIndx` | Token unlocking |
| `FundedRewardToken` | `offeringIndex, fundAmount, rewardMultiplier` | Reward funding |
| `RewardClaimed` | `holder, offerIndex, holdingIndex, amount` | Reward claiming |
| `RemoveRemainingBalance` | `ID, indx, remainingBalance` | Remaining balance removal (NEW) |

### Event Benefits
- **Transparency:** Complete audit trail of all operations
- **Monitoring:** Real-time tracking of contract activities
- **Compliance:** Regulatory and audit requirement fulfillment
- **Debugging:** Enhanced troubleshooting and issue resolution

## Function Summary

### Public Functions
- `setTokenAdmin(address _tokenAdmin, bool _force)` - Change token admin
- `pauseOffering(uint256 _indx)` - Pause specific offering
- `unpauseOffering(uint256 _indx)` - Unpause specific offering
- `isOfferingPaused(uint256 _indx)` - Check offering pause status
- `createOffering(...)` - Create new investment offering
- `withdrawInvested(uint256 _indx)` - Withdraw invested funds
- `unlockTokenId(uint256 _myIndx, address _feeToken)` - Unlock escrowed token
- `removeRemainingTokenId(uint256 _indx, address _feeToken)` - Remove remaining balance (NEW)
- `getTokenIdsInEscrow()` - Get escrow information
- `offeringCount()` - Get total offerings count
- `listOfferings()` - Get all offerings
- `listOffering(uint256 _offerIndx)` - Get specific offering
- `escrowHoldingCount(address _holder)` - Get holder's escrow count
- `listEscrowHoldings(address _holder)` - Get holder's escrow holdings
- `listEscrowHolding(address _holder, uint256 _myIndx)` - Get specific holding

### External Functions
- `investInOffering(uint256 indx, uint256 investment, address feeToken)` - Make investment
- `getRewardInfo(address holder, uint256 offerIndex, uint256 holdingIndex)` - Get reward info
- `claimReward(uint256 offerIndex, uint256 holdingIndex)` - Claim rewards
- `fundRewardTokenForOffering(uint256 _offeringIndex, uint256 _fundAmount, uint256 _rewardMultiplier, uint256 _rateDivisor)` - Fund rewards

### Internal Functions
- `_addTokenIdInEscrow(uint256 _tokenId, address _owner)` - Add token to escrow
- `_removeTokenIdInEscrow(uint256 _tokenId)` - Remove token from escrow
- `_checkTokenAdmin(address _ctmRwaToken)` - Validate token admin
- `_payFee(FeeType _feeType, address _feeToken)` - Pay operation fees

---

*This documentation is maintained by the ContinuumDAO team and should be updated as the contract evolves. For technical support or questions, please refer to the official documentation or contact the development team.*
