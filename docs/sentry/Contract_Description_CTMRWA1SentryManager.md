# CTMRWA1SentryManager Contract Documentation

## Overview

**Contract Name:** CTMRWA1SentryManager  
**Author:** @Selqui ContinuumDAO  
**License:** BSL-1.1  
**Solidity Version:** 0.8.27

The CTMRWA1SentryManager contract manages the cross-chain synchronization of all controlled access functionality for RWAs. It controls whitelists of addresses allowed to trade, adding requirements for KYC, KYB, age verification, accredited investor status, and geo-fencing.

This contract is deployed only once on each chain and manages all CTMRWA1Sentry contract deployments and functions. It integrates with C3Caller for cross-chain communication and provides comprehensive security policy management across multiple chains.

## Key Features

- **Cross-chain Security Management:** Synchronizes security policies across all chains
- **Comprehensive Access Control:** Manages whitelists, KYC, KYB, age, and geographic restrictions
- **zkMe Integration:** Configures zkMe KYC service parameters
- **Governance Control:** Governance can update contract addresses and configurations
- **Upgradeable:** Uses UUPS upgradeable pattern for future improvements
- **Fee Management:** Integrated fee system for cross-chain operations
- **C3Caller Integration:** Uses C3Caller for cross-chain communication
- **TokenAdmin Authorization:** Validates tokenAdmin permissions for operations

## Public Variables

### Contract Addresses
- **`ctmRwaDeployer`** (address): Address of the CTMRWADeployer contract
- **`ctmRwaMap`** (address): Address of the CTMRWAMap contract
- **`utilsAddr`** (address): Address of the CTMRWA1SentryUtils contract
- **`gateway`** (address): Address of the CTMRWAGateway contract
- **`feeManager`** (address): Address of the FeeManager contract
- **`identity`** (address): Address of the CTMRWA1Identity contract

### Contract Identification
- **`RWA_TYPE`** (uint256, constant): RWA type defining CTMRWA1 (1)
- **`VERSION`** (uint256, constant): Version of this RWA type (1)

### Configuration
- **`cIdStr`** (string): String representation of this chainID

## Core Functions

### Initialization

#### `initialize(address _gov, address _c3callerProxy, address _txSender, uint256 _dappID, address _ctmRwaDeployer, address _gateway, address _feeManager)`
- **Access:** Public initializer
- **Purpose:** Initializes the CTMRWA1SentryManager contract instance
- **Parameters:**
  - `_gov`: Governance address
  - `_c3callerProxy`: C3Caller proxy address
  - `_txSender`: Transaction sender address
  - `_dappID`: DApp ID for C3Caller integration
  - `_ctmRwaDeployer`: CTMRWADeployer contract address
  - `_gateway`: CTMRWAGateway contract address
  - `_feeManager`: FeeManager contract address
- **Initialization:**
  - Initializes C3GovernDapp with governance parameters
  - Sets contract addresses
  - Sets chain ID string representation

### Upgrade Management

#### `_authorizeUpgrade(address newImplementation)`
- **Access:** Internal function, only callable by governance
- **Purpose:** Authorizes contract upgrades
- **Parameters:** `newImplementation` - Address of new implementation
- **Security:** Only governance can authorize upgrades

### Governance Functions

#### `setGateway(address _gateway)`
- **Access:** Only callable by governance
- **Purpose:** Change to a new CTMRWAGateway contract
- **Parameters:** `_gateway` - Address of new gateway contract

#### `setFeeManager(address _feeManager)`
- **Access:** Only callable by governance
- **Purpose:** Change to a new FeeManager contract
- **Parameters:** `_feeManager` - Address of new fee manager contract

#### `setCtmRwaDeployer(address _deployer)`
- **Access:** Only callable by governance
- **Purpose:** Change to new CTMRWADeployer contract
- **Parameters:** `_deployer` - Address of new deployer contract

#### `setCtmRwaMap(address _map)`
- **Access:** Only callable by governance
- **Purpose:** Change to a new CTMRWAMap contract
- **Parameters:** `_map` - Address of new map contract

#### `setSentryUtils(address _utilsAddr)`
- **Access:** Only callable by governance
- **Purpose:** Change to a new CTMRWA1SentryUtils contract
- **Parameters:** `_utilsAddr` - Address of new utils contract

#### `setIdentity(address _id, address _zkMeVerifierAddr)`
- **Access:** Only callable by governance
- **Purpose:** Switch to a new CTMRWA1Identity contract
- **Parameters:**
  - `_id`: New identity contract address
  - `_zkMeVerifierAddr`: zkMe verifier address
- **Validation:** Ensures identity address is not zero
- **Logic:** Sets identity address and configures zkMe verifier

### Deployment Functions

#### `deploySentry(uint256 _ID, address _tokenAddr, uint256 _rwaType, uint256 _version, address _map)`
- **Access:** Only callable by CTMRWADeployer
- **Purpose:** Deploy a CTMRWA1Sentry contract
- **Parameters:**
  - `_ID`: ID of the RWA token
  - `_tokenAddr`: Address of the CTMRWA1 contract
  - `_rwaType`: Type of RWA (1 for CTMRWA1)
  - `_version`: Version of RWA (1 for current)
  - `_map`: Address of the CTMRWAMap contract
- **Logic:** Calls CTMRWA1SentryUtils to deploy sentry contract
- **Returns:** Address of the deployed CTMRWA1Sentry contract

### Sentry Configuration

#### `setSentryOptions(uint256 _ID, bool _whitelist, bool _kyc, bool _kyb, bool _over18, bool _accredited, bool _countryWL, bool _countryBL, string[] memory _chainIdsStr, string memory _feeTokenStr)`
- **Access:** Public function with tokenAdmin validation
- **Purpose:** Set sentry options across multiple chains
- **Parameters:**
  - `_ID`: ID of the RWA token
  - `_whitelist`: Enable whitelist switch
  - `_kyc`: Enable KYC switch
  - `_kyb`: Enable KYB switch (requires KYC)
  - `_over18`: Enable age 18+ switch (requires KYC)
  - `_accredited`: Enable accredited investor switch (requires KYC)
  - `_countryWL`: Enable country whitelist (requires KYC)
  - `_countryBL`: Enable country blacklist (requires KYC)
  - `_chainIdsStr`: Array of destination chain IDs
  - `_feeTokenStr`: Fee token for payment
- **Validation:**
  - Ensures tokenAdmin authorization
  - Validates sentry contract exists
  - Checks options not already set
  - Validates KYC dependencies
  - Prevents conflicting country lists
- **Logic:**
  - Pays cross-chain fee
  - Sets options on local chain
  - Makes cross-chain calls to other chains
- **Note:** Can only be called once per RWA token

#### `setSentryOptionsX(uint256 _ID, bool _whitelist, bool _kyc, bool _kyb, bool _over18, bool _accredited, bool _countryWL, bool _countryBL)`
- **Access:** Only callable by C3Caller
- **Purpose:** Set sentry options on destination chain
- **Parameters:** Same as setSentryOptions (without chain and fee parameters)
- **Logic:** Calls local sentry contract to set options
- **Returns:** True if successful
- **Events:** Emits SentryOptionsSet event

### zkMe Configuration

#### `setZkMeParams(uint256 _ID, string memory _appId, string memory _programNo, address _cooperator)`
- **Access:** Public function with tokenAdmin validation
- **Purpose:** Set zkMe KYC service parameters
- **Parameters:**
  - `_ID`: ID of the RWA token
  - `_appId`: zkMe appId from dashboard
  - `_programNo`: zkMe program number for Schema
  - `_cooperator`: zkMe verifier contract address
- **Validation:**
  - Ensures identity contract is set
  - Validates tokenAdmin authorization
  - Ensures KYC is enabled
- **Logic:** Calls sentry contract to set zkMe parameters
- **Reference:** See https://dashboard.zk.me for details

### Public Trading

#### `goPublic(uint256 _ID, string[] memory _chainIdsStr, string memory _feeTokenStr)`
- **Access:** Public function with tokenAdmin validation
- **Purpose:** Remove accredited investor restriction
- **Parameters:**
  - `_ID`: ID of the RWA token
  - `_chainIdsStr`: Array of destination chain IDs
  - `_feeTokenStr`: Fee token for payment
- **Validation:**
  - Ensures tokenAdmin authorization
  - Validates KYC and accredited switches are enabled
- **Logic:**
  - Pays cross-chain fee
  - Updates options on all chains to disable accredited requirement
  - Maintains other KYC requirements
- **Note:** No effect if zkMe is KYC provider (information only)

### Whitelist Management

#### `addWhitelist(uint256 _ID, string[] memory _wallets, bool[] memory _choices, string[] memory _chainIdsStr, string memory _feeTokenStr)`
- **Access:** Public function with tokenAdmin validation
- **Purpose:** Maintain whitelist across multiple chains
- **Parameters:**
  - `_ID`: ID of the RWA token
  - `_wallets`: Array of wallet addresses as strings
  - `_choices`: Array of boolean choices for each wallet
  - `_chainIdsStr`: Array of destination chain IDs
  - `_feeTokenStr`: Fee token for payment
- **Validation:**
  - Ensures arrays have same length
  - Validates tokenAdmin authorization
  - Ensures whitelist switch is enabled
- **Logic:**
  - Pays fee (different fee for KYC operations)
  - Updates whitelist on local chain
  - Makes cross-chain calls to other chains
- **Note:** Can only be called if whitelist switch is enabled

#### `setWhitelistX(uint256 _ID, string[] memory _wallets, bool[] memory _choices)`
- **Access:** Only callable by C3Caller
- **Purpose:** Set whitelist on destination chain
- **Parameters:**
  - `_ID`: ID of the RWA token
  - `_wallets`: Array of wallet addresses
  - `_choices`: Array of boolean choices
- **Logic:** Calls local sentry contract to update whitelist
- **Returns:** True if successful
- **Events:** Emits WhitelistAdded event

### Country List Management

#### `addCountrylist(uint256 _ID, string[] memory _countries, bool[] memory _choices, string[] memory _chainIdsStr, string memory _feeTokenStr)`
- **Access:** Public function with tokenAdmin validation
- **Purpose:** Maintain country whitelist or blacklist
- **Parameters:**
  - `_ID`: ID of the RWA token
  - `_countries`: Array of ISO3166 2-letter country codes
  - `_choices`: Array of boolean choices for each country
  - `_chainIdsStr`: Array of destination chain IDs
  - `_feeTokenStr`: Fee token for payment
- **Validation:**
  - Ensures arrays have same length
  - Validates tokenAdmin authorization
  - Ensures country WL or BL switch is enabled
  - Validates country codes are 2 characters
- **Logic:**
  - Pays cross-chain fee
  - Updates country list on local chain
  - Makes cross-chain calls to other chains
- **Note:** Can only be called if KYC and country switches are enabled

#### `setCountryListX(uint256 _ID, string[] memory _countries, bool[] memory _choices)`
- **Access:** Only callable by C3Caller
- **Purpose:** Set country list on destination chain
- **Parameters:**
  - `_ID`: ID of the RWA token
  - `_countries`: Array of country codes
  - `_choices`: Array of boolean choices
- **Logic:** Calls local sentry contract to update country list
- **Returns:** True if successful
- **Events:** Emits CountryListAdded event

## Internal Functions

### Fee Management
- **`_payFee(uint256 _feeWei, string memory _feeTokenStr)`**: Pays fees for operations
  - Transfers fee tokens from caller to contract
  - Approves and pays fee to FeeManager
  - Returns true if successful

- **`_getFee(FeeType _feeType, uint256 _nItems, string[] memory _toChainIdsStr, string memory _feeTokenStr)`**: Calculates fees
  - Gets base fee from FeeManager
  - Multiplies by number of items
  - Returns total fee amount

### Utility Functions
- **`getLastReason()`**: Returns latest revert reason from cross-chain failures
- **`_getTokenAddr(uint256 _ID)`**: Gets CTMRWA1 contract address for RWA ID
- **`_getSentryAddr(uint256 _ID)`**: Gets CTMRWA1Sentry contract address for RWA ID
- **`_getSentry(string memory _toChainIdStr)`**: Gets sentry manager address on destination chain
- **`_checkTokenAdmin(address _tokenAddr)`**: Validates tokenAdmin authorization

### C3Caller Integration
- **`_c3Fallback(bytes4 _selector, bytes calldata _data, bytes calldata _reason)`**: C3Caller fallback function
  - Handles cross-chain call failures
  - Delegates to CTMRWA1SentryUtils for processing
  - Returns success status

## Access Control Modifiers

- **`onlyDeployer`**: Restricts access to only CTMRWADeployer
  - Ensures only authorized deployer can create sentry contracts
  - Maintains deployment security and control

- **`onlyCaller`**: Restricts access to only C3Caller (inherited from C3GovernDapp)
  - Ensures only C3Caller can execute cross-chain functions
  - Maintains cross-chain security

- **`onlyGov`**: Restricts access to only governance (inherited from C3GovernDapp)
  - Ensures only governance can perform administrative functions
  - Maintains system control

## Events

- **`SettingSentryOptions(uint256 ID, string toChainIdStr)`**: Emitted when setting sentry options on destination chain
- **`SentryOptionsSet(uint256 ID)`**: Emitted when sentry options are set on local chain
- **`AddingWhitelist(uint256 ID, string toChainIdStr)`**: Emitted when adding whitelist to destination chain
- **`WhitelistAdded(uint256 ID)`**: Emitted when whitelist is added on local chain
- **`AddingCountryList(uint256 ID, string toChainIdStr)`**: Emitted when adding country list to destination chain
- **`CountryListAdded(uint256 ID)`**: Emitted when country list is added on local chain

## Security Features

1. **Access Control:** Multiple levels of access control for different operations
2. **TokenAdmin Validation:** Validates tokenAdmin authorization for operations
3. **Cross-chain Security:** Secure cross-chain communication via C3Caller
4. **Configuration Validation:** Validates sentry options and dependencies
5. **Fee Integration:** Integrated fee system for cross-chain operations
6. **Upgradeable:** Uses UUPS pattern for secure upgrades
7. **Governance Control:** Governance can update contract addresses
8. **Fallback Handling:** Handles cross-chain call failures gracefully

## Integration Points

- **CTMRWA1Sentry**: Individual sentry contracts for each RWA
- **CTMRWA1SentryUtils**: Utility contract for deployment and fallback handling
- **CTMRWAGateway**: Gateway for cross-chain address resolution
- **CTMRWAMap**: Contract address registry
- **CTMRWA1Identity**: Identity verification contract
- **FeeManager**: Fee calculation and payment management
- **C3Caller**: Cross-chain communication system
- **CTMRWADeployer**: Deployment coordinator

## Error Handling

The contract uses custom error types for efficient gas usage:

- **`CTMRWA1SentryManager_OnlyAuthorized(CTMRWAErrorParam.Sender, CTMRWAErrorParam.Deployer)`**: Thrown when unauthorized address tries to deploy sentry
- **`CTMRWA1SentryManager_OnlyAuthorized(CTMRWAErrorParam.Sender, CTMRWAErrorParam.TokenAdmin)`**: Thrown when unauthorized address tries to perform admin functions
- **`CTMRWA1SentryManager_IsZeroAddress(CTMRWAErrorParam.Identity)`**: Thrown when identity address is zero
- **`CTMRWA1SentryManager_InvalidContract(CTMRWAErrorParam.Token)`**: Thrown when token contract not found
- **`CTMRWA1SentryManager_InvalidContract(CTMRWAErrorParam.Sentry)`**: Thrown when sentry contract not found
- **`CTMRWA1SentryManager_InvalidContract(CTMRWAErrorParam.SentryManager)`**: Thrown when sentry manager not found
- **`CTMRWA1SentryManager_OptionsAlreadySet()`**: Thrown when sentry options already set
- **`CTMRWA1SentryManager_InvalidList(CTMRWAErrorParam.WL_KYC_Disabled)`**: Thrown when whitelist enabled without KYC
- **`CTMRWA1SentryManager_NoKYC()`**: Thrown when KYC is not enabled
- **`CTMRWA1SentryManager_InvalidList(CTMRWAErrorParam.WL_BL_Defined)`**: Thrown when both country WL and BL are set
- **`CTMRWA1SentryManager_LengthMismatch(CTMRWAErrorParam.Input)`**: Thrown when array lengths don't match
- **`CTMRWA1SentryManager_InvalidList(CTMRWAErrorParam.WL_Disabled)`**: Thrown when whitelist is disabled
- **`CTMRWA1SentryManager_InvalidList(CTMRWAErrorParam.WL_BL_Undefined)`**: Thrown when country switches are disabled
- **`CTMRWA1SentryManager_InvalidLength(CTMRWAErrorParam.CountryCode)`**: Thrown when country code is invalid length
- **`CTMRWA1SentryManager_SameChain()`**: Thrown when trying to call same chain
- **`CTMRWA1SentryManager_KYCDisabled()`**: Thrown when KYC is disabled
- **`CTMRWA1SentryManager_AccreditationDisabled()`**: Thrown when accreditation is disabled

## Cross-chain Security Process

### 1. Local Configuration
- **Step:** Configure sentry options on local chain
- **Method:** Call setSentryOptions with local chain ID
- **Result:** Options set on local chain

### 2. Cross-chain Propagation
- **Step:** Propagate configuration to other chains
- **Method:** Make C3Caller calls to destination chains
- **Result:** Options synchronized across all chains

### 3. Fee Payment
- **Step:** Pay cross-chain fees
- **Method:** Calculate and pay fees for all destination chains
- **Result:** Fees paid for cross-chain operations

### 4. Validation
- **Step:** Validate configuration on all chains
- **Method:** Check sentry options on each chain
- **Result:** Consistent configuration across all chains

## Use Cases

### Cross-chain Security Management
- **Scenario:** Maintain consistent security across multiple chains
- **Process:** Use setSentryOptions to configure all chains
- **Benefit:** Unified security policy across ecosystem

### KYC Integration
- **Scenario:** Integrate zkMe KYC for cross-chain verification
- **Process:** Configure zkMe parameters and enable KYC
- **Benefit:** Privacy-preserving KYC across all chains

### Public Trading Transition
- **Scenario:** Transition from accredited-only to public trading
- **Process:** Use goPublic to remove accredited restrictions
- **Benefit:** Regulatory compliance for public trading

### Geographic Compliance
- **Scenario:** Enforce geographic restrictions across chains
- **Process:** Configure country whitelist or blacklist
- **Benefit:** Geographic compliance across all chains

## Best Practices

1. **Configuration Planning:** Plan sentry options before setting them
2. **Cross-chain Coordination:** Coordinate operations across all chains
3. **Fee Management:** Ensure sufficient fee token balance
4. **TokenAdmin Security:** Secure tokenAdmin private keys
5. **Governance Control:** Use governance for contract updates

## Limitations

- **Single Instance:** Only one SentryManager per chain
- **One-time Configuration:** Sentry options can only be set once
- **Chain Addition:** No new chains can be added after configuration
- **KYC Dependencies:** Some switches require KYC to be enabled
- **Cross-chain Dependency:** Requires C3Caller for cross-chain operations

## Future Enhancements

Potential improvements to the sentry management system:

1. **Dynamic Configuration:** Allow configuration updates after initial setup
2. **Enhanced Analytics:** Add security analytics and reporting
3. **Multi-provider Support:** Extend to support additional KYC providers
4. **Automated Compliance:** Implement automated compliance validation
5. **Enhanced Geo-fencing:** Add more sophisticated geographic controls

## Cross-chain Architecture

### Security Synchronization
- **Centralized Management:** Single point of control for security policies
- **Distributed Enforcement:** Policies enforced on each chain
- **Synchronized Updates:** Updates propagated across all chains
- **Consistent Validation:** Consistent validation across all chains

### Communication Flow
- **Local Operations:** Direct calls to local sentry contracts
- **Cross-chain Operations:** C3Caller-mediated calls to remote chains
- **Fee Management:** Fee calculation and payment for cross-chain operations
- **Fallback Handling:** Graceful handling of cross-chain failures

## Gas Optimization

### Cross-chain Costs
- **Local Operations:** ~50000-100000 gas for local sentry operations
- **Cross-chain Calls:** ~100000-200000 gas per destination chain
- **Fee Payment:** Variable based on fee amount and number of chains
- **Total Estimate:** ~150000-500000 gas per cross-chain operation

### Optimization Strategies
- **Batch Operations:** Consider batch operations for efficiency
- **Fee Optimization:** Optimize fee payment mechanisms
- **Gas Estimation:** Always estimate gas before operations
- **Network Selection:** Choose appropriate networks for operations

## Security Considerations

### Access Control
- **TokenAdmin Authorization:** Only tokenAdmin can configure security policies
- **Governance Control:** Only governance can update contract addresses
- **Cross-chain Security:** Secure cross-chain communication via C3Caller
- **Function Validation:** Validate all function parameters

### Configuration Security
- **One-time Setup:** Sentry options can only be set once
- **Dependency Validation:** Enforce proper switch dependencies
- **Cross-chain Consistency:** Ensure consistent configuration across chains
- **Parameter Validation:** Validate all configuration parameters

### Cross-chain Security
- **C3Caller Integration:** Secure cross-chain communication
- **Fallback Handling:** Graceful handling of cross-chain failures
- **Address Resolution:** Secure address resolution via gateway
- **Fee Security:** Secure fee payment and management
