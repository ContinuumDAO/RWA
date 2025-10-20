# CTMRWA1Storage Contract Documentation

## Overview

**Contract Name:** CTMRWA1Storage  
**Author:** @Selqui ContinuumDAO  
**License:** BSL-1.1  
**Solidity Version:** 0.8.27

The CTMRWA1Storage contract manages and stores on-chain information relating to RWA storage objects. The storage data is specific to this chain but is reproduced in CTMRWA1Storage contracts on every chain where the RWA is deployed. This enables users on any chain in the RWA ecosystem to access the same decentralized storage data on BNB Greenfield or IPFS.

This contract is deployed by CTMRWADeployer once for every CTMRWA1 contract on each chain. Its ID matches the ID in CTMRWA1, and cross-chain functionality is managed by CTMRWA1StorageManager.

## Key Features

- **Decentralized Storage Integration:** Supports BNB Greenfield and IPFS storage systems
- **Cross-chain Data Synchronization:** Maintains consistent storage data across all chains
- **URI Management:** Manages storage object URIs with categories and types
- **Hash Verification:** Validates stored data integrity through checksums
- **Nonce Management:** Tracks storage object sequence across chains
- **Security Integration:** Supports regulatory compliance and security features
- **Bucket Management:** Manages BNB Greenfield bucket names and organization
- **Data Retrieval:** Comprehensive query functions for storage data

## Public Variables

### Contract Identification
- **`ID`** (uint256): ID for this contract, same as in the linked CTMRWA1
- **`RWA_TYPE`** (uint256, immutable): RWA type defining CTMRWA1
- **`VERSION`** (uint256, immutable): Version of this RWA type

### Contract Addresses
- **`tokenAddr`** (address): CTMRWA1 contract address linked to this contract
- **`storageManagerAddr`** (address): Address of the CTMRWAStorageManager contract
- **`storageUtilsAddr`** (address): Address of the CTMRWAStorageUtils contract
- **`tokenAdmin`** (address): TokenAdmin (Issuer) address, same as in CTMRWA1
- **`ctmRwa1X`** (address): Address of the CTMRWA1X contract
- **`ctmRwa1Map`** (address): Address of the CTMRWAMap contract
- **`regulatorWallet`** (address): Address of the Security Regulator's wallet

### Storage Configuration
- **`baseURI`** (string): String describing storage type ("GFLD", "IPFS", or "NONE")
- **`idStr`** (string): Shortened 16-character unique ID derived from ID
- **`nonce`** (uint256): Counter for stored objects, starts at 1
- **`TYPE`** (string, constant): Prefix for BNB Greenfield bucket names ("ctm-rwa1-")

### Data Storage
- **`uriDataIndex`** (mapping): Maps objectName to uriData index
- **`uriData`** (URIData[]): Array of URIData structs storing storage information

## Core Functions

### Function Arguments Reference (complete)

#### constructor(uint256 _ID, address _tokenAddr, uint256 _rwaType, uint256 _version, address _storageManagerAddr, address _map)
- _ID (uint256): Unique RWA ID for this storage instance; must match linked CTMRWA1 ID.
- _tokenAddr (address): Deployed CTMRWA1 token address bound to this storage.
- _rwaType (uint256): RWA type (1 for CTMRWA1).
- _version (uint256): Single integer version of this RWA type.
- _storageManagerAddr (address): CTMRWA1StorageManager address on this chain.
- _map (address): CTMRWAMap address for contract lookups.

#### setTokenAdmin(address _tokenAdmin)
- _tokenAdmin (address): New tokenAdmin (Issuer) address.

#### createSecurity(address _regulatorWallet)
- _regulatorWallet (address): Security Regulator’s wallet address to register.

#### addURILocal(uint256 _ID, uint256 _version, string memory _objectName, URICategory _uriCategory, URIType _uriType, string memory _title, uint256 _slot, uint256 _timestamp, bytes32 _uriDataHash)
- _ID (uint256): RWA ID; must equal this contract’s ID.
- _version (uint256): RWA version; used to validate the linked CTMRWA1 via CTMRWAMap.
- _objectName (string): Storage object name (e.g., Greenfield object name).
- _uriCategory (URICategory): Category enum describing the record (e.g., ISSUER, LICENSE, …).
- _uriType (URIType): CONTRACT (whole token) or SLOT (specific asset class).
- _title (string): Human-readable title/description shown in Explorer.
- _slot (uint256): Asset Class index; must exist if _uriType == SLOT; 0 for CONTRACT.
- _timestamp (uint256): Unix timestamp when the record is created.
- _uriDataHash (bytes32): Hash of checksum of the stored object; must be globally unique here.

#### popURILocal(uint256 _toPop)
- _toPop (uint256): Number of most recent records to remove (fallback recovery); must be <= current record count.

#### setNonce(uint256 _val)
- _val (uint256): New nonce value to set (used to rewind during fallback recovery).

#### increaseNonce(uint256 _val)
- _val (uint256): New nonce value; must be strictly greater than current nonce.

#### greenfieldBucket()
- (no arguments)

#### getAllURIData()
- (no arguments)

#### getURIHashByIndex(URICategory _uriCat, URIType _uriTyp, uint256 _index)
- _uriCat (URICategory): Category to query.
- _uriTyp (URIType): Type to query (CONTRACT or SLOT).
- _index (uint256): 0-based position within the category/type list.

#### getURIHashCount(URICategory _uriCat, URIType _uriTyp)
- _uriCat (URICategory): Category to count.
- _uriTyp (URIType): Type to count.

#### getURIHash(bytes32 _hash)
- _hash (bytes32): Hash of checksum to look up.

#### existURIHash(bytes32 _uriHash)
- _uriHash (bytes32): Hash of checksum to test existence.

#### existObjectName(string memory _objectName)
- _objectName (string): Object name to test existence (on-chain index only).

#### getURIByObjectName(string memory _objectName)
- _objectName (string): Object name to look up and return full record.

### Initialization

#### `constructor(uint256 _ID, address _tokenAddr, uint256 _rwaType, uint256 _version, address _storageManagerAddr, address _map)`
- **Access:** Public constructor
- **Purpose:** Initializes the CTMRWA1Storage contract instance
- **Parameters:**
  - `_ID`: ID for this contract
  - `_tokenAddr`: CTMRWA1 contract address
  - `_rwaType`: RWA type defining CTMRWA1
  - `_version`: Version of this RWA type
  - `_storageManagerAddr`: Storage manager contract address
  - `_map`: CTMRWAMap contract address
- **Initialization:**
  - Sets contract ID and generates shortened ID string
  - Sets immutable RWA_TYPE and VERSION
  - Links to CTMRWA1 contract and retrieves tokenAdmin and ctmRwa1X
  - Sets storage manager and utils addresses
  - Retrieves baseURI from CTMRWA1 contract

### Administrative Functions

#### `setTokenAdmin(address _tokenAdmin)`
- **Access:** Only callable by tokenAdmin or ctmRwa1X
- **Purpose:** Change the tokenAdmin address
- **Parameters:** `_tokenAdmin` - New tokenAdmin address
- **Returns:** True if successful
- **Security:** Only existing tokenAdmin or ctmRwa1X can update

#### `createSecurity(address _regulatorWallet)`
- **Access:** Only callable by tokenAdmin
- **Purpose:** Register the Security Regulator wallet
- **Requirement:** Must have at least one LICENSE record of type CONTRACT, otherwise reverts with `CTMRWA1Storage_NoSecurityDescription`

### Storage Write Functions (Manager-only)

#### `addURILocal(uint256 _ID, uint256 _version, string memory _objectName, URICategory _uriCategory, URIType _uriType, string memory _title, uint256 _slot, uint256 _timestamp, bytes32 _uriDataHash)`
- **Access:** Only callable by storage manager/utils
- **Purpose:** Add a new storage record locally
- **Validations:**
  - `_ID` must match `ID` -> `CTMRWA1Storage_InvalidID`
  - `existURIHash(_uriDataHash)` must be false -> `CTMRWA1Storage_HashExists`
  - If `_uriType == SLOT`, map must confirm compatible token/version and `slotExists(_slot)` must be true -> `CTMRWA1Storage_InvalidSlot`
  - First record must be `(ISSUER, CONTRACT)` -> `CTMRWA1Storage_IssuerNotFirst`
- **Effects:** Appends record, updates indices/counters, increments `nonce`, emits `NewURI`

#### `popURILocal(uint256 _toPop)`
- **Access:** Only callable by storage manager/utils
- **Purpose:** Remove last `_toPop` records (used by cross-chain fallback)
- **Validation:** `_toPop` <= current length, else `CTMRWA1Storage_OutOfBounds`
- **Cleanup:** Updates hash/counters/category-type indices for removed items

#### `setNonce(uint256 _val)`
- **Access:** Only callable by storage manager/utils
- **Purpose:** Rewind nonce during fallback handling

### TokenAdmin Nonce Adjustment

#### `increaseNonce(uint256 _val)`
- **Access:** Only callable by tokenAdmin
- **Purpose:** Temporarily allow increasing nonce manually
- **Validation:** `_val` must be strictly greater than current `nonce`, else `CTMRWA1Storage_IncreasingNonceOnly`

#### `createSecurity(address _regulatorWallet)`
- **Access:** Only callable by tokenAdmin
- **Purpose:** Add Security Regulator wallet address
- **Parameters:** `_regulatorWallet` - Regulator's wallet address
- **Validation:** Requires LICENSE storage object to exist first
- **Note:** Required before enabling forceTransfer functionality

### Storage Management

#### `addURILocal(uint256 _ID, uint256 _version, string memory _objectName, URICategory _uriCategory, URIType _uriType, string memory _title, uint256 _slot, uint256 _timestamp, bytes32 _uriDataHash)`
- **Access:** Only callable by storage manager or utils
- **Purpose:** Add storage object information to contract state
- **Parameters:**
  - `_ID`: RWA token ID
  - `_objectName`: Object name on decentralized storage
  - `_uriCategory`: Category of stored data
  - `_uriType`: Type of stored data (CONTRACT or SLOT)
  - `_title`: Description for AssetX Explorer
  - `_slot`: Asset Class index (not used for CONTRACT type)
  - `_timestamp`: Linux timestamp of record creation
  - `_uriDataHash`: Bytes32 hash of stored data checksum
- **Validation:**
  - Ensures ID matches contract ID
  - Prevents duplicate hash entries
  - Validates slot exists for SLOT type
  - Requires ISSUER CONTRACT record first (except for ISSUER CONTRACT)
- **Logic:**
  - Adds URIData to uriData array
  - Updates uriDataIndex mapping
  - Increments nonce
- **Events:** Emits NewURI event

#### `popURILocal(uint256 _toPop)`
- **Access:** Only callable by storage manager or utils
- **Purpose:** Remove URI records after cross-chain failure
- **Parameters:** `_toPop` - Number of records to remove
- **Validation:** Ensures _toPop doesn't exceed array length
- **Logic:** Removes specified number of records from uriData array

### Nonce Management

#### `increaseNonce(uint256 _val)`
- **Access:** Only callable by tokenAdmin
- **Purpose:** Manually fix nonce after cross-chain failure
- **Parameters:** `_val` - New nonce value
- **Validation:** Ensures new value is greater than current nonce
- **Note:** Will be removed in later versions

#### `setNonce(uint256 _val)`
- **Access:** Only callable by storage manager or utils
- **Purpose:** Set nonce value (used by c3Fallback)
- **Parameters:** `_val` - New nonce value
- **Logic:** Directly sets nonce to specified value

### Query Functions

#### `greenfieldBucket()`
- **Access:** Public view function
- **Purpose:** Get BNB Greenfield bucket name
- **Returns:** Bucket name string if using Greenfield, empty string otherwise
- **Logic:** Concatenates TYPE constant with idStr if baseURI is "GFLD"

#### `getAllURIData()`
- **Access:** Public view function
- **Purpose:** Return all on-chain storage data for this RWA
- **Returns:** Seven arrays containing:
  - `uriCategory`: URICategory enum values
  - `uriType`: URIType enum values
  - `title`: Description strings
  - `slot`: Asset Class indices
  - `objectName`: Object names on decentralized storage
  - `uriHash`: Checksum hashes
  - `timestamp`: Creation timestamps
- **Note:** Cannot return actual decentralized storage data, only pointers

#### `getURIHashByIndex(URICategory _uriCat, URIType _uriTyp, uint256 _index)`
- **Access:** Public view function
- **Purpose:** Get URI hash by index for specific category and type
- **Parameters:**
  - `_uriCat`: URICategory to search
  - `_uriTyp`: URIType to search
  - `_index`: Index of desired record
- **Returns:** Tuple of (bytes32 hash, string objectName)
- **Logic:** Iterates through uriData to find matching records

#### `getURIHashCount(URICategory _uriCat, URIType _uriTyp)`
- **Access:** External view function
- **Purpose:** Get count of records for specific category and type combination
- **Parameters:**
  - `_uriCat`: URICategory to count
  - `_uriTyp`: URIType to count
- **Returns:** Number of matching records
- **Logic:** Counts records matching both category and type

#### `getURIHash(bytes32 _hash)`
- **Access:** Public view function
- **Purpose:** Get full URIData struct by hash
- **Parameters:** `_hash` - Bytes32 hash to search for
- **Returns:** URIData struct (empty if not found)
- **Logic:** Searches uriData array for matching hash

#### `existURIHash(bytes32 _uriHash)`
- **Access:** Public view function
- **Purpose:** Check if hash exists in storage
- **Parameters:** `_uriHash` - Hash to check
- **Returns:** True if hash exists, false otherwise
- **Logic:** Searches uriData array for matching hash

#### `existObjectName(string memory _objectName)`
- **Access:** Public view function
- **Purpose:** Check if object name exists on-chain
- **Parameters:** `_objectName` - Object name to check
- **Returns:** True if object name exists, false otherwise
- **Logic:** Checks uriDataIndex mapping
- **Note:** Only checks on-chain existence, not decentralized storage

#### `getURIByObjectName(string memory _objectName)`
- **Access:** Public view function
- **Purpose:** Get full URIData struct by object name
- **Parameters:** `_objectName` - Object name to search for
- **Returns:** URIData struct (empty if not found)
- **Logic:** Uses uriDataIndex to find corresponding record

## Internal Functions

### Utility Functions
- **`cID()`**: Returns current chain ID
  - Used for chain identification
  - Returns block.chainid

## Access Control Modifiers

- **`onlyTokenAdmin`**: Restricts access to only tokenAdmin or ctmRwa1X
  - Ensures only authorized parties can perform administrative functions
  - Maintains security and control over storage operations

- **`onlyStorageManager`**: Restricts access to only storage manager or utils
  - Ensures only authorized storage management contracts can modify data
  - Maintains data integrity and cross-chain synchronization

## Events

- **`NewURI(URICategory uriCategory, URIType uriType, uint256 slot, bytes32 uriDataHash)`**: Emitted when new storage object is added
  - Records category, type, slot, and hash of new URI
  - Enables tracking of storage additions
  - Supports monitoring and analytics

## Security Features

1. **Access Control:** Multiple levels of access control for different operations
2. **Hash Verification:** Validates stored data integrity through checksums
3. **Cross-chain Synchronization:** Maintains consistent data across chains
4. **Nonce Management:** Prevents out-of-order operations
5. **Regulatory Compliance:** Supports security regulator integration
6. **Data Validation:** Validates slot existence and hash uniqueness
7. **Immutable Configuration:** RWA_TYPE and VERSION are immutable

## Integration Points

- **CTMRWA1**: Core RWA token contract
- **CTMRWA1StorageManager**: Cross-chain storage management
- **CTMRWA1StorageUtils**: Storage deployment and error recovery
- **CTMRWAMap**: Contract address registry
- **CTMRWA1X**: Cross-chain coordinator
- **BNB Greenfield**: Decentralized storage system
- **IPFS**: Inter-Planetary File System (future implementation)
 - **ForceTransfer Prerequisite**: `createSecurity(_regulatorWallet)` must be called (and a LICENSE/CONTRACT record must exist) before any wallet can be authorized for forceTransfer functionality

## Error Handling

The contract uses custom error types for efficient gas usage:

- **`CTMRWA1Storage_OnlyAuthorized(CTMRWAErrorParam.Sender, CTMRWAErrorParam.TokenAdmin)`**: Thrown when unauthorized address tries to perform admin functions
- **`CTMRWA1Storage_OnlyAuthorized(CTMRWAErrorParam.Sender, CTMRWAErrorParam.StorageManager)`**: Thrown when unauthorized address tries to modify storage
- **`CTMRWA1Storage_InvalidID(uint256 expected, uint256 provided)`**: Thrown when ID doesn't match
- **`CTMRWA1Storage_HashExists(bytes32 hash)`**: Thrown when hash already exists
- **`CTMRWA1Storage_InvalidContract(CTMRWAErrorParam.Token)`**: Thrown when token contract not found
- **`CTMRWA1Storage_InvalidSlot(uint256 slot)`**: Thrown when slot doesn't exist
- **`CTMRWA1Storage_IssuerNotFirst()`**: Thrown when ISSUER CONTRACT record doesn't exist first
- **`CTMRWA1Storage_OutOfBounds()`**: Thrown when trying to pop more records than exist
- **`CTMRWA1Storage_IncreasingNonceOnly()`**: Thrown when trying to decrease nonce
- **`CTMRWA1Storage_NoSecurityDescription()`**: Thrown when no LICENSE record exists

## Storage Data Structure

### URIData Struct
```solidity
struct URIData {
    URICategory uriCategory;  // Category of stored data
    URIType uriType;          // Type (CONTRACT or SLOT)
    string title;             // Description for Explorer
    uint256 slot;             // Asset Class index
    string objectName;        // Object name on decentralized storage
    bytes32 uriHash;          // Checksum hash of stored data
    uint256 timeStamp;        // Creation timestamp
}
```

### URICategory Enum
- **EMPTY**: Empty category
- **ISSUER**: Issuer-related data
- **LICENSE**: License and regulatory data
- **FINANCIAL**: Financial reports and data
- **LEGAL**: Legal documents
- **TECHNICAL**: Technical specifications
- **MARKETING**: Marketing materials
- **OTHER**: Other categories

### URIType Enum
- **EMPTY**: Empty type
- **CONTRACT**: Data relating to entire RWA
- **SLOT**: Data relating to specific Asset Class

## Use Cases

### Decentralized Storage Management
- **Scenario:** Store RWA documentation on BNB Greenfield
- **Process:** Use addURILocal to record storage information
- **Benefit:** Immutable, decentralized storage with on-chain verification

### Cross-chain Data Access
- **Scenario:** Access storage data from any chain
- **Process:** Use query functions to retrieve storage information
- **Benefit:** Consistent data access across all chains

### Regulatory Compliance
- **Scenario:** Store regulatory documents and licenses
- **Process:** Use LICENSE category for regulatory data
- **Benefit:** Transparent regulatory compliance

### Asset Class Documentation
- **Scenario:** Store documentation for specific asset classes
- **Process:** Use SLOT type with specific slot numbers
- **Benefit:** Organized documentation by asset class

## Best Practices

1. **Hash Verification:** Always verify stored data against on-chain hashes
2. **Category Organization:** Use appropriate URICategory for data organization
3. **Cross-chain Coordination:** Ensure data is added to all chains
4. **Nonce Management:** Monitor nonce consistency across chains
5. **Security Setup:** Complete security setup before enabling advanced features

## Limitations

- **Single Instance:** One storage contract per RWA per chain
- **Cross-chain Dependency:** Requires coordination across all chains
- **Storage Type Limitation:** Currently supports GFLD, IPFS planned
- **Nonce Synchronization:** Nonce must be same on all chains for new additions
- **External Storage Dependency:** Relies on external decentralized storage systems

## Future Enhancements

Potential improvements to the storage system:

1. **IPFS Integration:** Full IPFS storage support
2. **Enhanced Categories:** Additional URICategory types
3. **Batch Operations:** Support for batch URI additions
4. **Advanced Verification:** Enhanced data integrity verification
5. **Storage Analytics:** Comprehensive storage analytics and reporting

## Cross-chain Architecture

### Data Synchronization
- **Local Storage:** Each chain maintains complete storage data
- **Cross-chain Updates:** Updates propagated to all chains
- **Consistency Validation:** Nonce ensures consistency across chains
- **Failure Recovery:** Fallback mechanisms for failed operations

### Storage Management
- **Centralized Control:** StorageManager coordinates cross-chain operations
- **Local Execution:** Each chain executes storage operations locally
- **Synchronized State:** State synchronized across all chains
- **Error Handling:** Comprehensive error handling and recovery

## Gas Optimization

### Storage Costs
- **URI Addition:** ~50000-100000 gas per URI addition
- **Query Operations:** ~5000-20000 gas for data queries
- **Nonce Management:** ~20000-50000 gas for nonce operations
- **Total Estimate:** ~75000-170000 gas per storage operation

### Optimization Strategies
- **Batch Operations:** Consider batch URI additions
- **Efficient Queries:** Use indexed queries when possible
- **Gas Estimation:** Always estimate gas before operations
- **Storage Planning:** Plan storage operations efficiently

## Security Considerations

### Access Control
- **TokenAdmin Authorization:** Only tokenAdmin can perform administrative functions
- **Storage Manager Control:** Only storage manager can modify storage data
- **Cross-chain Security:** Secure cross-chain communication and synchronization
- **Data Validation:** Validate all storage data and parameters

### Data Integrity
- **Hash Verification:** Verify stored data against on-chain hashes
- **Nonce Management:** Maintain nonce consistency across chains
- **Duplicate Prevention:** Prevent duplicate hash entries
- **Slot Validation:** Validate slot existence for SLOT type data

### Regulatory Compliance
- **Security Setup:** Complete security setup before advanced features
- **Regulator Integration:** Integrate with security regulator requirements
- **Documentation Storage:** Store regulatory documents securely
- **Compliance Tracking:** Track regulatory compliance requirements
