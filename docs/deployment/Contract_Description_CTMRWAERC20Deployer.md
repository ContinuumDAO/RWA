# CTMRWAERC20Deployer Contract Documentation

## Overview

**Contract Name:** CTMRWAERC20Deployer  
**File:** `src/deployment/CTMRWAERC20Deployer.sol`  
**License:** BSL-1.1  
**Author:** @Selqui ContinuumDAO

## Contract Description

This contract manages the deployment of an ERC20 token from CTMRWADeployer that is an interface to the underlying CTMRWA1 token. It allows the tokenAdmin of the CTMRWA contract to deploy a unique ERC20 representing a single Asset Class (slot).

This contract is only deployed ONCE on each chain and manages all CTMRWAERC20 contract deployments.

### Key Features
- ERC20 factory for slot-specific token deployment
- Single instance per chain for all ERC20 deployments
- CREATE2 integration with deterministic addresses
- Fee management and payment integration
- Access control via onlyDeployer modifier
- Slot-specific deployment (one ERC20 per slot)
- Cross-contract validation and integration
- Reentrancy protection for fee operations
- Original caller tracking for fee payment

## State Variables

- `ctmRwaMap (address)`: The address of the CTMRWAMap contract
- `deployer (address)`: The address of the deployer contract
- `feeManager (address)`: The address of the FeeManager contract
- `cIdStr (string)`: String representation of the local chainID

## Constructor

```solidity
constructor(address _ctmRwaMap, address _deployer, address _feeManager)
```
- Initializes the CTMRWAERC20Deployer contract instance
- Sets contract addresses for integration
- Sets chain ID string representation
- Establishes integration with the CTMRWA ecosystem

## Access Control

- `onlyDeployer`: Restricts access to only the deployer contract

## Deployment Functions

### deployERC20()
```solidity
function deployERC20(
    uint256 _ID,
    uint256 _rwaType,
    uint256 _version,
    uint256 _slot,
    string memory _name,
    address _feeToken,
    address _originalCaller
) external onlyDeployer returns (address)
```
Deploy a new ERC20 contract linked to a CTMRWA1 with ID, for ONE slot.

**Parameters:**
- `_ID`: The unique ID number for the CTMRWA1
- `_rwaType`: The type of RWA token
- `_version`: The version of the RWA token
- `_slot`: The slot number selected for this ERC20
- `_name`: The name for the ERC20. This will be pre-pended with "slot X | ", where X is the slot number
- `_feeToken`: The fee token address to pay. The contract address must be in the return from feeTokenList() in FeeManager
- `_originalCaller`: The address of the original caller who should pay the fee

**Process:**
1. Validates CTMRWA1 contract exists in CTMRWAMap
2. Validates name length (max 128 characters)
3. Pays deployment fee using FeeManager
4. Generates salt from keccak256 hash of (ID, rwaType, version, slot)
5. Deploys CTMRWAERC20 using CREATE2 with salt
6. Validates deployed contract parameters
7. Registers ERC20 address in CTMRWA1 using setErc20
8. Returns the deployed contract address

**Returns:** The address of the deployed ERC20 contract

**Note:** The public function to deploy the ERC20 is deployERC20 in CTMRWADeployer.

## Internal Functions

### _payFee()
```solidity
function _payFee(FeeType _feeType, address _feeToken, address _originalCaller) internal nonReentrant returns (bool)
```
Pay the fee for deploying the ERC20.

**Process:**
1. Calculates cross-chain fee amount using FeeManager
2. Applies fee reduction for original caller
3. Transfers fee tokens from original caller to this contract
4. Approves and pays fee to FeeManager
5. Validates balance changes for security

**Returns:** True if the fee was paid, false otherwise

## Events

The contract does not emit custom events, as it focuses solely on deployment operations.

## Security Features

- Access control via onlyDeployer modifier
- CREATE2 deterministic address generation
- Salt-based deployment for uniqueness
- Fee payment validation with balance checks
- Contract parameter validation
- Reentrancy protection for fee operations
- Original caller tracking for fee payment
- Name length validation (max 128 characters)
- Cross-contract validation and integration

## Integration Points

- `CTMRWADeployer`: Main deployment coordinator that calls this contract
- `CTMRWAMap`: Contract address registry for CTMRWA1 validation
- `CTMRWAERC20`: Target contract type being deployed
- `CTMRWA1`: Semi-fungible token contract for ERC20 registration
- `FeeManager`: Fee calculation and payment management
- `C3Caller`: Cross-chain communication system

## Error Handling

The contract uses custom error types for efficient gas usage:

- `CTMRWAERC20Deployer_OnlyAuthorized(CTMRWAErrorParam.Sender, CTMRWAErrorParam.Deployer)`: Thrown when unauthorized address tries to deploy ERC20
- `CTMRWAERC20Deployer_InvalidContract(CTMRWAErrorParam.Token)`: Thrown when CTMRWA1 contract not found
- `CTMRWAERC20Deployer_NameTooLong()`: Thrown when ERC20 name exceeds 128 characters
- `CTMRWAERC20Deployer_InvalidVersion(uint256 _version)`: Thrown when version is invalid
- `CTMRWAERC20Deployer_InvalidRWAType(uint256 _rwaType)`: Thrown when RWA type is invalid
- `CTMRWAERC20Deployer_InvalidSlot(uint256 _slot)`: Thrown when slot is invalid
- `CTMRWAERC20Deployer_FailedTransfer()`: Thrown when fee transfer fails

## Deployment Process

### 1. Contract Validation
- Validates CTMRWA1 contract exists in CTMRWAMap
- Ensures contract address is valid and accessible

### 2. Parameter Validation
- Validates name length (max 128 characters)
- Ensures all parameters are within valid ranges

### 3. Fee Payment
- Calculates deployment fee using FeeManager
- Applies fee reduction for original caller
- Transfers fee tokens from original caller
- Validates balance changes for security

### 4. Salt Generation
- Generates salt from keccak256 hash of (ID, rwaType, version, slot)
- Ensures unique contract addresses per slot per RWA per chain

### 5. Contract Creation
- CREATE2 instruction creates new CTMRWAERC20 contract
- Uses generated salt for deterministic addressing
- Validates deployed contract parameters

### 6. ERC20 Registration
- Registers ERC20 address in CTMRWA1 using setErc20
- Links ERC20 contract to specific slot

### 7. Address Return
- Returns deployed contract address
- Address available for use in ERC20 operations

## Use Cases

### Asset Class Representation
- Creating ERC20 tokens for specific asset classes
- Deploy ERC20 for each slot in CTMRWA1
- Standard ERC20 interface for each asset class

### DeFi Integration
- Enabling DeFi protocol integration
- Deploy ERC20 tokens for trading and liquidity
- Seamless integration with existing DeFi ecosystem

### Wallet Support
- Supporting standard ERC20 wallets
- Deploy ERC20 tokens for wallet compatibility
- No special wallet requirements for RWA tokens

### Portfolio Management
- Managing RWA token portfolios
- Deploy ERC20 tokens for portfolio tools
- Familiar ERC20 interface for portfolio management

### Cross-chain Operations
- Supporting cross-chain RWA operations
- Deploy ERC20 tokens with cross-chain fee support
- Consistent fee structure across chains

## Best Practices

1. **Slot Planning**: Plan slot structure before ERC20 deployment
2. **Fee Management**: Ensure sufficient fee token balance for deployments
3. **Address Tracking**: Track deployed ERC20 contract addresses
4. **Cross-chain Coordination**: Coordinate deployments across all chains
5. **Validation Testing**: Test contract validation before deployment
6. **Original Caller Management**: Properly track fee payers
7. **Fee Token Selection**: Choose appropriate fee tokens for each chain

## Limitations

- Single Instance: Only one ERC20 per slot per RWA per chain
- Deployer Dependency: Requires CTMRWADeployer to trigger deployments
- Fee Requirement: All deployments require fee payment
- Chain Specific: Each deployer operates on a single chain
- Slot Specific: Each ERC20 represents only one slot
- Original Caller Required: Must provide original caller for fee payment

## CREATE2 Deployment Details

### Salt Generation
- Uses keccak256 hash of (ID, rwaType, version, slot) as salt
- Ensures unique contract addresses per slot per RWA per chain
- Enables deterministic address prediction

### Address Calculation
- Formula: `address = keccak256(0xff ++ factoryAddress ++ salt ++ keccak256(contractBytecode ++ constructorArgs))`
- Components:
  - `factoryAddress`: Address of this deployer contract
  - `salt`: Hash of (ID, rwaType, version, slot)
  - `contractBytecode`: CTMRWAERC20 contract bytecode
  - `constructorArgs`: Encoded constructor arguments

### Deterministic Benefits
- Cross-chain Consistency: Same parameters produce same address across chains
- Address Prediction: Addresses can be calculated before deployment
- Lookup Efficiency: Enables efficient address-based lookups
- Coordination: Simplifies cross-chain coordination

## ERC20 Deployment Architecture

### Role in CTMRWA System
- ERC20 Factory Layer: Handles ERC20 contract deployment
- Slot Interface Layer: Provides ERC20 interface to CTMRWA1 slots
- DeFi Integration Layer: Enables DeFi protocol integration
- Map Layer: Tracks deployed ERC20 contract addresses
- Fee Management Layer: Handles cross-chain fee payments

### Integration Flow
1. CTMRWADeployer receives ERC20 deployment request
2. CTMRWAERC20Deployer creates new ERC20 contract
3. CTMRWA1 registers new ERC20 contract address
4. CTMRWAERC20 provides ERC20 interface to slot
5. DeFi Protocols interact with standard ERC20 interface
6. FeeManager handles fee collection from original caller

## Gas Optimization

### Deployment Costs
- CREATE2 Operation: ~32000 gas base cost
- Contract Creation: ~200000-300000 gas for CTMRWAERC20
- Fee Payment: Variable based on fee amount
- Total Estimate: ~250000-350000 gas per deployment

### Optimization Strategies
- Minimal Deployer Logic: Keeps deployer simple and gas-efficient
- Fee Optimization: Optimize fee payment mechanisms
- Gas Estimation: Always estimate gas before deployment
- Network Selection: Choose appropriate networks for deployment
- Efficient Fee Transfer: Optimize fee transfer operations

## Security Considerations

### Access Control
- Deployer Authorization: Only CTMRWADeployer can create ERC20 contracts
- Deployer Security: Deployer contract should be secure and audited
- Contract Validation: Validate all contract addresses
- Parameter Validation: Validate all deployment parameters

### Address Collision Prevention
- Unique Salts: RWA and slot parameters ensure unique addresses
- Salt Validation: Validate salt uniqueness before deployment
- Address Verification: Verify deployed address matches expected

### Integration Security
- Contract Verification: Verify deployed contracts on block explorers
- Address Registration: Ensure proper registration in CTMRWA1
- Cross-chain Coordination: Coordinate deployments across chains properly
- Fee Security: Secure fee payment and validation

### Fee Security
- Original Caller Validation: Ensure original caller is legitimate
- Fee Token Security: Validate fee token addresses
- Cross-chain Fee Security: Secure cross-chain fee operations
- Reentrancy Protection: Prevent fee payment reentrancy attacks

## Slot Management

### Slot Representation
- One-to-One Mapping: Each ERC20 represents exactly one slot
- Slot Validation: Validates slot exists in CTMRWA1
- Slot Metadata: Retrieves slot information for ERC20 creation
- Slot Coordination: Coordinates ERC20 deployment with slot structure

### Slot Operations
- ERC20 Creation: Creates ERC20 interface for specific slot
- Address Management: Manages ERC20 addresses per slot
- Cross-chain Consistency: Ensures consistent slot representation
- DeFi Integration: Enables DeFi integration for specific slots

## Fee Management

### Fee Structure
- Fee Type: ERC20 deployment fee
- Fee Calculation: Based on chain and fee token (cross-chain support)
- Fee Payment: Required before deployment
- Fee Distribution: Paid to FeeManager contract

### Cross-chain Fee Support
- Chain-specific Fees: Different fees for different chains
- Fee Token Flexibility: Support for various fee tokens
- Original Caller Tracking: Separate fee payer from contract caller
- Zero Fee Handling: Graceful handling of zero fee scenarios

### Use Cases
- Platform Fees: Cover platform operational costs
- Revenue Generation: Generate revenue for ecosystem maintenance
- Incentive Alignment: Align incentives between stakeholders
- Sustainability: Ensure long-term platform sustainability
- Cross-chain Operations: Support fees across different chains