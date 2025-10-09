# CTMRWA1Identity Contract Documentation

## Overview

**Contract Name:** CTMRWA1Identity  
**File:** `src/identity/CTMRWA1Identity.sol`  
**License:** BSL-1.1  
**Author:** @Selqui ContinuumDAO  
**Type:** Implementation Contract  

## Contract Description

CTMRWA1Identity is a decentralized identity verification contract for Real-World Asset (RWA) tokens. It allows users to register their KYC credentials and, if they satisfy the requirements of the KYC Schema, get their address whitelisted in the RWA token across all chains. The contract enables truly decentralized and anonymous cross-chain credential verifications, currently configured to work with zkMe but designed to be extensible to other zkProof identity systems.

### Key Features
- Decentralized KYC credential verification
- Cross-chain whitelisting
- zkProof integration (zkMe)
- Anonymous verification
- Fee management
- Reentrancy protection
- Multi-chain support

## State Variables

### Core Addresses
- `ctmRwa1Map` (address): The address of the CTMRWAMap contract
- `sentryManager` (address): The address of the CTMRWA1SentryManager contract
- `zkMeVerifierAddress` (address): The address of the zKMe Verifier contract
- `feeManager` (address): The address of the FeeManager contract

### Identifiers
- `RWA_TYPE` (uint256, immutable): RWA type defining CTMRWA1
- `VERSION` (uint256, immutable): Version of this RWA type

### Chain Information
- `cIdStr` (string): The chainId as a string

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

### Constructor Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `_rwaType` | `uint256` | RWA type defining CTMRWA1 |
| `_version` | `uint256` | Version of this RWA type |
| `_map` | `address` | The CTMRWAMap contract address |
| `_sentryManager` | `address` | The CTMRWA1SentryManager contract address |
| `_verifierAddress` | `address` | The zKMe Verifier contract address |
| `_feeManager` | `address` | The FeeManager contract address |

### Constructor Behavior

During construction, the contract:
1. Sets the RWA_TYPE and VERSION as immutable values
2. Sets the ctmRwa1Map address for cross-chain mapping
3. Sets the sentryManager address for access control
4. Sets the zkMeVerifierAddress for zkProof verification
5. Sets the feeManager address for fee collection
6. Sets the chainId string

## Identity Verification Functions

### verifyPerson()
```solidity
function verifyPerson(
    uint256 _ID,
    string[] memory _chainIds,
    string memory _feeTokenStr
) public onlyIdChain nonReentrant returns (bool)
```
**Description:** Verifies a person's identity using zkProof and whitelists them across specified chains.  
**Parameters:**
- `_ID` (uint256): RWA identifier
- `_chainIds` (string[]): Array of chain IDs where the user should be whitelisted
- `_feeTokenStr` (string): Fee token identifier
**Access:** Public (only on chains with zkMe verifier)  
**Returns:** True if verification successful  
**Effects:** Whitelists user across specified chains  

### verifyPersonWithProof()
```solidity
function verifyPersonWithProof(
    uint256 _ID,
    string[] memory _chainIds,
    string memory _feeTokenStr,
    bytes memory _proof
) public onlyIdChain nonReentrant returns (bool)
```
**Description:** Verifies a person's identity with a provided zkProof.  
**Parameters:**
- `_ID` (uint256): RWA identifier
- `_chainIds` (string[]): Array of chain IDs where the user should be whitelisted
- `_feeTokenStr` (string): Fee token identifier
- `_proof` (bytes): zkProof data
**Access:** Public (only on chains with zkMe verifier)  
**Returns:** True if verification successful  
**Effects:** Whitelists user across specified chains  

## Administrative Functions

### setSentryOptions()
```solidity
function setSentryOptions(
    uint256 _ID,
    bool _kyc,
    bool _aml,
    bool _kyb,
    string memory _feeTokenStr
) external onlyTokenAdmin(_ID)
```
**Description:** Sets KYC, AML, and KYB options for an RWA.  
**Parameters:**
- `_ID` (uint256): RWA identifier
- `_kyc` (bool): Enable/disable KYC requirement
- `_aml` (bool): Enable/disable AML requirement
- `_kyb` (bool): Enable/disable KYB requirement
- `_feeTokenStr` (string): Fee token identifier
**Access:** Only tokenAdmin for the specified RWA  
**Effects:** Updates verification requirements  

### setZkMeVerifier()
```solidity
function setZkMeVerifier(address _verifierAddress) external onlySentryManager
```
**Description:** Sets the zKMe verifier contract address.  
**Parameters:**
- `_verifierAddress` (address): New zKMe verifier address
**Access:** Only sentryManager  
**Effects:** Updates zkMeVerifierAddress  

### setFeeManager()
```solidity
function setFeeManager(address _feeManager) external onlySentryManager
```
**Description:** Sets the FeeManager contract address.  
**Parameters:**
- `_feeManager` (address): New fee manager address
**Access:** Only sentryManager  
**Effects:** Updates feeManager address  

## Query Functions

### getVerificationStatus()
```solidity
function getVerificationStatus(uint256 _ID, address _user) external view returns (bool)
```
**Description:** Returns the verification status of a user for a specific RWA.  
**Parameters:**
- `_ID` (uint256): RWA identifier
- `_user` (address): User address
**Returns:** True if user is verified/whitelisted  

### getSentryOptions()
```solidity
function getSentryOptions(uint256 _ID) external view returns (bool, bool, bool)
```
**Description:** Returns the KYC, AML, and KYB options for an RWA.  
**Parameters:**
- `_ID` (uint256): RWA identifier
**Returns:** Tuple of (kyc, aml, kyb) boolean values  

### getZkMeVerifier()
```solidity
function getZkMeVerifier() external view returns (address)
```
**Description:** Returns the zKMe verifier contract address.  
**Returns:** zKMe verifier address  

### getFeeManager()
```solidity
function getFeeManager() external view returns (address)
```
**Description:** Returns the FeeManager contract address.  
**Returns:** FeeManager address  

## Access Control Modifiers

- `onlyIdChain`: Ensures the contract is deployed on a chain with zkMe verifier
- `onlySentryManager`: Restricts access to sentryManager
- `onlyTokenAdmin`: Restricts access to tokenAdmin for specific RWA
- `nonReentrant`: Prevents reentrancy attacks

## Events

### LogFallback
```solidity
event LogFallback(bytes4 selector, bytes data, bytes reason);
```
**Description:** Emitted when a fallback function is called with details about the call.

### UserVerified
```solidity
event UserVerified(address indexed user);
```
**Description:** Emitted when a user is successfully verified.

## Security Features

- **ReentrancyGuard**: Protects against reentrancy attacks
- **Access Control**: Role-based permissions
- **zkProof Verification**: Cryptographic proof validation
- **Cross-chain Validation**: Secure multi-chain operations
- **Fee Management**: Integrated fee collection

## Integration Points

- **CTMRWAMap**: Cross-chain contract mapping
- **CTMRWA1SentryManager**: Access control management
- **zkMe Verifier**: zkProof verification
- **FeeManager**: Fee collection and management
- **CTMRWA1Sentry**: Individual sentry contracts

## Verification Flow

1. **User** calls `verifyPerson()` with RWA ID and target chains
2. **Contract** validates zkProof using zkMe verifier
3. **Contract** collects fees via FeeManager
4. **Contract** calls sentryManager to whitelist user across chains
5. **User** becomes whitelisted for the specified RWA on all target chains

## Key Features

- **Decentralized**: No central authority controls verification
- **Anonymous**: Users can verify without revealing personal data
- **Cross-chain**: Verification applies across multiple chains
- **Extensible**: Designed to support multiple zkProof systems
- **Fee-based**: Integrated fee collection for verification services
- **Configurable**: TokenAdmins can set verification requirements

## Deployment Considerations

- Contract is only deployed on chains with zkMe verifier contracts
- Issuers must add identity-enabled chains before enabling KYC
- Order of operations: Add chain → Enable KYC → Verify users
- Supports multiple verification types (KYC, AML, KYB)
