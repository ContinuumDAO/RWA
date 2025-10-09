# CTMRWADeployer Contract Documentation

## Overview

**Contract Name:** CTMRWADeployer  
**File:** `src/deployment/CTMRWADeployer.sol`  
**License:** BSL-1.1  
**Author:** @Selqui ContinuumDAO  
**Type:** Upgradeable Contract  

## Contract Description

CTMRWADeployer is the central deployment coordinator for Real-World Asset (RWA) token contracts. It manages the deployment of the complete suite of contracts required for each RWA across multiple chains. The contract uses CREATE2 for deterministic deployments and coordinates with various factory contracts to deploy CTMRWA1, CTMRWA1Storage, CTMRWA1Dividend, and CTMRWA1Sentry contracts.

### Key Features
- Centralized deployment coordination
- CREATE2 deterministic deployments
- Multi-chain RWA deployment management
- Factory contract management
- Governance-controlled upgrades
- Cross-chain integration

## State Variables

### Core Addresses
- `gateway` (address): The address of the CTMRWAGateway contract
- `feeManager` (address): The address of the FeeManager contract
- `rwaX` (address): The address of the CTMRWA1X contract
- `ctmRwaMap` (address): The address of the CTMRWAMap contract
- `erc20Deployer` (address): The address of the CTMRWAERC20Deployer contract
- `deployInvest` (address): The address of the CTMRWADeployInvest contract

### Factory Storage
- `tokenFactory` (mapping): Storage for CTMRWA1TokenFactory contract addresses
- `dividendFactory` (mapping): Storage for CTMRWA1DividendFactory contract addresses
- `storageFactory` (mapping): Storage for CTMRWA1StorageManager contract addresses
- `sentryFactory` (mapping): Storage for CTMRWA1SentryManager contract addresses

## Initialization

The contract uses an `initialize` function instead of a constructor since it's upgradeable:

```solidity
function initialize(
    address _gov,
    address _gateway,
    address _feeManager,
    address _rwaX,
    address _map,
    address _c3callerProxy,
    address _txSender,
    uint256 _dappID
) external initializer
```

### Initialization Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `_gov` | `address` | The governance address |
| `_gateway` | `address` | The address of the CTMRWAGateway contract |
| `_feeManager` | `address` | The address of the FeeManager contract |
| `_rwaX` | `address` | The address of the CTMRWA1X contract |
| `_map` | `address` | The address of the CTMRWAMap contract |
| `_c3callerProxy` | `address` | The C3Caller proxy address |
| `_txSender` | `address` | The transaction sender address |
| `_dappID` | `uint256` | The dApp ID |

### Initialization Behavior

During initialization, the contract:
1. Initializes C3GovernDapp with governance parameters
2. Sets the gateway, feeManager, rwaX, and ctmRwaMap addresses

## Governance Functions

### setGateway()
```solidity
function setGateway(address _gateway) external onlyGov
```
**Description:** Changes the CTMRWAGateway contract address.  
**Parameters:**
- `_gateway` (address): New gateway address
**Access:** Only governance  
**Effects:** Updates gateway address  

### setFeeManager()
```solidity
function setFeeManager(address _feeManager) external onlyGov
```
**Description:** Changes the FeeManager contract address.  
**Parameters:**
- `_feeManager` (address): New fee manager address
**Access:** Only governance  
**Effects:** Updates feeManager address  

### setRwaX()
```solidity
function setRwaX(address _rwaX) external onlyGov
```
**Description:** Changes the CTMRWA1X contract address.  
**Parameters:**
- `_rwaX` (address): New rwaX address
**Access:** Only governance  
**Effects:** Updates rwaX address  

### setCtmRwaMap()
```solidity
function setCtmRwaMap(address _map) external onlyGov
```
**Description:** Changes the CTMRWAMap contract address.  
**Parameters:**
- `_map` (address): New map address
**Access:** Only governance  
**Effects:** Updates ctmRwaMap address  

### setErc20Deployer()
```solidity
function setErc20Deployer(address _erc20Deployer) external onlyGov
```
**Description:** Changes the CTMRWAERC20Deployer contract address.  
**Parameters:**
- `_erc20Deployer` (address): New ERC20 deployer address
**Access:** Only governance  
**Effects:** Updates erc20Deployer address  

### setDeployInvest()
```solidity
function setDeployInvest(address _deployInvest) external onlyGov
```
**Description:** Changes the CTMRWADeployInvest contract address.  
**Parameters:**
- `_deployInvest` (address): New deploy invest address
**Access:** Only governance  
**Effects:** Updates deployInvest address  

## Factory Management Functions

### setTokenFactory()
```solidity
function setTokenFactory(uint256 _rwaType, uint256 _version, address _factory) external onlyGov
```
**Description:** Sets the CTMRWA1TokenFactory address for a specific RWA type and version.  
**Parameters:**
- `_rwaType` (uint256): RWA type
- `_version` (uint256): Version number
- `_factory` (address): Factory contract address
**Access:** Only governance  
**Effects:** Updates tokenFactory mapping  

### setDividendFactory()
```solidity
function setDividendFactory(uint256 _rwaType, uint256 _version, address _factory) external onlyGov
```
**Description:** Sets the CTMRWA1DividendFactory address for a specific RWA type and version.  
**Parameters:**
- `_rwaType` (uint256): RWA type
- `_version` (uint256): Version number
- `_factory` (address): Factory contract address
**Access:** Only governance  
**Effects:** Updates dividendFactory mapping  

### setStorageFactory()
```solidity
function setStorageFactory(uint256 _rwaType, uint256 _version, address _factory) external onlyGov
```
**Description:** Sets the CTMRWA1StorageManager address for a specific RWA type and version.  
**Parameters:**
- `_rwaType` (uint256): RWA type
- `_version` (uint256): Version number
- `_factory` (address): Factory contract address
**Access:** Only governance  
**Effects:** Updates storageFactory mapping  

### setSentryFactory()
```solidity
function setSentryFactory(uint256 _rwaType, uint256 _version, address _factory) external onlyGov
```
**Description:** Sets the CTMRWA1SentryManager address for a specific RWA type and version.  
**Parameters:**
- `_rwaType` (uint256): RWA type
- `_version` (uint256): Version number
- `_factory` (address): Factory contract address
**Access:** Only governance  
**Effects:** Updates sentryFactory mapping  

## Deployment Functions

### deploy()
```solidity
function deploy(
    uint256 _rwaType,
    uint256 _version,
    uint256 _ID,
    address _tokenAdmin,
    bytes memory _deployData
) external onlyRwaX returns (address, address, address, address)
```
**Description:** Deploys the complete suite of contracts for an RWA.  
**Parameters:**
- `_rwaType` (uint256): RWA type
- `_version` (uint256): Version number
- `_ID` (uint256): Unique RWA identifier
- `_tokenAdmin` (address): Token administrator address
- `_deployData` (bytes): Encoded deployment data
**Access:** Only CTMRWA1X  
**Returns:** Tuple of deployed contract addresses (token, storage, dividend, sentry)  
**Effects:** Deploys all required contracts  

## Query Functions

### tokenFactory()
```solidity
function tokenFactory(uint256 _rwaType, uint256 _version) external view returns (address)
```
**Description:** Returns the CTMRWA1TokenFactory address for a specific RWA type and version.  
**Parameters:**
- `_rwaType` (uint256): RWA type
- `_version` (uint256): Version number
**Returns:** Factory contract address  

### dividendFactory()
```solidity
function dividendFactory(uint256 _rwaType, uint256 _version) external view returns (address)
```
**Description:** Returns the CTMRWA1DividendFactory address for a specific RWA type and version.  
**Parameters:**
- `_rwaType` (uint256): RWA type
- `_version` (uint256): Version number
**Returns:** Factory contract address  

### storageFactory()
```solidity
function storageFactory(uint256 _rwaType, uint256 _version) external view returns (address)
```
**Description:** Returns the CTMRWA1StorageManager address for a specific RWA type and version.  
**Parameters:**
- `_rwaType` (uint256): RWA type
- `_version` (uint256): Version number
**Returns:** Factory contract address  

### sentryFactory()
```solidity
function sentryFactory(uint256 _rwaType, uint256 _version) external view returns (address)
```
**Description:** Returns the CTMRWA1SentryManager address for a specific RWA type and version.  
**Parameters:**
- `_rwaType` (uint256): RWA type
- `_version` (uint256): Version number
**Returns:** Factory contract address  

### erc20Deployer()
```solidity
function erc20Deployer() external view returns (address)
```
**Description:** Returns the CTMRWAERC20Deployer contract address.  
**Returns:** ERC20 deployer address  

## Access Control Modifiers

- `onlyGov`: Restricts access to governance
- `onlyRwaX`: Restricts access to CTMRWA1X contract

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
- **CREATE2**: Deterministic deployments
- **Factory Pattern**: Modular deployment architecture

## Integration Points

- **CTMRWA1X**: Main deployment coordinator
- **CTMRWAMap**: Contract address mapping
- **CTMRWAGateway**: Cross-chain communication
- **FeeManager**: Fee collection and management
- **Factory Contracts**: Specialized deployment contracts
- **C3GovernDapp**: Governance functionality

## Deployment Flow

1. **CTMRWA1X** calls `deploy()` with RWA parameters
2. **CTMRWADeployer** retrieves factory addresses for the RWA type and version
3. **Factory contracts** deploy the required components using CREATE2
4. **Deployed addresses** are returned to CTMRWA1X
5. **CTMRWAMap** stores the contract addresses for cross-chain reference

## Factory Contracts

The deployer coordinates with four main factory contracts:

1. **CTMRWA1TokenFactory**: Deploys CTMRWA1 tokens
2. **CTMRWA1StorageManager**: Deploys CTMRWA1Storage contracts
3. **CTMRWA1DividendFactory**: Deploys CTMRWA1Dividend contracts
4. **CTMRWA1SentryManager**: Deploys CTMRWA1Sentry contracts

Each factory can be updated independently by governance to support new RWA types or versions.
