# CTMRWAUtils Library Documentation

## Overview

`CTMRWAUtils` provides shared utilities and strongly-typed error parameters used across the CTMRWA1 suite. It includes:
- A canonical `CTMRWAErrorParam` enum for compact, structured error signaling
- String utilities (lowercasing, hex parsing, address parsing, length checks)
- Single-value-to-array helpers used to build cross-chain batched payloads

## Error Parameter Enum

```solidity
enum CTMRWAErrorParam {
    TokenId, TokenName, Symbol, SlotLength, SlotName, Value, Input, Title, URI, Nonce,
    Address, Balance, Dividend, Commission, CountryCode, Offering, MinInvestment,
    InvestmentLow, InvestmentHigh, Payable, ChainID, Multiplier, BaseURI, Early, Late,
    Type, Version, Sender, Owner, To, From, Regulator, TokenAdmin, Factory, Deployer,
    Identity, Map, Storage, Sentry, SentryManager, StorageManager, RWAERC20, Override,
    Admin, Minter, Fallback, Token, Invest, DeployInvest, Spender, ZKMe, Cooperator,
    Gateway, FeeManager, RWAX, ERC20Deployer, Allowable, ApprovedOrOwner, Wallet,
    WL_Disabled, WL_Enabled, WL_BL_Undefined, WL_BL_Defined, WL_KYC_Disabled, Utils
}
```

Used in custom errors throughout the system (e.g., `..._InvalidLength(CTMRWAErrorParam.Address)`), enabling consistent, gas-efficient error reporting without verbose strings.

## Custom Errors

```solidity
error CTMRWAUtils_InvalidLength(CTMRWAErrorParam);
error CTMRWAUtils_InvalidHexCharacter();
error CTMRWAUtils_StringTooLong();
```

## String Utilities

### _toLower
```solidity
function _toLower(string memory str) internal pure returns (string memory)
```
- Converts ASCII uppercase characters in `str` to lowercase.

### _stringToAddress
```solidity
function _stringToAddress(string memory str) internal pure returns (address)
```
- Parses a hex string address with 0x prefix and length 42 into an `address`.
- Reverts `CTMRWAUtils_InvalidLength(Address)` on invalid length/prefix.
- Reverts `CTMRWAUtils_InvalidHexCharacter()` on invalid hex characters.

### _hexCharToByte
```solidity
function _hexCharToByte(bytes1 char) internal pure returns (uint8)
```
- Converts a single ASCII hex character to its 0–15 nibble value.
- Reverts on non-hex input.

### _checkStringLength
```solidity
function _checkStringLength(string memory _str, uint256 _len) internal pure
```
- Reverts `CTMRWAUtils_StringTooLong()` if `_str.length > _len`.

## Single-Value Array Builders

These helpers wrap a single value into a 1-element array for composing multi-chain batched calls.

### _stringToArray
```solidity
function _stringToArray(string memory _string) internal pure returns (string[] memory)
```

### _boolToArray
```solidity
function _boolToArray(bool _bool) internal pure returns (bool[] memory)
```

### _uint256ToArray
```solidity
function _uint256ToArray(uint256 _myUint256) internal pure returns (uint256[] memory)
```

### _uint8ToArray
```solidity
function _uint8ToArray(uint8 _myUint8) internal pure returns (uint8[] memory)
```

### _bytes32ToArray
```solidity
function _bytes32ToArray(bytes32 _myBytes32) internal pure returns (bytes32[] memory)
```

## Integration Notes

- Address parsing (`_stringToAddress`) is used wherever addresses are passed as strings across chains.
- Single-value array builders are heavily used by managers sending one-item batched parameters via C3 calls.
- Error parameter enum values map directly to failure contexts (e.g., `Title`, `URI`, `Sender`).

## Best Practices

- Always validate string addresses via `_stringToAddress` rather than manual parsing.
- Use `_checkStringLength` before persisting external strings (titles, object names, etc.).
- Prefer enum-based custom errors with `CTMRWAErrorParam` for consistent, low-gas diagnostics.
# CTMRWAUtils Contract Documentation

## Overview

**Contract Name:** CTMRWAUtils  
**Author:** @Selqui ContinuumDAO  
**License:** BSL-1.1  
**Solidity Version:** 0.8.27

The CTMRWAUtils contract is a utility library that provides essential helper functions for the CTMRWA ecosystem. It contains a comprehensive error parameter enumeration and various utility functions for string manipulation, address conversion, and data type transformations.

This library serves as a shared utility across all CTMRWA contracts, providing standardized error handling and common utility functions that are frequently used throughout the ecosystem.

## Key Features

- **Error Parameter Enumeration:** Comprehensive error parameter definitions for consistent error handling
- **String Utilities:** String manipulation and validation functions
- **Address Conversion:** Safe conversion between strings and EVM addresses
- **Data Type Conversion:** Array conversion utilities for various data types
- **Hex Character Handling:** Safe hex character to byte conversion
- **String Validation:** String length validation and checking
- **Cross-contract Compatibility:** Designed for use across all CTMRWA contracts

## Error Parameter Enumeration

The `CTMRWAErrorParam` enum provides a comprehensive set of error parameters used throughout the CTMRWA ecosystem:

### Token-related Parameters
- **`TokenId`**: Token ID related errors
- **`TokenName`**: Token name related errors
- **`Symbol`**: Token symbol related errors
- **`Value`**: Token value related errors
- **`Balance`**: Balance related errors
- **`Spender`**: Spender authorization errors

### Slot-related Parameters
- **`SlotLength`**: Slot length validation errors
- **`SlotName`**: Slot name related errors

### Input Validation Parameters
- **`Input`**: General input validation errors
- **`Title`**: Title validation errors
- **`URI`**: URI validation errors
- **`Address`**: Address validation errors
- **`CountryCode`**: Country code validation errors
- **`ChainID`**: Chain ID validation errors

### Investment Parameters
- **`Offering`**: Offering related errors
- **`MinInvestment`**: Minimum investment errors
- **`InvestmentLow`**: Investment too low errors
- **`InvestmentHigh`**: Investment too high errors
- **`Payable`**: Payment related errors

### Contract Address Parameters
- **`Sender`**: Sender address errors
- **`Owner`**: Owner address errors
- **`To`**: Recipient address errors
- **`From`**: Source address errors
- **`Regulator`**: Regulator address errors
- **`TokenAdmin`**: Token admin address errors
- **`Factory`**: Factory contract address errors
- **`Deployer`**: Deployer contract address errors
- **`Dividend`**: Dividend contract address errors
- **`Identity`**: Identity contract address errors
- **`Map`**: Map contract address errors
- **`Storage`**: Storage contract address errors
- **`Sentry`**: Sentry contract address errors
- **`SentryManager`**: Sentry manager address errors
- **`StorageManager`**: Storage manager address errors
- **`RWAERC20`**: RWA ERC20 contract address errors
- **`Invest`**: Investment contract address errors
- **`DeployInvest`**: Deploy investment contract address errors
- **`ZKMe`**: ZKMe contract address errors
- **`Cooperator`**: Cooperator address errors
- **`Gateway`**: Gateway contract address errors
- **`FeeManager`**: Fee manager address errors
- **`RWAX`**: RWA1X contract address errors
- **`ERC20Deployer`**: ERC20 deployer address errors

### Configuration Parameters
- **`Commission`**: Commission rate errors
- **`Multiplier`**: Multiplier value errors
- **`BaseURI`**: Base URI errors
- **`Nonce`**: Nonce value errors
- **`Type`**: RWA type errors
- **`Version`**: Version errors

### Access Control Parameters
- **`Override`**: Override permission errors
- **`Admin`**: Admin permission errors
- **`Minter`**: Minter permission errors
- **`ApprovedOrOwner`**: Approval or ownership errors
- **`Wallet`**: Wallet address errors

### Time-related Parameters
- **`Early`**: Too early timing errors
- **`Late`**: Too late timing errors

### Whitelist Parameters
- **`WL_Disabled`**: Whitelist disabled errors
- **`WL_Enabled`**: Whitelist enabled errors
- **`WL_BL_Undefined`**: Neither whitelist nor blacklist defined
- **`WL_BL_Defined`**: Both whitelist and blacklist defined
- **`WL_KYC_Disabled`**: Neither whitelist nor KYC enabled

### Validation Parameters
- **`Allowable`**: Allowable value errors

## Core Functions

### String Utilities

#### `_toLower(string memory str)`
- **Access:** Internal pure function
- **Purpose:** Convert a string to lowercase
- **Parameters:** `str` - The string to convert
- **Returns:** The lowercase version of the input string
- **Logic:**
  - Converts string to bytes for processing
  - Iterates through each character
  - Converts uppercase characters (ASCII 65-90) to lowercase by adding 32
  - Leaves other characters unchanged
- **Use Case:** Standardizing string comparisons and storage

#### `_checkStringLength(string memory _str, uint256 _len)`
- **Access:** Internal pure function
- **Purpose:** Validate that a string length is within specified limits
- **Parameters:**
  - `_str` - The string to check
  - `_len` - The maximum allowed length
- **Logic:** Reverts with `CTMRWAUtils_StringTooLong()` if string exceeds maximum length
- **Use Case:** Input validation for string parameters

### Address Conversion

#### `_stringToAddress(string memory str)`
- **Access:** Internal pure function
- **Purpose:** Convert a hex string to an EVM address
- **Parameters:** `str` - The hex string to convert (must be 42 characters including "0x")
- **Returns:** The EVM address
- **Validation:**
  - Ensures string length is exactly 42 characters
  - Reverts with `CTMRWAUtils_InvalidLength(CTMRWAErrorParam.Address)` if length is invalid
- **Logic:**
  - Skips "0x" prefix
  - Converts each pair of hex characters to a byte
  - Combines bytes into 20-byte address
- **Use Case:** Converting string addresses from external sources to EVM addresses

#### `_hexCharToByte(bytes1 char)`
- **Access:** Internal pure function
- **Purpose:** Convert a single hex character to its byte value
- **Parameters:** `char` - The hex character to convert
- **Returns:** The byte value (0-15)
- **Logic:**
  - Handles digits 0-9 (ASCII 48-57)
  - Handles lowercase letters a-f (ASCII 97-102)
  - Handles uppercase letters A-F (ASCII 65-70)
  - Reverts with `CTMRWAUtils_InvalidHexCharacter()` for invalid characters
- **Use Case:** Helper function for hex string parsing

### Array Conversion Utilities

#### `_stringToArray(string memory _string)`
- **Access:** Internal pure function
- **Purpose:** Convert a single string to an array with one element
- **Parameters:** `_string` - The string to convert
- **Returns:** Array containing the single string
- **Use Case:** Converting single values to arrays for cross-chain operations

#### `_boolToArray(bool _bool)`
- **Access:** Internal pure function
- **Purpose:** Convert a single boolean to an array with one element
- **Parameters:** `_bool` - The boolean to convert
- **Returns:** Array containing the single boolean
- **Use Case:** Converting single boolean values to arrays for cross-chain operations

#### `_uint256ToArray(uint256 _myUint256)`
- **Access:** Internal pure function
- **Purpose:** Convert a single uint256 to an array with one element
- **Parameters:** `_myUint256` - The uint256 to convert
- **Returns:** Array containing the single uint256
- **Use Case:** Converting single uint256 values to arrays for cross-chain operations

#### `_uint8ToArray(uint8 _myUint8)`
- **Access:** Internal pure function
- **Purpose:** Convert a single uint8 to an array with one element
- **Parameters:** `_myUint8` - The uint8 to convert
- **Returns:** Array containing the single uint8
- **Use Case:** Converting single uint8 values to arrays for cross-chain operations

#### `_bytes32ToArray(bytes32 _myBytes32)`
- **Access:** Internal pure function
- **Purpose:** Convert a single bytes32 to an array with one element
- **Parameters:** `_myBytes32` - The bytes32 to convert
- **Returns:** Array containing the single bytes32
- **Use Case:** Converting single bytes32 values to arrays for cross-chain operations

## Error Types

The library defines three custom error types for efficient gas usage:

- **`CTMRWAUtils_InvalidLength(CTMRWAErrorParam)`**: Thrown when a parameter has an invalid length
- **`CTMRWAUtils_InvalidHexCharacter()`**: Thrown when an invalid hex character is encountered
- **`CTMRWAUtils_StringTooLong()`**: Thrown when a string exceeds the maximum allowed length

## Integration Points

The CTMRWAUtils library is used throughout the CTMRWA ecosystem:

- **All CTMRWA Contracts**: Provide standardized error handling and utility functions
- **Cross-chain Operations**: Array conversion utilities for C3Caller operations
- **String Processing**: Address and string manipulation across the ecosystem
- **Input Validation**: Consistent validation patterns across all contracts

## Use Cases

### Cross-chain Data Preparation
- **Scenario:** Prepare data for cross-chain operations
- **Process:** Use array conversion functions to format single values as arrays
- **Benefit:** Consistent data formatting for C3Caller operations

### Address Handling
- **Scenario:** Convert string addresses from external sources
- **Process:** Use _stringToAddress for safe conversion
- **Benefit:** Safe and validated address conversion

### String Standardization
- **Scenario:** Standardize string comparisons
- **Process:** Use _toLower for case-insensitive comparisons
- **Benefit:** Consistent string handling across the ecosystem

### Input Validation
- **Scenario:** Validate string inputs
- **Process:** Use _checkStringLength for length validation
- **Benefit:** Consistent input validation patterns

## Best Practices

1. **Error Consistency:** Use the provided error parameters for consistent error handling
2. **Address Validation:** Always use _stringToAddress for string-to-address conversion
3. **String Processing:** Use _toLower for case-insensitive string operations
4. **Input Validation:** Use _checkStringLength for string length validation
5. **Array Conversion:** Use appropriate conversion functions for cross-chain operations

## Gas Optimization

### Function Costs
- **String Conversion:** ~1000-5000 gas for string operations
- **Address Conversion:** ~2000-8000 gas for address parsing
- **Array Conversion:** ~500-2000 gas for single value to array conversion
- **Hex Parsing:** ~500-1500 gas per hex character

### Optimization Strategies
- **Efficient String Operations:** Minimize string operations in loops
- **Caching:** Cache converted addresses when possible
- **Batch Operations:** Use batch operations when converting multiple values
- **Gas Estimation:** Always estimate gas for complex operations

## Security Considerations

### Input Validation
- **String Length:** Always validate string lengths before processing
- **Hex Validation:** Validate hex characters before conversion
- **Address Format:** Ensure proper address format (42 characters with "0x" prefix)

### Error Handling
- **Consistent Errors:** Use standardized error parameters for consistency
- **Descriptive Errors:** Provide meaningful error information
- **Gas Efficiency:** Use custom errors for efficient gas usage

### Data Conversion
- **Safe Conversion:** Use provided functions for safe data conversion
- **Validation:** Always validate converted data when possible
- **Bounds Checking:** Check array bounds and string lengths

## Limitations

- **String Length:** Limited by Solidity string handling
- **Hex Parsing:** Only supports standard hex characters (0-9, a-f, A-F)
- **Address Format:** Requires exact 42-character format with "0x" prefix
- **Array Size:** Single value to array conversion only

