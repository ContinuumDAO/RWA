# Contract Description: CTMRWAMap

## Overview

The `CTMRWAMap` contract links together the various parts of CTMRWA tokens (e.g. CTMRWA1). For every ID (and rwaType and version), which is unique to one CTMRWA token, there are different contracts as follows:

1. The CTMRWA contract itself, which is the Semi-Fungible-Token
2. A Dividend contract called CTMRWA1Dividend (for rwaType 1)
3. A Storage contract called CTMRWA1Storage (for rwwatType 1)
4. A Sentry contract called CTMRWA1Sentry (for rwaType 1)
5. A Investment contract called CTMRWADeployInvest
6. A ERC20 contract called CTMRWAERC20

This set all share a single ID, which is the same on all chains that the CTMRWA token is deployed to. The whole set is deployed by CTMRWADeployer. This contract, deployed just once on each chain, stores the state linking the ID to each of the constituent contract addresses. The links from the contract addresses back to the ID are also stored.

## Contract Description

The CTMRWAMap is a central registry contract that maintains the mapping between RWA token IDs and their associated contract addresses. It serves as the single source of truth for contract relationships within the RWA ecosystem, enabling cross-contract communication and ensuring proper contract associations.

## Key Features

- **Contract Registry**: Central registry for all RWA token contracts
- **Bidirectional Mapping**: Maps IDs to contracts and contracts to IDs
- **Multi-contract Support**: Supports multiple contract types per RWA token
- **Cross-chain Consistency**: Maintains consistent mappings across chains
- **Contract Attachment**: Links contracts together during deployment
- **Type and Version Validation**: Ensures contract compatibility
- **Access Control**: Restricted access for contract management

## Public Variables

### gateway
```solidity
address public gateway
```
The address of the CTMRWAGateway contract

### ctmRwaDeployer
```solidity
address public ctmRwaDeployer
```
The address of the CTMRWADeployer contract

### ctmRwa1X
```solidity
address public ctmRwa1X
```
The address of the CTMRWA1X contract

### cIdStr
```solidity
string cIdStr
```
String representation of the local chainID

## Mapping Variables

### idToContract
```solidity
mapping(uint256 => string) idToContract
```
ID => address of CTMRWA1 contract as string

### contractToId
```solidity
mapping(string => uint256) contractToId
```
address of CTMRWA1 contract as string => ID

### idToDividend
```solidity
mapping(uint256 => string) idToDividend
```
ID => CTMRWA1Dividend contract as string

### dividendToId
```solidity
mapping(string => uint256) dividendToId
```
CTMRWA1Dividend contract as string => ID

### idToStorage
```solidity
mapping(uint256 => string) idToStorage
```
ID => CTMRWA1Storage contract as string

### storageToId
```solidity
mapping(string => uint256) storageToId
```
CTMRWA1Storage contract as string => ID

### idToSentry
```solidity
mapping(uint256 => string) idToSentry
```
ID => CTMRWA1Sentry contract as string

### sentryToId
```solidity
mapping(string => uint256) sentryToId
```
CTMRWA1Sentry contract as string => ID

### idToInvest
```solidity
mapping(uint256 => string) idToInvest
```
ID => CTMRWADeployInvest contract as string

### investToId
```solidity
mapping(string => uint256) investToId
```
CTMRWADeployInvest contract as string => ID

### idToErc20
```solidity
mapping(uint256 => mapping(uint256 => string)) idToErc20
```
ID => slot => CTMRWAERC20 contract as string

### erc20ToId
```solidity
mapping(uint256 => mapping(string => uint256)) erc20ToId
```
slot => CTMRWAERC20 contract as string => ID

## Constructor

### initialize()
```solidity
function initialize(
    address _gov,
    address _c3callerProxy,
    address _txSender,
    uint256 _dappID,
    address _gateway,
    address _rwa1X
) external initializer
```
Initialize the contract with required parameters

**Parameters:**
- `_gov`: The governance address
- `_c3callerProxy`: The C3 caller proxy address
- `_txSender`: The transaction sender address
- `_dappID`: The dApp ID
- `_gateway`: The gateway address
- `_rwa1X`: The CTMRWA1X address

## Access Control

### onlyDeployer
```solidity
modifier onlyDeployer()
```
Restricts access to the deployer only

### onlyRwa1X
```solidity
modifier onlyRwa1X()
```
Restricts access to the CTMRWA1X contract only

## Administrative Functions

### setCtmRwaDeployer()
```solidity
function setCtmRwaDeployer(address _deployer, address _gateway, address _rwa1X) external onlyRwa1X
```
Set the addresses of CTMRWADeployer, CTMRWAGateway and CTMRWA1X

**Parameters:**
- `_deployer`: The deployer address
- `_gateway`: The gateway address
- `_rwa1X`: The CTMRWA1X address

**Note:** Can only be called by the setMap function in CTMRWA1X, called by Governor

## Query Functions

### getTokenId()
```solidity
function getTokenId(string memory _tokenAddrStr, uint256 _rwaType, uint256 _version) public view returns (bool, uint256)
```
Return the ID of a given CTMRWA1 contract

**Parameters:**
- `_tokenAddrStr`: String version of the CTMRWA1 contract address
- `_rwaType`: The type of CTMRWA. Must be 1 here, to match CTMRWA1
- `_version`: The version of this CTMRWA. Latest version is 1

**Returns:**
- `ok`: True if the ID exists, false otherwise
- `id`: The ID of the CTMRWA1 contract

**Note:** The input address is a string. The function also returns a boolean ok, which is false if the ID does not exist

### getTokenContract()
```solidity
function getTokenContract(uint256 _ID, uint256 _rwaType, uint256 _version) public view returns (bool, address)
```
Return the CTMRWA1 contract address for a given ID

**Parameters:**
- `_ID`: The ID being examined
- `_rwaType`: The type of CTMRWA. Must be 1 here, to match CTMRWA1
- `_version`: The version of this CTMRWA. Latest version is 1

**Returns:**
- `ok`: True if the ID exists, false otherwise
- `contractAddr`: The address of the CTMRWA1 contract

### getDividendContract()
```solidity
function getDividendContract(uint256 _ID, uint256 _rwaType, uint256 _version) public view returns (bool, address)
```
Return the CTMRWA1Dividend contract address for a given ID

**Parameters:**
- `_ID`: The ID being examined
- `_rwaType`: The type of CTMRWA. Must be 1 here, to match CTMRWA1
- `_version`: The version of this CTMRWA. Latest version is 1

**Returns:**
- `ok`: True if the ID exists, false otherwise
- `dividendAddr`: The address of the CTMRWA1Dividend contract

### getStorageContract()
```solidity
function getStorageContract(uint256 _ID, uint256 _rwaType, uint256 _version) public view returns (bool, address)
```
Return the CTMRWA1Storage contract address for a given ID

**Parameters:**
- `_ID`: The ID being examined
- `_rwaType`: The type of CTMRWA. Must be 1 here, to match CTMRWA1
- `_version`: The version of this CTMRWA. Latest version is 1

**Returns:**
- `ok`: True if the ID exists, false otherwise
- `storageAddr`: The address of the CTMRWA1Storage contract

### getSentryContract()
```solidity
function getSentryContract(uint256 _ID, uint256 _rwaType, uint256 _version) public view returns (bool, address)
```
Return the CTMRWA1Sentry contract address for a given ID

**Parameters:**
- `_ID`: The ID being examined
- `_rwaType`: The type of CTMRWA. Must be 1 here, to match CTMRWA1
- `_version`: The version of this CTMRWA. Latest version is 1

**Returns:**
- `ok`: True if the ID exists, false otherwise
- `sentryAddr`: The address of the CTMRWA1Sentry contract

### getInvestContract()
```solidity
function getInvestContract(uint256 _ID, uint256 _rwaType, uint256 _version) public view returns (bool, address)
```
Return the CTMRWADeployInvest contract address for a given ID

**Parameters:**
- `_ID`: The ID being examined
- `_rwaType`: The type of CTMRWA. Must be 1 here, to match CTMRWA1
- `_version`: The version of this CTMRWA. Latest version is 1

**Returns:**
- `ok`: True if the ID exists, false otherwise
- `investAddr`: The address of the CTMRWADeployInvest contract

### getErc20Contract()
```solidity
function getErc20Contract(uint256 _ID, uint256 _rwaType, uint256 _version, uint256 _slot) public view returns (bool, address)
```
Return the CTMRWAERC20 contract address for a given ID and slot

**Parameters:**
- `_ID`: The ID being examined
- `_rwaType`: The type of CTMRWA. Must be 1 here, to match CTMRWA1
- `_version`: The version of this CTMRWA. Latest version is 1
- `_slot`: The slot number being examined

**Returns:**
- `ok`: True if the ID and slot exist, false otherwise
- `erc20Addr`: The address of the CTMRWAERC20 contract

## Contract Management Functions

### attachContracts()
```solidity
function attachContracts(
    uint256 _ID,
    address _tokenAddr,
    address _dividendAddr,
    address _storageAddr,
    address _sentryAddr
) external onlyDeployer
```
This function is called by CTMRWADeployer after the deployment of the CTMRWA1, CTMRWA1Dividend, CTMRWA1Storage and CTMRWA1Sentry contracts on a chain. It links them together by setting the same ID for the one CTMRWA token and storing their contract addresses.

**Parameters:**
- `_ID`: The ID of the CTMRWA token
- `_tokenAddr`: The address of the CTMRWA1 contract
- `_dividendAddr`: The address of the CTMRWA1Dividend contract
- `_storageAddr`: The address of the CTMRWA1Storage contract
- `_sentryAddr`: The address of the CTMRWA1Sentry contract

**Note:** Only the deployer of the CTMRWAMap contract can call this function

### setInvestmentContract()
```solidity
function setInvestmentContract(uint256 _ID, uint256 _rwaType, uint256 _version, address _investAddr) external onlyDeployer returns (bool)
```
Set the investment contract for a given ID

**Parameters:**
- `_ID`: The ID of the CTMRWA token
- `_rwaType`: The type of CTMRWA. Must be 1 here, to match CTMRWA1
- `_version`: The version of this CTMRWA. Latest version is 1
- `_investAddr`: The address of the CTMRWADeployInvest contract

**Returns:** success True if the investment contract was set, false otherwise

**Note:** Only the deployer of the CTMRWAMap contract can call this function

### setErc20Contract()
```solidity
function setErc20Contract(uint256 _ID, uint256 _rwaType, uint256 _version, uint256 _slot, address _erc20Addr) external onlyDeployer returns (bool)
```
Set the ERC20 contract for a given ID and slot

**Parameters:**
- `_ID`: The ID of the CTMRWA token
- `_rwaType`: The type of CTMRWA. Must be 1 here, to match CTMRWA1
- `_version`: The version of this CTMRWA. Latest version is 1
- `_slot`: The slot number for the ERC20
- `_erc20Addr`: The address of the CTMRWAERC20 contract

**Returns:** success True if the ERC20 contract was set, false otherwise

**Note:** Only the deployer of the CTMRWAMap contract can call this function

## Internal Functions

### _attachCTMRWAID()
```solidity
function _attachCTMRWAID(
    uint256 _ID,
    address _ctmRwaAddr,
    address _dividendAddr,
    address _storageAddr,
    address _sentryAddr
) internal returns (bool)
```
Internal helper function for attachContracts

**Parameters:**
- `_ID`: The ID of the CTMRWA token
- `_ctmRwaAddr`: The address of the CTMRWA1 contract
- `_dividendAddr`: The address of the CTMRWA1Dividend contract
- `_storageAddr`: The address of the CTMRWA1Storage contract
- `_sentryAddr`: The address of the CTMRWA1Sentry contract

**Returns:** success True if the contracts were attached, false otherwise

### _checkRwaTypeVersion()
```solidity
function _checkRwaTypeVersion(string memory _addrStr, uint256 _rwaType, uint256 _version) internal view returns (bool)
```
Internal helper function to check the CTMRWA type and version of a contract

**Parameters:**
- `_addrStr`: The address of the contract to check
- `_rwaType`: The type of CTMRWA. Must be 1 here, to match CTMRWA1
- `_version`: The version of this CTMRWA. Latest version is 1

**Returns:** ok True if the CTMRWA type and version are compatible, false otherwise

### cID()
```solidity
function cID() internal view returns (uint256)
```
Get the current chain ID

**Returns:** The current chain ID

### _c3Fallback()
```solidity
function _c3Fallback(bytes4 _selector, bytes calldata _data, bytes calldata _reason) internal override returns (bool)
```
Fallback function for failed c3call cross-chain. Only emits an event at present

**Parameters:**
- `_selector`: The selector of the function that failed
- `_data`: The data of the function that failed
- `_reason`: The reason for the failure

**Returns:** ok True if the fallback was successful, false otherwise

## Events

### LogFallback
```solidity
event LogFallback(bytes4 selector, bytes data, bytes reason)
```
Emitted when a cross-chain call fails and fallback is triggered

**Parameters:**
- `selector`: The selector of the failed function
- `data`: The data of the failed function
- `reason`: The reason for the failure

## Security Features

- **Access Control**: Multi-layer access control with role-based permissions
- **Input Validation**: Comprehensive input validation for all parameters
- **Type and Version Validation**: Ensures contract compatibility
- **Zero Address Protection**: Prevents zero address assignments
- **Duplicate Prevention**: Prevents duplicate contract attachments
- **Contract Verification**: Verifies contract compatibility before attachment

## Integration Points

- **CTMRWA1**: Core RWA token contract integration
- **CTMRWA1Dividend**: Dividend contract integration
- **CTMRWA1Storage**: Storage contract integration
- **CTMRWA1Sentry**: Sentry contract integration
- **CTMRWADeployInvest**: Investment contract integration
- **CTMRWAERC20**: ERC20 contract integration
- **CTMRWADeployer**: Deployer contract integration
- **CTMRWAGateway**: Gateway contract integration
- **CTMRWA1X**: Cross-chain contract integration

## Error Handling

The contract uses custom error types for gas efficiency:

- `CTMRWAMap_OnlyAuthorized`: Thrown when unauthorized access is attempted
- `CTMRWAMap_IsZeroAddress`: Thrown when zero address is provided
- `CTMRWAMap_AlreadyAttached`: Thrown when contract is already attached
- `CTMRWAMap_FailedAttachment`: Thrown when attachment fails
- `CTMRWAMap_IncompatibleRWA`: Thrown when RWA type or version is incompatible

## Contract Attachment Process

### 1. Contract Deployment
- Deploy CTMRWA1, CTMRWA1Dividend, CTMRWA1Storage, and CTMRWA1Sentry contracts
- Ensure all contracts are properly initialized
- Verify contract compatibility

### 2. Contract Attachment
- Call attachContracts with all contract addresses
- Link contracts together with shared ID
- Set up bidirectional mappings
- Attach contracts to each other

### 3. Investment Contract Setup
- Set investment contract for the ID
- Verify contract compatibility
- Set up investment contract mapping

### 4. ERC20 Contract Setup
- Set ERC20 contract for specific slot
- Verify contract compatibility
- Set up ERC20 contract mapping

## Use Cases

1. **Contract Discovery**: Find contract addresses by ID
2. **Cross-contract Communication**: Enable communication between contracts
3. **Contract Validation**: Verify contract relationships
4. **Deployment Management**: Manage contract deployments
5. **Cross-chain Consistency**: Maintain consistent mappings across chains
6. **Contract Registry**: Central registry for all RWA contracts
7. **Relationship Management**: Manage contract relationships

## Best Practices

1. **Contract Planning**: Plan contract relationships before deployment
2. **Address Management**: Properly manage contract addresses
3. **Type Validation**: Ensure contract type and version compatibility
4. **Access Control**: Maintain proper access control for sensitive operations
5. **Error Handling**: Implement robust error handling
6. **Integration**: Ensure proper integration with other contracts
7. **Security**: Implement security measures for contract management

## Limitations

- **Single Chain**: Each map contract is chain-specific
- **Deployer Dependency**: Requires deployer for contract attachment
- **Type Restriction**: Limited to specific RWA types and versions
- **Address Format**: Requires string format for addresses
- **Contract Dependency**: Depends on other contracts for functionality

## Future Enhancements

- **Multi-chain Support**: Enhanced multi-chain contract management
- **Advanced Validation**: More sophisticated contract validation
- **Automated Management**: Automated contract relationship management
- **Analytics Integration**: Contract relationship analytics
- **Enhanced Security**: Advanced security features for contract management

## Cross-chain Architecture

### Map Role
- Central registry for contract relationships
- Contract address management
- Cross-chain consistency maintenance
- Contract validation and verification

### Contract Management
- Contract attachment and linking
- Bidirectional mapping maintenance
- Type and version validation
- Contract relationship management

### Integration Management
- Multi-contract integration
- Cross-contract communication
- Contract discovery and validation
- Relationship management

## Gas Optimization

- **Efficient Storage**: Optimized storage layout for gas efficiency
- **Batch Operations**: Batch operations to reduce gas costs
- **Event Optimization**: Efficient event emission
- **Function Optimization**: Optimized function implementations
- **Mapping Optimization**: Efficient mapping operations

## Security Considerations

- **Access Control**: Multi-layer access control system
- **Input Validation**: Comprehensive input validation
- **Type Security**: Type and version validation
- **Address Security**: Zero address protection
- **Duplicate Prevention**: Duplicate attachment prevention
- **Contract Security**: Contract compatibility verification
- **Integration Security**: Secure contract integration