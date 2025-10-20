# Contract Description: CTMRWA1SentryManager

## Overview

The `CTMRWA1SentryManager` contract manages the cross-chain synchronization of all controlled access functionality to Real-World Assets (RWAs). This contract controls whitelists of addresses allowed to trade, adding requirements for KYC, KYB, over 18 years, Accredited Investor status, and geo-fencing.

This contract is only deployed ONCE on each chain and manages all CTMRWA1Sentry contract deployments and functions.

## Contract Description

The CTMRWA1SentryManager is a governance-controlled contract that serves as the central management system for RWA token access control across multiple chains. It handles the deployment and configuration of sentry contracts that enforce compliance requirements for RWA token transfers.

## Key Features

- **Cross-chain Access Control**: Manages access control settings across multiple chains
- **KYC/KYB Integration**: Supports Know Your Customer and Know Your Business verification
- **Whitelist Management**: Maintains whitelists of approved addresses
- **Country Restrictions**: Supports country whitelist and blacklist functionality
- **Accredited Investor Controls**: Manages accredited investor requirements
- **Age Verification**: Enforces over-18 age requirements
- **Fee Management**: Integrates with FeeManager for operation costs
- **Cross-chain Synchronization**: Ensures consistent access control across all chains

## Public Variables

### LATEST_VERSION
```solidity
uint256 public LATEST_VERSION
```
The latest version of RWA type

### ctmRwaDeployer
```solidity
address public ctmRwaDeployer
```
The address of the CTMRWADeployer contract

### ctmRwaMap
```solidity
address public ctmRwaMap
```
The address of the CTMRWAMap contract

### utilsAddr
```solidity
address public utilsAddr
```
The address of the CTMRWA1SentryUtils contract (adjunct to this contract)

### RWA_TYPE
```solidity
uint256 public immutable RWA_TYPE = 1
```
rwaType is the RWA type defining CTMRWA1

### gateway
```solidity
address public gateway
```
The address of the CTMRWAGateway contract

### feeManager
```solidity
address public feeManager
```
The address of the FeeManager contract

### identity
```solidity
address public identity
```
The address of the CTMRWA1Identity contract

### cIdStr
```solidity
string cIdStr
```
A string representation of this chainID

## Constructor

### initialize()
```solidity
function initialize(
    address _gov,
    address _c3callerProxy,
    address _txSender,
    uint256 _dappID,
    address _ctmRwaDeployer,
    address _gateway,
    address _feeManager
) external initializer
```
Initialize the contract

**Parameters:**
- `_gov`: The governance address
- `_c3callerProxy`: The C3 caller proxy address
- `_txSender`: The transaction sender address
- `_dappID`: The dApp ID
- `_ctmRwaDeployer`: The CTMRWA deployer address
- `_gateway`: The gateway address
- `_feeManager`: The fee manager address

## Access Control

### onlyDeployer
```solidity
modifier onlyDeployer()
```
Restricts access to the deployer only

## Administrative Functions

### updateLatestVersion()
```solidity
function updateLatestVersion(uint256 _newVersion) external onlyGov
```
Governance can update the latest version

**Parameters:**
- `_newVersion`: The new latest version

### setGateway()
```solidity
function setGateway(address _gateway) external onlyGov
```
Governance can change to a new CTMRWAGateway contract

**Parameters:**
- `_gateway`: address of the new CTMRWAGateway contract

### setFeeManager()
```solidity
function setFeeManager(address _feeManager) external onlyGov
```
Governance can change to a new FeeManager contract

**Parameters:**
- `_feeManager`: address of the new FeeManager contract

### setCtmRwaDeployer()
```solidity
function setCtmRwaDeployer(address _deployer) external onlyGov
```
Governance can change to a new CTMRWADeployer and CTMRWAERC20Deployer contracts

**Parameters:**
- `_deployer`: address of the new CTMRWADeployer contract

### setCtmRwaMap()
```solidity
function setCtmRwaMap(address _map) external onlyGov
```
Governance can change to a new CTMRWAMap contract

**Parameters:**
- `_map`: address of the new CTMRWAMap contract

### setSentryUtils()
```solidity
function setSentryUtils(address _utilsAddr) external onlyGov
```
Governance can change to a new CTMRWA1SentryUtils contract

**Parameters:**
- `_utilsAddr`: address of the new CTMRWA1SentryUtils contract

### setIdentity()
```solidity
function setIdentity(address _id, address _zkMeVerifierAddr) external onlyGov
```
Governance can switch to a new CTMRWA1Identity contract

**Parameters:**
- `_id`: The identity contract address
- `_zkMeVerifierAddr`: The zkMe verifier address

## Deployment Functions

### deploySentry()
```solidity
function deploySentry(
    uint256 _ID,
    address _tokenAddr,
    uint256 _rwaType,
    uint256 _version,
    address _map
) external onlyDeployer returns (address)
```
This function is called by CTMRWADeployer, allowing CTMRWA1SentryUtils to deploy a CTMRWA1Sentry contract with the same ID as for the CTMRWA1 contract

**Parameters:**
- `_ID`: The ID of the RWA token
- `_tokenAddr`: The address of the CTMRWA1 contract
- `_rwaType`: The type of RWA (set to 1 for CTMRWA1)
- `_version`: The version of RWA (set to 1 for current version)
- `_map`: The address of the CTMRWAMap contract

**Returns:** sentryAddr The address of the deployed CTMRWA1Sentry contract

## Sentry Options Management

### setSentryOptions()
```solidity
function setSentryOptions(
    uint256 _ID,
    uint256 _version,
    bool _whitelist,
    bool _kyc,
    bool _kyb,
    bool _over18,
    bool _accredited,
    bool _countryWL,
    bool _countryBL,
    string[] memory _chainIdsStr,
    string memory _feeTokenStr
) public
```
The tokenAdmin (Issuer) can optionally set options to control which wallet addresses can be transferred to using a Whitelist, identical on all chains that the RWA token is deployed to. The tokenAdmin can also require KYC via zkProofs, which then allows a user to add themselves to the Whitelist using the verifyPerson function in CTMRWA1Identity function. Either or both _whitelist and _kyc can be set. The other options can only be set if _kyc is set. These are not required for all zkProof verifiers though, since some control geo-fencing and age criteria themselves (e.g. zkMe). These other options are still useful for on-chain information purposes though.

**Parameters:**
- `_ID`: The ID of the RWA token
- `_version`: The version of the RWA token
- `_whitelist`: A switch which, if set, enables the tokenAdmin to control a Whitelist of wallets that may be sent value
- `_kyc`: A switch which, if set, allows KYC via a zkProof to allow users to add themselves to the Whitelist
- `_kyb`: A switch which, if set, allows a business to undergo KYB via zkProofs. To set this switch, _kyc must also be set
- `_over18`: A switch, if set, only allows those over 18 years of age to trade. To set this switch, _kyc must also be set
- `_accredited`: A switch, if set, only allows Accredited, or Sophisticated Investors to trade. To set this switch, _kyc must also be set
- `_countryWL`: a switch, which if set, allows a tokenAdmin to maintain a Whitelist of countries from which investors are allowed to trade value
- `_countryBL`: a switch, which if set, allows a tokenAdmin to maintain a Blacklist of countries from which investors are allowed to trade value
- `_chainIdsStr`: This is an array of strings of chainIDs to deploy to
- `_feeTokenStr`: This is fee token on the source chain (local chain) that you wish to use to pay for the deployment

**Note:** The function setSentryOptions CAN ONLY BE CALLED ONCE. Once the function setSentryOptions has been called, NO NEW CHAINS CAN BE ADDED TO THIS RWA TOKEN

### setSentryOptionsX()
```solidity
function setSentryOptionsX(
    uint256 _ID,
    uint256 _version,
    bool _whitelist,
    bool _kyc,
    bool _kyb,
    bool _over18,
    bool _accredited,
    bool _countryWL,
    bool _countryBL
) external onlyCaller returns (bool)
```
This is the function called on the destination chain by the setSentryoptions function. See this function for the parameter descriptions. It is an onlyCaller function.

**Parameters:**
- `_ID`: The ID of the RWA token
- `_version`: The version of the RWA token
- `_whitelist`: Whitelist switch
- `_kyc`: KYC switch
- `_kyb`: KYB switch
- `_over18`: Over 18 switch
- `_accredited`: Accredited investor switch
- `_countryWL`: Country whitelist switch
- `_countryBL`: Country blacklist switch

**Returns:** True if the sentry options were set

## KYC Configuration

### setZkMeParams()
```solidity
function setZkMeParams(
    uint256 _ID,
    uint256 _version,
    string memory _appId,
    string memory _programNo,
    address _cooperator
) public
```
This function is used to store important parameters relating to the zKMe zkProof KYC implementation. It can only be called by the tokenAdmin (Issuer). It can only be called if the _kyc switch has been set in setSentryOptions. See https://dashboard.zk.me for details.

**Parameters:**
- `_ID`: The ID of the RWA token
- `_version`: The version of the RWA token
- `_appId`: The appId that the tokenAdmin can generate in the zkMe Dashboard from their apiKey
- `_programNo`: The programNo for the Schema, which details access restrictions (e.g. geo-fencing)
- `_cooperator`: This address is the zkMe verifier contract that allows AssetX to check if a user has undergone KYC AND passes the access restrictions in the Schema (_programNo)

**Note:** The tokenAdmin can change the _programNo if they update the access restrictions, so that all new users undergoing KYC will be subject to these updated restrictions.

### goPublic()
```solidity
function goPublic(
    uint256 _ID,
    uint256 _version,
    string[] memory _chainIdsStr,
    string memory _feeTokenStr
) public
```
This function removes the Accredited flag, _accredited, if KYC is set. It is designed to remove the obstacle of allowing only Accredited Investors to trade the RWA token and typically would be called after a time period had elapsed as determined by a Regulator, so that the token can be publicly traded.

**Parameters:**
- `_ID`: The ID of the RWA token
- `_version`: The version of the RWA token
- `_chainIdsStr`: This is an array of strings of chainIDs to deploy to
- `_feeTokenStr`: This is fee token on the source chain (local chain) that you wish to use to pay for the deployment

**Note:** This function has no effect if zkMe is the KYC provider and is then only for information purposes.

## Whitelist Management

### addWhitelist()
```solidity
function addWhitelist(
    uint256 _ID,
    uint256 _version,
    string[] memory _wallets,
    bool[] memory _choices,
    string[] memory _chainIdsStr,
    string memory _feeTokenStr
) public
```
This function allows the tokenAdmin (Issuer) to maintain a Whitelist of user wallets on all chains that may receive value in the RWA token.

**Parameters:**
- `_ID`: The ID of the RWA token
- `_version`: The version of the RWA token
- `_wallets`: An array of wallets as strings for which the access status is being updated
- `_choices`: An array of switches corresponding to _wallets. If an entry is true, then this wallet address may receive value
- `_chainIdsStr`: This is an array of strings of chainIDs to deploy to
- `_feeTokenStr`: This is fee token on the source chain (local chain) that you wish to use to pay for the deployment

**Note:** This function can only be called if the _whitelist switch has been set in setSentryOptions

### setWhitelistX()
```solidity
function setWhitelistX(
    uint256 _ID,
    uint256 _version,
    string[] memory _wallets,
    bool[] memory _choices
) external onlyCaller returns (bool)
```
This function is only called on the destination chain by addWhitelist. It is an onlyCaller function

**Parameters:**
- `_ID`: The ID of the RWA token
- `_version`: The version of the RWA token
- `_wallets`: The list of wallets to set the state for
- `_choices`: The list of choices for the wallets

**Returns:** success True if the whitelist was set, false otherwise

## Country List Management

### addCountrylist()
```solidity
function addCountrylist(
    uint256 _ID,
    uint256 _version,
    string[] memory _countries,
    bool[] memory _choices,
    string[] memory _chainIdsStr,
    string memory _feeTokenStr
) public
```
This function allows the tokenAdmin to maintain a list of countries from which users are allowed to trade. The list can be either a Country Whitelist OR a Country Blacklist as determined by setSentryOptions

**Parameters:**
- `_ID`: The ID of the RWA token
- `_version`: The version of the RWA token
- `_countries`: Is an array of strings representing the countries whose access is being set here. The strings must each be an ISO3166 2 letter country code
- `_choices`: An array of switches corresponding to the _countries array
- `_chainIdsStr`: This is an array of strings of chainIDs to deploy to
- `_feeTokenStr`: This is fee token on the source chain (local chain) that you wish to use to pay for the deployment

**Note:** This function can only be called if both _kyc and either _countryWL, or _countryBL has been set in setSentryOptions. This function has no effect if zkMe is the KYC provider and is then only for information purposes.

### setCountryListX()
```solidity
function setCountryListX(
    uint256 _ID,
    uint256 _version,
    string[] memory _countries,
    bool[] memory _choices
) external onlyCaller returns (bool)
```
This function is only called on the destination chain by addCountrylist. It is an onlyCaller function.

**Parameters:**
- `_ID`: The ID of the RWA token
- `_version`: The version of the RWA token
- `_countries`: The list of countries to set the state for
- `_choices`: The list of choices for the countries

**Returns:** success True if the country list was set, false otherwise

## Query Functions

### getLastReason()
```solidity
function getLastReason() public view returns (string memory)
```
This reports on the latest revert string if a cross-chain call failed for whatever reason

**Returns:** lastReason The latest revert string if a cross-chain call failed for whatever reason

## Internal Functions

### _payFee()
```solidity
function _payFee(uint256 _feeWei, string memory _feeTokenStr) internal returns (bool)
```
Pay a fee, calculated by the feeType, the fee token and the chains in question

**Parameters:**
- `_feeWei`: The fee to pay in wei
- `_feeTokenStr`: The fee token address (as a string) to pay in

**Returns:** success True if the fee was paid, false otherwise

### _getFee()
```solidity
function _getFee(
    FeeType _feeType,
    uint256 _nItems,
    string[] memory _toChainIdsStr,
    string memory _feeTokenStr
) internal view returns (uint256)
```
Get the fee payable, depending on the _feeType

**Parameters:**
- `_feeType`: The type of fee to get
- `_nItems`: The number of items to get the fee for
- `_toChainIdsStr`: The list of chainIds to get the fee for
- `_feeTokenStr`: The fee token address (as a string) to get the fee in

**Returns:** fee The fee to pay in wei

### _getTokenAddr()
```solidity
function _getTokenAddr(uint256 _ID, uint256 _version) internal view returns (address, string memory)
```
Get the CTMRWA1 contract address corresponding to the ID on this chain

**Parameters:**
- `_ID`: The ID of the RWA token
- `_version`: The version of the RWA token

**Returns:**
- `tokenAddr`: The address of the CTMRWA1 contract
- `tokenAddrStr`: The string version of the CTMRWA1 contract address

### _getSentryAddr()
```solidity
function _getSentryAddr(uint256 _ID, uint256 _version) internal view returns (address, string memory)
```
Get the CTMRWA1Sentry address corresponding to the ID on this chain

**Parameters:**
- `_ID`: The ID of the RWA token
- `_version`: The version of the RWA token

**Returns:**
- `sentryAddr`: The address of the CTMRWA1Sentry contract
- `sentryAddrStr`: The string version of the CTMRWA1Sentry contract address

### _getSentry()
```solidity
function _getSentry(string memory _toChainIdStr, uint256 _version) internal view returns (string memory, string memory)
```
Get the sentryManager address on a destination chain for a c3call

**Parameters:**
- `_toChainIdStr`: The chainId of the destination chain
- `_version`: The version of the RWA token

**Returns:**
- `fromAddressStr`: The address of the CTMRWA1SentryManager contract on this chain
- `toSentryStr`: The address of the CTMRWA1SentryManager contract on the destination chain

### _checkTokenAdmin()
```solidity
function _checkTokenAdmin(address _tokenAddr) internal returns (address, string memory)
```
Check that the msg.sender is the same as the tokenAdmin for this RWA token

**Parameters:**
- `_tokenAddr`: The address of the CTMRWA1 contract

**Returns:**
- `currentAdmin`: The current tokenAdmin address
- `currentAdminStr`: The string version of the current tokenAdmin address

### _c3Fallback()
```solidity
function _c3Fallback(bytes4 _selector, bytes calldata _data, bytes calldata _reason) internal override returns (bool)
```
The fallback function for this GovernDApp in the event of a cross-chain call failure

**Parameters:**
- `_selector`: The selector of the function that failed
- `_data`: The data of the function that failed
- `_reason`: The reason for the failure

**Returns:** ok True if the fallback was successful, false otherwise

## Access Control Modifiers

- `onlyDeployer`: Restricts access to the deployer only
- `onlyGov`: Restricts access to governance only
- `onlyCaller`: Restricts access to cross-chain callers only
- `initializer`: Ensures the function is only called during initialization

## Events

### SettingSentryOptions
```solidity
event SettingSentryOptions(uint256 ID, string toChainIdStr)
```
A new c3call for ID to set the Sentry Options on chain toChainIdStr

### SentryOptionsSet
```solidity
event SentryOptionsSet(uint256 ID)
```
New Sentry Options set for ID

### AddingWhitelist
```solidity
event AddingWhitelist(uint256 ID, string toChainIdStr)
```
New c3call to set Whitelist for ID to chain toChainIdStr

### WhitelistAdded
```solidity
event WhitelistAdded(uint256 ID)
```
New Whitelist added on local chain for ID

### AddingCountryList
```solidity
event AddingCountryList(uint256 ID, string toChainIdStr)
```
New c3call to Add a Country CTMRWAErrorParam for ID to chain toChainIdStr

### CountryListAdded
```solidity
event CountryListAdded(uint256 ID)
```
New Country CTMRWAErrorParam added on local chain for ID

## Security Features

- **Access Control**: Multiple layers of access control with role-based permissions
- **Cross-chain Security**: Secure cross-chain communication through C3 protocol
- **Fee Protection**: Fee validation and transfer protection
- **Input Validation**: Comprehensive input validation for all parameters
- **Version Control**: Version checking to ensure compatibility
- **Admin Verification**: Token admin verification for sensitive operations
- **Fallback Handling**: Robust fallback mechanisms for failed cross-chain calls

## Integration Points

- **CTMRWA1**: Core RWA token contract integration
- **CTMRWAGateway**: Cross-chain gateway for communication
- **FeeManager**: Fee calculation and payment integration
- **CTMRWA1Identity**: KYC/KYB identity verification
- **CTMRWAMap**: Contract address mapping
- **CTMRWA1SentryUtils**: Utility functions for sentry operations
- **C3 Protocol**: Cross-chain communication protocol

## Error Handling

The contract uses custom error types for gas efficiency:

- `CTMRWA1SentryManager_OnlyAuthorized`: Thrown when unauthorized access is attempted
- `CTMRWA1SentryManager_InvalidVersion`: Thrown when invalid version is provided
- `CTMRWA1SentryManager_IsZeroAddress`: Thrown when zero address is provided
- `CTMRWA1SentryManager_InvalidContract`: Thrown when invalid contract is referenced
- `CTMRWA1SentryManager_OptionsAlreadySet`: Thrown when options are already set
- `CTMRWA1SentryManager_InvalidList`: Thrown when invalid list configuration is provided
- `CTMRWA1SentryManager_NoKYC`: Thrown when KYC is not enabled
- `CTMRWA1SentryManager_LengthMismatch`: Thrown when array lengths don't match
- `CTMRWA1SentryManager_InvalidLength`: Thrown when invalid length is provided
- `CTMRWA1SentryManager_SameChain`: Thrown when same chain is specified
- `CTMRWA1SentryManager_FailedTransfer`: Thrown when transfer fails
- `CTMRWA1SentryManager_InvalidRWAType`: Thrown when invalid RWA type is provided
- `CTMRWA1SentryManager_KYCDisabled`: Thrown when KYC is disabled
- `CTMRWA1SentryManager_AccreditationDisabled`: Thrown when accreditation is disabled

## Access Control Process

### 1. Sentry Options Configuration
- Token admin sets initial access control options
- Options can only be set once per token
- Cross-chain synchronization ensures consistency

### 2. KYC/KYB Setup
- Configure zkMe parameters for KYC verification
- Set up business verification if required
- Configure age and accreditation requirements

### 3. Whitelist Management
- Add/remove addresses from whitelist
- Cross-chain synchronization of whitelist changes
- Fee-based operations for whitelist updates

### 4. Country Restrictions
- Configure country whitelist or blacklist
- ISO3166 country code validation
- Cross-chain synchronization of country lists

### 5. Public Trading
- Remove accredited investor restrictions
- Maintain other compliance requirements
- Cross-chain synchronization of public status

## Use Cases

1. **RWA Token Compliance**: Enforce regulatory compliance for RWA tokens
2. **Cross-chain Access Control**: Maintain consistent access control across chains
3. **KYC/KYB Integration**: Integrate with identity verification systems
4. **Whitelist Management**: Manage approved investor lists
5. **Country Restrictions**: Enforce geographic trading restrictions
6. **Accredited Investor Controls**: Manage sophisticated investor requirements
7. **Public Trading Transition**: Transition from private to public trading

## Best Practices

1. **Access Control Planning**: Plan access control requirements before token deployment
2. **Cross-chain Coordination**: Ensure consistent configuration across all chains
3. **Fee Management**: Monitor and manage operation fees
4. **KYC Integration**: Properly configure KYC parameters
5. **Whitelist Maintenance**: Regularly update whitelist as needed
6. **Country Compliance**: Stay updated with regulatory requirements
7. **Public Transition**: Plan the transition to public trading

## Limitations

- **One-time Configuration**: Sentry options can only be set once
- **Cross-chain Dependency**: Requires proper cross-chain setup
- **Fee Requirements**: All operations require fee payment
- **Governance Dependency**: Many functions require governance approval
- **KYC Provider Dependency**: Some functions depend on KYC provider capabilities

## Future Enhancements

- **Additional KYC Providers**: Support for more KYC verification providers
- **Advanced Compliance**: More sophisticated compliance checking
- **Automated Updates**: Automated compliance rule updates
- **Analytics Integration**: Compliance analytics and reporting
- **Multi-signature Support**: Enhanced security for sensitive operations

## Cross-chain Architecture

### Sentry Manager Role
- Central management for all sentry contracts
- Cross-chain synchronization of access control
- Fee management and payment processing
- Governance and administrative functions

### Cross-chain Communication
- C3 protocol for secure cross-chain calls
- Fallback mechanisms for failed operations
- Event logging for cross-chain operations
- Error handling and recovery

### Deployment Management
- Sentry contract deployment coordination
- Version management across chains
- Contract address mapping and verification
- Cross-chain contract validation

## Gas Optimization

- **Efficient Storage**: Optimized storage layout for gas efficiency
- **Batch Operations**: Batch operations to reduce gas costs
- **Event Optimization**: Efficient event emission
- **Function Optimization**: Optimized function implementations
- **Cross-chain Efficiency**: Efficient cross-chain communication

## Security Considerations

- **Access Control**: Multi-layer access control system
- **Cross-chain Security**: Secure cross-chain communication
- **Fee Protection**: Protected fee payment mechanisms
- **Input Validation**: Comprehensive input validation
- **Version Control**: Version compatibility checking
- **Admin Security**: Secure admin function access
- **Fallback Security**: Secure fallback mechanisms