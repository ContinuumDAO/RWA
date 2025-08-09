# CTMRWA1Storage Contract Documentation

## Overview

**Contract Name:** CTMRWA1Storage  
**File:** `src/storage/CTMRWA1Storage.sol`  
**License:** BSL-1.1  
**Author:** @Selqui ContinuumDAO  
**Type:** Implementation Contract  

## Contract Description

CTMRWA1Storage is a decentralized storage management contract for Real-World Asset (RWA) tokens. It manages and stores on-chain information relating to RWA storage objects, supporting multiple storage types including BNB Greenfield and IPFS. The storage data is replicated across all chains where the RWA is deployed, ensuring consistent access to decentralized storage data from any chain.

### Key Features
- Decentralized storage management
- Multi-chain data replication
- BNB Greenfield integration
- IPFS support (planned)
- URI-based data organization
- Cross-chain synchronization
- Nonce-based object tracking

## State Variables

### Core Addresses
- `tokenAddr` (address): The linked CTMRWA1 contract address
- `storageManagerAddr` (address): The CTMRWAStorageManager contract address
- `storageUtilsAddr` (address): The CTMRWAStorageUtils contract address
- `tokenAdmin` (address): The token administrator (Issuer) address
- `ctmRwa1X` (address): The CTMRWA1X contract address
- `ctmRwa1Map` (address): The CTMRWAMap contract address
- `regulatorWallet` (address): The Security Regulator's wallet address

### Identifiers
- `ID` (uint256): Unique identifier matching the linked CTMRWA1
- `RWA_TYPE` (uint256, immutable): RWA type defining CTMRWA1
- `VERSION` (uint256, immutable): Version of this RWA type

### Storage Configuration
- `baseURI` (string): Storage type description ("GFLD", "IPFS", or "NONE")
- `idStr` (string): 16-character unique ID derived from the main ID
- `nonce` (uint256): Counter for stored objects (starts at 1)
- `TYPE` (string, constant): Prefix for BNB Greenfield bucket names ("ctm-rwa1-")

### Data Management
- `uriDataIndex` (mapping): objectName => uriData index
- `uriData` (URIData[]): Array of URIData structs storing object information

## Data Structures

### URIData
```solidity
struct URIData {
    URICategory uriCategory;  // Category of the URI data
    URIType uriType;          // Type of the URI data
    uint256 slot;             // Associated slot number
    string objectName;        // Object name in storage
    string uri;               // URI pointing to the data
    bytes32 uriDataHash;      // Hash of the URI data
    uint256 timestamp;        // Timestamp when data was stored
}
```

### URICategory (Enum)
- `Token`: Token-related data
- `Slot`: Slot-specific data
- `RWA`: RWA-specific data
- `Document`: Document storage
- `Image`: Image storage
- `Video`: Video storage
- `Audio`: Audio storage
- `Other`: Other types of data

### URIType (Enum)
- `Metadata`: Metadata information
- `Document`: Document files
- `Image`: Image files
- `Video`: Video files
- `Audio`: Audio files
- `Other`: Other file types

## Constructor

```solidity
constructor(
    uint256 _ID,
    address _tokenAddr,
    uint256 _rwaType,
    uint256 _version,
    address _storageManager,
    address _map
)
```

### Constructor Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `_ID` | `uint256` | Unique identifier matching the linked CTMRWA1 |
| `_tokenAddr` | `address` | The CTMRWA1 contract address |
| `_rwaType` | `uint256` | RWA type defining CTMRWA1 |
| `_version` | `uint256` | Version of this RWA type |
| `_storageManager` | `address` | The CTMRWAStorageManager contract address |
| `_map` | `address` | The CTMRWAMap contract address |

### Constructor Behavior

During construction, the contract:
1. Sets the ID, RWA_TYPE, and VERSION
2. Sets the tokenAddr and retrieves tokenAdmin and ctmRwa1X from the CTMRWA1 contract
3. Sets the storageManagerAddr and ctmRwa1Map addresses
4. Initializes the idStr from the ID
5. Sets the initial nonce to 1

## Administrative Functions

### setTokenAdmin()
```solidity
function setTokenAdmin(address _tokenAdmin) public onlyTokenAdmin returns (bool)
```
**Description:** Sets a new tokenAdmin address.  
**Parameters:**
- `_tokenAdmin` (address): New tokenAdmin address
**Access:** Only tokenAdmin or CTMRWA1X  
**Returns:** True if successful  
**Effects:** Updates tokenAdmin address  

### setBaseURI()
```solidity
function setBaseURI(string memory _baseURI) external onlyTokenAdmin
```
**Description:** Sets the base URI for storage type.  
**Parameters:**
- `_baseURI` (string): New base URI ("GFLD", "IPFS", or "NONE")
**Access:** Only tokenAdmin  
**Effects:** Updates baseURI  

### setRegulatorWallet()
```solidity
function setRegulatorWallet(address _regulatorWallet) external onlyTokenAdmin
```
**Description:** Sets the regulator wallet address.  
**Parameters:**
- `_regulatorWallet` (address): New regulator wallet address
**Access:** Only tokenAdmin  
**Effects:** Updates regulatorWallet address  

## Storage Management Functions

### addURI()
```solidity
function addURI(
    URICategory _uriCategory,
    URIType _uriType,
    uint256 _slot,
    string memory _objectName,
    string memory _uri,
    bytes32 _uriDataHash
) external onlyTokenAdmin
```
**Description:** Adds a new URI to the storage.  
**Parameters:**
- `_uriCategory` (URICategory): Category of the URI data
- `_uriType` (URIType): Type of the URI data
- `_slot` (uint256): Associated slot number
- `_objectName` (string): Object name in storage
- `_uri` (string): URI pointing to the data
- `_uriDataHash` (bytes32): Hash of the URI data
**Access:** Only tokenAdmin  
**Effects:** Adds new URIData and increments nonce  

### addURIFromManager()
```solidity
function addURIFromManager(
    URICategory _uriCategory,
    URIType _uriType,
    uint256 _slot,
    string memory _objectName,
    string memory _uri,
    bytes32 _uriDataHash
) external onlyStorageManager
```
**Description:** Adds a new URI from the storage manager.  
**Parameters:** Same as addURI  
**Access:** Only storageManager  
**Effects:** Adds new URIData and increments nonce  

### setNonce()
```solidity
function setNonce(uint256 _nonce) external onlyStorageManager
```
**Description:** Sets the nonce value for cross-chain synchronization.  
**Parameters:**
- `_nonce` (uint256): New nonce value
**Access:** Only storageManager  
**Effects:** Updates nonce value  

## Query Functions

### getURI()
```solidity
function getURI(string memory _objectName) external view returns (URIData memory)
```
**Description:** Returns URI data for a specific object name.  
**Parameters:**
- `_objectName` (string): Object name to query
**Returns:** URIData struct for the object  

### getURIByIndex()
```solidity
function getURIByIndex(uint256 _index) external view returns (URIData memory)
```
**Description:** Returns URI data by index.  
**Parameters:**
- `_index` (uint256): Index in the uriData array
**Returns:** URIData struct at the specified index  

### getURIBySlot()
```solidity
function getURIBySlot(uint256 _slot) external view returns (URIData[] memory)
```
**Description:** Returns all URI data for a specific slot.  
**Parameters:**
- `_slot` (uint256): Slot number to query
**Returns:** Array of URIData structs for the slot  

### getURIByCategory()
```solidity
function getURIByCategory(URICategory _uriCategory) external view returns (URIData[] memory)
```
**Description:** Returns all URI data for a specific category.  
**Parameters:**
- `_uriCategory` (URICategory): Category to query
**Returns:** Array of URIData structs for the category  

### getURIByType()
```solidity
function getURIByType(URIType _uriType) external view returns (URIData[] memory)
```
**Description:** Returns all URI data for a specific type.  
**Parameters:**
- `_uriType` (URIType): Type to query
**Returns:** Array of URIData structs for the type  

### getAllURI()
```solidity
function getAllURI() external view returns (URIData[] memory)
```
**Description:** Returns all URI data.  
**Returns:** Array of all URIData structs  

### getURICount()
```solidity
function getURICount() external view returns (uint256)
```
**Description:** Returns the total number of URI entries.  
**Returns:** Number of URI entries  

### getBucketName()
```solidity
function getBucketName() external view returns (string memory)
```
**Description:** Returns the BNB Greenfield bucket name.  
**Returns:** Bucket name string  

### getBaseURI()
```solidity
function getBaseURI() external view returns (string memory)
```
**Description:** Returns the base URI.  
**Returns:** Base URI string  

### getRegulatorWallet()
```solidity
function getRegulatorWallet() external view returns (address)
```
**Description:** Returns the regulator wallet address.  
**Returns:** Regulator wallet address  

## Access Control Modifiers

- `onlyTokenAdmin`: Restricts access to tokenAdmin or CTMRWA1X
- `onlyStorageManager`: Restricts access to storageManager

## Events

### NewURI
```solidity
event NewURI(URICategory uriCategory, URIType uriType, uint256 slot, bytes32 uriDataHash);
```
**Description:** Emitted when a new URI is added to storage.

## Security Features

- **Access Control**: Role-based permissions
- **Data Integrity**: Hash-based data verification
- **Cross-chain Sync**: Nonce-based synchronization
- **Regulator Oversight**: Regulator wallet integration
- **Immutable Configuration**: RWA type and version are immutable

## Integration Points

- **CTMRWA1**: Linked token contract
- **CTMRWA1StorageManager**: Centralized storage management
- **CTMRWA1X**: Cross-chain operations
- **CTMRWAMap**: Component address mapping
- **BNB Greenfield**: Decentralized storage
- **IPFS**: Distributed file system (planned)

## Storage Types

### BNB Greenfield ("GFLD")
- Uses bucket-based storage
- Bucket name format: `ctm-rwa1-{idStr}`
- Object names are string representations of nonce
- Fully decentralized storage solution

### IPFS ("IPFS")
- Inter-Planetary File System storage
- Not yet implemented
- Planned for future releases

### None ("NONE")
- No external storage configured
- Issuer chose not to store data for the RWA

## Storage Flow

1. **TokenAdmin** configures storage type (GFLD, IPFS, or NONE)
2. **TokenAdmin** adds URI data with appropriate category and type
3. **Contract** stores URIData struct with metadata
4. **Cross-chain sync** ensures data consistency across chains
5. **Users** can query storage data from any chain

## Key Features

- **Multi-chain Replication**: Same data available on all chains
- **Categorized Storage**: Organized by category and type
- **Hash Verification**: Data integrity through hashing
- **Flexible URIs**: Support for various storage backends
- **Slot Association**: Data can be linked to specific token slots
- **Timestamp Tracking**: When data was stored
- **Cross-chain Sync**: Nonce ensures consistency across chains
