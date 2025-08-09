# CTMRWAMap Contract Documentation

## Overview

**Contract Name:** CTMRWAMap  
**Author:** @Selqui ContinuumDAO  
**License:** BSL-1.1  
**Solidity Version:** 0.8.27

The CTMRWAMap contract serves as the central registry that links together the various components of the CTMRWA1 RWA ecosystem. For every unique RWA ID, there are five main contracts that work together:

1. **CTMRWA1** - The core Semi-Fungible-Token contract
2. **CTMRWA1Dividend** - Dividend distribution contract
3. **CTMRWA1Storage** - Storage management contract
4. **CTMRWA1Sentry** - Security and access control contract
5. **CTMRWAInvest** - Investment with escrow contract

This contract is deployed once on each chain and maintains the state linking each RWA ID to its constituent contract addresses. It also stores reverse mappings from contract addresses back to their corresponding IDs. The contract provides a unified interface for querying and managing these relationships across the entire CTMRWA ecosystem.

## Key Features

- **Central Registry:** Maintains mappings between RWA IDs and contract addresses
- **Bidirectional Lookup:** Supports both ID-to-contract and contract-to-ID queries
- **Multi-contract Support:** Manages relationships for all CTMRWA1 ecosystem contracts
- **Cross-chain Consistency:** Ensures consistent ID mapping across all chains
- **Contract Attachment:** Handles the linking of contracts during deployment
- **Type Validation:** Validates RWA type and version compatibility
- **Governance Control:** Governance can update contract addresses
- **Upgradeable:** Uses UUPS upgradeable pattern for future improvements
- **C3Caller Integration:** Uses C3Caller for cross-chain communication

## Public Variables

### Contract Addresses
- **`gateway`** (address): Address of the CTMRWAGateway contract
- **`ctmRwaDeployer`** (address): Address of the CTMRWADeployer contract
- **`ctmRwa1X`** (address): Address of the CTMRWA1X contract

### Configuration
- **`cIdStr`** (string): String representation of the local chainID

### ID to Contract Mappings
- **`idToContract`** (mapping): Maps RWA ID to CTMRWA1 contract address (string)
- **`idToDividend`** (mapping): Maps RWA ID to CTMRWA1Dividend contract address (string)
- **`idToStorage`** (mapping): Maps RWA ID to CTMRWA1Storage contract address (string)
- **`idToSentry`** (mapping): Maps RWA ID to CTMRWA1Sentry contract address (string)
- **`idToInvest`** (mapping): Maps RWA ID to CTMRWADeployInvest contract address (string)

### Contract to ID Mappings
- **`contractToId`** (mapping): Maps CTMRWA1 contract address (string) to RWA ID
- **`dividendToId`** (mapping): Maps CTMRWA1Dividend contract address (string) to RWA ID
- **`storageToId`** (mapping): Maps CTMRWA1Storage contract address (string) to RWA ID
- **`sentryToId`** (mapping): Maps CTMRWA1Sentry contract address (string) to RWA ID
- **`investToId`** (mapping): Maps CTMRWADeployInvest contract address (string) to RWA ID

## Core Functions

### Initialization

#### `initialize(address _gov, address _c3callerProxy, address _txSender, uint256 _dappID, address _gateway, address _rwa1X)`
- **Access:** Public initializer
- **Purpose:** Initializes the CTMRWAMap contract instance
- **Parameters:**
  - `_gov`: Governance address
  - `_c3callerProxy`: C3Caller proxy address
  - `_txSender`: Transaction sender address
  - `_dappID`: DApp ID for C3Caller integration
  - `_gateway`: CTMRWAGateway contract address
  - `_rwa1X`: CTMRWA1X contract address
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

### Configuration Functions

#### `setCtmRwaDeployer(address _deployer, address _gateway, address _rwa1X)`
- **Access:** Only callable by CTMRWA1X
- **Purpose:** Set addresses of CTMRWADeployer, CTMRWAGateway, and CTMRWA1X
- **Parameters:**
  - `_deployer`: New CTMRWADeployer address
  - `_gateway`: New CTMRWAGateway address
  - `_rwa1X`: New CTMRWA1X address
- **Note:** Can only be called by setMap function in CTMRWA1X, called by Governor

### Query Functions

#### `getTokenId(string memory _tokenAddrStr, uint256 _rwaType, uint256 _version)`
- **Access:** Public view function
- **Purpose:** Get RWA ID for a given CTMRWA1 contract address
- **Parameters:**
  - `_tokenAddrStr`: String version of CTMRWA1 contract address
  - `_rwaType`: Type of RWA (must be 1 for CTMRWA1)
  - `_version`: Version of RWA (latest is 1)
- **Returns:** Tuple of (bool ok, uint256 id)
  - `ok`: True if ID exists, false otherwise
  - `id`: RWA ID if found, 0 otherwise
- **Logic:** Converts address to lowercase and looks up in contractToId mapping

#### `getTokenContract(uint256 _ID, uint256 _rwaType, uint256 _version)`
- **Access:** Public view function
- **Purpose:** Get CTMRWA1 contract address for a given RWA ID
- **Parameters:**
  - `_ID`: RWA ID to examine
  - `_rwaType`: Type of RWA (must be 1 for CTMRWA1)
  - `_version`: Version of RWA (latest is 1)
- **Returns:** Tuple of (bool ok, address contractStr)
  - `ok`: True if ID exists, false otherwise
  - `contractStr`: CTMRWA1 contract address if found, address(0) otherwise
- **Logic:** Looks up in idToContract mapping and validates type/version

#### `getDividendContract(uint256 _ID, uint256 _rwaType, uint256 _version)`
- **Access:** Public view function
- **Purpose:** Get CTMRWA1Dividend contract address for a given RWA ID
- **Parameters:** Same as getTokenContract
- **Returns:** Tuple of (bool ok, address dividendStr)
- **Logic:** Looks up in idToDividend mapping and validates type/version

#### `getStorageContract(uint256 _ID, uint256 _rwaType, uint256 _version)`
- **Access:** Public view function
- **Purpose:** Get CTMRWA1Storage contract address for a given RWA ID
- **Parameters:** Same as getTokenContract
- **Returns:** Tuple of (bool ok, address storageStr)
- **Logic:** Looks up in idToStorage mapping and validates type/version

#### `getSentryContract(uint256 _ID, uint256 _rwaType, uint256 _version)`
- **Access:** Public view function
- **Purpose:** Get CTMRWA1Sentry contract address for a given RWA ID
- **Parameters:** Same as getTokenContract
- **Returns:** Tuple of (bool ok, address sentryStr)
- **Logic:** Looks up in idToSentry mapping and validates type/version

#### `getInvestContract(uint256 _ID, uint256 _rwaType, uint256 _version)`
- **Access:** Public view function
- **Purpose:** Get CTMRWADeployInvest contract address for a given RWA ID
- **Parameters:** Same as getTokenContract
- **Returns:** Tuple of (bool ok, address investStr)
- **Logic:** Looks up in idToInvest mapping and validates type/version

### Contract Management

#### `attachContracts(uint256 _ID, address _tokenAddr, address _dividendAddr, address _storageAddr, address _sentryAddr)`
- **Access:** Only callable by CTMRWADeployer
- **Purpose:** Link CTMRWA1 ecosystem contracts together after deployment
- **Parameters:**
  - `_ID`: RWA ID for the contracts
  - `_tokenAddr`: CTMRWA1 contract address
  - `_dividendAddr`: CTMRWA1Dividend contract address
  - `_storageAddr`: CTMRWA1Storage contract address
  - `_sentryAddr`: CTMRWA1Sentry contract address
- **Logic:**
  - Calls internal _attachCTMRWAID function
  - Attaches dividend, storage, and sentry contracts to CTMRWA1
  - Validates all attachments are successful
- **Validation:** Ensures contracts are not already attached

#### `setInvestmentContract(uint256 _ID, uint256 _rwaType, uint256 _version, address _investAddr)`
- **Access:** Only callable by CTMRWADeployer
- **Purpose:** Set investment contract for a given RWA ID
- **Parameters:**
  - `_ID`: RWA ID
  - `_rwaType`: Type of RWA (must be 1 for CTMRWA1)
  - `_version`: Version of RWA (latest is 1)
  - `_investAddr`: CTMRWADeployInvest contract address
- **Returns:** True if investment contract was set, false otherwise
- **Logic:**
  - Validates RWA type and version
  - Ensures contract hasn't been deployed yet
  - Sets bidirectional mappings

## Internal Functions

### Contract Attachment
- **`_attachCTMRWAID(uint256 _ID, address _ctmRwaAddr, address _dividendAddr, address _storageAddr, address _sentryAddr)`**: Internal helper for attachContracts
  - Converts addresses to lowercase strings
  - Validates contracts are not already attached
  - Sets all bidirectional mappings
  - Returns true if successful, false if already attached

### Utility Functions
- **`cID()`**: Returns current chain ID
  - Used for chain identification
  - Returns block.chainid

### Validation Functions
- **`_checkRwaTypeVersion(string memory _addrStr, uint256 _rwaType, uint256 _version)`**: Validates RWA type and version compatibility
  - Checks if address string is not empty
  - Queries contract for RWA_TYPE and VERSION
  - Validates against provided parameters
  - Returns true if compatible, false otherwise

### C3Caller Integration
- **`_c3Fallback(bytes4 _selector, bytes calldata _data, bytes calldata _reason)`**: C3Caller fallback function
  - Handles cross-chain call failures
  - Emits LogFallback event with failure details
  - Returns true (currently only logs failures)

## Access Control Modifiers

- **`onlyDeployer`**: Restricts access to only CTMRWADeployer
  - Ensures only authorized deployer can attach contracts
  - Maintains deployment security and control

- **`onlyRwa1X`**: Restricts access to only CTMRWA1X
  - Ensures only CTMRWA1X can update contract addresses
  - Maintains system control and coordination

- **`onlyGov`**: Restricts access to only governance (inherited from C3GovernDapp)
  - Ensures only governance can authorize upgrades
  - Maintains system control

## Events

- **`LogFallback(bytes4 selector, bytes data, bytes reason)`**: Emitted when C3Caller fallback is processed
  - Records function selector, data, and reason for debugging
  - Helps track cross-chain operation failures
  - Enables monitoring and analysis of failure patterns

## Security Features

1. **Access Control:** Multiple levels of access control for different operations
2. **Type Validation:** Validates RWA type and version compatibility
3. **Duplicate Prevention:** Prevents duplicate contract attachments
4. **Bidirectional Mapping:** Ensures data consistency with reverse lookups
5. **Upgradeable:** Uses UUPS pattern for secure upgrades
6. **Governance Control:** Governance can authorize upgrades
7. **Address Validation:** Validates contract addresses before operations

## Integration Points

- **CTMRWA1**: Core RWA token contract
- **CTMRWA1Dividend**: Dividend distribution contract
- **CTMRWA1Storage**: Storage management contract
- **CTMRWA1Sentry**: Security and access control contract
- **CTMRWADeployInvest**: Investment deployment contract
- **CTMRWADeployer**: Deployment coordinator
- **CTMRWAGateway**: Cross-chain gateway
- **CTMRWA1X**: Cross-chain coordinator
- **C3Caller**: Cross-chain communication system

## Error Handling

The contract uses custom error types for efficient gas usage:

- **`CTMRWAMap_OnlyAuthorized(CTMRWAErrorParam.Sender, CTMRWAErrorParam.Deployer)`**: Thrown when unauthorized address tries to attach contracts
- **`CTMRWAMap_OnlyAuthorized(CTMRWAErrorParam.Sender, CTMRWAErrorParam.RWAX)`**: Thrown when unauthorized address tries to update addresses
- **`CTMRWAMap_AlreadyAttached(uint256 ID, address tokenAddr)`**: Thrown when contracts are already attached
- **`CTMRWAMap_FailedAttachment(CTMRWAErrorParam.Dividend)`**: Thrown when dividend attachment fails
- **`CTMRWAMap_FailedAttachment(CTMRWAErrorParam.Storage)`**: Thrown when storage attachment fails
- **`CTMRWAMap_FailedAttachment(CTMRWAErrorParam.Sentry)`**: Thrown when sentry attachment fails
- **`CTMRWAMap_IncompatibleRWA(CTMRWAErrorParam.Type)`**: Thrown when RWA type is incompatible
- **`CTMRWAMap_IncompatibleRWA(CTMRWAErrorParam.Version)`**: Thrown when RWA version is incompatible

## Contract Relationship Management

### Ecosystem Structure
- **Single ID:** Each RWA has a unique ID across all chains
- **Four Core Contracts:** CTMRWA1, CTMRWA1Dividend, CTMRWA1Storage, CTMRWA1Sentry
- **Optional Investment Contract:** CTMRWADeployInvest for investment functionality
- **Bidirectional Mapping:** ID-to-contract and contract-to-ID lookups

### Attachment Process
1. **Deployment:** CTMRWADeployer deploys all contracts
2. **Registration:** CTMRWAMap registers contract addresses
3. **Attachment:** Contracts are linked together
4. **Validation:** All relationships are validated

## Use Cases

### Contract Discovery
- **Scenario:** Find all contracts for a specific RWA
- **Process:** Use query functions with RWA ID
- **Benefit:** Complete ecosystem contract discovery

### Address Resolution
- **Scenario:** Resolve contract addresses across chains
- **Process:** Use getTokenContract and related functions
- **Benefit:** Consistent address resolution

### Contract Management
- **Scenario:** Manage contract relationships during deployment
- **Process:** Use attachContracts to link contracts
- **Benefit:** Automated contract relationship management

### Cross-chain Coordination
- **Scenario:** Coordinate contract addresses across chains
- **Process:** Use CTMRWAGateway for cross-chain resolution
- **Benefit:** Consistent contract addressing across ecosystem

## Best Practices

1. **ID Management:** Ensure unique RWA IDs across all chains
2. **Contract Validation:** Always validate RWA type and version
3. **Address Consistency:** Maintain consistent address mappings
4. **Deployment Coordination:** Coordinate deployments across chains
5. **Governance Control:** Use governance for critical updates

## Limitations

- **Single Instance:** Only one CTMRWAMap per chain
- **Deployer Dependency:** All attachments require deployer authorization
- **Cross-chain Dependency:** Requires coordination across chains
- **Type Restriction:** Currently only supports RWA_TYPE = 1
- **Version Restriction:** Currently only supports VERSION = 1

## Future Enhancements

Potential improvements to the mapping system:

1. **Multi-type Support:** Additional RWA types can be added
2. **Version Management:** Enhanced version management and migration
3. **Advanced Queries:** Enhanced query capabilities and filtering
4. **Analytics Integration:** Add mapping analytics and reporting

## Cross-chain Architecture

### Mapping Synchronization
- **Centralized Registry:** Single point of truth for contract mappings
- **Distributed Storage:** Mappings stored on each chain
- **Consistent Addressing:** Consistent contract addressing across chains
- **Gateway Integration:** Uses gateway for cross-chain resolution

### Communication Flow
- **Local Queries:** Direct queries to local mappings
- **Cross-chain Resolution:** Gateway-mediated address resolution
- **Deployment Coordination:** Coordinated deployment across chains
- **Fallback Handling:** Graceful handling of cross-chain failures

## Gas Optimization

### Query Costs
- **Local Queries:** ~5000-15000 gas for contract address lookups
- **Type Validation:** ~10000-20000 gas for RWA type/version checks
- **Contract Attachment:** ~50000-100000 gas for contract linking
- **Total Estimate:** ~65000-135000 gas per operation

### Optimization Strategies
- **Efficient Queries:** Use appropriate query functions
- **Batch Operations:** Consider batch operations for efficiency
- **Gas Estimation:** Always estimate gas before operations
- **Caching:** Cache frequently accessed mappings

## Security Considerations

### Access Control
- **Deployer Authorization:** Only deployer can attach contracts
- **Governance Control:** Only governance can authorize upgrades
- **Cross-chain Security:** Secure cross-chain communication
- **Function Validation:** Validate all function parameters

### Data Integrity
- **Bidirectional Mapping:** Maintain consistent bidirectional mappings
- **Type Validation:** Validate RWA type and version compatibility
- **Duplicate Prevention:** Prevent duplicate contract attachments
- **Address Validation:** Validate contract addresses before operations

### Cross-chain Security
- **Gateway Integration:** Secure gateway for cross-chain resolution
- **Fallback Handling:** Graceful handling of cross-chain failures
- **Consistent Addressing:** Maintain consistent addressing across chains
- **Deployment Security:** Secure deployment and attachment process
