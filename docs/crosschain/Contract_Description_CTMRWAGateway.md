# CTMRWAGateway Contract Documentation

## Overview

**Contract Name:** CTMRWAGateway  
**File:** `src/crosschain/CTMRWAGateway.sol`  
**License:** BSL-1.1  
**Author:** @Selqui ContinuumDAO

## Contract Description

This contract is the gateway between any blockchain that can have an RWA deployed to it. It stores the contract addresses of CTMRWAGateway contracts on other chains, as well as, for instance, in the case of rwaType 1, the contract addresses of CTMRWA1X, CTMRWA1StorageManager and CTMRWA1SentryManager contracts. This enables c3calls to be made between all the c3Caller DApps that make up AssetX.

This contract is only deployed ONCE on each chain and manages all CTMRWA contract interactions related to cross-chain communication and address mapping.

### Key Features
- Cross-chain address mapping for CTMRWAGateway contracts
- Multi-contract support for CTMRWA1X, StorageManager, and SentryManager contracts
- Chain discovery and contract address resolution
- Governance integration through C3GovernDAppUpgradeable
- UUPS upgradeable pattern for future improvements
- Fallback handling for failed cross-chain calls

## State Variables

- `cIdStr (string)`: String representation of the current chain ID
- `rwaX (mapping(uint256 => mapping(uint256 => ChainContract[])))`: rwaType => version => ChainContract array. Addresses of other CTMRWAGateway contracts
- `rwaXChains (mapping(uint256 => mapping(uint256 => string[])))`: rwaType => version => chainStr array. ChainIds of other CTMRWA1X contracts
- `storageManager (mapping(uint256 => mapping(uint256 => ChainContract[])))`: rwaType => version => chainStr array. Addresses of other CTMRWA1StorageManager contracts
- `sentryManager (mapping(uint256 => mapping(uint256 => ChainContract[])))`: rwaType => version => chainStr array. Addresses of other CTMRWA1SentryManager contracts
- `chainContract (ChainContract[])`: Array holding ChainContract structs for all chains

## Data Structures

### ChainContract
```solidity
struct ChainContract {
    string chainIdStr;    // Chain ID as string
    string contractStr;   // Contract address as string
}
```

## Constructor

```solidity
function initialize(address _gov, address _c3callerProxy, address _txSender, uint256 _dappID)
```
- Initializes the CTMRWAGateway contract instance
- Sets chain ID string representation
- Adds this contract to the chain contract list

## Access Control

- `onlyGov`: Restricts access to governance functions
- `initializer`: Ensures function can only be called once during initialization

## Chain Contract Management

### addChainContract()
```solidity
function addChainContract(string[] memory _newChainIdsStr, string[] memory _contractAddrsStr) external onlyGov
```
Governor function to add addresses of CTMRWAGateway contracts on other chains. All input addresses are arrays of strings.

### getChainContract()
```solidity
function getChainContract(string memory _chainIdStr) external view returns (string memory)
```
Get the address string for a CTMRWAGateway contract on another chainId.

### getChainContract()
```solidity
function getChainContract(uint256 _pos) public view returns (string memory, string memory)
```
Get the chainId and address of a CTMRWAGateway contract at an index _pos.

### getChainCount()
```solidity
function getChainCount() public view returns (uint256)
```
Get the number of stored chainIds and CTMRWAGateway pairs stored.

## CTMRWA1X Management

### getAllRwaXChains()
```solidity
function getAllRwaXChains(uint256 _rwaType, uint256 _version) public view returns (string[] memory)
```
Get all the chainIds of all CTMRWA1X contracts.

### existRwaXChain()
```solidity
function existRwaXChain(uint256 _rwaType, uint256 _version, string memory _chainIdStr) public view returns (bool)
```
Check the existence of a stored CTMRWA1X contract on chainId _chainIdStr.

### getAttachedRWAX()
```solidity
function getAttachedRWAX(uint256 _rwaType, uint256 _version, uint256 _indx) public view returns (string memory, string memory)
```
Return all chainIds as an array, including the local chainId, and the corresponding CTMRWA1X contract addresses as another array at an index position. NOTE: The local chainId is at index 0.

### getRWAXCount()
```solidity
function getRWAXCount(uint256 _rwaType, uint256 _version) public view returns (uint256)
```
Get the total number of stored CTMRWA1X contracts for all chainIds (including this one).

### getAttachedRWAX()
```solidity
function getAttachedRWAX(uint256 _rwaType, uint256 _version, string memory _chainIdStr) public view returns (bool, string memory)
```
Get the attached CTMRWA1X contract address for chainId _chainIdStr as a string, including the local chainId. NOTE: The local chainId is at index 0.

### attachRWAX()
```solidity
function attachRWAX(uint256 _rwaType, uint256 _version, string[] memory _chainIdsStr, string[] memory _rwaXAddrsStr) external onlyGov returns (bool)
```
Governor function. Attach new CTMRWA1X contracts for chainIds, including the local chainId. NOTE: The local chainId is at index 0.

## Storage Manager Management

### getAttachedStorageManager()
```solidity
function getAttachedStorageManager(uint256 _rwaType, uint256 _version, uint256 _indx) public view returns (string memory, string memory)
```
Return all chainIds as an array, including the local chainId, and the corresponding CTMRWA1StorageManager contract addresses as another array at an index position. NOTE: The local chainId is at index 0.

### getStorageManagerCount()
```solidity
function getStorageManagerCount(uint256 _rwaType, uint256 _version) public view returns (uint256)
```
Get the total number of stored CTMRWA1StorageManager contracts for all chainIds (including this one).

### getAttachedStorageManager()
```solidity
function getAttachedStorageManager(uint256 _rwaType, uint256 _version, string memory _chainIdStr) public view returns (bool, string memory)
```
Get the attached CTMRWA1StorageManager contract address for chainId _chainIdStr as a string.

### attachStorageManager()
```solidity
function attachStorageManager(uint256 _rwaType, uint256 _version, string[] memory _chainIdsStr, string[] memory _storageManagerAddrsStr) external onlyGov returns (bool)
```
Governor function. Attach new CTMRWA1StorageManager contracts for chainIds, including the local chainId. NOTE: The local chainId is at index 0.

## Sentry Manager Management

### getAttachedSentryManager()
```solidity
function getAttachedSentryManager(uint256 _rwaType, uint256 _version, uint256 _indx) public view returns (string memory, string memory)
```
Return all chainIds as an array, including the local chainId, and the corresponding CTMRWA1SentryManager contract addresses as another array at an index position. NOTE: The local chainId is at index 0.

### getSentryManagerCount()
```solidity
function getSentryManagerCount(uint256 _rwaType, uint256 _version) public view returns (uint256)
```
Get the total number of stored CTMRWA1SentryManager contracts for all chainIds (including this one).

### getAttachedSentryManager()
```solidity
function getAttachedSentryManager(uint256 _rwaType, uint256 _version, string memory _chainIdStr) public view returns (bool, string memory)
```
Get the attached CTMRWA1SentryManager contract address for chainId _chainIdStr as a string, including the local chainId. NOTE: The local chainId is at index 0.

### attachSentryManager()
```solidity
function attachSentryManager(uint256 _rwaType, uint256 _version, string[] memory _chainIdsStr, string[] memory _sentryManagerAddrsStr) external onlyGov returns (bool)
```
Governor function. Attach new CTMRWA1SentryManager contracts for chainIds, including the local chainId. NOTE: The local chainId is at index 0.

## Internal Functions

### _addChainContract()
```solidity
function _addChainContract(uint256 _chainId, address _contractAddr) internal
```
Adds the address of a CTMRWAGateway contract on another chainId.

### cID()
```solidity
function cID() internal view returns (uint256)
```
Returns current chain ID.

### _c3Fallback()
```solidity
function _c3Fallback(bytes4 _selector, bytes calldata _data, bytes calldata _reason) internal override returns (bool)
```
Fallback function for a failed c3call. Only logs an event at present.

## Events

- `LogFallback(bytes4 selector, bytes data, bytes reason)`: Record that a c3Caller cross-chain transfer failed with fallback

## Security Features

- Governance integration through C3GovernDAppUpgradeable
- UUPS upgradeable pattern for future improvements
- Access control via onlyGov modifier
- Input validation for string lengths and array lengths
- String normalization to lowercase for consistency

## Integration Points

- `CTMRWA1X`: Cross-chain coordinator contracts on different chains
- `CTMRWA1StorageManager`: Storage management contracts across chains
- `CTMRWA1SentryManager`: Access control contracts across chains
- `C3GovernDApp`: Governance functionality
- `C3Caller`: Cross-chain communication system

## Error Handling

The contract uses custom error types for efficient gas usage:

- `CTMRWAGateway_LengthMismatch(CTMRWAErrorParam.Input)`: Thrown when input arrays have different lengths
- `CTMRWAGateway_InvalidLength(CTMRWAErrorParam.Input)`: Thrown when input arrays are empty
- `CTMRWAGateway_InvalidLength(CTMRWAErrorParam.Address)`: Thrown when address string is too long

## Cross-chain Architecture Role

The CTMRWAGateway contract serves as the central registry for cross-chain RWA operations:

### Address Discovery
- Enables discovery of RWA contracts on different chains
- Stores and retrieves contract addresses across multiple chains
- Allows seamless cross-chain communication

### Contract Mapping
- Maps chain IDs to contract addresses
- Maintains relationships between chains and their RWA infrastructure
- Enables targeted cross-chain operations

### Multi-contract Support
- Manages different types of RWA contracts
- Handles CTMRWA1X, StorageManager, and SentryManager contracts
- Provides comprehensive cross-chain infrastructure