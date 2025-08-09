# CTMRWAGateway Contract Documentation

## Overview

**Contract Name:** CTMRWAGateway  
**Author:** @Selqui ContinuumDAO  
**License:** BSL-1.1  
**Solidity Version:** 0.8.27

The CTMRWAGateway contract is the gateway between any blockchain that can have an RWA deployed to it. It stores the contract addresses of CTMRWAGateway contracts on other chains, as well as the contract addresses of CTMRWA1X, CTMRWA1StorageManager and CTMRWA1SentryManager contracts. This enables c3calls to be made between all the c3Caller dApps that make up AssetX.

This contract is only deployed ONCE on each chain and manages all CTMRWA1 contract interactions related to cross-chain communication and address mapping.

## Key Features

- **Cross-chain Address Mapping:** Stores contract addresses across multiple chains
- **Multi-contract Support:** Manages addresses for CTMRWA1X, StorageManager, and SentryManager contracts
- **Chain Discovery:** Enables discovery of RWA contracts on different chains
- **Governance Integration:** Built-in governance capabilities through C3GovernDappUpgradeable
- **Upgradeable:** Uses UUPS upgradeable pattern for future improvements
- **Fallback Handling:** Basic fallback mechanism for failed cross-chain calls

## Public Variables

### Chain Information
- **`cIdStr`** (string): String representation of the current chain ID

### Cross-chain Contract Mappings
- **`rwaX`** (mapping(uint256 => mapping(uint256 => ChainContract[]))): rwaType => version => ChainContract array. Addresses of other CTMRWAGateway contracts
- **`rwaXChains`** (mapping(uint256 => mapping(uint256 => string[]))): rwaType => version => chainStr array. ChainIds of other CTMRWA1X contracts
- **`storageManager`** (mapping(uint256 => mapping(uint256 => ChainContract[]))): rwaType => version => chainStr array. Addresses of other CTMRWA1StorageManager contracts
- **`sentryManager`** (mapping(uint256 => mapping(uint256 => ChainContract[]))): rwaType => version => chainStr array. Addresses of other CTMRWA1SentryManager contracts

### Internal Storage
- **`chainContract`** (ChainContract[]): Array holding ChainContract structs for all chains

## Data Structures

### ChainContract
```solidity
struct ChainContract {
    string chainIdStr;    // Chain ID as string
    string contractStr;   // Contract address as string
}
```

## Core Functions

### Initializer

#### `initialize(address _gov, address _c3callerProxy, address _txSender, uint256 _dappID)`
- **Purpose:** Initializes the CTMRWAGateway contract instance
- **Parameters:**
  - `_gov`: Address of the governance contract
  - `_c3callerProxy`: Address of the C3 caller proxy
  - `_txSender`: Address of the transaction sender
  - `_dappID`: ID of the dapp
- **Initialization:**
  - Initializes C3GovernDapp with governance parameters
  - Sets chain ID string representation
  - Adds this contract to the chain contract list

### Chain Contract Management Functions

#### `addChainContract(string[] memory _newChainIdsStr, string[] memory _contractAddrsStr)`
- **Access:** Only callable by governance
- **Purpose:** Adds addresses of CTMRWAGateway contracts on other chains
- **Parameters:**
  - `_newChainIdsStr`: Array of chain IDs as strings
  - `_contractAddrsStr`: Array of contract addresses as strings
- **Requirements:**
  - Arrays must have same length
  - Each string must be 64 characters or less
- **Logic:**
  - Validates input parameters
  - Updates existing entries or adds new ones
  - Converts all strings to lowercase for consistency
- **Returns:** True if addresses were added successfully

#### `getChainContract(string memory _chainIdStr)`
- **Purpose:** Gets the address string for a CTMRWAGateway contract on another chainId
- **Parameters:**
  - `_chainIdStr`: Chain ID converted to a string
- **Returns:** Contract address string for the specified chain ID, or empty string if not found

#### `getChainContract(uint256 _pos)`
- **Purpose:** Gets the chainId and address of a CTMRWAGateway contract at a specific index
- **Parameters:**
  - `_pos`: Index into the stored array
- **Returns:** Chain ID string and contract address string at the specified index

#### `getChainCount()`
- **Purpose:** Gets the number of stored chainIds and CTMRWAGateway pairs
- **Returns:** Total number of stored chain-contract pairs

### CTMRWA1X Management Functions

#### `getAllRwaXChains(uint256 _rwaType, uint256 _version)`
- **Purpose:** Gets all the chainIds of all CTMRWA1X contracts
- **Parameters:**
  - `_rwaType`: Type of RWA (1 for CTMRWA1)
  - `_version`: Version of RWA type (1 for current)
- **Returns:** Array of chain IDs for all CTMRWA1X contracts

#### `existRwaXChain(uint256 _rwaType, uint256 _version, string memory _chainIdStr)`
- **Purpose:** Checks if a stored CTMRWA1X contract exists on a specific chainId
- **Parameters:**
  - `_rwaType`: Type of RWA (1 for CTMRWA1)
  - `_version`: Version of RWA type (1 for current)
  - `_chainIdStr`: Chain ID as string to check
- **Returns:** True if chain ID exists, false otherwise

#### `getAttachedRWAX(uint256 _rwaType, uint256 _version, uint256 _indx)`
- **Purpose:** Gets chainId and CTMRWA1X contract address at a specific index
- **Parameters:**
  - `_rwaType`: Type of RWA (1 for CTMRWA1)
  - `_version`: Version of RWA type (1 for current)
  - `_indx`: Index position to return data from
- **Returns:** Chain ID string and contract address string at the index

#### `getRWAXCount(uint256 _rwaType, uint256 _version)`
- **Purpose:** Gets the total number of stored CTMRWA1X contracts for all chainIds
- **Parameters:**
  - `_rwaType`: Type of RWA (1 for CTMRWA1)
  - `_version`: Version of RWA type (1 for current)
- **Returns:** Total number of stored CTMRWA1X contracts

#### `getAttachedRWAX(uint256 _rwaType, uint256 _version, string memory _chainIdStr)`
- **Purpose:** Gets the attached CTMRWA1X contract address for a specific chainId
- **Parameters:**
  - `_rwaType`: Type of RWA (1 for CTMRWA1)
  - `_version`: Version of RWA type (1 for current)
  - `_chainIdStr`: Chain ID as string being examined
- **Returns:** Success boolean and contract address string

#### `attachRWAX(uint256 _rwaType, uint256 _version, string[] memory _chainIdsStr, string[] memory _rwaXAddrsStr)`
- **Access:** Only callable by governance
- **Purpose:** Attaches new CTMRWA1X contracts for chainIds
- **Parameters:**
  - `_rwaType`: Type of RWA (1 for CTMRWA1)
  - `_version`: Version of RWA type (1 for current)
  - `_chainIdsStr`: Array of chain IDs as strings
  - `_rwaXAddrsStr`: Array of CTMRWA1X contract addresses as strings
- **Requirements:**
  - Arrays must not be empty and must have same length
  - Each string must be 64 characters or less
- **Returns:** True if addresses were added successfully

### Storage Manager Management Functions

#### `getAttachedStorageManager(uint256 _rwaType, uint256 _version, uint256 _indx)`
- **Purpose:** Gets chainId and CTMRWA1StorageManager contract address at a specific index
- **Parameters:**
  - `_rwaType`: Type of RWA (1 for CTMRWA1)
  - `_version`: Version of RWA type (1 for current)
  - `_indx`: Index position to return data from
- **Returns:** Chain ID string and contract address string at the index

#### `getStorageManagerCount(uint256 _rwaType, uint256 _version)`
- **Purpose:** Gets the total number of stored CTMRWA1StorageManager contracts
- **Parameters:**
  - `_rwaType`: Type of RWA (1 for CTMRWA1)
  - `_version`: Version of RWA type (1 for current)
- **Returns:** Total number of stored CTMRWA1StorageManager contracts

#### `getAttachedStorageManager(uint256 _rwaType, uint256 _version, string memory _chainIdStr)`
- **Purpose:** Gets the attached CTMRWA1StorageManager contract address for a specific chainId
- **Parameters:**
  - `_rwaType`: Type of RWA (1 for CTMRWA1)
  - `_version`: Version of RWA type (1 for current)
  - `_chainIdStr`: Chain ID as string being examined
- **Returns:** Success boolean and contract address string

#### `attachStorageManager(uint256 _rwaType, uint256 _version, string[] memory _chainIdsStr, string[] memory _storageManagerAddrsStr)`
- **Access:** Only callable by governance
- **Purpose:** Attaches new CTMRWA1StorageManager contracts for chainIds
- **Parameters:**
  - `_rwaType`: Type of RWA (1 for CTMRWA1)
  - `_version`: Version of RWA type (1 for current)
  - `_chainIdsStr`: Array of chain IDs as strings
  - `_storageManagerAddrsStr`: Array of CTMRWA1StorageManager contract addresses as strings
- **Requirements:**
  - Arrays must not be empty and must have same length
  - Each string must be 64 characters or less
- **Returns:** True if addresses were added successfully

### Sentry Manager Management Functions

#### `getAttachedSentryManager(uint256 _rwaType, uint256 _version, uint256 _indx)`
- **Purpose:** Gets chainId and CTMRWA1SentryManager contract address at a specific index
- **Parameters:**
  - `_rwaType`: Type of RWA (1 for CTMRWA1)
  - `_version`: Version of RWA type (1 for current)
  - `_indx`: Index position to return data from
- **Returns:** Chain ID string and contract address string at the index

#### `getSentryManagerCount(uint256 _rwaType, uint256 _version)`
- **Purpose:** Gets the total number of stored CTMRWA1SentryManager contracts
- **Parameters:**
  - `_rwaType`: Type of RWA (1 for CTMRWA1)
  - `_version`: Version of RWA type (1 for current)
- **Returns:** Total number of stored CTMRWA1SentryManager contracts

#### `getAttachedSentryManager(uint256 _rwaType, uint256 _version, string memory _chainIdStr)`
- **Purpose:** Gets the attached CTMRWA1SentryManager contract address for a specific chainId
- **Parameters:**
  - `_rwaType`: Type of RWA (1 for CTMRWA1)
  - `_version`: Version of RWA type (1 for current)
  - `_chainIdStr`: Chain ID as string being examined
- **Returns:** Success boolean and contract address string

#### `attachSentryManager(uint256 _rwaType, uint256 _version, string[] memory _chainIdsStr, string[] memory _sentryManagerAddrsStr)`
- **Access:** Only callable by governance
- **Purpose:** Attaches new CTMRWA1SentryManager contracts for chainIds
- **Parameters:**
  - `_rwaType`: Type of RWA (1 for CTMRWA1)
  - `_version`: Version of RWA type (1 for current)
  - `_chainIdsStr`: Array of chain IDs as strings
  - `_sentryManagerAddrsStr`: Array of CTMRWA1SentryManager contract addresses as strings
- **Requirements:**
  - Arrays must not be empty and must have same length
  - Each string must be 64 characters or less
- **Returns:** True if addresses were added successfully

## Internal Functions

### Chain Management
- **`_addChainContract(uint256 _chainId, address _contractAddr)`**: Adds a chain contract to the internal array
- **`cID()`**: Returns current chain ID

### Fallback Handling
- **`_c3Fallback(bytes4 _selector, bytes calldata _data, bytes calldata _reason)`**: Handles failed cross-chain calls

## Access Control Modifiers

- **`onlyGov`**: Restricts access to governance functions
- **`initializer`**: Ensures function can only be called once during initialization

## Events

The contract emits events for tracking operations:

- **`LogFallback(bytes4 indexed selector, bytes data, bytes reason)`**: Emitted when a cross-chain call fails
  - `selector`: Function selector that failed
  - `data`: ABI encoded data that was sent
  - `reason`: Revert reason from the failed operation

## Security Features

1. **Governance Integration:** Built-in governance through C3GovernDappUpgradeable
2. **Access Control:** Only governance can modify contract mappings
3. **Upgradeable:** UUPS upgradeable pattern for future improvements
4. **Input Validation:** Extensive validation of input parameters
5. **String Normalization:** All strings converted to lowercase for consistency
6. **Fallback Handling:** Basic fallback mechanism for failed operations

## Integration Points

- **CTMRWA1X**: Cross-chain coordinator contracts on different chains
- **CTMRWA1StorageManager**: Storage management contracts across chains
- **CTMRWA1SentryManager**: Access control contracts across chains
- **C3GovernDapp**: Governance functionality
- **C3Caller**: Cross-chain communication system

## Error Handling

The contract uses custom error types for efficient gas usage and clear error messages:

- **`CTMRWAGateway_LengthMismatch(CTMRWAErrorParam.Input)`**: Thrown when input arrays have different lengths
- **`CTMRWAGateway_InvalidLength(CTMRWAErrorParam.Input)`**: Thrown when input arrays are empty
- **`CTMRWAGateway_InvalidLength(CTMRWAErrorParam.Address)`**: Thrown when address string is too long

## Cross-chain Architecture Role

The CTMRWAGateway contract serves as the central registry for cross-chain RWA operations:

### 1. Address Discovery
- **Purpose:** Enables discovery of RWA contracts on different chains
- **Function:** Stores and retrieves contract addresses across multiple chains
- **Benefit:** Allows seamless cross-chain communication

### 2. Contract Mapping
- **Purpose:** Maps chain IDs to contract addresses
- **Function:** Maintains relationships between chains and their RWA infrastructure
- **Benefit:** Enables targeted cross-chain operations

### 3. Multi-contract Support
- **Purpose:** Manages different types of RWA contracts
- **Function:** Handles CTMRWA1X, StorageManager, and SentryManager contracts
- **Benefit:** Provides comprehensive cross-chain infrastructure

## Use Cases

### Cross-chain Deployment
- **Scenario:** Deploying RWA contracts across multiple chains
- **Process:** Gateway stores addresses of deployed contracts
- **Benefit:** Enables coordinated deployment and management

### Cross-chain Communication
- **Scenario:** Sending messages between chains
- **Process:** Gateway provides target contract addresses
- **Benefit:** Enables reliable cross-chain messaging

### Contract Discovery
- **Scenario:** Finding RWA contracts on different chains
- **Process:** Query gateway for contract addresses
- **Benefit:** Enables dynamic contract discovery

### Infrastructure Management
- **Scenario:** Managing RWA infrastructure across chains
- **Process:** Gateway maintains infrastructure mappings
- **Benefit:** Centralized infrastructure management

## Best Practices

1. **Regular Updates:** Keep contract mappings up to date as new chains are added
2. **Validation:** Always validate contract addresses before using them
3. **Monitoring:** Monitor for failed cross-chain operations
4. **Governance:** Use governance processes for adding new chains
5. **Backup:** Maintain backup records of contract mappings

## Limitations

- **Governance Dependency:** All modifications require governance approval
- **String Storage:** Uses strings for addresses, which is gas-intensive
- **Centralized Control:** Single point of control for cross-chain mappings
- **Manual Updates:** Requires manual updates when new chains are added

## Future Enhancements

Potential improvements to the gateway system:

1. **Automated Discovery:** Implement automatic contract discovery mechanisms
2. **Enhanced Validation:** Add more sophisticated address validation
3. **Performance Optimization:** Optimize storage and retrieval mechanisms
4. **Multi-signature Support:** Add multi-signature requirements for critical updates
5. **Event-driven Updates:** Implement event-driven updates for contract changes
