# CTMRWA1TokenFactory Contract Documentation

## Overview

**Contract Name:** CTMRWA1TokenFactory  
**Author:** @Selqui ContinuumDAO  
**License:** BSL-1.1  
**Solidity Version:** 0.8.27

The CTMRWA1TokenFactory contract has one primary task: to deploy new CTMRWA1 contracts on a single chain. The deploy function is called by CTMRWADeployer and uses the CREATE2 instruction to deploy contracts, returning their addresses.

This contract is only deployed ONCE on each chain and manages all CTMRWA1 contract deployments. It serves as the factory for creating new RWA token contracts with deterministic addresses.

## Key Features

- **Deterministic Deployment:** Uses CREATE2 with salt to ensure unique contract addresses
- **Single Purpose:** Focused solely on CTMRWA1 contract deployment
- **Access Control:** Only callable by authorized deployer
- **Slot Initialization:** Automatically initializes slot data for new contracts
- **Cross-chain Integration:** Works within the broader CTMRWA deployment architecture
- **Gas Efficiency:** Optimized for contract deployment operations

## Public Variables

### Contract Addresses
- **`ctmRwaMap`** (address): Address of the CTMRWAMap contract
- **`ctmRwaDeployer`** (address): Address of the CTMRWADeployer contract

## Core Functions

### Constructor

#### `constructor(address _ctmRwaMap, address _ctmRwaDeployer)`
- **Purpose:** Initializes the CTMRWA1TokenFactory contract instance
- **Parameters:**
  - `_ctmRwaMap`: Address of the CTMRWAMap contract
  - `_ctmRwaDeployer`: Address of the CTMRWADeployer contract
- **Initialization:**
  - Sets the CTMRWAMap address for contract coordination
  - Sets the CTMRWADeployer address for access control

### Deployment Functions

#### `deploy(bytes memory _deployData)`
- **Access:** Only callable by CTMRWADeployer
- **Purpose:** Deploys a new CTMRWA1 contract using CREATE2 with salt
- **Parameters:**
  - `_deployData`: ABI encoded data containing deployment parameters
- **Deployment Data Structure:**
  ```solidity
  (
      uint256 ID,                    // Unique RWA ID
      address admin,                 // Token admin address
      string memory tokenName,       // Token name
      string memory symbol,          // Token symbol
      uint8 decimals,                // Token decimals
      string memory baseURI,         // Base URI for metadata
      uint256[] memory slotNumbers,  // Array of slot numbers
      string[] memory slotNames,     // Array of slot names
      address ctmRwa1X               // CTMRWA1X contract address
  )
  ```
- **Logic:**
  - Decodes deployment data
  - Deploys CTMRWA1 contract using CREATE2 with ID as salt
  - Initializes slot data if provided
  - Returns the deployed contract address
- **Returns:** Address of the deployed CTMRWA1 contract
- **Security:** Uses CREATE2 to ensure deterministic addresses
- **Integration:** Automatically initializes slot data for new contracts

## Internal Functions

The contract is designed to be simple and focused, with minimal internal functions beyond the core deployment logic.

## Access Control Modifiers

- **`onlyDeployer`**: Restricts access to only the CTMRWADeployer contract
  - Ensures that only the authorized deployment coordinator can create new contracts
  - Prevents unauthorized contract creation

## Events

The contract does not emit custom events, as it focuses solely on deployment operations. Deployment events are handled by the calling CTMRWADeployer contract.

## Security Features

1. **Access Control:** Only authorized deployer can create contracts
2. **Deterministic Addresses:** CREATE2 ensures predictable contract addresses
3. **Salt-based Deployment:** Uses RWA ID as salt for unique addresses
4. **Input Validation:** Validates deployment data through ABI decoding
5. **Integration Safety:** Works within established deployment architecture

## Integration Points

- **CTMRWADeployer**: Main deployment coordinator that calls this factory
- **CTMRWAMap**: Provides contract address mapping for new deployments
- **CTMRWA1**: Target contract type being deployed
- **CTMRWA1X**: Cross-chain coordinator referenced in deployments

## Error Handling

The contract uses custom error types for efficient gas usage and clear error messages:

- **`CTMRWA1TokenFactory_OnlyAuthorized(CTMRWAErrorParam.Sender, CTMRWAErrorParam.Deployer)`**: Thrown when unauthorized address tries to deploy contracts

## Deployment Process

### 1. Deployment Request
- **Step:** CTMRWADeployer calls deploy function with encoded data
- **Requirements:** Valid deployment data and authorization
- **Result:** Deployment process initiated

### 2. Contract Creation
- **Step:** CREATE2 instruction creates new CTMRWA1 contract
- **Requirements:** Valid constructor parameters
- **Result:** New contract deployed with deterministic address

### 3. Slot Initialization
- **Step:** Slot data initialized if provided
- **Requirements:** Valid slot arrays
- **Result:** Contract ready for use with configured slots

### 4. Address Return
- **Step:** Deployed contract address returned
- **Requirements:** Successful deployment
- **Result:** Address available for registration in CTMRWAMap

## Use Cases

### New RWA Deployment
- **Scenario:** Deploying a new RWA token on a chain
- **Process:** Factory creates CTMRWA1 contract with specific parameters
- **Benefit:** Standardized deployment process with predictable addresses

### Cross-chain Coordination
- **Scenario:** Coordinating deployments across multiple chains
- **Process:** Factory ensures consistent contract addresses across chains
- **Benefit:** Enables cross-chain RWA operations

### Slot Management
- **Scenario:** Creating RWA tokens with predefined slots
- **Process:** Factory initializes slot data during deployment
- **Benefit:** Ready-to-use tokens with configured asset classes

### Deterministic Addresses
- **Scenario:** Ensuring consistent contract addresses
- **Process:** CREATE2 with salt ensures unique, predictable addresses
- **Benefit:** Enables address-based lookups and cross-chain coordination

## Best Practices

1. **Authorization Management:** Ensure only authorized deployers can call factory
2. **Data Validation:** Validate deployment data before processing
3. **Gas Optimization:** Monitor gas costs for deployment operations
4. **Address Tracking:** Track deployed contract addresses for registration
5. **Error Handling:** Implement proper error handling for deployment failures

## Limitations

- **Single Purpose:** Only deploys CTMRWA1 contracts
- **Access Restriction:** Limited to authorized deployer only
- **No Upgradeability:** Deployed contracts are not upgradeable through factory
- **Chain Specific:** Each factory operates on a single chain

## Future Enhancements

Potential improvements to the factory system:

1. **Multi-contract Support:** Extend to deploy other RWA contract types
2. **Deployment Templates:** Add support for deployment templates
3. **Batch Deployment:** Implement batch deployment capabilities
4. **Deployment Verification:** Add post-deployment verification mechanisms
5. **Deployment Analytics:** Add deployment tracking and analytics

## CREATE2 Deployment Details

### Salt Generation
- **Method:** Uses RWA ID as salt for CREATE2
- **Purpose:** Ensures unique contract addresses
- **Benefit:** Enables deterministic address prediction

### Address Calculation
- **Formula:** `address = keccak256(0xff ++ factoryAddress ++ salt ++ keccak256(contractBytecode ++ constructorArgs))`
- **Components:**
  - `factoryAddress`: Address of this factory contract
  - `salt`: RWA ID converted to bytes32
  - `contractBytecode`: CTMRWA1 contract bytecode
  - `constructorArgs`: Encoded constructor arguments

### Deterministic Benefits
- **Cross-chain Consistency:** Same RWA ID produces same address across chains
- **Address Prediction:** Addresses can be calculated before deployment
- **Lookup Efficiency:** Enables efficient address-based lookups
- **Coordination:** Simplifies cross-chain coordination

## Deployment Architecture

### Role in CTMRWA System
- **Factory Layer:** Handles contract creation
- **Deployer Layer:** Coordinates deployment across components
- **Map Layer:** Tracks deployed contract addresses
- **Token Layer:** Manages RWA token operations

### Integration Flow
1. **CTMRWADeployer** receives deployment request
2. **CTMRWA1TokenFactory** creates new CTMRWA1 contract
3. **CTMRWAMap** registers new contract address
4. **CTMRWA1X** coordinates cross-chain operations
5. **CTMRWA1** manages token operations

## Gas Optimization

### Deployment Costs
- **CREATE2 Operation:** ~32000 gas base cost
- **Contract Creation:** ~200000 gas for CTMRWA1
- **Slot Initialization:** Variable based on slot count
- **Total Estimate:** ~250000-300000 gas per deployment

### Optimization Strategies
- **Minimal Factory Logic:** Keeps factory simple and gas-efficient
- **Batch Operations:** Consider batch deployments for multiple contracts
- **Gas Estimation:** Always estimate gas before deployment
- **Network Selection:** Choose appropriate networks for deployment

## Security Considerations

### Access Control
- **Deployer Authorization:** Only authorized deployer can create contracts
- **Factory Security:** Factory contract should be secure and audited
- **Deployment Validation:** Validate all deployment parameters

### Address Collision Prevention
- **Unique Salts:** RWA ID ensures unique addresses
- **Salt Validation:** Validate salt uniqueness before deployment
- **Address Verification:** Verify deployed address matches expected

### Integration Security
- **Contract Verification:** Verify deployed contracts on block explorers
- **Address Registration:** Ensure proper registration in CTMRWAMap
- **Cross-chain Coordination:** Coordinate deployments across chains properly
