# FeeManager Contract Documentation

## Overview

**Contract Name:** FeeManager  
**File:** `src/managers/FeeManager.sol`  
**License:** BSL-1.1  
**Author:** @Selqui ContinuumDAO  
**Type:** Upgradeable Contract  

## Contract Description

FeeManager is the central fee management contract for the AssetX platform. It calculates and charges fees for various AssetX services, supporting multiple fee currencies to allow users and Issuers to pay in their preferred currency. The contract handles different fee types based on the chains involved, with configurable base fees for each chain and service fees as multiples of the base fee.

### Key Features
- Multi-currency fee support
- Chain-specific fee configuration
- Multiple fee types (29 different FeeTypes)
- Governance-controlled fee management
- Pausable operations
- Reentrancy protection
- Upgradeable architecture

## State Variables

### Fee Token Management
- `feeTokenList` (address[]): List of allowable fee token ERC20 addresses
- `feeTokenIndexMap` (mapping): Maps fee token addresses to their 1-based indices
- `feetokens` (address[]): Additional fee token storage

### Fee Configuration
- `feeMultiplier` (uint256[29]): Multipliers for each FeeType
- `MAX_SAFE_MULTIPLIER` (uint256, constant): Maximum safe multiplier (1e55)
- `_toFeeConfigs` (mapping): Chain-specific fee configurations

## Initialization

The contract uses an `initialize` function instead of a constructor since it's upgradeable:

```solidity
function initialize(
    address govAddr,
    address c3callerProxyAddr,
    address txSender,
    uint256 dappID2
) public initializer
```

### Initialization Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `govAddr` | `address` | The governance address |
| `c3callerProxyAddr` | `address` | The C3Caller proxy address |
| `txSender` | `address` | The transaction sender address |
| `dappID2` | `uint256` | The dApp ID |

### Initialization Behavior

During initialization, the contract:
1. Initializes ReentrancyGuard
2. Initializes UUPSUpgradeable
3. Initializes C3GovernDapp with governance parameters
4. Initializes Pausable functionality

## Governance Functions

### pause()
```solidity
function pause() external onlyGov
```
**Description:** Pauses fee operations.  
**Access:** Only governance  
**Effects:** Pauses all pausable functions  

### unpause()
```solidity
function unpause() external onlyGov
```
**Description:** Unpauses fee operations.  
**Access:** Only governance  
**Effects:** Unpauses all pausable functions  

### addFeeToken()
```solidity
function addFeeToken(string memory _feeTokenStr) external onlyGov whenNotPaused nonReentrant returns (bool)
```
**Description:** Adds a new fee token to the list of allowable fee tokens.  
**Parameters:**
- `_feeTokenStr` (string): Fee token address as a string
**Access:** Only governance  
**Returns:** True if successful  
**Effects:** Adds token to feeTokenList and updates index mapping  

### delFeeToken()
```solidity
function delFeeToken(string memory _feeTokenStr) external onlyGov whenNotPaused nonReentrant returns (bool)
```
**Description:** Removes a fee token from the list of allowable fee tokens.  
**Parameters:**
- `_feeTokenStr` (string): Fee token address as a string
**Access:** Only governance  
**Returns:** True if successful  
**Effects:** Removes token from feeTokenList and clears index mapping  

### setFeeMultiplier()
```solidity
function setFeeMultiplier(FeeType _feeType, uint256 _multiplier) external onlyGov whenNotPaused
```
**Description:** Sets the fee multiplier for a specific FeeType.  
**Parameters:**
- `_feeType` (FeeType): The fee type to configure
- `_multiplier` (uint256): The multiplier value
**Access:** Only governance  
**Effects:** Updates feeMultiplier for the specified FeeType  

### addFeeToken()
```solidity
function addFeeToken(
    string memory _toChainIdStr,
    string memory _feeTokenStr,
    uint256 _baseFee
) external onlyGov whenNotPaused nonReentrant returns (bool)
```
**Description:** Adds fee configuration for a specific chain and token.  
**Parameters:**
- `_toChainIdStr` (string): Target chain ID
- `_feeTokenStr` (string): Fee token address as a string
- `_baseFee` (uint256): Base fee amount
**Access:** Only governance  
**Returns:** True if successful  
**Effects:** Sets base fee for the chain-token combination  

### delFeeToken()
```solidity
function delFeeToken(
    string memory _toChainIdStr,
    string memory _feeTokenStr
) external onlyGov whenNotPaused nonReentrant returns (bool)
```
**Description:** Removes fee configuration for a specific chain and token.  
**Parameters:**
- `_toChainIdStr` (string): Target chain ID
- `_feeTokenStr` (string): Fee token address as a string
**Access:** Only governance  
**Returns:** True if successful  
**Effects:** Removes base fee for the chain-token combination  

## Fee Calculation Functions

### calculateFee()
```solidity
function calculateFee(
    FeeType _feeType,
    string memory _toChainIdStr,
    string memory _feeTokenStr,
    bool _includeLocal
) external view returns (uint256)
```
**Description:** Calculates the fee for a specific operation.  
**Parameters:**
- `_feeType` (FeeType): The type of fee to calculate
- `_toChainIdStr` (string): Target chain ID
- `_feeTokenStr` (string): Fee token identifier
- `_includeLocal` (bool): Whether to include local chain fees
**Returns:** Calculated fee amount  

### calculateFeeWithAmount()
```solidity
function calculateFeeWithAmount(
    FeeType _feeType,
    string memory _toChainIdStr,
    string memory _feeTokenStr,
    uint256 _amount,
    bool _includeLocal
) external view returns (uint256)
```
**Description:** Calculates the fee for a specific operation with a custom amount.  
**Parameters:**
- `_feeType` (FeeType): The type of fee to calculate
- `_toChainIdStr` (string): Target chain ID
- `_feeTokenStr` (string): Fee token identifier
- `_amount` (uint256): Custom amount for fee calculation
- `_includeLocal` (bool): Whether to include local chain fees
**Returns:** Calculated fee amount  

## Fee Collection Functions

### collectFee()
```solidity
function collectFee(
    FeeType _feeType,
    string memory _toChainIdStr,
    string memory _feeTokenStr,
    bool _includeLocal
) external whenNotPaused nonReentrant returns (uint256)
```
**Description:** Collects fees for a specific operation.  
**Parameters:**
- `_feeType` (FeeType): The type of fee to collect
- `_toChainIdStr` (string): Target chain ID
- `_feeTokenStr` (string): Fee token identifier
- `_includeLocal` (bool): Whether to include local chain fees
**Returns:** Collected fee amount  
**Effects:** Transfers fees from caller to contract  

### collectFeeWithAmount()
```solidity
function collectFeeWithAmount(
    FeeType _feeType,
    string memory _toChainIdStr,
    string memory _feeTokenStr,
    uint256 _amount,
    bool _includeLocal
) external whenNotPaused nonReentrant returns (uint256)
```
**Description:** Collects fees for a specific operation with a custom amount.  
**Parameters:**
- `_feeType` (FeeType): The type of fee to collect
- `_toChainIdStr` (string): Target chain ID
- `_feeTokenStr` (string): Fee token identifier
- `_amount` (uint256): Custom amount for fee calculation
- `_includeLocal` (bool): Whether to include local chain fees
**Returns:** Collected fee amount  
**Effects:** Transfers fees from caller to contract  

## Treasury Functions

### withdrawFee()
```solidity
function withdrawFee(
    string memory _feeTokenStr,
    address _treasury,
    uint256 _amount
) external onlyGov whenNotPaused nonReentrant returns (bool)
```
**Description:** Withdraws collected fees to a treasury address.  
**Parameters:**
- `_feeTokenStr` (string): Fee token address as a string
- `_treasury` (address): Treasury address to receive fees
- `_amount` (uint256): Amount to withdraw
**Access:** Only governance  
**Returns:** True if successful  
**Effects:** Transfers fees from contract to treasury  

## Query Functions

### getFeeTokenList()
```solidity
function getFeeTokenList() external view returns (address[] memory)
```
**Description:** Returns the list of all allowable fee tokens.  
**Returns:** Array of fee token addresses  

### getFeeTokenIndex()
```solidity
function getFeeTokenIndex(address _feeToken) external view returns (uint256)
```
**Description:** Returns the index of a fee token in the list.  
**Parameters:**
- `_feeToken` (address): Fee token address
**Returns:** 1-based index of the token (0 if not found)  

### getFeeMultiplier()
```solidity
function getFeeMultiplier(FeeType _feeType) external view returns (uint256)
```
**Description:** Returns the fee multiplier for a specific FeeType.  
**Parameters:**
- `_feeType` (FeeType): The fee type
**Returns:** Fee multiplier value  

### getBaseFee()
```solidity
function getBaseFee(string memory _toChainIdStr, string memory _feeTokenStr) external view returns (uint256)
```
**Description:** Returns the base fee for a specific chain and token.  
**Parameters:**
- `_toChainIdStr` (string): Target chain ID
- `_feeTokenStr` (string): Fee token identifier
**Returns:** Base fee amount  

### getBalance()
```solidity
function getBalance(string memory _feeTokenStr) external view returns (uint256)
```
**Description:** Returns the contract's balance of a specific fee token.  
**Parameters:**
- `_feeTokenStr` (string): Fee token identifier
**Returns:** Contract balance of the token  

## Access Control Modifiers

- `onlyGov`: Restricts access to governance
- `whenNotPaused`: Ensures contract is not paused
- `nonReentrant`: Prevents reentrancy attacks

## Events

### AddFeeToken
```solidity
event AddFeeToken(address indexed feeToken);
```
**Description:** Emitted when a fee token is added.

### DelFeeToken
```solidity
event DelFeeToken(address indexed feeToken);
```
**Description:** Emitted when a fee token is removed.

### SetFeeMultiplier
```solidity
event SetFeeMultiplier(FeeType indexed feeType, uint256 multiplier);
```
**Description:** Emitted when a fee multiplier is set.

### WithdrawFee
```solidity
event WithdrawFee(address indexed feeToken, address indexed treasury, uint256 amount);
```
**Description:** Emitted when fees are withdrawn to treasury.

### LogFallback
```solidity
event LogFallback(bytes4 selector, bytes data, bytes reason);
```
**Description:** Emitted when a fallback function is called.

## Fee Types

The contract supports 29 different fee types (FeeType enum), including:
- Deployment fees
- Transfer fees
- Cross-chain fees
- Identity verification fees
- Dividend distribution fees
- Storage fees
- And more...

## Security Features

- **ReentrancyGuard**: Protects against reentrancy attacks
- **Pausable**: Allows pausing of critical functions
- **Governance Controls**: Comprehensive governance oversight
- **SafeERC20**: Safe token transfers
- **Upgradeable**: Can be upgraded by governance
- **Multiplier Limits**: Prevents overflow with MAX_SAFE_MULTIPLIER

## Integration Points

- **C3GovernDapp**: Governance functionality
- **ERC20 Tokens**: Multiple fee currencies
- **Cross-chain contracts**: Fee collection for cross-chain operations
- **Identity contracts**: Verification fees
- **Dividend contracts**: Distribution fees

## Fee Calculation Logic

1. **Base Fee**: Retrieved from chain-specific configuration
2. **Multiplier**: Applied based on FeeType
3. **Local Inclusion**: Optionally includes local chain fees
4. **Final Amount**: Base fee × multiplier (with local adjustments)

## Key Features

- **Multi-currency**: Support for multiple ERC20 tokens as fees
- **Chain-specific**: Different base fees for different chains
- **Flexible**: Configurable multipliers for different operations
- **Governance-controlled**: All fee parameters managed by governance
- **Safe**: Overflow protection and reentrancy guards
- **Transparent**: All fee calculations are viewable
