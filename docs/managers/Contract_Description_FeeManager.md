# FeeManager Contract Documentation

## Overview

**Contract Name:** FeeManager  
**File:** `src/managers/FeeManager.sol`  
**License:** BSL-1.1  
**Author:** @Selqui ContinuumDAO

## Contract Description

This contract is used by the whole of AssetX to calculate and charge fees for the AssetX service. Multiple fee currencies can be established, so that users and Issuers can pay in a currency of their choosing.

The fees are split up into different enum FeeTypes. The actual fees to be paid depend on the chains involved and different base fees can be set up for each chain. The service fees are multiples of the base fee. Some fees include the local chain and some only for cross-chain components, depending on the includeLocal flag.

Governance can withdraw fees from this contract to a treasury address. This contract is deployed once on each chain.

### Key Features
- Multi-currency fee support for flexible payment options
- Flexible fee structure with configurable multipliers
- Cross-chain fee calculation based on destination chains
- Governance control for fee management and withdrawals
- Upgradeable using UUPS upgradeable pattern
- Pausable operations for emergency control
- Reentrancy protection for fee payment security
- C3 integration for cross-chain operations
- Fee reduction system for specific addresses
- Token validation and safety checks

## State Variables

- `feeTokenList (address[])`: A current list of the allowable fee token ERC20 addresses on this chain
- `feeTokenIndexMap (mapping(address => uint256))`: 1-based index mapping for fee tokens. If a token is removed and re-added, its index will change. Off-chain consumers should not rely on index stability
- `feetokens (address[])`: Additional fee token array (legacy)
- `feeMultiplier (uint256[30])`: The multiplier of the baseFee applicable for each FeeType
- `feeReduction (mapping(address => uint256))`: A fee reduction for wallet addresses. address => reduction factor (0 - 10000)
- `feeReductionExpiration (mapping(address => uint256))`: The expiration timestamp of the fee reduction for a wallet address. address => expiration timestamp
- `MAX_SAFE_MULTIPLIER (uint256, constant = 1e55)`: A safe multiplier, so that Governance cannot set up an overflow of any FeeType
- `_toFeeConfigs (mapping(string => mapping(address => uint256)))`: Base fee configurations per chain and token

## Initialization

### initialize()
```solidity
function initialize(address govAddr, address c3callerProxyAddr, address txSender, uint256 dappID2) public initializer
```
Initializes the FeeManager contract instance.

**Parameters:**
- `govAddr`: Governance address
- `c3callerProxyAddr`: C3Caller proxy address
- `txSender`: Transaction sender address
- `dappID2`: DApp ID for C3Caller integration

**Initialization:**
- Initializes ReentrancyGuard
- Initializes UUPS upgradeable functionality
- Initializes C3GovernDApp with governance parameters
- Initializes Pausable functionality

## Access Control

- `onlyGov`: Restricts access to governance address
- `whenNotPaused`: Ensures contract is not paused
- `nonReentrant`: Prevents reentrancy attacks

## Administrative Functions

### _authorizeUpgrade()
```solidity
function _authorizeUpgrade(address newImplementation) internal override onlyGov
```
Authorizes contract upgrades.

**Parameters:**
- `newImplementation`: Address of new implementation

**Security:** Only governance can authorize upgrades

### pause()
```solidity
function pause() external onlyGov
```
Pause the contract (prevents fee operations).

### unpause()
```solidity
function unpause() external onlyGov
```
Unpause the contract (resumes fee operations).

## Fee Token Management

### addFeeToken()
```solidity
function addFeeToken(string memory _feeTokenStr) external onlyGov whenNotPaused nonReentrant returns (bool)
```
Add a new fee token to the list of fee tokens allowed to be used.

**Parameters:**
- `_feeTokenStr`: The fee token address (as a string) to add

**Note:** This only adds a fee token to the list. Its parameters must still be configured with a call to the other addFeeToken function.

**Returns:** True if the fee token was added, false otherwise

### delFeeToken()
```solidity
function delFeeToken(string memory _feeTokenStr) external onlyGov whenNotPaused nonReentrant returns (bool)
```
Remove a fee token from the list of allowable fee tokens.

**Parameters:**
- `_feeTokenStr`: The fee token address (as a string) to remove

**Returns:** True if the fee token was removed, false otherwise

### getFeeTokenList()
```solidity
function getFeeTokenList() external view virtual returns (address[])
```
Get a list of all allowable fee token addresses as an array of strings.

**Returns:** The list of all allowable fee token addresses as an array of strings

### getFeeTokenIndexMap()
```solidity
function getFeeTokenIndexMap(string memory _feeTokenStr) external view returns (uint256)
```
Get the index into the fee token list for a particular fee token.

**Parameters:**
- `_feeTokenStr`: The fee token address (as a string) to examine

**Returns:** The index into the fee token list for a particular fee token

## Fee Configuration

### addFeeToken()
```solidity
function addFeeToken(string memory dstChainIDStr, string[] memory feeTokensStr, uint256[] memory baseFee) external onlyGov whenNotPaused nonReentrant returns (bool)
```
Add the parameters for fee tokens that are in the feeTokenList.

**Parameters:**
- `dstChainIDStr`: The destination chainId as a string for which parameters are being set
- `feeTokensStr`: An array of fee tokens, as strings, that the fees are being set for
- `baseFee`: This is an array of fees, in wei, for each fee token and to the destination chainId

**Note:** The actual fee paid for an operation to a chainId is the baseFee multiplied by the fee multiplier.

**Decimal Normalization:** Base fees are normalized to 18 decimals regardless of the actual token decimals. For example, if USDT (6 decimals) is used as a fee token, the base fee should be set as if it has 18 decimals. The contract automatically normalizes the fee calculation when retrieving base fees for tokens with different decimal configurations.

**Returns:** True if the fee token parameters were added, false otherwise

### setFeeMultiplier()
```solidity
function setFeeMultiplier(FeeType _feeType, uint256 _multiplier) external onlyGov whenNotPaused nonReentrant returns (bool)
```
Set the fee multiplier (of baseFee) for a particular FeeType.

**Parameters:**
- `_feeType`: The FeeType enum to set the fee multiplier for
- `_multiplier`: The multiplier to set for the FeeType

**Returns:** True if the fee multiplier was set, false otherwise

### getFeeMultiplier()
```solidity
function getFeeMultiplier(FeeType _feeType) public view returns (uint256)
```
Get the fee multiplier for a given FeeType.

**Parameters:**
- `_feeType`: The FeeType enum to get the fee multiplier for

**Returns:** The fee multiplier for a given FeeType

## Fee Calculation

### getXChainFee()
```solidity
function getXChainFee(string[] memory _toChainIDsStr, bool _includeLocal, FeeType _feeType, string memory _feeTokenStr) public view returns (uint256)
```
Get the fee for a given AssetX operation, depending on the FeeType and the array of chains involved and whether to include the local chain or not.

**Parameters:**
- `_toChainIDsStr`: An array of chainIds (as strings) to include in the fee calculation
- `_includeLocal`: When to include the local chain in the fee calculation or not
- `_feeType`: The FeeType enum to get the fee for
- `_feeTokenStr`: The fee token address (as a string) to calculate the fee in

**Returns:** The fee for a given AssetX operation, depending on the FeeType and the array of chains involved and whether to include the local chain or not

### getToChainBaseFee()
```solidity
function getToChainBaseFee(string memory _toChainIDStr, string memory _feeTokenStr) public view returns (uint256)
```
Get the configured base fee for a cross chain operation.

**Parameters:**
- `_toChainIDStr`: The chainID (as a string) to consider the fee for
- `_feeTokenStr`: The fee token address (as a string)

**Returns:** The configured base fee for a cross chain operation

**Decimal Normalization:** This function automatically normalizes the base fee from 18 decimals to the actual token decimals. For tokens with fewer decimals (like USDT with 6 decimals), the returned fee will be proportionally smaller. For tokens with 18 decimals, the fee is returned as-is.

## Fee Payment

### payFee()
```solidity
function payFee(uint256 _fee, string memory _feeTokenStr) external nonReentrant whenNotPaused returns (uint256)
```
Pay a fee to this contract for an AssetX service.

**Parameters:**
- `_fee`: The fee to pay in wei
- `_feeTokenStr`: The fee token address (as a string) to pay in

**Returns:** The fee paid in wei

## Fee Withdrawal

### withdrawFee()
```solidity
function withdrawFee(string memory _feeTokenStr, uint256 _amount, string memory _treasuryStr) external onlyGov nonReentrant whenNotPaused returns (bool)
```
Allow Governance to withdraw the fees collected in this contract to a treasury address.

**Parameters:**
- `_feeTokenStr`: The fee contract address (as a string) to withdraw
- `_amount`: The amount to withdraw in wei
- `_treasuryStr`: The wallet address (as a string) to withdraw to

**Returns:** True if the fee was withdrawn, false otherwise

## Fee Reduction Management

### addFeeReduction()
```solidity
function addFeeReduction(address[] memory _addresses, uint256[] memory _reductionFactors, uint256[] memory _expirations) external onlyGov whenNotPaused nonReentrant returns (bool)
```
Add fee reduction for multiple addresses with corresponding expiration times.

**Parameters:**
- `_addresses`: Array of addresses to add fee reduction for
- `_reductionFactors`: Array of reduction factors (0-10000, where 10000 = 100%)
- `_expirations`: Array of expiration timestamps (0 for permanent)

**Returns:** True if all fee reductions were added successfully

### removeFeeReduction()
```solidity
function removeFeeReduction(address[] memory _addresses) external onlyGov whenNotPaused nonReentrant returns (bool)
```
Remove fee reduction for multiple addresses.

**Parameters:**
- `_addresses`: Array of addresses to remove fee reduction for

**Returns:** True if all fee reductions were removed successfully

### updateFeeReductionExpiration()
```solidity
function updateFeeReductionExpiration(address[] memory _addresses, uint256[] memory _newExpirations) external onlyGov whenNotPaused nonReentrant returns (bool)
```
Update expiration times for multiple addresses.

**Parameters:**
- `_addresses`: Array of addresses to update expiration for
- `_newExpirations`: Array of new expiration timestamps (0 for permanent)

**Returns:** True if all expiration times were updated successfully

### getFeeReduction()
```solidity
function getFeeReduction(address _address) external view returns (uint256)
```
Get the effective fee reduction factor for a single address.

**Parameters:**
- `_address`: The address to get fee reduction for

**Returns:** The effective fee reduction factor (0 if no reduction or expired)

## Internal Functions

### _isSafeERC20Compliant()
```solidity
function _isSafeERC20Compliant(address token) internal view returns (bool)
```
Check if a token is SafeERC20 compliant.

**Parameters:**
- `token`: The token address to check

**Returns:** True if the token is SafeERC20 compliant, false otherwise

### _isUpgradeable()
```solidity
function _isUpgradeable(address token) internal view returns (bool)
```
Check if a token is upgradeable (proxy pattern).

**Parameters:**
- `token`: The token address to check

**Returns:** True if the token is upgradeable, false otherwise

### _c3Fallback()
```solidity
function _c3Fallback(bytes4 _selector, bytes calldata _data, bytes calldata _reason) internal virtual override returns (bool)
```
The c3caller required fallback contract in the event of a cross-chain error.

**Returns:** True if the fallback was successful, false otherwise

## Events

- `LogFallback(bytes4 selector, bytes data, bytes reason)`: Emitted on C3Caller fallback
- `AddFeeToken(address indexed feeToken)`: Emitted when fee token is added
- `DelFeeToken(address indexed feeToken)`: Emitted when fee token is removed
- `SetFeeMultiplier(FeeType indexed feeType, uint256 multiplier)`: Emitted when fee multiplier is set
- `WithdrawFee(address indexed feeToken, address indexed treasury, uint256 amount)`: Emitted when fees are withdrawn
- `AddFeeReduction(address indexed account, uint256 reductionFactor, uint256 expiration)`: Emitted when fee reduction is added
- `RemoveFeeReduction(address indexed account)`: Emitted when fee reduction is removed
- `UpdateFeeReductionExpiration(address indexed account, uint256 newExpiration)`: Emitted when fee reduction expiration is updated

## Security Features

- Access control via onlyGov modifier
- Reentrancy protection for fee operations
- Pausable operations for emergency control
- Upgradeable using UUPS pattern for secure upgrades
- Input validation for all parameters
- Safe math using OpenZeppelin Math library
- Transfer safety using SafeERC20
- Overflow protection with MAX_SAFE_MULTIPLIER
- Token validation and safety checks
- Fee reduction system with expiration management

## Integration Points

- `C3Caller`: Cross-chain communication system
- `Governance`: Controls fee configuration and withdrawals
- `AssetX Contracts`: All contracts use this for fee calculation
- `ERC20 Tokens`: Multiple fee token support
- `Treasury`: Receives withdrawn fees

## Error Handling

The contract uses custom error types for efficient gas usage:

- `FeeManager_InvalidLength(CTMRWAErrorParam.Address)`: Thrown when address string is invalid length
- `FeeManager_InvalidLength(CTMRWAErrorParam.ChainID)`: Thrown when chain ID string is invalid
- `FeeManager_InvalidLength(CTMRWAErrorParam.Input)`: Thrown when input parameters are invalid
- `FeeManager_InvalidLength(CTMRWAErrorParam.Multiplier)`: Thrown when multiplier exceeds safe limit
- `FeeManager_NonExistentToken(address token)`: Thrown when token doesn't exist in fee list
- `FeeManager_FailedTransfer()`: Thrown when token transfer fails
- `FeeManager_UnsafeToken(address token)`: Thrown when token is not SafeERC20 compliant
- `FeeManager_InvalidDecimals(address token, uint8 decimals)`: Thrown when token has invalid decimals
- `FeeManager_UpgradeableToken(address token)`: Thrown when token is upgradeable
- `FeeManager_InvalidFeeType(FeeType feeType)`: Thrown when fee type is invalid
- `FeeManager_UnsetFee(address token)`: Thrown when fee is not set for token
- `FeeManager_InvalidReductionFactor(uint256 factor)`: Thrown when reduction factor is invalid
- `FeeManager_InvalidExpiration(uint256 expiration)`: Thrown when expiration is invalid
- `FeeManager_InvalidAddress(address addr)`: Thrown when address is invalid

## Fee Calculation Process

### 1. Base Fee Configuration
- Governance configures base fees per chain-token combination
- Call addFeeToken with chain ID and token arrays
- Base fees stored in _toFeeConfigs mapping
- **Important:** Base fees should be set as if all tokens have 18 decimals, regardless of actual token decimals

### 2. Fee Multiplier Setting
- Governance sets multipliers for each FeeType
- Call setFeeMultiplier with FeeType and multiplier
- Multipliers stored in feeMultiplier array

### 3. Fee Calculation
- Calculate fee for specific operation
- Call getXChainFee with operation parameters
- Sum base fees × multiplier
- **Decimal Normalization:** Base fees are automatically normalized from 18 decimals to actual token decimals
- Total fee for the operation

### 4. Fee Payment
- User pays calculated fee
- Call payFee with amount and token
- Transfer tokens from user to contract
- Fee collected in contract

### 5. Fee Withdrawal
- Governance withdraws collected fees
- Call withdrawFee with token, amount, and treasury
- Transfer tokens to treasury address
- Fees distributed to treasury

## Use Cases

### Multi-currency Fee Support
- Users want to pay fees in different currencies
- Add multiple fee tokens, configure base fees
- Flexible payment options for users

### Cross-chain Fee Management
- Different fees for different destination chains
- Configure base fees per chain-token combination
- Optimized fees based on chain characteristics

### Governance Fee Control
- Governance needs to manage fee structure
- Add/remove tokens, set multipliers, withdraw fees
- Centralized fee management and revenue collection

### Emergency Controls
- Emergency situations requiring fee pause
- Use pause/unpause functions
- Emergency control over fee operations

### Fee Reduction System
- Provide fee discounts to specific addresses
- Set reduction factors and expiration times
- Flexible fee management for different user types

## Best Practices

1. **Fee Planning**: Plan fee structure based on operational costs
2. **Multiplier Safety**: Use reasonable multipliers to prevent overflow
3. **Token Management**: Carefully manage fee token additions/removals
4. **Cross-chain Coordination**: Coordinate fee configuration across chains
5. **Treasury Management**: Regular fee withdrawals to treasury
6. **Fee Reduction Management**: Properly manage fee reduction expiration
7. **Decimal Normalization**: Always set base fees as if tokens have 18 decimals, regardless of actual token decimals (e.g., USDT with 6 decimals should have base fees set in 18-decimal format)

## Limitations

- Single Instance: Only one FeeManager per chain
- Governance Dependency: Requires governance for configuration changes
- Token List Management: Fee token indices may change when tokens are removed/added
- Chain-specific: Each FeeManager operates on a single chain
- Upgrade Dependency: Requires governance for contract upgrades

## Fee Types and Multipliers

### FeeType Enum
The contract supports 30 different fee types (indices 0-29) with configurable multipliers:

- **Base Fee**: Configured per chain-token combination
- **Service Fee**: Base fee × multiplier for specific operation type
- **Total Fee**: Sum of all applicable fees for the operation

### Multiplier Management
- **Safe Limits**: MAX_SAFE_MULTIPLIER prevents overflow
- **Governance Control**: Only governance can set multipliers
- **Flexible Configuration**: Different multipliers for different operations
- **Event Tracking**: All multiplier changes are logged

## Cross-chain Fee Architecture

### Fee Calculation Logic
- **Destination Chains**: Sum base fees for all destination chains
- **Local Chain**: Optionally include local chain base fee
- **Fee Type**: Apply appropriate multiplier for operation type
- **Token Support**: Validate fee token is supported

### Chain Coordination
- **Independent Configuration**: Each chain configures its own fees
- **Cross-chain Operations**: Fees calculated based on destination chains
- **Local Inclusion**: Option to include local chain in fee calculation
- **Consistent Structure**: Same fee structure across all chains

## Gas Optimization

### Fee Calculation Costs
- **Base Fee Lookup**: ~2600 gas per chain lookup
- **Multiplier Calculation**: ~2100 gas for multiplication
- **Token Validation**: ~5000 gas for token list iteration
- **Total Estimate**: ~10000-50000 gas per fee calculation

### Optimization Strategies
- **Efficient Storage**: Use mappings for O(1) lookups
- **Batch Operations**: Consider batch fee configurations
- **Gas Estimation**: Always estimate gas before operations
- **Storage Optimization**: Minimize storage operations

## Security Considerations

### Access Control
- **Governance Authorization**: Only governance can perform admin functions
- **Pause Controls**: Emergency pause capability for security
- **Upgrade Security**: Secure upgrade mechanism with governance control
- **Function Validation**: Validate all function parameters

### Financial Security
- **Transfer Safety**: Use SafeERC20 for all token transfers
- **Balance Validation**: Ensure sufficient balance before withdrawals
- **Overflow Protection**: Prevent mathematical overflow
- **Reentrancy Protection**: Prevent reentrancy attacks

### Configuration Security
- **Input Validation**: Validate all input parameters
- **Safe Limits**: Enforce safe limits for multipliers
- **Token Management**: Secure token addition/removal process
- **Cross-chain Safety**: Secure cross-chain fee calculations

## Treasury Management

### Fee Collection
- **Automatic Collection**: Fees collected automatically during operations
- **Multi-token Support**: Collect fees in multiple currencies
- **Balance Tracking**: Track balances for each fee token
- **Withdrawal Control**: Governance controls fee withdrawals

### Withdrawal Process
- **Governance Authorization**: Only governance can withdraw fees
- **Balance Limits**: Withdrawal limited to available balance
- **Treasury Transfer**: Secure transfer to treasury address
- **Event Logging**: All withdrawals logged for transparency