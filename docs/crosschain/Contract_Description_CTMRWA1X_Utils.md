# CTMRWA1X_Utils Contract Documentation

## Overview

**Contract Name:** CTMRWA1XUtils  
**File:** `src/crosschain/CTMRWA1XUtils.sol`  
**License:** BSL-1.1  
**Author:** @Selqui ContinuumDAO

## Contract Description

CTMRWA1XUtils is a helper contract for CTMRWA1X. It provides additional functionality to CTMRWA1X, including admin and ownership tracking utilities, ERC20-assisted minting helpers, local mint orchestration with fee handling, and fallback handling for failed cross-chain mint operations. It is deployed once per chain and is authorized to be called by CTMRWA1X.

### Key Features
- Tracks CTMRWA1 addresses by tokenAdmin and by owner per version
- Utility entrypoints for ERC20 flow: mint new tokenIds for slot ERC20 contracts
- Local minting with fee calculation and payment via FeeManager
- Cross-chain fallback handler for failed mintX flows (re-mint on source)
- Minimal trusted surface: restricted to CTMRWA1X via onlyRwa1X

## State Variables

- `RWA_TYPE (uint256, immutable = 1)`: RWA type defining CTMRWA1
- `rwa1X (address)`: Address of the CTMRWA1X contract
- `ctmRwaMap (address)`: Address of the CTMRWAMap contract
- `feeManager (address)`: Address of the FeeManager contract
- `lastSelector (bytes4)`: Last selector processed in fallback
- `lastData (bytes)`: Last calldata processed in fallback
- `lastReason (bytes)`: Last revert reason recorded in fallback
- `cIdStr (string)`: String representation of chain ID
- `adminTokens (mapping(address => mapping(uint256 => address[])))`: tokenAdmin => version => CTMRWA1 list
- `ownedCtmRwa1 (mapping(address => mapping(uint256 => address[])))`: owner => version => CTMRWA1 list
- `MintX (bytes4)`: keccak selector for `mintX(uint256,uint256,string,string,uint256,uint256)`

## Constructor

```solidity
constructor(address _rwa1X)
```
- Sets `rwa1X`, derives `ctmRwaMap`, `feeManager`, and `cIdStr` from CTMRWA1X.

## Access Control

- `onlyRwa1X`: Restricts calls to the CTMRWA1X contract or to self (delegatecall flows)

## Governance/Config Functions (via CTMRWA1X authority)

### setRwa1X()
```solidity
function setRwa1X(address _rwa1X) external onlyRwa1X
```
Sets the CTMRWA1X address. Rejects zero address.

### setCtmRwaMap()
```solidity
function setCtmRwaMap(address _ctmRwaMap) external onlyRwa1X
```
Sets the CTMRWAMap address. Rejects zero address.

### setFeeManager()
```solidity
function setFeeManager(address _feeManager) external onlyRwa1X
```
Sets the FeeManager address. Rejects zero address.

## Admin and Ownership Tracking

### addAdminToken()
```solidity
function addAdminToken(address _admin, address _tokenAddr, uint256 _version) external onlyRwa1X
```
Adds a CTMRWA1 to `_admin`'s managed token list.

### updateOwnedCtmRwa1()
```solidity
function updateOwnedCtmRwa1(address _ownerAddr, address _tokenAddr, uint256 _version) external onlyRwa1X returns (bool)
```
Ensures `_tokenAddr` appears in the `_ownerAddr` list for `_version`. Returns true if already present, false if newly added.

### getAllTokensByAdminAddress()
```solidity
function getAllTokensByAdminAddress(address _admin, uint256 _version) public view returns (address[] memory)
```
Returns CTMRWA1 addresses administered by `_admin` for `_version`.

### getAllTokensByOwnerAddress()
```solidity
function getAllTokensByOwnerAddress(address _owner, uint256 _version) public view returns (address[] memory)
```
Returns CTMRWA1 addresses where `_owner` owns one or more tokenIds for `_version`.

### isOwnedToken()
```solidity
function isOwnedToken(address _owner, address _ctmRwa1Addr) public view returns (bool)
```
True if `_owner` has any tokenIds in `_ctmRwa1Addr`.

### swapAdminAddress()
```solidity
function swapAdminAddress(address _oldAdmin, address _newAdmin, address _ctmRwa1Addr, uint256 _version) external onlyRwa1X
```
Removes `_ctmRwa1Addr` from `_oldAdmin` list and appends to `_newAdmin` list for `_version`.

## ERC20-Assisted Minting

### mintFromXForERC20()
```solidity
function mintFromXForERC20(
    uint256 _ID,
    uint256 _version,
    address _to,
    uint256 _slot,
    string memory _slotName
) external returns (uint256)
```
- Validates caller is the authorized ERC20 for `_slot` on the CTMRWA1 of `_ID`/`_version`.
- Mints a new tokenId via CTMRWA1 and tracks ownership via `updateOwnedCtmRwa1`.
- Returns the new tokenId.

## Local Minting Orchestration

### mintNewTokenValueLocal()
```solidity
function mintNewTokenValueLocal(
    address _toAddress,
    uint256 _toTokenId,
    uint256 _slot,
    uint256 _value,
    uint256 _ID,
    uint256 _version,
    string memory _feeTokenStr
) public nonReentrant returns (uint256)
```
- Gets token by `_ID`/`_version` from map and verifies caller is current tokenAdmin.
- Pays fee via `FeeManager`.
- If `_toTokenId` > 0: requires `_slot == 0`, mints value to an existing tokenId.
- Else: requires slot exists; mints new tokenId in `_slot`, updates ownership tracking.
- Returns the target/new tokenId.

## Fallback Handling

### getLastReason()
```solidity
function getLastReason() public view returns (string memory)
```
Returns last revert reason captured in fallback.

### rwa1XC3Fallback()
```solidity
function rwa1XC3Fallback(bytes4 _selector, bytes calldata _data, bytes calldata _reason, address _map)
    external
    onlyRwa1X
    returns (bool)
```
- Records `_selector`, `_data`, `_reason`.  
- If `_selector` equals `MintX`, decodes data `(ID, version, from, to, slot, value)`, looks up CTMRWA1 via map, and attempts to re-mint on source chain to compensate burns; emits `ReturnValueFallback` on success.  
- Emits `LogFallback` and returns true.

## Internal Utilities

### _payFee()
```solidity
function _payFee(FeeType _feeType, string memory _feeTokenStr, string[] memory _toChainIdsStr, bool _includeLocal) internal
```
Calculates and pays fees via `FeeManager`, verifying spender balance change.

### _checkTokenAdmin()
```solidity
function _checkTokenAdmin(address _tokenAddr) internal returns (address, string memory)
```
Returns current tokenAdmin and its lowercase hex string; enforces caller equals tokenAdmin.

## Events

- `LogFallback(bytes4 selector, bytes data, bytes reason)`
- `ReturnValueFallback(address to, uint256 slot, uint256 value)`

## Security Features

- ReentrancyGuard for state-changing flows
- Strict `onlyRwa1X` gate for all mutating operations
- Fee transfer assertions with SafeERC20
- Fallback re-mint guarded by slot existence

## Integration Points

- `CTMRWA1X`: Authority and context provider
- `CTMRWAMap`: Resolves CTMRWA1 by ID/version
- `CTMRWA1`: Token contract for minting and queries
- `IFeeManager`: Fee calculation and payment
- Slot ERC20 contracts: Authorized callers for `mintFromXForERC20`