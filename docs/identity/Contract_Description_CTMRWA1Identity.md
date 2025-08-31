# CTMRWA1Identity Contract Documentation

## Overview

**Contract Name:** CTMRWA1Identity  
**Author:** @Selqui ContinuumDAO  
**License:** BSL-1.1  
**Solidity Version:** 0.8.27

The CTMRWA1Identity contract allows users to register their KYC credentials and, if they satisfy the requirements of the KYC Schema, their address is whitelisted in the RWA token on all chains. It enables truly decentralized and anonymous cross-chain credential verifications.

This contract is currently configured to work with zkMe (https://zk.me) but will be extended in the future to include other zkProof identity systems. It is only deployed on chains where the zkMe verifier contract is available. If an Issuer wants to use KYC with zkMe, they must first add one of these chains to their RWA token AND THEN call setSentryOptions to enable the _kyc flag - this order is critical.

## Key Features

- **KYC Integration:** Integrates with zkMe for zero-knowledge proof identity verification
- **Cross-chain Whitelisting:** Whitelists verified addresses across all chains
- **Decentralized Verification:** Enables anonymous credential verification
- **Fee Management:** Integrated fee system for KYC operations
- **Reentrancy Protection:** Uses ReentrancyGuard for verification security
- **Chain-specific Deployment:** Only deployed on chains with zkMe verifier
- **Sentry Integration:** Works with CTMRWA1Sentry for whitelist management
- **Future Extensibility:** Designed to support additional zkProof systems

## Public Variables

### Contract Identification
- **`RWA_TYPE`** (uint256, immutable): RWA type defining CTMRWA1
- **`VERSION`** (uint256, immutable): Single integer version of this RWA type

### Contract Addresses
- **`ctmRwa1Map`** (address): Address of the CTMRWAMap contract
- **`sentryManager`** (address): Address of the CTMRWA1SentryManager contract
- **`zkMeVerifierAddress`** (address): Address of the zkMe Verifier contract
- **`feeManager`** (address): Address of the FeeManager contract

### Configuration
- **`cIdStr`** (string): ChainId as a string

## Core Functions

### Constructor

#### `constructor(uint256 _rwaType, uint256 _version, address _map, address _sentryManager, address _verifierAddress, address _feeManager)`
- **Purpose:** Initializes a new CTMRWA1Identity contract instance
- **Parameters:**
  - `_rwaType`: RWA type defining CTMRWA1
  - `_version`: Version of this RWA type
  - `_map`: Address of the CTMRWAMap contract
  - `_sentryManager`: Address of the CTMRWA1SentryManager contract
  - `_verifierAddress`: Address of the zkMe Verifier contract
  - `_feeManager`: Address of the FeeManager contract
- **Initialization:**
  - Sets all contract addresses and configuration
  - Sets chain ID string representation
  - Establishes integration with the CTMRWA ecosystem

### Administrative Functions

#### `setZkMeVerifierAddress(address _verifierAddress)`
- **Access:** Only callable by SentryManager
- **Purpose:** Set the zkMe Verifier address
- **Parameters:** `_verifierAddress` - New zkMe verifier contract address
- **Use Case:** Allows updating zkMe verifier address for integration changes
- **Reference:** See https://docs.zk.me/zkme-dochub/verify-with-zkme-protocol/integration-guide

### Verification Functions

#### `verifyPerson(uint256 _ID, string[] memory _chainIdsStr, string memory _feeTokenStr)`
- **Access:** Public function with chain and reentrancy protection
- **Purpose:** Verify a person's KYC credentials and whitelist their address
- **Parameters:**
  - `_ID`: ID of the RWA token
  - `_chainIdsStr`: Array of chainID strings to deploy whitelist to
  - `_feeTokenStr`: Fee token on source chain for payment
- **Logic:**
  - Validates zkMe verifier is available
  - Checks sentry contract exists
  - Verifies KYC is enabled for the RWA
  - Ensures user is not already whitelisted
  - Validates zkMe cooperator address
  - Calls zkMe verifier to check approval
  - Pays verification fee
  - Adds user to whitelist across specified chains
- **Returns:** True if person was verified successfully
- **Events:** Emits UserVerified event
- **Security:** Uses nonReentrant modifier and chain validation

#### `isVerifiedPerson(uint256 _ID, address _wallet)`
- **Access:** Public view function with chain validation
- **Purpose:** Check if a wallet address has correct credentials for zkMe Schema
- **Parameters:**
  - `_ID`: ID of the RWA token
  - `_wallet`: Wallet address to check
- **Logic:**
  - Validates sentry contract exists
  - Checks KYC is enabled
  - Validates zkMe cooperator address
  - Calls zkMe verifier to check approval status
- **Returns:** True if wallet has valid credentials
- **Note:** Does NOT check if wallet is currently whitelisted
- **Note:** Status can change if zkMe parameters are updated

### Query Functions

#### `isKycChain()`
- **Purpose:** Check if current chain supports KYC verification
- **Logic:** Returns true if zkMe verifier address is set
- **Returns:** True if chain is a KYC chain, false otherwise
- **Use Case:** Determine if KYC operations are available on current chain

## Internal Functions

### Fee Management
- **`_payFee(string memory _feeTokenStr)`**: Pays fees for KYC verification
  - Calculates fee amount using FeeManager
  - Transfers fee tokens from user
  - Approves and pays fee to FeeManager
  - Returns true if fee payment successful

## Access Control Modifiers

- **`onlyIdChain`**: Ensures zkMe verifier is available on current chain
  - Validates zkMe verifier address is not zero
  - Prevents operations on chains without KYC support

- **`onlySentryManager`**: Restricts access to only SentryManager
  - Ensures only authorized manager can update verifier address
  - Maintains system security and control

- **`onlyTokenAdmin(uint256 _ID)`**: Restricts access to token admin for specific RWA
  - Validates sentry contract exists
  - Checks caller is token admin for the RWA
  - Ensures proper authorization for admin functions

## Events

- **`LogFallback(bytes4 selector, bytes data, bytes reason)`**: Logs fallback function calls
- **`UserVerified(address indexed user)`**: Emitted when a user is successfully verified and whitelisted

## Security Features

1. **Access Control:** Multiple levels of access control for different operations
2. **Reentrancy Protection:** Uses ReentrancyGuard for verification functions
3. **Chain Validation:** Ensures operations only on supported chains
4. **KYC Validation:** Validates KYC requirements before whitelisting
5. **Fee Integration:** Integrated fee system for KYC operations
6. **Zero Address Validation:** Prevents operations with invalid addresses
7. **Duplicate Prevention:** Prevents re-whitelisting of already verified users
8. **Cross-chain Security:** Secure cross-chain whitelist management

## Integration Points

- **zkMe Verifier**: Zero-knowledge proof verification system
- **CTMRWA1Sentry**: Sentry contract for whitelist management
- **CTMRWA1SentryManager**: Manager for cross-chain whitelist operations
- **CTMRWAMap**: Contract address registry for sentry lookup
- **FeeManager**: Fee calculation and payment management
- **C3Caller**: Cross-chain communication system

## Error Handling

The contract uses custom error types for efficient gas usage:

- **`CTMRWA1Identity_IsZeroAddress(CTMRWAErrorParam.ZKMe)`**: Thrown when zkMe verifier address is zero
- **`CTMRWA1Identity_IsZeroAddress(CTMRWAErrorParam.Cooperator)`**: Thrown when cooperator address is zero
- **`CTMRWA1Identity_OnlyAuthorized(CTMRWAErrorParam.Sender, CTMRWAErrorParam.SentryManager)`**: Thrown when unauthorized address tries to update verifier
- **`CTMRWA1Identity_OnlyAuthorized(CTMRWAErrorParam.Sender, CTMRWAErrorParam.TokenAdmin)`**: Thrown when unauthorized address tries to perform admin functions
- **`CTMRWA1Identity_InvalidContract(CTMRWAErrorParam.Sentry)`**: Thrown when sentry contract not found
- **`CTMRWA1Identity_KYCDisabled()`**: Thrown when KYC is disabled for the RWA
- **`CTMRWA1Identity_AlreadyWhitelisted(address user)`**: Thrown when user is already whitelisted
- **`CTMRWA1Identity_InvalidKYC(address user)`**: Thrown when user fails KYC verification

## Verification Process

### 1. KYC Preparation
- **Step:** User completes KYC with zkMe provider
- **Requirements:** Valid KYC credentials meeting Schema requirements
- **Result:** User ready for on-chain verification

### 2. Verification Request
- **Step:** User calls verifyPerson with RWA ID and chain parameters
- **Requirements:** Valid RWA ID, chain IDs, and fee token
- **Result:** Verification process initiated

### 3. System Validation
- **Step:** Validate KYC system availability and configuration
- **Requirements:** zkMe verifier available, KYC enabled, user not whitelisted
- **Result:** Proceed if valid, revert if invalid

### 4. Credential Verification
- **Step:** Call zkMe verifier to check user credentials
- **Requirements:** Valid cooperator address and user credentials
- **Result:** Verification result from zkMe

### 5. Fee Payment
- **Step:** Pay verification fee using FeeManager
- **Requirements:** Sufficient fee token balance and approval
- **Result:** Fee paid and verification proceeds

### 6. Whitelist Addition
- **Step:** Add user to whitelist across specified chains
- **Requirements:** Successful verification and fee payment
- **Result:** User whitelisted on all specified chains

## Use Cases

### KYC Verification
- **Scenario:** User needs KYC verification for RWA participation
- **Process:** Complete zkMe KYC, call verifyPerson
- **Benefit:** Anonymous yet verified identity for RWA access

### Cross-chain Access
- **Scenario:** User needs access to RWA across multiple chains
- **Process:** Single verification whitelists user on all chains
- **Benefit:** Seamless cross-chain RWA participation

### Compliance Management
- **Scenario:** Issuer needs KYC compliance for RWA
- **Process:** Enable KYC in sentry, users verify through identity contract
- **Benefit:** Regulatory compliance with privacy preservation

### Identity Portability
- **Scenario:** User wants to use verified identity across different RWAs
- **Process:** Verify once, access multiple RWAs
- **Benefit:** Reusable identity verification

## Best Practices

1. **Chain Selection:** Choose chains with zkMe verifier support
2. **KYC Configuration:** Enable KYC in sentry before verification
3. **Fee Planning:** Ensure sufficient fee token balance for verification
4. **Cross-chain Coordination:** Coordinate verification across all chains
5. **Verification Monitoring:** Monitor verification events and status

## Limitations

- **zkMe Dependency:** Currently only supports zkMe verification
- **Chain Specific:** Only deployed on chains with zkMe verifier
- **KYC Requirement:** Requires KYC to be enabled in sentry
- **Fee Requirement:** All verifications require fee payment
- **Single Provider:** Limited to one verification provider initially

## Future Enhancements

Potential improvements to the identity system:

1. **Multi-provider Support:** Extend to support other zkProof systems
2. **Enhanced Privacy:** Implement additional privacy features
3. **Verification Analytics:** Add verification tracking and analytics
4. **Automated Verification:** Implement automated verification workflows
5. **Identity Portability:** Enhanced cross-RWA identity sharing

## zkMe Integration

### Verification Process
- **Provider:** zkMe zero-knowledge proof system
- **Method:** hasApproved function call to verifier contract
- **Parameters:** Cooperator address and user wallet
- **Result:** Boolean indicating verification status

### Configuration Requirements
- **Verifier Address:** Must be set for KYC operations
- **Cooperator Address:** Must be configured in sentry contract
- **Schema Compliance:** User must meet zkMe Schema requirements
- **Chain Support:** Only available on chains with zkMe deployment

### Integration Benefits
- **Privacy:** Zero-knowledge proofs preserve user privacy
- **Decentralization:** No central authority for verification
- **Cross-chain:** Verification works across all supported chains
- **Compliance:** Meets regulatory requirements while preserving privacy

## Cross-chain Architecture

### Whitelist Management
- **Centralized Verification:** Single verification point per user
- **Distributed Whitelist:** Whitelist distributed across all chains
- **Synchronized Status:** Consistent whitelist status across chains
- **Coordinated Updates:** Coordinated whitelist updates via SentryManager

### Chain Coordination
- **Verification Chain:** User verifies on chain with zkMe support
- **Target Chains:** Whitelist added to all specified target chains
- **Fee Management:** Fee paid on verification chain
- **Status Synchronization:** Status synchronized across all chains

## Gas Optimization

### Verification Costs
- **zkMe Verification:** ~50000-100000 gas for verification call
- **Fee Payment:** Variable based on fee amount
- **Cross-chain Operations:** ~100000-200000 gas for whitelist updates
- **Total Estimate:** ~150000-300000 gas per verification

### Optimization Strategies
- **Efficient Verification:** Optimize zkMe verification calls
- **Fee Optimization:** Optimize fee payment mechanisms
- **Gas Estimation:** Always estimate gas before verification
- **Network Selection:** Choose appropriate networks for verification

## Security Considerations

### Access Control
- **Verifier Authorization:** Only SentryManager can update verifier
- **Admin Authorization:** Only token admin can perform admin functions
- **Chain Validation:** Validate chain support before operations
- **Function Validation:** Validate all function parameters

### Privacy Protection
- **Zero-knowledge Proofs:** Use zkProofs to preserve privacy
- **Minimal Data Exposure:** Expose only necessary verification data
- **Anonymous Verification:** Enable anonymous credential verification
- **Data Minimization:** Minimize data stored on-chain

### Integration Security
- **Verifier Validation:** Validate zkMe verifier contract
- **Sentry Integration:** Secure integration with sentry system
- **Cross-chain Safety:** Secure cross-chain whitelist management
- **Fee Security:** Secure fee payment and management

## Compliance and Privacy

### Regulatory Compliance
- **KYC Requirements:** Meets Know Your Customer requirements
- **Privacy Preservation:** Preserves user privacy through zkProofs
- **Cross-border:** Supports cross-border compliance
- **Audit Trail:** Maintains audit trail for compliance

### Privacy Features
- **Zero-knowledge:** Uses zero-knowledge proofs for verification
- **Anonymous:** Enables anonymous credential verification
- **Selective Disclosure:** Only discloses necessary information
- **Data Protection:** Protects user data through cryptographic methods
