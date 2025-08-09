# ICTMRWA1 Interface Documentation

## Overview

**Contract Name:** ICTMRWA1  
**File:** `src/core/ICTMRWA1.sol`  
**License:** BSL-1.1  
**Type:** Interface  

## Contract Description

ICTMRWA1 is the main interface for the CTMRWA1 semi-fungible token standard. It defines the core functionality for Real-World Asset (RWA) tokens that can be deployed across multiple chains. This interface extends ICTMRWA and provides the complete API for semi-fungible token operations.

### Key Features
- Semi-fungible token standard interface
- Multi-chain support definitions
- Value transfer capabilities
- Slot-based token management
- Cross-chain integration functions
- Comprehensive error handling

## Data Structures

### TokenContract
```solidity
struct TokenContract {
    string chainIdStr;    // Chain identifier string
    string contractStr;   // Contract address string
}
```
**Description:** Represents a token contract on a specific chain.

### SlotData
```solidity
struct SlotData {
    uint256 slot;         // Slot number
    string slotName;      // Slot name
    uint256[] slotTokens; // Array of token IDs in this slot
}
```
**Description:** Contains information about a token slot and its associated tokens.

## Events

### Approval
```solidity
event Approval(address from, address to, uint256 tokenId);
```
**Description:** Emitted when an address is approved to transfer a specific token.

### ApprovalForAll
```solidity
event ApprovalForAll(address owner, address operator, bool approved);
```
**Description:** Emitted when an operator is approved or disapproved for all tokens of an owner.

### Transfer
```solidity
event Transfer(address from, address to, uint256 tokenId);
```
**Description:** Emitted when a token is transferred between addresses.

### TransferValue
```solidity
event TransferValue(uint256 indexed fromTokenId, uint256 indexed toTokenId, uint256 value);
```
**Description:** Emitted when value is transferred between tokens with the same slot.

### ApprovalValue
```solidity
event ApprovalValue(uint256 indexed tokenId, address indexed operator, uint256 value);
```
**Description:** Emitted when the approval value of a token is set or changed.

### SlotChanged
```solidity
event SlotChanged(uint256 indexed tokenId, uint256 indexed oldSlot, uint256 indexed newSlot);
```
**Description:** Emitted when the slot of a token is set or changed.

## Custom Errors

### Authorization Errors
- `CTMRWA1_Unauthorized(Address addr, Address unauth)`: Address cannot be unauthorized
- `CTMRWA1_OnlyAuthorized(Address addr, Address auth)`: Address must be authorized

### Address Errors
- `CTMRWA1_IsZeroAddress(Address)`: Address cannot be zero
- `CTMRWA1_NotZeroAddress(Address)`: Address must be zero

### Uint Errors
- `CTMRWA1_IsZeroUint(Uint)`: Value cannot be zero
- `CTMRWA1_NonZeroUint(Uint)`: Value must be zero
- `CTMRWA1_LengthMismatch(Uint)`: Array lengths do not match
- `CTMRWA1_ValueOverflow(uint256 value, uint256 maxValue)`: Value exceeds maximum
- `CTMRWA1_InsufficientBalance()`: Insufficient balance for operation
- `CTMRWA1_InsufficientAllowance()`: Insufficient allowance for operation
- `CTMRWA1_OutOfBounds()`: Index is out of bounds
- `CTMRWA1_NameTooLong()`: Name exceeds maximum length

### Existence Errors
- `CTMRWA1_IDNonExistent(uint256 tokenId)`: Token ID does not exist
- `CTMRWA1_IDExists(uint256 _tokenId)`: Token ID already exists
- `CTMRWA1_InvalidSlot(uint256 _slot)`: Invalid slot number

### Transfer Errors
- `CTMRWA1_ReceiverRejected()`: Transfer was rejected by receiver
- `CTMRWA1_WhiteListRejected(address _addr)`: Address rejected by whitelist

## Core Functions

### Contract Information
- `ID()`: Returns the unique identifier linking CTMRWA1 across chains
- `tokenAdmin()`: Returns the address of the token administrator
- `ctmRwa1X()`: Returns the address of the cross-chain operations contract

### Pausable Functions
- `pause()`: Pauses the contract
- `unpause()`: Unpauses the contract
- `isPaused()`: Returns true if the contract is paused

### Administrative Functions
- `setOverrideWallet(address overrideWallet)`: Sets the override wallet
- `overrideWallet()`: Returns the override wallet address
- `changeAdmin(address _admin)`: Changes the token administrator
- `attachId(uint256 nextID, address tokenAdmin)`: Attaches an ID to the contract

### Token Information
- `name()`: Returns the token collection name
- `symbol()`: Returns the token collection symbol
- `valueDecimals()`: Returns the number of decimals for token values

### Balance and Ownership
- `balanceOf(uint256 _tokenId)`: Returns the balance of a specific token
- `balanceOf(address _owner)`: Returns the total balance of all tokens owned by an address
- `balanceOf(address _owner, uint256 _slot)`: Returns the balance in a specific slot
- `balanceOfAt(address _owner, uint256 _slot, uint256 _timestamp)`: Returns historical balance
- `ownerOf(uint256 _tokenId)`: Returns the owner of a specific token

### Slot Management
- `slotOf(uint256 _tokenId)`: Returns the slot number of a token
- `slotNameOf(uint256 _tokenId)`: Returns the slot name of a token
- `slotCount()`: Returns the total number of slots
- `getAllSlots()`: Returns all slot numbers and names
- `getSlotInfoByIndex(uint256 _indx)`: Returns slot information by index
- `slotName(uint256 _slot)`: Returns the name of a slot
- `slotByIndex(uint256 _index)`: Returns the slot number at a specific index
- `slotExists(uint256 _slot)`: Checks if a slot exists

### Supply and Enumeration
- `totalSupply()`: Returns the total supply of all tokens
- `tokenByIndex(uint256 _index)`: Returns the token ID at a specific index
- `tokenOfOwnerByIndex(address _owner, uint256 _index)`: Returns the token ID owned by an address at a specific index
- `tokenSupplyInSlot(uint256 _slot)`: Returns the number of tokens in a slot
- `totalSupplyInSlot(uint256 _slot)`: Returns the total supply in a slot
- `totalSupplyInSlotAt(uint256 _slot, uint256 _timestamp)`: Returns historical total supply in a slot
- `tokenInSlotByIndex(uint256 _slot, uint256 _index)`: Returns the token ID in a slot at a specific index

### Approval Functions
- `approve(uint256 _tokenId, address _to, uint256 _value)`: Approves an address to spend a specific value from a token
- `approve(address _to, uint256 _tokenId)`: Approves an address to transfer a token
- `allowance(uint256 _tokenId, address _operator)`: Returns the approved value for an operator on a token
- `getApproved(uint256 _tokenId)`: Returns the approved address for a token
- `isApprovedOrOwner(address _operator, uint256 _tokenId)`: Checks if an address is approved or owner of a token

### Transfer Functions
- `transferFrom(uint256 _fromTokenId, address _to, uint256 _value)`: Transfers value from one token to an address
- `transferFrom(uint256 _fromTokenId, uint256 _toTokenId, uint256 _value)`: Transfers value between two tokens
- `transferFrom(address _from, address _to, uint256 _tokenId)`: Transfers a token between addresses

### Minting Functions
- `mintFromX(address _to, uint256 _slot, string memory _slotName, uint256 _value)`: Mints a token from cross-chain call
- `mintFromX(address _to, uint256 _tokenId, uint256 _slot, string memory _slotName, uint256 _value)`: Mints a specific token ID from cross-chain call
- `mintValueX(uint256 _toTokenId, uint256 _slot, uint256 _value)`: Mints value to an existing token

### Burning Functions
- `burn(uint256 _tokenId)`: Burns a token
- `burnValueX(uint256 _fromTokenId, uint256 _value)`: Burns value from a token

### ERC20 Integration
- `deployErc20(uint256 _slot, string memory _erc20Name, address _feeToken)`: Deploys an ERC20 wrapper for a slot
- `getErc20(uint256 _slot)`: Returns the ERC20 wrapper address for a slot
- `createOriginalTokenId()`: Creates an original token ID for ERC20 integration

### Utility Functions
- `exists(uint256 _tokenId)`: Checks if a token exists
- `spendAllowance(address _operator, uint256 _tokenId, uint256 _value)`: Spends allowance for an operator on a token

### Cross-Chain Integration
- `approveFromX(address _to, uint256 _tokenId)`: Approves an address from cross-chain call
- `clearApprovedValues(uint256 _tokenId)`: Clears all value approvals for a token
- `clearApprovedValuesErc20(uint256 _tokenId)`: Clears value approvals for ERC20 integration
- `removeTokenFromOwnerEnumeration(address _from, uint256 _tokenId)`: Removes token from owner enumeration

## Integration Points

- **ICTMRWA**: Base interface for RWA tokens
- **CTMRWA1**: Main implementation contract
- **Cross-chain contracts**: For multi-chain operations
- **ERC20 wrappers**: For slot-specific ERC20 tokens

## Security Considerations

- All functions include proper access control
- Comprehensive error handling for edge cases
- Support for pausable operations
- Cross-chain validation mechanisms
- Whitelist and approval systems
