# CTMRWA1X Contract Documentation

## Overview

**Contract Name:** CTMRWA1X  
**File:** `src/crosschain/CTMRWA1X.sol`  
**License:** BSL-1.1  
**Author:** @Selqui ContinuumDAO

## Contract Description

CTMRWA1X manages the basic cross-chain deployment of CTMRWA1 as well as the creation of Asset Classes (slots), minting value on local chains, changing tokenAdmin (Issuer), and transferring value cross-chain. This contract is only deployed ONCE on each chain and manages all CTMRWA1 contract interactions.

### Key Features
- Cross-chain deployment of CTMRWA1 contracts
- Asset Class (slot) creation and management
- Cross-chain value transfers and minting
- TokenAdmin management across chains
- Fee management integration
- Governance controls through C3GovernDAppUpgradeable
- Upgradeable architecture with UUPS pattern

## State Variables

### Core Identifiers
- `LATEST_VERSION (uint256)`: The latest version of RWA type
- `RWA_TYPE (uint256, immutable = 1)`: RWA type defining CTMRWA1

### Contract Addresses
- `gateway (address)`: Address of the CTMRWAGateway contract
- `feeManager (address)`: Address of the FeeManager contract
- `ctmRwaDeployer (address)`: Address of the CTMRWADeployer contract
- `ctmRwaMap (address)`: Address of the CTMRWAMap contract
- `ctmRwa1XUtilsAddr (address)`: Address of the CTMRWA1XUtils contract

### Chain Information
- `cIdStr (string)`: String representation of the chainID

### Access Control
- `isMinter (mapping(address => bool))`: Addresses of routers permitted to bridge tokens cross-chain

## Initialization

### initialize()
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
Description: Initializes the CTMRWA1X contract instance.  
Parameters:
- `_gateway`: Address of the CTMRWAGateway contract
- `_feeManager`: Address of the FeeManager contract
- `_gov`: Address of the governance contract
- `_c3callerProxy`: Address of the C3 caller proxy
- `_txSender`: Address of the transaction sender
- `_dappID`: ID of the dapp

## Governance Functions

### updateLatestVersion()
```solidity
function updateLatestVersion(uint256 _newVersion) external onlyGov
```
Description: Governance can update the latest version.  
Parameters: `_newVersion` (uint256) new latest version  
Access: Only governance

### changeMinterStatus()
```solidity
function changeMinterStatus(address _minter, bool _set) external onlyGov
```
Description: Governance adds or removes a router able to bridge tokens or value cross-chain.  
Parameters:
- `_minter` (address): Router address
- `_set` (bool): Boolean setting or un-setting minter  
Access: Only governance

### changeFeeManager()
```solidity
function changeFeeManager(address _feeManager) external onlyGov
```
Description: Governance can change to a new FeeManager contract.  
Parameters: `_feeManager` (address) new FeeManager contract  
Access: Only governance

### setGateway()
```solidity
function setGateway(address _gateway) external onlyGov
```
Description: Governance can change to a new CTMRWAGateway contract.  
Parameters: `_gateway` (address) new CTMRWAGateway contract  
Access: Only governance

### setCtmRwaMap()
```solidity
function setCtmRwaMap(address _map) external onlyGov
```
Description: Governance can change to a new CTMRWAMap contract and reset deployer, gateway and rwaX addresses.  
Parameters: `_map` (address) new CTMRWAMap contract  
Access: Only governance

### setCtmRwaDeployer()
```solidity
function setCtmRwaDeployer(address _deployer) external onlyGov
```
Description: Governance can change to a new CTMRWADeployer.  
Parameters: `_deployer` (address) new CTMRWADeployer contract  
Access: Only governance

### setFallback()
```solidity
function setFallback(address _ctmRwa1XUtilsAddr) external onlyGov
```
Description: Governance can change to a new CTMRWA1XUtils contract.  
Parameters: `_ctmRwa1XUtilsAddr` (address) new CTMRWA1XUtils contract  
Access: Only governance

## Deployment Functions

### deployAllCTMRWA1X()
```solidity
function deployAllCTMRWA1X(
    bool _includeLocal,
    uint256 _existingID,
    uint256 _version,
    string memory _tokenName,
    string memory _symbol,
    uint8 _decimals,
    string memory _baseURI,
    string[] memory _toChainIdsStr,
    string memory _feeTokenStr
) public virtual returns (uint256)
```
Description: Deploy or extend the deployment of an RWA.  
Parameters:
- `_includeLocal`: If TRUE, deploys new CTMRWA1 on local chain. If FALSE, extends existing RWA
- `_existingID`: Set to ZERO for new RWA, or existing ID to extend
- `_version`: Version of RWA (1 for current)
- `_tokenName`: Name of RWA (10-512 characters)
- `_symbol`: Symbol for RWA (1-6 characters, uppercase, no spaces)
- `_decimals`: Decimal precision (0-18)
- `_baseURI`: Storage method ("GFLD", "IPFS", or "NONE")
- `_toChainIdsStr`: Array of chainID strings to deploy to
- `_feeTokenStr`: Fee token address as string  
Returns: ID of the deployed/extended RWA

### deployCTMRWA1()
```solidity
function deployCTMRWA1(
    uint256 _version,
    string memory _newAdminStr,
    uint256 _ID,
    string memory _tokenName,
    string memory _symbol,
    uint8 _decimals,
    string memory _baseURI,
    uint256[] memory _slotNumbers,
    string[] memory _slotNames
) external onlyCaller returns (bool)
```
Description: Deploys new CTMRWA1 instance on destination chain.  
Parameters:
- `_version`: Version of RWA (1 for current)
- `_newAdminStr`: New admin address as string
- `_ID`: RWA ID
- `_tokenName`, `_symbol`, `_decimals`, `_baseURI`: Token metadata
- `_slotNumbers`, `_slotNames`: Slot configuration  
Access: Only MPC network  
Returns: True if deployment successful

## Admin Management Functions

### changeTokenAdmin()
```solidity
function changeTokenAdmin(
    string memory _newAdminStr,
    string[] memory _toChainIdsStr,
    uint256 _ID,
    uint256 _version,
    string memory _feeTokenStr
) public
```
Description: Changes tokenAdmin address across multiple chains.  
Parameters:
- `_newAdminStr`: New tokenAdmin as string
- `_toChainIdsStr`: Array of chainID strings (includes local chain)
- `_ID`: RWA ID
- `_version`: Version of the RWA contract
- `_feeTokenStr`: Fee token address as string  
Access: Only current tokenAdmin  
Note: To lock RWA, set `_newAdminStr` to `address(0).toHexString()`

### adminX()
```solidity
function adminX(uint256 _ID, uint256 _version, string memory _oldAdminStr, string memory _newAdminStr)
    external
    onlyCaller
    returns (bool)
```
Description: Changes tokenAdmin of RWA on a specific chain.  
Parameters:
- `_ID`: RWA ID
- `_version`: Version of the RWA contract
- `_oldAdminStr`: Old admin address as string
- `_newAdminStr`: New admin address as string  
Access: Only MPC network  
Returns: True if change successful

## Slot Management Functions

### createNewSlot()
```solidity
function createNewSlot(
    uint256 _ID,
    uint256 _version,
    uint256 _slot,
    string memory _slotName,
    string[] memory _toChainIdsStr,
    string memory _feeTokenStr
) public
```
Description: Creates a new Asset Class (slot) across multiple chains.  
Parameters:
- `_ID`: RWA ID
- `_version`: Version of the RWA contract
- `_slot`: New slot number (must be unique)
- `_slotName`: Name of new Asset Class (max 256 characters)
- `_toChainIdsStr`: Array of chainID strings (includes local chain)
- `_feeTokenStr`: Fee token address as string  
Access: Only tokenAdmin

### createNewSlotX()
```solidity
function createNewSlotX(
    uint256 _ID,
    uint256 _version,
    string memory _fromAddressStr,
    uint256 _slot,
    string memory _slotName
) external onlyCaller returns (bool)
```
Description: Creates new slot for RWA on a specific chain.  
Parameters:
- `_ID`: RWA ID
- `_version`: Version of the RWA contract
- `_fromAddressStr`: Source address as string
- `_slot`: Slot number
- `_slotName`: Slot name  
Access: Only MPC network  
Returns: True if slot creation successful

## Cross-chain Transfer Functions

### transferPartialTokenX()
```solidity
function transferPartialTokenX(
    uint256 _fromTokenId,
    string memory _toAddressStr,
    string memory _toChainIdStr,
    uint256 _value,
    uint256 _ID,
    uint256 _version,
    string memory _feeTokenStr
) public nonReentrant returns (uint256)
```
Description: Transfers part of fungible balance of a tokenId to another chain.  
Parameters:
- `_fromTokenId`: TokenId to transfer from
- `_toAddressStr`: Destination address as string
- `_toChainIdStr`: Destination chainID as string
- `_value`: Fungible value to send
- `_ID`: RWA ID
- `_version`: Version of the RWA contract
- `_feeTokenStr`: Fee token address as string  
Access: Owner or approved operator  
Returns: New tokenId that was minted

### transferWholeTokenX()
```solidity
function transferWholeTokenX(
    string memory _fromAddrStr,
    string memory _toAddressStr,
    string memory _toChainIdStr,
    uint256 _fromTokenId,
    uint256 _ID,
    uint256 _version,
    string memory _feeTokenStr
) public nonReentrant
```
Description: Transfers a whole tokenId to another chain.  
Parameters:
- `_fromAddrStr`: Source address as string
- `_toAddressStr`: Destination address as string
- `_toChainIdStr`: Destination chainID as string
- `_fromTokenId`: TokenId to transfer
- `_ID`: RWA ID
- `_version`: Version of the RWA contract
- `_feeTokenStr`: Fee token address as string  
Access: Owner or approved operator

## Minting Functions

### mintX()
```solidity
function mintX(
    uint256 _ID,
    uint256 _version,
    string memory _fromAddressStr,
    string memory _toAddressStr,
    uint256 _slot,
    uint256 _balance
) external onlyCaller returns (bool)
```
Description: Mints value in a new slot to an address (creates new tokenId).  
Parameters:
- `_ID`: RWA ID
- `_version`: Version of the RWA contract
- `_fromAddressStr`: Source address as string
- `_toAddressStr`: Destination address as string
- `_slot`: Slot number
- `_balance`: Balance to mint  
Access: Only MPC network  
Returns: True if minting successful

## Internal Functions

### _deployCTMRWA1Local()
```solidity
function _deployCTMRWA1Local(
    uint256 _ID,
    uint256 _version,
    string memory _tokenName,
    string memory _symbol,
    uint8 _decimals,
    string memory _baseURI,
    uint256[] memory _slotNumbers,
    string[] memory _slotNames,
    address _tokenAdmin
) internal returns (address)
```
Description: Deploys new RWA on local chain. Called by deployAllCTMRWA1X or deployCTMRWA1.

### _deployCTMRWA1X()
```solidity
function _deployCTMRWA1X(
    uint256 _version,
    string memory _tokenName,
    string memory _symbol,
    uint8 _decimals,
    string memory _baseURI,
    string memory _toChainIdStr,
    uint256[] memory _slotNumbers,
    string[] memory _slotNames,
    string memory _ctmRwa1AddrStr
) internal
```
Description: Deploys CTMRWA1 instance on destination chain. Called by deployAllCTMRWA1X.

### _changeAdmin()
```solidity
function _changeAdmin(address _currentAdmin, address _newAdmin, uint256 _ID, uint256 _version) internal
```
Description: Changes tokenAdmin across all related contracts.

### _getRWAX()
```solidity
function _getRWAX(string memory _toChainIdStr, uint256 _version) internal view returns (string memory, string memory)
```
Description: Gets corresponding CTMRWA1X address on another chain.

### _checkTokenAdmin()
```solidity
function _checkTokenAdmin(address _tokenAddr) internal returns (address, string memory)
```
Description: Checks and returns tokenAdmin for a CTMRWA1.

### _getTokenAddr()
```solidity
function _getTokenAddr(uint256 _ID, uint256 _version) internal view returns (address, string memory)
```
Description: Gets CTMRWA1 address and string version for an ID.

### _payFee()
```solidity
function _payFee(FeeType _feeType, string memory _feeTokenStr, string[] memory _toChainIdsStr, bool _includeLocal)
    internal
    returns (bool)
```
Description: Pays fees for operations.

### cID()
```solidity
function cID() internal view returns (uint256)
```
Description: Returns current chain ID.

### _c3Fallback()
```solidity
function _c3Fallback(bytes4 _selector, bytes calldata _data, bytes calldata _reason)
    internal
    override
    returns (bool)
```
Description: Handles cross-chain call failures.

## Access Control Modifiers

- `onlyGov`: Restricts access to governance functions
- `onlyCaller`: Restricts access to MPC network calls
- `initializer`: Ensures function can only be called once during initialization

## Events

- `CreateNewCTMRWA1(uint256 indexed ID)`: New CTMRWA1 created
- `DeployCTMRWA1(uint256 indexed ID, string toChainIdStr)`: CTMRWA1 deployed to chain
- `ChangingAdmin(uint256 indexed ID, string toChainIdStr)`: Admin change initiated
- `AdminChanged(uint256 indexed ID, string newAdminStr)`: Admin change completed
- `CreateSlot(uint256 indexed ID, uint256 indexed slot, string toChainIdStr)`: Slot creation initiated
- `SlotCreated(uint256 indexed ID, uint256 indexed slot, string fromChainIdStr)`: Slot creation completed
- `Minting(uint256 indexed ID, string toAddressStr, string toChainIdStr)`: Cross-chain minting initiated
- `Minted(uint256 indexed ID, string fromChainIdStr, string fromAddressStr)`: Cross-chain minting completed

## Security Features

- **Reentrancy Protection:** Uses OpenZeppelin's ReentrancyGuardUpgradeable
- **Access Control:** Comprehensive modifier system for different roles
- **Governance Integration:** Built-in governance through C3GovernDAppUpgradeable
- **Upgradeable:** UUPS upgradeable pattern for future improvements
- **Fee Management:** Integrated fee system for cross-chain operations
- **Fallback Handling:** Dedicated fallback contract for failed cross-chain calls
- **Parameter Validation:** Extensive validation of input parameters
- **Cross-chain Security:** MPC network integration for secure cross-chain operations

## Integration Points

- **CTMRWAGateway**: Cross-chain communication gateway
- **FeeManager**: Fee calculation and payment management
- **CTMRWADeployer**: Contract deployment management
- **CTMRWAMap**: Multi-chain address mapping
- **CTMRWA1XUtils**: Extended functionality and fallback handling
- **C3GovernDApp**: Governance functionality
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