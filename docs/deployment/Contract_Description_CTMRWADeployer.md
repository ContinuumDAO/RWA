# CTMRWADeployer Contract Documentation

## Overview

**Contract Name:** CTMRWADeployer  
**Author:** @Selqui ContinuumDAO  
**License:** BSL-1.1  
**Solidity Version:** 0.8.27

The CTMRWADeployer contract is the central deployment coordinator for the CTMRWA ecosystem. The deploy function in this contract is called by CTMRWA1X on each chain that an RWA is deployed to. It calls other contracts that use CREATE2 to deploy the suite of contracts for the RWA.

These include CTMRWA1TokenFactory to deploy CTMRWA1, CTMRWA1StorageManager to deploy CTMRWA1Storage, CTMRWA1DividendFactory to deploy CTMRWA1Dividend, and CTMRWA1SentryManager to deploy CTMRWA1Sentry. This unique set of contracts is deployed for every ID and then the contract addresses are stored in CTMRWAMap.

The contracts that do the deployment can be updated by Governance, with different addresses dependent on the rwaType and version. The data passed to CTMRWA1TokenFactory is abi encoded deployData for maximum flexibility for future types of RWA.

This contract is only deployed ONCE on each chain and manages all CTMRWA1 contract interactions.

## Key Features

- **Centralized Deployment:** Coordinates deployment of all RWA contract components
- **Multi-contract Suite:** Deploys token, storage, dividend, and sentry contracts
- **Governance Control:** Factory addresses can be updated by governance
- **Cross-chain Integration:** Works with CTMRWA1X for cross-chain deployments
- **CREATE2 Integration:** Uses CREATE2 for deterministic contract addresses
- **Upgradeable:** Uses UUPS upgradeable pattern for future improvements
- **Investment Support:** Can deploy investment contracts for capital raising
- **Factory Management:** Flexible factory system for different RWA types and versions
- **Address Validation:** Comprehensive validation of all contract addresses
- **Commission Management:** Configurable commission rates for investment contracts

## Public Variables

### Contract Addresses
- **`gateway`** (address): Address of the CTMRWAGateway contract
- **`feeManager`** (address): Address of the FeeManager contract
- **`rwaX`** (address): Address of the CTMRWA1X contract
- **`ctmRwaMap`** (address): Address of the CTMRWAMap contract
- **`erc20Deployer`** (address): Address of the CTMRWAERC20Deployer contract
- **`deployInvest`** (address): Address of the CTMRWADeployInvest contract

### Factory Mappings
- **`tokenFactory`** (mapping(uint256 => address[1_000_000_000])): Storage for CTMRWA1TokenFactory contract addresses by RWA type and version
- **`dividendFactory`** (mapping(uint256 => address[1_000_000_000])): Storage for CTMRWA1DividendFactory addresses by RWA type and version
- **`storageFactory`** (mapping(uint256 => address[1_000_000_000])): Storage for CTMRWA1StorageManager addresses by RWA type and version
- **`sentryFactory`** (mapping(uint256 => address[1_000_000_000])): Storage for CTMRWA1SentryManager addresses by RWA type and version

## Core Functions

### Initialization

#### `initialize(address _gov, address _gateway, address _feeManager, address _rwaX, address _map, address _c3callerProxy, address _txSender, uint256 _dappID)`
- **Purpose:** Initializes the CTMRWADeployer contract instance
- **Parameters:**
  - `_gov`: Address of the governance contract
  - `_gateway`: Address of the CTMRWAGateway contract
  - `_feeManager`: Address of the FeeManager contract
  - `_rwaX`: Address of the CTMRWA1X contract
  - `_map`: Address of the CTMRWAMap contract
  - `_c3callerProxy`: Address of the C3 caller proxy
  - `_txSender`: Address of the transaction sender
  - `_dappID`: ID of the dapp
- **Initialization:**
  - Initializes C3GovernDapp with governance parameters
  - Sets all core contract addresses
  - Establishes integration with the broader CTMRWA ecosystem
- **Access:** Can only be called once during contract deployment

### Governance Functions

#### Core Contract Address Updates
- **`setGateway(address _gateway)`**: Updates CTMRWAGateway contract address
- **`setFeeManager(address _feeManager)`**: Updates FeeManager contract address
- **`setRwaX(address _rwaX)`**: Updates CTMRWA1X contract address
- **`setMap(address _ctmRwaMap)`**: Updates CTMRWAMap contract address

**Access:** Only callable by governance  
**Validation:** Ensures address is not zero  
**Use Case:** Allows governance to update core contract addresses

#### Deployer Contract Address Updates
- **`setErc20DeployerAddress(address _erc20Deployer)`**: Updates CTMRWAERC20Deployer contract address
- **`setDeployInvest(address _deployInvest)`**: Updates CTMRWADeployInvest contract address

**Access:** Only callable by governance  
**Validation:** Ensures address is not zero  
**Use Case:** Allows governance to update deployer contract addresses

#### `setDeployerMapFee()`
- **Access:** Only callable by governance
- **Purpose:** Sets deployer, map, and fee addresses in CTMRWADeployInvest
- **Logic:** Calls setDeployerMapFee on the deployInvest contract
- **Use Case:** Synchronizes addresses across related contracts

### Factory Management Functions

#### `setTokenFactory(uint256 _rwaType, uint256 _version, address _tokenFactory)`
- **Access:** Only callable by governance
- **Purpose:** Sets a new CTMRWA1TokenFactory for specific RWA type and version
- **Parameters:**
  - `_rwaType`: RWA type (1 for CTMRWA1)
  - `_version`: RWA version (1 for current)
  - `_tokenFactory`: Address of the new token factory
- **Use Case:** Enables deployment of new RWA token types

#### `setDividendFactory(uint256 _rwaType, uint256 _version, address _dividendFactory)`
- **Access:** Only callable by governance
- **Purpose:** Sets a new CTMRWA1DividendFactory for specific RWA type and version
- **Parameters:**
  - `_rwaType`: RWA type (1 for CTMRWA1)
  - `_version`: RWA version (1 for current)
  - `_dividendFactory`: Address of the new dividend factory
- **Use Case:** Enables deployment of new dividend contract types

#### `setStorageFactory(uint256 _rwaType, uint256 _version, address _storageFactory)`
- **Access:** Only callable by governance
- **Purpose:** Sets a new CTMRWA1StorageManager for specific RWA type and version
- **Parameters:**
  - `_rwaType`: RWA type (1 for CTMRWA1)
  - `_version`: RWA version (1 for current)
  - `_storageFactory`: Address of the new storage factory
- **Use Case:** Enables deployment of new storage contract types

#### `setSentryFactory(uint256 _rwaType, uint256 _version, address _sentryFactory)`
- **Access:** Only callable by governance
- **Purpose:** Sets a new CTMRWA1SentryManager for specific RWA type and version
- **Parameters:**
  - `_rwaType`: RWA type (1 for CTMRWA1)
  - `_version`: RWA version (1 for current)
  - `_sentryFactory`: Address of the new sentry factory
- **Use Case:** Enables deployment of new sentry contract types

### Deployment Functions

#### `deploy(uint256 _ID, uint256 _rwaType, uint256 _version, bytes memory deployData)`
- **Access:** Only callable by CTMRWA1X
- **Purpose:** Main deployment function that coordinates deployment of all RWA contract components
- **Parameters:**
  - `_ID`: Unique RWA ID
  - `_rwaType`: RWA type (1 for CTMRWA1)
  - `_version`: RWA version (1 for current)
  - `deployData`: ABI encoded deployment data for token factory
- **Logic:**
  - Deploys CTMRWA1 token contract using token factory
  - Validates RWA type and version compatibility
  - Deploys dividend contract (if factory exists)
  - Deploys storage contract (if factory exists)
  - Deploys sentry contract (if factory exists)
  - Attaches all contracts to CTMRWAMap
- **Returns:** Tuple of (tokenAddr, dividendAddr, storageAddr, sentryAddr)
- **Integration:** Coordinates with CTMRWAMap for address registration
- **Security:** Validates RWA type and version compatibility

### Investment Functions

#### `setInvestCommissionRate(uint256 _commissionRate)`
- **Access:** Only callable by governance
- **Purpose:** Sets the commission rate on funds raised
- **Parameters:**
  - `_commissionRate`: Number between 0 and 10000 (0.01% increments)
- **Logic:** Calls setCommissionRate on the deployInvest contract
- **Use Case:** Configures investment contract commission structure

#### `deployNewInvestment(uint256 _ID, uint256 _rwaType, uint256 _version, address _feeToken)`
- **Purpose:** Deploys a new CTMRWA1Invest contract
- **Parameters:**
  - `_ID`: ID of the RWA token
  - `_rwaType`: Type of RWA (1 for CTMRWA1)
  - `_version`: Version of RWA (1 for current)
  - `_feeToken`: Address of valid fee token
- **Requirements:**
  - Only one CTMRWA1Invest contract can be deployed per chain per RWA
  - deployInvest address must be set
- **Logic:**
  - Checks if investment contract already exists
  - Deploys new investment contract
  - Registers contract in CTMRWAMap
- **Returns:** Address of the deployed investment contract
- **Note:** Anyone can call this, but only tokenAdmin can create offerings

## Internal Functions

### Deployment Coordination
- **`dividendDeployer(uint256 _ID, address _tokenAddr, uint256 _rwaType, uint256 _version)`**: 
  - Deploys CTMRWA1Dividend contract if factory exists
  - Returns dividend contract address or address(0) if no factory
- **`storageDeployer(uint256 _ID, address _tokenAddr, uint256 _rwaType, uint256 _version)`**: 
  - Deploys CTMRWA1Storage contract if factory exists
  - Returns storage contract address or address(0) if no factory
- **`sentryDeployer(uint256 _ID, address _tokenAddr, uint256 _rwaType, uint256 _version)`**: 
  - Deploys CTMRWA1Sentry contract if factory exists
  - Returns sentry contract address or address(0) if no factory

### Utility Functions
- **`cID()`**: Returns current chain ID
- **`_c3Fallback(bytes4 _selector, bytes calldata _data, bytes calldata _reason)`**: 
  - Handles failed cross-chain calls
  - Emits LogFallback event with failure details
  - Returns true to indicate successful fallback handling

### Upgrade Functions
- **`_authorizeUpgrade(address newImplementation)`**: 
  - Internal function for UUPS upgrade authorization
  - Only callable by governance
  - Enables contract upgrades

## Access Control Modifiers

- **`onlyRwaX`**: Restricts access to only the CTMRWA1X contract
  - Ensures that only the authorized cross-chain coordinator can trigger deployments
  - Prevents unauthorized contract deployments
- **`onlyGov`**: Restricts access to governance functions
  - Inherited from C3GovernDappUpgradeable
  - Ensures only governance can perform administrative functions
- **`initializer`**: Ensures function can only be called once during initialization
  - Prevents re-initialization attacks

## Events

The contract emits events for tracking operations:

- **`LogFallback(bytes4 indexed selector, bytes data, bytes reason)`**: Emitted when a cross-chain call fails
  - `selector`: Function selector that failed
  - `data`: ABI encoded data that was sent
  - `reason`: Revert reason from the failed operation

## Security Features

1. **Governance Integration:** Built-in governance through C3GovernDappUpgradeable
2. **Access Control:** Comprehensive modifier system for different roles
3. **Upgradeable:** UUPS upgradeable pattern for future improvements
4. **Address Validation:** Validates all contract addresses are not zero
5. **Compatibility Checks:** Validates RWA type and version compatibility
6. **Integration Safety:** Works within established deployment architecture
7. **Factory Validation:** Ensures factory contracts exist before deployment
8. **Investment Uniqueness:** Prevents duplicate investment contracts
9. **Cross-chain Security:** Secure fallback handling for failed operations

## Integration Points

- **CTMRWA1X**: Cross-chain coordinator that triggers deployments
- **CTMRWAMap**: Contract address mapping and registration
- **CTMRWA1TokenFactory**: Token contract deployment
- **CTMRWA1DividendFactory**: Dividend contract deployment
- **CTMRWA1StorageManager**: Storage contract deployment
- **CTMRWA1SentryManager**: Sentry contract deployment
- **CTMRWADeployInvest**: Investment contract deployment
- **CTMRWAGateway**: Cross-chain communication gateway
- **FeeManager**: Fee calculation and payment management
- **C3GovernDapp**: Governance and upgrade management

## Error Handling

The contract uses custom error types for efficient gas usage and clear error messages:

- **`CTMRWADeployer_OnlyAuthorized(CTMRWAErrorParam.Sender, CTMRWAErrorParam.RWAX)`**: Thrown when unauthorized address tries to deploy
- **`CTMRWADeployer_IsZeroAddress(CTMRWAErrorParam.Gateway/FeeManager/RWAX/Map/ERC20Deployer/DeployInvest)`**: Thrown when zero address is provided
- **`CTMRWADeployer_IncompatibleRWA(CTMRWAErrorParam.Type/Version)`**: Thrown when RWA type or version is incompatible
- **`CTMRWADeployer_InvalidContract(CTMRWAErrorParam.Invest)`**: Thrown when investment contract already exists

## Deployment Process

### 1. Deployment Request
- **Step:** CTMRWA1X calls deploy function with RWA parameters
- **Requirements:** Valid RWA ID, type, version, and deployment data
- **Result:** Deployment process initiated

### 2. Token Contract Deployment
- **Step:** CTMRWA1TokenFactory deploys CTMRWA1 contract
- **Requirements:** Valid deployment data and factory address
- **Result:** Token contract deployed with deterministic address

### 3. Compatibility Validation
- **Step:** Validate deployed token contract RWA type and version
- **Requirements:** Token contract must match expected parameters
- **Result:** Compatibility confirmed or deployment reverted

### 4. Component Deployment
- **Step:** Deploy dividend, storage, and sentry contracts
- **Requirements:** Factory addresses must be set (optional)
- **Result:** All available component contracts deployed

### 5. Address Registration
- **Step:** All contract addresses registered in CTMRWAMap
- **Requirements:** Successful deployment of all components
- **Result:** Complete RWA ecosystem ready for use

## Use Cases

### New RWA Deployment
- **Scenario:** Deploying a new RWA across multiple chains
- **Process:** Deployer coordinates deployment of all contract components
- **Benefit:** Standardized deployment process with full ecosystem

### Cross-chain Coordination
- **Scenario:** Coordinating deployments across multiple chains
- **Process:** CTMRWA1X triggers deployments on each chain
- **Benefit:** Consistent RWA deployment across all chains

### Investment Platform Setup
- **Scenario:** Setting up investment capabilities for RWA
- **Process:** Deploy investment contract for capital raising
- **Benefit:** Enables structured investment opportunities

### Factory Updates
- **Scenario:** Updating deployment factories for new RWA types
- **Process:** Governance updates factory addresses
- **Benefit:** Enables deployment of new RWA contract types

### Contract Address Management
- **Scenario:** Updating core contract addresses
- **Process:** Governance updates contract addresses
- **Benefit:** Maintains system integration and functionality

## Best Practices

1. **Factory Management:** Keep factory addresses up to date for new RWA types
2. **Address Validation:** Always validate contract addresses before use
3. **Compatibility Checks:** Ensure RWA type and version compatibility
4. **Cross-chain Coordination:** Coordinate deployments across all chains
5. **Investment Planning:** Plan investment contract deployment carefully
6. **Governance Updates:** Regular review and updates of factory addresses
7. **Address Synchronization:** Use setDeployerMapFee for address consistency
8. **Commission Planning:** Set appropriate commission rates for investment contracts

## Limitations

- **Single Investment Contract:** Only one investment contract per chain per RWA
- **Factory Dependency:** Requires factory addresses to be set for deployment
- **Governance Control:** All factory updates require governance approval
- **Chain Specific:** Each deployer operates on a single chain
- **Initialization Restriction:** Can only be initialized once
- **Factory Optionality:** Component contracts are optional if factories not set

## Future Enhancements

Potential improvements to the deployment system:

1. **Batch Deployment:** Implement batch deployment for multiple RWAs
2. **Deployment Templates:** Add support for deployment templates
3. **Automated Validation:** Add post-deployment validation mechanisms
4. **Deployment Analytics:** Add deployment tracking and analytics
5. **Multi-version Support:** Enhanced support for multiple RWA versions
6. **Dynamic Factory Updates:** Automated factory address updates
7. **Deployment Verification:** On-chain deployment verification
8. **Gas Optimization:** Enhanced gas optimization for deployments

## Deployment Architecture

### Role in CTMRWA System
- **Deployment Layer:** Coordinates all contract deployments
- **Factory Layer:** Manages deployment factories
- **Map Layer:** Tracks deployed contract addresses
- **Integration Layer:** Connects with cross-chain infrastructure
- **Governance Layer:** Manages system configuration

### Integration Flow
1. **CTMRWA1X** receives deployment request
2. **CTMRWADeployer** coordinates deployment
3. **Factory Contracts** deploy individual components
4. **CTMRWAMap** registers all addresses
5. **RWA Ecosystem** ready for operations

### Factory System Design
- **Type-based Mapping:** Different factories for different RWA types
- **Version-based Mapping:** Different factories for different versions
- **Flexible Deployment:** Optional component deployment
- **Governance Control:** Centralized factory management

## Gas Optimization

### Deployment Costs
- **Token Deployment:** ~250000-300000 gas
- **Component Deployment:** ~100000-150000 gas each
- **Address Registration:** ~50000 gas
- **Total Estimate:** ~500000-700000 gas per RWA

### Optimization Strategies
- **Factory Updates:** Update factories efficiently
- **Batch Operations:** Consider batch deployments
- **Gas Estimation:** Always estimate gas before deployment
- **Network Selection:** Choose appropriate networks for deployment
- **Optional Components:** Deploy only necessary components

## Security Considerations

### Access Control
- **Deployer Authorization:** Only CTMRWA1X can trigger deployments
- **Governance Control:** Factory updates require governance approval
- **Address Validation:** Validate all contract addresses
- **Upgrade Authorization:** Only governance can authorize upgrades

### Deployment Security
- **Factory Security:** Ensure factory contracts are secure and audited
- **Compatibility Validation:** Validate RWA type and version compatibility
- **Address Registration:** Ensure proper registration in CTMRWAMap
- **Investment Uniqueness:** Prevent duplicate investment contracts

### Integration Security
- **Cross-chain Coordination:** Coordinate deployments across chains properly
- **Contract Verification:** Verify deployed contracts on block explorers
- **Address Tracking:** Track all deployed contract addresses
- **Fallback Handling:** Secure handling of failed cross-chain operations

### Upgrade Security
- **UUPS Pattern:** Secure upgrade mechanism
- **Governance Authorization:** Only governance can authorize upgrades
- **Implementation Validation:** Validate new implementation addresses
- **Rollback Capability:** Maintain ability to rollback if needed
