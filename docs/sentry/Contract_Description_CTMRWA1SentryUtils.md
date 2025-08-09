# CTMRWA1SentryUtils Contract Documentation

## Overview

**Contract Name:** CTMRWA1SentryUtils  
**Author:** @Selqui ContinuumDAO  
**License:** BSL-1.1  
**Solidity Version:** 0.8.27

The CTMRWA1SentryUtils contract serves as a utility contract for the CTMRWA1Sentry system. Its main purpose is to deploy instances of CTMRWA1Sentry contracts for CTMRWA1 tokens using CREATE2 for deterministic addresses. It also houses the required C3Caller fallback function for handling cross-chain operation failures.

This contract is deployed only once on each chain and manages all CTMRWA1Sentry contract deployments and C3Caller fallbacks. It provides deployment and error tracking functionality for the sentry system.

## Key Features

- **CREATE2 Deployment:** Uses CREATE2 instruction for deterministic sentry contract addresses
- **Cross-chain Error Tracking:** Maintains records of failed C3Caller operations
- **Sentry Management:** Coordinates with CTMRWA1SentryManager for deployments
- **Error Monitoring:** Provides debugging information for cross-chain failures
- **Fallback Handling:** Handles C3Caller fallbacks for sentry operations
- **Address Resolution:** Provides utility functions for contract address lookup
- **Immutable Configuration:** Uses immutable variables for security

## Public Variables

### Contract Identification
- **`RWA_TYPE`** (uint256, immutable): RWA type defining CTMRWA1
- **`VERSION`** (uint256, immutable): Version of this RWA type

### Contract Addresses
- **`ctmRwa1Map`** (address): Address of the CTMRWAMap contract
- **`sentryManager`** (address): Address of the CTMRWA1SentryManager contract

### Error Tracking
- **`lastSelector`** (bytes4): Latest function selector from failed C3Caller operation
- **`lastData`** (bytes): Latest data from failed C3Caller operation
- **`lastReason`** (bytes): Latest reason from failed C3Caller operation

## Core Functions

### Initialization

#### `constructor(uint256 _rwaType, uint256 _version, address _map, address _sentryManager)`
- **Access:** Public constructor
- **Purpose:** Initializes the CTMRWA1SentryUtils contract instance
- **Parameters:**
  - `_rwaType`: RWA type defining CTMRWA1
  - `_version`: Version of this RWA type
  - `_map`: Address of the CTMRWAMap contract
  - `_sentryManager`: Address of the CTMRWA1SentryManager contract
- **Initialization:**
  - Sets immutable RWA_TYPE and VERSION
  - Sets contract addresses for map and sentry manager
  - Establishes connection to sentry management system

### Deployment Functions

#### `deploySentry(uint256 _ID, address _tokenAddr, uint256 _rwaType, uint256 _version, address _map)`
- **Access:** Only callable by CTMRWA1SentryManager
- **Purpose:** Deploy an instance of CTMRWA1Sentry using CREATE2
- **Parameters:**
  - `_ID`: ID of the RWA token (used as CREATE2 salt)
  - `_tokenAddr`: Address of the CTMRWA1 contract
  - `_rwaType`: Type of RWA token (set to 1 for CTMRWA1)
  - `_version`: Version of the RWA token (set to 1 for current version)
  - `_map`: Address of the CTMRWAMap contract
- **Logic:**
  - Uses CREATE2 instruction with `_ID` as salt for deterministic address
  - Deploys new CTMRWA1Sentry contract
  - Passes sentryManager as the manager address
- **Returns:** Address of the deployed CTMRWA1Sentry contract
- **Security:** Only sentryManager can deploy sentry contracts

### Error Recovery Functions

#### `getLastReason()`
- **Access:** Public view function
- **Purpose:** Get the latest revert string from a failed cross-chain C3Caller operation
- **Returns:** String representation of the last failure reason
- **Use Case:** Debugging and monitoring cross-chain operation failures
- **Note:** For debug purposes only

#### `sentryC3Fallback(bytes4 _selector, bytes calldata _data, bytes calldata _reason)`
- **Access:** Only callable by CTMRWA1SentryManager
- **Purpose:** Handle C3Caller fallbacks for failed cross-chain sentry operations
- **Parameters:**
  - `_selector`: Function selector of the failed operation
  - `_data`: Encoded data of the failed operation
  - `_reason`: Reason for the failure
- **Logic:**
  - Stores failure information for debugging purposes
  - Currently does not perform any recovery operations
  - Emits LogFallback event with failure details
- **Returns:** True if fallback was successful
- **Events:** Emits LogFallback event with failure details
- **Note:** Currently only tracks failures, no recovery actions implemented

## Internal Functions

### Utility Functions
- **`_getTokenAddr(uint256 _ID)`**: Gets CTMRWA1 contract address for RWA ID
  - Queries CTMRWAMap for token contract address
  - Returns both address and lowercase hex string
  - Throws error if token contract not found

## Access Control Modifiers

- **`onlySentryManager`**: Restricts access to only CTMRWA1SentryManager
  - Ensures only authorized sentry manager can deploy contracts
  - Maintains deployment security and control
  - Prevents unauthorized access to fallback functions

## Events

- **`LogFallback(bytes4 selector, bytes data, bytes reason)`**: Emitted when C3Caller fallback is processed
  - Records function selector, data, and reason for debugging
  - Helps track cross-chain operation failures
  - Enables monitoring and analysis of failure patterns

## Security Features

1. **Access Control:** Only sentryManager can deploy contracts and handle fallbacks
2. **CREATE2 Security:** Uses deterministic deployment with ID as salt
3. **Error Tracking:** Maintains comprehensive error records
4. **Parameter Validation:** Validates contract addresses and parameters
5. **Immutable Configuration:** RWA_TYPE and VERSION are immutable for security
6. **Manager Authorization:** All operations require sentry manager authorization

## Integration Points

- **CTMRWA1SentryManager**: Main sentry management contract
- **CTMRWA1Sentry**: Individual sentry contracts for each RWA
- **CTMRWAMap**: Contract address registry
- **CTMRWA1**: Core RWA token contract
- **C3Caller**: Cross-chain communication system

## Error Handling

The contract uses custom error types for efficient gas usage:

- **`CTMRWA1SentryUtils_OnlyAuthorized(CTMRWAErrorParam.Sender, CTMRWAErrorParam.SentryManager)`**: Thrown when unauthorized address tries to access functions
- **`CTMRWA1SentryUtils_InvalidContract(CTMRWAErrorParam.Token)`**: Thrown when token contract not found

## Cross-chain Error Tracking Process

### 1. Failure Detection
- **Step:** C3Caller detects cross-chain operation failure
- **Method:** C3Caller calls sentryC3Fallback with failure details
- **Result:** Failure information stored for analysis

### 2. Error Recording
- **Step:** Record failure details for debugging
- **Method:** Store selector, data, and reason
- **Result:** Complete failure record maintained

### 3. Event Emission
- **Step:** Emit event for monitoring
- **Method:** Emit LogFallback event
- **Result:** Failure visible to external monitoring systems

### 4. Debug Access
- **Step:** Provide access to failure information
- **Method:** Use getLastReason to retrieve details
- **Result:** Debug information available for analysis

## Use Cases

### Sentry Contract Deployment
- **Scenario:** Deploy new sentry contract for RWA token
- **Process:** Use deploySentry with CREATE2 for deterministic address
- **Benefit:** Predictable contract addresses across deployments

### Cross-chain Error Monitoring
- **Scenario:** Monitor cross-chain sentry operation failures
- **Process:** Use getLastReason to retrieve failure details
- **Benefit:** Debug and improve cross-chain reliability

### Sentry System Management
- **Scenario:** Coordinate sentry operations across multiple contracts
- **Process:** Work with sentry manager for deployment and error tracking
- **Benefit:** Centralized sentry management and error handling

### Debugging Support
- **Scenario:** Debug cross-chain sentry operation failures
- **Process:** Analyze failure records and events
- **Benefit:** Improved system reliability and debugging capabilities

## Best Practices

1. **Error Monitoring:** Regularly check getLastReason for failures
2. **Deployment Planning:** Plan sentry deployments with deterministic addresses
3. **Cross-chain Coordination:** Coordinate with sentry manager for operations
4. **Debug Information:** Use failure records for system improvement
5. **Event Monitoring:** Monitor LogFallback events for failure patterns

## Limitations

- **Single Instance:** Only one SentryUtils per chain
- **Manager Dependency:** All operations require sentry manager authorization
- **Limited Recovery:** Currently only tracks failures, no recovery actions
- **Cross-chain Dependency:** Requires C3Caller for cross-chain operations
- **Debug Focus:** Primarily focused on debugging rather than recovery

## Future Enhancements

Potential improvements to the sentry utilities system:

1. **Enhanced Recovery:** Implement actual recovery mechanisms for failures
2. **Advanced Monitoring:** Add comprehensive monitoring and alerting
3. **Batch Operations:** Support batch deployment and error handling
4. **Automated Debugging:** Add automated failure analysis and reporting
5. **Recovery Actions:** Implement specific recovery actions for different failure types

## CREATE2 Deployment Architecture

### Deterministic Addresses
- **Salt Generation:** Uses RWA ID as CREATE2 salt
- **Address Calculation:** Predictable addresses across deployments
- **Collision Prevention:** Unique addresses for each RWA token
- **Verification:** Addresses can be calculated off-chain

### Deployment Process
- **Parameter Validation:** Validate all deployment parameters
- **Contract Creation:** Use CREATE2 for deterministic deployment
- **Address Registration:** Register address with sentry manager
- **Verification:** Verify successful deployment

## Gas Optimization

### Deployment Costs
- **CREATE2 Deployment:** ~200000-300000 gas for sentry contract deployment
- **Fallback Processing:** ~20000-50000 gas for error tracking
- **Address Lookup:** ~5000-10000 gas for contract address queries
- **Total Estimate:** ~225000-360000 gas per deployment

### Optimization Strategies
- **Batch Deployments:** Consider batch deployment for efficiency
- **Gas Estimation:** Always estimate gas before deployments
- **Error Prevention:** Minimize cross-chain failures to reduce tracking costs
- **Efficient Tracking:** Optimize error tracking operations for gas efficiency

## Security Considerations

### Access Control
- **Manager Authorization:** Only sentry manager can deploy and handle fallbacks
- **Function Validation:** Validate all function parameters
- **Address Verification:** Verify contract addresses before operations
- **Error Handling:** Secure error handling and tracking

### Deployment Security
- **CREATE2 Security:** Secure CREATE2 deployment with proper salt
- **Parameter Validation:** Validate all deployment parameters
- **Address Verification:** Verify deployed contract addresses
- **Manager Security:** Secure sentry manager access

### Cross-chain Security
- **C3Caller Integration:** Secure cross-chain communication
- **Fallback Security:** Secure fallback handling and tracking
- **Error Tracking:** Secure error tracking and debugging
- **Event Security:** Secure event emission and monitoring
