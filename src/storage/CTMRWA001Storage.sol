// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";


import {ICTMRWA001, ITokenContract} from "./interfaces/ICTMRWA001.sol";
import {ICTMRWAMap} from "./interfaces/ICTMRWAMap.sol";
import {ICTMRWA001StorageManager} from "./interfaces/ICTMRWA001StorageManager.sol";
import {URIData, URIType, URICategory} from "./interfaces/ICTMRWA001Storage.sol";

/**
 * @title AssetX Multi-chain Semi-Fungible-Token for Real-World-Assets (RWAs)
 * @author @Selqui ContinuumDAO
 *
 * @notice This contract manages and stores the on-chain information relating to RWA storage objects.
 * The storage data is for this chain only, but it is reproduced in the CTMRWA001Storage contracts on
 * every chain that the RWA is deployed to. This means that a user on any chain in the RWA can access
 * the same decentralized storage data on BNB Greenfield, or IPFS.
 *
 * This contract is deployed by CTMRWADeployer on each chain once for every CTMRWA001 contract.
 * Its ID matches the ID in CTMRWA001.
 * The cross-chain functionality is managed by CTMRWA001StorageManager
 */

contract CTMRWA001Storage is Context {
    using Strings for *;

    /// @dev The CTMRWA001 contract address linked to this contract
    address public tokenAddr;

    /// @dev The ID for this contract. Same as in the linked CTMRWA001
    uint256 public ID;

    /// @dev rwaType is the RWA type defining CTMRWA001
    uint256 rwaType;

    /// @dev version is the single integer version of this RWA type
    uint256 version;

    /// @dev The address of the CTMRWAStorageManager contract
    address public storageManagerAddr;

    /// @dev The address of the CTMRWAStorageUtils contract (extending this contract)
    address public storageUtilsAddr;

    /// @dev The tokenAdmin (Issuer) address. Same as in CTMRWA001
    address public tokenAdmin;

    /// @dev The address of the CTMRWA001X contract
    address public ctmRwa001X;

    /// @dev The address of the CTMRWAMap contract
    address public ctmRwa001Map;

    /// @dev The address of the Security Regulator's wallet
    address public regulatorWallet;

    /**
     * @dev String describing the type of storage used for this RWA
     * It can be "GFLD" for BNB Greenfield decentralized storage, or 
     * "IPFS" for Inter-Planetary-File-System storage (not implemented yet), or
     * it can be "NONE" if the Issuer did not want to store any data for the RWA
     */
    string baseURI;

    /**
     * @dev This string stores the shortened 16 character unique id, derived from the ID. 
     * It is used for the BNB Greenfield Bucket Name (if used)
     */
    string idStr;

    /**
     * @dev The nonce is the counter for stored objects relating to the RWA.
     * For BNB Greenfield, the Object Name is simply the string version of nonce.
     * NOTE The nonce is auto-incremented every time a new object is added to the RWA.
     * NOTE The nonce is updated on all chains in the RWA to be the same.
     * No new object can be added, unless the nonce values are the same on all chains.
     */
    uint256 public nonce = 1;

    /// @dev This string is pre-pended to idStr to create the Bucket Name for BNB Greenfield storage
    string constant TYPE = "ctm-rwa001-";

    /// @dev objectName => uriData index. 
    mapping(string => uint256) public uriDataIndex;

    /**
     *  @dev The uriData is the array of structs storing various data related to the stored object.
     * The URIData struct is described in ICTMRWA001Storage
     */
    URIData[] public uriData;

    /// @dev A new object has been added to the stored data in this contract
    event NewURI(URICategory uriCategory, URIType uriType, uint256 slot, bytes32 uriDataHash);

    modifier onlyTokenAdmin() {
        require(
            _msgSender() == tokenAdmin || _msgSender() == ctmRwa001X, 
            "CTMRWA001Storage: onlyTokenAdmin function"
        );
        _;
    }

    modifier onlyStorageManager() {
        require(
            _msgSender() == storageManagerAddr ||_msgSender() ==  storageUtilsAddr,
            "CTMRWA001Storage: onlyStorageManager function"
        );
        _;
    }

   
    constructor(
        uint256 _ID,
        address _tokenAddr,
        uint256 _rwaType,
        uint256 _version,
        address _storageManagerAddr,
        address _map
    ) {
        ID = _ID;
        idStr = _toLower(((ID<<192)>>192).toHexString());  // shortens string to 16 characters
        rwaType = _rwaType;
        version = _version;
        ctmRwa001Map = _map;

        tokenAddr = _tokenAddr;

        tokenAdmin = ICTMRWA001(tokenAddr).tokenAdmin();
        ctmRwa001X = ICTMRWA001(tokenAddr).ctmRwa001X();
        
        storageManagerAddr = _storageManagerAddr;
        storageUtilsAddr = ICTMRWA001StorageManager(storageManagerAddr).utilsAddr();

        baseURI = ICTMRWA001(tokenAddr).baseURI();
    }

    /**
     * @notice Change the tokenAdmin address
     * NOTE This function can only be called by CTMRWA001X, or the existing tokenAdmin
     */
    function setTokenAdmin(address _tokenAdmin) external onlyTokenAdmin returns(bool) {
        tokenAdmin = _tokenAdmin;
        return(true);
    }

    /**
     * @notice This returns the unique name of the Greenfield of this RWA, if
     * BNB Greenfield is used for storage. 
     */
    function greenfieldBucket() public view returns (string memory) {
        return
            stringsEqual(baseURI, "GFLD")
                ? string.concat(TYPE, idStr)
                : "";
    }

    /**
     * @dev This function is only called from CTMRWA001StorageManager. It puts the object storage
     * information into state in this contract. This information is duplicated on every chain in the RWA
     * NOTE See CTMRWA001StorageManager for more details
     */
    function addURILocal(
        uint256 _ID,
        string memory _objectName,
        URICategory _uriCategory,
        URIType _uriType,
        string memory _title,
        uint256 _slot,
        uint256 _timestamp,
        bytes32 _uriDataHash
    ) external onlyStorageManager {
        require(_ID == ID, "CTMRWA001Storage: Attempt to add URI to an incorrect ID");

        require(!existURIHash(_uriDataHash), "CTMRWA001Storage: Hash already exists");

        if(_uriType == URIType.SLOT) {
            (bool ok,) = ICTMRWAMap(ctmRwa001Map).getTokenContract(_ID, rwaType, version);
            require(ok && ICTMRWA001(tokenAddr).slotExists(_slot), "CTMRWA001Storage: Slot does not exist");
        }

        if(_uriType != URIType.CONTRACT || _uriCategory != URICategory.ISSUER) {
            require(this.getURIHashCount(URICategory.ISSUER, URIType.CONTRACT) > 0, 
            "CTMRWA001Storage: Type CONTRACT and CATEGORY ISSUER must be the first stored element");
        }

        uriData.push(URIData(_uriCategory, _uriType, _title, _slot, _objectName, _uriDataHash, _timestamp));
        uriDataIndex[_objectName] = nonce;

        nonce++;

        emit NewURI(_uriCategory, _uriType, _slot, _uriDataHash);

    }

    /// @dev This function is only called by c3Fallback after a cross-chain failure
    function popURILocal(
        uint256 _toPop
    ) external onlyStorageManager {
        require(_toPop <= uriData.length, "CTMRWA001Storage: Cannot pop this number of uriData");

        for(uint256 i=0; i<_toPop; i++){
            uriData.pop();
        }    
    }

    /**
     * @dev This function is to allow manual fixing of the nonce in the event of a cross-chain
     * failure.
     * NOTE This will be removed in later versions
     */

    function increaseNonce(uint256 _val) public onlyTokenAdmin {
        require(_val > nonce, "CTMRWA001Storage: Can only increase the nonce value");
        nonce = _val;
    }

    /// @dev This function is only called by c3Fallback after a cross-chain failure to rewind the nonce
    function setNonce(uint256 _val) external onlyStorageManager {
        nonce = _val;
    }

    /**
     * @notice Add the wallet address of the Security Regulator of this RWA
     * @param _regulatorWallet The Regulator's wallet address
     * NOTE This function can only be called by the tokenAdmin (Issuer)
     * NOTE The function can only be called AFTER a License for a Security has been obtained
     * and a Storage Object LICENSE has been created describing the License.
     * NOTE Setting the Regulator's wallet address is required before being able to set a wallet
     * address able to forceTransfer any holders tokenIds to another wallet.
     */
    function createSecurity(address _regulatorWallet) public onlyTokenAdmin {
        uint256 securityURICount = this.getURIHashCount(URICategory.LICENSE, URIType.CONTRACT);
        require(securityURICount > 0, "CTMRWA001Storage: No description of the Security is present");

        regulatorWallet = _regulatorWallet;
    }

    /**
     * @notice Return all on-chain data related to Storage data for this RWA
     * NOTE This function cannot return the data stored on decentralized storage such
     * as BNB Greenfield, but it can provide the pointers to where this data is.
     * NOTE The data is as follows per record -
     * (1) URICategory - an enum describing what type of stored data it is
     * (2) URIType - This can either be CONTRACT i.e. relating to the entire RWA,
     * or SLOT i.e. relating to just one Asset Class (slot)
     * (3) title - this is a string describing the stored data to be viewed in the AssetX Explorer
     * (4) slot - this is a number which is the index to the Asset Class. Not used for URIType CONTRACT
     * (5) objectName - This is the object name on BNB Greenfield, or IPFS
     * (6) uriHash - This is the bytes32 hash of the checksum of the stored data. The on-chain
     * value here is always checked against the calculated value from the stored object, to make sure
     * that the object has not been altered in some way. If it has, the object will be ignored by the
     * AssetX Explorer
     * (7) timestamp - This is the Linux timestamp of the time that the on-chain record was created.
     */
    function getAllURIData() public view returns(
        uint8[] memory,
        uint8[] memory,
        string[] memory,
        uint256[] memory,
        string[] memory,
        bytes32[] memory,
        uint256[] memory
    ) {

        uint256 len = uriData.length;

        uint8[] memory uriCategory = new uint8[](len);
        uint8[] memory uriType = new uint8[](len);
        string[] memory title = new string[](len);
        uint256[] memory slot = new uint256[](len);
        string[] memory objectName = new string[](len);
        bytes32[] memory uriHash = new bytes32[](len);
        uint256[] memory timestamp = new uint256[](len);

        for(uint256 i=0; i<len; i++) {
            uriCategory[i] = uint8(uriData[i].uriCategory);
            uriType[i] = uint8(uriData[i].uriType);
            title[i] = uriData[i].title;
            slot[i] = uriData[i].slot;
            objectName[i] = uriData[i].objectName;
            uriHash[i] = uriData[i].uriHash;
            timestamp[i] = uriData[i].timeStamp;
        }


        return(
            uriCategory,
            uriType,
            title,
            slot,
            objectName,
            uriHash,
            timestamp
        );
    }

    /**
     * @notice Gets the bytes32 hash by an index number for a defined type of stored record
     * @param _uriCat The URICategory (see ICTMRWA001Storage for the list of enums)
     * @param _uriTyp The URIType (either URIType.CONTRACT, or URIType.SLOT)
     * @param _index the index of the data sought
     */
    function getURIHashByIndex(URICategory _uriCat, URIType _uriTyp, uint256 _index) public view returns(bytes32, string memory) {
        uint256 currentIndx;

        for(uint256 i=0; i<uriData.length; i++) {
            if(uriData[i].uriType == _uriTyp && uriData[i].uriCategory == _uriCat) {
                if(_index == currentIndx) {
                    return(uriData[i].uriHash, uriData[i].objectName);
                } else currentIndx++;
            }
        }

        return(bytes32(0), "");
    }

    /**
     * @notice Get the total number of stored records with a combination of URICategory and URIType
     * @param _uriCat The URICategory (see ICTMRWA001Storage for the list of enums)
     * @param _uriTyp The URIType (either URIType.CONTRACT, or URIType.SLOT)
     */
    function getURIHashCount(URICategory _uriCat, URIType _uriTyp) external view returns(uint256) {
        uint256 count;
        for(uint256 i=0; i<uriData.length; i++) {
            if(uriData[i].uriType == _uriTyp && uriData[i].uriCategory == _uriCat) {
                count++;
            }
        }
        return(count);
    }

    /**
     * @notice Return the full storage struct corresponding to a given hash of a checksum
     * @param _hash The bytes32 hash of a checksum 
     * NOTE This function returns an EMPTY record if the hash is not found
     */
    function getURIHash(bytes32 _hash) public view returns(URIData memory) {
        for(uint256 i=0; i<uriData.length; i++) {
            if(uriData[i].uriHash == _hash) {
                return(uriData[i]);
            }
        }
        return(URIData(URICategory.EMPTY,URIType.EMPTY,"",0,"",0,0));
    }

    /**
     * @notice Check the existence of a stored hash of a checksum
     * @param _uriHash The requested hash of a checksum
     */
    function existURIHash(bytes32 _uriHash) public view returns(bool) {
        for(uint256 i=0; i<uriData.length; i++) {
            if(uriData[i].uriHash == _uriHash) return(true);
        }
        return(false);
    }

    /**
     * @notice Check for the existence of a specific storage Object name
     * @param _objectName The Object name string 
     * NOTE This checks the on-chain existence of an Object, but not if the Object actually
     * exists in decentralized storage such as BNB Greenfield. The AssetX Explorer checks both
     * and matches the stored hash of the checksum against the calculated value from the data
     */
    function existObjectName(string memory _objectName) public view returns(bool) {
        if(uriDataIndex[_objectName] == 0) {
            return(false);
        } else {
            return(true);
        }
    }

    // TODO test this
    /**
     * @notice Return the full Storage struct corresponding to a given Object name
     * NOTE This function returns an EMPTY record if the Object name was not found
     */
    function getURIHashByObjectName(string memory _objectName) public view returns(URIData memory) {
        uint256 indx = uriDataIndex[_objectName];

        if(indx == 0) {
            return(URIData(URICategory.EMPTY,URIType.EMPTY,"",0,"",0,0));
        } else {
            return(uriData[indx]);
        }
    }

    function cID() internal view returns (uint256) {
        return block.chainid;
    }

    /// @dev Convert a string to an EVM address. Also checks the string length
    function stringToAddress(string memory str) internal pure returns (address) {
        bytes memory strBytes = bytes(str);
        require(strBytes.length == 42, "CTMRWA001Storage: Invalid address length");
        bytes memory addrBytes = new bytes(20);

        for (uint i = 0; i < 20; i++) {
            addrBytes[i] = bytes1(
                hexCharToByte(strBytes[2 + i * 2]) *
                    16 +
                    hexCharToByte(strBytes[3 + i * 2])
            );
        }

        return address(uint160(bytes20(addrBytes)));
    }

    function hexCharToByte(bytes1 char) internal pure returns (uint8) {
        uint8 byteValue = uint8(char);
        if (
            byteValue >= uint8(bytes1("0")) && byteValue <= uint8(bytes1("9"))
        ) {
            return byteValue - uint8(bytes1("0"));
        } else if (
            byteValue >= uint8(bytes1("a")) && byteValue <= uint8(bytes1("f"))
        ) {
            return 10 + byteValue - uint8(bytes1("a"));
        } else if (
            byteValue >= uint8(bytes1("A")) && byteValue <= uint8(bytes1("F"))
        ) {
            return 10 + byteValue - uint8(bytes1("A"));
        }
        revert("Invalid hex character");
    }

    /// @dev Check if two strings are equal (in fact if their hashes are equal)
    function stringsEqual(
        string memory a,
        string memory b
    ) internal pure returns (bool) {
        bytes32 ka = keccak256(abi.encode(a));
        bytes32 kb = keccak256(abi.encode(b));
        return (ka == kb);
    }

    /// @dev Convert a string to lower case
    function _toLower(string memory str) internal pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint i = 0; i < bStr.length; i++) {
            // Uppercase character...
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                // So we add 32 to make it lowercase
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }
    
}