# CTMRWAMap Contract Documentation

## Overview

**Contract Name:** CTMRWAMap  
**File:** `src/shared/CTMRWAMap.sol`  
**License:** BSL-1.1  
**Author:** @Selqui ContinuumDAO  
**Type:** Upgradeable Contract  

## Contract Description

CTMRWAMap is the central mapping contract that links together the various components of CTMRWA1 Real-World Asset (RWA) tokens across multiple chains. For every unique RWA ID, it maintains mappings to the four core contract types: CTMRWA1 (the main token), CTMRWA1Dividend, CTMRWA1Storage, and CTMRWA1Sentry. This contract is deployed once on each chain and serves as the authoritative source for cross-chain contract address resolution.

### Key Features
- Cross-chain contract address mapping
- Bidirectional ID-to-contract and contract-to-ID lookups
- Multi-component RWA architecture support
- Governance-controlled upgrades
- Chain-specific deployment tracking
- Centralized contract registry

## State Variables

### Core Addresses
- `gateway` (address): The address of the CTMRWAGateway contract
- `ctmRwaDeployer` (address): The address of the CTMRWADeployer contract
- `ctmRwa1X` (address): The address of the CTMRWA1X contract

### Chain Information
- `cIdStr` (string): String representation of the local chain ID

### Contract Mappings

#### CTMRWA1 Token Mappings
- `idToContract` (mapping): ID => CTMRWA1 contract address as string
- `contractToId` (mapping): CTMRWA1 contract address as string => ID

#### Dividend Contract Mappings
- `idToDividend` (mapping): ID => CTMRWA1Dividend contract address as string
- `dividendToId` (mapping): CTMRWA1Dividend contract address as string => ID

#### Storage Contract Mappings
- `idToStorage` (mapping): ID => CTMRWA1Storage contract address as string
- `storageToId` (mapping): CTMRWA1Storage contract address as string => ID

#### Sentry Contract Mappings
- `idToSentry` (mapping): ID => CTMRWA1Sentry contract address as string
- `sentryToId` (mapping): CTMRWA1Sentry contract address as string => ID

#### Investment Contract Mappings
- `idToInvest` (mapping): ID => CTMRWADeployInvest contract address as string
- `investToId` (mapping): CTMRWADeployInvest contract address as string => ID

## Initialization

The contract uses an `initialize` function instead of a constructor since it's upgradeable:

```solidity
function initialize(
    address _gov,
    address _c3callerProxy,
    address _txSender,
    uint256 _dappID,
    address _gateway,
    address _rwa1X
) external initializer
```

### Initialization Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `_gov` | `address` | The governance address |
| `_c3callerProxy` | `address` | The C3Caller proxy address |
| `_txSender` | `address` | The transaction sender address |
| `_dappID` | `uint256` | The dApp ID |
| `_gateway` | `address` | The CTMRWAGateway contract address |
| `_rwa1X` | `address` | The CTMRWA1X contract address |

### Initialization Behavior

During initialization, the contract:
1. Initializes C3GovernDapp with governance parameters
2. Sets the gateway and ctmRwa1X addresses
3. Sets the chain ID string

## Governance Functions

### setCtmRwaDeployer()
```solidity
function setCtmRwaDeployer(address _deployer, address _gateway, address _rwa1X) external onlyGov
```
**Description:** Sets the CTMRWADeployer, Gateway, and CTMRWA1X addresses.  
**Parameters:**
- `_deployer` (address): New deployer address
- `_gateway` (address): New gateway address
- `_rwa1X` (address): New rwa1X address
**Access:** Only governance  
**Effects:** Updates core contract addresses  

## Contract Attachment Functions

### attachContract()
```solidity
function attachContract(uint256 _ID, string memory _contractStr) external onlyDeployer returns (bool)
```
**Description:** Attaches a CTMRWA1 contract to an ID.  
**Parameters:**
- `_ID` (uint256): RWA identifier
- `_contractStr` (string): CTMRWA1 contract address as string
**Access:** Only deployer  
**Returns:** True if successful  
**Effects:** Creates bidirectional mapping  

### attachDividend()
```solidity
function attachDividend(uint256 _ID, string memory _dividendStr) external onlyDeployer returns (bool)
```
**Description:** Attaches a CTMRWA1Dividend contract to an ID.  
**Parameters:**
- `_ID` (uint256): RWA identifier
- `_dividendStr` (string): CTMRWA1Dividend contract address as string
**Access:** Only deployer  
**Returns:** True if successful  
**Effects:** Creates bidirectional mapping  

### attachStorage()
```solidity
function attachStorage(uint256 _ID, string memory _storageStr) external onlyDeployer returns (bool)
```
**Description:** Attaches a CTMRWA1Storage contract to an ID.  
**Parameters:**
- `_ID` (uint256): RWA identifier
- `_storageStr` (string): CTMRWA1Storage contract address as string
**Access:** Only deployer  
**Returns:** True if successful  
**Effects:** Creates bidirectional mapping  

### attachSentry()
```solidity
function attachSentry(uint256 _ID, string memory _sentryStr) external onlyDeployer returns (bool)
```
**Description:** Attaches a CTMRWA1Sentry contract to an ID.  
**Parameters:**
- `_ID` (uint256): RWA identifier
- `_sentryStr` (string): CTMRWA1Sentry contract address as string
**Access:** Only deployer  
**Returns:** True if successful  
**Effects:** Creates bidirectional mapping  

### attachInvest()
```solidity
function attachInvest(uint256 _ID, string memory _investStr) external onlyDeployer returns (bool)
```
**Description:** Attaches a CTMRWADeployInvest contract to an ID.  
**Parameters:**
- `_ID` (uint256): RWA identifier
- `_investStr` (string): CTMRWADeployInvest contract address as string
**Access:** Only deployer  
**Returns:** True if successful  
**Effects:** Creates bidirectional mapping  

## Query Functions

### getContract()
```solidity
function getContract(uint256 _ID) external view returns (bool, string memory)
```
**Description:** Returns the CTMRWA1 contract address for an ID.  
**Parameters:**
- `_ID` (uint256): RWA identifier
**Returns:** Tuple of (exists, contract address)  

### getDividend()
```solidity
function getDividend(uint256 _ID) external view returns (bool, string memory)
```
**Description:** Returns the CTMRWA1Dividend contract address for an ID.  
**Parameters:**
- `_ID` (uint256): RWA identifier
**Returns:** Tuple of (exists, dividend address)  

### getStorage()
```solidity
function getStorage(uint256 _ID) external view returns (bool, string memory)
```
**Description:** Returns the CTMRWA1Storage contract address for an ID.  
**Parameters:**
- `_ID` (uint256): RWA identifier
**Returns:** Tuple of (exists, storage address)  

### getSentry()
```solidity
function getSentry(uint256 _ID) external view returns (bool, string memory)
```
**Description:** Returns the CTMRWA1Sentry contract address for an ID.  
**Parameters:**
- `_ID` (uint256): RWA identifier
**Returns:** Tuple of (exists, sentry address)  

### getInvest()
```solidity
function getInvest(uint256 _ID) external view returns (bool, string memory)
```
**Description:** Returns the CTMRWADeployInvest contract address for an ID.  
**Parameters:**
- `_ID` (uint256): RWA identifier
**Returns:** Tuple of (exists, invest address)  

### getIdFromContract()
```solidity
function getIdFromContract(string memory _contractStr) external view returns (bool, uint256)
```
**Description:** Returns the ID for a CTMRWA1 contract address.  
**Parameters:**
- `_contractStr` (string): CTMRWA1 contract address as string
**Returns:** Tuple of (exists, ID)  

### getIdFromDividend()
```solidity
function getIdFromDividend(string memory _dividendStr) external view returns (bool, uint256)
```
**Description:** Returns the ID for a CTMRWA1Dividend contract address.  
**Parameters:**
- `_dividendStr` (string): CTMRWA1Dividend contract address as string
**Returns:** Tuple of (exists, ID)  

### getIdFromStorage()
```solidity
function getIdFromStorage(string memory _storageStr) external view returns (bool, uint256)
```
**Description:** Returns the ID for a CTMRWA1Storage contract address.  
**Parameters:**
- `_storageStr` (string): CTMRWA1Storage contract address as string
**Returns:** Tuple of (exists, ID)  

### getIdFromSentry()
```solidity
function getIdFromSentry(string memory _sentryStr) external view returns (bool, uint256)
```
**Description:** Returns the ID for a CTMRWA1Sentry contract address.  
**Parameters:**
- `_sentryStr` (string): CTMRWA1Sentry contract address as string
**Returns:** Tuple of (exists, ID)  

### getIdFromInvest()
```solidity
function getIdFromInvest(string memory _investStr) external view returns (bool, uint256)
```
**Description:** Returns the ID for a CTMRWADeployInvest contract address.  
**Parameters:**
- `_investStr` (string): CTMRWADeployInvest contract address as string
**Returns:** Tuple of (exists, ID)  

## Cross-Chain Functions

### getContractCrossChain()
```solidity
function getContractCrossChain(uint256 _ID, uint256 _rwaType, uint256 _version) external view returns (bool, address)
```
**Description:** Returns the CTMRWA1 contract address for an ID with type and version validation.  
**Parameters:**
- `_ID` (uint256): RWA identifier
- `_rwaType` (uint256): RWA type
- `_version` (uint256): RWA version
**Returns:** Tuple of (exists, contract address)  

### getDividendCrossChain()
```solidity
function getDividendCrossChain(uint256 _ID, uint256 _rwaType, uint256 _version) external view returns (bool, address)
```
**Description:** Returns the CTMRWA1Dividend contract address for an ID with type and version validation.  
**Parameters:**
- `_ID` (uint256): RWA identifier
- `_rwaType` (uint256): RWA type
- `_version` (uint256): RWA version
**Returns:** Tuple of (exists, dividend address)  

### getStorageCrossChain()
```solidity
function getStorageCrossChain(uint256 _ID, uint256 _rwaType, uint256 _version) external view returns (bool, address)
```
**Description:** Returns the CTMRWA1Storage contract address for an ID with type and version validation.  
**Parameters:**
- `_ID` (uint256): RWA identifier
- `_rwaType` (uint256): RWA type
- `_version` (uint256): RWA version
**Returns:** Tuple of (exists, storage address)  

### getSentryCrossChain()
```solidity
function getSentryCrossChain(uint256 _ID, uint256 _rwaType, uint256 _version) external view returns (bool, address)
```
**Description:** Returns the CTMRWA1Sentry contract address for an ID with type and version validation.  
**Parameters:**
- `_ID` (uint256): RWA identifier
- `_rwaType` (uint256): RWA type
- `_version` (uint256): RWA version
**Returns:** Tuple of (exists, sentry address)  

## Access Control Modifiers

- `onlyGov`: Restricts access to governance
- `onlyDeployer`: Restricts access to CTMRWADeployer

## Events

### LogFallback
```solidity
event LogFallback(bytes4 selector, bytes data, bytes reason);
```
**Description:** Emitted when a fallback function is called with details about the call.

## Security Features

- **Governance Controls**: Comprehensive governance oversight
- **Access Control**: Role-based permissions
- **Upgradeable**: Can be upgraded by governance
- **Bidirectional Mapping**: Secure contract-to-ID resolution
- **Cross-chain Validation**: Type and version checking

## Integration Points

- **CTMRWADeployer**: Contract deployment coordination
- **CTMRWAGateway**: Cross-chain communication
- **CTMRWA1X**: Cross-chain operations
- **C3GovernDapp**: Governance functionality
- **All RWA Components**: Central registry for all contract addresses

## RWA Architecture

Each RWA consists of four core components:

1. **CTMRWA1**: Main semi-fungible token contract
2. **CTMRWA1Dividend**: Dividend distribution management
3. **CTMRWA1Storage**: Decentralized storage management
4. **CTMRWA1Sentry**: Access control and compliance

## Mapping Flow

1. **CTMRWADeployer** deploys RWA components
2. **CTMRWAMap** receives attachment calls for each component
3. **Bidirectional mappings** are created (ID ↔ Contract)
4. **Cross-chain contracts** can resolve addresses using the map
5. **Governance** can update mappings if needed

## Key Features

- **Central Registry**: Single source of truth for all RWA contract addresses
- **Cross-chain Support**: Consistent addressing across multiple chains
- **Type Safety**: Validation of RWA types and versions
- **Bidirectional Lookup**: ID-to-contract and contract-to-ID resolution
- **Governance Control**: Centralized management of mappings
- **Upgradeable**: Can be upgraded to support new contract types
