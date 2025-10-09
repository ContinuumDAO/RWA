# CTMRWA1Dividend Contract Documentation

## Overview

**Contract Name:** CTMRWA1Dividend  
**File:** `src/dividend/CTMRWA1Dividend.sol`  
**License:** BSL-1.1  
**Author:** @Selqui ContinuumDAO  
**Type:** Implementation Contract  

## Contract Description

CTMRWA1Dividend is a dividend distribution contract for Real-World Asset (RWA) tokens. It manages the distribution of dividends to holders of CTMRWA1 tokens, allowing tokenAdmins (Issuers) to fund dividend pools and enabling token holders to claim their proportional dividends based on their token holdings.

### Key Features
- Dividend distribution management
- Slot-based dividend tracking
- Checkpoint-based historical data
- Pausable operations
- Reentrancy protection
- ERC20 token support
- Multi-slot dividend support

## State Variables

### Core Addresses
- `dividendToken` (address): The ERC20 token used for dividend distribution
- `tokenAddr` (address): The linked CTMRWA1 contract address
- `tokenAdmin` (address): The token administrator (Issuer) address
- `ctmRwa1X` (address): The CTMRWA1X contract address
- `ctmRwa1Map` (address): The CTMRWAMap contract address

### Identifiers
- `ID` (uint256): Unique identifier matching the linked CTMRWA1
- `RWA_TYPE` (uint256, immutable): RWA type defining CTMRWA1
- `VERSION` (uint256, immutable): Version of this RWA type

### Constants
- `ONE_DAY` (uint48, constant): One day in seconds (86400)

### Dividend Tracking
- `dividendFundings` (DividendFunding[]): Array of dividend funding records
- `lastClaimedIndex` (mapping): Tracks last claimed index for each holder and slot
- `_dividendRate` (mapping): Slot => dividend rate checkpoints

## Data Structures

### DividendFunding
```solidity
struct DividendFunding {
    uint256 slot;        // Slot number
    uint48 fundingTime;  // Time when dividend was funded
}
```
**Description:** Tracks dividend funding events for each slot.

## Constructor

```solidity
constructor(
    uint256 _ID,
    address _tokenAddr,
    uint256 _rwaType,
    uint256 _version,
    address _map
)
```

### Constructor Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `_ID` | `uint256` | Unique identifier matching the linked CTMRWA1 |
| `_tokenAddr` | `address` | The CTMRWA1 contract address |
| `_rwaType` | `uint256` | RWA type defining CTMRWA1 |
| `_version` | `uint256` | Version of this RWA type |
| `_map` | `address` | The CTMRWAMap contract address |

### Constructor Behavior

During construction, the contract:
1. Sets the tokenAddr to the provided CTMRWA1 address
2. Retrieves and sets the tokenAdmin from the CTMRWA1 contract
3. Retrieves and sets the ctmRwa1X address from the CTMRWA1 contract
4. Sets the ctmRwa1Map address
5. Sets the ID, RWA_TYPE, and VERSION

## Administrative Functions

### changeAdmin()
```solidity
function changeAdmin(address _tokenAdmin) public onlyTokenAdmin returns (bool)
```
**Description:** Changes the tokenAdmin address.  
**Parameters:**
- `_tokenAdmin` (address): New tokenAdmin address
**Access:** Only tokenAdmin or CTMRWA1X  
**Returns:** True if successful  
**Effects:** Updates tokenAdmin address  

### setDividendToken()
```solidity
function setDividendToken(address _dividendToken) external onlyTokenAdmin
```
**Description:** Sets the ERC20 token used for dividend distribution.  
**Parameters:**
- `_dividendToken` (address): New dividend token address
**Access:** Only tokenAdmin  
**Effects:** Updates dividendToken address and emits event  

### setDividendRate()
```solidity
function setDividendRate(uint256 _slot, uint256 _dividendRate) external onlyTokenAdmin
```
**Description:** Sets the dividend rate for a specific slot.  
**Parameters:**
- `_slot` (uint256): Slot number
- `_dividendRate` (uint256): New dividend rate
**Access:** Only tokenAdmin  
**Effects:** Updates dividend rate for slot and emits event  

## Dividend Management Functions

### fundDividend()
```solidity
function fundDividend(uint256 _slot, uint256 _amount) external onlyTokenAdmin whenDividendNotPaused
```
**Description:** Funds a dividend pool for a specific slot.  
**Parameters:**
- `_slot` (uint256): Slot number
- `_amount` (uint256): Amount to fund
**Access:** Only tokenAdmin  
**Effects:** Transfers tokens and records funding event  

### claimDividend()
```solidity
function claimDividend(uint256 _slot) external nonReentrant whenDividendNotPaused returns (uint256)
```
**Description:** Claims dividends for a specific slot.  
**Parameters:**
- `_slot` (uint256): Slot number
**Access:** Public  
**Returns:** Amount of dividends claimed  
**Effects:** Transfers dividends to caller and updates claim index  

### claimAllDividends()
```solidity
function claimAllDividends() external nonReentrant whenDividendNotPaused returns (uint256)
```
**Description:** Claims dividends for all slots where the caller has unclaimed dividends.  
**Access:** Public  
**Returns:** Total amount of dividends claimed  
**Effects:** Transfers dividends to caller for all eligible slots  

## Query Functions

### getDividendRate()
```solidity
function getDividendRate(uint256 _slot) external view returns (uint256)
```
**Description:** Returns the current dividend rate for a slot.  
**Parameters:**
- `_slot` (uint256): Slot number
**Returns:** Current dividend rate  

### getDividendRateAt()
```solidity
function getDividendRateAt(uint256 _slot, uint256 _timestamp) external view returns (uint256)
```
**Description:** Returns the dividend rate for a slot at a specific timestamp.  
**Parameters:**
- `_slot` (uint256): Slot number
- `_timestamp` (uint256): Timestamp
**Returns:** Historical dividend rate  

### getClaimableDividend()
```solidity
function getClaimableDividend(address _holder, uint256 _slot) external view returns (uint256)
```
**Description:** Returns the claimable dividend amount for a holder in a specific slot.  
**Parameters:**
- `_holder` (address): Holder address
- `_slot` (uint256): Slot number
**Returns:** Claimable dividend amount  

### getTotalClaimableDividend()
```solidity
function getTotalClaimableDividend(address _holder) external view returns (uint256)
```
**Description:** Returns the total claimable dividend amount for a holder across all slots.  
**Parameters:**
- `_holder` (address): Holder address
**Returns:** Total claimable dividend amount  

### getDividendFundings()
```solidity
function getDividendFundings() external view returns (DividendFunding[] memory)
```
**Description:** Returns all dividend funding records.  
**Returns:** Array of dividend funding records  

### getDividendFundingsBySlot()
```solidity
function getDividendFundingsBySlot(uint256 _slot) external view returns (DividendFunding[] memory)
```
**Description:** Returns dividend funding records for a specific slot.  
**Parameters:**
- `_slot` (uint256): Slot number
**Returns:** Array of dividend funding records for the slot  

## Pausable Functions

### pause()
```solidity
function pause() external onlyTokenAdmin
```
**Description:** Pauses dividend operations.  
**Access:** Only tokenAdmin  
**Effects:** Pauses all pausable functions  

### unpause()
```solidity
function unpause() external onlyTokenAdmin
```
**Description:** Unpauses dividend operations.  
**Access:** Only tokenAdmin  
**Effects:** Unpauses all pausable functions  

### isPaused()
```solidity
function isPaused() external view returns (bool)
```
**Description:** Returns true if the contract is paused.  
**Returns:** Boolean indicating pause status  

## Access Control Modifiers

- `onlyTokenAdmin`: Restricts access to tokenAdmin or CTMRWA1X
- `whenDividendNotPaused`: Ensures contract is not paused
- `nonReentrant`: Prevents reentrancy attacks

## Events

### NewDividendToken
```solidity
event NewDividendToken(address newToken, address currentAdmin);
```
**Description:** Emitted when the dividend token is changed.

### ChangeDividendRate
```solidity
event ChangeDividendRate(uint256 slot, uint256 newDividend, address currentAdmin);
```
**Description:** Emitted when the dividend rate for a slot is changed.

### FundDividend
```solidity
event FundDividend(uint256 dividendPayable, address dividendToken, address currentAdmin);
```
**Description:** Emitted when dividends are funded.

### ClaimDividend
```solidity
event ClaimDividend(address claimant, uint256 dividend, address dividendToken);
```
**Description:** Emitted when dividends are claimed.

## Security Features

- **ReentrancyGuard**: Protects against reentrancy attacks
- **Pausable**: Allows pausing of critical functions
- **Access Control**: Role-based permissions
- **Checkpoints**: Historical data tracking
- **SafeERC20**: Safe token transfers

## Integration Points

- **CTMRWA1**: Linked token contract
- **CTMRWA1X**: Cross-chain operations
- **CTMRWAMap**: Component address mapping
- **ERC20 Tokens**: Dividend distribution tokens
- **Checkpoints**: Historical rate tracking

## Dividend Flow

1. **TokenAdmin** funds dividend pool for specific slots
2. **Token holders** check their claimable dividends
3. **Token holders** claim dividends for specific slots or all slots
4. **Contract** transfers ERC20 tokens to claimants
5. **Contract** updates claim indices to prevent double-claiming

## Key Features

- **Slot-based**: Dividends can be managed per token slot
- **Historical tracking**: Uses checkpoints for historical rate data
- **Batch claiming**: Claim dividends for multiple slots at once
- **Pausable**: Emergency pause functionality
- **Safe transfers**: Uses SafeERC20 for secure token transfers
