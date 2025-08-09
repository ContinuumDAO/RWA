# CTMRWA1X Contract Documentation

## Overview

**Contract Name:** CTMRWA1X  
**Author:** @Selqui ContinuumDAO  
**License:** BSL-1.1  
**Solidity Version:** 0.8.27

The CTMRWA1X contract manages the basic cross-chain deployment of CTMRWA1 as well as the creation of Asset Classes (slots), minting value on local chains, changing tokenAdmin (Issuer), and transferring value cross-chain.

This contract is only deployed ONCE on each chain and manages all CTMRWA1 contract interactions. It serves as the central coordination point for cross-chain RWA operations.

## Key Features

- **Cross-chain Deployment:** Manages deployment of CTMRWA1 contracts across multiple chains
- **Asset Class Management:** Creates and manages slots (Asset Classes) across chains
- **Cross-chain Transfers:** Enables transfer of tokens and values between chains
- **Admin Management:** Handles tokenAdmin changes across multiple chains
- **Fee Management:** Integrates with FeeManager for cross-chain operations
- **Governance Integration:** Built-in governance capabilities through C3GovernDappUpgradeable
- **Upgradeable:** Uses UUPS upgradeable pattern for future improvements

## Public Variables

### Core Identifiers
- **`RWA_TYPE`** (uint256, constant): RWA type defining CTMRWA1 (value: 1)
- **`VERSION`** (uint256, constant): Single integer version of this RWA type (value: 1)

### Contract Addresses
- **`gateway`** (address): Address of the CTMRWAGateway contract
- **`feeManager`** (address): Address of the FeeManager contract
- **`ctmRwaDeployer`** (address): Address of the CTMRWADeployer contract
- **`ctmRwa1Map`** (address): Address of the CTMRWAMap contract
- **`fallbackAddr`** (address): Address of the CTMRWA1XFallback contract

### Chain Information
- **`cIdStr`** (string): String representation of the chainID

### Access Control
- **`isMinter`** (mapping(address => bool)): Addresses of routers, including ContinuumDAO, permitted to bridge tokens cross-chain

### Token Management
- **`adminTokens`** (mapping(address => address[])): tokenAdmin address => array of CTMRWA1 contracts. List of contracts controlled by each tokenAdmin
- **`ownedCtmRwa1`** (mapping(address => address[])): owner address => array of CTMRWA1 contracts. List of CTMRWA1 contracts that an owner address has one or more tokenIds

## Core Functions

### Initializer

#### `initialize(address _gateway, address _feeManager, address _gov, address _c3callerProxy, address _txSender, uint256 _dappID)`
- **Purpose:** Initializes the CTMRWA1X contract instance
- **Parameters:**
  - `_gateway`: Address of the CTMRWAGateway contract
  - `_feeManager`: Address of the FeeManager contract
  - `_gov`: Address of the governance contract
  - `_c3callerProxy`: Address of the C3 caller proxy
  - `_txSender`: Address of the transaction sender
  - `_dappID`: ID of the dapp
- **Initialization:**
  - Initializes ReentrancyGuard
  - Initializes C3GovernDapp with governance parameters
  - Sets gateway and feeManager addresses
  - Sets chain ID string representation
  - Sets this contract as a minter

### Governance Functions

#### `changeMinterStatus(address _minter, bool _set)`
- **Access:** Only callable by governance
- **Purpose:** Adds or removes a router able to bridge tokens or value cross-chain
- **Parameters:**
  - `_minter`: Router address to modify
  - `_set`: Boolean setting or un-setting minter status
- **Security:** Cannot set this contract or fallback address as minter

#### `changeFeeManager(address _feeManager)`
- **Access:** Only callable by governance
- **Purpose:** Changes to a new FeeManager contract
- **Parameters:**
  - `_feeManager`: Address of the new FeeManager contract

#### `setGateway(address _gateway)`
- **Access:** Only callable by governance
- **Purpose:** Changes to a new CTMRWAGateway contract
- **Parameters:**
  - `_gateway`: Address of the new CTMRWAGateway contract

#### `setCtmRwaMap(address _map)`
- **Access:** Only callable by governance
- **Purpose:** Changes to a new CTMRWAMap contract and resets deployer, gateway and rwaX addresses
- **Parameters:**
  - `_map`: Address of the new CTMRWAMap contract
- **Requirements:** ctmRwaDeployer must be set

#### `setCtmRwaDeployer(address _deployer)`
- **Access:** Only callable by governance
- **Purpose:** Changes to a new CTMRWADeployer
- **Parameters:**
  - `_deployer`: Address of the new CTMRWADeployer contract

#### `setFallback(address _fallbackAddr)`
- **Access:** Only callable by governance
- **Purpose:** Changes to a new CTMRWA1Fallback contract
- **Parameters:**
  - `_fallbackAddr`: Address of the new CTMRWA1Fallback contract
- **Security:** Cannot set this contract as fallback address

### Deployment Functions

#### `deployAllCTMRWA1X(bool _includeLocal, uint256 _existingID, uint256 _rwaType, uint256 _version, string memory _tokenName, string memory _symbol, uint8 _decimals, string memory _baseURI, string[] memory _toChainIdsStr, string memory _feeTokenStr)`
- **Purpose:** Deploy or extend the deployment of an RWA
- **Parameters:**
  - `_includeLocal`: If TRUE, deploys new CTMRWA1 on local chain. If FALSE, extends existing RWA
  - `_existingID`: Set to ZERO for new RWA, or existing ID to extend
  - `_rwaType`: Type of RWA (1 for CTMRWA1)
  - `_version`: Version of RWA (1 for current)
  - `_tokenName`: Name of RWA (10-512 characters)
  - `_symbol`: Symbol for RWA (1-6 characters, uppercase, no spaces)
  - `_decimals`: Decimal precision (0-18)
  - `_baseURI`: Storage method ("GFLD", "IPFS", or "NONE")
  - `_toChainIdsStr`: Array of chainID strings to deploy to
  - `_feeTokenStr`: Fee token address as string
- **Returns:** ID of the deployed/extended RWA
- **Logic:**
  - If `_includeLocal` is TRUE: Creates new RWA with generated ID
  - If `_includeLocal` is FALSE: Extends existing RWA to other chains
  - Validates parameters and pays fees
  - Deploys to specified chains

#### `deployCTMRWA1(string memory _newAdminStr, uint256 _ID, string memory _tokenName, string memory _symbol, uint8 _decimals, string memory _baseURI, uint256[] memory _slotNumbers, string[] memory _slotNames)`
- **Access:** Only callable by MPC network
- **Purpose:** Deploys new CTMRWA1 instance on destination chain
- **Parameters:**
  - `_newAdminStr`: New admin address as string
  - `_ID`: RWA ID
  - `_tokenName`, `_symbol`, `_decimals`, `_baseURI`: Token metadata
  - `_slotNumbers`, `_slotNames`: Slot configuration
- **Returns:** True if deployment successful

### Admin Management Functions

#### `changeTokenAdmin(string memory _newAdminStr, string[] memory _toChainIdsStr, uint256 _ID, string memory _feeTokenStr)`
- **Purpose:** Changes tokenAdmin address across multiple chains
- **Parameters:**
  - `_newAdminStr`: New tokenAdmin as string
  - `_toChainIdsStr`: Array of chainID strings (includes local chain)
  - `_ID`: RWA ID
  - `_feeTokenStr`: Fee token address as string
- **Access:** Only callable by current tokenAdmin
- **Note:** To lock RWA, set `_newAdminStr` to `address(0).toHexString()`
- **Returns:** True if change successful

#### `adminX(uint256 _ID, string memory _oldAdminStr, string memory _newAdminStr)`
- **Access:** Only callable by MPC network
- **Purpose:** Changes tokenAdmin of RWA on a specific chain
- **Parameters:**
  - `_ID`: RWA ID
  - `_oldAdminStr`: Old admin address as string
  - `_newAdminStr`: New admin address as string
- **Returns:** True if change successful

### Minting Functions

#### `mintNewTokenValueLocal(address _toAddress, uint256 _toTokenId, uint256 _slot, uint256 _value, uint256 _ID, string memory _feeTokenStr)`
- **Purpose:** Mints new fungible value for an RWA to an Asset Class (slot)
- **Parameters:**
  - `_toAddress`: Address to mint new value for
  - `_toTokenId`: TokenId to add value to (0 for new tokenId)
  - `_slot`: Asset Class (slot) for minting
  - `_value`: Fungible value to create
  - `_ID`: RWA ID
  - `_feeTokenStr`: Fee token address as string
- **Access:** Only callable by tokenAdmin
- **Note:** Not a cross-chain function - must switch to each chain
- **Returns:** New tokenId that was minted

#### `mintX(uint256 _ID, string memory _fromAddressStr, string memory _toAddressStr, uint256 _slot, uint256 _balance)`
- **Access:** Only callable by MPC network
- **Purpose:** Mints value in a new slot to an address (creates new tokenId)
- **Parameters:**
  - `_ID`: RWA ID
  - `_fromAddressStr`: Source address as string
  - `_toAddressStr`: Destination address as string
  - `_slot`: Slot number
  - `_balance`: Balance to mint
- **Returns:** True if minting successful

### Slot Management Functions

#### `createNewSlot(uint256 _ID, uint256 _slot, string memory _slotName, string[] memory _toChainIdsStr, string memory _feeTokenStr)`
- **Purpose:** Creates a new Asset Class (slot) across multiple chains
- **Parameters:**
  - `_ID`: RWA ID
  - `_slot`: New slot number (must be unique)
  - `_slotName`: Name of new Asset Class (max 256 characters)
  - `_toChainIdsStr`: Array of chainID strings (includes local chain)
  - `_feeTokenStr`: Fee token address as string
- **Access:** Only callable by tokenAdmin
- **Returns:** True if slot creation successful

#### `createNewSlotX(uint256 _ID, string memory _fromAddressStr, uint256 _slot, string memory _slotName)`
- **Access:** Only callable by MPC network
- **Purpose:** Creates new slot for RWA on a specific chain
- **Parameters:**
  - `_ID`: RWA ID
  - `_fromAddressStr`: Source address as string
  - `_slot`: Slot number
  - `_slotName`: Slot name
- **Returns:** True if slot creation successful

### Cross-chain Transfer Functions

#### `transferPartialTokenX(uint256 _fromTokenId, string memory _toAddressStr, string memory _toChainIdStr, uint256 _value, uint256 _ID, string memory _feeTokenStr)`
- **Purpose:** Transfers part of fungible balance of a tokenId to another chain
- **Parameters:**
  - `_fromTokenId`: TokenId to transfer from
  - `_toAddressStr`: Destination address as string
  - `_toChainIdStr`: Destination chainID as string
  - `_value`: Fungible value to send
  - `_ID`: RWA ID
  - `_feeTokenStr`: Fee token address as string
- **Access:** Owner or approved operator
- **Note:** Creates new tokenId on destination chain
- **Returns:** New tokenId that was minted

#### `transferWholeTokenX(string memory _fromAddrStr, string memory _toAddressStr, string memory _toChainIdStr, uint256 _fromTokenId, uint256 _ID, string memory _feeTokenStr)`
- **Purpose:** Transfers a whole tokenId to another chain
- **Parameters:**
  - `_fromAddrStr`: Source address as string
  - `_toAddressStr`: Destination address as string
  - `_toChainIdStr`: Destination chainID as string
  - `_fromTokenId`: TokenId to transfer
  - `_ID`: RWA ID
  - `_feeTokenStr`: Fee token address as string
- **Access:** Owner or approved operator

### Query Functions

#### `getAllTokensByAdminAddress(address _admin)`
- **Purpose:** Gets list of CTMRWA1 addresses controlled by an admin
- **Parameters:**
  - `_admin`: TokenAdmin address to check
- **Returns:** Array of CTMRWA1 addresses

#### `getAllTokensByOwnerAddress(address _owner)`
- **Purpose:** Gets list of CTMRWA1 addresses owned by an address
- **Parameters:**
  - `_owner`: Owner address to check
- **Returns:** Array of CTMRWA1 addresses

#### `isOwnedToken(address _owner, address _ctmRwa1Addr)`
- **Purpose:** Checks if address has any tokenIds in a CTMRWA1
- **Parameters:**
  - `_owner`: Address to check
  - `_ctmRwa1Addr`: CTMRWA1 address to check
- **Returns:** True if address has tokenIds, false otherwise

## Internal Functions

### Deployment Functions
- **`_deployCTMRWA1Local(...)`**: Deploys new RWA on local chain
- **`_deployCTMRWA1X(...)`**: Deploys CTMRWA1 instance on destination chain

### Admin Management
- **`_changeAdmin(address _currentAdmin, address _newAdmin, uint256 _ID)`**: Changes tokenAdmin across all related contracts
- **`swapAdminAddress(address _oldAdmin, address _newAdmin, address _ctmRwa1Addr)`**: Swaps admin addresses in tracking arrays

### Transfer Functions
- **`_updateOwnedCtmRwa1(address _ownerAddr, address _tokenAddr)`**: Updates list of CTMRWA1 addresses owned by an address

### Utility Functions
- **`_getTokenAddr(uint256 _ID)`**: Gets CTMRWA1 address and string version for an ID
- **`_getRWAX(string memory _toChainIdStr)`**: Gets corresponding CTMRWA1X address on another chain
- **`_checkTokenAdmin(address _tokenAddr)`**: Checks and returns tokenAdmin for a CTMRWA1
- **`_payFee(FeeType _feeType, string memory _feeTokenStr, string[] memory _toChainIdsStr, bool _includeLocal)`**: Pays fees for operations
- **`cID()`**: Returns current chain ID
- **`_c3Fallback(bytes4 _selector, bytes calldata _data, bytes calldata _reason)`**: Handles cross-chain call failures

## Access Control Modifiers

- **`onlyGov`**: Restricts access to governance functions
- **`onlyCaller`**: Restricts access to MPC network calls
- **`initializer`**: Ensures function can only be called once during initialization

## Events

The contract emits various events for tracking operations:

- **`CreateNewCTMRWA1(uint256 indexed ID)`**: New CTMRWA1 created
- **`DeployCTMRWA1(uint256 indexed ID, string toChainIdStr)`**: CTMRWA1 deployed to chain
- **`ChangingAdmin(uint256 indexed ID, string toChainIdStr)`**: Admin change initiated
- **`AdminChanged(uint256 indexed ID, string newAdminStr)`**: Admin change completed
- **`CreateSlot(uint256 indexed ID, uint256 indexed slot, string toChainIdStr)`**: Slot creation initiated
- **`SlotCreated(uint256 indexed ID, uint256 indexed slot, string fromChainIdStr)`**: Slot creation completed
- **`Minting(uint256 indexed ID, string toAddressStr, string toChainIdStr)`**: Cross-chain minting initiated
- **`Minted(uint256 indexed ID, string fromChainIdStr, string fromAddressStr)`**: Cross-chain minting completed

## Security Features

1. **Reentrancy Protection:** Uses OpenZeppelin's ReentrancyGuardUpgradeable
2. **Access Control:** Comprehensive modifier system for different roles
3. **Governance Integration:** Built-in governance through C3GovernDappUpgradeable
4. **Upgradeable:** UUPS upgradeable pattern for future improvements
5. **Fee Management:** Integrated fee system for cross-chain operations
6. **Fallback Handling:** Dedicated fallback contract for failed cross-chain calls
7. **Parameter Validation:** Extensive validation of input parameters
8. **Cross-chain Security:** MPC network integration for secure cross-chain operations

## Integration Points

- **CTMRWAGateway**: Cross-chain communication gateway
- **FeeManager**: Fee calculation and payment management
- **CTMRWADeployer**: Contract deployment management
- **CTMRWAMap**: Multi-chain address mapping
- **CTMRWA1XFallback**: Fallback handling for failed operations
- **C3GovernDapp**: Governance functionality
- **MPC Network**: Secure cross-chain message passing

## Error Handling

The contract uses custom error types for efficient gas usage and clear error messages, including:

- Authorization errors
- Invalid address errors
- Invalid parameter errors
- Contract existence errors
- Cross-chain operation errors
- Fee payment errors
- Slot management errors

## Cross-chain Architecture

The CTMRWA1X contract serves as the central coordinator for cross-chain RWA operations:

1. **Local Operations**: Handles deployment, minting, and management on the local chain
2. **Cross-chain Coordination**: Manages communication with other chains through the gateway
3. **MPC Integration**: Uses MPC network for secure cross-chain message passing
4. **Fallback Handling**: Dedicated fallback contract for handling failed operations
5. **Fee Management**: Integrated fee system for cross-chain operations
6. **Admin Synchronization**: Ensures admin changes are synchronized across all chains
