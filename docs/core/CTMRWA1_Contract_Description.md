# CTMRWA1 Contract Documentation

## Overview

**Contract Name:** CTMRWA1  
**File:** `src/core/CTMRWA1.sol`  
**License:** MIT (for CTMRWA1.sol)  
**Author:** @Selqui ContinuumDAO  

## Contract Description

CTMRWA1 is a multi-chain semi-fungible token contract for Real-World Assets (RWAs). It is derived from ERC3525 but is NOT ERC3525 compliant. The contract can be deployed multiple times on multiple chains from CTMRWA1X and supports cross-chain functionality.

### Key Features
- Semi-fungible token implementation for RWAs
- Multi-chain deployment support
- Slot-based value management
- Cross-chain transfer capabilities
- Pausable functionality
- Reentrancy protection
- ERC20 wrapper support with approval system
- Fine-grained ERC20 spending control

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

### Constructor Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `_tokenAdmin` | `address` | The address of the token administrator (Issuer) who controls the RWA |
| `_map` | `address` | The address of the CTMRWAMap contract that maps multi-chain IDs to component addresses |
| `tokenName_` | `string` | The name of the token (e.g., "AssetX RWA Token") |
| `symbol_` | `string` | The symbol of the token (e.g., "ARWA") |
| `decimals_` | `uint8` | The number of decimal places for the token (typically 18) |
| `baseURI_` | `string` | The base URI for token metadata |
| `_ctmRwa1X` | `address` | The address of the CTMRWA1X contract responsible for cross-chain operations |

### Constructor Behavior

During construction, the contract:
1. Sets the `tokenAdmin` to the provided address
2. Initializes the `ctmRwaMap` for cross-chain mapping
3. Sets up token metadata (name, symbol, decimals, baseURI)
4. Establishes the `ctmRwa1X` contract for cross-chain functionality
5. Retrieves and sets the `rwa1XFallback` address from the CTMRWA1X contract
6. Gets the `ctmRwaDeployer` address from CTMRWA1X
7. Sets the `tokenFactory` address for this RWA type and version
8. Sets the `erc20Deployer` address for ERC20 token deployment
9. Initializes the token ID generator to 1

## State Variables

### Core Identifiers
- `ID` (uint256): Unique identifier linking CTMRWA1 across chains
- `VERSION` (uint256, constant): Version of this RWA type (1)
- `RWA_TYPE` (uint256, constant): RWA type defining CTMRWA1 (1)

### Administrative Addresses
- `tokenAdmin` (address): Wallet controlling the RWA (Issuer)
- `ctmRwaDeployer` (address): Contract deploying CTMRWA1 components
- `overrideWallet` (address): Wallet that can forceTransfer assets (if defined)
- `ctmRwaMap` (address): Contract mapping multi-chain ID to component addresses
- `ctmRwa1X` (address): Contract responsible for cross-chain operations
- `rwa1XFallback` (address): Contract handling failed cross-chain calls

### Component Addresses
- `dividendAddr` (address): Contract managing dividend payments
- `storageAddr` (address): Contract managing decentralized storage
- `sentryAddr` (address): Contract controlling access to CTMRWA1
- `tokenFactory` (address): Contract that directly deploys this contract
- `erc20Deployer` (address): Contract for ERC20 wrapper deployment

### Slot Management
- `slotNumbers` (uint256[]): Array of defined slot numbers
- `slotNames` (string[]): Array of slot names

## Data Structures

### TokenData
```solidity
struct TokenData {
    uint256 id;           // Token ID
    uint256 slot;         // Slot number
    uint256 balance;      // Token balance
    address owner;        // Token owner
    address approved;     // Approved address
    address[] valueApprovals; // Value approval addresses
}
```

### AddressData
```solidity
struct AddressData {
    uint256[] ownedTokens;                    // Array of owned token IDs
    mapping(uint256 => uint256) ownedTokensIndex; // Token ID to index mapping
}
```

### ERC20 Approval System
The contract maintains a mapping for ERC20 approvals:
```solidity
mapping(address => mapping(uint256 => uint256[])) _erc20Approvals; // owner => slot => tokenId[]
```
This allows owners to selectively approve specific tokenIds for spending by ERC20 contracts, providing fine-grained control over which tokens can be used in ERC20 operations.

## Access Control Functions

### pause()
```solidity
function pause() external onlyTokenAdmin
```
**Description:** Pauses the contract. Only callable by tokenAdmin.  
**Access:** Only tokenAdmin  
**Effects:** Pauses all pausable functions  

### unpause()
```solidity
function unpause() external onlyTokenAdmin
```
**Description:** Unpauses the contract. Only callable by tokenAdmin.  
**Access:** Only tokenAdmin  
**Effects:** Unpauses all pausable functions  

### isPaused()
```solidity
function isPaused() external view returns (bool)
```
**Description:** Returns true if the contract is paused.  
**Returns:** Boolean indicating pause status  

## Administrative Functions

### changeAdmin()
```solidity
function changeAdmin(address _tokenAdmin) public onlyRwa1X returns (bool)
```
**Description:** Changes the tokenAdmin address. Only callable by CTMRWA1X.  
**Parameters:**
- `_tokenAdmin` (address): New tokenAdmin address
**Access:** Only CTMRWA1X  
**Returns:** True if successful  

### setOverrideWallet()
```solidity
function setOverrideWallet(address _overrideWallet) public onlyTokenAdmin
```
**Description:** Sets the override wallet that can forceTransfer assets.  
**Parameters:**
- `_overrideWallet` (address): Override wallet address
**Access:** Only tokenAdmin  
**Requirements:** Regulator wallet must be set in storage  

### attachId()
```solidity
function attachId(uint256 nextID, address _tokenAdmin) external onlyRwa1X returns (bool)
```
**Description:** Sets the ID for this CTMRWA1 after deployment.  
**Parameters:**
- `nextID` (uint256): ID to attach
- `_tokenAdmin` (address): TokenAdmin address
**Access:** Only CTMRWA1X  
**Returns:** True if ID was attached  

### attachDividend()
```solidity
function attachDividend(address _dividendAddr) external onlyCtmMap returns (bool)
```
**Description:** Connects the CTMRWA1Dividend contract to this CTMRWA1.  
**Parameters:**
- `_dividendAddr` (address): Dividend contract address
**Access:** Only CTMRWAMap  
**Returns:** True if successful  

### attachStorage()
```solidity
function attachStorage(address _storageAddr) external onlyCtmMap returns (bool)
```
**Description:** Connects the CTMRWA1Storage contract to this CTMRWA1.  
**Parameters:**
- `_storageAddr` (address): Storage contract address
**Access:** Only CTMRWAMap  
**Returns:** True if successful  

### attachSentry()
```solidity
function attachSentry(address _sentryAddr) external onlyCtmMap returns (bool)
```
**Description:** Connects the CTMRWA1Sentry contract to this CTMRWA1.  
**Parameters:**
- `_sentryAddr` (address): Sentry contract address
**Access:** Only CTMRWAMap  
**Returns:** True if successful  

## Token Information Functions

### name()
```solidity
function name() public view virtual override returns (string memory)
```
**Description:** Returns the token collection name.  
**Returns:** Token name string  

### symbol()
```solidity
function symbol() public view virtual override returns (string memory)
```
**Description:** Returns the token collection symbol.  
**Returns:** Token symbol string  

### valueDecimals()
```solidity
function valueDecimals() external view virtual returns (uint8)
```
**Description:** Returns the number of decimals the token uses for value.  
**Returns:** Number of decimals  

### idOf()
```solidity
function idOf(uint256 _tokenId) public view virtual returns (uint256)
```
**Description:** Returns the ID of the token.  
**Parameters:**
- `_tokenId` (uint256): Token ID
**Returns:** Token ID (same as input)  

## Balance and Ownership Functions

### balanceOf(uint256)
```solidity
function balanceOf(uint256 _tokenId) public view virtual override returns (uint256)
```
**Description:** Returns the balance of a specific token.  
**Parameters:**
- `_tokenId` (uint256): Token ID
**Returns:** Token balance  

### balanceOf(address)
```solidity
function balanceOf(address _owner) public view virtual override returns (uint256)
```
**Description:** Returns the total balance of all tokens owned by an address.  
**Parameters:**
- `_owner` (address): Owner address
**Returns:** Total balance  

### balanceOf(address, uint256)
```solidity
function balanceOf(address _owner, uint256 _slot) public view returns (uint256)
```
**Description:** Returns the balance of tokens in a specific slot owned by an address.  
**Parameters:**
- `_owner` (address): Owner address
- `_slot` (uint256): Slot number
**Returns:** Balance in slot  

### balanceOfAt()
```solidity
function balanceOfAt(address _owner, uint256 _slot, uint256 _timestamp) public view returns (uint256)
```
**Description:** Returns the balance at a specific timestamp using checkpoints.  
**Parameters:**
- `_owner` (address): Owner address
- `_slot` (uint256): Slot number
- `_timestamp` (uint256): Timestamp
**Returns:** Historical balance  

### ownerOf()
```solidity
function ownerOf(uint256 _tokenId) public view virtual returns (address)
```
**Description:** Returns the owner of a specific token.  
**Parameters:**
- `_tokenId` (uint256): Token ID
**Returns:** Owner address  

## Slot Management Functions

### slotOf()
```solidity
function slotOf(uint256 _tokenId) public view virtual override returns (uint256)
```
**Description:** Returns the slot number of a token.  
**Parameters:**
- `_tokenId` (uint256): Token ID
**Returns:** Slot number  

### slotNameOf()
```solidity
function slotNameOf(uint256 _tokenId) public view virtual returns (string memory)
```
**Description:** Returns the slot name of a token.  
**Parameters:**
- `_tokenId` (uint256): Token ID
**Returns:** Slot name  

### getTokenInfo()
```solidity
function getTokenInfo(uint256 _tokenId) public view returns (TokenData memory)
```
**Description:** Returns comprehensive information about a token.  
**Parameters:**
- `_tokenId` (uint256): Token ID
**Returns:** TokenData struct with token information  

### slotCount()
```solidity
function slotCount() public view returns (uint256)
```
**Description:** Returns the total number of slots.  
**Returns:** Number of slots  

### getAllSlots()
```solidity
function getAllSlots() public view returns (uint256[] memory, string[] memory)
```
**Description:** Returns all slot numbers and names.  
**Returns:** Arrays of slot numbers and names  

### getSlotInfoByIndex()
```solidity
function getSlotInfoByIndex(uint256 _indx) public view returns (SlotData memory)
```
**Description:** Returns slot information by index.  
**Parameters:**
- `_indx` (uint256): Slot index
**Returns:** SlotData struct  

### initializeSlotData()
```solidity
function initializeSlotData(uint256[] memory _slotNumbers, string[] memory _slotNames) external onlyTokenFactory
```
**Description:** Initializes slot data during contract deployment.  
**Parameters:**
- `_slotNumbers` (uint256[]): Array of slot numbers
- `_slotNames` (string[]): Array of slot names
**Access:** Only tokenFactory  

### slotName()
```solidity
function slotName(uint256 _slot) public view returns (string memory)
```
**Description:** Returns the name of a slot.  
**Parameters:**
- `_slot` (uint256): Slot number
**Returns:** Slot name  

### slotByIndex()
```solidity
function slotByIndex(uint256 _index) public view returns (uint256)
```
**Description:** Returns the slot number at a specific index.  
**Parameters:**
- `_index` (uint256): Index
**Returns:** Slot number  

### slotExists()
```solidity
function slotExists(uint256 _slot) public view virtual returns (bool)
```
**Description:** Checks if a slot exists.  
**Parameters:**
- `_slot` (uint256): Slot number
**Returns:** True if slot exists  

### createSlotX()
```solidity
function createSlotX(uint256 _slot, string memory _slotName) external onlyRwa1X
```
**Description:** Creates a new slot from cross-chain call.  
**Parameters:**
- `_slot` (uint256): Slot number
- `_slotName` (string): Slot name
**Access:** Only CTMRWA1X  

## Supply and Enumeration Functions

### totalSupply()
```solidity
function totalSupply() external view virtual returns (uint256)
```
**Description:** Returns the total supply of all tokens.  
**Returns:** Total supply  

### tokenByIndex()
```solidity
function tokenByIndex(uint256 _index) public view virtual returns (uint256)
```
**Description:** Returns the token ID at a specific index.  
**Parameters:**
- `_index` (uint256): Index
**Returns:** Token ID  

### tokenOfOwnerByIndex()
```solidity
function tokenOfOwnerByIndex(address _owner, uint256 _index) external view virtual override returns (uint256)
```
**Description:** Returns the token ID owned by an address at a specific index.  
**Parameters:**
- `_owner` (address): Owner address
- `_index` (uint256): Index
**Returns:** Token ID  

### tokenSupplyInSlot()
```solidity
function tokenSupplyInSlot(uint256 _slot) external view returns (uint256)
```
**Description:** Returns the number of tokens in a slot.  
**Parameters:**
- `_slot` (uint256): Slot number
**Returns:** Number of tokens  

### totalSupplyInSlot()
```solidity
function totalSupplyInSlot(uint256 _slot) external view returns (uint256)
```
**Description:** Returns the total supply in a slot.  
**Parameters:**
- `_slot` (uint256): Slot number
**Returns:** Total supply in slot  

### totalSupplyInSlotAt()
```solidity
function totalSupplyInSlotAt(uint256 _slot, uint256 _timestamp) external view returns (uint256)
```
**Description:** Returns the total supply in a slot at a specific timestamp.  
**Parameters:**
- `_slot` (uint256): Slot number
- `_timestamp` (uint256): Timestamp
**Returns:** Historical total supply  

### tokenInSlotByIndex()
```solidity
function tokenInSlotByIndex(uint256 _slot, uint256 _index) public view returns (uint256)
```
**Description:** Returns the token ID in a slot at a specific index.  
**Parameters:**
- `_slot` (uint256): Slot number
- `_index` (uint256): Index
**Returns:** Token ID  

## Approval Functions

### approve(uint256, address, uint256)
```solidity
function approve(uint256 _tokenId, address _to, uint256 _value) public payable virtual override
```
**Description:** Approves an address to spend a specific value from a token.  
**Parameters:**
- `_tokenId` (uint256): Token ID
- `_to` (address): Approved address
- `_value` (uint256): Approved value
**Effects:** Sets value approval  

### approve(address, uint256)
```solidity
function approve(address _to, uint256 _tokenId) public virtual
```
**Description:** Approves an address to transfer a token.  
**Parameters:**
- `_to` (address): Approved address
- `_tokenId` (uint256): Token ID
**Effects:** Sets token approval  

### allowance()
```solidity
function allowance(uint256 _tokenId, address _operator) public view virtual override returns (uint256)
```
**Description:** Returns the approved value for an operator on a token.  
**Parameters:**
- `_tokenId` (uint256): Token ID
- `_operator` (address): Operator address
**Returns:** Approved value  

### getApproved()
```solidity
function getApproved(uint256 _tokenId) public view virtual returns (address)
```
**Description:** Returns the approved address for a token.  
**Parameters:**
- `_tokenId` (uint256): Token ID
**Returns:** Approved address  

### isApprovedOrOwner()
```solidity
function isApprovedOrOwner(address _operator, uint256 _tokenId) public view virtual returns (bool)
```
**Description:** Checks if an address is approved or owner of a token.  
**Parameters:**
- `_operator` (address): Operator address
- `_tokenId` (uint256): Token ID
**Returns:** True if approved or owner  

## Transfer Functions

### transferFrom(uint256, address, uint256)
```solidity
function transferFrom(uint256 _fromTokenId, address _to, uint256 _value) public payable virtual override whenNotPaused
```
**Description:** Transfers value from one token to an address.  
**Parameters:**
- `_fromTokenId` (uint256): Source token ID
- `_to` (address): Recipient address
- `_value` (uint256): Value to transfer
**Effects:** Transfers value, may create new token  

### transferFrom(uint256, uint256, uint256)
```solidity
function transferFrom(uint256 _fromTokenId, uint256 _toTokenId, uint256 _value) public payable virtual override whenNotPaused
```
**Description:** Transfers value between two tokens.  
**Parameters:**
- `_fromTokenId` (uint256): Source token ID
- `_toTokenId` (uint256): Destination token ID
- `_value` (uint256): Value to transfer
**Effects:** Transfers value between tokens  

### transferFrom(address, address, uint256)
```solidity
function transferFrom(address _from, address _to, uint256 _tokenId) public onlyRwa1X whenNotPaused
```
**Description:** Transfers a token between addresses (cross-chain).  
**Parameters:**
- `_from` (address): Source address
- `_to` (address): Destination address
- `_tokenId` (uint256): Token ID
**Access:** Only CTMRWA1X  
**Effects:** Transfers token ownership  

### forceTransfer()
```solidity
function forceTransfer(address _from, address _to, uint256 _tokenId) public returns (bool)
```
**Description:** Force transfers a token (override wallet only).  
**Parameters:**
- `_from` (address): Source address
- `_to` (address): Destination address
- `_tokenId` (uint256): Token ID
**Access:** Only overrideWallet  
**Returns:** True if successful  

## Minting Functions

### _mint(address, uint256, string, uint256)
```solidity
function _mint(address _to, uint256 _slot, string memory _slotName, uint256 _value) internal virtual whenNotPaused
```
**Description:** Mints a new token with value.  
**Parameters:**
- `_to` (address): Recipient address
- `_slot` (uint256): Slot number
- `_slotName` (string): Slot name
- `_value` (uint256): Initial value
**Effects:** Creates new token  

### mintFromX()
```solidity
function mintFromX(address _to, uint256 _slot, string memory _slotName, uint256 _value) external whenNotPaused
```
**Description:** Mints a token from cross-chain call or ERC20 contract.  
**Parameters:**
- `_to` (address): Recipient address
- `_slot` (uint256): Slot number
- `_slotName` (string): Slot name
- `_value` (uint256): Initial value
**Access:** Authorized minters or ERC20 contracts for the specific slot  

### mintFromX(address, uint256, uint256, string, uint256)
```solidity
function mintFromX(address _to, uint256 _tokenId, uint256 _slot, string memory _slotName, uint256 _value) external onlyMinter whenNotPaused
```
**Description:** Mints a specific token ID from cross-chain call.  
**Parameters:**
- `_to` (address): Recipient address
- `_tokenId` (uint256): Token ID
- `_slot` (uint256): Slot number
- `_slotName` (string): Slot name
- `_value` (uint256): Initial value
**Access:** Only minter  

### mintValueX()
```solidity
function mintValueX(uint256 _toTokenId, uint256 _slot, uint256 _value) external onlyMinter whenNotPaused returns (bool)
```
**Description:** Mints value to an existing token.  
**Parameters:**
- `_toTokenId` (uint256): Target token ID
- `_slot` (uint256): Slot number
- `_value` (uint256): Value to mint
**Access:** Only minter  
**Returns:** True if successful  

## Burning Functions

### burn()
```solidity
function burn(uint256 _tokenId) public virtual whenNotPaused
```
**Description:** Burns a token.  
**Parameters:**
- `_tokenId` (uint256): Token ID to burn
**Effects:** Destroys token  

### burnValueX()
```solidity
function burnValueX(uint256 _fromTokenId, uint256 _value) external onlyMinter whenNotPaused returns (bool)
```
**Description:** Burns value from a token.  
**Parameters:**
- `_fromTokenId` (uint256): Source token ID
- `_value` (uint256): Value to burn
**Access:** Only minter  
**Returns:** True if successful  

## ERC20 Integration Functions

### setErc20()
```solidity
function setErc20(address _erc20, uint256 _slot) external onlyErc20Deployer
```
**Description:** Sets the ERC20 contract address for a specific slot.  
**Parameters:**
- `_erc20` (address): ERC20 contract address
- `_slot` (uint256): Slot number
**Access:** Only ERC20 deployer  
**Requirements:** Slot must exist and no ERC20 already set for this slot

### getErc20()
```solidity
function getErc20(uint256 _slot) public view returns (address)
```
**Description:** Returns the ERC20 wrapper address for a slot.  
**Parameters:**
- `_slot` (uint256): Slot number
**Returns:** ERC20 wrapper address  

### createOriginalTokenId()
```solidity
function createOriginalTokenId() external onlyErc20Deployer returns (uint256)
```
**Description:** Creates an original token ID for ERC20 integration.  
**Access:** Only ERC20 deployer  
**Returns:** New token ID

## ERC20 Approval System

### approveErc20()
```solidity
function approveErc20(uint256 tokenId) external
```
**Description:** Approves a tokenId to be spent by the ERC20 contract for its slot.  
**Parameters:**
- `tokenId` (uint256): Token ID to approve
**Requirements:** 
- Caller must be the owner of the tokenId
- ERC20 contract must exist for the token's slot
- TokenId must not already be approved
**Effects:** Adds tokenId to the owner's ERC20 approvals array

### revokeApproval()
```solidity
function revokeApproval(uint256 tokenId) external
```
**Description:** Revokes ERC20 approval for a tokenId.  
**Parameters:**
- `tokenId` (uint256): Token ID to revoke approval for
**Requirements:** Caller must be the owner of the tokenId
**Effects:** Removes tokenId from the owner's ERC20 approvals array

### getErc20Approvals()
```solidity
function getErc20Approvals(address _owner, uint256 _slot) external view returns (uint256[] memory)
```
**Description:** Returns the array of tokenIds approved for ERC20 spending by an owner in a specific slot.  
**Parameters:**
- `_owner` (address): Owner address
- `_slot` (uint256): Slot number
**Returns:** Array of approved tokenIds

### clearApprovedValuesFromERC20()
```solidity
function clearApprovedValuesFromERC20(uint256 _tokenId) external onlyERC20
```
**Description:** Clears all value approvals for a tokenId (called by ERC20 contracts).  
**Parameters:**
- `_tokenId` (uint256): Token ID
**Access:** Only authorized ERC20 contracts  

## Utility Functions

### exists()
```solidity
function exists(uint256 _tokenId) external view virtual returns (bool)
```
**Description:** Checks if a token exists.  
**Parameters:**
- `_tokenId` (uint256): Token ID
**Returns:** True if token exists  

### spendAllowance()
```solidity
function spendAllowance(address _operator, uint256 _tokenId, uint256 _value) public virtual
```
**Description:** Spends allowance for an operator on a token.  
**Parameters:**
- `_operator` (address): Operator address
- `_tokenId` (uint256): Token ID
- `_value` (uint256): Value to spend
**Effects:** Reduces allowance  

## Cross-Chain Integration Functions

### approveFromX()
```solidity
function approveFromX(address _to, uint256 _tokenId) external
```
**Description:** Approves an address from cross-chain call or ERC20 contract.  
**Parameters:**
- `_to` (address): Approved address
- `_tokenId` (uint256): Token ID
**Access:** CTMRWA1X, RWA1XFallback, or authorized ERC20 contracts  

### clearApprovedValues()
```solidity
function clearApprovedValues(uint256 _tokenId) external onlyRwa1X
```
**Description:** Clears all value approvals for a token.  
**Parameters:**
- `_tokenId` (uint256): Token ID
**Access:** Only CTMRWA1X  

### clearApprovedValuesErc20()
```solidity
function clearApprovedValuesErc20(uint256 _tokenId) external onlyErc20Deployer
```
**Description:** Clears value approvals for ERC20 integration.  
**Parameters:**
- `_tokenId` (uint256): Token ID
**Access:** Only ERC20 deployer  

### removeTokenFromOwnerEnumeration()
```solidity
function removeTokenFromOwnerEnumeration(address _from, uint256 _tokenId) external onlyRwa1X
```
**Description:** Removes token from owner enumeration (cross-chain).  
**Parameters:**
- `_from` (address): Owner address
- `_tokenId` (uint256): Token ID
**Access:** Only CTMRWA1X  

## Access Control Modifiers

- `onlyTokenAdmin`: Restricts access to tokenAdmin
- `onlyRwa1X`: Restricts access to CTMRWA1X contract
- `onlyCtmMap`: Restricts access to CTMRWAMap contract
- `onlyTokenFactory`: Restricts access to tokenFactory
- `onlyMinter`: Restricts access to authorized minters
- `onlyERC20`: Restricts access to authorized ERC20 contracts
- `onlyErc20Deployer`: Restricts access to ERC20 deployer
- `whenNotPaused`: Ensures contract is not paused

## Events

The contract emits various events for:
- Token transfers
- Value transfers
- Approvals
- Minting operations
- Burning operations
- Slot creation
- Admin changes

## Security Features

- **ReentrancyGuard**: Protects against reentrancy attacks
- **Pausable**: Allows pausing of critical functions
- **Access Control**: Comprehensive role-based access control
- **Override Wallet**: Emergency transfer capability
- **Cross-Chain Validation**: Secure cross-chain operations

## Integration Points

- **CTMRWA1X**: Cross-chain operations
- **CTMRWAMap**: Component address mapping
- **CTMRWA1Sentry**: Access control and KYC
- **CTMRWA1Storage**: Decentralized storage
- **CTMRWA1Dividend**: Dividend management
- **ERC20 Wrappers**: Slot-specific ERC20 tokens
