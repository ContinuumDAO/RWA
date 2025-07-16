// SPDX-License-Identifier: BSL-1.1

pragma solidity 0.8.27;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { ICTMRWA1 } from "../core/ICTMRWA1.sol";

import { Address, CTMRWAUtils } from "../CTMRWAUtils.sol";
import { ICTMRWAMap } from "../shared/ICTMRWAMap.sol";
import { CTMRWA1Storage } from "./CTMRWA1Storage.sol";
import { ICTMRWA1Storage, URICategory, URIData, URIType } from "./ICTMRWA1Storage.sol";
import { ICTMRWA1StorageUtils } from "./ICTMRWA1StorageUtils.sol";

/**
 * @title AssetX Multi-chain Semi-Fungible-Token for Real-World-Assets (RWAs)
 * @author @Selqui ContinuumDAO
 *
 * @notice This contract has two tasks. The first is to deploy a new CTMRWA1Storage contract on
 * one chain. It uses the CREATE2 instruction to deploy the contract, returning its address.
 * The second function is to manage all cross-chain failures in synchronizing the on-chain records
 * for Storage.
 *
 * This contract is only deployed ONCE on each chain and manages all CTMRWA1Storage contract
 * deployments and c3Fallbacks.
 */
contract CTMRWA1StorageUtils is ICTMRWA1StorageUtils {
    using Strings for *;
    using CTMRWAUtils for string;

    uint256 public immutable RWA_TYPE;
    uint256 public immutable VERSION;
    address public ctmRwa1Map;
    address public storageManager;
    bytes4 public lastSelector;
    bytes public lastData;
    bytes public lastReason;

    modifier onlyStorageManager() {
        // require(msg.sender == storageManager, "CTMRWA1StorageUtils: onlyStorageManager function");
        if (msg.sender != storageManager) {
            revert CTMRWA1StorageUtils_Unauthorized(Address.Sender);
        }
        _;
    }

    event LogFallback(bytes4 selector, bytes data, bytes reason);

    bytes4 public AddURIX =
        bytes4(keccak256("addURIX(uint256,uint256,string[],uint8[],uint8[],string[],uint256[],uint256[],bytes32[])"));

    constructor(uint256 _rwaType, uint256 _version, address _map, address _storageManager) {
        RWA_TYPE = _rwaType;
        VERSION = _version;
        ctmRwa1Map = _map;
        storageManager = _storageManager;
    }

    /**
     * @dev Deploy a new CTMRWA1Storage using 'salt' ID to ensure a unique contract address
     */
    function deployStorage(uint256 _ID, address _tokenAddr, uint256 _rwaType, uint256 _version, address _map)
        external
        onlyStorageManager
        returns (address)
    {
        CTMRWA1Storage ctmRwa1Storage =
            new CTMRWA1Storage{ salt: bytes32(_ID) }(_ID, _tokenAddr, _rwaType, _version, msg.sender, _map);

        return (address(ctmRwa1Storage));
    }

    /// @dev Get the latest revert string from a failed c3call cross-chain transaction
    function getLastReason() public view returns (string memory) {
        return (string(lastReason));
    }

    /**
     * @dev This fallback function from a failed c3call manages the reversion of an addURI
     * cross-chain c3call. The storage record is 'popped' and the nonce is rewound.
     * NOTE The storage object created on decentralized storage (e.g. BNB Greenfield) must
     * before another addURI call can be made
     */
    function smC3Fallback(bytes4 _selector, bytes calldata _data, bytes calldata _reason)
        external
        onlyStorageManager
        returns (bool)
    {
        lastSelector = _selector;
        lastData = _data;
        lastReason = _reason;

        if (_selector == AddURIX) {
            uint256 ID;
            uint256 startNonce;
            string[] memory objectName;

            (ID, startNonce, objectName,,,,,,) = abi.decode(
                _data, (uint256, uint256, string[], uint8[], uint8[], string[], uint256[], uint256[], bytes32[])
            );

            (bool ok, address storageAddr) = ICTMRWAMap(ctmRwa1Map).getStorageContract(ID, RWA_TYPE, VERSION);
            // require(ok, "CTMRWA1StorageUtils: Could not find _ID or its storage address");
            if (!ok) {
                revert CTMRWA1StorageUtils_InvalidContract(Address.Storage);
            }

            ICTMRWA1Storage(storageAddr).popURILocal(objectName.length);
            ICTMRWA1Storage(storageAddr).setNonce(startNonce);
        }

        emit LogFallback(_selector, _data, _reason);

        return (true);
    }

    /// @dev Get the address of the CTMRWA1 contract from the _ID
    function _getTokenAddr(uint256 _ID) internal view returns (address, string memory) {
        (bool ok, address tokenAddr) = ICTMRWAMap(ctmRwa1Map).getTokenContract(_ID, RWA_TYPE, VERSION);
        // require(ok, "CTMRWA1StorageUtils: The requested tokenID does not exist");
        if (!ok) {
            revert CTMRWA1StorageUtils_InvalidContract(Address.Token);
        }
        string memory tokenAddrStr = tokenAddr.toHexString()._toLower();

        return (tokenAddr, tokenAddrStr);
    }
}
