// SPDX-License-Identifier: BSL-1.1

pragma solidity 0.8.27;

import { ICTMRWA1, ITokenContract, TokenContract } from "../core/ICTMRWA1.sol";
import { ITokenContract } from "../core/ICTMRWA1.sol";
import { ICTMRWAGateway } from "../crosschain/ICTMRWAGateway.sol";
import { FeeType, IFeeManager } from "../managers/IFeeManager.sol";
import { ICTMRWAMap } from "../shared/ICTMRWAMap.sol";
import { Address, CTMRWAUtils, Uint } from "../utils/CTMRWAUtils.sol";
import { ICTMRWA1Storage, URICategory, URIData, URIType } from "./ICTMRWA1Storage.sol";
import { ICTMRWA1StorageManager } from "./ICTMRWA1StorageManager.sol";
import { ICTMRWA1StorageUtils } from "./ICTMRWA1StorageUtils.sol";
import { C3GovernDapp } from "@c3caller/gov/C3GovernDapp.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title AssetX Multi-chain Semi-Fungible-Token for Real-World-Assets (RWAs)
 * @author @Selqui ContinuumDAO
 *
 * @notice This contract handles the cross-chain interactions for decentralized storage of data
 * relating to the RWA, updating the CTMRWA1Storage contract for each ID with checksum and other data
 * and ensuring that the CTMRWA1Storage for every RWA with the same ID on each chain stores the
 * exact same information.
 *
 * This contract is only deployed ONCE on each chain and manages all CTMRWA1 contract interactions
 */
contract CTMRWA1StorageManager is ICTMRWA1StorageManager, C3GovernDapp, UUPSUpgradeable {
    using Strings for *;
    using SafeERC20 for IERC20;
    using CTMRWAUtils for *;

    /// @dev The address of the CTMRWADeployer contract on this chain
    address public ctmRwaDeployer;

    /// @dev The address of the CTMRWAMap contract
    address public ctmRwa1Map;

    /// @dev The address of the CTMRWA1StorageUtils contract on this chain
    address public utilsAddr;

    /// @dev rwaType is the RWA type defining CTMRWA1
    uint256 public constant RWA_TYPE = 1;

    /// @dev version is the single integer version of this RWA type
    uint256 public constant VERSION = 1;

    /// @dev The address of the CTMRWAGateway contract
    address public gateway;

    /// @dev The address of the FeeManager contract
    address public feeManager;

    /// @dev string representation of the chainID
    string cIdStr;

    /// @dev New c3call for adding URI for ID to chain chainIdStr
    event AddingURI(uint256 ID, string chainIdStr);

    /// @dev New URI added on local chain for ID
    event URIAdded(uint256 ID);

    modifier onlyDeployer() {
        if (msg.sender != ctmRwaDeployer) {
            revert CTMRWA1StorageManager_OnlyAuthorized(Address.Sender, Address.Deployer);
        }
        _;
    }

    function initialize(
        address _gov,
        address _c3callerProxy,
        address _txSender,
        uint256 _dappID,
        address _ctmRwaDeployer,
        address _gateway,
        address _feeManager
    ) external initializer {
        __C3GovernDapp_init(_gov, _c3callerProxy, _txSender, _dappID);
        ctmRwaDeployer = _ctmRwaDeployer;
        gateway = _gateway;
        feeManager = _feeManager;
        cIdStr = cID().toString();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyGov { }

    /**
     * @notice Governance can change to a new CTMRWAGateway contract
     * @param _gateway address of the new CTMRWAGateway contract
     */
    function setGateway(address _gateway) external onlyGov {
        gateway = _gateway;
    }

    /**
     * @notice Governance can change to a new FeeManager contract
     * @param _feeManager address of the new FeeManager contract
     */
    function setFeeManager(address _feeManager) external onlyGov {
        feeManager = _feeManager;
    }

    /**
     * @notice Governance can change to a new CTMRWADeployer and CTMRWAERC20Deployer contracts
     * @param _deployer address of the new CTMRWADeployer contract
     */
    function setCtmRwaDeployer(address _deployer) external onlyGov {
        ctmRwaDeployer = _deployer;
    }

    /**
     * @notice Governance can change to a new CTMRWAMap contract
     * @param _map address of the new CTMRWAMap contract
     */
    function setCtmRwaMap(address _map) external onlyGov {
        ctmRwa1Map = _map;
    }

    /**
     * @notice Governance can change to a new CTMRWA1StorageUtils contract
     * @param _utilsAddr address of the new CTMRWA1StorageUtils contract
     */
    function setStorageUtils(address _utilsAddr) external onlyGov {
        utilsAddr = _utilsAddr;
    }

    /**
     * @dev This function is called by CTMRWADeployer, allowing CTMRWA1StorageUtils to
     * deploy a CTMRWA1Storage contract with the same ID as for the CTMRWA1 contract
     */
    function deployStorage(uint256 _ID, address _tokenAddr, uint256 _rwaType, uint256 _version, address _map)
        external
        onlyDeployer
        returns (address)
    {
        address storageAddr = ICTMRWA1StorageUtils(utilsAddr).deployStorage(_ID, _tokenAddr, _rwaType, _version, _map);

        return (storageAddr);
    }

    /**
     * @notice Add a data storage record to the RWA's CTMRWA1Storage contract on this chain and
     * identically on every other chain that the RWA is deployed to. The bulk of the data is stored
     * in an object in decentralized storage (e.g. BNB Greenfield) in an object with name _objectName.
     * Also stored in the CTMRWA1Storage are the title of the record, the type of information, the
     * Asset Class (slot) and a hash of the checksum of the stored data.
     * @param _ID The ID of the RWA token
     * @param _objectName The name of the object stored in decentralized storage (e.g. BNB Greenfield)
     * It should be identical to the string version of the nonce() in the RWA's CTMRWA1Storage contract.
     * @param _uriCategory The category type of the data being stored. The allowable values are the enums
     * in URICategory defined in ICTMRWA1Storage
     * @param _uriType The type of storage information. It can either relate the the entire RWA
     * (URIType.CONTRACT), or to an individual Asset Class (URIType.SLOT)
     * @param _title The title of this storage record. It has to be between 10 and 256 charcters in length.
     * @param _slot The Asset Class (slot) for this storage record if URIType.SLOT, otherwise set to zero.
     * @param _uriDataHash The hash of the checksum of the storage record as a bytes32.
     * NOTE _uriDataHash has to be unique.
     * @param _chainIdsStr This is an array of strings of chainIDs to deploy to.
     * NOTE For EVM chains, you must convert the integer chainID values to strings. Include the local chainID too.
     * @param _feeTokenStr This is fee token on the source chain (local chain) that you wish to use to pay
     * for the deployment. See the function feeTokenList in the FeeManager contract for allowable values.
     * NOTE For EVM chains, the address of the fee token must be converted to a string
     *
     * NOTE The very first storage object MUST be URICategory.ISSUER and URIType.CONTRACT describing the
     * Issuer of the RWA
     * NOTE The tokenAdmin (Issuer) of the RWA must register the RWA as a Security and add a
     * URICategory.LICENSE record before they can create a wallet address able to forceTransfer value
     * in CTMRWA1.
     */
    function addURI(
        uint256 _ID,
        string memory _objectName,
        URICategory _uriCategory,
        URIType _uriType,
        string memory _title,
        uint256 _slot,
        bytes32 _uriDataHash,
        string[] memory _chainIdsStr,
        string memory _feeTokenStr
    ) public {
        (bool ok, address storageAddr) = ICTMRWAMap(ctmRwa1Map).getStorageContract(_ID, RWA_TYPE, VERSION);
        if (!ok) {
            revert CTMRWA1StorageManager_InvalidContract(Address.Storage);
        }

        (address ctmRwa1Addr,) = _getTokenAddr(_ID);
        _checkTokenAdmin(ctmRwa1Addr);

        if (bytes(ICTMRWA1(ctmRwa1Addr).baseURI()).length == 0) {
            revert CTMRWA1StorageManager_NoStorage();
        }

        uint256 fee;
        uint256 titleLength;

        titleLength = bytes(_title).length;
        if (ICTMRWA1Storage(storageAddr).existObjectName(_objectName)) {
            revert CTMRWA1StorageManager_ObjectAlreadyExists();
        }

        if (titleLength < 10 || titleLength > 256) {
            revert CTMRWA1StorageManager_InvalidLength(Uint.Title);
        }

        fee = _individualFee(_uriCategory, _feeTokenStr, _chainIdsStr, false);

        _payFee(fee, _feeTokenStr);

        uint256 startNonce = ICTMRWA1Storage(storageAddr).nonce();

        for (uint256 i = 0; i < _chainIdsStr.length; i++) {
            string memory chainIdStr = _chainIdsStr[i]._toLower();

            if (chainIdStr.equal(cIdStr)) {
                ICTMRWA1Storage(storageAddr).addURILocal(
                    _ID, _objectName, _uriCategory, _uriType, _title, _slot, block.timestamp, _uriDataHash
                );
            } else {
                (, string memory toRwaSMStr) = _getSM(chainIdStr);

                string memory funcCall =
                    "addURIX(uint256,uint256,string[],uint8[],uint8[],string[],uint256[],uint256[],bytes32[])";
                bytes memory callData = abi.encodeWithSignature(
                    funcCall,
                    _ID,
                    startNonce,
                    _objectName._stringToArray(),
                    uint8(_uriCategory)._uint8ToArray(),
                    uint8(_uriType)._uint8ToArray(),
                    _title._stringToArray(),
                    _slot._uint256ToArray(),
                    block.timestamp._uint256ToArray(),
                    _uriDataHash._bytes32ToArray()
                );

                _c3call(toRwaSMStr, chainIdStr, callData);

                emit AddingURI(_ID, chainIdStr);
            }
        }
    }

    /**
     * @notice When new chains are added to the RWA with _ID, this function transfers all the existing storage
     * data from the CTMRWA1Storage contract for the ID on the local chain to the newly added chains.
     * In this way, the storage data is synced on all chains of the RWA for this ID, all pointing to the same
     * decentralized storage objects on e.g. BNB Greenfield.
     * @param _ID The ID of this RWA
     * @param _chainIdsStr This is an array of strings of chainIDs to deploy to.
     * NOTE For EVM chains, you must convert the integer chainID values to strings. Do not include the local chainID.
     * @param _feeTokenStr This is fee token on the source chain (local chain) that you wish to use to pay
     * for the deployment. See the function feeTokenList in the FeeManager contract for allowable values.
     * NOTE For EVM chains, the address of the fee token must be converted to a string
     */
    function transferURI(uint256 _ID, string[] memory _chainIdsStr, string memory _feeTokenStr) public {
        (bool ok, address storageAddr) = ICTMRWAMap(ctmRwa1Map).getStorageContract(_ID, RWA_TYPE, VERSION);
        if (!ok) {
            revert CTMRWA1StorageManager_InvalidContract(Address.Storage);
        }

        (address ctmRwa1Addr,) = _getTokenAddr(_ID);
        _checkTokenAdmin(ctmRwa1Addr);

        if (bytes(ICTMRWA1(ctmRwa1Addr).baseURI()).length == 0) {
            revert CTMRWA1StorageManager_NoStorage();
        }

        (
            uint8[] memory uriCategory,
            uint8[] memory uriType,
            string[] memory title,
            uint256[] memory slot,
            string[] memory objectName,
            bytes32[] memory uriDataHash,
            uint256[] memory timestamp
        ) = ICTMRWA1Storage(storageAddr).getAllURIData();

        uint256 len = objectName.length;

        if (len < 1) {
            revert CTMRWA1StorageManager_InvalidLength(Uint.URI);
        }

        uint256 fee;

        for (uint256 i = 0; i < len; i++) {
            fee = fee + _individualFee(_uToCat(uriCategory[i]), _feeTokenStr, _chainIdsStr, false);
        }

        _payFee(fee, _feeTokenStr);

        uint256 startNonce = 1;

        for (uint256 i = 0; i < _chainIdsStr.length; i++) {
            string memory chainIdStr = _chainIdsStr[i]._toLower();

            if (chainIdStr.equal(cIdStr)) {
                revert CTMRWA1StorageManager_SameChain();
            } else {
                (, string memory toRwaSMStr) = _getSM(chainIdStr);

                string memory funcCall =
                    "addURIX(uint256,uint256,string[],uint8[],uint8[],string[],uint256[],uint256[],bytes32[])";
                bytes memory callData = abi.encodeWithSignature(
                    funcCall, _ID, startNonce, objectName, uriCategory, uriType, title, slot, timestamp, uriDataHash
                );

                _c3call(toRwaSMStr, chainIdStr, callData);

                emit AddingURI(_ID, chainIdStr);
            }
        }
    }

    /**
     * @dev Adds the storage information for a storage object to the CTMRWA1Storage
     * contract on this chain, being a copy of that on the source chain. This function
     * can only be called by the MPC network.
     */
    function addURIX(
        uint256 _ID,
        uint256 _startNonce,
        string[] memory _objectName,
        uint8[] memory _uriCategory,
        uint8[] memory _uriType,
        string[] memory _title,
        uint256[] memory _slot,
        uint256[] memory _timestamp,
        bytes32[] memory _uriDataHash
    ) external onlyCaller returns (bool) {
        (bool ok, address storageAddr) = ICTMRWAMap(ctmRwa1Map).getStorageContract(_ID, RWA_TYPE, VERSION);
        if (!ok) {
            revert CTMRWA1StorageManager_InvalidContract(Address.Storage);
        }

        uint256 currentNonce = ICTMRWA1Storage(storageAddr).nonce();
        if (_startNonce != currentNonce) {
            revert CTMRWA1StorageManager_StartNonce();
        }

        uint256 len = _objectName.length;

        for (uint256 i = 0; i < len; i++) {
            ICTMRWA1Storage(storageAddr).addURILocal(
                _ID,
                _objectName[i],
                _uToCat(_uriCategory[i]),
                _uToType(_uriType[i]),
                _title[i],
                _slot[i],
                _timestamp[i],
                _uriDataHash[i]
            );
        }

        emit URIAdded(_ID);

        return (true);
    }

    /// @dev Get the address of the CTMRWA1 corresponding to the _ID
    function _getTokenAddr(uint256 _ID) internal view returns (address, string memory) {
        (bool ok, address tokenAddr) = ICTMRWAMap(ctmRwa1Map).getTokenContract(_ID, RWA_TYPE, VERSION);
        if (!ok) {
            revert CTMRWA1StorageManager_InvalidContract(Address.Token);
        }
        string memory tokenAddrStr = tokenAddr.toHexString()._toLower();

        return (tokenAddr, tokenAddrStr);
    }

    /**
     * @dev  Get the address of the corresponding CTMRWA1StorageManager contract on another chain
     * with chainID (converted to a string) of _toChainIdStr
     */
    function _getSM(string memory _toChainIdStr) internal view returns (string memory, string memory) {
        if (_toChainIdStr.equal(cIdStr)) {
            revert CTMRWA1StorageManager_SameChain();
        }

        string memory fromAddressStr = msg.sender.toHexString()._toLower();

        (bool ok, string memory toSMStr) =
            ICTMRWAGateway(gateway).getAttachedStorageManager(RWA_TYPE, VERSION, _toChainIdStr);
        if (!ok) {
            revert CTMRWA1StorageManager_InvalidContract(Address.Storage);
        }

        return (fromAddressStr, toSMStr);
    }

    /**
     * @dev Return the tokenAdmin address for a CTMRWA1 with address _tokenAddr and
     * check that the msg.sender is the tokenAdmin and revert if not so.
     */
    function _checkTokenAdmin(address _tokenAddr) internal returns (address, string memory) {
        address currentAdmin = ICTMRWA1(_tokenAddr).tokenAdmin();
        string memory currentAdminStr = currentAdmin.toHexString()._toLower();

        if (msg.sender != currentAdmin) {
            revert CTMRWA1StorageManager_OnlyAuthorized(Address.Sender, Address.Admin);
        }

        return (currentAdmin, currentAdminStr);
    }

    /**
     * @dev Get the total fee for an individual URICategory to all the chains in _toChainIdsStr
     * _includeLocal, if TRUE means to include the fee for the local chain too.
     */
    function _individualFee(
        URICategory _uriCategory,
        string memory _feeTokenStr,
        string[] memory _toChainIdsStr,
        bool _includeLocal
    ) internal view returns (uint256) {
        FeeType feeType;

        if (_uriCategory == URICategory.ISSUER) {
            feeType = FeeType.ISSUER;
        } else if (_uriCategory == URICategory.PROVENANCE) {
            feeType = FeeType.PROVENANCE;
        } else if (_uriCategory == URICategory.VALUATION) {
            feeType = FeeType.VALUATION;
        } else if (_uriCategory == URICategory.PROSPECTUS) {
            feeType = FeeType.PROSPECTUS;
        } else if (_uriCategory == URICategory.RATING) {
            feeType = FeeType.RATING;
        } else if (_uriCategory == URICategory.LEGAL) {
            feeType = FeeType.LEGAL;
        } else if (_uriCategory == URICategory.FINANCIAL) {
            feeType = FeeType.FINANCIAL;
        } else if (_uriCategory == URICategory.LICENSE) {
            feeType = FeeType.LICENSE;
        } else if (_uriCategory == URICategory.DUEDILIGENCE) {
            feeType = FeeType.DUEDILIGENCE;
        } else if (_uriCategory == URICategory.NOTICE) {
            feeType = FeeType.NOTICE;
        } else if (_uriCategory == URICategory.DIVIDEND) {
            feeType = FeeType.DIVIDEND;
        } else if (_uriCategory == URICategory.REDEMPTION) {
            feeType = FeeType.REDEMPTION;
        } else if (_uriCategory == URICategory.WHOCANINVEST) {
            feeType = FeeType.WHOCANINVEST;
        } else if (_uriCategory == URICategory.IMAGE) {
            feeType = FeeType.IMAGE;
        } else if (_uriCategory == URICategory.VIDEO) {
            feeType = FeeType.VIDEO;
        } else if (_uriCategory == URICategory.ICON) {
            feeType = FeeType.ICON;
        }

        uint256 fee = IFeeManager(feeManager).getXChainFee(_toChainIdsStr, _includeLocal, feeType, _feeTokenStr);

        return (fee);
    }

    /// @dev Convert uint8 to the enum URICategory
    function _uToCat(uint8 _cat) internal pure returns (URICategory) {
        URICategory uriCategory;

        if (_cat == 0) {
            uriCategory = URICategory.ISSUER;
        } else if (_cat == 1) {
            uriCategory = URICategory.PROVENANCE;
        } else if (_cat == 2) {
            uriCategory = URICategory.VALUATION;
        } else if (_cat == 3) {
            uriCategory = URICategory.PROSPECTUS;
        } else if (_cat == 4) {
            uriCategory = URICategory.RATING;
        } else if (_cat == 5) {
            uriCategory = URICategory.LEGAL;
        } else if (_cat == 6) {
            uriCategory = URICategory.FINANCIAL;
        } else if (_cat == 7) {
            uriCategory = URICategory.LICENSE;
        } else if (_cat == 8) {
            uriCategory = URICategory.DUEDILIGENCE;
        } else if (_cat == 9) {
            uriCategory = URICategory.NOTICE;
        } else if (_cat == 10) {
            uriCategory = URICategory.DIVIDEND;
        } else if (_cat == 11) {
            uriCategory = URICategory.REDEMPTION;
        } else if (_cat == 12) {
            uriCategory = URICategory.WHOCANINVEST;
        } else if (_cat == 13) {
            uriCategory = URICategory.IMAGE;
        } else if (_cat == 14) {
            uriCategory = URICategory.VIDEO;
        } else if (_cat == 15) {
            uriCategory = URICategory.ICON;
        }

        return uriCategory;
    }

    /// @dev Convert uint8 to to the enum URIType
    function _uToType(uint8 _type) internal pure returns (URIType) {
        URIType uriType;

        if (_type == 0) {
            uriType = URIType.CONTRACT;
        } else if (_type == 1) {
            uriType = URIType.SLOT;
        }

        return uriType;
    }

    /// @dev Pay a fee, calculated by the feeType, the fee token and the chains in question
    function _payFee(uint256 _feeWei, string memory _feeTokenStr) internal returns (bool) {
        if (_feeWei > 0) {
            address feeToken = _feeTokenStr._stringToAddress();

            IERC20(feeToken).transferFrom(msg.sender, address(this), _feeWei);

            IERC20(feeToken).approve(feeManager, _feeWei);
            IFeeManager(feeManager).payFee(_feeWei, _feeTokenStr);
        }
        return (true);
    }

    /// @dev Get the last revert string from a cross-chain c3Fallback
    function getLastReason() public view returns (string memory) {
        string memory lastReason = ICTMRWA1StorageUtils(utilsAddr).getLastReason();
        return (lastReason);
    }

    function cID() internal view returns (uint256) {
        return block.chainid;
    }

    /// @dev Manage a cross-chain fallback from c3Caller. See CTMRWA1StorageUtils
    function _c3Fallback(bytes4 _selector, bytes calldata _data, bytes calldata _reason)
        internal
        override
        returns (bool)
    {
        bool ok = ICTMRWA1StorageUtils(utilsAddr).smC3Fallback(_selector, _data, _reason);
        return ok;
    }
}
