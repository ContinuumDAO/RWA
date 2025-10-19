// SPDX-License-Identifier: BSL-1.1

pragma solidity 0.8.27;

import { CTMRWAUtils, CTMRWAErrorParam } from "../utils/CTMRWAUtils.sol";
import { ChainContract, ICTMRWAGateway } from "./ICTMRWAGateway.sol";
import { C3GovernDAppUpgradeable } from "@c3caller/upgradeable/gov/C3GovernDAppUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title AssetX Multi-chain Semi-Fungible-Token for Real-World-Assets (RWAs)
 * @author @Selqui ContinuumDAO
 *
 * @notice This contract is the gateway between any blockchain that can have an RWA deployed
 * to it. It stores the contract addresses of CTMRWAGateway contracts on other chains, as well.
 * In the case of rwaType 1, the contract addresses of CTMRWA1X, CTMRWA1StorageManager and CTMRWA1SentryMananager
 * contracts are stored, but other rwaTypes are also supported. 
 * This enables c3calls to be made between all the c3Caller DApps that make up AssetX
 *
 * This contract is only deployed ONCE on each chain and manages all CTMRWA contract interactions
 */
contract CTMRWAGateway is ICTMRWAGateway, C3GovernDAppUpgradeable, UUPSUpgradeable {
    using Strings for *;
    using CTMRWAUtils for string;

    string public cIdStr;

    /// @dev rwaType => version => ChainContract. Addresses of other CTMRWAGateway contracts
    mapping(uint256 => mapping(uint256 => ChainContract[])) rwaX;

    /// @dev rwaType => version => chainStr array. ChainIds of other CTMRWA1X contracts
    mapping(uint256 => mapping(uint256 => string[])) rwaXChains;

    /// @dev rwaType => version => chainStr array. Addresses of other CTMRWA1StorageManager contracts
    mapping(uint256 => mapping(uint256 => ChainContract[])) storageManager;

    /// @dev rwaType => version => chainStr array. Addresses of other CTMRWA1SentryManager contracts
    mapping(uint256 => mapping(uint256 => ChainContract[])) sentryManager;

    /// @dev Record that a c3Caller cross-chain transfer failed with fallback
    event LogFallback(bytes4 selector, bytes data, bytes reason);

    /// @dev This array holds ChainContract structs for all chains
    ChainContract[] private chainContract;

    function initialize(address _gov, address _c3callerProxy, address _txSender, uint256 _dappID)
        external
        initializer
    {
        __C3GovernDApp_init(_gov, _c3callerProxy, _txSender, _dappID);
        cIdStr = cID().toString();
        _addChainContract(cID(), address(this));
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyGov { }

    /// @dev Adds the address of a CTMRWAGateway contract on another chainId
    function _addChainContract(uint256 _chainId, address _contractAddr) internal {
        string memory newChainIdStr = _chainId.toString();
        string memory contractStr = _contractAddr.toHexString()._toLower();

        chainContract.push(ChainContract(newChainIdStr, contractStr));
    }

    /**
     * @notice Governor function to add addresses of CTMRWAGateway contracts on other chains.
     * @dev All input address are arrays of strings
     */
    function addChainContract(string[] memory _newChainIdsStr, string[] memory _contractAddrsStr)
        external
        onlyGov
    {
        if (_newChainIdsStr.length != _contractAddrsStr.length) {
            revert CTMRWAGateway_LengthMismatch(CTMRWAErrorParam.Input);
        }

        bool preExisted;

        for (uint256 j = 0; j < _newChainIdsStr.length; j++) {
            _newChainIdsStr[j]._checkStringLength(64);
            _contractAddrsStr[j]._checkStringLength(64);
            string memory newChainIdStr = _newChainIdsStr[j]._toLower();
            string memory contractAddrStr = _contractAddrsStr[j]._toLower();

            for (uint256 i = 0; i < chainContract.length; i++) {
                if (chainContract[i].chainIdStr.equal(newChainIdStr)) {
                    chainContract[i].contractStr = contractAddrStr;
                    preExisted = true;
                }
            }

            if (!preExisted) {
                chainContract.push(ChainContract(newChainIdStr, contractAddrStr));
                preExisted = false;
            }
        }
    }

    /**
     * @notice Get the address string for a CTMRWAGateway contract on another chainId
     * @param _chainIdStr The chainId converted to a string
     * @return contractStr The address string for a CTMRWAGateway contract on another chainId
     */
    function getChainContract(string memory _chainIdStr) external view returns (string memory) {
        for (uint256 i = 0; i < chainContract.length; i++) {
            if (chainContract[i].chainIdStr.equal(_chainIdStr._toLower())) {
                return (chainContract[i].contractStr);
            }
        }
        return ("");
    }

    /**
     * @notice Get the chainId and address of a CTMRWAGateway contract at an index _pos
     * @param _pos The index into the stored array
     * @return chainIdStr The chainId of the CTMRWAGateway contract at the index
     * @return tuple (chainIdStr, contractStr) The chainId and address string for a CTMRWAGateway contract at the index
     */
    function getChainContract(uint256 _pos) public view returns (string memory, string memory) {
        return (chainContract[_pos].chainIdStr, chainContract[_pos].contractStr);
    }

    /// @notice Get the number of stored chainIds and CTMRWAGateway pairs stored
    /// @return The number of stored chainIds and CTMRWAGateway pairs stored
    function getChainCount() public view returns (uint256) {
        return (chainContract.length);
    }

    /**
     * @notice Get all the chainIds of all CTMRWA1X contracts
     * @param _rwaType The type of RWA. CTMRWA1 is 1
     * @param _version The version of this RWA type. Currently only 1 is in use
     * @return rwaXChains The array of chainIds of all CTMRWA1X contracts
     */
    function getAllRwaXChains(uint256 _rwaType, uint256 _version) public view returns (string[] memory) {
        return (rwaXChains[_rwaType][_version]);
    }

    /**
     * @notice Check the existence of a stored CTMRWA1X contract on chainId _chainIdStr
     * @param _rwaType The type of RWA. CTMRWA1 is 1
     * @param _version The version of this RWA type. Currently only 1 is in use
     * @param _chainIdStr The chainId converted to a string to check for
     * @return success True if the chainId exists, false otherwise.
     */
    function existRwaXChain(uint256 _rwaType, uint256 _version, string memory _chainIdStr) public view returns (bool) {
        for (uint256 i = 0; i < rwaXChains[_rwaType][_version].length; i++) {
            if (rwaXChains[_rwaType][_version][i].equal(_chainIdStr._toLower())) {
                return (true);
            }
        }
        return (false);
    }

    /**
     * @notice Return all chainIds as an array, including the local chainId, and the corresponding CTMRWA1X contract addresses
     * as another array at an index position
     * @param _rwaType The type of RWA. CTMRWA1 is 1
     * @param _version The version of this RWA type. Currently only 1 is in use
     * @param _indx The index position to return data from
     * @return chainIdStr The chainId of the CTMRWA1X contract at the index
     * @return tuple (chainIdStr, contractStr) The chainId and address string for a CTMRWA1X contract at the index
     * NOTE The local chainId is at index 0.
     */
    function getAttachedRWAX(uint256 _rwaType, uint256 _version, uint256 _indx)
        public
        view
        returns (string memory, string memory)
    {
        return (rwaX[_rwaType][_version][_indx].chainIdStr, rwaX[_rwaType][_version][_indx].contractStr);
    }

    /**
     * @notice get the total number of stored CTMRWA1X contracts for all chainIds (including this one)
     * @param _rwaType The type of RWA. CTMRWA1 is 1
     * @param _version The version of this RWA type. Currently only 1 is in use
     * @return The total number of stored CTMRWA1X contracts for all chainIds (including this one)
     */
    function getRWAXCount(uint256 _rwaType, uint256 _version) public view returns (uint256) {
        return (rwaX[_rwaType][_version].length);
    }

    /**
     * @notice Get the attached CTMRWA1X contract address for chainId _chainIdStr as a string, including the local chainId
     * @param _rwaType The type of RWA. CTMRWA1 is 1
     * @param _version The version of this RWA type. Currently only 1 is in use
     * @param _chainIdStr The chainId (as a string) being examined
     * @return tuple (success, contractStr) success True if the chainId exists, false otherwise. contractStr is the address string for a CTMRWA1X contract at the index
     * NOTE The local chainId is at index 0.
     */
    function getAttachedRWAX(uint256 _rwaType, uint256 _version, string memory _chainIdStr)
        public
        view
        returns (bool, string memory)
    {
        for (uint256 i = 0; i < rwaX[_rwaType][_version].length; i++) {
            if (rwaX[_rwaType][_version][i].chainIdStr.equal(_chainIdStr._toLower())) {
                return (true, rwaX[_rwaType][_version][i].contractStr);
            }
        }

        return (false, "0");
    }

    /**
     * @notice Return all chainIds as an array, including the local chainId, and the corresponding CTMRWA1StorageManager
     * contract addresses as another array at an index position.
     * NOTE The local chainId is at index 0.
     * @param _rwaType The type of RWA. CTMRWA1 is 1
     * @param _version The version of this RWA type. Currently only 1 is in use
     * @param _indx The index position to return data from
     * @return chainIdStr The chainId of the CTMRWA1StorageManager contract at the index
     * @return tuple (chainIdStr, contractStr) The chainId and address string for a CTMRWA1StorageManager contract at the index
     * NOTE The local chainId is at index 0.
     */
    function getAttachedStorageManager(uint256 _rwaType, uint256 _version, uint256 _indx)
        public
        view
        returns (string memory, string memory)
    {
        return (
            storageManager[_rwaType][_version][_indx].chainIdStr, storageManager[_rwaType][_version][_indx].contractStr
        );
    }

    /**
     * @notice get the total number of stored CTMRWA1StorageManager contracts for all
     * chainIds (including this one)
     * @param _rwaType The type of RWA. CTMRWA1 is 1
     * @param _version The version of this RWA type. Currently only 1 is in use
     * @return The total number of stored CTMRWA1StorageManager contracts for all chainIds (including this one)
     */
    function getStorageManagerCount(uint256 _rwaType, uint256 _version) public view returns (uint256) {
        return (storageManager[_rwaType][_version].length);
    }

    /**
     * @notice Get the attached CTMRWA1StorageManager contract address for chainId _chainIdStr
     * as a string
     * @param _rwaType The type of RWA. CTMRWA1 is 1
     * @param _version The version of this RWA type. Currently only 1 is in use
     * @param _chainIdStr The chainId (as a string) being examined
     * @return success True if the chainId exists, false otherwise.
     * @return tuple (chainIdStr, contractStr) The chainId and address string for a CTMRWA1StorageManager contract at the index
     */
    function getAttachedStorageManager(uint256 _rwaType, uint256 _version, string memory _chainIdStr)
        public
        view
        returns (bool, string memory)
    {
        for (uint256 i = 0; i < storageManager[_rwaType][_version].length; i++) {
            if (storageManager[_rwaType][_version][i].chainIdStr.equal(_chainIdStr._toLower())) {
                return (true, storageManager[_rwaType][_version][i].contractStr);
            }
        }

        return (false, "0");
    }

    /**
     * @notice Return all chainIds as an array, including the local chainId, and the corresponding CTMRWA1SentryManager
     * contract addresses as another array at an index position
     * @param _rwaType The type of RWA. CTMRWA1 is 1
     * @param _version The version of this RWA type. Currently only 1 is in use
     * @param _indx The index position to return data from
     * @return chainIdStr The chainId of the CTMRWA1SentryManager contract at the index
     * @return tuple (chainIdStr, contractStr) The chainId and address string for a CTMRWA1SentryManager contract at the index
     * NOTE The local chainId is at index 0.
     */
    function getAttachedSentryManager(uint256 _rwaType, uint256 _version, uint256 _indx)
        public
        view
        returns (string memory, string memory)
    {
        return
            (sentryManager[_rwaType][_version][_indx].chainIdStr, sentryManager[_rwaType][_version][_indx].contractStr);
    }

    /**
     * @notice get the total number of stored CTMRWA1SentryManager contracts for all
     * chainIds (including this one)
     * @param _rwaType The type of RWA. CTMRWA1 is 1
     * @param _version The version of this RWA type. Currently only 1 is in use
     * @return The total number of stored CTMRWA1SentryManager contracts for all chainIds (including this one)
     */
    function getSentryManagerCount(uint256 _rwaType, uint256 _version) public view returns (uint256) {
        return (sentryManager[_rwaType][_version].length);
    }

    /**
     * @notice Get the attached CTMRWA1SentryManager contract address for chainId _chainIdStr
     * as a string, including the local chainId
     * @param _rwaType The type of RWA. CTMRWA1 is 1
     * @param _version The version of this RWA type. Currently only 1 is in use
     * @param _chainIdStr The chainId (as a string) being examined
     * @return success True if the chainId exists, false otherwise.
     * @return tuple (chainIdStr, contractStr) The chainId and address string for a CTMRWA1SentryManager contract at the index
     * NOTE The local chainId is at index 0.
     */
    function getAttachedSentryManager(uint256 _rwaType, uint256 _version, string memory _chainIdStr)
        public
        view
        returns (bool, string memory)
    {
        for (uint256 i = 0; i < sentryManager[_rwaType][_version].length; i++) {
            if (sentryManager[_rwaType][_version][i].chainIdStr.equal(_chainIdStr._toLower())) {
                return (true, sentryManager[_rwaType][_version][i].contractStr);
            }
        }

        return (false, "0");
    }

    /**
     * @notice Governor function. Attach new CTMRWA1X contracts for chainIds, including the local chainId
     * @param _rwaType The type of RWA. CTMRWA1 is 1
     * @param _version The version of this RWA type. Currently only 1 is in use
     * @param _chainIdsStr Array of chainIds converted to strings
     * @param _rwaXAddrsStr Array of the CTMRWA1X contract addresses converted to strings
     * @return success True if the addresses were added successfully.
     * NOTE The local chainId is at index 0.
     */
    function attachRWAX(uint256 _rwaType, uint256 _version, string[] memory _chainIdsStr, string[] memory _rwaXAddrsStr)
        external
        onlyGov
        returns (bool)
    {
        if (_chainIdsStr.length == 0 || _rwaXAddrsStr.length == 0) {
            revert CTMRWAGateway_InvalidLength(CTMRWAErrorParam.Input);
        }

        if (_chainIdsStr.length != _rwaXAddrsStr.length) {
            revert CTMRWAGateway_LengthMismatch(CTMRWAErrorParam.Input);
        }

        bool preExisted;

        for (uint256 j = 0; j < _chainIdsStr.length; j++) {
            _chainIdsStr[j]._checkStringLength(64);
            _rwaXAddrsStr[j]._checkStringLength(64);
            string memory rwaXAddrStr = _rwaXAddrsStr[j]._toLower();
            string memory chainIdStr = _chainIdsStr[j]._toLower();

            if (bytes(rwaXAddrStr).length > 64) {
                revert CTMRWAGateway_InvalidLength(CTMRWAErrorParam.Address);
            }

            for (uint256 i = 0; i < rwaX[_rwaType][_version].length; i++) {
                if (rwaX[_rwaType][_version][i].chainIdStr.equal(chainIdStr)) {
                    rwaX[_rwaType][_version][i].contractStr = rwaXAddrStr;
                    preExisted = true;
                }
            }

            if (!preExisted) {
                ChainContract memory newAttach = ChainContract(chainIdStr, rwaXAddrStr);
                rwaX[_rwaType][_version].push(newAttach);
                rwaXChains[_rwaType][_version].push(chainIdStr);
                preExisted = false;
            }
        }

        return (true);
    }

    /**
     * @notice Governor function. Attach new CTMRWA1StorageManager contracts for chainIds, including the local chainId
     * @param _rwaType The type of RWA. CTMRWA1 is 1
     * @param _version The version of this RWA type. Currently only 1 is in use
     * @param _chainIdsStr Array of chainIds converted to strings
     * @param _storageManagerAddrsStr Array of the CTMRWA1StorageManager contract addresses
     * converted to strings
     * @return success True if the addresses were added successfully.
     * NOTE The local chainId is at index 0.
     */
    function attachStorageManager(
        uint256 _rwaType,
        uint256 _version,
        string[] memory _chainIdsStr,
        string[] memory _storageManagerAddrsStr
    ) external onlyGov returns (bool) {
        if (_chainIdsStr.length == 0 || _storageManagerAddrsStr.length == 0) {
            revert CTMRWAGateway_InvalidLength(CTMRWAErrorParam.Input);
        }

        if (_chainIdsStr.length != _storageManagerAddrsStr.length) {
            revert CTMRWAGateway_LengthMismatch(CTMRWAErrorParam.Input);
        }

        bool preExisted;

        for (uint256 j = 0; j < _chainIdsStr.length; j++) {
            _chainIdsStr[j]._checkStringLength(64);
            _storageManagerAddrsStr[j]._checkStringLength(64);
            string memory storageManagerAddrStr = _storageManagerAddrsStr[j]._toLower();
            string memory chainIdStr = _chainIdsStr[j]._toLower();

            for (uint256 i = 0; i < storageManager[_rwaType][_version].length; i++) {
                if (storageManager[_rwaType][_version][i].chainIdStr.equal(chainIdStr)) {
                    storageManager[_rwaType][_version][i].contractStr = storageManagerAddrStr;
                    preExisted = true;
                }
            }

            if (!preExisted) {
                ChainContract memory newAttach = ChainContract(chainIdStr, storageManagerAddrStr);
                storageManager[_rwaType][_version].push(newAttach);
                preExisted = false;
            }
        }

        return (true);
    }

    /**
     * @notice Governor function. Attach new CTMRWA1SentryManager contracts for chainIds, including the local chainId
     * @param _rwaType The type of RWA. CTMRWA1 is 1
     * @param _version The version of this RWA type. Currently only 1 is in use
     * @param _chainIdsStr Array of chainIds converted to strings
     * @param _sentryManagerAddrsStr Array of the CTMRWA1SentryManager contract addresses
     * converted to strings
     * @return success True if the addresses were added successfully.
     * NOTE The local chainId is at index 0.
     */
    function attachSentryManager(
        uint256 _rwaType,
        uint256 _version,
        string[] memory _chainIdsStr,
        string[] memory _sentryManagerAddrsStr
    ) external onlyGov returns (bool) {
        if (_chainIdsStr.length == 0 || _sentryManagerAddrsStr.length == 0) {
            revert CTMRWAGateway_InvalidLength(CTMRWAErrorParam.Input);
        }

        if (_chainIdsStr.length != _sentryManagerAddrsStr.length) {
            revert CTMRWAGateway_LengthMismatch(CTMRWAErrorParam.Input);
        }

        bool preExisted;

        for (uint256 j = 0; j < _chainIdsStr.length; j++) {
            _chainIdsStr[j]._checkStringLength(64);
            _sentryManagerAddrsStr[j]._checkStringLength(64);
            string memory sentryManagerAddrStr = _sentryManagerAddrsStr[j]._toLower();
            string memory chainIdStr = _chainIdsStr[j]._toLower();

            for (uint256 i = 0; i < sentryManager[_rwaType][_version].length; i++) {
                if (sentryManager[_rwaType][_version][i].chainIdStr.equal(chainIdStr)) {
                    sentryManager[_rwaType][_version][i].contractStr = sentryManagerAddrStr;
                    preExisted = true;
                }
            }

            if (!preExisted) {
                ChainContract memory newAttach = ChainContract(chainIdStr, sentryManagerAddrStr);
                sentryManager[_rwaType][_version].push(newAttach);
                preExisted = false;
            }
        }

        return (true);
    }

    function cID() internal view returns (uint256) {
        return block.chainid;
    }

    /// @dev Fallback function for a failed c3call. Only logs an event at present
    /// @return success True if the fallback was successful, false otherwise.
    function _c3Fallback(bytes4 _selector, bytes calldata _data, bytes calldata _reason)
        internal
        override
        returns (bool)
    {
        emit LogFallback(_selector, _data, _reason);
        return true;
    }
}
