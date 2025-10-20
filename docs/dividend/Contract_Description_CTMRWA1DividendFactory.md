# CTMRWA1DividendFactory Contract Documentation

## Overview

**Contract Name:** CTMRWA1DividendFactory  
**File:** `src/dividend/CTMRWA1DividendFactory.sol`  
**License:** BSL-1.1  
**Author:** @Selqui ContinuumDAO

## Contract Description

This contract has one task, which is to deploy a new CTMRWA1Dividend contract on one chain. The deploy function is called by CTMRWADeployer. It uses the CREATE2 instruction to deploy the contract, returning its address.

This contract is only deployed ONCE on each chain and manages all CTMRWA1Dividend contract deployments.

### Key Features
- Single-purpose dividend contract deployment
- CREATE2 integration with deterministic addresses
- Access control via onlyDeployer modifier
- Simple and focused architecture
- Cross-chain deployment coordination
- Salt-based deployment for uniqueness
- Integration with CTMRWADeployer system

## State Variables

- `deployer (address)`: Address of the authorized deployer contract

## Constructor

```solidity
constructor(address _deployer)
```
- Initializes the CTMRWA1DividendFactory contract instance
- Sets the deployer address for access control
- Establishes authorization for deployment operations

## Access Control

- `onlyDeployer`: Restricts access to only the authorized deployer contract

## Deployment Functions

### deployDividend()
```solidity
function deployDividend(uint256 _ID, address _tokenAddr, uint256 _rwaType, uint256 _version, address _map) external onlyDeployer returns (address)
```
Deploy a new CTMRWA1Dividend using 'salt' ID to ensure a unique contract address.

**Parameters:**
- `_ID`: Unique ID for the dividend contract (same as CTMRWA1)
- `_tokenAddr`: Address of the CTMRWA1 contract
- `_rwaType`: Type of RWA token (1 for CTMRWA1)
- `_version`: Version of the RWA token
- `_map`: Address of the CTMRWAMap contract

**Process:**
1. Uses CREATE2 with salt derived from _ID
2. Deploys new CTMRWA1Dividend contract
3. Passes all parameters to constructor
4. Returns the deployed contract address

**Returns:** The address of the deployed CTMRWA1Dividend contract

## Internal Functions

The contract does not contain any internal functions, as it focuses solely on deployment operations.

## Events

The contract does not emit custom events, as it focuses solely on deployment operations.

## Security Features

- Access control via onlyDeployer modifier
- CREATE2 deterministic address generation
- Salt-based deployment for uniqueness
- Single instance per chain design
- Integration safety with established deployment architecture
- Simple design with minimal attack surface

## Integration Points

- `CTMRWADeployer`: Main deployment coordinator that calls this factory
- `CTMRWA1Dividend`: Target contract type being deployed
- `CTMRWAMap`: Contract address registry for dividend contract lookup
- `CTMRWA1`: Semi-fungible token contracts that dividend contracts serve
- `C3Caller`: Cross-chain communication system

## Error Handling

The contract uses custom error types for efficient gas usage:

- `CTMRWA1DividendFactory_OnlyAuthorized(CTMRWAErrorParam.Sender, CTMRWAErrorParam.Deployer)`: Thrown when unauthorized address tries to deploy dividend contracts

## Deployment Process

### 1. Deployment Request
- CTMRWADeployer calls deployDividend function with RWA parameters
- Valid RWA ID, token address, type, version, and map address required
- Deployment process initiated

### 2. Access Validation
- Validates caller is authorized deployer
- Caller must match stored deployer address
- Proceed if authorized, revert if unauthorized

### 3. Salt Generation
- Uses RWA ID as salt for CREATE2
- Valid RWA ID parameter required
- Unique salt for CREATE2 deployment

### 4. Contract Creation
- CREATE2 instruction creates new CTMRWA1Dividend contract
- Valid constructor parameters and unique salt required
- Dividend contract deployed with deterministic address

### 5. Address Return
- Deployed contract address returned
- Successful deployment required
- Address available for registration in CTMRWAMap

## Use Cases

### Dividend System Setup
- Setting up dividend capabilities for an RWA
- Deploy dividend contract with specific parameters
- Enables dividend distribution for RWA token holders

### Cross-chain Dividend Deployment
- Deploying dividend contracts across multiple chains
- Deploy dividend contract on each chain with same parameters
- Consistent dividend system across all chains

### Deterministic Deployment
- Ensuring consistent dividend contract addresses
- CREATE2 with salt ensures unique, predictable addresses
- Enables address-based lookups and cross-chain coordination

### RWA Ecosystem Integration
- Integrating dividend contracts into RWA ecosystem
- Deploy dividend contract as part of complete RWA suite
- Complete RWA functionality including dividend distribution

## Best Practices

1. **Deployer Security**: Ensure deployer contract is secure and audited
2. **Address Tracking**: Track deployed dividend contract addresses
3. **Cross-chain Coordination**: Coordinate deployments across all chains
4. **Parameter Validation**: Validate all deployment parameters
5. **Integration Testing**: Test dividend contract integration

## Limitations

- Single Instance: Only one dividend contract per RWA per chain
- Deployer Dependency: Requires CTMRWADeployer to trigger deployments
- Chain Specific: Each factory operates on a single chain
- Simple Functionality: Focused solely on deployment, no additional features

## CREATE2 Deployment Details

### Salt Generation
- Uses RWA ID directly as salt for CREATE2
- Ensures unique contract addresses per RWA per chain
- Enables deterministic address prediction

### Address Calculation
- Formula: `address = keccak256(0xff ++ factoryAddress ++ salt ++ keccak256(contractBytecode ++ constructorArgs))`
- Components:
  - `factoryAddress`: Address of this factory contract
  - `salt`: RWA ID (uint256 converted to bytes32)
  - `contractBytecode`: CTMRWA1Dividend contract bytecode
  - `constructorArgs`: Encoded constructor arguments

### Deterministic Benefits
- Cross-chain Consistency: Same RWA ID produces same address across chains
- Address Prediction: Addresses can be calculated before deployment
- Lookup Efficiency: Enables efficient address-based lookups
- Coordination: Simplifies cross-chain coordination

## Dividend Factory Architecture

### Role in CTMRWA System
- Dividend Factory Layer: Handles dividend contract deployment
- Deployer Layer: Coordinates with main deployment system
- Map Layer: Tracks deployed dividend contract addresses
- Integration Layer: Enables dividend functionality in RWA ecosystem

### Integration Flow
1. CTMRWADeployer receives dividend deployment request
2. CTMRWA1DividendFactory creates new dividend contract
3. CTMRWAMap registers new dividend contract address
4. CTMRWA1Dividend manages dividend distribution
5. CTMRWA1 provides token data for dividend calculations

## Gas Optimization

### Deployment Costs
- CREATE2 Operation: ~32000 gas base cost
- Contract Creation: ~150000-250000 gas for CTMRWA1Dividend
- Total Estimate: ~200000-300000 gas per deployment

### Optimization Strategies
- Minimal Factory Logic: Keeps factory simple and gas-efficient
- Efficient Salt Usage: Direct use of RWA ID as salt
- Gas Estimation: Always estimate gas before deployment
- Network Selection: Choose appropriate networks for deployment

## Security Considerations

### Access Control
- Deployer Authorization: Only authorized deployer can create dividend contracts
- Deployer Security: Deployer contract should be secure and audited
- Parameter Validation: Validate all deployment parameters

### Address Collision Prevention
- Unique Salts: RWA ID ensures unique addresses
- Salt Validation: Validate salt uniqueness before deployment
- Address Verification: Verify deployed address matches expected

### Integration Security
- Contract Verification: Verify deployed contracts on block explorers
- Address Registration: Ensure proper registration in CTMRWAMap
- Cross-chain Coordination: Coordinate deployments across chains properly

## Dividend Contract Lifecycle

### Deployment Phase
- Factory Creation: Deploy factory contract on each chain
- Parameter Setup: Configure deployment parameters
- Contract Creation: Deploy dividend contracts using factory
- Address Registration: Register addresses in CTMRWAMap

### Operational Phase
- Dividend Management: Manage dividend rates and funding
- Holder Claims: Process dividend claims from token holders
- Balance Tracking: Track dividend balances and distributions
- Event Monitoring: Monitor dividend events and operations

### Maintenance Phase
- Contract Updates: Update dividend contracts if needed
- Rate Adjustments: Adjust dividend rates based on performance
- Token Changes: Change dividend tokens if required
- Emergency Controls: Use pause/unpause for emergency situations

## Factory Management

### Single Instance Design
- One Factory Per Chain: Only one factory deployed per chain
- Centralized Control: Centralized deployment control
- Consistent Addresses: Ensures consistent address generation
- Simplified Management: Reduces complexity in deployment management

### Deployment Coordination
- CTMRWADeployer Integration: Works with main deployment coordinator
- Parameter Validation: Validates deployment parameters
- Address Generation: Generates deterministic addresses
- Integration Support: Supports broader RWA ecosystem integration

## Cross-chain Considerations

### Deterministic Addresses
- Same Parameters: Same RWA parameters produce same addresses
- Cross-chain Consistency: Consistent addresses across all chains
- Lookup Efficiency: Efficient address-based lookups
- Coordination Benefits: Simplifies cross-chain coordination

### Deployment Coordination
- Synchronized Deployment: Coordinate deployments across chains
- Parameter Consistency: Ensure consistent parameters across chains
- Address Tracking: Track addresses across all chains
- Integration Testing: Test integration across all chains