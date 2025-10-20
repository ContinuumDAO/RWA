# CTMRWA1StorageManager Contract Documentation

## Overview

**Contract Name:** CTMRWA1StorageManager  
**Author:** @Selqui ContinuumDAO  
**License:** BSL-1.1  
**Solidity Version:** 0.8.27

The CTMRWA1StorageManager contract handles cross-chain interactions for decentralized storage of data relating to RWAs. It updates CTMRWA1Storage contracts for each RWA ID with checksum and other data, ensuring that CTMRWA1Storage contracts for every RWA with the same ID on each chain store exactly the same information.

This contract is deployed only once on each chain and manages all CTMRWA1 storage contract interactions. It provides comprehensive cross-chain storage management, fee calculation, and data synchronization capabilities.

## Key Features

- **Cross-chain Storage Management:** Synchronizes storage data across all chains
- **Decentralized Storage Integration:** Supports BNB Greenfield and IPFS storage systems
- **Fee Management:** Integrated fee calculation and payment for cross-chain operations
- **URI Management:** Manages storage object URIs with categories and types
- **Data Transfer:** Transfers existing storage data to newly added chains
- **Governance Control:** Governance can update contract addresses and configurations
- **Upgradeable:** Uses UUPS upgradeable pattern for future improvements
- **C3Caller Integration:** Uses C3Caller for cross-chain communication
- **TokenAdmin Authorization:** Validates tokenAdmin permissions for operations

## Public Variables

### Contract Addresses
- **`ctmRwaDeployer`** (address): Address of the CTMRWADeployer contract
- **`ctmRwa1Map`** (address): Address of the CTMRWAMap contract
- **`utilsAddr`** (address): Address of the CTMRWA1StorageUtils contract
- **`gateway`** (address): Address of the CTMRWAGateway contract
- **`feeManager`** (address): Address of the FeeManager contract

### Contract Identification
- **`RWA_TYPE`** (uint256, immutable): RWA type defining CTMRWA1 (1)
- **`LATEST_VERSION`** (uint256): Latest supported RWA version for this manager

### Configuration
- **`cIdStr`** (string): String representation of this chainID

## Core Functions

### Initialization

#### `initialize(address _gov, address _c3callerProxy, address _txSender, uint256 _dappID, address _ctmRwaDeployer, address _gateway, address _feeManager)`
- **Access:** Public initializer
- **Purpose:** Initializes the CTMRWA1StorageManager contract instance
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

#### `updateLatestVersion(uint256 _newVersion)`
- **Access:** Only callable by governance
- **Purpose:** Update the latest supported version
- **Parameters:** `_newVersion` - Must be > 0

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

#### `setStorageUtils(address _utilsAddr)`
- **Access:** Only callable by governance
- **Purpose:** Change to a new CTMRWA1StorageUtils contract
- **Parameters:** `_utilsAddr` - Address of new utils contract

### Deployment Functions

#### `deployStorage(uint256 _ID, address _tokenAddr, uint256 _rwaType, uint256 _version, address _map)`
- **Access:** Only callable by CTMRWADeployer
- **Purpose:** Deploy a CTMRWA1Storage contract
- **Parameters:**
  - `_ID`: ID of the RWA token
  - `_tokenAddr`: Address of the CTMRWA1 contract
  - `_rwaType`: Type of RWA (set to 1 for CTMRWA1)
  - `_version`: Version of RWA (set to 1 for current version)
  - `_map`: Address of the CTMRWAMap contract
- **Logic:** Calls CTMRWA1StorageUtils to deploy storage contract
- **Returns:** Address of the deployed CTMRWA1Storage contract

### Storage Management

#### `addURI(uint256 _ID, uint256 _version, string memory _objectName, URICategory _uriCategory, URIType _uriType, string memory _title, uint256 _slot, bytes32 _uriDataHash, string[] memory _chainIdsStr, string memory _feeTokenStr)`
- **Access:** Public function with tokenAdmin validation
- **Purpose:** Add storage record across multiple chains
- **Parameters:**
  - `_ID`: ID of the RWA token
  - `_version`: Version of the RWA token
  - `_objectName`: Object name on decentralized storage (should match nonce)
  - `_uriCategory`: Category type of stored data
  - `_uriType`: Type of storage (CONTRACT or SLOT)
  - `_title`: Title of storage record (10-256 characters)
  - `_slot`: Asset Class index (0 for CONTRACT type)
  - `_uriDataHash`: Unique hash of stored data checksum
  - `_chainIdsStr`: Array of destination chain IDs
  - `_feeTokenStr`: Fee token for payment
- **Validation:**
  - Ensures storage contract exists
  - Validates tokenAdmin authorization
  - Checks baseURI is configured
  - Prevents duplicate object names
  - Validates title length (10-256 characters)
- **Logic:**
  - Calculates and pays cross-chain fee
  - Adds URI on local chain
  - Makes cross-chain calls to other chains
- **Events:** Emits AddingURI event for each destination chain
- **Note:** First storage object must be ISSUER CONTRACT describing the Issuer

#### `transferURI(uint256 _ID, uint256 _version, string[] memory _chainIdsStr, string memory _feeTokenStr)`
- **Access:** Public function with tokenAdmin validation
- **Purpose:** Transfer all existing storage data to newly added chains
- **Parameters:**
  - `_ID`: ID of the RWA token
  - `_version`: Version of the RWA token
  - `_chainIdsStr`: Array of destination chain IDs (exclude local chain)
  - `_feeTokenStr`: Fee token for payment
- **Validation:**
  - Ensures storage contract exists
  - Validates tokenAdmin authorization
  - Checks baseURI is configured
  - Ensures at least one URI exists
- **Logic:**
  - Retrieves all URI data from local storage
  - Calculates total fee for all URIs
  - Pays cross-chain fee
  - Transfers all URIs to destination chains
- **Events:** Emits AddingURI event for each destination chain
- **Note:** Used when new chains are added to existing RWA

#### `addURIX(uint256 _ID, uint256 _version, uint256 _startNonce, string[] memory _objectName, uint8[] memory _uriCategory, uint8[] memory _uriType, string[] memory _title, uint256[] memory _slot, uint256[] memory _timestamp, bytes32[] memory _uriDataHash)`
- **Access:** Only callable by C3Caller
- **Purpose:** Add storage information on destination chain
- **Parameters:**
  - `_ID`: ID of the RWA token
  - `_version`: Version of the RWA token
  - `_startNonce`: Starting nonce value
  - `_objectName`: Array of object names
  - `_uriCategory`: Array of category types
  - `_uriType`: Array of storage types
  - `_title`: Array of titles
  - `_slot`: Array of slot indices
  - `_timestamp`: Array of timestamps
  - `_uriDataHash`: Array of data hashes
- **Validation:**
  - Ensures storage contract exists
  - Validates startNonce matches current nonce
- **Logic:**
  - Adds all URIs to local storage contract
  - Converts uint8 arrays to enums
- **Returns:** True if successful
- **Events:** Emits URIAdded event

## Internal Functions

### Utility Functions
- **`getLastReason()`**: Returns latest revert reason from cross-chain failures
- **`_getTokenAddr(uint256 _ID)`**: Gets CTMRWA1 contract address for RWA ID
- **`_getSM(string memory _toChainIdStr)`**: Gets storage manager address on destination chain
- **`_checkTokenAdmin(address _tokenAddr)`**: Validates tokenAdmin authorization
- **`cID()`**: Returns current chain ID

### Fee Management
- **`_individualFee(URICategory _uriCategory, string memory _feeTokenStr, string[] memory _toChainIdsStr, bool _includeLocal)`**: Calculates fee for specific URI category
  - Maps URICategory to FeeType
  - Gets fee from FeeManager
  - Returns total fee amount

- **`_payFee(uint256 _feeWei, string memory _feeTokenStr)`**: Pays fees for operations
  - Transfers fee tokens from caller to contract
  - Approves and pays fee to FeeManager
  - Returns true if successful

### Data Conversion
- **`_uToCat(uint8 _cat)`**: Converts uint8 to URICategory enum
- **`_uToType(uint8 _type)`**: Converts uint8 to URIType enum

### C3Caller Integration
- **`_c3Fallback(bytes4 _selector, bytes calldata _data, bytes calldata _reason)`**: C3Caller fallback function
  - Handles cross-chain call failures
  - Delegates to CTMRWA1StorageUtils for processing
  - Returns success status

## Access Control Modifiers

- **`onlyDeployer`**: Restricts access to only CTMRWADeployer
  - Ensures only authorized deployer can create storage contracts
  - Maintains deployment security and control

- **`onlyCaller`**: Restricts access to only C3Caller (inherited from C3GovernDapp)
  - Ensures only C3Caller can execute cross-chain functions
  - Maintains cross-chain security

- **`onlyGov`**: Restricts access to only governance (inherited from C3GovernDapp)
  - Ensures only governance can perform administrative functions
  - Maintains system control

## Events

- **`AddingURI(uint256 ID, string chainIdStr)`**: Emitted when adding URI to destination chain
- **`URIAdded(uint256 ID)`**: Emitted when URI is added on local chain

## Security Features

1. **Access Control:** Multiple levels of access control for different operations
2. **TokenAdmin Validation:** Validates tokenAdmin authorization for operations
3. **Cross-chain Security:** Secure cross-chain communication via C3Caller
4. **Fee Integration:** Integrated fee system for cross-chain operations
5. **Upgradeable:** Uses UUPS pattern for secure upgrades
6. **Governance Control:** Governance can update contract addresses
7. **Data Validation:** Validates all storage parameters and requirements
8. **Nonce Management:** Ensures proper nonce synchronization across chains

## Integration Points

- **CTMRWA1Storage**: Individual storage contracts for each RWA
- **CTMRWA1StorageUtils**: Storage deployment and error recovery
- **CTMRWAGateway**: Gateway for cross-chain address resolution
- **CTMRWAMap**: Contract address registry
- **CTMRWA1**: Core RWA token contract
- **FeeManager**: Fee calculation and payment management
- **C3Caller**: Cross-chain communication system
- **CTMRWADeployer**: Deployment coordinator

## Error Handling

The contract uses custom error types for efficient gas usage:

- **`CTMRWA1StorageManager_OnlyAuthorized(CTMRWAErrorParam.Sender, CTMRWAErrorParam.Deployer)`**: Thrown when unauthorized address tries to deploy storage
- **`CTMRWA1StorageManager_OnlyAuthorized(CTMRWAErrorParam.Sender, CTMRWAErrorParam.Admin)`**: Thrown when unauthorized address tries to perform admin functions
- **`CTMRWA1StorageManager_InvalidContract(CTMRWAErrorParam.Storage)`**: Thrown when storage contract not found
- **`CTMRWA1StorageManager_InvalidContract(CTMRWAErrorParam.Token)`**: Thrown when token contract not found
- **`CTMRWA1StorageManager_NoStorage()`**: Thrown when baseURI is not configured
- **`CTMRWA1StorageManager_ObjectAlreadyExists()`**: Thrown when object name already exists
- **`CTMRWA1StorageManager_InvalidLength(CTMRWAErrorParam.Title)`**: Thrown when title length is invalid
- **`CTMRWA1StorageManager_InvalidLength(CTMRWAErrorParam.URI)`**: Thrown when no URIs exist for transfer
- **`CTMRWA1StorageManager_SameChain()`**: Thrown when trying to call same chain
- **`CTMRWA1StorageManager_StartNonce()`**: Thrown when startNonce doesn't match current nonce

## Cross-chain Storage Process

### 1. Local Storage Addition
- **Step:** Add storage record on local chain
- **Method:** Call addURI with local chain ID
- **Result:** URI added to local storage contract

### 2. Cross-chain Propagation
- **Step:** Propagate storage to other chains
- **Method:** Make C3Caller calls to destination chains
- **Result:** Storage synchronized across all chains

### 3. Fee Payment
- **Step:** Pay cross-chain fees
- **Method:** Calculate and pay fees for all destination chains
- **Result:** Fees paid for cross-chain operations

### 4. Validation
- **Step:** Validate storage on all chains
- **Method:** Check storage data on each chain
- **Result:** Consistent storage across all chains

## Use Cases

### Cross-chain Storage Management
- **Scenario:** Add storage records across multiple chains
- **Process:** Use addURI to add storage to all chains
- **Benefit:** Consistent storage data across ecosystem

### New Chain Integration
- **Scenario:** Transfer existing storage to newly added chains
- **Process:** Use transferURI to sync all existing data
- **Benefit:** Seamless integration of new chains

### Decentralized Storage Integration
- **Scenario:** Store RWA documentation on BNB Greenfield
- **Process:** Use addURI with appropriate category and type
- **Benefit:** Immutable, decentralized storage with cross-chain access

### Regulatory Compliance
- **Scenario:** Store regulatory documents across all chains
- **Process:** Use LICENSE category for regulatory data
- **Benefit:** Transparent regulatory compliance across chains

## Best Practices

1. **Storage Planning:** Plan storage categories and types before adding
2. **Cross-chain Coordination:** Ensure storage is added to all chains
3. **Fee Management:** Ensure sufficient fee token balance
4. **TokenAdmin Security:** Secure tokenAdmin private keys
5. **Governance Control:** Use governance for contract updates

## Limitations

- **Single Instance:** Only one StorageManager per chain
- **Cross-chain Dependency:** Requires C3Caller for cross-chain operations
- **Fee Requirements:** All operations require fee payment
- **TokenAdmin Dependency:** All operations require tokenAdmin authorization
- **Nonce Synchronization:** Nonce must be synchronized across chains

## Future Enhancements

Potential improvements to the storage management system:

1. **Batch Operations:** Support batch URI additions and transfers
2. **Enhanced Analytics:** Add storage analytics and reporting
3. **Multi-storage Support:** Extend to support additional storage providers
4. **Automated Synchronization:** Implement automated cross-chain synchronization
5. **Advanced Fee Management:** Enhanced fee calculation and payment mechanisms

## Cross-chain Architecture
- **MPC Network** ContinuumDAO's public MPC node infrastructure

### Storage Synchronization
- **Centralized Management:** Single point of control for storage operations
- **Distributed Storage:** Storage data distributed across all chains
- **Synchronized Updates:** Updates propagated across all chains
- **Consistent Validation:** Consistent validation across all chains

### Communication Flow
- **Local Operations:** Direct calls to local storage contracts
- **Cross-chain Operations:** C3Caller-mediated calls to remote chains
- **Fee Management:** Fee calculation and payment for cross-chain operations
- **Fallback Handling:** Graceful handling of cross-chain failures

## Gas Optimization

### Cross-chain Costs
- **Local Storage Addition:** ~50000-100000 gas for local URI addition
- **Cross-chain Calls:** ~100000-200000 gas per destination chain
- **Fee Payment:** Variable based on fee amount and number of chains
- **Total Estimate:** ~150000-500000 gas per cross-chain operation

### Optimization Strategies
- **Batch Operations:** Consider batch URI additions for efficiency
- **Fee Optimization:** Optimize fee payment mechanisms
- **Gas Estimation:** Always estimate gas before operations
- **Network Selection:** Choose appropriate networks for operations

## Security Considerations

### Access Control
- **TokenAdmin Authorization:** Only tokenAdmin can perform storage operations
- **Governance Control:** Only governance can update contract addresses
- **Cross-chain Security:** Secure cross-chain communication via C3Caller
- **Function Validation:** Validate all function parameters

### Storage Security
- **Data Validation:** Validate all storage parameters and requirements
- **Cross-chain Consistency:** Ensure consistent storage across chains
- **Nonce Management:** Maintain nonce consistency across chains
- **Hash Verification:** Verify stored data integrity through checksums

### Cross-chain Security
- **C3Caller Integration:** Secure cross-chain communication
- **Fallback Handling:** Graceful handling of cross-chain failures
- **Address Resolution:** Secure address resolution via gateway
- **Fee Security:** Secure fee payment and management
