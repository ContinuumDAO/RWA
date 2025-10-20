# CTMRWA1TokenFactory Contract Documentation

## Overview

**Contract Name:** CTMRWA1TokenFactory  
**File:** `src/deployment/CTMRWA1TokenFactory.sol`  
**License:** BSL-1.1  
**Author:** @Selqui ContinuumDAO

## Contract Description

This contract has one task, which is to deploy a new CTMRWA1 contract on one chain. The deploy function is called by CTMRWADeployer. It uses the CREATE2 instruction to deploy the contract, returning its address.

This contract is only deployed ONCE on each chain and manages all CTMRWA1 contract deployments.

### Key Features
- Single-purpose contract deployment factory
- CREATE2 instruction for deterministic addresses
- Access control via onlyDeployer modifier
- Automatic slot data initialization
- RWA type and version validation
- Integration with CTMRWAMap and CTMRWADeployer

## State Variables

- `RWA_TYPE (uint256, immutable = 1)`: RWA type constant for CTMRWA1
- `VERSION (uint256, immutable = 1)`: Version constant for current implementation
- `ctmRwaMap (address)`: Address of the CTMRWAMap contract
- `ctmRwaDeployer (address)`: Address of the CTMRWADeployer contract

## Constructor

```solidity
constructor(address _ctmRwaMap, address _ctmRwaDeployer)
```
- Initializes the CTMRWA1TokenFactory contract instance
- Sets the CTMRWAMap address for contract coordination
- Sets the CTMRWADeployer address for access control

## Access Control

- `onlyDeployer`: Restricts access to only the CTMRWADeployer contract

## Deployment Functions

### deploy()
```solidity
function deploy(uint256 _rwaType, uint256 _version, bytes memory _deployData) external onlyDeployer returns (address)
```
Deploy a new CTMRWA1 using 'salt' ID to ensure a unique contract address.

**Parameters:**
- `_rwaType`: RWA type (must be 1 for CTMRWA1)
- `_version`: RWA version (must be 1 for current)
- `_deployData`: ABI encoded deployment data containing:
  - `ID (uint256)`: Unique RWA ID
  - `admin (address)`: Token admin address
  - `tokenName (string)`: Token name
  - `symbol (string)`: Token symbol
  - `decimals (uint8)`: Token decimals
  - `baseURI (string)`: Base URI for metadata
  - `slotNumbers (uint256[])`: Array of slot numbers
  - `slotNames (string[])`: Array of slot names
  - `ctmRwa1X (address)`: CTMRWA1X contract address

**Process:**
1. Decodes deployment data from ABI encoding
2. Deploys CTMRWA1 contract using CREATE2 with ID as salt
3. Validates RWA type and version compatibility
4. Initializes slot data if provided
5. Returns the deployed contract address

**Returns:** Address of the deployed CTMRWA1 contract

## Events

The contract does not emit custom events, as it focuses solely on deployment operations.

## Security Features

- Access control via onlyDeployer modifier
- RWA type and version validation
- CREATE2 deterministic address generation
- Input validation through ABI decoding
- Integration safety within deployment architecture

## Integration Points

- `CTMRWADeployer`: Main deployment coordinator that calls this factory
- `CTMRWAMap`: Provides contract address mapping for new deployments
- `CTMRWA1`: Target contract type being deployed
- `CTMRWA1X`: Cross-chain coordinator referenced in deployments

## Error Handling

The contract uses custom error types for efficient gas usage:

- `CTMRWA1TokenFactory_OnlyAuthorized(CTMRWAErrorParam.Sender, CTMRWAErrorParam.Deployer)`: Thrown when unauthorized address tries to deploy contracts
- `CTMRWA1TokenFactory_InvalidRWAType(uint256 _rwaType)`: Thrown when RWA type is invalid
- `CTMRWA1TokenFactory_InvalidVersion(uint256 _version)`: Thrown when version is invalid

## Deployment Process

### 1. Deployment Request
- CTMRWADeployer calls deploy function with encoded data
- Validates authorization via onlyDeployer modifier
- Decodes deployment parameters from ABI encoding

### 2. Contract Creation
- CREATE2 instruction creates new CTMRWA1 contract with ID as salt
- Ensures deterministic and unique contract addresses
- Validates RWA type and version compatibility

### 3. Slot Initialization
- If slot data is provided, initializes slot information
- Calls initializeSlotData on the deployed contract
- Prepares contract for immediate use

### 4. Address Return
- Returns deployed contract address
- Address available for registration in CTMRWAMap

## Use Cases

### New RWA Deployment
- Deploying a new RWA token on a chain
- Factory creates CTMRWA1 contract with specific parameters
- Standardized deployment process with predictable addresses

### Cross-chain Coordination
- Coordinating deployments across multiple chains
- Factory ensures consistent contract addresses across chains
- Enables cross-chain RWA operations

### Slot Management
- Creating RWA tokens with predefined slots
- Factory initializes slot data during deployment
- Ready-to-use tokens with configured asset classes

### Deterministic Addresses
- Ensuring consistent contract addresses
- CREATE2 with salt ensures unique, predictable addresses
- Enables address-based lookups and cross-chain coordination

## Best Practices

1. **Authorization Management**: Ensure only authorized deployers can call factory
2. **Data Validation**: Validate deployment data before processing
3. **Gas Optimization**: Monitor gas costs for deployment operations
4. **Address Tracking**: Track deployed contract addresses for registration
5. **Error Handling**: Implement proper error handling for deployment failures

## Limitations

- Single Purpose: Only deploys CTMRWA1 contracts
- Access Restriction: Limited to authorized deployer only
- No Upgradeability: Deployed contracts are not upgradeable through factory
- Chain Specific: Each factory operates on a single chain

## CREATE2 Deployment Details

### Salt Generation
- Uses RWA ID as salt for CREATE2
- Ensures unique contract addresses
- Enables deterministic address prediction

### Address Calculation
- Formula: `address = keccak256(0xff ++ factoryAddress ++ salt ++ keccak256(contractBytecode ++ constructorArgs))`
- Components:
  - `factoryAddress`: Address of this factory contract
  - `salt`: RWA ID converted to bytes32
  - `contractBytecode`: CTMRWA1 contract bytecode
  - `constructorArgs`: Encoded constructor arguments

### Deterministic Benefits
- Cross-chain Consistency: Same RWA ID produces same address across chains
- Address Prediction: Addresses can be calculated before deployment
- Lookup Efficiency: Enables efficient address-based lookups
- Coordination: Simplifies cross-chain coordination

## Deployment Architecture

### Role in CTMRWA System
- Factory Layer: Handles contract creation
- Deployer Layer: Coordinates deployment across components
- Map Layer: Tracks deployed contract addresses
- Token Layer: Manages RWA token operations

### Integration Flow
1. CTMRWADeployer receives deployment request
2. CTMRWA1TokenFactory creates new CTMRWA1 contract
3. CTMRWAMap registers new contract address
4. CTMRWA1X coordinates cross-chain operations
5. CTMRWA1 manages token operations

## Gas Optimization

### Deployment Costs
- CREATE2 Operation: ~32000 gas base cost
- Contract Creation: ~200000 gas for CTMRWA1
- Slot Initialization: Variable based on slot count
- Total Estimate: ~250000-300000 gas per deployment

### Optimization Strategies
- Minimal Factory Logic: Keeps factory simple and gas-efficient
- Batch Operations: Consider batch deployments for multiple contracts
- Gas Estimation: Always estimate gas before deployment
- Network Selection: Choose appropriate networks for deployment

## Security Considerations

### Access Control
- Deployer Authorization: Only authorized deployer can create contracts
- Factory Security: Factory contract should be secure and audited
- Deployment Validation: Validate all deployment parameters

### Address Collision Prevention
- Unique Salts: RWA ID ensures unique addresses
- Salt Validation: Validate salt uniqueness before deployment
- Address Verification: Verify deployed address matches expected

### Integration Security
- Contract Verification: Verify deployed contracts on block explorers
- Address Registration: Ensure proper registration in CTMRWAMap
- Cross-chain Coordination: Coordinate deployments across chains properly