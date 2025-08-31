# CTMRWA1Sentry Contract Documentation

## Overview

**Contract Name:** CTMRWA1Sentry  
**Author:** @Selqui ContinuumDAO  
**License:** BSL-1.1  
**Solidity Version:** 0.8.27

The CTMRWA1Sentry contract acts as a security sentry for CTMRWA1 tokens, managing access control, whitelisting, and compliance features. It enforces various security switches including whitelist controls, KYC/KYB requirements, country restrictions, and age verification.

This contract is deployed once for every CTMRWA1 contract and holds the whitelist state for that specific RWA token. It integrates with CTMRWA1SentryManager for cross-chain coordination and works with zkMe for KYC verification.

## Key Features

- **Access Control:** Manages whitelist of permitted wallet addresses
- **Compliance Switches:** Configurable KYC, KYB, country, and age verification
- **zkMe Integration:** Stores zkMe KYC service parameters
- **Cross-chain Coordination:** Works with SentryManager for multi-chain operations
- **TokenAdmin Management:** Handles tokenAdmin updates and protection
- **Country Restrictions:** Supports country whitelist and blacklist
- **Transfer Validation:** Validates transfers before they occur
- **Security Enforcement:** Enforces various security policies

## Public Variables

### Contract Identification
- **`tokenAddr`** (address): Address of the CTMRWA1 contract
- **`ID`** (uint256): ID of the RWA token
- **`RWA_TYPE`** (uint256, immutable): RWA type defining CTMRWA1
- **`VERSION`** (uint256, immutable): Version of this RWA type

### Contract Addresses
- **`sentryManagerAddr`** (address): Address of the CTMRWA1SentryManager contract
- **`tokenAdmin`** (address): TokenAdmin address (same as in CTMRWA1)
- **`ctmRwa1X`** (address): Address of the CTMRWA1X contract
- **`ctmRwa1Map`** (address): CTMRWAMap contract address

### zkMe Configuration
- **`appId`** (string): zkMe KYC service appId (same as Merchant No)
- **`programNo`** (string): zkMe KYC service programNo
- **`cooperator`** (address): zkMe KYC service cooperator address

### Configuration Status
- **`sentryOptionsSet`** (bool): Whether sentry options have been configured

### Whitelist Management
- **`ctmWhitelist`** (string[]): Array of whitelisted wallet addresses
- **`whitelistIndx`** (mapping(string => uint256), private): Index mapping for whitelist addresses

### Country Management
- **`countryList`** (string[]): Array of countries for KYC restrictions
- **`countryIndx`** (mapping(string => uint256), private): Index mapping for countries

### Security Switches
- **`whitelistSwitch`** (bool): Enable/disable whitelist enforcement
- **`kycSwitch`** (bool): Enable/disable KYC requirements
- **`kybSwitch`** (bool): Enable/disable KYB requirements
- **`countryWLSwitch`** (bool): Enable/disable country whitelist
- **`countryBLSwitch`** (bool): Enable/disable country blacklist
- **`accreditedSwitch`** (bool): Enable/disable accredited investor requirements
- **`age18Switch`** (bool): Enable/disable age 18+ requirements

## Core Functions

### Constructor

#### `constructor(uint256 _ID, address _tokenAddr, uint256 _rwaType, uint256 _version, address _sentryManager, address _map)`
- **Purpose:** Initializes a new CTMRWA1Sentry contract instance
- **Parameters:**
  - `_ID`: ID of the RWA token
  - `_tokenAddr`: Address of the CTMRWA1 contract
  - `_rwaType`: RWA type defining CTMRWA1
  - `_version`: Version of this RWA type
  - `_sentryManager`: Address of the CTMRWA1SentryManager contract
  - `_map`: CTMRWAMap contract address
- **Initialization:**
  - Sets contract identification parameters
  - Retrieves tokenAdmin and ctmRwa1X from CTMRWA1
  - Sets sentry manager address
  - Initializes whitelist with "no go" address and tokenAdmin
  - Initializes country list with "NOGO" entry

### Administrative Functions

#### `setTokenAdmin(address _tokenAdmin)`
- **Access:** Only callable by current tokenAdmin or CTMRWA1X
- **Purpose:** Set a new tokenAdmin address
- **Parameters:** `_tokenAdmin` - New tokenAdmin address
- **Logic:**
  - Updates tokenAdmin address
  - Adds new tokenAdmin to whitelist if not zero address
  - Prevents leaving stranded tokens by old tokenAdmin
- **Returns:** True if successful
- **Use Case:** Called by CTMRWA1X for cross-chain tokenAdmin updates

#### `setZkMeParams(string memory _appId, string memory _programNo, address _cooperator)`
- **Access:** Only callable by SentryManager
- **Purpose:** Set zkMe KYC service parameters
- **Parameters:**
  - `_appId`: zkMe KYC service appId
  - `_programNo`: zkMe KYC service programNo
  - `_cooperator`: zkMe KYC service cooperator address
- **Use Case:** Configure zkMe integration for KYC verification

#### `getZkMeParams()`
- **Purpose:** Retrieve current zkMe KYC service parameters
- **Returns:** Tuple of (appId, programNo, cooperator)
- **Use Case:** Query zkMe configuration for KYC operations

### Sentry Configuration

#### `setSentryOptionsLocal(uint256 _ID, bool _whitelist, bool _kyc, bool _kyb, bool _over18, bool _accredited, bool _countryWL, bool _countryBL)`
- **Access:** Only callable by SentryManager
- **Purpose:** Set sentry options on the local chain
- **Parameters:**
  - `_ID`: ID of the RWA token (must match contract ID)
  - `_whitelist`: Enable whitelist switch
  - `_kyc`: Enable KYC switch
  - `_kyb`: Enable KYB switch (requires KYC)
  - `_over18`: Enable age 18+ switch (requires KYC)
  - `_accredited`: Enable accredited investor switch
  - `_countryWL`: Enable country whitelist (requires KYC)
  - `_countryBL`: Enable country blacklist (requires KYC)
- **Validation:** Ensures ID matches contract ID
- **Logic:** Sets switches based on parameters and dependencies
- **Use Case:** Configure security policies for the RWA token

### Whitelist Management

#### `setWhitelistSentry(uint256 _ID, string[] memory _wallets, bool[] memory _choices)`
- **Access:** Only callable by SentryManager
- **Purpose:** Set whitelist status for multiple wallets
- **Parameters:**
  - `_ID`: ID of the RWA token (must match contract ID)
  - `_wallets`: Array of wallet addresses as strings
  - `_choices`: Array of boolean choices for each wallet
- **Validation:** Ensures ID matches contract ID
- **Logic:** Calls internal _setWhitelist function
- **Use Case:** Update whitelist across multiple wallets

#### `_setWhitelist(string[] memory _wallets, bool[] memory _choices)`
- **Access:** Internal function
- **Purpose:** Internal whitelist management logic
- **Logic:**
  - Processes each wallet in the array
  - Prevents removal of tokenAdmin from whitelist
  - Handles addition and removal of wallet addresses
  - Maintains index mapping for efficient lookups
  - Optimizes array operations for gas efficiency

### Country List Management

#### `setCountryListLocal(uint256 _ID, string[] memory _countryList, bool[] memory _choices)`
- **Access:** Only callable by SentryManager
- **Purpose:** Set country whitelist or blacklist
- **Parameters:**
  - `_ID`: ID of the RWA token (must match contract ID)
  - `_countryList`: Array of country codes
  - `_choices`: Array of boolean choices for each country
- **Validation:** Ensures ID matches contract ID
- **Logic:** Calls internal _setCountryList function
- **Use Case:** Update country restrictions

#### `_setCountryList(string[] memory _countries, bool[] memory _choices)`
- **Access:** Internal function
- **Purpose:** Internal country list management logic
- **Logic:**
  - Processes each country in the array
  - Handles addition and removal of countries
  - Maintains index mapping for efficient lookups
  - Optimizes array operations for gas efficiency

### Transfer Validation

#### `isAllowableTransfer(string memory _user)`
- **Purpose:** Check if an address is allowed to receive value
- **Parameters:** `_user` - Address as string to check
- **Logic:**
  - Checks if whitelist is enabled
  - Allows zero address transfers
  - Allows dividend and investment contract transfers
  - Checks whitelist status for other addresses
- **Returns:** True if transfer is allowed, false otherwise
- **Use Case:** Called by CTMRWA1 before transfers

### Query Functions

#### `getWhitelistLength()`
- **Purpose:** Get number of whitelisted wallet addresses
- **Returns:** Length of whitelist (excluding unused first entry)
- **Use Case:** Query whitelist size

#### `getWhitelistAddressAtIndx(uint256 _indx)`
- **Purpose:** Get whitelist address at specific index
- **Parameters:** `_indx` - Index to query
- **Returns:** Wallet address as string at the index
- **Validation:** Ensures index is within bounds
- **Use Case:** Iterate through whitelist

#### `_isWhitelisted(string memory _walletStr)`
- **Access:** Internal view function
- **Purpose:** Check if wallet is whitelisted
- **Parameters:** `_walletStr` - Wallet address as string
- **Returns:** True if whitelisted, false otherwise
- **Logic:** Checks index mapping for wallet address

## Internal Functions

### Utility Functions
- **`cID()`**: Returns current chain ID
  - Used for chain identification in cross-chain operations

## Access Control Modifiers

- **`onlyTokenAdmin`**: Restricts access to tokenAdmin or CTMRWA1X
  - Ensures only authorized parties can perform admin functions
  - Allows CTMRWA1X to update tokenAdmin across contracts

- **`onlySentryManager`**: Restricts access to only SentryManager
  - Ensures only authorized manager can update sentry configuration
  - Maintains system security and control

## Events

The contract does not emit custom events, as it focuses on state management and validation operations.

## Security Features

1. **Access Control:** Multiple levels of access control for different operations
2. **TokenAdmin Protection:** Prevents removal of tokenAdmin from whitelist
3. **Transfer Validation:** Validates all transfers before execution
4. **Contract Allowance:** Allows dividend and investment contracts to pass validation
5. **Configuration Validation:** Validates sentry options and dependencies
6. **Cross-chain Security:** Secure integration with SentryManager
7. **Index Management:** Efficient whitelist and country list management
8. **Zero Address Handling:** Proper handling of zero address transfers

## Integration Points

- **CTMRWA1**: Core token contract that calls transfer validation
- **CTMRWA1SentryManager**: Manager for cross-chain sentry operations
- **CTMRWAMap**: Contract address registry for dividend and investment contracts
- **CTMRWA1X**: Cross-chain coordination contract for tokenAdmin updates
- **zkMe**: KYC verification service integration
- **CTMRWA1Dividend**: Dividend contract (allowed to pass validation)
- **CTMRWA1Invest**: Investment contract (allowed to pass validation)

## Error Handling

The contract uses custom error types for efficient gas usage:

- **`CTMRWA1Sentry_OnlyAuthorized(CTMRWAErrorParam.Sender, CTMRWAErrorParam.TokenAdmin)`**: Thrown when unauthorized address tries to perform admin functions
- **`CTMRWA1Sentry_OnlyAuthorized(CTMRWAErrorParam.Sender, CTMRWAErrorParam.SentryManager)`**: Thrown when unauthorized address tries to update sentry
- **`CTMRWA1Sentry_InvalidID(uint256 expected, uint256 provided)`**: Thrown when ID doesn't match contract ID
- **`CTMRWA1Sentry_Unauthorized(CTMRWAErrorParam.Wallet, CTMRWAErrorParam.TokenAdmin)`**: Thrown when trying to remove tokenAdmin from whitelist
- **`CTMRWA1Sentry_OutofBounds()`**: Thrown when accessing whitelist with invalid index

## Transfer Validation Process

### 1. Whitelist Check
- **Step:** Check if whitelist is enabled
- **Result:** If disabled, allow all transfers

### 2. Special Address Check
- **Step:** Check if address is zero address
- **Result:** Allow zero address transfers

### 3. Contract Allowance Check
- **Step:** Check if address is dividend or investment contract
- **Result:** Allow contract transfers

### 4. Whitelist Validation
- **Step:** Check if address is in whitelist
- **Result:** Allow only whitelisted addresses

## Use Cases

### Access Control
- **Scenario:** Restrict token transfers to authorized addresses
- **Process:** Enable whitelist, add authorized addresses
- **Benefit:** Prevents unauthorized token transfers

### KYC Compliance
- **Scenario:** Enforce KYC requirements for token holders
- **Process:** Enable KYC switch, integrate with zkMe
- **Benefit:** Regulatory compliance with privacy preservation

### Country Restrictions
- **Scenario:** Restrict token access by country
- **Process:** Enable country whitelist/blacklist, add countries
- **Benefit:** Geographic compliance and restrictions

### Cross-chain Security
- **Scenario:** Maintain consistent security across chains
- **Process:** Use SentryManager for cross-chain coordination
- **Benefit:** Unified security policy across all chains

## Best Practices

1. **Whitelist Management:** Carefully manage whitelist additions and removals
2. **Configuration Planning:** Plan sentry options before enabling
3. **Cross-chain Coordination:** Coordinate sentry configuration across chains
4. **TokenAdmin Protection:** Never remove tokenAdmin from whitelist
5. **Contract Integration:** Ensure dividend and investment contracts are allowed

## Limitations

- **Single Instance:** Only one sentry per RWA per chain
- **SentryManager Dependency:** Requires SentryManager for cross-chain operations
- **Configuration Dependencies:** Some switches require KYC to be enabled
- **Chain Specific:** Each sentry operates on a single chain
- **Index Management:** Whitelist indices may change when addresses are removed

## Future Enhancements

Potential improvements to the sentry system:

1. **Enhanced Compliance:** Add more compliance verification types
2. **Dynamic Policies:** Implement dynamic security policy updates
3. **Analytics Integration:** Add security analytics and reporting
4. **Multi-provider Support:** Extend to support additional KYC providers
5. **Automated Validation:** Implement automated compliance validation

## Whitelist Architecture

### Storage Structure
- **Array Storage:** ctmWhitelist array stores wallet addresses
- **Index Mapping:** whitelistIndx provides O(1) lookup
- **Optimized Operations:** Efficient addition and removal operations
- **TokenAdmin Protection:** Special protection for tokenAdmin address

### Management Operations
- **Addition:** Add new addresses to whitelist
- **Removal:** Remove addresses from whitelist
- **Validation:** Check if address is whitelisted
- **Enumeration:** Iterate through whitelist addresses

## Country List Architecture

### Storage Structure
- **Array Storage:** countryList array stores country codes
- **Index Mapping:** countryIndx provides O(1) lookup
- **Optimized Operations:** Efficient addition and removal operations
- **Flexible Policy:** Support for both whitelist and blacklist

### Management Operations
- **Addition:** Add new countries to list
- **Removal:** Remove countries from list
- **Validation:** Check if country is in list
- **Enumeration:** Iterate through country list

## Security Policy Management

### Switch Dependencies
- **KYC Base:** KYC switch enables other compliance switches
- **KYB Dependency:** KYB requires KYC to be enabled
- **Age Dependency:** Age 18+ requires KYC to be enabled
- **Country Dependency:** Country restrictions require KYC to be enabled

### Policy Enforcement
- **Transfer Validation:** All transfers validated against policies
- **Contract Allowance:** System contracts allowed to pass validation
- **TokenAdmin Protection:** TokenAdmin always allowed
- **Cross-chain Consistency:** Policies synchronized across chains

## Gas Optimization

### Validation Costs
- **Whitelist Check:** ~2600 gas for mapping lookup
- **Contract Check:** ~5000 gas for contract address lookup
- **Transfer Validation:** ~8000-15000 gas per validation
- **Total Estimate:** ~10000-20000 gas per transfer validation

### Optimization Strategies
- **Efficient Storage:** Use mappings for O(1) lookups
- **Batch Operations:** Consider batch whitelist updates
- **Gas Estimation:** Always estimate gas before operations
- **Storage Optimization:** Minimize storage operations

## Security Considerations

### Access Control
- **TokenAdmin Authorization:** Only authorized parties can perform admin functions
- **SentryManager Authorization:** Only SentryManager can update configuration
- **Function Validation:** Validate all function parameters
- **Cross-chain Security:** Secure integration with SentryManager

### Transfer Security
- **Pre-transfer Validation:** Validate transfers before execution
- **Contract Allowance:** Allow system contracts to pass validation
- **TokenAdmin Protection:** Protect tokenAdmin from removal
- **Zero Address Handling:** Proper handling of zero address transfers

### Configuration Security
- **ID Validation:** Validate RWA ID matches contract ID
- **Switch Dependencies:** Enforce proper switch dependencies
- **Parameter Validation:** Validate all configuration parameters
- **Cross-chain Consistency:** Ensure consistent configuration across chains
