# FeeManager Contract Documentation

## Overview

**Contract Name:** FeeManager  
**Author:** @Selqui ContinuumDAO  
**License:** BSL-1.1  
**Solidity Version:** 0.8.27

The FeeManager contract is used by the entire AssetX ecosystem to calculate and charge fees for AssetX services. It supports multiple fee currencies, allowing users and Issuers to pay in their preferred currency.

Fees are categorized into different FeeTypes using an enum, with actual fees depending on the chains involved and different base fees configured for each chain. Service fees are multiples of the base fee. Some fees include the local chain while others only cover cross-chain components, depending on the includeLocal flag.

Governance can withdraw collected fees from this contract to a treasury address. This contract is deployed once on each chain and is upgradeable using the UUPS pattern.

## Key Features

- **Multi-currency Support:** Supports multiple fee token currencies
- **Flexible Fee Structure:** Different fee types with configurable multipliers
- **Cross-chain Fee Calculation:** Calculates fees based on destination chains
- **Governance Control:** Governance can manage fee tokens and withdraw fees
- **Upgradeable:** Uses UUPS upgradeable pattern for future improvements
- **Pausable:** Can pause operations during emergencies
- **Reentrancy Protection:** Uses ReentrancyGuard for fee payment security
- **C3 Integration:** Integrates with C3Caller for cross-chain operations

## Public Variables

### Fee Token Management
- **`feeTokenList`** (address[]): Current list of allowable fee token ERC20 addresses
- **`feeTokenIndexMap`** (mapping(address => uint256)): 1-based index mapping for fee tokens
- **`feetokens`** (address[]): Additional fee token array (legacy)

### Fee Configuration
- **`feeMultiplier`** (uint256[29]): Multiplier of baseFee applicable for each FeeType
- **`MAX_SAFE_MULTIPLIER`** (uint256, constant): Safe multiplier limit to prevent overflow (1e55)

### Private Storage
- **`_toFeeConfigs`** (mapping(string => mapping(address => uint256))): Base fee configurations per chain and token

## Core Functions

### Initialization

#### `initialize(address govAddr, address c3callerProxyAddr, address txSender, uint256 dappID2)`
- **Access:** Public initializer
- **Purpose:** Initializes the FeeManager contract instance
- **Parameters:**
  - `govAddr`: Governance address
  - `c3callerProxyAddr`: C3Caller proxy address
  - `txSender`: Transaction sender address
  - `dappID2`: DApp ID for C3Caller integration
- **Initialization:**
  - Initializes ReentrancyGuard
  - Initializes UUPS upgradeable functionality
  - Initializes C3GovernDapp with governance parameters
  - Initializes Pausable functionality

### Upgrade Management

#### `_authorizeUpgrade(address newImplementation)`
- **Access:** Internal function, only callable by governance
- **Purpose:** Authorizes contract upgrades
- **Parameters:** `newImplementation` - Address of new implementation
- **Security:** Only governance can authorize upgrades

### Pause Management

#### `pause()`
- **Access:** Only callable by governance
- **Purpose:** Pause the contract (prevents fee operations)
- **Use Case:** Emergency pause during issues

#### `unpause()`
- **Access:** Only callable by governance
- **Purpose:** Unpause the contract (resumes fee operations)
- **Use Case:** Resume operations after emergency

### Fee Token Management

#### `addFeeToken(string memory _feeTokenStr)`
- **Access:** Only callable by governance when not paused
- **Purpose:** Add a new fee token to the allowable list
- **Parameters:** `_feeTokenStr` - Fee token address as string
- **Validation:** Ensures address string is 42 characters (0x + 40 hex)
- **Logic:** Adds token to feeTokenList and sets index in feeTokenIndexMap
- **Returns:** True if successful
- **Events:** Emits AddFeeToken event
- **Security:** Uses nonReentrant modifier

#### `delFeeToken(string memory _feeTokenStr)`
- **Access:** Only callable by governance when not paused
- **Purpose:** Remove a fee token from the allowable list
- **Parameters:** `_feeTokenStr` - Fee token address as string
- **Validation:** Ensures token exists in the list
- **Logic:** Removes token and reorders list to maintain indices
- **Returns:** True if successful
- **Events:** Emits DelFeeToken event
- **Security:** Uses nonReentrant modifier

#### `getFeeTokenList()`
- **Purpose:** Get list of all allowable fee token addresses
- **Returns:** Array of fee token addresses
- **Use Case:** Query available fee tokens

#### `getFeeTokenIndexMap(string memory _feeTokenStr)`
- **Purpose:** Get index of a fee token in the list
- **Parameters:** `_feeTokenStr` - Fee token address as string
- **Returns:** Index of the fee token (1-based, 0 if not found)
- **Validation:** Converts address to lowercase for consistency

### Fee Configuration

#### `addFeeToken(string memory dstChainIDStr, string[] memory feeTokensStr, uint256[] memory baseFee)`
- **Access:** Only callable by governance when not paused
- **Purpose:** Add fee parameters for tokens in feeTokenList
- **Parameters:**
  - `dstChainIDStr`: Destination chainId as string
  - `feeTokensStr`: Array of fee token addresses as strings
  - `baseFee`: Array of base fees in wei for each token
- **Validation:**
  - Ensures arrays have same length
  - Validates all addresses are 42 characters
  - Ensures tokens exist in feeTokenList
- **Logic:** Sets base fees for each token-chain combination
- **Returns:** True if successful
- **Security:** Uses nonReentrant modifier

#### `setFeeMultiplier(FeeType _feeType, uint256 _multiplier)`
- **Access:** Only callable by governance when not paused
- **Purpose:** Set fee multiplier for a specific FeeType
- **Parameters:**
  - `_feeType`: FeeType enum to configure
  - `_multiplier`: Multiplier value to set
- **Validation:** Ensures multiplier doesn't exceed MAX_SAFE_MULTIPLIER
- **Returns:** True if successful
- **Events:** Emits SetFeeMultiplier event
- **Security:** Uses nonReentrant modifier

#### `getFeeMultiplier(FeeType _feeType)`
- **Purpose:** Get fee multiplier for a specific FeeType
- **Parameters:** `_feeType` - FeeType enum to query
- **Returns:** Fee multiplier for the specified type

### Fee Calculation

#### `getXChainFee(string[] memory _toChainIDsStr, bool _includeLocal, FeeType _feeType, string memory _feeTokenStr)`
- **Purpose:** Calculate fee for AssetX operation
- **Parameters:**
  - `_toChainIDsStr`: Array of destination chainIds as strings
  - `_includeLocal`: Whether to include local chain in calculation
  - `_feeType`: FeeType enum for the operation
  - `_feeTokenStr`: Fee token address as string
- **Logic:**
  - Validates fee token exists in feeTokenList
  - Sums base fees for all destination chains
  - Adds local chain base fee if includeLocal is true
  - Multiplies by fee multiplier for the FeeType
- **Returns:** Calculated fee in wei
- **Validation:** Ensures fee token is supported

#### `getToChainBaseFee(string memory _toChainIDStr, string memory _feeTokenStr)`
- **Purpose:** Get configured base fee for cross-chain operation
- **Parameters:**
  - `_toChainIDStr`: Destination chainId as string
  - `_feeTokenStr`: Fee token address as string
- **Returns:** Base fee for the chain-token combination
- **Validation:** Ensures parameters are valid

### Fee Payment

#### `payFee(uint256 _fee, string memory _feeTokenStr)`
- **Purpose:** Pay fee to this contract for AssetX service
- **Parameters:**
  - `_fee`: Fee amount in wei
  - `_feeTokenStr`: Fee token address as string
- **Logic:** Transfers fee tokens from caller to contract
- **Returns:** Fee amount paid
- **Security:** Uses nonReentrant and whenNotPaused modifiers

### Fee Withdrawal

#### `withdrawFee(string memory _feeTokenStr, uint256 _amount, string memory _treasuryStr)`
- **Access:** Only callable by governance when not paused
- **Purpose:** Withdraw collected fees to treasury address
- **Parameters:**
  - `_feeTokenStr`: Fee token address as string
  - `_amount`: Amount to withdraw in wei
  - `_treasuryStr`: Treasury wallet address as string
- **Logic:**
  - Validates all addresses are 42 characters
  - Limits withdrawal to available balance
  - Transfers tokens to treasury
- **Returns:** True if successful
- **Events:** Emits WithdrawFee event
- **Security:** Uses nonReentrant modifier

## Internal Functions

### C3Caller Integration
- **`_c3Fallback(bytes4 _selector, bytes calldata _data, bytes calldata _reason)`**: C3Caller fallback function
  - Handles cross-chain errors
  - Emits LogFallback event
  - Returns true to indicate successful fallback handling

## Access Control Modifiers

The contract inherits access control from C3GovernDappUpgradeable:
- **`onlyGov`**: Restricts access to governance address
- **`whenNotPaused`**: Ensures contract is not paused
- **`nonReentrant`**: Prevents reentrancy attacks

## Events

- **`LogFallback(bytes4 selector, bytes data, bytes reason)`**: Emitted on C3Caller fallback
- **`AddFeeToken(address indexed feeToken)`**: Emitted when fee token is added
- **`DelFeeToken(address indexed feeToken)`**: Emitted when fee token is removed
- **`SetFeeMultiplier(FeeType indexed feeType, uint256 multiplier)`**: Emitted when fee multiplier is set
- **`WithdrawFee(address indexed feeToken, address indexed treasury, uint256 amount)`**: Emitted when fees are withdrawn

## Security Features

1. **Access Control:** Only governance can perform administrative functions
2. **Reentrancy Protection:** Uses ReentrancyGuard for fee operations
3. **Pausable Operations:** Can pause operations during emergencies
4. **Upgradeable:** Uses UUPS pattern for secure upgrades
5. **Input Validation:** Validates all input parameters
6. **Safe Math:** Uses OpenZeppelin Math library for safe calculations
7. **Transfer Safety:** Uses SafeERC20 for token transfers
8. **Overflow Protection:** MAX_SAFE_MULTIPLIER prevents overflow

## Integration Points

- **C3Caller**: Cross-chain communication system
- **Governance**: Controls fee configuration and withdrawals
- **AssetX Contracts**: All contracts use this for fee calculation
- **ERC20 Tokens**: Multiple fee token support
- **Treasury**: Receives withdrawn fees

## Error Handling

The contract uses custom error types for efficient gas usage:

- **`FeeManager_InvalidLength(CTMRWAErrorParam.Address)`**: Thrown when address string is invalid length
- **`FeeManager_InvalidLength(CTMRWAErrorParam.ChainID)`**: Thrown when chain ID string is invalid
- **`FeeManager_InvalidLength(CTMRWAErrorParam.Input)`**: Thrown when input parameters are invalid
- **`FeeManager_InvalidLength(CTMRWAErrorParam.Multiplier)`**: Thrown when multiplier exceeds safe limit
- **`FeeManager_NonExistentToken(address token)`**: Thrown when token doesn't exist in fee list
- **`FeeManager_FailedTransfer()`**: Thrown when token transfer fails

## Fee Calculation Process

### 1. Base Fee Configuration
- **Step:** Governance configures base fees per chain-token combination
- **Method:** Call addFeeToken with chain ID and token arrays
- **Result:** Base fees stored in _toFeeConfigs mapping

### 2. Fee Multiplier Setting
- **Step:** Governance sets multipliers for each FeeType
- **Method:** Call setFeeMultiplier with FeeType and multiplier
- **Result:** Multipliers stored in feeMultiplier array

### 3. Fee Calculation
- **Step:** Calculate fee for specific operation
- **Method:** Call getXChainFee with operation parameters
- **Logic:** Sum base fees × multiplier
- **Result:** Total fee for the operation

### 4. Fee Payment
- **Step:** User pays calculated fee
- **Method:** Call payFee with amount and token
- **Logic:** Transfer tokens from user to contract
- **Result:** Fee collected in contract

### 5. Fee Withdrawal
- **Step:** Governance withdraws collected fees
- **Method:** Call withdrawFee with token, amount, and treasury
- **Logic:** Transfer tokens to treasury address
- **Result:** Fees distributed to treasury

## Use Cases

### Multi-currency Fee Support
- **Scenario:** Users want to pay fees in different currencies
- **Process:** Add multiple fee tokens, configure base fees
- **Benefit:** Flexible payment options for users

### Cross-chain Fee Management
- **Scenario:** Different fees for different destination chains
- **Process:** Configure base fees per chain-token combination
- **Benefit:** Optimized fees based on chain characteristics

### Governance Fee Control
- **Scenario:** Governance needs to manage fee structure
- **Process:** Add/remove tokens, set multipliers, withdraw fees
- **Benefit:** Centralized fee management and revenue collection

### Emergency Controls
- **Scenario:** Emergency situations requiring fee pause
- **Process:** Use pause/unpause functions
- **Benefit:** Emergency control over fee operations

## Best Practices

1. **Fee Planning:** Plan fee structure based on operational costs
2. **Multiplier Safety:** Use reasonable multipliers to prevent overflow
3. **Token Management:** Carefully manage fee token additions/removals
4. **Cross-chain Coordination:** Coordinate fee configuration across chains
5. **Treasury Management:** Regular fee withdrawals to treasury

## Limitations

- **Single Instance:** Only one FeeManager per chain
- **Governance Dependency:** Requires governance for configuration changes
- **Token List Management:** Fee token indices may change when tokens are removed/added
- **Chain-specific:** Each FeeManager operates on a single chain
- **Upgrade Dependency:** Requires governance for contract upgrades

## Future Enhancements

Potential improvements to the fee management system:

1. **Dynamic Fee Adjustment:** Implement dynamic fee adjustment mechanisms
2. **Fee Analytics:** Add fee tracking and analytics features
3. **Automated Withdrawals:** Implement automated fee withdrawal schedules
4. **Enhanced Token Support:** Support for additional token types
5. **Fee Optimization:** Implement fee optimization algorithms

## Fee Types and Multipliers

### FeeType Enum
The contract supports 29 different fee types (indices 0-28) with configurable multipliers:

- **Base Fee:** Configured per chain-token combination
- **Service Fee:** Base fee × multiplier for specific operation type
- **Total Fee:** Sum of all applicable fees for the operation

### Multiplier Management
- **Safe Limits:** MAX_SAFE_MULTIPLIER prevents overflow
- **Governance Control:** Only governance can set multipliers
- **Flexible Configuration:** Different multipliers for different operations
- **Event Tracking:** All multiplier changes are logged

## Cross-chain Fee Architecture

### Fee Calculation Logic
- **Destination Chains:** Sum base fees for all destination chains
- **Local Chain:** Optionally include local chain base fee
- **Fee Type:** Apply appropriate multiplier for operation type
- **Token Support:** Validate fee token is supported

### Chain Coordination
- **Independent Configuration:** Each chain configures its own fees
- **Cross-chain Operations:** Fees calculated based on destination chains
- **Local Inclusion:** Option to include local chain in fee calculation
- **Consistent Structure:** Same fee structure across all chains

## Gas Optimization

### Fee Calculation Costs
- **Base Fee Lookup:** ~2600 gas per chain lookup
- **Multiplier Calculation:** ~2100 gas for multiplication
- **Token Validation:** ~5000 gas for token list iteration
- **Total Estimate:** ~10000-50000 gas per fee calculation

### Optimization Strategies
- **Efficient Storage:** Use mappings for O(1) lookups
- **Batch Operations:** Consider batch fee configurations
- **Gas Estimation:** Always estimate gas before operations
- **Storage Optimization:** Minimize storage operations

## Security Considerations

### Access Control
- **Governance Authorization:** Only governance can perform admin functions
- **Pause Controls:** Emergency pause capability for security
- **Upgrade Security:** Secure upgrade mechanism with governance control
- **Function Validation:** Validate all function parameters

### Financial Security
- **Transfer Safety:** Use SafeERC20 for all token transfers
- **Balance Validation:** Ensure sufficient balance before withdrawals
- **Overflow Protection:** Prevent mathematical overflow
- **Reentrancy Protection:** Prevent reentrancy attacks

### Configuration Security
- **Input Validation:** Validate all input parameters
- **Safe Limits:** Enforce safe limits for multipliers
- **Token Management:** Secure token addition/removal process
- **Cross-chain Safety:** Secure cross-chain fee calculations

## Treasury Management

### Fee Collection
- **Automatic Collection:** Fees collected automatically during operations
- **Multi-token Support:** Collect fees in multiple currencies
- **Balance Tracking:** Track balances for each fee token
- **Withdrawal Control:** Governance controls fee withdrawals

### Withdrawal Process
- **Governance Authorization:** Only governance can withdraw fees
- **Balance Limits:** Withdrawal limited to available balance
- **Treasury Transfer:** Secure transfer to treasury address
- **Event Logging:** All withdrawals logged for transparency
