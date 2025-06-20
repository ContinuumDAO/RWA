// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";


import{ICTMRWAAttachment} from "./interfaces/ICTMRWAMap.sol";



/**
 * @title AssetX Multi-chain Semi-Fungible-Token for Real-World-Assets (RWAs)
 * @author @Selqui ContinuumDAO
 *
 * @notice This contract links together the various parts of the CTMRWA001 RWA.
 * For every ID, which is unique to one RWA, there are different contracts as follows -
 *
 * (1) The CTMRWA001 contract itself, which is the Semi-Fungible-Token
 * (2) A Dividend contract called CTMRWA001Dividend
 * (3) A Storage contract called CTMRWA001Storage
 * (4) A Sentry contract called CTMRWA001Sentry
 *
 * This set all share a single ID, which is the same on all chains that the RWA is deployed to
 * The whole set is deployed by CTMRWADeployer.
 * This contract, deployed just once on each chain, stores the state linking the ID to each of the 
 * constituent contract addresses. The links from the contract addresses back to the ID are also stored.
 *
 * The 'attach' functions are called by CTMRWADeployer when the contracts are deployed.
 */


/// @dev rwaType is the RWA type defining CTMRWA001
uint256 constant rwaType = 1;

/// @dev version is the single integer version of this RWA type
uint256 constant version = 1;

contract CTMRWAMap is Context {
    using Strings for *;

    /// @dev Address of the CTMRWAGateway contract
    address public gateway;

    /// @dev Address of the CTMRWADeployer contract
    address public ctmRwaDeployer;

    /// @dev Address of the CTMRWA001X contract
    address public ctmRwa001X;

    /// @dev String representation of the local chainID
    string cIdStr;

    /// @dev ID => address of CTMRWA001 contract as string
    mapping(uint256 => string) idToContract;

    /// @dev address of CTMRWA001 contract as string => ID
    mapping(string => uint256) contractToId;


    /// @dev ID => CTMRWA001Dividend contract as string
    mapping(uint256 => string) idToDividend;

    /// @dev CTMRWA001Dividend contract as string => ID
    mapping(string => uint256) dividendToId;


    /// @dev ID => CTMRWA001Storage contract as string
    mapping(uint256 => string) idToStorage;

    /// @dev CTMRWA001Storage contract as string => ID
    mapping(string => uint256) storageToId;


    /// @dev ID => CTMRWA001Sentry contract as string
    mapping(uint256 => string) idToSentry;

    /// @dev CTMRWA001Sentry contract as string => ID
    mapping(string => uint256) sentryToId;


    /// @dev ID => CTMRWADeployInvest contract as string
    mapping(uint256 => string) idToInvest;

    /// @dev CTMRWADeployInvest contract as string => ID
    mapping(string => uint256) investToId;


    constructor(
        address _gateway,
        address _rwa001X
    ) {
        gateway = _gateway;
        ctmRwa001X = _rwa001X;
        cIdStr = cID().toString();
    }

    modifier onlyDeployer {
        require(
            _msgSender() == ctmRwaDeployer,
            "CTMRWAMap: This is an onlyDeployer function"
        );
        _;
    }

    modifier onlyRwa001X {
        require(
            _msgSender() == ctmRwa001X,
            "CTMRWAMap: This is an onlyRwa001X function"
        );
        _;
    }

    /**
     * @dev Set the addresses of CTMRWADeployer, CTMRWAGateway and CTMRWA001X
     * NOTE Can only be called by the setMap function in CTMRWA001X, called by Governor
     */
    function setCtmRwaDeployer(
        address _deployer,
        address _gateway,
        address _rwa001X
    ) external onlyRwa001X {
        ctmRwaDeployer = _deployer;
        gateway = _gateway;
        ctmRwa001X = _rwa001X;
    }

    /**
     * @notice Return the ID of a given CTMRWA001 contract
     * NOTE The input address is a string.
     * NOTE The function also returns a boolean ok, which is false if the ID does not exist
     * @param _tokenAddrStr String version of the CTMRWA001 contract address
     * @param _rwaType The type of RWA. Must be 1 here, to match CTMRWA001
     * @param _version The version of this RWA. Latest version is 1
     */
    function getTokenId(string memory _tokenAddrStr, uint256 _rwaType, uint256 _version) public view returns(bool, uint256) {
        require(_rwaType == rwaType && _version == version, "CTMRWAMap: incorrect RWA type or version");

        string memory tokenAddrStr = _toLower(_tokenAddrStr);

        uint256 id = contractToId[tokenAddrStr];
        return (id != 0, id);
    }

    /**
     * @notice Return the CTMRWA001 contract address for a given ID
     * NOTE The function also returns a boolean ok, which is false if the ID does not exist
     * @param _ID The ID being examined
     * @param _rwaType The type of RWA. Must be 1 here, to match CTMRWA001
     * @param _version The version of this RWA. Latest version is 1
     */
    function getTokenContract(uint256 _ID, uint256 _rwaType, uint256 _version) public view returns(bool, address) {
        require(_rwaType == rwaType && _version == version, "CTMRWAMap: incorrect RWA type or version");

        string memory _contractStr = idToContract[_ID];
        return bytes(_contractStr).length != 0 
            ? (true, stringToAddress(_contractStr)) 
            : (false, address(0));
    }

    /**
     * @notice Return the CTMRWA001Dividend contract address for a given ID
     * NOTE The function also returns a boolean ok, which is false if the ID does not exist
     * @param _ID The ID being examined
     * @param _rwaType The type of RWA. Must be 1 here, to match CTMRWA001
     * @param _version The version of this RWA. Latest version is 1
     */
    function getDividendContract(uint256 _ID, uint256 _rwaType, uint256 _version) public view returns(bool, address) {
        require(_rwaType == rwaType && _version == version, "CTMRWAMap: incorrect RWA type or version");

        string memory _dividendStr = idToDividend[_ID];
        return bytes(_dividendStr).length != 0 
            ? (true, stringToAddress(_dividendStr)) 
            : (false, address(0));
    }

    /**
     * @notice Return the CTMRWA001Storage contract address for a given ID
     * NOTE The function also returns a boolean ok, which is false if the ID does not exist
     * @param _ID The ID being examined
     * @param _rwaType The type of RWA. Must be 1 here, to match CTMRWA001
     * @param _version The version of this RWA. Latest version is 1
     */
    function getStorageContract(uint256 _ID, uint256 _rwaType, uint256 _version) public view returns(bool, address) {
        require(_rwaType == rwaType && _version == version, "CTMRWAMap: incorrect RWA type or version");

        string memory _storageStr = idToStorage[_ID];
        return bytes(_storageStr).length != 0 
            ? (true, stringToAddress(_storageStr)) 
            : (false, address(0));
    }

    /**
     * @notice Return the CTMRWA001Sentry contract address for a given ID
     * NOTE The function also returns a boolean ok, which is false if the ID does not exist
     * @param _ID The ID being examined
     * @param _rwaType The type of RWA. Must be 1 here, to match CTMRWA001
     * @param _version The version of this RWA. Latest version is 1
     */
    function getSentryContract(uint256 _ID, uint256 _rwaType, uint256 _version) public view returns(bool, address) {
        require(_rwaType == rwaType && _version == version, "CTMRWAMap: incorrect RWA type or version");

        string memory _sentryStr = idToSentry[_ID];
        return bytes(_sentryStr).length != 0 
            ? (true, stringToAddress(_sentryStr)) 
            : (false, address(0));
    }

    function getInvestContract(
        uint256 _ID, 
        uint256 _rwaType, 
        uint256 _version
    ) public view returns(bool, address) {
        require(_rwaType == rwaType && _version == version, "CTMRWAMap: incorrect RWA type or version");

        string memory _investStr = idToInvest[_ID];
        return bytes(_investStr).length != 0 
            ? (true, stringToAddress(_investStr)) 
            : (false, address(0));
    }

    /**
     * @dev This function is called by CTMRWADeployer after the deployment of the
     * CTMRWA001, CTMRWA001Dividend, CTMRWA001Storage and CTMRWA001Sentry contracts on a chain.
     * It links them together by setting the same ID for the one RWA and storing their
     * contract addresses.
     */
    function attachContracts(
        uint256 _ID, 
        uint256 _rwaType, 
        uint256 _version,
        address _tokenAddr, 
        address _dividendAddr, 
        address _storageAddr,
        address _sentryAddr
    ) external onlyDeployer {
        require(_rwaType == rwaType && _version == version, "CTMRWAMap: incorrect RWA type or version");

        bool ok = _attachCTMRWAID(
            _ID,
            _tokenAddr,
            _dividendAddr, 
            _storageAddr,
            _sentryAddr
        );
        require(ok, "CTMRWAMap: Failed to set token ID");

        ok = ICTMRWAAttachment(_tokenAddr).attachDividend(_dividendAddr);
        require(ok, "CTMRWAMap: Failed to set the dividend contract address");

        ok = ICTMRWAAttachment(_tokenAddr).attachStorage(_storageAddr);
        require(ok, "CTMRWAMap: Failed to set the storage contract address");

        ok = ICTMRWAAttachment(_tokenAddr).attachSentry(_sentryAddr);
        require(ok, "CTMRWAMap: Failed to set the sentry contract address");

    }

    function setInvestmentContract(
        uint256 _ID, 
        uint256 _rwaType, 
        uint256 _version, 
        address _investAddr
    ) external onlyDeployer returns(bool) {
        require(_rwaType == rwaType && _version == version, "CTMRWAMap: incorrect RWA type or version");

        string memory investAddrStr = _toLower(_investAddr.toHexString());

        uint256 lenContract = bytes(idToInvest[_ID]).length;

        if(lenContract > 0 || investToId[investAddrStr] != 0) {
            return(false);
        } else {
            idToInvest[_ID] = investAddrStr;
            investToId[investAddrStr] = _ID;

            return(true);
        }
    }

    /// @dev Internal helper function for attachContracts
    function _attachCTMRWAID(
        uint256 _ID, 
        address _ctmRwaAddr,
        address _dividendAddr, 
        address _storageAddr,
        address _sentryAddr
    ) internal returns(bool) {

        string memory ctmRwaAddrStr = _toLower(_ctmRwaAddr.toHexString());
        string memory dividendAddr = _toLower(_dividendAddr.toHexString());
        string memory storageAddr = _toLower(_storageAddr.toHexString());
        string memory sentryAddr = _toLower(_sentryAddr.toHexString());

        uint256 lenContract = bytes(idToContract[_ID]).length;

        if(lenContract > 0 || contractToId[ctmRwaAddrStr] != 0) {
            return(false);
        } else {
            idToContract[_ID] = ctmRwaAddrStr;
            contractToId[ctmRwaAddrStr] = _ID;

            idToDividend[_ID] = dividendAddr;
            dividendToId[dividendAddr] = _ID;

            idToStorage[_ID] = storageAddr;
            storageToId[storageAddr] = _ID;

            idToSentry[_ID] = sentryAddr;
            sentryToId[sentryAddr] = _ID;

            return(true);
        }
    }

    function cID() internal view returns (uint256) {
        return block.chainid;
    }

    /// @dev Convert a string to an EVM address. Also checks the string length
    function stringToAddress(string memory str) internal pure returns (address) {
        bytes memory strBytes = bytes(str);
        require(strBytes.length == 42, "CTMRWA001X: Invalid address length");
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
    
    /// @dev Convert an individual string to an array with a single value
    function _stringToArray(string memory _string) internal pure returns(string[] memory) {
        string[] memory strArray = new string[](1);
        strArray[0] = _string;
        return(strArray);
    }
   

}