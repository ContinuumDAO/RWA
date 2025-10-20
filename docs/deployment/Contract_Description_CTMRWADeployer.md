# CTMRWADeployer Contract Documentation

## Overview

**Contract Name:** CTMRWADeployer  
**File:** `src/deployment/CTMRWADeployer.sol`  
**License:** BSL-1.1  
**Author:** @Selqui ContinuumDAO

## Contract Description

The deploy function in this contract is called by cross chain contracts such as CTMRWA1X on each chain that an CTMRWA is deployed to. It calls other contracts that use CREATE2 to deploy the suite of contracts for the CTMRWA.

In the case of CTMRWA1, these are CTMRWA1TokenFactory to deploy CTMRWA1, CTMRWA1StorageManager to deploy CTMRWA1Storage, CTMRWA1DividendFactory to deploy CTMRWA1Dividend and CTMRWA1SentryManager to deploy CTMRWA1Sentry. Optionally, CTMRWAERC20Deployer can be used to deploy Investment contracts and ERC20 tokens that are interfaces to the underlying CTMRWA1 token.

This unique set of contracts is deployed for every ID and then the contract addresses are stored in CTMRWAMap.

The contracts that do the deployment can be updated by Governance, with different addresses dependent on the rwaType and version. The data passed to the factory contracts is abi encoded deployData for maximum flexibility for future types of CTMRWA.

This contract is only deployed ONCE on each chain and manages all CTMRWA contract interactions.

### Key Features
- Centralized deployment coordination for RWA contract components
- Multi-contract suite deployment (token, storage, dividend, sentry)
- Governance-controlled factory management
- Cross-chain integration with CTMRWA1X
- CREATE2 integration for deterministic addresses
- Investment contract deployment capabilities
- ERC20 token deployment for slot interfaces
- UUPS upgradeable pattern for future improvements

## State Variables

- `gateway (address)`: The address of the CTMRWAGateway contract
- `feeManager (address)`: The address the FeeManager contract
- `rwaX (address)`: The address of the CTMRWA1X contract
- `ctmRwaMap (address)`: The address of the CTMRWAMap contract
- `erc20Deployer (address)`: The address of the CTMRWAERC20Deployer contract
- `deployInvest (address)`: The address of the CTMRWADeployInvest contract
- `lastCommissionRateChange (uint256)`: The timestamp of the last commission rate change
- `tokenFactory (mapping(uint256 => address[1_000_000_000]))`: Storage for the addresses of the CTMRWA1TokenFactory contracts
- `dividendFactory (mapping(uint256 => address[1_000_000_000]))`: Storage for the addresses of the CTMRWA1DividendFactory addresses
- `storageFactory (mapping(uint256 => address[1_000_000_000]))`: Storage for the addresses of the CTMRWA1StorageManager addresses
- `sentryFactory (mapping(uint256 => address[1_000_000_000]))`: Storage for the addresses of the CTMRWA1SentryManager addresses

## Constructor

```solidity
function initialize(
    address _gov,
    address _gateway,
    address _feeManager,
    address _rwaX,
    address _map,
    address _c3callerProxy,
    address _txSender,
    uint256 _dappID
) external initializer
```
- Initializes the CTMRWADeployer contract instance
- Sets all core contract addresses
- Establishes integration with the broader CTMRWA ecosystem

## Access Control

- `onlyRwaX`: Restricts access to only the CTMRWA1X contract
- `onlyGov`: Restricts access to governance functions
- `initializer`: Ensures function can only be called once during initialization

## Governance Functions

### Core Contract Address Updates

#### setGateway()
```solidity
function setGateway(address _gateway) external onlyGov
```
Governance function to change the CTMRWAGateway contract address.

#### setFeeManager()
```solidity
function setFeeManager(address _feeManager) external onlyGov
```
Governance function to change the FeeManager contract address.

#### setRwaX()
```solidity
function setRwaX(address _rwaX) external onlyGov
```
Governance function to change the CTMRWA1X contract address.

#### setMap()
```solidity
function setMap(address _ctmRwaMap) external onlyGov
```
Governance function to change the CTMRWAMap contract address.

### Deployer Contract Address Updates

#### setErc20DeployerAddress()
```solidity
function setErc20DeployerAddress(address _erc20Deployer) external onlyGov
```
Governance can change to a new CTMRWAERC20Deployer contract.

#### setDeployInvest()
```solidity
function setDeployInvest(address _deployInvest) external onlyGov
```
Governance function to change the CTMRWADeployInvest contract address.

#### setDeployerMapFee()
```solidity
function setDeployerMapFee() external onlyGov
```
Governance function to set the CTMRWADeployInvest contract addresses for this contract (CTMRWADeployer), CTMRWAMap and FeeManager.

### Factory Management

#### setTokenFactory()
```solidity
function setTokenFactory(uint256 _rwaType, uint256 _version, address _tokenFactory) external onlyGov
```
Governance function to set a new CTMRWA1TokenFactory.

#### setDividendFactory()
```solidity
function setDividendFactory(uint256 _rwaType, uint256 _version, address _dividendFactory) external onlyGov
```
Governance function to set a new CTMRWA1DividendFactory.

#### setStorageFactory()
```solidity
function setStorageFactory(uint256 _rwaType, uint256 _version, address _storageFactory) external onlyGov
```
Governance function to set a new CTMRWA1StorageManager.

#### setSentryFactory()
```solidity
function setSentryFactory(uint256 _rwaType, uint256 _version, address _sentryFactory) external onlyGov
```
Governance function to set a new CTMRWA1SentryManager.

### Investment Management

#### setInvestCommissionRate()
```solidity
function setInvestCommissionRate(uint256 _commissionRate) external onlyGov
```
Governance function to set the commission rate on funds raised. The commission rate is a number between 0 and 10000, so in 0.01% increments. The commission rate can only be increased by 100 or more (1%). The commission rate can only be increased every 30 days, but can be decreased at any time.

#### getInvestCommissionRate()
```solidity
function getInvestCommissionRate() external view returns (uint256)
```
Get the commission rate on funds raised.

#### getLastCommissionRateChange()
```solidity
function getLastCommissionRateChange() external view returns (uint256)
```
Get the timestamp of the last commission rate change.

## Deployment Functions

### deploy()
```solidity
function deploy(uint256 _ID, uint256 _rwaType, uint256 _version, bytes memory deployData) external onlyRwaX returns (address, address, address, address)
```
The main deploy function that calls the various deploy functions that call CREATE2 for this ID.

### deployNewInvestment()
```solidity
function deployNewInvestment(uint256 _ID, uint256 _rwaType, uint256 _version, address _feeToken) public returns (address)
```
Deploy a new CTMRWA1Invest contract. Only the tokenAdmin of the CTMRWA contract can deploy a new investment contract. Only one CTMRWAInvest contract can be deployed on each chain.

### deployERC20()
```solidity
function deployERC20(uint256 _ID, uint256 _rwaType, uint256 _version, uint256 _slot, string memory _name, address _feeToken) public returns (address)
```
Deploy a new ERC20 contract for a specific slot. Only callable by the tokenAdmin of the CTMRWA contract.

## Internal Functions

### dividendDeployer()
```solidity
function dividendDeployer(uint256 _ID, address _tokenAddr, uint256 _rwaType, uint256 _version) internal returns (address)
```
Calls the contract function to deploy the CTMRWA1Dividend for this _ID.

### storageDeployer()
```solidity
function storageDeployer(uint256 _ID, address _tokenAddr, uint256 _rwaType, uint256 _version) internal returns (address)
```
Calls the contract function to deploy the CTMRWA1Storage for this _ID.

### sentryDeployer()
```solidity
function sentryDeployer(uint256 _ID, address _tokenAddr, uint256 _rwaType, uint256 _version) internal returns (address)
```
Governance function to change the CTMRWA1Sentry contract address.

### cID()
```solidity
function cID() internal view returns (uint256)
```
Returns current chain ID.

### _c3Fallback()
```solidity
function _c3Fallback(bytes4 _selector, bytes calldata _data, bytes calldata _reason) internal override returns (bool)
```
Fallback function for failed c3call cross-chain. Only emits an event at present.

## Events

- `LogFallback(bytes4 selector, bytes data, bytes reason)`: Emitted when a cross-chain call fails
- `CommissionRateChanged(uint256 commissionRate)`: Emitted when commission rate is changed

## Security Features

- Governance integration through C3GovernDAppUpgradeable
- Access control via onlyRwaX and onlyGov modifiers
- UUPS upgradeable pattern for future improvements
- Address validation for all contract addresses
- RWA type and version compatibility validation
- Investment contract uniqueness enforcement
- Commission rate change restrictions
- TokenAdmin authorization for investment and ERC20 deployment

## Integration Points

- `CTMRWA1X`: Cross-chain coordinator that triggers deployments
- `CTMRWAMap`: Contract address mapping and registration
- `CTMRWA1TokenFactory`: Token contract deployment
- `CTMRWA1DividendFactory`: Dividend contract deployment
- `CTMRWA1StorageManager`: Storage contract deployment
- `CTMRWA1SentryManager`: Sentry contract deployment
- `CTMRWADeployInvest`: Investment contract deployment
- `CTMRWAERC20Deployer`: ERC20 contract deployment
- `CTMRWAGateway`: Cross-chain communication gateway
- `FeeManager`: Fee calculation and payment management

## Error Handling

The contract uses custom error types for efficient gas usage:

- `CTMRWADeployer_OnlyAuthorized(CTMRWAErrorParam.Sender, CTMRWAErrorParam.RWAX/TokenAdmin)`: Thrown when unauthorized address tries to perform action
- `CTMRWADeployer_IsZeroAddress(CTMRWAErrorParam.Gateway/FeeManager/RWAX/Map/ERC20Deployer/DeployInvest)`: Thrown when zero address is provided
- `CTMRWADeployer_IncompatibleRWA(CTMRWAErrorParam.Type/Version)`: Thrown when RWA type or version is incompatible
- `CTMRWADeployer_InvalidContract(CTMRWAErrorParam.Token/SlotName/RWAERC20/Invest)`: Thrown when contract validation fails
- `CTMRWADeployer_CommissionRateOutOfBounds(CTMRWAErrorParam.Commission)`: Thrown when commission rate is out of bounds
- `CTMRWADeployer_CommissionRateIncreasedTooMuch(CTMRWAErrorParam.Commission)`: Thrown when commission rate increase is too large
- `CTMRWADeployer_CommissionRateChangeTooSoon(CTMRWAErrorParam.Commission)`: Thrown when commission rate change is too soon

## Deployment Process

### 1. Token Deployment
- CTMRWA1TokenFactory deploys CTMRWA1 contract using CREATE2
- Validates RWA type and version compatibility
- Returns token contract address

### 2. Component Deployment
- Deploys dividend contract (if factory exists)
- Deploys storage contract (if factory exists)  
- Deploys sentry contract (if factory exists)
- Returns component contract addresses

### 3. Address Registration
- All contract addresses registered in CTMRWAMap
- Complete RWA ecosystem ready for operations

## Use Cases

### New RWA Deployment
- Deploying a new RWA across multiple chains
- Coordinated deployment of all contract components
- Standardized deployment process with full ecosystem

### Investment Platform Setup
- Setting up investment capabilities for RWA
- Deploy investment contract for capital raising
- Enables structured investment opportunities

### ERC20 Interface Deployment
- Creating ERC20 interfaces for specific slots
- Enabling traditional ERC20 interactions with RWA tokens
- Slot-specific token interfaces

### Factory Management
- Updating deployment factories for new RWA types
- Governance-controlled factory address updates
- Enables deployment of new RWA contract types

## Best Practices

1. **Factory Management**: Keep factory addresses up to date for new RWA types
2. **Address Validation**: Always validate contract addresses before use
3. **Compatibility Checks**: Ensure RWA type and version compatibility
4. **Investment Planning**: Plan investment contract deployment carefully
5. **Commission Planning**: Set appropriate commission rates for investment contracts
6. **TokenAdmin Authorization**: Ensure proper authorization for investment and ERC20 deployment
7. **Cross-chain Coordination**: Coordinate deployments across all chains
8. **Address Synchronization**: Use setDeployerMapFee for address consistency