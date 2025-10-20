# CTMRWA1 Contract Documentation

## Overview

**Contract Name:** CTMRWA1  
**File:** `src/core/CTMRWA1.sol`  
**License:** MIT  
**Author:** @Selqui ContinuumDAO

## Contract Description

CTMRWA1 is a multi-chain semi-fungible token contract for Real-World Assets (RWAs). It derives concepts from ERC3525 but is not ERC3525 compliant. The contract can be deployed multiple times on multiple chains from CTMRWA1X and supports cross-chain functionality.

### Key Features
- Semi-fungible, slot-based value model
- Multi-chain deployment and coordination via CTMRWA1X
- Pausable and reentrancy-protected state-changing flows
- Fine-grained approvals for tokenId transfers and value spending
- Per-slot ERC20 wrapper integration with selective token approvals
- Historical per-slot balances and total supply via checkpoints

## Constructor

The CTMRWA1 contract is initialized with the following parameters:

```solidity
constructor(
    address _tokenAdmin,
    address _map,
    string memory tokenName_,
    string memory symbol_,
    uint8 decimals_,
    string memory baseURI_,
    address _ctmRwa1X
)
```

### Constructor Behavior

During construction, the contract:
1. Sets `tokenAdmin` and `ctmRwaMap`
2. Initializes `_tokenIdGenerator` to 1
3. Sets token metadata (`_name`, `_symbol`, `_decimals`, `baseURI`)
4. Stores `ctmRwa1X`
5. Derives `ctmRwaDeployer` from `CTMRWA1X`
6. Derives `tokenFactory` and `erc20Deployer` from `CTMRWADeployer`

## State Variables

### Core Identifiers
- `ID (uint256)`: Unique identifier linking CTMRWA1 across chains
- `VERSION (uint256, immutable = 1)`: Version of this RWA type
- `RWA_TYPE (uint256, immutable = 1)`: RWA type defining CTMRWA1

### Administrative Addresses
- `tokenAdmin (address)`: Wallet controlling the RWA (Issuer)
- `ctmRwaDeployer (address)`: Contract deploying CTMRWA1 components
- `overrideWallet (address)`: Optional wallet permitted to forceTransfer
- `ctmRwaMap (address)`: Contract mapping multi-chain ID to components
- `ctmRwa1X (address)`: Cross-chain coordinator for deploy/mint/transfer

### Component Addresses
- `dividendAddr (address)`: Dividend manager contract
- `storageAddr (address)`: Storage manager contract
- `sentryAddr (address)`: Access control and whitelisting contract
- `tokenFactory (address)`: Contract that directly deploys CTMRWA1
- `erc20Deployer (address)`: Contract for deploying per-slot ERC20s

### Token Metadata and Slot Indexes
- `baseURI (string)`: Identifier for info storage: "GFLD" | "IPFS" | "NONE"
- `slotNumbers (uint256[])`: Array of slot numbers defined for this CTMRWA1
- `slotNames (string[])`: Array of slot names corresponding to `slotNumbers`
- `_allSlots (SlotData[])`: Array of slot metadata and membership
- `allSlotsIndex (mapping(uint256 => uint256))`: slot => index into `_allSlots`

### Checkpointing and Approvals
- `_balance (mapping(address => mapping(uint256 => Checkpoints.Trace208)))`: Owner => slot => balance checkpoints
- `_supplyInSlot (mapping(uint256 => Checkpoints.Trace208))`: Slot => total supply checkpoints
- `_approvedValues (mapping(uint256 => mapping(address => uint256)))`: tokenId => (spender => allowance)
- `_erc20Slots (mapping(uint256 => address))`: slot => ERC20 address
- `_erc20Approvals (mapping(address => mapping(uint256 => uint256[])))`: Owner => slot => approved tokenIds for ERC20

## Data Structures

### TokenData
```solidity
struct TokenData {
    uint256 id;           // Token ID
    uint256 slot;         // Slot number
    uint256 balance;      // Token balance
    address owner;        // Token owner
    address approved;     // Approved address for tokenId transfer
    address[] valueApprovals; // Addresses approved for value spending
}
```

### AddressData
```solidity
struct AddressData {
    uint256[] ownedTokens;                    // Array of owned token IDs
    mapping(uint256 => uint256) ownedTokensIndex; // Token ID to index mapping
}
```

### SlotData
```solidity
struct SlotData {
    uint256 slot;         // Slot number
    string slotName;      // Slot name
    uint256[] slotTokens; // Token IDs in the slot
}
```

## Access Control Functions

### pause()
```solidity
function pause() external onlyTokenAdmin
```
Description: Pauses the contract.  
Access: Only tokenAdmin or CTMRWA1X

### unpause()
```solidity
function unpause() external onlyTokenAdmin
```
Description: Unpauses the contract.  
Access: Only tokenAdmin or CTMRWA1X

## Administrative Functions

### changeAdmin()
```solidity
function changeAdmin(address _tokenAdmin) public onlyRwa1X
```
Description: Changes the `tokenAdmin`. Resets `overrideWallet` for safety.  
Parameters: `_tokenAdmin` (address) new admin  
Access: Only CTMRWA1X

### setOverrideWallet()
```solidity
function setOverrideWallet(address _overrideWallet) public onlyTokenAdmin
```
Description: Sets the override wallet that can force transfers.  
Parameters: `_overrideWallet` (address)  
Access: Only tokenAdmin  
Requirements: Regulator wallet must be set in `CTMRWA1Storage`

### attachId()
```solidity
function attachId(uint256 nextID, address _tokenAdmin) external onlyRwa1X returns (bool)
```
Description: Attaches `ID` after deployment (only once).  
Parameters: `nextID` (uint256), `_tokenAdmin` (address)  
Returns: True if attached

### attachDividend()
```solidity
function attachDividend(address _dividendAddr) external onlyCtmMap returns (bool)
```
Description: Connect the `CTMRWA1Dividend` contract.  
Returns: True if successful

### attachStorage()
```solidity
function attachStorage(address _storageAddr) external onlyCtmMap returns (bool)
```
Description: Connect the `CTMRWA1Storage` contract.  
Returns: True if successful

### attachSentry()
```solidity
function attachSentry(address _sentryAddr) external onlyCtmMap returns (bool)
```
Description: Connect the `CTMRWA1Sentry` contract.  
Returns: True if successful

## Token Information Functions

### name()
```solidity
function name() public view returns (string memory)
```
Description: Returns the token collection name.

### symbol()
```solidity
function symbol() public view returns (string memory)
```
Description: Returns the token collection symbol.

### valueDecimals()
```solidity
function valueDecimals() external view returns (uint8)
```
Description: Returns decimals used for value.

### ownerOf()
```solidity
function ownerOf(uint256 _tokenId) public view returns (address)
```
Description: Returns the owner of a tokenId.

### slotOf()
```solidity
function slotOf(uint256 _tokenId) public view returns (uint256)
```
Description: Returns the slot number of a tokenId.

### slotNameOf()
```solidity
function slotNameOf(uint256 _tokenId) public view returns (string memory)
```
Description: Returns the slot name of a tokenId.

### getTokenInfo()
```solidity
function getTokenInfo(uint256 _tokenId)
    external
    view
    returns (uint256, uint256, address, uint256, string memory, address)
```
Description: Returns `(id, balance, owner, slot, slotName, tokenAdmin)` for a tokenId.

## Balance and Ownership Functions

### balanceOf(uint256)
```solidity
function balanceOf(uint256 _tokenId) public view returns (uint256)
```
Description: Returns the fungible balance of a tokenId.

### balanceOf(address)
```solidity
function balanceOf(address _owner) public view returns (uint256)
```
Description: Returns count of tokenIds owned by `_owner`.

### balanceOf(address, uint256)
```solidity
function balanceOf(address _owner, uint256 _slot) public view returns (uint256)
```
Description: Returns total balance across `_owner`'s tokenIds in `_slot`.

### balanceOfAt()
```solidity
function balanceOfAt(address _owner, uint256 _slot, uint256 _timestamp) public view returns (uint256)
```
Description: Returns checkpointed balance at a timestamp for owner and slot.

## Slot Management Functions

### slotCount()
```solidity
function slotCount() public view returns (uint256)
```
Description: Returns the number of slots.

### getAllSlots()
```solidity
function getAllSlots() public view returns (uint256[] memory, string[] memory)
```
Description: Returns arrays of all slot numbers and slot names.

### initializeSlotData()
```solidity
function initializeSlotData(uint256[] memory _slotNumbers, string[] memory _slotNames) external onlyTokenFactory
```
Description: Initializes slot data on a newly deployed chain.  
Access: Only tokenFactory  
Requirements: Same length arrays; only if slots not yet initialized

### slotName()
```solidity
function slotName(uint256 _slot) public view returns (string memory)
```
Description: Returns the name for a slot number.

### slotByIndex()
```solidity
function slotByIndex(uint256 _index) public view returns (uint256)
```
Description: Returns the slot number at index in slot array.

### slotExists()
```solidity
function slotExists(uint256 _slot) public view returns (bool)
```
Description: Returns whether a slot exists.

### tokenSupplyInSlot()
```solidity
function tokenSupplyInSlot(uint256 _slot) external view returns (uint256)
```
Description: Returns the number of tokenIds in a slot.

### totalSupplyInSlot()
```solidity
function totalSupplyInSlot(uint256 _slot) external view returns (uint256)
```
Description: Returns total fungible balance in a slot.

### totalSupplyInSlotAt()
```solidity
function totalSupplyInSlotAt(uint256 _slot, uint256 _timestamp) external view returns (uint256)
```
Description: Returns historical total supply for a slot at timestamp.

### tokenInSlotByIndex()
```solidity
function tokenInSlotByIndex(uint256 _slot, uint256 _index) public view returns (uint256)
```
Description: Returns the tokenId in a slot by index.

### createSlotX()
```solidity
function createSlotX(uint256 _slot, string memory _slotName) external onlyRwa1X
```
Description: Creates a new slot (cross-chain controlled).  
Access: Only CTMRWA1X

## Supply and Enumeration Functions

### totalSupply()
```solidity
function totalSupply() external view returns (uint256)
```
Description: Returns total number of tokenIds in CTMRWA1.

### tokenOfOwnerByIndex()
```solidity
function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256)
```
Description: Returns the tokenId owned by `_owner` at `_index`.

## Approval Functions

### approve(uint256, address, uint256)
```solidity
function approve(uint256 _tokenId, address _to, uint256 _value) public payable
```
Description: Approves `_to` to spend `_value` from `_tokenId`'s fungible balance.

### allowance()
```solidity
function allowance(uint256 _tokenId, address _operator) public view returns (uint256)
```
Description: Returns allowance to spend from `_tokenId` by `_operator`.

### approve(address, uint256)
```solidity
function approve(address _to, uint256 _tokenId) public
```
Description: Approves `_to` to transfer `_tokenId` (tokenId-level approval).

### revokeApproval()
```solidity
function revokeApproval(uint256 _tokenId) public
```
Description: Revokes tokenId-level approval; clears ERC20 approval bookkeeping if set.

### isApprovedOrOwner()
```solidity
function isApprovedOrOwner(address _operator, uint256 _tokenId) public view returns (bool)
```
Description: Returns whether `_operator` is approved or owner for `_tokenId`.

### getApproved()
```solidity
function getApproved(uint256 _tokenId) public view returns (address)
```
Description: Returns address approved for tokenId-level transfer.

### spendAllowance()
```solidity
function spendAllowance(address _operator, uint256 _tokenId, uint256 _value) public
```
Description: Reduces allowance or requires direct ownership approval when spending value.

## Transfer Functions

### transferFrom(uint256, address, uint256)
```solidity
function transferFrom(uint256 _fromTokenId, address _to, uint256 _value)
    public
    onlyRwa1X
    whenNotPaused
    nonReentrant
    returns (uint256 newTokenId)
```
Description: Transfers value from a tokenId to a new token for `_to`. Creates a new tokenId and moves `_value`.

### transferFrom(uint256, uint256, uint256)
```solidity
function transferFrom(uint256 _fromTokenId, uint256 _toTokenId, uint256 _value)
    public
    nonReentrant
    whenNotPaused
    returns (address)
```
Description: Transfers value between two existing tokenIds. If the source becomes empty, it is removed from owner enumeration.

### transferFrom(address, address, uint256)
```solidity
function transferFrom(address _from, address _to, uint256 _tokenId) public onlyRwa1X whenNotPaused
```
Description: Transfers a tokenId between addresses (cross-chain controlled) with approval checks.

### forceTransfer()
```solidity
function forceTransfer(address _from, address _to, uint256 _tokenId) public
```
Description: If `overrideWallet` is set, allows force transfer of any tokenId by that wallet.

## Minting Functions

### mintFromX(address, uint256, string, uint256)
```solidity
function mintFromX(address _to, uint256 _slot, string memory _slotName, uint256 _value)
    external
    whenNotPaused
    returns (uint256 tokenId)
```
Description: Mints to a new tokenId. Callable by authorized minters or the slot ERC20.

### mintFromX(address, uint256, uint256, string, uint256)
```solidity
function mintFromX(address _to, uint256 _tokenId, uint256 _slot, string memory _slotName, uint256 _value)
    external
    onlyMinter
    whenNotPaused
```
Description: Low-level mint to a provided new `_tokenId`. Callable by authorized minters.

### mintValueX()
```solidity
function mintValueX(uint256 _toTokenId, uint256 _value)
    external
    onlyMinter
    whenNotPaused
```
Description: Mints value to an existing tokenId. Checks whitelist if enabled.

## Burning Functions

### burn()
```solidity
function burn(uint256 _tokenId) public whenNotPaused
```
Description: Burns a tokenId if caller is owner or approved.

### burnValueX()
```solidity
function burnValueX(uint256 _fromTokenId, uint256 _value) external onlyMinter whenNotPaused
```
Description: Burns value from an existing tokenId. Callable by minters.

## ERC20 Integration Functions

### setErc20()
```solidity
function setErc20(address _erc20, uint256 _slot) external onlyErc20Deployer
```
Description: Sets the ERC20 address for a slot (once). Requires slot exist and ERC20 not already set.

### getErc20()
```solidity
function getErc20(uint256 _slot) public view returns (address)
```
Description: Returns the ERC20 wrapper address for a slot.

### approveFromX()
```solidity
function approveFromX(address _to, uint256 _tokenId) external
```
Description: Approve from RWA1X or authorized slot ERC20 contracts.

### clearApprovedValues()
```solidity
function clearApprovedValues(uint256 _tokenId) external onlyRwa1X
```
Description: Clears all value approvals for a tokenId (cross-chain context).

### clearApprovedValuesFromERC20()
```solidity
function clearApprovedValuesFromERC20(uint256 _tokenId) external onlyERC20
```
Description: Clears all value approvals for a tokenId (slot ERC20 context).

### removeTokenFromOwnerEnumeration()
```solidity
function removeTokenFromOwnerEnumeration(address _from, uint256 _tokenId) external onlyRwa1X
```
Description: Owner enumeration maintenance helper for cross-chain operations.

### getErc20Approvals()
```solidity
function getErc20Approvals(address _owner, uint256 _slot) external view returns (uint256[] memory)
```
Description: Returns tokenIds approved for slot ERC20 spending for an owner.

### approveErc20()
```solidity
function approveErc20(uint256 _tokenId) public
```
Description: Owner approves the slot ERC20 to manage a tokenId; records in per-owner, per-slot approval list.

## Utility Functions

### exists()
```solidity
function exists(uint256 _tokenId) external view returns (bool)
```
Description: Returns whether a tokenId exists.

## Access Control Modifiers

- `onlyTokenAdmin`: Restricts access to `tokenAdmin` or `ctmRwa1X`
- `onlyErc20Deployer`: Restricts access to `erc20Deployer`
- `onlyTokenFactory`: Restricts access to `tokenFactory`
- `onlyCtmMap`: Restricts access to `ctmRwaMap`
- `onlyRwa1X`: Restricts access to `ctmRwa1X`
- `onlyMinter`: Restricts access to authorized minters per `CTMRWA1X`
- `onlyERC20`: Restricts access to authorized slot ERC20 contracts

## Events

- `Transfer(address indexed from, address indexed to, uint256 indexed tokenId)`
- `Approval(address indexed owner, address indexed approved, uint256 indexed tokenId)`
- `TransferValue(uint256 indexed fromTokenId, uint256 indexed toTokenId, uint256 value)`
- `ApprovalValue(uint256 indexed tokenId, address indexed operator, uint256 value)`
- `SlotChanged(uint256 indexed tokenId, uint256 indexed oldSlot, uint256 indexed newSlot)`

## Security Features

- Reentrancy guard on critical value-transfer functions
- Pausable controls
- Strict access modifiers with custom errors
- Whitelist enforcement via `CTMRWA1Sentry` when configured
- Overflow checks for uint208-based checkpoint math
- Cross-chain authority enforcement via `CTMRWA1X`

## Integration Points

- `CTMRWA1X`: Cross-chain coordinator and minter registry
- `CTMRWAMap`: Multi-chain component address mapping
- `CTMRWA1Sentry`: Access control and whitelist
- `CTMRWA1Storage`: Issuer/regulator/legal metadata
- `CTMRWA1Dividend`: Dividend distribution
- `CTMRWAERC20Deployer`: Per-slot ERC20 deployment and management
