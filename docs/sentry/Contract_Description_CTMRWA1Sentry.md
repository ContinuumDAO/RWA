# Contract Description: CTMRWA1Sentry

## Overview

The `CTMRWA1Sentry` contract serves as the access control and compliance enforcement mechanism for Real-World Asset (RWA) tokens. It manages whitelists, KYC/KYB requirements, country restrictions, and other compliance features to ensure regulatory compliance for RWA token transfers.

## Contract Description

The CTMRWA1Sentry is a compliance contract that enforces access control rules for RWA token transfers. It maintains whitelists of approved addresses, manages KYC/KYB verification requirements, handles country-based restrictions, and ensures that only compliant users can receive RWA tokens.

## Key Features

- **Access Control**: Enforces whitelist-based access control for token transfers
- **KYC/KYB Integration**: Supports Know Your Customer and Know Your Business verification
- **Country Restrictions**: Manages country whitelist and blacklist functionality
- **Accredited Investor Controls**: Enforces accredited investor requirements
- **Age Verification**: Manages over-18 age requirements
- **Compliance Enforcement**: Ensures regulatory compliance for RWA tokens
- **Cross-chain Synchronization**: Maintains consistent compliance across chains

## Public Variables

### tokenAddr
```solidity
address public tokenAddr
```
The address of the associated CTMRWA1 token contract

### ID
```solidity
uint256 public ID
```
The unique identifier of the RWA token

### RWA_TYPE
```solidity
uint256 public immutable RWA_TYPE
```
The RWA type identifier (immutable)

### VERSION
```solidity
uint256 public immutable VERSION
```
The version of the RWA token (immutable)

### tokenAdmin
```solidity
address public tokenAdmin
```
The address of the token administrator

### ctmRwa1X
```solidity
address public ctmRwa1X
```
The address of the CTMRWA1X contract

### ctmRwa1Map
```solidity
address public ctmRwa1Map
```
The address of the CTMRWAMap contract

### sentryOptionsSet
```solidity
bool public sentryOptionsSet
```
Flag indicating if sentry options have been set

### ctmWhitelist
```solidity
string[] public ctmWhitelist
```
Array of whitelisted wallet addresses

### countryList
```solidity
string[] public countryList
```
Array of countries for KYC (white OR black listed, depending on flag)

### whitelistSwitch
```solidity
bool public whitelistSwitch
```
Switch to enable/disable whitelist functionality

### kycSwitch
```solidity
bool public kycSwitch
```
Switch to enable/disable KYC functionality

### kybSwitch
```solidity
bool public kybSwitch
```
Switch to enable/disable KYB functionality

### countryWLSwitch
```solidity
bool public countryWLSwitch
```
Switch to enable/disable country whitelist functionality

### countryBLSwitch
```solidity
bool public countryBLSwitch
```
Switch to enable/disable country blacklist functionality

### accreditedSwitch
```solidity
bool public accreditedSwitch
```
Switch to enable/disable accredited investor requirements

### age18Switch
```solidity
bool public age18Switch
```
Switch to enable/disable over-18 age requirements

## Constructor

### Constructor
```solidity
constructor(
    uint256 _ID,
    address _tokenAddr,
    uint256 _rwaType,
    uint256 _version,
    address _sentryManager,
    address _map
)
```
Initialize the sentry contract with required parameters

**Parameters:**
- `_ID`: The unique identifier of the RWA token
- `_tokenAddr`: The address of the CTMRWA1 token contract
- `_rwaType`: The RWA type identifier
- `_version`: The version of the RWA token
- `_sentryManager`: The address of the sentry manager contract
- `_map`: The address of the CTMRWAMap contract

## Administrative Functions

### setTokenAdmin()
```solidity
function setTokenAdmin(address _tokenAdmin) external onlyTokenAdmin returns (bool)
```
This function is normally called by CTMRWA1X to set a new tokenAdmin. It can also be called by the current tokenAdmin, but this should not normally be required and would only happen to clean up in the event of a cross-chain failure to reset the tokenAdmin

**Parameters:**
- `_tokenAdmin`: The new tokenAdmin address

**Returns:** success True if the tokenAdmin was set, false otherwise

### setZkMeParams()
```solidity
function setZkMeParams(string memory _appId, string memory _programNo, address _cooperator) external onlySentryManager
```
This function is called by SentryManager to set zkMe KYC service parameters

**Parameters:**
- `_appId`: The appId for the zkMe KYC service
- `_programNo`: The programNo for the zkMe KYC service
- `_cooperator`: The cooperator address for the zkMe KYC service

### getZkMeParams()
```solidity
function getZkMeParams() public view returns (string memory, string memory, address)
```
Recover the currently stored parameters for the zkMe KYC service

**Returns:**
- `appId`: The appId for the zkMe KYC service
- `programNo`: The programNo for the zkMe KYC service
- `cooperator`: The cooperator address for the zkMe KYC service

## Sentry Options Management

### setSentryOptionsLocal()
```solidity
function setSentryOptionsLocal(
    uint256 _ID,
    uint256 _version,
    bool _whitelist,
    bool _kyc,
    bool _kyb,
    bool _over18,
    bool _accredited,
    bool _countryWL,
    bool _countryBL
) external onlySentryManager
```
Set the sentry options on the local chain. This function is called by CTMRWA1SentryManager

**Parameters:**
- `_ID`: The ID of the RWA token
- `_version`: The version of the RWA token
- `_whitelist`: The whitelist switch
- `_kyc`: The KYC switch
- `_kyb`: The KYB switch
- `_over18`: The over 18 switch
- `_accredited`: The accredited investor switch
- `_countryWL`: The country whitelist switch
- `_countryBL`: The country blacklist switch

## Whitelist Management

### setWhitelistSentry()
```solidity
function setWhitelistSentry(
    uint256 _ID,
    uint256 _version,
    string[] memory _wallets,
    bool[] memory _choices
) external onlySentryManager
```
Set the Whitelist status on this chain. This contract holds the Whitelist state. This contract is called by CTMRWA1SentryManager

**Parameters:**
- `_ID`: The ID of the RWA token
- `_version`: The version of the RWA token
- `_wallets`: The list of wallets to set the state for
- `_choices`: The list of choices for the wallets

### getWhitelistLength()
```solidity
function getWhitelistLength() public view returns (uint256)
```
Get the number of Whitelisted wallet addresses (excluding the unused first one)

**Returns:** The length of the whitelist array minus 1

### getWhitelistAddressAtIndx()
```solidity
function getWhitelistAddressAtIndx(uint256 _indx) public view returns (string memory)
```
Get the Whitelist wallet address at an index as string

**Parameters:**
- `_indx`: The index of into the Whitelist to check

**Returns:** The whitelist address at the specified index

## Country List Management

### setCountryListLocal()
```solidity
function setCountryListLocal(
    uint256 _ID,
    uint256 _version,
    string[] memory _countryList,
    bool[] memory _choices
) external onlySentryManager
```
Set the country Whitelist or Blacklist on this chain. This contract holds the state. This contract is called by CTMRWA1SentryManager

**Parameters:**
- `_ID`: The ID of the RWA token
- `_version`: The version of the RWA token
- `_countryList`: The list of countries to set the state for
- `_choices`: The list of choices for the countries

## Access Control Functions

### isAllowableTransfer()
```solidity
function isAllowableTransfer(string memory _user) public view returns (bool)
```
This function checks if an address is allowed to receive value. It is called by _beforeValueTransfer in CTMRWA1 before any transfers. The contracts CTMRWA1Dividend and CTMRWA1Storage are allowed to pass.

**Parameters:**
- `_user`: address as a string that is being checked

**Returns:** True if the transfer is allowable, false otherwise

## Internal Functions

### _setWhitelist()
```solidity
function _setWhitelist(string[] memory _wallets, bool[] memory _choices) internal
```
Internal function to manage the wallet Whitelist on this chain. This contract holds the state. This contract is called by CTMRWA1SentryManager

**Parameters:**
- `_wallets`: The list of wallets to set the state for
- `_choices`: The list of choices for the wallets

### _setCountryList()
```solidity
function _setCountryList(string[] memory _countries, bool[] memory _choices) internal
```
Internal function to manage the state for a stored country Whitelist or Blacklist on this chain

**Parameters:**
- `_countries`: The list of countries to set the state for
- `_choices`: The list of choices for the countries

### _isWhitelisted()
```solidity
function _isWhitelisted(string memory _walletStr) internal view returns (bool)
```
Check if a particular address (as a string) is Whitelisted

**Parameters:**
- `_walletStr`: The address (as a string) to check

**Returns:** True if the address is whitelisted, false otherwise

### cID()
```solidity
function cID() internal view returns (uint256)
```
Get the current chain ID

**Returns:** The current chain ID

## Access Control Modifiers

### onlyTokenAdmin
```solidity
modifier onlyTokenAdmin()
```
Restricts access to the token admin and CTMRWA1X contract only

### onlySentryManager
```solidity
modifier onlySentryManager()
```
Restricts access to the sentry manager only

## Security Features

- **Access Control**: Multi-layer access control with role-based permissions
- **Whitelist Protection**: Prevents removal of token admin from whitelist
- **Input Validation**: Comprehensive input validation for all parameters
- **Version Control**: Version checking to ensure compatibility
- **ID Validation**: ID validation for all operations
- **Contract Integration**: Secure integration with other contracts
- **State Management**: Secure state management for whitelists and country lists

## Integration Points

- **CTMRWA1**: Core RWA token contract integration
- **CTMRWA1X**: Cross-chain token contract integration
- **CTMRWA1SentryManager**: Sentry manager for configuration
- **CTMRWAMap**: Contract address mapping
- **CTMRWA1Dividend**: Dividend contract integration
- **CTMRWA1Storage**: Storage contract integration

## Error Handling

The contract uses custom error types for gas efficiency:

- `CTMRWA1Sentry_OnlyAuthorized`: Thrown when unauthorized access is attempted
- `CTMRWA1Sentry_InvalidID`: Thrown when invalid ID is provided
- `CTMRWA1Sentry_InvalidVersion`: Thrown when invalid version is provided
- `CTMRWA1Sentry_Unauthorized`: Thrown when unauthorized operation is attempted
- `CTMRWA1Sentry_OutofBounds`: Thrown when index is out of bounds

## Access Control Process

### 1. Initialization
- Set up contract with required parameters
- Initialize whitelist with token admin
- Configure country list with default values

### 2. Options Configuration
- Set sentry options through sentry manager
- Configure whitelist, KYC, KYB switches
- Set country restrictions and age requirements

### 3. Whitelist Management
- Add/remove addresses from whitelist
- Maintain whitelist state
- Protect token admin from removal

### 4. Country List Management
- Configure country whitelist or blacklist
- Manage country restrictions
- Maintain country list state

### 5. Transfer Validation
- Check if transfer is allowable
- Validate whitelist status
- Enforce compliance requirements

## Use Cases

1. **RWA Token Compliance**: Enforce regulatory compliance for RWA tokens
2. **Access Control**: Manage who can receive RWA tokens
3. **KYC/KYB Integration**: Integrate with identity verification systems
4. **Country Restrictions**: Enforce geographic trading restrictions
5. **Accredited Investor Controls**: Manage sophisticated investor requirements
6. **Age Verification**: Enforce age requirements for trading
7. **Whitelist Management**: Maintain approved investor lists

## Best Practices

1. **Compliance Planning**: Plan compliance requirements before token deployment
2. **Whitelist Management**: Regularly update whitelist as needed
3. **Country Compliance**: Stay updated with regulatory requirements
4. **Access Control**: Maintain proper access control for sensitive operations
5. **State Management**: Properly manage whitelist and country list state
6. **Integration**: Ensure proper integration with other contracts
7. **Security**: Implement robust security measures

## Limitations

- **Single Token**: Each sentry contract is tied to a single RWA token
- **Manager Dependency**: Requires sentry manager for configuration
- **Cross-chain Dependency**: Depends on cross-chain communication
- **State Management**: Complex state management for whitelists and country lists
- **Compliance Dependency**: Depends on external compliance systems

## Future Enhancements

- **Additional Compliance**: Support for more compliance requirements
- **Advanced Analytics**: Compliance analytics and reporting
- **Automated Updates**: Automated compliance rule updates
- **Multi-signature Support**: Enhanced security for sensitive operations
- **Integration Improvements**: Better integration with external systems

## Cross-chain Architecture

### Sentry Role
- Access control enforcement for RWA tokens
- Compliance requirement management
- Whitelist and country list management
- Transfer validation and enforcement

### State Management
- Whitelist state management
- Country list state management
- Compliance switch management
- Token admin management

### Integration Management
- CTMRWA1 token integration
- CTMRWA1X cross-chain integration
- Sentry manager integration
- Map contract integration

## Gas Optimization

- **Efficient Storage**: Optimized storage layout for gas efficiency
- **Batch Operations**: Batch operations to reduce gas costs
- **Event Optimization**: Efficient event emission
- **Function Optimization**: Optimized function implementations
- **State Optimization**: Efficient state management

## Security Considerations

- **Access Control**: Multi-layer access control system
- **Whitelist Security**: Secure whitelist management
- **State Security**: Secure state management
- **Input Validation**: Comprehensive input validation
- **Version Control**: Version compatibility checking
- **Admin Security**: Secure admin function access
- **Integration Security**: Secure contract integration