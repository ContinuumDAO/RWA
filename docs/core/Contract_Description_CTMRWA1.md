# CTMRWA1 Contract Documentation

## Overview

**Contract Name:** CTMRWA1  
**Author:** @Selqui ContinuumDAO  
**License:** MIT  
**Solidity Version:** 0.8.27

The CTMRWA1 contract is an AssetX Multi-chain Semi-Fungible-Token for Real-World-Assets (RWAs). The basic functionality relating to the Semi Fungible Token is derived from ERC3525 (https://eips.ethereum.org/EIPS/eip-3525), but **CTMRWA1 is NOT ERC3525 compliant**.

This token can be deployed many times and on multiple chains from CTMRWA1X. Each CTMRWA1 corresponds to a single RWA and is deployed on each chain.

## Key Features

- **Multi-chain Support:** Each CTMRWA1 corresponds to a single RWA deployed across multiple chains
- **Semi-Fungible Tokens:** Based on ERC3525 concepts but with custom implementation
- **Slot-based System:** Tokens are organized into slots with different characteristics
- **Cross-chain Architecture:** Integrated with CTMRWA1X for cross-chain operations
- **Regulatory Compliance:** Built-in support for regulatory oversight and compliance
- **Access Control:** Comprehensive permission system with multiple roles

## Public Variables

### Core Identifiers
- **`ID`** (uint256): Unique identifier linking CTMRWA1 across chains - same ID on every chain
- **`VERSION`** (uint256, constant): Single integer version of this RWA type (value: 1)
- **`RWA_TYPE`** (uint256, constant): RWA type defining CTMRWA1 (value: 1)

### Administrative Addresses
- **`tokenAdmin`** (address): Address of the wallet controlling the RWA, also known as the Issuer
- **`ctmRwaDeployer`** (address): Single contract on each chain which deploys the components of a CTMRWA1
- **`overrideWallet`** (address): If defined by the tokenAdmin, is a wallet that can forceTransfer assets from any holder
- **`ctmRwaMap`** (address): Single contract which maps the multi-chain ID to the component address of each part of the CTMRWA1
- **`ctmRwa1X`** (address): Single contract on each chain responsible for deploying, minting, and transferring the CTMRWA1 and its components
- **`rwa1XFallback`** (address): Contract responsible for dealing with failed cross-chain calls from ctmRwa1X

### Component Addresses
- **`dividendAddr`** (address): Contract managing dividend payments to CTMRWA1 holders
- **`storageAddr`** (address): Contract managing decentralized storage of information for CTMRWA1
- **`sentryAddr`** (address): Contract controlling access to the CTMRWA1
- **`tokenFactory`** (address): Contract that directly deploys this contract
- **`erc20Deployer`** (address): Contract which allows deployment of an ERC20 representing any slot of a CTMRWA1

### Token Metadata
- **`baseURI`** (string): String identifying how information is stored about the CTMRWA1. Can be set to "GFLD", "IPFS", or "NONE"

### Slot Management
- **`slotNumbers`** (uint256[]): Array holding the slots defined for this CTMRWA1
- **`slotNames`** (string[]): Array holding the names of each slot in this CTMRWA1
- **`_allSlots`** (SlotData[]): Array of all slot data structures
- **`allSlotsIndex`** (mapping(uint256 => uint256)): Mapping from slot number to index in _allSlots array

## Data Structures

### TokenData
```solidity
struct TokenData {
    uint256 id;           // Unique token identifier
    uint256 slot;         // Slot number this token belongs to
    uint256 balance;      // Fungible balance of the token
    address owner;        // Address that owns this token
    address approved;     // Address approved to transfer this token
    address[] valueApprovals; // Array of addresses approved to spend value
}
```

### AddressData
```solidity
struct AddressData {
    uint256[] ownedTokens;                    // Array of token IDs owned by this address
    mapping(uint256 => uint256) ownedTokensIndex; // Mapping from token ID to index in ownedTokens array
}
```

### SlotData
```solidity
struct SlotData {
    uint256 slot;         // Slot number
    string slotName;      // Name of the slot
    uint256[] slotTokens; // Array of token IDs in this slot
}
```

## Core Functions

### Constructor

#### `constructor(address _tokenAdmin, address _map, string memory tokenName_, string memory symbol_, uint8 decimals_, string memory baseURI_, address _ctmRwa1X)`
- **Purpose:** Initializes a new CTMRWA1 contract instance
- **Parameters:**
  - `_tokenAdmin`: Address of the wallet controlling the RWA (Issuer)
  - `_map`: Address of the CTMRWA map contract for multi-chain coordination
  - `tokenName_`: Name of the token collection
  - `symbol_`: Symbol of the token collection
  - `decimals_`: Number of decimal places for token values
  - `baseURI_`: String identifying storage method ("GFLD", "IPFS", or "NONE")
  - `_ctmRwa1X`: Address of the CTMRWA1X cross-chain coordination contract
- **Initialization:**
  - Sets tokenAdmin and ctmRwaMap addresses
  - Initializes tokenId generator to 1
  - Sets token metadata (name, symbol, decimals, baseURI)
  - Configures ctmRwa1X and derives related addresses:
    - rwa1XFallback from CTMRWA1X contract
    - ctmRwaDeployer from CTMRWA1X contract
    - tokenFactory from CTMRWADeployer contract
    - erc20Deployer from CTMRWADeployer contract

### Administrative Functions

#### `changeAdmin(address _tokenAdmin)`
- **Access:** Only callable by CTMRWA1X
- **Purpose:** Changes the tokenAdmin for this CTMRWA1
- **Security:** Resets the override wallet for safety
- **Returns:** True if admin was changed successfully

#### `setOverrideWallet(address _overrideWallet)`
- **Access:** Only callable by tokenAdmin
- **Purpose:** Sets the override wallet that can force transfers
- **Requirements:** 
  - Regulator wallet must be set in CTMRWA1Storage
  - Token admin must have fully described Issuer details
  - Security license from regulator must be obtained
- **Security:** Override wallet should be a multi-sig or MPC TSS wallet

#### `pause()` / `unpause()` / `isPaused()`
- **Access:** Only callable by tokenAdmin or CTMRWA1X
- **Purpose:** Controls the paused state of the contract

### Token Information Functions

#### `name()` / `symbol()` / `valueDecimals()`
- **Purpose:** Returns basic token metadata
- **Returns:** Token name, symbol, and decimal places

#### `idOf(uint256 _tokenId)`
- **Purpose:** Returns the id of a user-held token
- **Returns:** The id of the specified token

#### `balanceOf(uint256 _tokenId)`
- **Purpose:** Returns the fungible balance of a token
- **Returns:** The balance of the specified token

#### `balanceOf(address _owner)`
- **Purpose:** Returns the number of tokenIds owned by a wallet
- **Returns:** Number of tokens owned by the address

#### `balanceOf(address _owner, uint256 _slot)`
- **Purpose:** Returns the total balance of all tokenIds owned by a wallet in a specific slot
- **Returns:** Total balance in the specified slot

#### `balanceOfAt(address _owner, uint256 _slot, uint256 _timestamp)`
- **Purpose:** Returns the balance at a specific historical timestamp
- **Returns:** Historical balance at the specified timestamp

#### `ownerOf(uint256 _tokenId)`
- **Purpose:** Returns the address of the owner of a token
- **Returns:** Owner address of the specified token

#### `slotOf(uint256 _tokenId)` / `slotNameOf(uint256 _tokenId)`
- **Purpose:** Returns the slot number and name of a token
- **Returns:** Slot number and slot name

#### `getTokenInfo(uint256 _tokenId)`
- **Purpose:** Returns comprehensive information about a token
- **Returns:** Token id, balance, owner, slot, slot name, and token admin

### Transfer and Approval Functions

#### `approve(uint256 _tokenId, address _to, uint256 _value)`
- **Purpose:** Approves spending of fungible balance from a tokenId
- **Access:** Owner or approved operator
- **Events:** Emits ApprovalValue event

#### `allowance(uint256 _tokenId, address _operator)`
- **Purpose:** Returns the allowance to spend from a tokenId's fungible balance
- **Returns:** Current allowance amount

#### `transferFrom(uint256 _fromTokenId, address _to, uint256 _value)`
- **Purpose:** Transfers value from a tokenId to a new address (creates new tokenId)
- **Access:** Only callable by CTMRWA1X
- **Returns:** New tokenId created

#### `transferFrom(uint256 _fromTokenId, uint256 _toTokenId, uint256 _value)`
- **Purpose:** Transfers value between two existing tokenIds
- **Access:** Requires spend allowance
- **Returns:** Owner of destination tokenId

#### `transferFrom(address _from, address _to, uint256 _tokenId)`
- **Purpose:** Transfers a tokenId between addresses
- **Access:** Only callable by CTMRWA1X
- **Requirements:** Token must be approved for transfer or owned by _from

#### `forceTransfer(address _from, address _to, uint256 _tokenId)`
- **Purpose:** Allows override wallet to force transfer any tokenId
- **Access:** Only callable by override wallet
- **Returns:** True if transfer successful

### Minting and Burning Functions

#### `mintFromX(address _to, uint256 _slot, string memory _slotName, uint256 _value)`
- **Purpose:** Mints a new tokenId with value to a specific slot
- **Access:** Only callable by authorized minters
- **Returns:** New tokenId created

#### `mintFromX(address _to, uint256 _tokenId, uint256 _slot, string memory _slotName, uint256 _value)`
- **Purpose:** Mints value to a specific existing tokenId
- **Access:** Only callable by authorized minters

#### `mintValueX(uint256 _toTokenId, uint256 _slot, uint256 _value)`
- **Purpose:** Mints value to an existing tokenId
- **Access:** Only callable by authorized minters
- **Requirements:** Slot must match, address must be whitelisted (if enabled)

#### `burn(uint256 _tokenId)`
- **Purpose:** Burns a tokenId completely
- **Access:** Owner or approved operator

#### `burnValueX(uint256 _fromTokenId, uint256 _value)`
- **Purpose:** Burns value from an existing tokenId
- **Access:** Only callable by authorized minters
- **Returns:** True if burn successful

### Slot Management Functions

#### `slotCount()`
- **Purpose:** Returns the number of slots in the CTMRWA1
- **Returns:** Total number of slots

#### `getAllSlots()`
- **Purpose:** Returns arrays of all slot numbers and names
- **Returns:** Arrays of slot numbers and slot names

#### `getSlotInfoByIndex(uint256 _indx)`
- **Purpose:** Returns slot data by index
- **Returns:** SlotData struct for the specified index

#### `initializeSlotData(uint256[] memory _slotNumbers, string[] memory _slotNames)`
- **Purpose:** Initializes slot data on a newly deployed chain
- **Access:** Only callable by tokenFactory
- **Requirements:** Arrays must have same length, slots must not already be initialized

#### `slotName(uint256 _slot)` / `slotByIndex(uint256 _index)` / `slotExists(uint256 _slot)`
- **Purpose:** Slot information and validation functions
- **Returns:** Slot name, slot number, or existence status

#### `tokenSupplyInSlot(uint256 _slot)` / `totalSupplyInSlot(uint256 _slot)`
- **Purpose:** Returns supply information for a specific slot
- **Returns:** Number of tokens or total balance in the slot

#### `totalSupplyInSlotAt(uint256 _slot, uint256 _timestamp)`
- **Purpose:** Returns historical total supply in a slot
- **Returns:** Total supply at the specified timestamp

#### `tokenInSlotByIndex(uint256 _slot, uint256 _index)`
- **Purpose:** Returns tokenId at specific index in a slot
- **Returns:** TokenId at the specified index

### ERC20 Integration Functions

#### `deployErc20(uint256 _slot, string memory _erc20Name, address _feeToken)`
- **Purpose:** Deploys an ERC20 representing a specific slot
- **Access:** Only callable by tokenAdmin
- **Requirements:** 
  - Slot must exist
  - ERC20 must not already exist for this slot
  - Name must be 128 characters or less
- **Note:** Can only be called once per slot

#### `getErc20(uint256 _slot)`
- **Purpose:** Returns the address of the ERC20 token representing a slot
- **Returns:** ERC20 contract address for the slot

### Utility Functions

#### `totalSupply()`
- **Purpose:** Returns the total number of tokenIds in this CTMRWA1
- **Returns:** Total number of tokens

#### `tokenOfOwnerByIndex(address _owner, uint256 _index)`
- **Purpose:** Returns tokenId at specific index for an owner
- **Returns:** TokenId at the specified index

#### `exists(uint256 _tokenId)`
- **Purpose:** Checks if a tokenId exists
- **Returns:** True if tokenId exists

#### `getApproved(uint256 _tokenId)`
- **Purpose:** Returns the address approved to transfer a tokenId
- **Returns:** Approved address

#### `isApprovedOrOwner(address _operator, uint256 _tokenId)`
- **Purpose:** Checks if an address is approved or owner of a tokenId
- **Returns:** True if operator is approved or owner

#### `spendAllowance(address _operator, uint256 _tokenId, uint256 _value)`
- **Purpose:** Spends allowance for value transfer
- **Requirements:** Must have sufficient allowance

## Internal Functions

### Token Management
- **`_exists(uint256 _tokenId)`**: Checks if tokenId exists
- **`_mint(address _to, uint256 _slot, string memory _slotName, uint256 _value)`**: Internal minting function
- **`_mint(address _to, uint256 _tokenId, uint256 _slot, string memory _slotName, uint256 _value)`**: Low-level minting
- **`_mintValue(uint256 _tokenId, uint256 _value)`**: Mints value to existing tokenId
- **`__mintValue(uint256 _tokenId, uint256 _value)`**: Lowest level mint function
- **`__mintToken(address _to, uint256 _tokenId, uint256 _slot)`**: Mints new token using new tokenId
- **`_burn(uint256 _tokenId)`**: Internal burn function
- **`_burnValue(uint256 _tokenId, uint256 _value)`**: Burns value from existing tokenId

### Transfer Functions
- **`_transferValue(uint256 _fromTokenId, uint256 _toTokenId, uint256 _value)`**: Transfers value between tokenIds
- **`_transferTokenId(address _from, address _to, uint256 _tokenId)`**: Transfers tokenId ownership
- **`_beforeValueTransfer(...)`**: Hook called before value transfer
- **`_afterValueTransfer(...)`**: Hook called after value transfer

### Approval Functions
- **`_approve(address _to, uint256 _tokenId)`**: Internal approval function
- **`_approveValue(uint256 _tokenId, address _to, uint256 _value)`**: Approves value spending
- **`_clearApprovedValues(uint256 _tokenId)`**: Clears all value approvals
- **`_existApproveValue(address _to, uint256 _tokenId)`**: Checks if value approval exists

### Enumeration Functions
- **`_addTokenToOwnerEnumeration(address _to, uint256 _tokenId)`**: Adds token to owner's enumeration
- **`_removeTokenFromOwnerEnumeration(address _from, uint256 _tokenId)`**: Removes token from owner's enumeration
- **`_addTokenToAllTokensEnumeration(TokenData memory _tokenData)`**: Adds token to all tokens enumeration
- **`_removeTokenFromAllTokensEnumeration(uint256 _tokenId)`**: Removes token from all tokens enumeration
- **`_addTokenToSlotEnumeration(uint256 _slot, uint256 _tokenId)`**: Adds token to slot enumeration
- **`_removeTokenFromSlotEnumeration(uint256 _slot, uint256 _tokenId)`**: Removes token from slot enumeration
- **`_addSlotToAllSlotsEnumeration(SlotData memory _slotData)`**: Adds slot to all slots enumeration

### Slot Management
- **`_createSlot(uint256 _slot, string memory _slotName)`**: Creates new slot
- **`_tokenExistsInSlot(uint256 _slot, uint256 _tokenId)`**: Checks if token exists in slot

### Utility Functions
- **`_createOriginalTokenId()`**: Creates new tokenId
- **`_checkOnCTMRWA1Received(...)`**: Hook for token receiver validation

## Access Control Modifiers

- **`onlyTokenAdmin`**: Restricts access to tokenAdmin or CTMRWA1X
- **`onlyErc20Deployer`**: Restricts access to ERC20 deployer contracts
- **`onlyTokenFactory`**: Restricts access to token factory
- **`onlyCtmMap`**: Restricts access to CTMRWA map contract
- **`onlyRwa1X`**: Restricts access to CTMRWA1X or fallback contract
- **`onlyMinter`**: Restricts access to authorized minters
- **`onlyERC20`**: Restricts access to ERC20 contracts

## Events

The contract emits standard ERC721-like events plus custom events for value transfers and slot changes:

- **`Transfer(address indexed from, address indexed to, uint256 indexed tokenId)`**: Token transfer
- **`Approval(address indexed owner, address indexed approved, uint256 indexed tokenId)`**: Token approval
- **`TransferValue(uint256 indexed fromTokenId, uint256 indexed toTokenId, uint256 value)`**: Value transfer
- **`ApprovalValue(uint256 indexed tokenId, address indexed operator, uint256 value)`**: Value approval
- **`SlotChanged(uint256 indexed tokenId, uint256 indexed oldSlot, uint256 indexed newSlot)`**: Slot change

## Security Features

1. **Pausable:** Contract can be paused by authorized parties
2. **Reentrancy Protection:** Uses OpenZeppelin's ReentrancyGuard
3. **Access Control:** Comprehensive modifier system for different roles
4. **Override Wallet:** Regulatory oversight capability for forced transfers
5. **Whitelisting:** Optional address whitelisting through Sentry contract
6. **Value Overflow Protection:** Checks for uint208 overflow in value operations
7. **Cross-chain Security:** Integration with CTMRWA1X for secure cross-chain operations

## Integration Points

- **CTMRWA1X**: Main cross-chain coordination contract
- **CTMRWA1Sentry**: Access control and whitelisting
- **CTMRWA1Storage**: Decentralized storage for RWA information
- **CTMRWA1Dividend**: Dividend distribution system
- **CTMRWAERC20Deployer**: ERC20 token deployment for slots
- **CTMRWAMap**: Multi-chain address mapping

## Error Handling

The contract uses custom error types for efficient gas usage and clear error messages, including:

- Authorization errors
- Zero address checks
- Invalid slot errors
- Insufficient balance/allowance errors
- Non-existent token errors
- Overflow protection errors
