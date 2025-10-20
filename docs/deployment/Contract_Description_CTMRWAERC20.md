# CTMRWAERC20 Contract Documentation

## Overview

**Contract Name:** CTMRWAERC20  
**File:** `src/deployment/CTMRWAERC20.sol`  
**License:** BSL-1.1  
**Author:** @Selqui ContinuumDAO

## Contract Description

This contract is an ERC20. The required interface functions are directly linked to various functions in CTMRWA1. This contract is deployed by deployERC20() in the contract CTMRWAERC20Deployer which uses CREATE2.

### Key Features
- ERC20 compliance with full standard implementation
- Slot-specific representation (one ERC20 per slot)
- Dynamic supply derived from CTMRWA1 slot balances
- Cross-contract integration with CTMRWA1
- Reentrancy protection for transfer security
- Deterministic deployment using CREATE2
- **TokenId Approval System**: Owners must specifically approve tokenIds for ERC20 transfers
- **Revocable Approvals**: TokenId approvals can be easily revoked at any time
- Gas optimization through approved tokenId processing
- Dual balance functions (total and approved)
- Automatic approval management for new tokenIds

## State Variables

- `ID (uint256)`: The ID of the CTMRWA1 that created this ERC20 is stored here
- `RWA_TYPE (uint256, immutable)`: rwaType is the type of RWA token contract, e.g. CTMRWA1 has rwaType == 1
- `VERSION (uint256, immutable)`: version is the version of the rwaType
- `slot (uint256)`: The slot number that this ERC20 relates to. Each ERC20 relates to ONE slot
- `slotName (string)`: The corresponding slot name
- `ctmRwaName (string)`: The name of this ERC20
- `ctmRwaSymbol (string)`: The symbol of this ERC20
- `ctmRwaDecimals (uint8)`: The decimals of this ERC20 are the same as for the CTMRWA1
- `ctmRwaMap (address)`: The address of the CTMRWAMap contract
- `ctmRwaToken (address)`: The address of the CTMRWA1 contract that called this

## Constructor

```solidity
constructor(
    uint256 _ID,
    uint256 _rwaType,
    uint256 _version,
    uint256 _slot,
    string memory _name,
    string memory _symbol,
    address _ctmRwaMap
)
```
- Initializes a new CTMRWAERC20 contract instance
- Sets token identification parameters
- Creates slot-prefixed name (e.g., "slot 1| TokenName")
- Retrieves CTMRWA1 contract address from map
- Validates slot exists in CTMRWA1
- Gets slot name and decimals from CTMRWA1

## ERC20 Interface Functions

### name()
```solidity
function name() public view override(ERC20, ICTMRWAERC20) returns (string memory)
```
The ERC20 name returns the input name, pre-pended with the slot.

**Returns:** The name of the ERC20

### symbol()
```solidity
function symbol() public view override(ERC20, ICTMRWAERC20) returns (string memory)
```
The ERC20 symbol.

**Returns:** The symbol of the ERC20

### decimals()
```solidity
function decimals() public view override(ERC20, ICTMRWAERC20) returns (uint8)
```
The ERC20 decimals. This is not part of the official ERC20 interface, but is added here for convenience.

**Returns:** The decimals of the ERC20

### totalSupply()
```solidity
function totalSupply() public view override(ERC20, IERC20) returns (uint256)
```
The ERC20 totalSupply. This is derived from the CTMRWA1 and is the total fungible balance summed over all tokenIds in the slot of this ERC20.

**Returns:** The total supply of the ERC20

### balanceOf()
```solidity
function balanceOf(address _account) public view override(ERC20, IERC20) returns (uint256)
```
The ERC20 balanceOf. This is derived from the CTMRWA1 and is the sum of the fungible balances of approved tokenIds in this slot for this _account.

**Parameters:**
- `_account`: The wallet address of the balanceOf being sought

**Returns:** The balance of the _account from approved tokenIds only

### balanceOfApproved()
```solidity
function balanceOfApproved(address _account) public view returns (uint256)
```
Returns the balance of approved tokenIds for a specific account.

**Purpose:** This function explicitly shows the balance available for ERC20 transfers, which only includes tokenIds that have been specifically approved by the owner for ERC20 operations.

**Parameters:**
- `_account`: The wallet address of the balanceOf being sought

**Returns:** The balance of the _account from approved tokenIds only

### allowance()
```solidity
function allowance(address _owner, address _spender) public view override(ERC20, IERC20) returns (uint256)
```
Returns the ERC20 allowance of _spender on behalf of _owner.

**Parameters:**
- `_owner`: The owner of the tokenIds who is granting approval to the spender
- `_spender`: The recipient, who is being granted approval to spend on behalf of _owner

**Returns:** The allowance of _spender on behalf of _owner

## Transfer Functions

### approve()
```solidity
function approve(address _spender, uint256 _value) public override(ERC20, IERC20) returns (bool)
```
Grant approval to a spender to spend a fungible value from the slot.

**Parameters:**
- `_spender`: The wallet address being granted approval to spend value
- `_value`: The fungible value being approved to spend by the spender

**Returns:** True if the approval was successful, false otherwise

### transfer()
```solidity
function transfer(address _to, uint256 _value) public override(ERC20, IERC20) nonReentrant returns (bool)
```
Transfer a fungible value to another wallet from the caller's balance.

**Parameters:**
- `_to`: The recipient of the transfer
- `_value`: The fungible amount being transferred

**Note:** The _value is taken from the first tokenId owned by the caller and if this is not sufficient, the balance is taken from the second owned tokenId etc.

**Returns:** True if the transfer was successful, false otherwise

### transferFrom()
```solidity
function transferFrom(address _from, address _to, uint256 _value) public override(ERC20, IERC20) nonReentrant returns (bool)
```
The caller transfers _value from the wallet _from to the wallet _to.

**Parameters:**
- `_from`: The wallet being debited
- `_to`: The wallet being credited
- `_value`: The fungible amount being transfered

**Note:** The caller must have sufficient allowance granted to it by the _from wallet. The _value is taken from the first tokenId owned by the caller and if this is not sufficient, the balance is taken from the second owned tokenId etc.

**Returns:** True if the transfer was successful, false otherwise

## Internal Functions

### _approve()
```solidity
function _approve(address _owner, address _spender, uint256 _value, bool _emitEvent) internal override
```
Low level function to approve spending.

**Parameters:**
- `_owner`: Owner of the tokenIds granting approval
- `_spender`: Recipient being granted approval
- `_value`: Fungible value being approved
- `_emitEvent`: Whether to emit approval event

### _update()
```solidity
function _update(address _from, address _to, uint256 _value) internal override
```
Low level function calling transferFrom in CTMRWA1 to adjust the balances of both the _from tokenIds and creating a new tokenId for the _to wallet.

**Process:**
1. Gets array of approved tokenIds for this owner and slot
2. Validates sufficient approved balance
3. Iterates through approved tokenIds
4. Creates new tokenId for recipient via CTMRWA1XUtils
5. Transfers value from approved tokenIds to new tokenId
6. Handles partial transfers across multiple approved tokenIds
7. Clears approved values from source tokenIds
8. Emits Transfer event

### _spendAllowance()
```solidity
function _spendAllowance(address _owner, address _spender, uint256 _value) internal override
```
Low level function granting approval IF the spender has enough allowance from _owner.

**Process:**
1. Checks current allowance against required value
2. Updates allowance if not unlimited
3. Handles allowance reduction

## Access Control

The contract does not use custom access control modifiers, as it follows standard ERC20 patterns where any address can interact with the token functions.

## Events

The contract inherits standard ERC20 events:
- `Transfer(address indexed from, address indexed to, uint256 value)`: Emitted on token transfers
- `Approval(address indexed owner, address indexed spender, uint256 value)`: Emitted on approval changes

## Security Features

- Reentrancy protection for transfer functions
- Zero address validation for approvals
- Approved balance validation before transfers
- Allowance validation for transferFrom
- **TokenId Approval Control**: Only pre-approved tokenIds can be used for ERC20 transfers
- **Revocable Approvals**: TokenId approvals can be revoked at any time by the owner
- Immutable parameters for critical values
- Cross-contract validation with CTMRWA1
- Automatic approval management for new tokenIds

## Integration Points

- `CTMRWA1`: Core semi-fungible token contract providing balance data
- `CTMRWAMap`: Contract address registry for CTMRWA1 lookup
- `CTMRWA1X`: Cross-chain coordinator for token operations
- `CTMRWA1XUtils`: Utility contract for minting operations
- `CTMRWAERC20Deployer`: Factory contract that creates ERC20 instances
- `DeFi Protocols`: Standard ERC20 integration for liquidity and trading
- `Wallets`: Standard ERC20 wallet support

## Error Handling

The contract uses custom error types for efficient gas usage:

- `CTMRWAERC20_InvalidContract(CTMRWAErrorParam.Token)`: Thrown when CTMRWA1 contract not found
- `CTMRWAERC20_NonExistentSlot(uint256 slot)`: Thrown when slot doesn't exist in CTMRWA1
- `CTMRWAERC20_IsZeroAddress(CTMRWAErrorParam.Spender)`: Thrown when approving zero address

Standard ERC20 errors are also used:
- `ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed)`: Insufficient balance
- `ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed)`: Insufficient allowance

## Transfer Process

### 1. Approved TokenId Retrieval
- Gets array of approved tokenIds for sender and slot
- Calls CTMRWA1.getErc20Approvals(sender, slot)
- **Important**: Only tokenIds that have been specifically approved by the owner for ERC20 transfers are included
- Result: Array of tokenIds approved for ERC20 spending

### 2. Approved Balance Validation
- Checks if sender has sufficient approved balance
- Calls balanceOfApproved(sender) to sum approved tokenId balances
- **Note**: If no tokenIds are approved, balance will be zero and transfer will fail
- Result: Proceed if sufficient, revert if insufficient

### 3. Approved TokenId Iteration
- Iterates through only approved tokenIds
- Processes approved tokenIds array from step 1
- **Security**: Only processes tokenIds that the owner has explicitly approved for ERC20 operations
- Benefit: Gas efficient - only processes relevant tokenIds

### 4. New TokenId Creation
- Creates new tokenId for recipient
- Calls CTMRWA1XUtils.mintFromXForERC20(recipient, slot, slotName)
- Result: New tokenId owned by recipient

### 5. Value Transfer
- Transfers value from approved tokenIds to new tokenId
- Uses CTMRWA1.transferFrom for each approved tokenId
- Logic: Handle partial transfers across multiple approved tokenIds

### 6. Automatic Approval
- Approves new tokenId for ERC20 contract
- Calls CTMRWA1.clearApprovedValuesFromERC20 for source tokenIds
- Result: New tokenId can be used in future ERC20 operations

### 7. Event Emission
- Emits Transfer event
- Data: from, to, and value parameters
- Result: Standard ERC20 event for external tracking

**Key Point**: The entire transfer process depends on the owner having previously approved specific tokenIds for ERC20 operations. Without these approvals, no ERC20 transfers are possible.

## Use Cases

### DeFi Integration
- Providing liquidity to DEXs
- Standard ERC20 transfer and approval
- Seamless integration with existing DeFi protocols

### Wallet Support
- Using standard ERC20 wallets
- Direct balance and transfer operations
- No special wallet requirements

### Cross-chain Trading
- Trading RWA tokens across chains
- Standard ERC20 operations on each chain
- Consistent interface across all chains

### Portfolio Management
- Managing RWA token portfolios
- Standard balance and transfer operations
- Familiar ERC20 interface for portfolio tools

## Best Practices

1. **Gas Optimization**: Monitor gas usage for large transfers
2. **Balance Checking**: Always check balances before transfers
3. **Allowance Management**: Use approve/transferFrom pattern for third-party transfers
4. **TokenId Approval Management**: Explicitly approve tokenIds for ERC20 transfers and revoke approvals when no longer needed
5. **Event Monitoring**: Monitor Transfer events for tracking
6. **Integration Testing**: Test with standard ERC20 interfaces

## Limitations

- Slot Specific: Each ERC20 represents only one slot
- **Approval Required**: TokenIds must be pre-approved for ERC20 spending - owners must explicitly approve each tokenId they want to use for ERC20 transfers
- **Revocable Approvals**: TokenId approvals can be revoked at any time, which may affect ERC20 transfer availability
- Gas Costs: Large transfers may be expensive due to tokenId iteration
- Cross-contract Dependency: Requires CTMRWA1 contract availability
- **Manual Approval Management**: Users must manually approve tokenIds for ERC20 operations and can revoke these approvals at any time

## CREATE2 Deployment Details

### Deterministic Addresses
- Uses CREATE2 with salt for deployment
- Salt generated from ERC20 parameters
- Benefit: Predictable addresses across deployments

### Deployment Process
1. CTMRWAERC20Deployer receives deployment request
2. Salt generation from ERC20 parameters
3. CREATE2 deployment with deterministic address
4. Contract initialization with slot and metadata
5. Address registration in CTMRWAMap

## ERC20 Architecture

### Role in CTMRWA System
- Fungible Layer: Provides ERC20 interface to semi-fungible tokens
- Slot Representation: Each ERC20 represents one CTMRWA1 slot
- Integration Layer: Enables DeFi and wallet integration
- Balance Aggregation: Aggregates balances across multiple tokenIds

### Integration Flow
1. CTMRWA1 manages semi-fungible token data
2. CTMRWAERC20 provides ERC20 interface to specific slot
3. DeFi Protocols interact with standard ERC20 interface
4. Wallets display and manage ERC20 balances
5. CTMRWAMap tracks ERC20 contract addresses

## Gas Optimization

### Transfer Costs
- Base Transfer: ~21000 gas for simple transfers
- TokenId Iteration: ~5000-50000 gas depending on number of tokenIds
- Cross-contract Calls: ~2600 gas per CTMRWA1 call
- Total Estimate: ~30000-100000 gas per transfer

### Optimization Strategies
- Approved TokenId Processing: Only processes pre-approved tokenIds
- Efficient Iteration: Optimized tokenId iteration algorithm
- Batch Operations: Consider batch transfers for efficiency
- Gas Estimation: Always estimate gas before transfers

## Security Considerations

### Transfer Security
- Reentrancy Protection: Prevents reentrancy attacks
- Balance Validation: Ensures sufficient balance before transfers
- Allowance Validation: Validates allowance for transferFrom
- Zero Address Protection: Prevents transfers to zero address

### Integration Security
- Contract Validation: Validates CTMRWA1 contract existence
- Slot Validation: Ensures slot exists in CTMRWA1
- Address Verification: Verify deployed addresses on block explorers
- Cross-contract Safety: Safe integration with CTMRWA1

### TokenId Management
- Iteration Safety: Safe iteration through tokenIds
- Partial Transfer Handling: Safe handling of partial transfers
- New TokenId Creation: Safe creation of new tokenIds
- Approval Management: Secure approval and clearance operations

## Slot Management

### Slot Representation
- One-to-One Mapping: Each ERC20 represents exactly one slot
- Slot Prefix: Name includes slot number for identification
- Slot Validation: Validates slot exists in CTMRWA1
- Slot Metadata: Retrieves slot name from CTMRWA1

### Slot Operations
- Balance Aggregation: Aggregates balances across slot tokenIds
- Transfer Coordination: Coordinates transfers within slot
- Supply Calculation: Calculates total supply from slot
- TokenId Management: Manages tokenIds within slot

## ERC20 Compliance

### Standard Interface
- ERC20 Functions: Implements all required ERC20 functions
- Event Compliance: Emits standard ERC20 events
- Return Values: Returns correct data types and values
- Error Handling: Uses standard ERC20 error patterns

### Extended Features
- Decimals Function: Additional decimals() function for convenience
- Slot Integration: Seamless integration with CTMRWA1 slots
- Dynamic Supply: Supply derived from underlying token balances
- Cross-contract Balance: Balance calculation from CTMRWA1