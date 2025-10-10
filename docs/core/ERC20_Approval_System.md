# ERC20 Approval System Documentation

## Overview

The ERC20 Approval System is a new security feature implemented in CTMRWA1 that provides fine-grained control over which tokenIds can be spent by ERC20 contracts. This system enhances security by requiring explicit user approval before tokenIds can be used in ERC20 operations.

## Key Features

- **Selective Approval:** Users can choose which specific tokenIds to approve for ERC20 spending
- **Slot-based Organization:** Approvals are organized by slot for efficient management
- **Array-based Storage:** Uses efficient array storage with swap-and-pop removal
- **Gas Optimization:** ERC20 transfers only process approved tokenIds
- **User Control:** Complete user control over which tokens can be spent
- **Security Enhancement:** Prevents unauthorized spending of unapproved tokenIds

## Data Structure

### ERC20 Approvals Mapping
```solidity
mapping(address => mapping(uint256 => uint256[])) _erc20Approvals;
```

**Structure:**
- **First Key (address):** Owner address
- **Second Key (uint256):** Slot number
- **Value (uint256[]):** Array of approved tokenIds

**Example:**
```solidity
_erc20Approvals[0x123...][1] = [1001, 1002, 1003]; // User 0x123... has approved tokenIds 1001, 1002, 1003 in slot 1
```

## Core Functions

### approveErc20()
```solidity
function approveErc20(uint256 tokenId) external
```

**Purpose:** Approves a tokenId for ERC20 spending

**Parameters:**
- `tokenId` (uint256): Token ID to approve

**Requirements:**
- Caller must be the owner of the tokenId
- ERC20 contract must exist for the token's slot
- TokenId must not already be approved

**Effects:**
- Adds tokenId to the owner's ERC20 approvals array
- TokenId can now be spent by the ERC20 contract

**Example:**
```solidity
// User approves tokenId 1001 for ERC20 spending
token.approveErc20(1001);
```

### revokeApproval()
```solidity
function revokeApproval(uint256 tokenId) external
```

**Purpose:** Revokes ERC20 approval for a tokenId

**Parameters:**
- `tokenId` (uint256): Token ID to revoke approval for

**Requirements:**
- Caller must be the owner of the tokenId

**Effects:**
- Removes tokenId from the owner's ERC20 approvals array
- TokenId can no longer be spent by the ERC20 contract

**Example:**
```solidity
// User revokes approval for tokenId 1001
token.revokeApproval(1001);
```

### getErc20Approvals()
```solidity
function getErc20Approvals(address _owner, uint256 _slot) external view returns (uint256[] memory)
```

**Purpose:** Returns the array of approved tokenIds for an owner in a specific slot

**Parameters:**
- `_owner` (address): Owner address
- `_slot` (uint256): Slot number

**Returns:**
- `uint256[]`: Array of approved tokenIds

**Example:**
```solidity
// Get approved tokenIds for user in slot 1
uint256[] memory approved = token.getErc20Approvals(user, 1);
```

## Internal Functions

### _revokeErc20Approval()
```solidity
function _revokeErc20Approval(uint256 _tokenId) internal
```

**Purpose:** Internal function to remove a tokenId from approvals array

**Parameters:**
- `_tokenId` (uint256): Token ID to remove

**Logic:**
1. Gets the owner and slot of the tokenId
2. Finds the tokenId in the approvals array
3. Uses swap-and-pop pattern to remove it efficiently
4. Maintains array integrity

**Benefits:**
- Gas efficient removal
- Maintains array order
- No gaps in the array

## Error Handling

### Custom Errors
- **`CTMRWA1_ERC20NonExistent(uint256 slot)`**: Thrown when trying to approve for a slot without an ERC20
- **`CTMRWA1_ERC20AlreadyApproved(uint256 tokenId)`**: Thrown when trying to approve an already approved tokenId

### Standard Errors
- **`CTMRWA1_OnlyAuthorized`**: Thrown when caller is not authorized
- **`CTMRWA1_NotOwner`**: Thrown when caller is not the owner of the tokenId

## Integration with ERC20 Contracts

### ERC20 Transfer Process
1. **Get Approved TokenIds:** ERC20 calls `getErc20Approvals(owner, slot)`
2. **Validate Approved Balance:** Check `balanceOfApproved(owner)` for sufficient balance
3. **Process Only Approved TokenIds:** Iterate through approved tokenIds only
4. **Transfer Values:** Transfer from approved tokenIds to new tokenId
5. **Auto-approve New TokenId:** Automatically approve new tokenId for ERC20

### Balance Functions
- **`balanceOf(owner)`**: Returns total balance from all tokenIds
- **`balanceOfApproved(owner)`**: Returns balance only from approved tokenIds

## Security Benefits

### 1. User Control
- Users have complete control over which tokenIds can be spent
- No automatic spending of all tokenIds
- Granular approval per tokenId

### 2. Gas Optimization
- ERC20 transfers only process approved tokenIds
- No need to iterate through all tokenIds
- Efficient array-based storage

### 3. Security Isolation
- Unapproved tokenIds cannot be spent by ERC20 contracts
- Clear separation between approved and unapproved tokens
- Prevents accidental spending

### 4. Audit Trail
- Clear record of which tokenIds are approved
- Easy to track approval status
- Transparent approval management

## Use Cases

### 1. Selective Spending
**Scenario:** User wants to approve only specific tokenIds for DeFi operations
```solidity
// Approve only high-value tokenIds for DeFi
token.approveErc20(highValueTokenId1);
token.approveErc20(highValueTokenId2);
// Keep other tokenIds unapproved for safety
```

### 2. Temporary Approvals
**Scenario:** User wants to temporarily approve tokenIds for a specific operation
```solidity
// Approve tokenIds for operation
token.approveErc20(tokenId1);
token.approveErc20(tokenId2);

// Perform ERC20 operations
erc20.transfer(recipient, amount);

// Revoke approvals after operation
token.revokeApproval(tokenId1);
token.revokeApproval(tokenId2);
```

### 3. Portfolio Management
**Scenario:** User wants to separate tokens for different purposes
```solidity
// Approve tokens for trading
token.approveErc20(tradingTokenId1);
token.approveErc20(tradingTokenId2);

// Keep other tokens unapproved for long-term holding
// These cannot be spent by ERC20 contracts
```

## Best Practices

### 1. Approval Management
- **Selective Approval:** Only approve tokenIds you want to spend
- **Regular Review:** Periodically review and revoke unnecessary approvals
- **Batch Operations:** Use batch approval/revocation for efficiency

### 2. Security Considerations
- **Minimal Approvals:** Approve only what you need
- **Revoke After Use:** Revoke approvals after completing operations
- **Monitor Approvals:** Keep track of approved tokenIds

### 3. Gas Optimization
- **Batch Approvals:** Approve multiple tokenIds in one transaction
- **Efficient Revocation:** Use revokeApproval for individual tokenIds
- **Array Management:** The system automatically manages array efficiency

## Migration from Previous System

### Before (All TokenIds Available)
- All tokenIds in a slot were available for ERC20 spending
- No user control over which tokens could be spent
- Potential security risk from automatic spending

### After (Approval-based System)
- Only approved tokenIds can be spent by ERC20 contracts
- Users have complete control over tokenId spending
- Enhanced security through selective approval

### Migration Steps
1. **Deploy New System:** Deploy updated contracts with approval system
2. **User Education:** Educate users about the new approval requirement
3. **Approval Process:** Users must approve tokenIds for ERC20 operations
4. **Gradual Adoption:** Users can approve tokenIds as needed

## Technical Implementation

### Array Management
The system uses efficient array management with the swap-and-pop pattern:

```solidity
// Find tokenId in array
uint256 index = length; // Initialize to length (not found)
for (uint256 i = 0; i < length; i++) {
    if (approvals[i] == _tokenId) {
        index = i;
        break;
    }
}

// Remove using swap-and-pop
if (index < length) {
    if (index != length - 1) {
        approvals[index] = approvals[length - 1];
    }
    approvals.pop();
}
```

### Gas Efficiency
- **O(1) Addition:** Adding approvals is O(1)
- **O(n) Removal:** Removing approvals is O(n) where n is array length
- **O(1) Lookup:** Checking approval status is O(1) via array iteration
- **Memory Efficient:** Uses dynamic arrays for flexible storage

## Future Enhancements

### Potential Improvements
1. **Batch Operations:** Implement batch approval/revocation functions
2. **Time-based Approvals:** Add expiration time for approvals
3. **Amount-based Approvals:** Approve specific amounts rather than entire tokenIds
4. **Event Enhancement:** Add detailed events for approval tracking
5. **Interface Extensions:** Add convenience functions for common operations

### Integration Opportunities
1. **DeFi Protocols:** Enhanced integration with DeFi protocols
2. **Wallet Support:** Better wallet integration for approval management
3. **Analytics:** Approval tracking and analytics
4. **Automation:** Automated approval management tools

## Conclusion

The ERC20 Approval System provides a robust, secure, and user-controlled mechanism for managing tokenId spending in ERC20 operations. It enhances security while maintaining gas efficiency and provides users with complete control over their token approvals.

The system is designed to be:
- **Secure:** Only approved tokenIds can be spent
- **Efficient:** Gas-optimized operations
- **User-friendly:** Simple approval/revocation interface
- **Flexible:** Supports various use cases and scenarios
- **Future-proof:** Extensible design for future enhancements
