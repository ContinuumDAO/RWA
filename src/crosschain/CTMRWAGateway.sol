// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {C3GovernDapp} from "@c3caller/gov/C3GovernDapp.sol";

import {ChainContract} from "../crosschain/ICTMRWAGateway.sol";

/**
 * @title AssetX Multi-chain Semi-Fungible-Token for Real-World-Assets (RWAs)
 * @author @Selqui ContinuumDAO
 *
 * @notice This contract is the gateway between any blockchain that can have an RWA deployed
 * to it. It stores the contract addresses of CTMRWAGateway contracts on other chians, as well
 * as the contract addresses of CTMRWA1X, CTMRWA1StorageManager and CTMRWA1SentryMananager
 * contracts. This enables c3calls to be made between all the c3Caller dApps that make up AssetX
 *
 * This contract is only deployed ONCE on each chain and manages all CTMRWA1 contract interactions
 */

contract CTMRWAGateway is Context, C3GovernDapp {
    using Strings for *;

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

    
    /// @dev  This array holds ChainContract structs for all chains
    ChainContract[] public chainContract;

    constructor(
        address _gov,
        address _c3callerProxy,
        address _txSender,
        uint256 _dappID
    ) C3GovernDapp(_gov, _c3callerProxy, _txSender, _dappID) {
        cIdStr = cID().toString();
        _addChainContract(cID(), address(this));
    }

    /// @dev Adds the address of a CTMRWAGateway contract on another chainId
    function _addChainContract(uint256 _chainId, address _contractAddr) internal  {
        string memory newChainIdStr = _chainId.toString();
        string memory contractStr = _toLower(_contractAddr.toHexString());

        chainContract.push(ChainContract(newChainIdStr, contractStr));
    }

    /**
     * @notice Governor function to add addresses of CTMRWAGateway contracts on other chains.
     * @dev All input address are arrays of strings
     */
    function addChainContract(string[] memory _newChainIdsStr, string[] memory _contractAddrsStr) external onlyGov returns (bool) {
        require(_newChainIdsStr.length == _contractAddrsStr.length, "CTMRWAGateway: Argument lengths not equal");

        bool preExisted;
        
        for(uint256 j=0; j<_newChainIdsStr.length; j++) {
            string memory newChainIdStr = _toLower(_newChainIdsStr[j]);
            string memory contractAddrStr = _toLower(_contractAddrsStr[j]);

            for(uint256 i=0; i<chainContract.length; i++) {
                if(stringsEqual(chainContract[i].chainIdStr, newChainIdStr)) {
                    chainContract[i].contractStr = contractAddrStr;
                    preExisted = true;
                }
            }

            if(!preExisted) {
                chainContract.push(ChainContract(newChainIdStr, contractAddrStr));
                preExisted = false;
            }
        }

        return(true);
    }

    /**
     * @notice Get the address string for a CTMRWAGateway contract on another chainId
     * @param _chainIdStr The chainId converted to a string
     */
    function getChainContract(string memory _chainIdStr) external view returns(string memory) {
        for(uint256 i=0; i<chainContract.length; i++) {
            if(stringsEqual(chainContract[i].chainIdStr, _toLower(_chainIdStr))) {
                return(chainContract[i].contractStr);
            }
        }
        return("");
    }

    /**
     * @notice Get the chainId and address of a CTMRWAGateway contract at an index _pos
     * @param _pos The index into the stored array
     */
    function getChainContract(uint256 _pos) public view returns(string memory, string memory) {
        return(chainContract[_pos].chainIdStr, chainContract[_pos].contractStr);
    }

    /// @notice Get the number of stored chainIds and CTMRWAGateway pairs stored
    function getChainCount() public view returns(uint256) {
        return(chainContract.length);
    }

    /**
     * @notice Get all the chainIds of all CTMRWA1X contracts
     * @param _rwaType The type of RWA. CTMRWA1 is 1
     * @param _version The version of this RWA type. Currently only 1 is in use
     */
    function getAllRwaXChains(
        uint256 _rwaType,
        uint256 _version
    ) public view returns(string[] memory) {
        return(rwaXChains[_rwaType][_version]);
    }

    /**
     * @notice Check the existence of a stored CTMRWA1X contract on chainId _chainIdStr
     * @param _rwaType The type of RWA. CTMRWA1 is 1
     * @param _version The version of this RWA type. Currently only 1 is in use
     * @param _chainIdStr The chainId converted to a string to check for
     */
    function existRwaXChain(uint256 _rwaType, uint256 _version, string memory _chainIdStr) public view returns(bool) {
        for(uint256 i=0; i < rwaXChains[_rwaType][_version].length; i++) {
            if(stringsEqual(rwaXChains[_rwaType][_version][i], _toLower(_chainIdStr))) return(true);
        }
        return(false);
    }

    /**
     * @notice Return all chainIds as an array and the corresponding CTMRWA1X contract addresses
     * as another array at an index position
     * @param _rwaType The type of RWA. CTMRWA1 is 1
     * @param _version The version of this RWA type. Currently only 1 is in use
     * @param _indx The index position to return data from
     */
    function getAttachedRWAX(
        uint256 _rwaType,
        uint256 _version,
        uint256 _indx
    ) public view returns(string memory, string memory) {
        return(
            rwaX[_rwaType][_version][_indx].chainIdStr,
            rwaX[_rwaType][_version][_indx].contractStr
        );
    }

    /**
     * @notice get the total number of stored CTMRWA1X contracts for all chainIds (including this one)
     * @param _rwaType The type of RWA. CTMRWA1 is 1
     * @param _version The version of this RWA type. Currently only 1 is in use
     */
    function getRWAXCount(
        uint256 _rwaType,
        uint256 _version
    ) public view returns(uint256) {
        return(rwaX[_rwaType][_version].length);
    }
        
    /**
     * @notice Get the attached CTMRWA1X contract address for chainId _chainIdStr as a string
     * @param _rwaType The type of RWA. CTMRWA1 is 1
     * @param _version The version of this RWA type. Currently only 1 is in use
     * @param _chainIdStr The chainId (as a string) being examined
     */
    function getAttachedRWAX(
        uint256 _rwaType,
        uint256 _version,
        string memory _chainIdStr
    ) public view returns(bool, string memory) {

        for(uint256 i=0; i<rwaX[_rwaType][_version].length; i++) {
            if(stringsEqual(rwaX[_rwaType][_version][i].chainIdStr, _chainIdStr)) {
                return(true, rwaX[_rwaType][_version][i].contractStr);
            }
        }

        return(false, "0");
    }

    /**
     * @notice Return all chainIds as an array and the corresponding CTMRWA1StorageManager
     * contract addresses as another array at an index position
     * @param _rwaType The type of RWA. CTMRWA1 is 1
     * @param _version The version of this RWA type. Currently only 1 is in use
     * @param _indx The index position to return data from
     */
    function getAttachedStorageManager(
        uint256 _rwaType,
        uint256 _version,
        uint256 _indx
    ) public view returns(string memory, string memory) {
        return(
            storageManager[_rwaType][_version][_indx].chainIdStr,
            storageManager[_rwaType][_version][_indx].contractStr
        );
    }

    /**
     * @notice get the total number of stored CTMRWA1StorageManager contracts for all
     * chainIds (including this one)
     * @param _rwaType The type of RWA. CTMRWA1 is 1
     * @param _version The version of this RWA type. Currently only 1 is in use
     */
    function getStorageManagerCount(
        uint256 _rwaType,
        uint256 _version
    ) public view returns(uint256) {
        return(storageManager[_rwaType][_version].length);
    }

    /**
     * @notice Get the attached CTMRWA1StorageManager contract address for chainId _chainIdStr
     * as a string
     * @param _rwaType The type of RWA. CTMRWA1 is 1
     * @param _version The version of this RWA type. Currently only 1 is in use
     * @param _chainIdStr The chainId (as a string) being examined
     */
    function getAttachedStorageManager(
        uint256 _rwaType,
        uint256 _version,
        string memory _chainIdStr
    ) public view returns(bool, string memory) {

        for(uint256 i=0; i<storageManager[_rwaType][_version].length; i++) {
            if(stringsEqual(storageManager[_rwaType][_version][i].chainIdStr, _chainIdStr)) {
                return(true, storageManager[_rwaType][_version][i].contractStr);
            }
        }

        return(false, "0");
    }

    /**
     * @notice Return all chainIds as an array and the corresponding CTMRWA1SentryManager
     * contract addresses as another array at an index position
     * @param _rwaType The type of RWA. CTMRWA1 is 1
     * @param _version The version of this RWA type. Currently only 1 is in use
     * @param _indx The index position to return data from
     */
    function getAttachedSentryManager(
        uint256 _rwaType,
        uint256 _version,
        uint256 _indx
    ) public view returns(string memory, string memory) {
        return(
            sentryManager[_rwaType][_version][_indx].chainIdStr,
            sentryManager[_rwaType][_version][_indx].contractStr
        );
    }

    /**
     * @notice get the total number of stored CTMRWA1SentryManager contracts for all
     * chainIds (including this one)
     * @param _rwaType The type of RWA. CTMRWA1 is 1
     * @param _version The version of this RWA type. Currently only 1 is in use
     */
    function getSentryManagerCount(
        uint256 _rwaType,
        uint256 _version
    ) public view returns(uint256) {
        return(sentryManager[_rwaType][_version].length);
    }

    /**
     * @notice Get the attached CTMRWA1SentryManager contract address for chainId _chainIdStr
     * as a string
     * @param _rwaType The type of RWA. CTMRWA1 is 1
     * @param _version The version of this RWA type. Currently only 1 is in use
     * @param _chainIdStr The chainId (as a string) being examined
     */
    function getAttachedSentryManager(
        uint256 _rwaType,
        uint256 _version,
        string memory _chainIdStr
    ) public view returns(bool, string memory) {

        for(uint256 i=0; i<sentryManager[_rwaType][_version].length; i++) {
            if(stringsEqual(sentryManager[_rwaType][_version][i].chainIdStr, _chainIdStr)) {
                return(true, sentryManager[_rwaType][_version][i].contractStr);
            }
        }

        return(false, "0");
    }

    /**
     * @notice Governor function. Attach new CTMRWA1X contracts for chainIds
     * @param _rwaType The type of RWA. CTMRWA1 is 1
     * @param _version The version of this RWA type. Currently only 1 is in use
     * @param _chainIdsStr Array of chainIds converted to strings
     * @param _rwaXAddrsStr Array of the CTMRWA1X contract addresses converted to strings
     */
    function attachRWAX (
        uint256 _rwaType,
        uint256 _version,
        string[] memory _chainIdsStr, 
        string[] memory _rwaXAddrsStr
    ) external onlyGov returns(bool) {
        require(_chainIdsStr.length == _rwaXAddrsStr.length, "CTMRWAGateway: Argument lengths not equal in attachRWAX");

        bool preExisted;

        for(uint256 j=0; j<_chainIdsStr.length; j++) {

            string memory rwaXAddrStr = _toLower(_rwaXAddrsStr[j]);
            string memory chainIdStr = _toLower(_chainIdsStr[j]);

            require(bytes(rwaXAddrStr).length == 42, "CTMRWAGateway: Incorrect address length");

            for(uint256 i=0; i<rwaX[_rwaType][_version].length; i++) {
                if(stringsEqual(rwaX[_rwaType][_version][i].chainIdStr, chainIdStr)) {
                    rwaX[_rwaType][_version][i].contractStr = rwaXAddrStr;
                    preExisted = true;
                }
            }

            if(!preExisted) {
                ChainContract memory newAttach = ChainContract(chainIdStr, rwaXAddrStr);
                rwaX[_rwaType][_version].push(newAttach);
                rwaXChains[_rwaType][_version].push(chainIdStr);
                preExisted = false;
            }
        }

        return(true);
    }

    /**
     * @notice Governor function. Attach new CTMRWA1StorageManager contracts for chainIds
     * @param _rwaType The type of RWA. CTMRWA1 is 1
     * @param _version The version of this RWA type. Currently only 1 is in use
     * @param _chainIdsStr Array of chainIds converted to strings
     * @param _storageManagerAddrsStr Array of the CTMRWA1StorageManager contract addresses 
     * converted to strings
     */
    function attachStorageManager (
        uint256 _rwaType,
        uint256 _version,
        string[] memory _chainIdsStr, 
        string[] memory _storageManagerAddrsStr
    ) external onlyGov returns(bool) {
        require(_chainIdsStr.length == _storageManagerAddrsStr.length, "CTMRWAGateway: Argument lengths not equal in attachStorageManager");

        bool preExisted;

        for(uint256 j=0; j<_chainIdsStr.length; j++) {
            string memory storageManagerAddrStr = _toLower(_storageManagerAddrsStr[j]);
            string memory chainIdStr = _toLower(_chainIdsStr[j]);

            require(bytes(storageManagerAddrStr).length == 42, "CTMRWAGateway: Incorrect address length");

            for(uint256 i=0; i<storageManager[_rwaType][_version].length; i++) {
                if(stringsEqual(storageManager[_rwaType][_version][i].chainIdStr, chainIdStr)) {
                    storageManager[_rwaType][_version][i].contractStr = storageManagerAddrStr;
                    preExisted = true;
                }
            }

            if(!preExisted) {
                ChainContract memory newAttach = ChainContract(chainIdStr, storageManagerAddrStr);
                storageManager[_rwaType][_version].push(newAttach);
                preExisted = false;
            }
        }

        return(true);
    }

    /**
     * @notice Governor function. Attach new CTMRWA1SentryManager contracts for chainIds
     * @param _rwaType The type of RWA. CTMRWA1 is 1
     * @param _version The version of this RWA type. Currently only 1 is in use
     * @param _chainIdsStr Array of chainIds converted to strings
     * @param _sentryManagerAddrsStr Array of the CTMRWA1SentryManager contract addresses 
     * converted to strings
     */
    function attachSentryManager (
        uint256 _rwaType,
        uint256 _version,
        string[] memory _chainIdsStr, 
        string[] memory _sentryManagerAddrsStr
    ) external onlyGov returns(bool) {
        require(_chainIdsStr.length == _sentryManagerAddrsStr.length, "CTMRWAGateway: Argument lengths not equal in attachSentryManager");

        bool preExisted;

        for(uint256 j=0; j<_chainIdsStr.length; j++) {
            string memory sentryManagerAddrStr = _toLower(_sentryManagerAddrsStr[j]);
            string memory chainIdStr = _toLower(_chainIdsStr[j]);

            require(bytes(sentryManagerAddrStr).length == 42, "CTMRWAGateway: Incorrect address length");

            for(uint256 i=0; i<sentryManager[_rwaType][_version].length; i++) {
                if(stringsEqual(sentryManager[_rwaType][_version][i].chainIdStr, chainIdStr)) {
                    sentryManager[_rwaType][_version][i].contractStr = sentryManagerAddrStr;
                    preExisted = true;
                }
            }

            if(!preExisted) {
                ChainContract memory newAttach = ChainContract(chainIdStr, sentryManagerAddrStr);
                sentryManager[_rwaType][_version].push(newAttach);
                preExisted = false;
            }
        }

        return(true);
    }

    function cID() internal view returns (uint256) {
        return block.chainid;
    }

    /// @dev Convert a string to an EVM address. Also checks the string length
    function stringToAddress(string memory str) internal pure returns (address) {
        bytes memory strBytes = bytes(str);
        require(strBytes.length == 42, "CTMRWA1X: Invalid address length");
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
    
    /// @dev Fallback function for a failed c3call. Only logs an event at present
    function _c3Fallback(bytes4 _selector,
        bytes calldata _data,
        bytes calldata _reason) internal override returns (bool) {


        emit LogFallback(_selector, _data, _reason);
        return true;
    }

}
