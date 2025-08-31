# CTMRWA1DividendFactory Contract Documentation

## Overview

**Contract Name:** CTMRWA1DividendFactory  
**Author:** @Selqui ContinuumDAO  
**License:** BSL-1.1  
**Solidity Version:** 0.8.27

The CTMRWA1DividendFactory contract has a single purpose: to deploy new CTMRWA1Dividend contracts on one chain. The deploy function is called by CTMRWADeployer and uses the CREATE2 instruction to deploy contracts with deterministic addresses.

This contract is deployed only once on each chain and manages all CTMRWA1Dividend contract deployments, ensuring consistent and predictable contract addresses across the ecosystem.

## Key Features

- **Dividend Contract Factory:** Deploys CTMRWA1Dividend contracts with deterministic addresses
- **Single Instance:** Only one factory per chain for all dividend contract deployments
- **CREATE2 Integration:** Uses CREATE2 with salt for predictable contract addresses
- **Access Control:** Only authorized deployer can create dividend contracts
- **Deterministic Deployment:** Ensures consistent addresses across deployments
- **Simple Architecture:** Focused solely on dividend contract deployment
- **Cross-chain Coordination:** Works within the broader deployment architecture

## Public Variables

### Contract Addresses
- **`deployer`** (address): Address of the authorized deployer contract (CTMRWADeployer)

## Core Functions

### Constructor

#### `constructor(address _deployer)`
- **Purpose:** Initializes the CTMRWA1DividendFactory contract instance
- **Parameters:**
  - `_deployer`: Address of the authorized deployer contract
- **Initialization:**
  - Sets the deployer address
  - Establishes access control for deployment operations
- **Use Case:** Called during factory deployment to set up authorization

### Deployment Functions

#### `deployDividend(uint256 _ID, address _tokenAddr, uint256 _rwaType, uint256 _version, address _map)`
- **Access:** Only callable by authorized deployer
- **Purpose:** Deploy a new CTMRWA1Dividend contract using CREATE2
- **Parameters:**
  - `_ID`: Unique ID for the dividend contract (same as CTMRWA1)
  - `_tokenAddr`: Address of the CTMRWA1 contract
  - `_rwaType`: Type of RWA token (1 for CTMRWA1)
  - `_version`: Version of the RWA token
  - `_map`: Address of the CTMRWAMap contract
- **Logic:**
  - Uses CREATE2 with salt derived from _ID
  - Deploys new CTMRWA1Dividend contract
  - Passes all parameters to constructor
- **Returns:** Address of the deployed CTMRWA1Dividend contract
- **Security:** Uses CREATE2 to ensure deterministic addresses
- **Uniqueness:** Salt ensures only one dividend contract per RWA per chain

## Internal Functions

The contract does not contain any internal functions, as it focuses solely on deployment operations.

## Access Control Modifiers

- **`onlyDeployer`**: Restricts access to only the authorized deployer contract
  - Ensures that only the authorized deployment coordinator can create dividend contracts
  - Prevents unauthorized dividend contract creation
  - Maintains deployment security and control
  - Validates caller against stored deployer address

## Events

The contract does not emit custom events, as it focuses solely on deployment operations. Deployment events are handled by the calling CTMRWADeployer contract.

## Security Features

1. **Access Control:** Only authorized deployer can create dividend contracts
2. **Deterministic Addresses:** CREATE2 ensures predictable contract addresses
3. **Salt-based Deployment:** Uses RWA ID as salt for uniqueness
4. **Single Instance:** Ensures only one dividend contract per RWA per chain
5. **Integration Safety:** Works within established deployment architecture
6. **Simple Design:** Minimal attack surface with focused functionality

## Integration Points

- **CTMRWADeployer**: Main deployment coordinator that calls this factory
- **CTMRWA1Dividend**: Target contract type being deployed
- **CTMRWAMap**: Contract address registry for dividend contract lookup
- **CTMRWA1**: Semi-fungible token contracts that dividend contracts serve
- **C3Caller**: Cross-chain communication system

## Error Handling

The contract uses custom error types for efficient gas usage and clear error messages:

- **`CTMRWA1DividendFactory_OnlyAuthorized(CTMRWAErrorParam.Sender, CTMRWAErrorParam.Deployer)`**: Thrown when unauthorized address tries to deploy dividend contracts

## Deployment Process

### 1. Deployment Request
- **Step:** CTMRWADeployer calls deployDividend function with RWA parameters
- **Requirements:** Valid RWA ID, token address, type, version, and map address
- **Result:** Deployment process initiated

### 2. Access Validation
- **Step:** Validates caller is authorized deployer
- **Requirements:** Caller matches stored deployer address
- **Result:** Proceed if authorized, revert if unauthorized

### 3. Salt Generation
- **Step:** Uses RWA ID as salt for CREATE2
- **Requirements:** Valid RWA ID parameter
- **Result:** Unique salt for CREATE2 deployment

### 4. Contract Creation
- **Step:** CREATE2 instruction creates new CTMRWA1Dividend contract
- **Requirements:** Valid constructor parameters and unique salt
- **Result:** Dividend contract deployed with deterministic address

### 5. Address Return
- **Step:** Deployed contract address returned
- **Requirements:** Successful deployment
- **Result:** Address available for registration in CTMRWAMap

## Use Cases

### Dividend System Setup
- **Scenario:** Setting up dividend capabilities for an RWA
- **Process:** Deploy dividend contract with specific parameters
- **Benefit:** Enables dividend distribution for RWA token holders

### Cross-chain Dividend Deployment
- **Scenario:** Deploying dividend contracts across multiple chains
- **Process:** Deploy dividend contract on each chain with same parameters
- **Benefit:** Consistent dividend system across all chains

### Deterministic Deployment
- **Scenario:** Ensuring consistent dividend contract addresses
- **Process:** CREATE2 with salt ensures unique, predictable addresses
- **Benefit:** Enables address-based lookups and cross-chain coordination

### RWA Ecosystem Integration
- **Scenario:** Integrating dividend contracts into RWA ecosystem
- **Process:** Deploy dividend contract as part of complete RWA suite
- **Benefit:** Complete RWA functionality including dividend distribution

## Best Practices

1. **Deployer Security:** Ensure deployer contract is secure and audited
2. **Address Tracking:** Track deployed dividend contract addresses
3. **Cross-chain Coordination:** Coordinate deployments across all chains
4. **Parameter Validation:** Validate all deployment parameters
5. **Integration Testing:** Test dividend contract integration

## Limitations

- **Single Instance:** Only one dividend contract per RWA per chain
- **Deployer Dependency:** Requires CTMRWADeployer to trigger deployments
- **Chain Specific:** Each factory operates on a single chain
- **Simple Functionality:** Focused solely on deployment, no additional features

## Future Enhancements

Potential improvements to the dividend factory system:

1. **Batch Deployment:** Implement batch deployment capabilities
2. **Deployment Templates:** Add support for deployment templates
3. **Deployment Analytics:** Add deployment tracking and analytics
4. **Enhanced Validation:** Add more comprehensive parameter validation
5. **Multi-contract Support:** Extend to deploy other dividend contract types

## CREATE2 Deployment Details

### Salt Generation
- **Method:** Uses RWA ID directly as salt for CREATE2
- **Purpose:** Ensures unique contract addresses per RWA per chain
- **Benefit:** Enables deterministic address prediction

### Address Calculation
- **Formula:** `address = keccak256(0xff ++ factoryAddress ++ salt ++ keccak256(contractBytecode ++ constructorArgs))`
- **Components:**
  - `factoryAddress`: Address of this factory contract
  - `salt`: RWA ID (uint256 converted to bytes32)
  - `contractBytecode`: CTMRWA1Dividend contract bytecode
  - `constructorArgs`: Encoded constructor arguments

### Deterministic Benefits
- **Cross-chain Consistency:** Same RWA ID produces same address across chains
- **Address Prediction:** Addresses can be calculated before deployment
- **Lookup Efficiency:** Enables efficient address-based lookups
- **Coordination:** Simplifies cross-chain coordination

## Dividend Factory Architecture

### Role in CTMRWA System
- **Dividend Factory Layer:** Handles dividend contract deployment
- **Deployer Layer:** Coordinates with main deployment system
- **Map Layer:** Tracks deployed dividend contract addresses
- **Integration Layer:** Enables dividend functionality in RWA ecosystem

### Integration Flow
1. **CTMRWADeployer** receives dividend deployment request
2. **CTMRWA1DividendFactory** creates new dividend contract
3. **CTMRWAMap** registers new dividend contract address
4. **CTMRWA1Dividend** manages dividend distribution
5. **CTMRWA1** provides token data for dividend calculations

## Gas Optimization

### Deployment Costs
- **CREATE2 Operation:** ~32000 gas base cost
- **Contract Creation:** ~150000-250000 gas for CTMRWA1Dividend
- **Total Estimate:** ~200000-300000 gas per deployment

### Optimization Strategies
- **Minimal Factory Logic:** Keeps factory simple and gas-efficient
- **Efficient Salt Usage:** Direct use of RWA ID as salt
- **Gas Estimation:** Always estimate gas before deployment
- **Network Selection:** Choose appropriate networks for deployment

## Security Considerations

### Access Control
- **Deployer Authorization:** Only authorized deployer can create dividend contracts
- **Deployer Security:** Deployer contract should be secure and audited
- **Parameter Validation:** Validate all deployment parameters

### Address Collision Prevention
- **Unique Salts:** RWA ID ensures unique addresses
- **Salt Validation:** Validate salt uniqueness before deployment
- **Address Verification:** Verify deployed address matches expected

### Integration Security
- **Contract Verification:** Verify deployed contracts on block explorers
- **Address Registration:** Ensure proper registration in CTMRWAMap
- **Cross-chain Coordination:** Coordinate deployments across chains properly

## Dividend Contract Lifecycle

### Deployment Phase
- **Factory Creation:** Deploy factory contract on each chain
- **Parameter Setup:** Configure deployment parameters
- **Contract Creation:** Deploy dividend contracts using factory
- **Address Registration:** Register addresses in CTMRWAMap

### Operational Phase
- **Dividend Management:** Manage dividend rates and funding
- **Holder Claims:** Process dividend claims from token holders
- **Balance Tracking:** Track dividend balances and distributions
- **Event Monitoring:** Monitor dividend events and operations

### Maintenance Phase
- **Contract Updates:** Update dividend contracts if needed
- **Rate Adjustments:** Adjust dividend rates based on performance
- **Token Changes:** Change dividend tokens if required
- **Emergency Controls:** Use pause/unpause for emergency situations

## Factory Management

### Single Instance Design
- **One Factory Per Chain:** Only one factory deployed per chain
- **Centralized Control:** Centralized deployment control
- **Consistent Addresses:** Ensures consistent address generation
- **Simplified Management:** Reduces complexity in deployment management

### Deployment Coordination
- **CTMRWADeployer Integration:** Works with main deployment coordinator
- **Parameter Validation:** Validates deployment parameters
- **Address Generation:** Generates deterministic addresses
- **Integration Support:** Supports broader RWA ecosystem integration

## Cross-chain Considerations

### Deterministic Addresses
- **Same Parameters:** Same RWA parameters produce same addresses
- **Cross-chain Consistency:** Consistent addresses across all chains
- **Lookup Efficiency:** Efficient address-based lookups
- **Coordination Benefits:** Simplifies cross-chain coordination

### Deployment Coordination
- **Synchronized Deployment:** Coordinate deployments across chains
- **Parameter Consistency:** Ensure consistent parameters across chains
- **Address Tracking:** Track addresses across all chains
- **Integration Testing:** Test integration across all chains
