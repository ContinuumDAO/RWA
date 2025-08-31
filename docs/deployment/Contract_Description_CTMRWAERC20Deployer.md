# CTMRWAERC20Deployer Contract Documentation

## Overview

**Contract Name:** CTMRWAERC20Deployer  
**Author:** @Selqui ContinuumDAO  
**License:** BSL-1.1  
**Solidity Version:** 0.8.27

The CTMRWAERC20Deployer contract manages the deployment of ERC20 tokens that provide interfaces to underlying CTMRWA1 tokens. It allows the tokenAdmin (Issuer) to deploy unique ERC20 tokens representing individual Asset Classes (slots) within CTMRWA1 contracts.

This contract is deployed only once on each chain and manages all CTMRWAERC20 contract deployments. While anyone could theoretically call `deployERC20()`, it must be called by a CTMRWA1 contract to be valid and properly linked to the underlying semi-fungible token contract.

## Key Features

- **ERC20 Factory:** Deploys ERC20 tokens representing CTMRWA1 slots
- **Single Instance:** Only one deployer per chain for all ERC20 deployments
- **CREATE2 Integration:** Uses CREATE2 with salt for deterministic addresses
- **Fee Management:** Integrated fee system for deployment operations
- **Access Control:** Only CTMRWA1 contracts can deploy valid ERC20 tokens
- **Slot-specific Deployment:** Each ERC20 represents exactly one slot
- **Cross-contract Validation:** Validates CTMRWA1 contract existence
- **Reentrancy Protection:** Uses ReentrancyGuard for fee payment security

## Public Variables

### Contract Addresses
- **`ctmRwaMap`** (address): Address of the CTMRWAMap contract
- **`feeManager`** (address): Address of the FeeManager contract

### Configuration
- **`cIdStr`** (string): String representation of the local chainID

## Core Functions

### Constructor

#### `constructor(address _ctmRwaMap, address _feeManager)`
- **Purpose:** Initializes the CTMRWAERC20Deployer contract instance
- **Parameters:**
  - `_ctmRwaMap`: Address of the CTMRWAMap contract
  - `_feeManager`: Address of the FeeManager contract
- **Validation:**
  - Ensures CTMRWAMap address is not zero
  - Ensures FeeManager address is not zero
- **Initialization:**
  - Sets contract addresses
  - Sets chain ID string representation
  - Establishes integration with the CTMRWA ecosystem

### Deployment Functions

#### `deployERC20(uint256 _ID, uint256 _rwaType, uint256 _version, uint256 _slot, string memory _name, string memory _symbol, address _feeToken)`
- **Access:** Only callable by valid CTMRWA1 contracts
- **Purpose:** Deploy a new ERC20 contract linked to a CTMRWA1 for one specific slot
- **Parameters:**
  - `_ID`: Unique ID number for the CTMRWA1 contract
  - `_rwaType`: Type of RWA token (1 for CTMRWA1)
  - `_version`: Version of the RWA token
  - `_slot`: Slot number selected for this ERC20
  - `_name`: Name for the ERC20 (will be prefixed with "slot X | ")
  - `_symbol`: Symbol to use for the ERC20
  - `_feeToken`: Fee token address for payment
- **Logic:**
  - Validates CTMRWA1 contract exists in CTMRWAMap
  - Ensures caller is the valid CTMRWA1 contract
  - Pays deployment fee using FeeManager
  - Generates salt from ID, RWA type, version, and slot
  - Deploys CTMRWAERC20 using CREATE2 with salt
  - Returns the deployed contract address
- **Returns:** Address of the deployed CTMRWAERC20 contract
- **Security:** Uses CREATE2 to ensure deterministic addresses
- **Uniqueness:** Salt ensures only one ERC20 per slot per RWA per chain

## Internal Functions

### Fee Management
- **`_payFee(FeeType _feeType, address _feeToken)`**: Pays fees for deployment operations
  - Calculates fee amount using FeeManager
  - Transfers fee tokens from deployer
  - Approves and pays fee to FeeManager
  - Uses nonReentrant modifier for security
  - Returns true if fee payment successful

## Access Control Modifiers

The contract does not use custom access control modifiers, but implements access control through function-level validation:

- **CTMRWA1 Validation:** Only valid CTMRWA1 contracts can deploy ERC20 tokens
- **Contract Existence Check:** Validates CTMRWA1 contract exists in CTMRWAMap
- **Caller Verification:** Ensures caller is the actual CTMRWA1 contract

## Events

The contract does not emit custom events, as it focuses solely on deployment operations. Deployment events are handled by the calling CTMRWA1 contract.

## Security Features

1. **Access Control:** Only authorized CTMRWA1 contracts can deploy ERC20 tokens
2. **Deterministic Addresses:** CREATE2 ensures predictable contract addresses
3. **Salt-based Deployment:** Uses RWA ID, type, version, and slot as salt for uniqueness
4. **Fee Integration:** Integrated fee system for deployment operations
5. **Contract Validation:** Validates CTMRWA1 contract existence before deployment
6. **Reentrancy Protection:** Uses ReentrancyGuard for fee payment security
7. **Zero Address Validation:** Prevents deployment with invalid addresses
8. **Single Instance:** Ensures only one ERC20 per slot per RWA per chain

## Integration Points

- **CTMRWA1**: Semi-fungible token contracts that call this deployer
- **CTMRWAMap**: Contract address registry for CTMRWA1 validation
- **CTMRWAERC20**: Target contract type being deployed
- **FeeManager**: Fee calculation and payment management
- **C3Caller**: Cross-chain communication system

## Error Handling

The contract uses custom error types for efficient gas usage and clear error messages:

- **`CTMRWAERC20Deployer_IsZeroAddress(CTMRWAErrorParam.Map)`**: Thrown when CTMRWAMap address is zero
- **`CTMRWAERC20Deployer_IsZeroAddress(CTMRWAErrorParam.FeeManager)`**: Thrown when FeeManager address is zero
- **`CTMRWAERC20Deployer_InvalidContract(CTMRWAErrorParam.Token)`**: Thrown when CTMRWA1 contract not found
- **`CTMRWAERC20Deployer_OnlyAuthorized(CTMRWAErrorParam.Sender, CTMRWAErrorParam.Token)`**: Thrown when unauthorized contract tries to deploy ERC20

## Deployment Process

### 1. Deployment Request
- **Step:** CTMRWA1 contract calls deployERC20 function with slot parameters
- **Requirements:** Valid RWA ID, type, version, slot, and fee token
- **Result:** Deployment process initiated

### 2. Contract Validation
- **Step:** Validates CTMRWA1 contract exists in CTMRWAMap
- **Requirements:** Valid contract address in registry
- **Result:** Proceed if valid, revert if invalid

### 3. Caller Verification
- **Step:** Ensures caller is the actual CTMRWA1 contract
- **Requirements:** Caller matches registered CTMRWA1 address
- **Result:** Proceed if authorized, revert if unauthorized

### 4. Fee Payment
- **Step:** Pays deployment fee using FeeManager
- **Requirements:** Sufficient fee token balance and approval
- **Result:** Fee paid and deployment proceeds

### 5. Salt Generation
- **Step:** Generates salt from RWA ID, type, version, and slot
- **Requirements:** Valid RWA and slot parameters
- **Result:** Unique salt for CREATE2 deployment

### 6. Contract Creation
- **Step:** CREATE2 instruction creates new CTMRWAERC20 contract
- **Requirements:** Valid constructor parameters and unique salt
- **Result:** ERC20 contract deployed with deterministic address

### 7. Address Return
- **Step:** Deployed contract address returned
- **Requirements:** Successful deployment
- **Result:** Address available for registration in CTMRWAMap

## Use Cases

### Asset Class Representation
- **Scenario:** Creating ERC20 tokens for specific asset classes
- **Process:** Deploy ERC20 for each slot in CTMRWA1
- **Benefit:** Standard ERC20 interface for each asset class

### DeFi Integration
- **Scenario:** Enabling DeFi protocol integration
- **Process:** Deploy ERC20 tokens for trading and liquidity
- **Benefit:** Seamless integration with existing DeFi ecosystem


### Wallet Support
- **Scenario:** Supporting standard ERC20 wallets
- **Process:** Deploy ERC20 tokens for wallet compatibility
- **Benefit:** No special wallet requirements for RWA tokens

### Portfolio Management
- **Scenario:** Managing RWA token portfolios
- **Process:** Deploy ERC20 tokens for portfolio tools
- **Benefit:** Familiar ERC20 interface for portfolio management

## Best Practices

1. **Slot Planning:** Plan slot structure before ERC20 deployment
2. **Fee Management:** Ensure sufficient fee token balance for deployments
3. **Address Tracking:** Track deployed ERC20 contract addresses
4. **Cross-chain Coordination:** Coordinate deployments across all chains
5. **Validation Testing:** Test contract validation before deployment

## Limitations

- **Single Instance:** Only one ERC20 per slot per RWA per chain
- **CTMRWA1 Dependency:** Requires CTMRWA1 contract to trigger deployments
- **Fee Requirement:** All deployments require fee payment
- **Chain Specific:** Each deployer operates on a single chain
- **Slot Specific:** Each ERC20 represents only one slot

## Future Enhancements

Potential improvements to the ERC20 deployment system:

1. **Batch Deployment:** Implement batch deployment capabilities
2. **Deployment Templates:** Add support for deployment templates
3. **Enhanced Fee Models:** Implement more sophisticated fee structures
4. **Deployment Analytics:** Add deployment tracking and analytics
5. **Multi-slot Support:** Extend to deploy ERC20s for multiple slots

## CREATE2 Deployment Details

### Salt Generation
- **Method:** Uses keccak256 hash of (ID, rwaType, version, slot) as salt
- **Purpose:** Ensures unique contract addresses per slot per RWA per chain
- **Benefit:** Enables deterministic address prediction

### Address Calculation
- **Formula:** `address = keccak256(0xff ++ factoryAddress ++ salt ++ keccak256(contractBytecode ++ constructorArgs))`
- **Components:**
  - `factoryAddress`: Address of this deployer contract
  - `salt`: Hash of (ID, rwaType, version, slot)
  - `contractBytecode`: CTMRWAERC20 contract bytecode
  - `constructorArgs`: Encoded constructor arguments

### Deterministic Benefits
- **Cross-chain Consistency:** Same parameters produce same address across chains
- **Address Prediction:** Addresses can be calculated before deployment
- **Lookup Efficiency:** Enables efficient address-based lookups
- **Coordination:** Simplifies cross-chain coordination

## ERC20 Deployment Architecture

### Role in CTMRWA System
- **ERC20 Factory Layer:** Handles ERC20 contract deployment
- **Slot Interface Layer:** Provides ERC20 interface to CTMRWA1 slots
- **DeFi Integration Layer:** Enables DeFi protocol integration
- **Map Layer:** Tracks deployed ERC20 contract addresses

### Integration Flow
1. **CTMRWA1** requests ERC20 deployment for specific slot
2. **CTMRWAERC20Deployer** creates new ERC20 contract
3. **CTMRWAMap** registers new ERC20 contract address
4. **CTMRWAERC20** provides ERC20 interface to slot
5. **DeFi Protocols** interact with standard ERC20 interface
6. **FeeManager** handles fee collection

## Gas Optimization

### Deployment Costs
- **CREATE2 Operation:** ~32000 gas base cost
- **Contract Creation:** ~200000-300000 gas for CTMRWAERC20
- **Fee Payment:** Variable based on fee amount
- **Total Estimate:** ~250000-350000 gas per deployment

### Optimization Strategies
- **Minimal Deployer Logic:** Keeps deployer simple and gas-efficient
- **Fee Optimization:** Optimize fee payment mechanisms
- **Gas Estimation:** Always estimate gas before deployment
- **Network Selection:** Choose appropriate networks for deployment

## Security Considerations

### Access Control
- **CTMRWA1 Authorization:** Only valid CTMRWA1 contracts can deploy ERC20s
- **Contract Validation:** Validate CTMRWA1 contract existence
- **Caller Verification:** Ensure caller is authorized CTMRWA1
- **Address Validation:** Validate all contract addresses

### Address Collision Prevention
- **Unique Salts:** RWA and slot parameters ensure unique addresses
- **Salt Validation:** Validate salt uniqueness before deployment
- **Address Verification:** Verify deployed address matches expected

### Integration Security
- **Contract Verification:** Verify deployed contracts on block explorers
- **Address Registration:** Ensure proper registration in CTMRWAMap
- **Cross-chain Coordination:** Coordinate deployments across chains properly

## Slot Management

### Slot Representation
- **One-to-One Mapping:** Each ERC20 represents exactly one slot
- **Slot Validation:** Validates slot exists in CTMRWA1
- **Slot Metadata:** Retrieves slot information for ERC20 creation
- **Slot Coordination:** Coordinates ERC20 deployment with slot structure

### Slot Operations
- **ERC20 Creation:** Creates ERC20 interface for specific slot
- **Address Management:** Manages ERC20 addresses per slot
- **Cross-chain Consistency:** Ensures consistent slot representation
- **DeFi Integration:** Enables DeFi integration for specific slots

## Fee Management

### Fee Structure
- **Fee Type:** ERC20 deployment fee
- **Fee Calculation:** Based on chain and fee token
- **Fee Payment:** Required before deployment
- **Fee Distribution:** Paid to FeeManager contract

### Use Cases
- **Platform Fees:** Cover platform operational costs
- **Revenue Generation:** Generate revenue for ecosystem maintenance
- **Incentive Alignment:** Align incentives between stakeholders
- **Sustainability:** Ensure long-term platform sustainability
