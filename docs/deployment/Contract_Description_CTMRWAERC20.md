# CTMRWAERC20 Contract Documentation

## Overview

**Contract Name:** CTMRWAERC20  
**Author:** @Selqui ContinuumDAO  
**License:** BSL-1.1  
**Solidity Version:** 0.8.27

The CTMRWAERC20 contract is an ERC20 token that provides a fungible interface to the semi-fungible CTMRWA1 tokens. It represents a specific slot within a CTMRWA1 contract as a standard ERC20 token, allowing for easier integration with DeFi protocols and traditional ERC20 wallets.

This contract is deployed by the `deployERC20()` function in the `CTMRWAERC20Deployer` contract using CREATE2 for deterministic addresses. Each ERC20 token corresponds to exactly one slot in the underlying CTMRWA1 contract.

## Key Features

- **ERC20 Compliance:** Full ERC20 standard implementation with fungible token interface
- **Slot Representation:** Each ERC20 represents a specific slot in CTMRWA1
- **Dynamic Supply:** Total supply derived from CTMRWA1 slot balances
- **Cross-contract Integration:** Direct integration with CTMRWA1 for balance management
- **Reentrancy Protection:** Uses ReentrancyGuard for transfer security
- **Deterministic Deployment:** CREATE2 deployment for predictable addresses
- **Gas Optimization:** Efficient balance calculation and transfer mechanisms using approved tokenIds
- **Approval-based Transfers:** Only processes pre-approved tokenIds for enhanced security
- **Dual Balance Functions:** Separate functions for total balance and approved balance

## Public Variables

### Token Identification
- **`ID`** (uint256): The ID of the CTMRWA1 contract that created this ERC20
- **`RWA_TYPE`** (uint256, immutable): Type of RWA token contract (1 for CTMRWA1)
- **`VERSION`** (uint256, immutable): Version of the RWA token type
- **`slot`** (uint256): The slot number that this ERC20 relates to

### Token Metadata
- **`ctmRwaName`** (string): The name of this ERC20 (includes slot prefix)
- **`ctmRwaSymbol`** (string): The symbol of this ERC20
- **`ctmRwaDecimals`** (uint8): The decimals of this ERC20 (same as CTMRWA1)
- **`slotName`** (string): The corresponding slot name from CTMRWA1

### Contract Addresses
- **`ctmRwaMap`** (address): Address of the CTMRWAMap contract
- **`ctmRwaToken`** (address): Address of the CTMRWA1 contract

### Constants
- **Removed `MAX_TOKENS`**: No longer needed as approval mechanism controls the number of tokenIds

## Core Functions

### Constructor

#### `constructor(uint256 _ID, uint256 _rwaType, uint256 _version, uint256 _slot, string memory _name, string memory _symbol, address _ctmRwaMap)`
- **Purpose:** Initializes a new CTMRWAERC20 contract instance
- **Parameters:**
  - `_ID`: ID of the CTMRWA1 contract
  - `_rwaType`: Type of RWA token (1 for CTMRWA1)
  - `_version`: Version of the RWA token
  - `_slot`: Slot number this ERC20 represents
  - `_name`: Base name for the ERC20
  - `_symbol`: Symbol for the ERC20
  - `_ctmRwaMap`: Address of the CTMRWAMap contract
- **Initialization:**
  - Sets token identification parameters
  - Creates slot-prefixed name (e.g., "slot 1| TokenName")
  - Retrieves CTMRWA1 contract address from map
  - Validates slot exists in CTMRWA1
  - Gets slot name and decimals from CTMRWA1
- **Validation:** Ensures slot exists in the underlying CTMRWA1 contract

### ERC20 Interface Functions

#### `name()`
- **Purpose:** Returns the ERC20 name with slot prefix
- **Returns:** `ctmRwaName` - The name of the ERC20 (e.g., "slot 1| MyToken")
- **Override:** Overrides both ERC20 and ICTMRWAERC20 interfaces

#### `symbol()`
- **Purpose:** Returns the ERC20 symbol
- **Returns:** `ctmRwaSymbol` - The symbol of the ERC20
- **Override:** Overrides both ERC20 and ICTMRWAERC20 interfaces

#### `decimals()`
- **Purpose:** Returns the ERC20 decimals (same as CTMRWA1)
- **Returns:** `ctmRwaDecimals` - The decimals of the ERC20
- **Override:** Overrides both ERC20 and ICTMRWAERC20 interfaces

#### `totalSupply()`
- **Purpose:** Returns the total supply derived from CTMRWA1 slot balances
- **Logic:** Sums all fungible balances across all tokenIds in the slot
- **Returns:** Total supply of the ERC20
- **Override:** Overrides both ERC20 and IERC20 interfaces

#### `balanceOf(address _account)`
- **Purpose:** Returns the total balance of a specific account in this slot
- **Parameters:** `_account` - Wallet address to check balance for
- **Logic:** Sums fungible balances of all tokenIds in this slot for the account
- **Returns:** Total balance of the account in this slot
- **Override:** Overrides both ERC20 and IERC20 interfaces

#### `balanceOfApproved(address _account)`
- **Purpose:** Returns the balance from only approved tokenIds for a specific account
- **Parameters:** `_account` - Wallet address to check approved balance for
- **Logic:** Sums fungible balances of only pre-approved tokenIds for ERC20 spending
- **Returns:** Approved balance of the account in this slot
- **Use Case:** Used internally for transfer validation and by external contracts

#### `allowance(address _owner, address _spender)`
- **Purpose:** Returns the ERC20 allowance of spender on behalf of owner
- **Parameters:**
  - `_owner`: Owner of the tokenIds granting approval
  - `_spender`: Recipient being granted approval
- **Returns:** Allowance amount
- **Override:** Overrides both ERC20 and IERC20 interfaces

### Transfer Functions

#### `approve(address _spender, uint256 _value)`
- **Purpose:** Grant approval to a spender to spend fungible value from the slot
- **Parameters:**
  - `_spender`: Wallet address being granted approval
  - `_value`: Fungible value being approved
- **Returns:** True if approval was successful
- **Override:** Overrides both ERC20 and IERC20 interfaces

#### `transfer(address _to, uint256 _value)`
- **Purpose:** Transfer fungible value to another wallet from caller's balance
- **Parameters:**
  - `_to`: Recipient of the transfer
  - `_value`: Fungible amount being transferred
- **Logic:** Takes value from first tokenId owned by caller, then second, etc.
- **Security:** Uses nonReentrant modifier for transfer protection
- **Returns:** True if transfer was successful
- **Override:** Overrides both ERC20 and IERC20 interfaces

#### `transferFrom(address _from, address _to, uint256 _value)`
- **Purpose:** Transfer value from one wallet to another (requires allowance)
- **Parameters:**
  - `_from`: Wallet being debited
  - `_to`: Wallet being credited
  - `_value`: Fungible amount being transferred
- **Logic:** Spends allowance and transfers value across tokenIds
- **Security:** Uses nonReentrant modifier for transfer protection
- **Returns:** True if transfer was successful
- **Override:** Overrides both ERC20 and IERC20 interfaces

## Internal Functions

### Approval Management
- **`_approve(address _owner, address _spender, uint256 _value, bool _emitEvent)`**: Low-level approval function
  - Validates spender is not zero address
  - Calls parent ERC20 approval logic
  - Controls event emission

### Transfer Management
- **`_update(address _from, address _to, uint256 _value)`**: Core transfer logic
  - Gets array of approved tokenIds from CTMRWA1
  - Validates sufficient approved balance in slot
  - Iterates through only approved tokenIds for gas efficiency
  - Creates new tokenId for recipient
  - Transfers value from source tokenIds to new tokenId
  - Handles partial transfers across multiple approved tokenIds
  - Automatically approves new tokenId for ERC20 contract
  - Emits Transfer event

### Allowance Management
- **`_spendAllowance(address _owner, address _spender, uint256 _value)`**: Spend allowance logic
  - Checks current allowance against required value
  - Updates allowance if not unlimited
  - Handles allowance reduction

## Access Control Modifiers

The contract does not use custom access control modifiers, as it follows standard ERC20 patterns where any address can interact with the token functions.

## Events

The contract inherits standard ERC20 events:
- **`Transfer(address indexed from, address indexed to, uint256 value)`**: Emitted on token transfers
- **`Approval(address indexed owner, address indexed spender, uint256 value)`**: Emitted on approval changes

## Security Features

1. **Reentrancy Protection:** Uses ReentrancyGuard for transfer functions
2. **Zero Address Validation:** Prevents approval to zero address
3. **Approval-based Balance Validation:** Ensures sufficient approved balance before transfers
4. **Allowance Validation:** Validates allowance before transferFrom
5. **ERC20 Approval System:** Only processes pre-approved tokenIds for enhanced security
6. **Immutable Parameters:** Critical parameters are immutable
7. **Cross-contract Validation:** Validates slot existence in CTMRWA1
8. **Automatic Approval Management:** Automatically approves new tokenIds for ERC20 contract

## Integration Points

- **CTMRWA1**: Core semi-fungible token contract providing balance data
- **CTMRWAMap**: Contract address registry for CTMRWA1 lookup
- **CTMRWAERC20Deployer**: Factory contract that creates ERC20 instances
- **DeFi Protocols**: Standard ERC20 integration for liquidity and trading
- **Wallets**: Standard ERC20 wallet support

## Error Handling

The contract uses custom error types for efficient gas usage:

- **`CTMRWAERC20_InvalidContract(CTMRWAErrorParam.Token)`**: Thrown when CTMRWA1 contract not found
- **`CTMRWAERC20_NonExistentSlot(uint256 slot)`**: Thrown when slot doesn't exist in CTMRWA1
- **`CTMRWAERC20_IsZeroAddress(CTMRWAErrorParam.Spender)`**: Thrown when approving zero address

Standard ERC20 errors are also used:
- **`ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed)`**: Insufficient balance
- **`ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed)`**: Insufficient allowance

## Transfer Process

### 1. Approved TokenId Retrieval
- **Step:** Get array of approved tokenIds for sender and slot
- **Method:** Call CTMRWA1.getErc20Approvals(sender, slot)
- **Result:** Array of tokenIds approved for ERC20 spending

### 2. Approved Balance Validation
- **Step:** Check if sender has sufficient approved balance
- **Method:** Call balanceOfApproved(sender) to sum approved tokenId balances
- **Result:** Proceed if sufficient, revert if insufficient

### 3. Approved TokenId Iteration
- **Step:** Iterate through only approved tokenIds
- **Method:** Process approved tokenIds array from step 1
- **Benefit:** Gas efficient - only processes relevant tokenIds

### 4. New TokenId Creation
- **Step:** Create new tokenId for recipient
- **Method:** Call CTMRWA1.mintFromX(recipient, slot, slotName, 0)
- **Result:** New tokenId owned by recipient

### 5. Value Transfer
- **Step:** Transfer value from approved tokenIds to new tokenId
- **Method:** Use CTMRWA1.transferFrom for each approved tokenId
- **Logic:** Handle partial transfers across multiple approved tokenIds

### 6. Automatic Approval
- **Step:** Approve new tokenId for ERC20 contract
- **Method:** Call CTMRWA1.approveFromX(address(this), newTokenId)
- **Result:** New tokenId can be used in future ERC20 operations

### 7. Event Emission
- **Step:** Emit Transfer event
- **Data:** from, to, and value parameters
- **Result:** Standard ERC20 event for external tracking

## Use Cases

### DeFi Integration
- **Scenario:** Providing liquidity to DEXs
- **Process:** Standard ERC20 transfer and approval
- **Benefit:** Seamless integration with existing DeFi protocols

### Wallet Support
- **Scenario:** Using standard ERC20 wallets
- **Process:** Direct balance and transfer operations
- **Benefit:** No special wallet requirements

### Cross-chain Trading
- **Scenario:** Trading RWA tokens across chains
- **Process:** Standard ERC20 operations on each chain
- **Benefit:** Consistent interface across all chains

### Portfolio Management
- **Scenario:** Managing RWA token portfolios
- **Process:** Standard balance and transfer operations
- **Benefit:** Familiar ERC20 interface for portfolio tools

## Best Practices

1. **Gas Optimization:** Monitor gas usage for large transfers
2. **Balance Checking:** Always check balances before transfers
3. **Allowance Management:** Use approve/transferFrom pattern for third-party transfers
4. **Event Monitoring:** Monitor Transfer events for tracking
5. **Integration Testing:** Test with standard ERC20 interfaces

## Limitations

- **Slot Specific:** Each ERC20 represents only one slot
- **Approval Required:** TokenIds must be pre-approved for ERC20 spending
- **Gas Costs:** Large transfers may be expensive due to tokenId iteration
- **Cross-contract Dependency:** Requires CTMRWA1 contract availability
- **Approval Management:** Users must manually approve tokenIds for ERC20 operations

## Future Enhancements

Potential improvements to the ERC20 interface:

1. **Batch Operations:** Implement batch transfer functions
2. **Gas Optimization:** Optimize tokenId iteration algorithms
3. **Event Enhancement:** Add detailed transfer tracking events
4. **Integration APIs:** Add convenience functions for common operations
5. **Metadata Support:** Enhanced metadata and URI support

## CREATE2 Deployment Details

### Deterministic Addresses
- **Method:** Uses CREATE2 with salt for deployment
- **Salt:** Generated from ERC20 parameters
- **Benefit:** Predictable addresses across deployments

### Deployment Process
1. **CTMRWAERC20Deployer** receives deployment request
2. **Salt Generation** from ERC20 parameters
3. **CREATE2 Deployment** with deterministic address
4. **Contract Initialization** with slot and metadata
5. **Address Registration** in CTMRWAMap

## ERC20 Architecture

### Role in CTMRWA System
- **Fungible Layer:** Provides ERC20 interface to semi-fungible tokens
- **Slot Representation:** Each ERC20 represents one CTMRWA1 slot
- **Integration Layer:** Enables DeFi and wallet integration
- **Balance Aggregation:** Aggregates balances across multiple tokenIds

### Integration Flow
1. **CTMRWA1** manages semi-fungible token data
2. **CTMRWAERC20** provides ERC20 interface to specific slot
3. **DeFi Protocols** interact with standard ERC20 interface
4. **Wallets** display and manage ERC20 balances
5. **CTMRWAMap** tracks ERC20 contract addresses

## Gas Optimization

### Transfer Costs
- **Base Transfer:** ~21000 gas for simple transfers
- **TokenId Iteration:** ~5000-50000 gas depending on number of tokenIds
- **Cross-contract Calls:** ~2600 gas per CTMRWA1 call
- **Total Estimate:** ~30000-100000 gas per transfer

### Optimization Strategies
- **MAX_TOKENS Limit:** Prevents excessive gas usage
- **Efficient Iteration:** Optimized tokenId iteration algorithm
- **Batch Operations:** Consider batch transfers for efficiency
- **Gas Estimation:** Always estimate gas before transfers

## Security Considerations

### Transfer Security
- **Reentrancy Protection:** Prevents reentrancy attacks
- **Balance Validation:** Ensures sufficient balance before transfers
- **Allowance Validation:** Validates allowance for transferFrom
- **Zero Address Protection:** Prevents transfers to zero address

### Integration Security
- **Contract Validation:** Validates CTMRWA1 contract existence
- **Slot Validation:** Ensures slot exists in CTMRWA1
- **Address Verification:** Verify deployed addresses on block explorers
- **Cross-contract Safety:** Safe integration with CTMRWA1

### TokenId Management
- **Iteration Safety:** Safe iteration through tokenIds
- **Gas Limit Protection:** MAX_TOKENS prevents gas limit issues
- **Partial Transfer Handling:** Safe handling of partial transfers
- **New TokenId Creation:** Safe creation of new tokenIds

## Slot Management

### Slot Representation
- **One-to-One Mapping:** Each ERC20 represents exactly one slot
- **Slot Prefix:** Name includes slot number for identification
- **Slot Validation:** Validates slot exists in CTMRWA1
- **Slot Metadata:** Retrieves slot name from CTMRWA1

### Slot Operations
- **Balance Aggregation:** Aggregates balances across slot tokenIds
- **Transfer Coordination:** Coordinates transfers within slot
- **Supply Calculation:** Calculates total supply from slot
- **TokenId Management:** Manages tokenIds within slot

## ERC20 Compliance

### Standard Interface
- **ERC20 Functions:** Implements all required ERC20 functions
- **Event Compliance:** Emits standard ERC20 events
- **Return Values:** Returns correct data types and values
- **Error Handling:** Uses standard ERC20 error patterns

### Extended Features
- **Decimals Function:** Additional decimals() function for convenience
- **Slot Integration:** Seamless integration with CTMRWA1 slots
- **Dynamic Supply:** Supply derived from underlying token balances
- **Cross-contract Balance:** Balance calculation from CTMRWA1
