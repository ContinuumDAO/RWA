# CTMRWA1Sentry Contract Description

## Overview

**Contract Name:** CTMRWA1Sentry  
**File:** `src/sentry/CTMRWA1Sentry.sol`  
**License:** BSL-1.1  
**Author:** @Selqui ContinuumDAO  
**Type:** Implementation Contract  

## Contract Description

CTMRWA1Sentry is an access control contract for Real-World Asset (RWA) tokens that manages whitelisting, KYC/KYB requirements, and compliance checks. It acts as a gatekeeper for CTMRWA1 tokens, ensuring that only authorized users can hold and interact with the tokens based on configurable compliance rules.

### Key Features
- Whitelist management for token holders
- KYC/KYB compliance checking
- Country-based restrictions
- Accredited investor verification
- Age verification
- Cross-chain access control
- Configurable compliance switches

## State Variables

### Core Addresses
- `tokenAddr` (address): The linked CTMRWA1 contract address
- `sentryManagerAddr` (address): The CTMRWA1SentryManager contract address
- `tokenAdmin` (address): The token administrator (Issuer) address
- `ctmRwa1X` (address): The CTMRWA1X contract address
- `ctmRwa1Map` (address): The CTMRWAMap contract address
- `cooperator` (address): Cooperating entity address

### Identifiers
- `ID` (uint256): Unique identifier matching the linked CTMRWA1
- `RWA_TYPE` (uint256, immutable): RWA type defining CTMRWA1
- `VERSION` (uint256, immutable): Version of this RWA type

### Configuration
- `appId` (string): Application ID (same as Merchant No)
- `programNo` (string): Program number
- `sentryOptionsSet` (bool): Whether sentry options have been configured

### Whitelist Management
- `ctmWhitelist` (string[]): Array of whitelisted wallet addresses
- `whitelistIndx` (mapping): Maps wallet addresses to their indices

### Country Management
- `countryList` (string[]): Array of country codes
- `countryIndx` (mapping): Maps country codes to their indices

### Compliance Switches
- `whitelistSwitch` (bool): Enable/disable whitelist requirement
- `kycSwitch` (bool): Enable/disable KYC requirement
- `kybSwitch` (bool): Enable/disable KYB requirement
- `countryWLSwitch` (bool): Enable/disable country whitelist
- `countryBLSwitch` (bool): Enable/disable country blacklist
- `accreditedSwitch` (bool): Enable/disable accredited investor requirement
- `age18Switch` (bool): Enable/disable age 18+ requirement

## Constructor

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

### Constructor Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `_ID` | `uint256` | Unique identifier matching the linked CTMRWA1 |
| `_tokenAddr` | `address` | The CTMRWA1 contract address |
| `_rwaType` | `uint256` | RWA type defining CTMRWA1 |
| `_version` | `uint256` | Version of this RWA type |
| `_sentryManager` | `address` | The CTMRWA1SentryManager contract address |
| `_map` | `address` | The CTMRWAMap contract address |

### Constructor Behavior

During construction, the contract:
1. Sets the ID, RWA_TYPE, and VERSION
2. Sets the ctmRwa1Map address
3. Sets the tokenAddr and retrieves tokenAdmin and ctmRwa1X from the CTMRWA1 contract
4. Sets the sentryManagerAddr
5. Initializes the whitelist with a placeholder and the tokenAdmin
6. Initializes the country list with "NOGO"

## Administrative Functions

### setTokenAdmin()
```solidity
function setTokenAdmin(address _tokenAdmin) external onlyTokenAdmin returns (bool)
```
**Description:** Sets a new tokenAdmin address.  
**Parameters:**
- `_tokenAdmin` (address): New tokenAdmin address
**Access:** Only tokenAdmin or CTMRWA1X  
**Returns:** True if successful  
**Effects:** Updates tokenAdmin and manages whitelist  

### setSentryOptions()
```solidity
function setSentryOptions(
    bool _whitelistSwitch,
    bool _kycSwitch,
    bool _kybSwitch,
    bool _countryWLSwitch,
    bool _countryBLSwitch,
    bool _accreditedSwitch,
    bool _age18Switch
) external onlyTokenAdmin
```
**Description:** Sets all compliance switches for the sentry.  
**Parameters:**
- `_whitelistSwitch` (bool): Enable/disable whitelist requirement
- `_kycSwitch` (bool): Enable/disable KYC requirement
- `_kybSwitch` (bool): Enable/disable KYB requirement
- `_countryWLSwitch` (bool): Enable/disable country whitelist
- `_countryBLSwitch` (bool): Enable/disable country blacklist
- `_accreditedSwitch` (bool): Enable/disable accredited investor requirement
- `_age18Switch` (bool): Enable/disable age 18+ requirement
**Access:** Only tokenAdmin  
**Effects:** Updates all compliance switches  

### setAppId()
```solidity
function setAppId(string memory _appId) external onlyTokenAdmin
```
**Description:** Sets the application ID.  
**Parameters:**
- `_appId` (string): New application ID
**Access:** Only tokenAdmin  
**Effects:** Updates appId  

### setProgramNo()
```solidity
function setProgramNo(string memory _programNo) external onlyTokenAdmin
```
**Description:** Sets the program number.  
**Parameters:**
- `_programNo` (string): New program number
**Access:** Only tokenAdmin  
**Effects:** Updates programNo  

### setCooperator()
```solidity
function setCooperator(address _cooperator) external onlyTokenAdmin
```
**Description:** Sets the cooperating entity address.  
**Parameters:**
- `_cooperator` (address): New cooperator address
**Access:** Only tokenAdmin  
**Effects:** Updates cooperator address  

## Whitelist Management Functions

### addToWhitelist()
```solidity
function addToWhitelist(string[] memory _addresses, bool[] memory _statuses) external onlyTokenAdmin
```
**Description:** Adds addresses to the whitelist with their status.  
**Parameters:**
- `_addresses` (string[]): Array of addresses to add
- `_statuses` (bool[]): Array of status values for each address
**Access:** Only tokenAdmin  
**Effects:** Updates whitelist with new addresses  

### removeFromWhitelist()
```solidity
function removeFromWhitelist(string[] memory _addresses) external onlyTokenAdmin
```
**Description:** Removes addresses from the whitelist.  
**Parameters:**
- `_addresses` (string[]): Array of addresses to remove
**Access:** Only tokenAdmin  
**Effects:** Removes addresses from whitelist  

### setWhitelist()
```solidity
function setWhitelist(string[] memory _addresses, bool[] memory _statuses) external onlySentryManager
```
**Description:** Sets the whitelist from the sentry manager.  
**Parameters:**
- `_addresses` (string[]): Array of addresses
- `_statuses` (bool[]): Array of status values
**Access:** Only sentryManager  
**Effects:** Updates whitelist  

## Country Management Functions

### addCountries()
```solidity
function addCountries(string[] memory _countries, bool[] memory _statuses) external onlyTokenAdmin
```
**Description:** Adds countries to the country list with their status.  
**Parameters:**
- `_countries` (string[]): Array of country codes
- `_statuses` (bool[]): Array of status values for each country
**Access:** Only tokenAdmin  
**Effects:** Updates country list  

### removeCountries()
```solidity
function removeCountries(string[] memory _countries) external onlyTokenAdmin
```
**Description:** Removes countries from the country list.  
**Parameters:**
- `_countries` (string[]): Array of country codes to remove
**Access:** Only tokenAdmin  
**Effects:** Removes countries from country list  

## Verification Functions

### checkWhitelist()
```solidity
function checkWhitelist(address _address) external view returns (bool)
```
**Description:** Checks if an address is whitelisted.  
**Parameters:**
- `_address` (address): Address to check
**Returns:** True if address is whitelisted  

### checkCountry()
```solidity
function checkCountry(string memory _country) external view returns (bool)
```
**Description:** Checks if a country is allowed based on whitelist/blacklist settings.  
**Parameters:**
- `_country` (string): Country code to check
**Returns:** True if country is allowed  

### checkCompliance()
```solidity
function checkCompliance(
    address _address,
    string memory _country,
    bool _kycVerified,
    bool _kybVerified,
    bool _accredited,
    bool _age18
) external view returns (bool)
```
**Description:** Performs comprehensive compliance checking.  
**Parameters:**
- `_address` (address): Address to check
- `_country` (string): Country code
- `_kycVerified` (bool): KYC verification status
- `_kybVerified` (bool): KYB verification status
- `_accredited` (bool): Accredited investor status
- `_age18` (bool): Age 18+ status
**Returns:** True if all compliance checks pass  

## Query Functions

### getWhitelist()
```solidity
function getWhitelist() external view returns (string[] memory)
```
**Description:** Returns the complete whitelist.  
**Returns:** Array of whitelisted addresses  

### getCountryList()
```solidity
function getCountryList() external view returns (string[] memory)
```
**Description:** Returns the complete country list.  
**Returns:** Array of country codes  

### getSentryOptions()
```solidity
function getSentryOptions() external view returns (bool, bool, bool, bool, bool, bool, bool)
```
**Description:** Returns all compliance switches.  
**Returns:** Tuple of all switch values  

### getAppId()
```solidity
function getAppId() external view returns (string memory)
```
**Description:** Returns the application ID.  
**Returns:** Application ID string  

### getProgramNo()
```solidity
function getProgramNo() external view returns (string memory)
```
**Description:** Returns the program number.  
**Returns:** Program number string  

### getCooperator()
```solidity
function getCooperator() external view returns (address)
```
**Description:** Returns the cooperating entity address.  
**Returns:** Cooperator address  

## Access Control Modifiers

- `onlyTokenAdmin`: Restricts access to tokenAdmin or CTMRWA1X
- `onlySentryManager`: Restricts access to sentryManager

## Events

The contract emits various events for:
- Whitelist changes
- Country list changes
- Configuration updates
- Compliance checks

## Security Features

- **Access Control**: Role-based permissions
- **Whitelist Management**: Comprehensive address filtering
- **Country Restrictions**: Geographic compliance controls
- **Cross-chain Integration**: Secure multi-chain operations
- **Configurable Compliance**: Flexible rule enforcement

## Integration Points

- **CTMRWA1**: Linked token contract
- **CTMRWA1SentryManager**: Centralized sentry management
- **CTMRWA1X**: Cross-chain operations
- **CTMRWAMap**: Component address mapping
- **Identity contracts**: KYC/KYB verification

## Compliance Flow

1. **TokenAdmin** configures compliance switches
2. **TokenAdmin** sets up whitelist and country restrictions
3. **Users** attempt to interact with CTMRWA1 tokens
4. **CTMRWA1Sentry** performs compliance checks
5. **Access** is granted or denied based on compliance rules

## Key Features

- **Flexible Compliance**: Configurable switches for different requirements
- **Whitelist Management**: Granular address-based access control
- **Geographic Restrictions**: Country-based compliance
- **Cross-chain Support**: Consistent compliance across chains
- **Identity Integration**: KYC/KYB verification support
- **Accredited Investor**: Support for accredited investor requirements
