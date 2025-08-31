# CTMRWA1StorageUtils Contract Documentation

## Overview

**Contract Name:** CTMRWA1StorageUtils  
**Author:** @Selqui ContinuumDAO  
**License:** BSL-1.1  
**Solidity Version:** 0.8.27

The CTMRWA1StorageUtils contract has two primary tasks. First, it deploys new CTMRWA1Storage contracts on a single chain using the CREATE2 instruction to ensure deterministic addresses. Second, it manages all cross-chain failures in synchronizing on-chain records for Storage operations.

This contract is deployed only once on each chain and manages all CTMRWA1Storage contract deployments and C3Caller fallbacks. It serves as a utility contract that provides deployment and error recovery functionality for the storage system.

## Key Features

- **CREATE2 Deployment:** Uses CREATE2 instruction for deterministic contract addresses
- **Cross-chain Error Recovery:** Manages C3Caller fallbacks for storage operations
- **Storage Management:** Coordinates with CTMRWA1StorageManager for deployments
- **Error Tracking:** Maintains records of failed cross-chain operations
- **URI Management:** Handles URI addition failures and recovery
- **Nonce Management:** Manages nonce rewinding for failed operations
- **Decentralized Storage Integration:** Supports integration with decentralized storage systems

## Public Variables

### Contract Identification
- **`RWA_TYPE`** (uint256, immutable): RWA type defining CTMRWA1
- **`VERSION`** (uint256, immutable): Version of this RWA type

### Contract Addresses
- **`ctmRwa1Map`** (address): Address of the CTMRWAMap contract
- **`storageManager`** (address): Address of the CTMRWA1StorageManager contract

### Error Tracking
- **`lastSelector`** (bytes4): Latest function selector from failed C3Caller operation
- **`lastData`** (bytes): Latest data from failed C3Caller operation
- **`lastReason`** (bytes): Latest reason from failed C3Caller operation

### Function Selectors
- **`AddURIX`** (bytes4, constant): Function selector for addURIX cross-chain function
  - Calculated as keccak256("addURIX(uint256,uint256,string[],uint8[],uint8[],string[],uint256[],uint256[],bytes32[])")

## Core Functions

### Initialization

#### `constructor(uint256 _rwaType, uint256 _version, address _map, address _storageManager)`
- **Access:** Public constructor
- **Purpose:** Initializes the CTMRWA1StorageUtils contract instance
- **Parameters:**
  - `_rwaType`: RWA type defining CTMRWA1
  - `_version`: Version of this RWA type
  - `_map`: Address of the CTMRWAMap contract
  - `_storageManager`: Address of the CTMRWA1StorageManager contract
- **Initialization:**
  - Sets immutable RWA_TYPE and VERSION
  - Sets contract addresses for map and storage manager
  - Establishes connection to storage management system

### Deployment Functions

#### `deployStorage(uint256 _ID, address _tokenAddr, uint256 _rwaType, uint256 _version, address _map)`
- **Access:** Only callable by CTMRWA1StorageManager
- **Purpose:** Deploy a new CTMRWA1Storage contract using CREATE2
- **Parameters:**
  - `_ID`: ID of the RWA token (used as CREATE2 salt)
  - `_tokenAddr`: Address of the CTMRWA1 contract
  - `_rwaType`: Type of RWA (set to 1 for CTMRWA1)
  - `_version`: Version of RWA (set to 1 for current version)
  - `_map`: Address of the CTMRWAMap contract
- **Logic:**
  - Uses CREATE2 instruction with `_ID` as salt for deterministic address
  - Deploys new CTMRWA1Storage contract
  - Passes storageManager as the manager address
- **Returns:** Address of the deployed CTMRWA1Storage contract
- **Security:** Only storageManager can deploy storage contracts

### Error Recovery Functions

#### `getLastReason()`
- **Access:** Public view function
- **Purpose:** Get the latest revert string from a failed C3Caller cross-chain transaction
- **Returns:** String representation of the last failure reason
- **Use Case:** Debugging and monitoring cross-chain operation failures

#### `smC3Fallback(bytes4 _selector, bytes calldata _data, bytes calldata _reason)`
- **Access:** Only callable by CTMRWA1StorageManager
- **Purpose:** Handle C3Caller fallbacks for failed cross-chain storage operations
- **Parameters:**
  - `_selector`: Function selector of the failed operation
  - `_data`: Encoded data of the failed operation
  - `_reason`: Reason for the failure
- **Logic:**
  - Stores failure information for debugging
  - Handles addURIX operation failures specifically
  - Decodes failed operation parameters
  - Performs recovery operations:
    - Pops URI records from storage
    - Rewinds nonce to previous state
- **Recovery Process:**
  - For addURIX failures:
    - Extracts ID, startNonce, and objectName from failed data
    - Gets storage contract address from map
    - Calls popURILocal to remove failed URI records
    - Calls setNonce to rewind nonce to previous state
- **Returns:** True if fallback was successful
- **Events:** Emits LogFallback event with failure details
- **Note:** Storage object on decentralized storage must be cleaned up before retry

## Internal Functions

### Utility Functions
- **`_getTokenAddr(uint256 _ID)`**: Gets CTMRWA1 contract address for RWA ID
  - Queries CTMRWAMap for token contract address
  - Returns both address and lowercase hex string
  - Throws error if token contract not found

## Access Control Modifiers

- **`onlyStorageManager`**: Restricts access to only CTMRWA1StorageManager
  - Ensures only authorized storage manager can deploy contracts
  - Maintains deployment security and control
  - Prevents unauthorized access to fallback functions

## Events

- **`LogFallback(bytes4 selector, bytes data, bytes reason)`**: Emitted when C3Caller fallback is processed
  - Records function selector, data, and reason for debugging
  - Helps track cross-chain operation failures
  - Enables monitoring and analysis of failure patterns

## Security Features

1. **Access Control:** Only storageManager can deploy contracts and handle fallbacks
2. **CREATE2 Security:** Uses deterministic deployment with ID as salt
3. **Error Tracking:** Maintains comprehensive error records
4. **Recovery Mechanisms:** Provides automatic recovery for failed operations
5. **Parameter Validation:** Validates contract addresses and parameters
6. **Immutable Configuration:** RWA_TYPE and VERSION are immutable for security

## Integration Points

- **CTMRWA1StorageManager**: Main storage management contract
- **CTMRWA1Storage**: Individual storage contracts for each RWA
- **CTMRWAMap**: Contract address registry
- **CTMRWA1**: Core RWA token contract
- **C3Caller**: Cross-chain communication system
- **Decentralized Storage**: External storage systems (e.g., BNB Greenfield)

## Error Handling

The contract uses custom error types for efficient gas usage:

- **`CTMRWA1StorageUtils_OnlyAuthorized(CTMRWAErrorParam.Sender, CTMRWAErrorParam.StorageManager)`**: Thrown when unauthorized address tries to access functions
- **`CTMRWA1StorageUtils_InvalidContract(CTMRWAErrorParam.Storage)`**: Thrown when storage contract not found
- **`CTMRWA1StorageUtils_InvalidContract(CTMRWAErrorParam.Token)`**: Thrown when token contract not found

## Cross-chain Error Recovery Process

### 1. Failure Detection
- **Step:** C3Caller detects cross-chain operation failure
- **Method:** C3Caller calls smC3Fallback with failure details
- **Result:** Failure information stored for analysis

### 2. Error Analysis
- **Step:** Analyze failure type and parameters
- **Method:** Decode function selector and data
- **Result:** Determine appropriate recovery action

### 3. State Recovery
- **Step:** Recover to previous consistent state
- **Method:** Pop failed records and rewind nonce
- **Result:** Storage state restored to pre-failure condition

### 4. Cleanup
- **Step:** Clean up external storage objects
- **Method:** Remove objects from decentralized storage
- **Result:** System ready for retry

## Use Cases

### Storage Contract Deployment
- **Scenario:** Deploy new storage contract for RWA token
- **Process:** Use deployStorage with CREATE2 for deterministic address
- **Benefit:** Predictable contract addresses across deployments

### Cross-chain URI Addition Recovery
- **Scenario:** Handle failed URI addition across chains
- **Process:** Use smC3Fallback to recover state
- **Benefit:** Maintain data consistency across chains

### Error Monitoring
- **Scenario:** Monitor cross-chain operation failures
- **Process:** Use getLastReason to retrieve failure details
- **Benefit:** Debug and improve cross-chain reliability

### Storage System Management
- **Scenario:** Coordinate storage operations across multiple contracts
- **Process:** Work with storage manager for deployment and recovery
- **Benefit:** Centralized storage management and error handling

## Best Practices

1. **Error Monitoring:** Regularly check getLastReason for failures
2. **Cleanup Coordination:** Ensure decentralized storage cleanup before retries
3. **Deployment Planning:** Plan storage deployments with deterministic addresses
4. **Recovery Testing:** Test fallback mechanisms regularly
5. **Cross-chain Coordination:** Coordinate with storage manager for operations

## Limitations

- **Single Instance:** Only one StorageUtils per chain
- **Manager Dependency:** All operations require storage manager authorization
- **External Cleanup:** Requires manual cleanup of decentralized storage objects
- **Cross-chain Dependency:** Requires C3Caller for cross-chain operations
- **Recovery Scope:** Limited to specific operation types (currently addURIX)

## Future Enhancements

Potential improvements to the storage utilities system:

1. **Enhanced Recovery:** Extend recovery to more operation types
2. **Automated Cleanup:** Automate decentralized storage cleanup
3. **Advanced Monitoring:** Add comprehensive monitoring and alerting
4. **Batch Operations:** Support batch deployment and recovery
5. **Multi-storage Support:** Extend to support multiple storage providers such as IPFS, Arweave

## CREATE2 Deployment Architecture

### Deterministic Addresses
- **Salt Generation:** Uses RWA ID as CREATE2 salt
- **Address Calculation:** Predictable addresses across deployments
- **Collision Prevention:** Unique addresses for each RWA token
- **Verification:** Addresses can be calculated off-chain

### Deployment Process
- **Parameter Validation:** Validate all deployment parameters
- **Contract Creation:** Use CREATE2 for deterministic deployment
- **Address Registration:** Register address with storage manager
- **Verification:** Verify successful deployment

## Gas Optimization

### Deployment Costs
- **CREATE2 Deployment:** ~200000-300000 gas for storage contract deployment
- **Fallback Processing:** ~50000-100000 gas for error recovery
- **Address Lookup:** ~5000-10000 gas for contract address queries
- **Total Estimate:** ~250000-400000 gas per deployment

### Optimization Strategies
- **Batch Deployments:** Consider batch deployment for efficiency
- **Gas Estimation:** Always estimate gas before deployments
- **Error Prevention:** Minimize cross-chain failures to reduce recovery costs
- **Efficient Recovery:** Optimize recovery operations for gas efficiency

## Security Considerations

### Access Control
- **Manager Authorization:** Only storage manager can deploy and handle fallbacks
- **Function Validation:** Validate all function parameters
- **Address Verification:** Verify contract addresses before operations
- **Error Handling:** Secure error handling and recovery

### Deployment Security
- **CREATE2 Security:** Secure CREATE2 deployment with proper salt
- **Parameter Validation:** Validate all deployment parameters
- **Address Verification:** Verify deployed contract addresses
- **Manager Security:** Secure storage manager access

### Cross-chain Security
- **C3Caller Integration:** Secure cross-chain communication
- **Fallback Security:** Secure fallback handling and recovery
- **State Consistency:** Maintain consistent state across chains
- **Error Recovery:** Secure error recovery mechanisms
