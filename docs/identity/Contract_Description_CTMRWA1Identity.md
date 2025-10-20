# CTMRWA1Identity Contract Documentation

## Overview

**Contract Name:** CTMRWA1Identity  
**File:** `src/identity/CTMRWA1Identity.sol`  
**License:** BSL-1.1  
**Author:** @Selqui ContinuumDAO

## Contract Description

This contract is to allow a user to register their KYC credentials and if they satisfy the requirements of the KYC Schema, then their address is Whitelisted in the RWA token on all chains. It allows truly decentralized & anonymous cross-chain credential verifications.

**Note:** This contract currently is only configured to work with zkMe (https://zk.me), but will be extended in the future to include other zkProof identity systems.

**Note:** This contract is only deployed on some chains, corresponding to where the zkMe verifier contract is. This means that if an Issuer wants to use KYC using zkMe, they must first add one of these chains to their RWA token AND ONLY THEN call setSentryOptions to enable the _kyc flag. IT HAS TO BE DONE IN THIS ORDER.

### Key Features
- KYC credential registration and verification
- Cross-chain whitelisting for verified addresses
- Decentralized and anonymous credential verification
- zkMe integration for zero-knowledge proof verification
- Fee management for KYC operations
- Reentrancy protection for verification security
- Chain-specific deployment (only on chains with zkMe verifier)
- Sentry integration for whitelist management
- Future extensibility for additional zkProof systems

## State Variables

- `RWA_TYPE (uint256, immutable)`: rwaType is the RWA type defining CTMRWA1
- `VERSION (uint256, immutable)`: version is the single integer version of this RWA type
- `ctmRwa1Map (address)`: The address of the CTMRWAMap contract
- `sentryManager (address)`: The address of the CTMRWA1SentryManager contract
- `zkMeVerifierAddress (address)`: The address of the zKMe Verifier contract
- `feeManager (address)`: The address of the FeeManager contract
- `cIdStr (string)`: The chainId as a string

## Constructor

```solidity
constructor(
    uint256 _rwaType,
    uint256 _version,
    address _map,
    address _sentryManager,
    address _verifierAddress,
    address _feeManager
)
```
- Initializes the CTMRWA1Identity contract instance
- Sets all contract addresses and configuration
- Sets chain ID string representation
- Establishes integration with the CTMRWA ecosystem

## Access Control

- `onlyIdChain`: Ensures zkMe verifier is available on current chain
- `onlySentryManager`: Restricts access to only SentryManager
- `onlyTokenAdmin(uint256 _ID)`: Restricts access to token admin for specific RWA

## Administrative Functions

### setZkMeVerifierAddress()
```solidity
function setZkMeVerifierAddress(address _verifierAddress) external onlySentryManager
```
Set the zkMe Verifier address.

**Reference:** See https://docs.zk.me/zkme-dochub/verify-with-zkme-protocol/integration-guide

## Verification Functions

### verifyPerson()
```solidity
function verifyPerson(uint256 _ID, uint256 _version, string[] memory _chainIdsStr, string memory _feeTokenStr) public onlyIdChain nonReentrant returns (bool)
```
Once a user has performed KYC with the provider, this function lets them submit their credentials to the Verifier by calling the hasApproved function. If they pass, then their wallet address is added to the RWA token Whitelist via a call to CTMRWASentryManager.

**Parameters:**
- `_ID`: The ID of the RWA token
- `_version`: The version of the RWA token
- `_chainIdsStr`: This is an array of strings of chainIDs to deploy to
- `_feeTokenStr`: This is fee token on the source chain (local chain) that you wish to use to pay for the deployment. See the function feeTokenList in the FeeManager contract for allowable values

**Returns:** True if the person was verified, false otherwise

### isVerifiedPerson()
```solidity
function isVerifiedPerson(uint256 _ID, uint256 _version, address _wallet) public view onlyIdChain returns (bool)
```
Check if a wallet address has the correct credentials to satisfy the Schema of the currently implemented zkMe programNo.

**Parameters:**
- `_ID`: The ID of the RWA token
- `_version`: The version of the RWA token
- `_wallet`: The wallet address to check

**Note:** Since the zkMe parameters can be updated, a user wallet can change its status. This function does NOT check if a wallet address is currently Whitelisted.

## Query Functions

### isKycChain()
```solidity
function isKycChain() public view returns (bool)
```
This checks if the zkMe Verifier contract has been set for this chain. If it returns false, then either the zkMeVerifier contract address has not yet been set (a deployment issue), or the current chain does not allow zkMe verification.

**Returns:** True if the chain is a KYC chain, false otherwise

## Internal Functions

### _payFee()
```solidity
function _payFee(string memory _feeTokenStr) internal returns (bool)
```
Pay the fees for verifyPerson KYC.

**Returns:** True if the fee was paid, false otherwise

## Events

- `LogFallback(bytes4 selector, bytes data, bytes reason)`: Logs fallback function calls
- `UserVerified(address indexed user)`: Emitted when a user is successfully verified and whitelisted

## Security Features

- Access control via multiple modifier levels
- Reentrancy protection for verification functions
- Chain validation ensures operations only on supported chains
- KYC validation validates KYC requirements before whitelisting
- Fee integration for KYC operations
- Zero address validation prevents operations with invalid addresses
- Duplicate prevention prevents re-whitelisting of already verified users
- Cross-chain security for whitelist management

## Integration Points

- `zkMe Verifier`: Zero-knowledge proof verification system
- `CTMRWA1Sentry`: Sentry contract for whitelist management
- `CTMRWA1SentryManager`: Manager for cross-chain whitelist operations
- `CTMRWAMap`: Contract address registry for sentry lookup
- `FeeManager`: Fee calculation and payment management
- `C3Caller`: Cross-chain communication system

## Error Handling

The contract uses custom error types for efficient gas usage:

- `CTMRWA1Identity_IsZeroAddress(CTMRWAErrorParam.ZKMe)`: Thrown when zkMe verifier address is zero
- `CTMRWA1Identity_IsZeroAddress(CTMRWAErrorParam.Cooperator)`: Thrown when cooperator address is zero
- `CTMRWA1Identity_OnlyAuthorized(CTMRWAErrorParam.Sender, CTMRWAErrorParam.SentryManager)`: Thrown when unauthorized address tries to update verifier
- `CTMRWA1Identity_OnlyAuthorized(CTMRWAErrorParam.Sender, CTMRWAErrorParam.TokenAdmin)`: Thrown when unauthorized address tries to perform admin functions
- `CTMRWA1Identity_InvalidContract(CTMRWAErrorParam.Sentry)`: Thrown when sentry contract not found
- `CTMRWA1Identity_KYCDisabled()`: Thrown when KYC is disabled for the RWA
- `CTMRWA1Identity_AlreadyWhitelisted(address user)`: Thrown when user is already whitelisted
- `CTMRWA1Identity_InvalidKYC(address user)`: Thrown when user fails KYC verification
- `CTMRWA1Identity_FailedTransfer()`: Thrown when token transfer fails

## Verification Process

### 1. KYC Preparation
- User completes KYC with zkMe provider
- Valid KYC credentials meeting Schema requirements
- User ready for on-chain verification

### 2. Verification Request
- User calls verifyPerson with RWA ID, version, chain IDs, and fee token
- Valid RWA ID, version, chain IDs, and fee token required
- Verification process initiated

### 3. System Validation
- Validate KYC system availability and configuration
- zkMe verifier available, KYC enabled, user not whitelisted
- Proceed if valid, revert if invalid

### 4. Credential Verification
- Call zkMe verifier to check user credentials
- Valid cooperator address and user credentials required
- Verification result from zkMe

### 5. Fee Payment
- Pay verification fee using FeeManager
- Sufficient fee token balance and approval required
- Fee paid and verification proceeds

### 6. Whitelist Addition
- Add user to whitelist across specified chains
- Successful verification and fee payment required
- User whitelisted on all specified chains

## Use Cases

### KYC Verification
- User needs KYC verification for RWA participation
- Complete zkMe KYC, call verifyPerson
- Anonymous yet verified identity for RWA access

### Cross-chain Access
- User needs access to RWA across multiple chains
- Single verification whitelists user on all chains
- Seamless cross-chain RWA participation

### Compliance Management
- Issuer needs KYC compliance for RWA
- Enable KYC in sentry, users verify through identity contract
- Regulatory compliance with privacy preservation

### Identity Portability
- User wants to use verified identity across different RWAs
- Verify once, access multiple RWAs
- Reusable identity verification

## Best Practices

1. **Chain Selection**: Choose chains with zkMe verifier support
2. **KYC Configuration**: Enable KYC in sentry before verification
3. **Fee Planning**: Ensure sufficient fee token balance for verification
4. **Cross-chain Coordination**: Coordinate verification across all chains
5. **Verification Monitoring**: Monitor verification events and status

## Limitations

- zkMe Dependency: Currently only supports zkMe verification
- Chain Specific: Only deployed on chains with zkMe verifier
- KYC Requirement: Requires KYC to be enabled in sentry
- Fee Requirement: All verifications require fee payment
- Single Provider: Limited to one verification provider initially

## zkMe Integration

### Verification Process
- Provider: zkMe zero-knowledge proof system
- Method: hasApproved function call to verifier contract
- Parameters: Cooperator address and user wallet
- Result: Boolean indicating verification status

### Configuration Requirements
- Verifier Address: Must be set for KYC operations
- Cooperator Address: Must be configured in sentry contract
- Schema Compliance: User must meet zkMe Schema requirements
- Chain Support: Only available on chains with zkMe deployment

### Integration Benefits
- Privacy: Zero-knowledge proofs preserve user privacy
- Decentralization: No central authority for verification
- Cross-chain: Verification works across all supported chains
- Compliance: Meets regulatory requirements while preserving privacy

## Cross-chain Architecture

### Whitelist Management
- Centralized Verification: Single verification point per user
- Distributed Whitelist: Whitelist distributed across all chains
- Synchronized Status: Consistent whitelist status across chains
- Coordinated Updates: Coordinated whitelist updates via SentryManager

### Chain Coordination
- Verification Chain: User verifies on chain with zkMe support
- Target Chains: Whitelist added to all specified target chains
- Fee Management: Fee paid on verification chain
- Status Synchronization: Status synchronized across all chains

## Gas Optimization

### Verification Costs
- zkMe Verification: ~50000-100000 gas for verification call
- Fee Payment: Variable based on fee amount
- Cross-chain Operations: ~100000-200000 gas for whitelist updates
- Total Estimate: ~150000-300000 gas per verification

### Optimization Strategies
- Efficient Verification: Optimize zkMe verification calls
- Fee Optimization: Optimize fee payment mechanisms
- Gas Estimation: Always estimate gas before verification
- Network Selection: Choose appropriate networks for verification

## Security Considerations

### Access Control
- Verifier Authorization: Only SentryManager can update verifier
- Admin Authorization: Only token admin can perform admin functions
- Chain Validation: Validate chain support before operations
- Function Validation: Validate all function parameters

### Privacy Protection
- Zero-knowledge Proofs: Use zkProofs to preserve privacy
- Minimal Data Exposure: Expose only necessary verification data
- Anonymous Verification: Enable anonymous credential verification
- Data Minimization: Minimize data stored on-chain

### Integration Security
- Verifier Validation: Validate zkMe verifier contract
- Sentry Integration: Secure integration with sentry system
- Cross-chain Safety: Secure cross-chain whitelist management
- Fee Security: Secure fee payment and management

## Compliance and Privacy

### Regulatory Compliance
- KYC Requirements: Meets Know Your Customer requirements
- Privacy Preservation: Preserves user privacy through zkProofs
- Cross-border: Supports cross-border compliance
- Audit Trail: Maintains audit trail for compliance

### Privacy Features
- Zero-knowledge: Uses zero-knowledge proofs for verification
- Anonymous: Enables anonymous credential verification
- Selective Disclosure: Only discloses necessary information
- Data Protection: Protects user data through cryptographic methods