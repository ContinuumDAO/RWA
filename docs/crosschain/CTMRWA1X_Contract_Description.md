# CTMRWA1X Contract Documentation

## Overview

**Contract Name:** CTMRWA1X  
**File:** `src/crosschain/CTMRWA1X.sol`  
**License:** BSL-1.1  
**Author:** @Selqui ContinuumDAO  
**Type:** Upgradeable Contract  

## Contract Description

CTMRWA1X is the central cross-chain management contract for Real-World Asset (RWA) tokens. It manages the deployment of CTMRWA1 contracts across multiple chains, handles cross-chain value transfers, and coordinates all CTMRWA1 contract interactions. This contract is deployed only once on each chain and serves as the primary interface for cross-chain operations.

### Key Features
- Cross-chain CTMRWA1 deployment management
- Asset Class (slot) creation across chains
- Cross-chain value minting and transfers
- TokenAdmin (Issuer) management
- Fee management integration
- Governance controls
- Upgradeable architecture
- Reentrancy protection

## State Variables

### Core Addresses
- `gateway` (address): The address of the CTMRWAGateway contract
- `feeManager` (address): The address of the FeeManager contract
- `ctmRwaDeployer` (address): The address of the CTMRWADeployer contract
- `ctmRwa1Map` (address): The address of the CTMRWAMap contract
- `fallbackAddr` (address): The address of the CTMRWA1XFallback contract

### Constants
- `RWA_TYPE` (uint256, constant): RWA type defining CTMRWA1 (1)
- `VERSION` (uint256, constant): Version of this RWA type (1)

### Chain Information
- `cIdStr` (string): String representation of the chain ID

### Access Control
- `isMinter` (mapping): Addresses of routers permitted to bridge tokens cross-chain

### Token Management
- `adminTokens` (mapping): tokenAdmin address => array of CTMRWA1 contracts
- `ownedCtmRwa1` (mapping): owner address => array of CTMRWA1 contracts

## Initialization

The contract uses an `initialize` function instead of a constructor since it's upgradeable:

```solidity
function initialize(
    address _gateway,
    address _feeManager,
    address _gov,
    address _c3callerProxy,
    address _txSender,
    uint256 _dappID
) external initializer
```

### Initialization Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `_gateway` | `address` | The address of the CTMRWAGateway contract |
| `_feeManager` | `address` | The address of the FeeManager contract |
| `_gov` | `address` | The governance address |
| `_c3callerProxy` | `address` | The C3Caller proxy address |
| `_txSender` | `address` | The transaction sender address |
| `_dappID` | `uint256` | The dApp ID |

### Initialization Behavior

During initialization, the contract:
1. Initializes ReentrancyGuard
2. Initializes C3GovernDapp with governance parameters
3. Sets the gateway and feeManager addresses
4. Sets the chain ID string
5. Sets the contract itself as a minter

## Governance Functions

### changeMinterStatus()
```solidity
function changeMinterStatus(address _minter, bool _set) external onlyGov
```
**Description:** Adds or removes a router able to bridge tokens cross-chain.  
**Parameters:**
- `_minter` (address): The router address
- `_set` (bool): Boolean setting or un-setting minter
**Access:** Only governance  
**Effects:** Updates minter status  

### changeFeeManager()
```solidity
function changeFeeManager(address _feeManager) external onlyGov
```
**Description:** Changes to a new FeeManager contract.  
**Parameters:**
- `_feeManager` (address): Address of the new FeeManager contract
**Access:** Only governance  
**Effects:** Updates feeManager address  

### setGateway()
```solidity
function setGateway(address _gateway) external onlyGov
```
**Description:** Changes to a new CTMRWAGateway contract.  
**Parameters:**
- `_gateway` (address): Address of the new CTMRWAGateway contract
**Access:** Only governance  
**Effects:** Updates gateway address  

### setCtmRwaMap()
```solidity
function setCtmRwaMap(address _map) external onlyGov
```
**Description:** Changes to a new CTMRWAMap contract and resets deployer, gateway, and rwaX addresses.  
**Parameters:**
- `_map` (address): Address of the new CTMRWAMap contract
**Access:** Only governance  
**Effects:** Updates map address and resets related addresses  

### setCtmRwaDeployer()
```solidity
function setCtmRwaDeployer(address _deployer) external onlyGov
```
**Description:** Changes to a new CTMRWADeployer.  
**Parameters:**
- `_deployer` (address): Address of the new CTMRWADeployer contract
**Access:** Only governance  
**Effects:** Updates deployer address  

### setFallback()
```solidity
function setFallback(address _fallbackAddr) external onlyGov
```
**Description:** Changes to a new CTMRWA1Fallback contract.  
**Parameters:**
- `_fallbackAddr` (address): Address of the new CTMRWA1Fallback contract
**Access:** Only governance  
**Effects:** Updates fallback address and minter status  

## Cross-Chain Deployment Functions

### deployCtmRwa1()
```solidity
function deployCtmRwa1(
    address _tokenAdmin,
    string memory _tokenName,
    string memory _symbol,
    uint8 _decimals,
    string memory _baseURI,
    uint256[] memory _slotNumbers,
    string[] memory _slotNames
) external payable returns (address)
```
**Description:** Deploys a new CTMRWA1 contract across all chains.  
**Parameters:**
- `_tokenAdmin` (address): Token administrator address
- `_tokenName` (string): Token name
- `_symbol` (string): Token symbol
- `_decimals` (uint8): Number of decimals
- `_baseURI` (string): Base URI for metadata
- `_slotNumbers` (uint256[]): Array of slot numbers
- `_slotNames` (string[]): Array of slot names
**Returns:** Address of the deployed contract  
**Effects:** Deploys CTMRWA1 on all chains  

### deployCtmRwa1Local()
```solidity
function deployCtmRwa1Local(
    address _tokenAdmin,
    string memory _tokenName,
    string memory _symbol,
    uint8 _decimals,
    string memory _baseURI,
    uint256[] memory _slotNumbers,
    string[] memory _slotNames
) external payable returns (address)
```
**Description:** Deploys a new CTMRWA1 contract on the local chain only.  
**Parameters:** Same as deployCtmRwa1  
**Returns:** Address of the deployed contract  
**Effects:** Deploys CTMRWA1 on local chain only  

## Cross-Chain Value Transfer Functions

### transferValueX()
```solidity
function transferValueX(
    uint256 _fromTokenId,
    string memory _toChainId,
    address _to,
    uint256 _value,
    address _feeToken
) external payable returns (bool)
```
**Description:** Transfers value cross-chain from one token to an address.  
**Parameters:**
- `_fromTokenId` (uint256): Source token ID
- `_toChainId` (string): Destination chain ID
- `_to` (address): Recipient address
- `_value` (uint256): Value to transfer
- `_feeToken` (address): Fee token address
**Returns:** True if successful  
**Effects:** Transfers value across chains  

### transferValueXToToken()
```solidity
function transferValueXToToken(
    uint256 _fromTokenId,
    string memory _toChainId,
    uint256 _toTokenId,
    uint256 _value,
    address _feeToken
) external payable returns (bool)
```
**Description:** Transfers value cross-chain between tokens.  
**Parameters:**
- `_fromTokenId` (uint256): Source token ID
- `_toChainId` (string): Destination chain ID
- `_toTokenId` (uint256): Destination token ID
- `_value` (uint256): Value to transfer
- `_feeToken` (address): Fee token address
**Returns:** True if successful  
**Effects:** Transfers value between tokens across chains  

## Minting Functions

### mintValueX()
```solidity
function mintValueX(
    string memory _chainId,
    uint256 _toTokenId,
    uint256 _slot,
    uint256 _value,
    address _feeToken
) external payable returns (bool)
```
**Description:** Mints value to a token on a specific chain.  
**Parameters:**
- `_chainId` (string): Target chain ID
- `_toTokenId` (uint256): Target token ID
- `_slot` (uint256): Slot number
- `_value` (uint256): Value to mint
- `_feeToken` (address): Fee token address
**Returns:** True if successful  
**Effects:** Mints value on target chain  

### mintTokenX()
```solidity
function mintTokenX(
    string memory _chainId,
    address _to,
    uint256 _slot,
    string memory _slotName,
    uint256 _value,
    address _feeToken
) external payable returns (bool)
```
**Description:** Mints a new token on a specific chain.  
**Parameters:**
- `_chainId` (string): Target chain ID
- `_to` (address): Recipient address
- `_slot` (uint256): Slot number
- `_slotName` (string): Slot name
- `_value` (uint256): Initial value
- `_feeToken` (address): Fee token address
**Returns:** True if successful  
**Effects:** Mints new token on target chain  

## Administrative Functions

### changeAdminX()
```solidity
function changeAdminX(
    string memory _chainId,
    address _ctmRwa1Addr,
    address _newAdmin,
    address _feeToken
) external payable returns (bool)
```
**Description:** Changes the tokenAdmin across chains.  
**Parameters:**
- `_chainId` (string): Target chain ID
- `_ctmRwa1Addr` (address): CTMRWA1 contract address
- `_newAdmin` (address): New admin address
- `_feeToken` (address): Fee token address
**Returns:** True if successful  
**Effects:** Changes admin on target chain  

### createSlotX()
```solidity
function createSlotX(
    string memory _chainId,
    address _ctmRwa1Addr,
    uint256 _slot,
    string memory _slotName,
    address _feeToken
) external payable returns (bool)
```
**Description:** Creates a new slot on a specific chain.  
**Parameters:**
- `_chainId` (string): Target chain ID
- `_ctmRwa1Addr` (address): CTMRWA1 contract address
- `_slot` (uint256): Slot number
- `_slotName` (string): Slot name
- `_feeToken` (address): Fee token address
**Returns:** True if successful  
**Effects:** Creates slot on target chain  

## Query Functions

### getAdminTokens()
```solidity
function getAdminTokens(address _tokenAdmin) external view returns (address[] memory)
```
**Description:** Returns all CTMRWA1 contracts controlled by a tokenAdmin.  
**Parameters:**
- `_tokenAdmin` (address): Token admin address
**Returns:** Array of CTMRWA1 contract addresses  

### getOwnedCtmRwa1()
```solidity
function getOwnedCtmRwa1(address _owner) external view returns (address[] memory)
```
**Description:** Returns all CTMRWA1 contracts where an address owns tokens.  
**Parameters:**
- `_owner` (address): Owner address
**Returns:** Array of CTMRWA1 contract addresses  

### isMinter()
```solidity
function isMinter(address _minter) external view returns (bool)
```
**Description:** Checks if an address is a minter.  
**Parameters:**
- `_minter` (address): Address to check
**Returns:** True if address is a minter  

## Access Control Modifiers

- `onlyGov`: Restricts access to governance
- `onlyMinter`: Restricts access to authorized minters
- `nonReentrant`: Prevents reentrancy attacks

## Events

The contract emits various events for:
- Cross-chain deployments
- Value transfers
- Minting operations
- Administrative changes
- Slot creation
- Fee payments

## Security Features

- **ReentrancyGuard**: Protects against reentrancy attacks
- **Governance Controls**: Comprehensive governance oversight
- **Access Control**: Role-based permissions
- **Fee Management**: Integrated fee collection and validation
- **Cross-Chain Validation**: Secure cross-chain operations
- **Upgradeable**: Can be upgraded by governance

## Integration Points

- **CTMRWAGateway**: Cross-chain communication
- **CTMRWAMap**: Component address mapping
- **CTMRWADeployer**: Contract deployment
- **FeeManager**: Fee collection and management
- **CTMRWA1XFallback**: Failed operation handling
- **C3GovernDapp**: Governance functionality
