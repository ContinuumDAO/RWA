# CTMRWAUtils Contract Documentation

## Overview

**Contract Name:** CTMRWAUtils  
**File:** `src/utils/CTMRWAUtils.sol`  
**License:** BSL-1.1  
**Author:** @Selqui ContinuumDAO  
**Type:** Library  

## Contract Description

CTMRWAUtils is a utility library that provides common helper functions and enums used throughout the CTMRWA1 ecosystem. It contains string manipulation utilities, address conversion functions, and standardized enums for error handling and type safety across all CTMRWA1 contracts.

### Key Features
- String manipulation utilities
- Address conversion functions
- Standardized enums for error handling
- Type safety across the ecosystem
- Common utility functions
- Error standardization

## Enums

### Uint
Enumeration of numeric values that can be referenced in errors:
```solidity
enum Uint {
    TokenId,        // Token identifier
    TokenName,      // Token name
    Symbol,         // Token symbol
    SlotLength,     // Slot array length
    SlotName,       // Slot name
    Value,          // Token value
    Input,          // Input parameter
    Title,          // Title string
    URI,            // URI string
    Nonce,          // Nonce value
    Address,        // Address parameter
    Balance,        // Balance amount
    Dividend,       // Dividend amount
    Commission,     // Commission amount
    CountryCode,    // Country code
    Offering,       // Offering amount
    MinInvestment,  // Minimum investment
    InvestmentLow,  // Low investment range
    InvestmentHigh, // High investment range
    Payable,        // Payable amount
    ChainID,        // Chain identifier
    Multiplier,     // Fee multiplier
    BaseURI         // Base URI
}
```

### Time
Enumeration for time-related operations:
```solidity
enum Time {
    Early,  // Early time period
    Late    // Late time period
}
```

### RWA
Enumeration for RWA-specific parameters:
```solidity
enum RWA {
    Type,    // RWA type
    Version  // RWA version
}
```

### Address
Enumeration of common addresses referenced in errors:
```solidity
enum Address {
    Sender,         // Message sender
    Owner,          // Token owner
    To,             // Recipient address
    From,           // Source address
    Regulator,      // Regulator wallet
    TokenAdmin,     // Token administrator
    Factory,        // Factory contract
    Deployer,       // Deployer contract
    Dividend,       // Dividend contract
    Identity,       // Identity contract
    Map,            // Map contract
    Storage,        // Storage contract
    Sentry,         // Sentry contract
    SentryManager,  // Sentry manager
    StorageManager, // Storage manager
    RWAERC20,       // RWA ERC20 contract
    Override,       // Override wallet
    Admin,          // Administrator
    Minter,         // Minter address
    Fallback,       // Fallback contract
    Token,          // Token contract
    Invest,         // Investment contract
    DeployInvest,   // Deploy investment contract
    Spender,        // Spender address
    ZKMe,           // ZKMe verifier
    Cooperator,     // Cooperating entity
    Gateway,        // Gateway contract
    FeeManager,     // Fee manager
    RWAX,           // CTMRWA1X contract
    ERC20Deployer,  // ERC20 deployer
    Allowable,      // Allowable address
    ApprovedOrOwner, // Approved or owner
    Wallet          // Wallet address
}
```

### List
Enumeration for list-related operations:
```solidity
enum List {
    WL_Disabled,     // Whitelisting is disabled
    WL_Enabled,      // Whitelisting is enabled
    WL_BL_Undefined, // Neither whitelist nor blacklist are defined
    WL_BL_Defined,   // Whitelist and blacklist are defined
    WL_KYC_Disabled  // Neither whitelist nor KYC is enabled
}
```

## Custom Errors

### CTMRWAUtils_InvalidLength
```solidity
error CTMRWAUtils_InvalidLength(Uint);
```
**Description:** Thrown when a parameter has an invalid length.

### CTMRWAUtils_InvalidHexCharacter
```solidity
error CTMRWAUtils_InvalidHexCharacter();
```
**Description:** Thrown when a string contains invalid hex characters.

### CTMRWAUtils_StringTooLong
```solidity
error CTMRWAUtils_StringTooLong();
```
**Description:** Thrown when a string exceeds the maximum allowed length.

## String Manipulation Functions

### _toLower()
```solidity
function _toLower(string memory str) internal pure returns (string memory)
```
**Description:** Converts a string to lowercase.  
**Parameters:**
- `str` (string): The string to convert
**Returns:** Lowercase version of the input string  

### _stringToAddress()
```solidity
function _stringToAddress(string memory str) internal pure returns (address)
```
**Description:** Converts a string to an address.  
**Parameters:**
- `str` (string): The string to convert (must be valid hex address)
**Returns:** Address representation of the string  
**Reverts:** If string is not a valid hex address  

### _stringToArray()
```solidity
function _stringToArray(string memory str) internal pure returns (string[] memory)
```
**Description:** Converts a string to a single-element array.  
**Parameters:**
- `str` (string): The string to convert
**Returns:** Array containing the input string  

### _boolToArray()
```solidity
function _boolToArray(bool value) internal pure returns (bool[] memory)
```
**Description:** Converts a boolean to a single-element array.  
**Parameters:**
- `value` (bool): The boolean to convert
**Returns:** Array containing the input boolean  

## Address Conversion Functions

### _addressToString()
```solidity
function _addressToString(address addr) internal pure returns (string memory)
```
**Description:** Converts an address to a string.  
**Parameters:**
- `addr` (address): The address to convert
**Returns:** String representation of the address  

### _addressToHexString()
```solidity
function _addressToHexString(address addr) internal pure returns (string memory)
```
**Description:** Converts an address to a hex string.  
**Parameters:**
- `addr` (address): The address to convert
**Returns:** Hex string representation of the address  

## Validation Functions

### _validateAddress()
```solidity
function _validateAddress(string memory str) internal pure returns (bool)
```
**Description:** Validates if a string is a valid address.  
**Parameters:**
- `str` (string): The string to validate
**Returns:** True if the string is a valid address  

### _validateHexString()
```solidity
function _validateHexString(string memory str) internal pure returns (bool)
```
**Description:** Validates if a string is a valid hex string.  
**Parameters:**
- `str` (string): The string to validate
**Returns:** True if the string is a valid hex string  

## Array Manipulation Functions

### _removeFromArray()
```solidity
function _removeFromArray(string[] memory arr, string memory element) internal pure returns (string[] memory)
```
**Description:** Removes an element from a string array.  
**Parameters:**
- `arr` (string[]): The input array
- `element` (string): The element to remove
**Returns:** New array with the element removed  

### _containsElement()
```solidity
function _containsElement(string[] memory arr, string memory element) internal pure returns (bool)
```
**Description:** Checks if an array contains a specific element.  
**Parameters:**
- `arr` (string[]): The array to search
- `element` (string): The element to find
**Returns:** True if the element is found in the array  

## String Extension Functions

The library provides extension functions for the string type:

### _stringToAddress()
```solidity
function _stringToAddress(string memory str) internal pure returns (address)
```
**Description:** Extension function to convert string to address.  

### _stringToArray()
```solidity
function _stringToArray(string memory str) internal pure returns (string[] memory)
```
**Description:** Extension function to convert string to array.  

### _toLower()
```solidity
function _toLower(string memory str) internal pure returns (string memory)
```
**Description:** Extension function to convert string to lowercase.  

## Usage Examples

### Converting Address to String
```solidity
import { CTMRWAUtils } from "./utils/CTMRWAUtils.sol";

contract Example {
    using CTMRWAUtils for string;
    
    function getAddressString(address addr) public pure returns (string memory) {
        return addr._addressToString();
    }
}
```

### Validating Address String
```solidity
function validateAddressInput(string memory addrStr) public pure returns (bool) {
    return CTMRWAUtils._validateAddress(addrStr);
}
```

### Error Handling
```solidity
function processTokenName(string memory name) public pure {
    if (bytes(name).length > 50) {
        revert CTMRWAUtils_InvalidLength(Uint.TokenName);
    }
    // Process the name...
}
```

## Integration Points

- **All CTMRWA1 Contracts**: Used throughout the ecosystem
- **Error Handling**: Standardized error enums
- **Type Safety**: Consistent type definitions
- **String Operations**: Common string manipulation utilities
- **Address Handling**: Address conversion and validation

## Key Features

- **Standardized Enums**: Consistent error and type definitions
- **String Utilities**: Common string manipulation functions
- **Address Conversion**: Safe address-to-string and string-to-address conversion
- **Validation Functions**: Input validation utilities
- **Array Operations**: Array manipulation helpers
- **Type Safety**: Strong typing for better code safety
- **Error Standardization**: Consistent error handling across contracts

## Best Practices

1. **Use Enums**: Always use the provided enums for error handling
2. **Validate Inputs**: Use validation functions before processing
3. **Safe Conversions**: Use the provided conversion functions for type safety
4. **Consistent Naming**: Follow the established naming conventions
5. **Error Handling**: Use the standardized error types for consistency
