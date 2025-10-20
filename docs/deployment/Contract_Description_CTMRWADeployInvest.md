# CTMRWADeployInvest Contract Documentation

## Overview

**Contract Name:** CTMRWADeployInvest  
**File:** `src/deployment/CTMRWADeployInvest.sol`  
**License:** BSL-1.1  
**Author:** @Selqui ContinuumDAO

## Contract Description

This contract deploys an CTMRWA1InvestWithTimeLock contract. Only one such contract can be deployed for an RWA token per chain, since the salt is tied to the _ID, _rwaType, _version. The contract address of the CTMRWA1InvestWithTimeLock can be got using CTMRWAMap.

### Key Features
- Investment contract deployment with deterministic addresses
- Single instance per RWA per chain enforcement
- CREATE2 integration with salt-based deployment
- Fee management and payment integration
- Commission rate configuration
- Access control via onlyDeployer modifier
- Cross-chain integration within CTMRWA ecosystem

## State Variables

- `ctmRwaMap (address)`: Address of the CTMRWAMap contract
- `ctmRwaDeployer (address)`: Address of the CTMRWADeployer contract
- `commissionRate (uint256)`: The commission rate payable to FeeManager is a number from 0 to 10000 (%0.01)
- `feeManager (address)`: Address of the FeeManager contract
- `cIdStr (string)`: String representation of the local chainID

## Constructor

```solidity
constructor(address _ctmRwaMap, address _deployer, uint256 _commissionRate, address _feeManager)
```
- Initializes the CTMRWADeployInvest contract instance
- Sets all contract addresses and configuration
- Sets chain ID string representation
- Establishes integration with the CTMRWA ecosystem

## Access Control

- `onlyDeployer`: Restricts access to only the CTMRWADeployer contract

## Configuration Functions

### setDeployerMapFee()
```solidity
function setDeployerMapFee(address _deployer, address _ctmRwaMap, address _feeManager) external onlyDeployer
```
This allows the deployer, map and fee manager to be set.

### setCommissionRate()
```solidity
function setCommissionRate(uint256 _commissionRate) external onlyDeployer
```
This allows a commission to be charged on the offering, payable to the FeeManager contract.

**Commission Rate Conditions:**
- Rate must be between 0 and 10000 (0.01% increments)
- Rate can only be increased by 100 or more (1%) at a time
- Rate can only be increased every 30 days
- Rate can be decreased at any time
- Rate increases are subject to time restrictions to prevent rapid changes

## Deployment Functions

### deployInvest()
```solidity
function deployInvest(uint256 _ID, uint256 _rwaType, uint256 _version, address _feeToken, address _originalCaller) external onlyDeployer returns (address)
```
This deploys a new CTMRWA1Invest contract.

**Parameters:**
- `_ID`: The ID of the RWA token
- `_rwaType`: The type of RWA token
- `_version`: The version of the RWA token
- `_feeToken`: The address of the fee token
- `_originalCaller`: The address of the original caller who should pay the fee

**Process:**
1. Pays deployment fee using FeeManager
2. Generates salt from keccak256 hash of (ID, rwaType, version)
3. Deploys CTMRWA1InvestWithTimeLock using CREATE2 with salt
4. Validates RWA type and version compatibility
5. Returns the deployed contract address

**Returns:** The address of the deployed CTMRWA1Invest contract

## Internal Functions

### _payFee()
```solidity
function _payFee(FeeType _feeType, address _feeToken, address _originalCaller) internal returns (bool)
```
Pay the fee for deploying the Invest contract.

**Process:**
1. Calculates fee amount using FeeManager with fee reduction
2. Transfers fee tokens from original caller to this contract
3. Approves and pays fee to FeeManager
4. Validates balance changes for security

**Returns:** True if fee payment successful

## Events

The contract does not emit custom events, as it focuses solely on deployment operations.

## Security Features

- Access control via onlyDeployer modifier
- CREATE2 deterministic address generation
- Salt-based deployment for uniqueness
- Fee payment validation with balance checks
- RWA type and version validation
- Single instance enforcement per RWA per chain
- Integration safety within deployment architecture

## Integration Points

- `CTMRWADeployer`: Main deployment coordinator that calls this contract
- `CTMRWAMap`: Provides contract address mapping for new deployments
- `CTMRWA1InvestWithTimeLock`: Target contract type being deployed
- `FeeManager`: Fee calculation and payment management
- `C3Caller`: Cross-chain communication system

## Error Handling

The contract uses custom error types for efficient gas usage:

- `CTMRWADeployInvest_OnlyAuthorized(CTMRWAErrorParam.Sender, CTMRWAErrorParam.Deployer)`: Thrown when unauthorized address tries to deploy investment contracts
- `CTMRWADeployInvest_IsZeroAddress(CTMRWAErrorParam.Deployer/Map/FeeManager)`: Thrown when zero address is provided
- `CTMRWADeployInvest_InvalidVersion(uint256 _version)`: Thrown when version is invalid
- `CTMRWADeployInvest_InvalidRWAType(uint256 _rwaType)`: Thrown when RWA type is invalid
- `CTMRWADeployInvest_FailedTransfer()`: Thrown when fee transfer fails

## Deployment Process

### 1. Fee Payment
- Calculates deployment fee using FeeManager
- Applies fee reduction for original caller
- Transfers fee tokens from caller to contract
- Approves and pays fee to FeeManager

### 2. Salt Generation
- Generates salt from keccak256 hash of (ID, rwaType, version)
- Ensures unique contract addresses per RWA per chain
- Enables deterministic address prediction

### 3. Contract Creation
- CREATE2 instruction creates new CTMRWA1InvestWithTimeLock contract
- Uses generated salt for deterministic addressing
- Validates RWA type and version compatibility

### 4. Address Return
- Returns deployed contract address
- Address available for registration in CTMRWAMap

## Use Cases

### Investment Platform Setup
- Setting up investment capabilities for an RWA
- Deploy investment contract with specific parameters
- Enables structured capital raising for RWA projects

### Cross-chain Investment
- Deploying investment contracts across multiple chains
- Deploy investment contract on each chain with same parameters
- Consistent investment platform across all chains

### Commission Management
- Managing commission rates for investment offerings
- Update commission rate through governance
- Flexible fee structure for investment platforms

### Deterministic Deployment
- Ensuring consistent investment contract addresses
- CREATE2 with salt ensures unique, predictable addresses
- Enables address-based lookups and cross-chain coordination

## Best Practices

1. **Commission Planning**: Set appropriate commission rates for investment offerings
2. **Fee Management**: Ensure sufficient fee token balance for deployments
3. **Address Tracking**: Track deployed investment contract addresses
4. **Cross-chain Coordination**: Coordinate deployments across all chains
5. **Governance Control**: Use governance processes for configuration updates

## Limitations

- Single Instance: Only one investment contract per RWA per chain
- Deployer Dependency: Requires CTMRWADeployer to trigger deployments
- Fee Requirement: All deployments require fee payment
- Chain Specific: Each deployer operates on a single chain

## CREATE2 Deployment Details

### Salt Generation
- Uses keccak256 hash of (ID, rwaType, version) as salt
- Ensures unique contract addresses per RWA per chain
- Enables deterministic address prediction

### Address Calculation
- Formula: `address = keccak256(0xff ++ factoryAddress ++ salt ++ keccak256(contractBytecode ++ constructorArgs))`
- Components:
  - `factoryAddress`: Address of this deployer contract
  - `salt`: Hash of (ID, rwaType, version)
  - `contractBytecode`: CTMRWA1InvestWithTimeLock contract bytecode
  - `constructorArgs`: Encoded constructor arguments

### Deterministic Benefits
- Cross-chain Consistency: Same RWA parameters produce same address across chains
- Address Prediction: Addresses can be calculated before deployment
- Lookup Efficiency: Enables efficient address-based lookups
- Coordination: Simplifies cross-chain coordination

## Investment Architecture

### Role in CTMRWA System
- Investment Layer: Handles investment contract deployment
- Deployer Layer: Coordinates with main deployment system
- Map Layer: Tracks deployed investment contract addresses
- Fee Layer: Manages deployment fees and commissions

### Integration Flow
1. CTMRWADeployer receives investment deployment request
2. CTMRWADeployInvest creates new investment contract
3. CTMRWAMap registers new investment contract address
4. CTMRWA1InvestWithTimeLock manages investment operations
5. FeeManager handles fee collection and commission distribution

## Gas Optimization

### Deployment Costs
- CREATE2 Operation: ~32000 gas base cost
- Contract Creation: ~300000-400000 gas for CTMRWA1InvestWithTimeLock
- Fee Payment: Variable based on fee amount
- Total Estimate: ~350000-450000 gas per deployment

### Optimization Strategies
- Minimal Deployer Logic: Keeps deployer simple and gas-efficient
- Fee Optimization: Optimize fee payment mechanisms
- Gas Estimation: Always estimate gas before deployment
- Network Selection: Choose appropriate networks for deployment

## Security Considerations

### Access Control
- Deployer Authorization: Only CTMRWADeployer can create investment contracts
- Deployer Security: Deployer contract should be secure and audited
- Configuration Validation: Validate all configuration parameters

### Address Collision Prevention
- Unique Salts: RWA parameters ensure unique addresses
- Salt Validation: Validate salt uniqueness before deployment
- Address Verification: Verify deployed address matches expected

### Integration Security
- Contract Verification: Verify deployed contracts on block explorers
- Address Registration: Ensure proper registration in CTMRWAMap
- Cross-chain Coordination: Coordinate deployments across chains properly

## Commission Management

### Commission Structure
- Rate Range: 0-10000 (0.01% increments)
- Calculation: `commission = investment * commissionRate / 10000`
- Distribution: Commission paid to FeeManager contract
- Flexibility: Rate can be updated by governance

### Use Cases
- Platform Fees: Cover platform operational costs
- Revenue Generation: Generate revenue for ecosystem maintenance
- Incentive Alignment: Align incentives between stakeholders
- Sustainability: Ensure long-term platform sustainability