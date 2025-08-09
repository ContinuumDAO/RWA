# CTMRWADeployInvest Contract Documentation

## Overview

**Contract Name:** CTMRWADeployInvest  
**Author:** @Selqui ContinuumDAO  
**License:** BSL-1.1  
**Solidity Version:** 0.8.27

The CTMRWADeployInvest contract deploys CTMRWA1InvestWithTimeLock contracts. Only one such contract can be deployed for an RWA token per chain, since the salt is tied to the _ID, _rwaType, and _version. The contract address of the CTMRWA1InvestWithTimeLock can be retrieved using CTMRWAMap.

This contract serves as a specialized factory for investment contract deployment, ensuring deterministic addresses and proper fee management for investment platform setup.

## Key Features

- **Investment Contract Deployment:** Deploys CTMRWA1InvestWithTimeLock contracts with deterministic addresses
- **Single Instance Per Chain:** Ensures only one investment contract per RWA per chain
- **CREATE2 Integration:** Uses CREATE2 with salt for predictable contract addresses
- **Fee Management:** Integrated fee system for deployment operations
- **Commission Support:** Configurable commission rates for investment offerings
- **Access Control:** Only authorized deployer can create investment contracts
- **Cross-chain Integration:** Works within the broader CTMRWA deployment architecture

## Public Variables

### Contract Addresses
- **`ctmRwaMap`** (address): Address of the CTMRWAMap contract
- **`ctmRwaDeployer`** (address): Address of the CTMRWADeployer contract
- **`feeManager`** (address): Address of the FeeManager contract

### Configuration
- **`commissionRate`** (uint256): The commission rate payable to FeeManager (0-10000, 0.01% increments)
- **`cIdStr`** (string): String representation of the local chainID

## Core Functions

### Constructor

#### `constructor(address _ctmRwaMap, address _deployer, uint256 _commissionRate, address _feeManager)`
- **Purpose:** Initializes the CTMRWADeployInvest contract instance
- **Parameters:**
  - `_ctmRwaMap`: Address of the CTMRWAMap contract
  - `_deployer`: Address of the CTMRWADeployer contract
  - `_commissionRate`: Commission rate payable to FeeManager (0-10000)
  - `_feeManager`: Address of the FeeManager contract
- **Initialization:**
  - Sets all contract addresses and configuration
  - Sets chain ID string representation
  - Establishes integration with the CTMRWA ecosystem

### Configuration Functions

#### `setDeployerMapFee(address _deployer, address _ctmRwaMap, address _feeManager)`
- **Access:** Only callable by CTMRWADeployer
- **Purpose:** Updates deployer, map, and fee manager addresses
- **Parameters:**
  - `_deployer`: New address of the deployer
  - `_ctmRwaMap`: New address of the CTMRWAMap contract
  - `_feeManager`: New address of the FeeManager contract
- **Use Case:** Allows CTMRWADeployer to update integration addresses

#### `setCommissionRate(uint256 _commissionRate)`
- **Access:** Only callable by CTMRWADeployer
- **Purpose:** Sets the commission rate for investment offerings
- **Parameters:**
  - `_commissionRate`: New commission rate (0-10000, 0.01% increments)
- **Use Case:** Allows governance to adjust commission rates for investment platforms

### Deployment Functions

#### `deployInvest(uint256 _ID, uint256 _rwaType, uint256 _version, address _feeToken)`
- **Access:** Only callable by CTMRWADeployer
- **Purpose:** Deploys a new CTMRWA1InvestWithTimeLock contract
- **Parameters:**
  - `_ID`: ID of the RWA token
  - `_rwaType`: Type of RWA token (1 for CTMRWA1)
  - `_version`: Version of the RWA token (1 for current)
  - `_feeToken`: Address of the fee token
- **Logic:**
  - Pays deployment fee using FeeManager
  - Generates salt from ID, RWA type, and version
  - Deploys CTMRWA1InvestWithTimeLock using CREATE2 with salt
  - Returns the deployed contract address
- **Returns:** Address of the deployed CTMRWA1InvestWithTimeLock contract
- **Security:** Uses CREATE2 to ensure deterministic addresses
- **Uniqueness:** Salt ensures only one investment contract per RWA per chain

## Internal Functions

### Fee Management
- **`_payFee(FeeType _feeType, address _feeToken)`**: Pays fees for deployment operations
  - Calculates fee amount using FeeManager
  - Transfers fee tokens from deployer
  - Approves and pays fee to FeeManager
  - Returns true if fee payment successful

## Access Control Modifiers

- **`onlyDeployer`**: Restricts access to only the CTMRWADeployer contract
  - Ensures that only the authorized deployment coordinator can create investment contracts
  - Prevents unauthorized investment contract creation
  - Maintains deployment security and control

## Events

The contract does not emit custom events, as it focuses solely on deployment operations. Deployment events are handled by the calling CTMRWADeployer contract.

## Security Features

1. **Access Control:** Only authorized deployer can create investment contracts
2. **Deterministic Addresses:** CREATE2 ensures predictable contract addresses
3. **Salt-based Deployment:** Uses RWA ID, type, and version as salt for uniqueness
4. **Fee Integration:** Integrated fee system for deployment operations
5. **Single Instance:** Ensures only one investment contract per RWA per chain
6. **Integration Safety:** Works within established deployment architecture

## Integration Points

- **CTMRWADeployer**: Main deployment coordinator that calls this contract
- **CTMRWAMap**: Provides contract address mapping for new deployments
- **CTMRWA1InvestWithTimeLock**: Target contract type being deployed
- **FeeManager**: Fee calculation and payment management
- **C3Caller**: Cross-chain communication system

## Error Handling

The contract uses custom error types for efficient gas usage and clear error messages:

- **`CTMRWADeployInvest_OnlyAuthorized(CTMRWAErrorParam.Sender, CTMRWAErrorParam.Deployer)`**: Thrown when unauthorized address tries to deploy investment contracts

## Deployment Process

### 1. Deployment Request
- **Step:** CTMRWADeployer calls deployInvest function with RWA parameters
- **Requirements:** Valid RWA ID, type, version, and fee token
- **Result:** Deployment process initiated

### 2. Fee Payment
- **Step:** Pays deployment fee using FeeManager
- **Requirements:** Sufficient fee token balance and approval
- **Result:** Fee paid and deployment proceeds

### 3. Salt Generation
- **Step:** Generates salt from RWA ID, type, and version
- **Requirements:** Valid RWA parameters
- **Result:** Unique salt for CREATE2 deployment

### 4. Contract Creation
- **Step:** CREATE2 instruction creates new CTMRWA1InvestWithTimeLock contract
- **Requirements:** Valid constructor parameters and unique salt
- **Result:** Investment contract deployed with deterministic address

### 5. Address Return
- **Step:** Deployed contract address returned
- **Requirements:** Successful deployment
- **Result:** Address available for registration in CTMRWAMap

## Use Cases

### Investment Platform Setup
- **Scenario:** Setting up investment capabilities for an RWA
- **Process:** Deploy investment contract with specific parameters
- **Benefit:** Enables structured capital raising for RWA projects

### Cross-chain Investment
- **Scenario:** Deploying investment contracts across multiple chains
- **Process:** Deploy investment contract on each chain with same parameters
- **Benefit:** Consistent investment platform across all chains

### Commission Management
- **Scenario:** Managing commission rates for investment offerings
- **Process:** Update commission rate through governance
- **Benefit:** Flexible fee structure for investment platforms

### Deterministic Deployment
- **Scenario:** Ensuring consistent investment contract addresses
- **Process:** CREATE2 with salt ensures unique, predictable addresses
- **Benefit:** Enables address-based lookups and cross-chain coordination

## Best Practices

1. **Commission Planning:** Set appropriate commission rates for investment offerings
2. **Fee Management:** Ensure sufficient fee token balance for deployments
3. **Address Tracking:** Track deployed investment contract addresses
4. **Cross-chain Coordination:** Coordinate deployments across all chains
5. **Governance Control:** Use governance processes for configuration updates

## Limitations

- **Single Instance:** Only one investment contract per RWA per chain
- **Deployer Dependency:** Requires CTMRWADeployer to trigger deployments
- **Fee Requirement:** All deployments require fee payment
- **Chain Specific:** Each deployer operates on a single chain

## Future Enhancements

Potential improvements to the investment deployment system:

1. **Multi-contract Support:** Extend to deploy other investment contract types
2. **Batch Deployment:** Implement batch deployment capabilities
3. **Deployment Templates:** Add support for deployment templates
4. **Enhanced Fee Models:** Implement more sophisticated fee structures
5. **Deployment Analytics:** Add deployment tracking and analytics

## CREATE2 Deployment Details

### Salt Generation
- **Method:** Uses keccak256 hash of (ID, rwaType, version) as salt
- **Purpose:** Ensures unique contract addresses per RWA per chain
- **Benefit:** Enables deterministic address prediction

### Address Calculation
- **Formula:** `address = keccak256(0xff ++ factoryAddress ++ salt ++ keccak256(contractBytecode ++ constructorArgs))`
- **Components:**
  - `factoryAddress`: Address of this deployer contract
  - `salt`: Hash of (ID, rwaType, version)
  - `contractBytecode`: CTMRWA1InvestWithTimeLock contract bytecode
  - `constructorArgs`: Encoded constructor arguments

### Deterministic Benefits
- **Cross-chain Consistency:** Same RWA parameters produce same address across chains
- **Address Prediction:** Addresses can be calculated before deployment
- **Lookup Efficiency:** Enables efficient address-based lookups
- **Coordination:** Simplifies cross-chain coordination

## Investment Architecture

### Role in CTMRWA System
- **Investment Layer:** Handles investment contract deployment
- **Deployer Layer:** Coordinates with main deployment system
- **Map Layer:** Tracks deployed investment contract addresses
- **Fee Layer:** Manages deployment fees and commissions

### Integration Flow
1. **CTMRWADeployer** receives investment deployment request
2. **CTMRWADeployInvest** creates new investment contract
3. **CTMRWAMap** registers new investment contract address
4. **CTMRWA1InvestWithTimeLock** manages investment operations
5. **FeeManager** handles fee collection and commission distribution

## Gas Optimization

### Deployment Costs
- **CREATE2 Operation:** ~32000 gas base cost
- **Contract Creation:** ~300000-400000 gas for CTMRWA1InvestWithTimeLock
- **Fee Payment:** Variable based on fee amount
- **Total Estimate:** ~350000-450000 gas per deployment

### Optimization Strategies
- **Minimal Deployer Logic:** Keeps deployer simple and gas-efficient
- **Fee Optimization:** Optimize fee payment mechanisms
- **Gas Estimation:** Always estimate gas before deployment
- **Network Selection:** Choose appropriate networks for deployment

## Security Considerations

### Access Control
- **Deployer Authorization:** Only CTMRWADeployer can create investment contracts
- **Deployer Security:** Deployer contract should be secure and audited
- **Configuration Validation:** Validate all configuration parameters

### Address Collision Prevention
- **Unique Salts:** RWA parameters ensure unique addresses
- **Salt Validation:** Validate salt uniqueness before deployment
- **Address Verification:** Verify deployed address matches expected

### Integration Security
- **Contract Verification:** Verify deployed contracts on block explorers
- **Address Registration:** Ensure proper registration in CTMRWAMap
- **Cross-chain Coordination:** Coordinate deployments across chains properly

## Commission Management

### Commission Structure
- **Rate Range:** 0-10000 (0.01% increments)
- **Calculation:** `commission = investment * commissionRate / 10000`
- **Distribution:** Commission paid to FeeManager contract
- **Flexibility:** Rate can be updated by governance

### Use Cases
- **Platform Fees:** Cover platform operational costs
- **Revenue Generation:** Generate revenue for ecosystem maintenance
- **Incentive Alignment:** Align incentives between stakeholders
- **Sustainability:** Ensure long-term platform sustainability
