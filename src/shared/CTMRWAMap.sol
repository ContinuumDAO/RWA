// SPDX-License-Identifier: BSL-1.1

pragma solidity 0.8.27;

import { ICTMRWA } from "../core/ICTMRWA.sol";
import { CTMRWAUtils, CTMRWAErrorParam } from "../utils/CTMRWAUtils.sol";
import { ICTMRWAAttachment, ICTMRWAMap } from "./ICTMRWAMap.sol";
import { C3GovernDAppUpgradeable } from "@c3caller/upgradeable/gov/C3GovernDAppUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title AssetX Multi-chain Semi-Fungible-Token for Real-World-Assets (RWAs)
 * @author @Selqui ContinuumDAO
 *
 * @notice This contract links together the various parts of the CTMRWA1 token.
 * For every ID, which is unique to one CTMRWA token, there are different contracts as follows -
 *
 * (1) The CTMRWA1 contract itself, which is the Semi-Fungible-Token
 * (2) A Dividend contract called CTMRWA1Dividend
 * (3) A Storage contract called CTMRWA1Storage
 * (4) A Sentry contract called CTMRWA1Sentry
 * (5) A Investment contract called CTMRWADeployInvest
 * (6) A ERC20 contract called CTMRWAERC20
 *
 * This set all share a single ID, which is the same on all chains that the CTMRWA token is deployed to
 * The whole set is deployed by CTMRWADeployer.
 * This contract, deployed just once on each chain, stores the state linking the ID to each of the
 * constituent contract addresses. The links from the contract addresses back to the ID are also stored.
 *
 * The 'attach' functions are called by CTMRWADeployer when the contracts are deployed.
 */
contract CTMRWAMap is ICTMRWAMap, C3GovernDAppUpgradeable, UUPSUpgradeable {
    using Strings for *;
    using CTMRWAUtils for string;

    /// @dev CTMRWA of the CTMRWAGateway contract
    address public gateway;

    /// @dev CTMRWA of the CTMRWADeployer contract
    address public ctmRwaDeployer;

    /// @dev CTMRWA of the CTMRWA1X contract
    address public ctmRwa1X;

    /// @dev String representation of the local chainID
    string cIdStr;

    /// @dev ID => address of CTMRWA1 contract as string
    mapping(uint256 => string) idToContract;

    /// @dev address of CTMRWA1 contract as string => ID
    mapping(string => uint256) contractToId;

    /// @dev ID => CTMRWA1Dividend contract as string
    mapping(uint256 => string) idToDividend;

    /// @dev CTMRWA1Dividend contract as string => ID
    mapping(string => uint256) dividendToId;

    /// @dev ID => CTMRWA1Storage contract as string
    mapping(uint256 => string) idToStorage;

    /// @dev CTMRWA1Storage contract as string => ID
    mapping(string => uint256) storageToId;

    /// @dev ID => CTMRWA1Sentry contract as string
    mapping(uint256 => string) idToSentry;

    /// @dev CTMRWA1Sentry contract as string => ID
    mapping(string => uint256) sentryToId;

    /// @dev ID => CTMRWADeployInvest contract as string
    mapping(uint256 => string) idToInvest;

    /// @dev CTMRWADeployInvest contract as string => ID
    mapping(string => uint256) investToId;

    /// @dev ID => slot => CTMRWAERC20 contract as string
    mapping(uint256 => mapping(uint256 => string)) idToErc20;

    /// @dev slot => CTMRWAERC20 contract as string => ID
    mapping(uint256 => mapping(string => uint256)) erc20ToId;

    event LogFallback(bytes4 selector, bytes data, bytes reason);

    function initialize(
        address _gov,
        address _c3callerProxy,
        address _txSender,
        uint256 _dappID,
        address _gateway,
        address _rwa1X
    ) external initializer {
        __C3GovernDApp_init(_gov, _c3callerProxy, _txSender, _dappID);
        gateway = _gateway;
        ctmRwa1X = _rwa1X;
        cIdStr = cID().toString();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyGov { }

    modifier onlyDeployer() {
        if (msg.sender != ctmRwaDeployer) {
            revert CTMRWAMap_OnlyAuthorized(CTMRWAErrorParam.Sender, CTMRWAErrorParam.Deployer);
        }
        _;
    }

    modifier onlyRwa1X() {
        if (msg.sender != ctmRwa1X) {
            revert CTMRWAMap_OnlyAuthorized(CTMRWAErrorParam.Sender, CTMRWAErrorParam.RWAX);
        }
        _;
    }

    /**
     * @dev Set the addresses of CTMRWADeployer, CTMRWAGateway and CTMRWA1X
     * NOTE Can only be called by the setMap function in CTMRWA1X, called by Governor
     */
    function setCtmRwaDeployer(address _deployer, address _gateway, address _rwa1X) external onlyRwa1X {
        if (_deployer == address(0)) {
            revert CTMRWAMap_IsZeroAddress(CTMRWAErrorParam.Deployer);
        }
        if (_gateway == address(0)) {
            revert CTMRWAMap_IsZeroAddress(CTMRWAErrorParam.Gateway);
        }
        if (_rwa1X == address(0)) {
            revert CTMRWAMap_IsZeroAddress(CTMRWAErrorParam.RWAX);
        }

        ctmRwaDeployer = _deployer;
        gateway = _gateway;
        ctmRwa1X = _rwa1X;
    }

    /**
     * @notice Return the ID of a given CTMRWA1 contract
     * NOTE The input address is a string.
     * NOTE The function also returns a boolean ok, which is false if the ID does not exist
     * @param _tokenAddrStr String version of the CTMRWA1 contract address
     * @param _rwaType The type of CTMRWA. Must be 1 here, to match CTMRWA1
     * @param _version The version of this CTMRWAErrorParam. Latest version is 1
     * @return ok True if the ID exists, false otherwise
     * @return tuple (ok, id) ok True if the ID exists, false otherwise, id The ID of the CTMRWA1 contract
     */
    function getTokenId(string memory _tokenAddrStr, uint256 _rwaType, uint256 _version)
        public
        view
        virtual
        returns (bool, uint256)
    {
        string memory tokenAddrStr = _tokenAddrStr._toLower();

        uint256 id = contractToId[tokenAddrStr];
        if (id == 0) {
            return (false, 0);
        }
        bool ok = _checkRwaTypeVersion(tokenAddrStr, _rwaType, _version);
        return (ok, id);
    }

    /**
     * @notice Return the CTMRWA1 contract address for a given ID
     * NOTE The function also returns a boolean ok, which is false if the ID does not exist
     * @param _ID The ID being examined
     * @param _rwaType The type of CTMRWA. Must be 1 here, to match CTMRWA1
     * @param _version The version of this CTMRWAErrorParam. Latest version is 1
     * @return ok True if the ID exists, false otherwise
     * @return tuple (ok, contractAddr) ok True if the ID exists, false otherwise, contractAddr The address of the CTMRWA1 contract
     */
    function getTokenContract(uint256 _ID, uint256 _rwaType, uint256 _version) public view returns (bool, address) {
        string memory contractStr = idToContract[_ID];
        // INFO: Revert if non-matching rwaType and version for given ID
        bool ok = _checkRwaTypeVersion(contractStr, _rwaType, _version);
        return ok ? (true, contractStr._stringToAddress()) : (false, address(0));
    }

    /**
     * @notice Return the CTMRWA1Dividend contract address for a given ID
     * NOTE The function also returns a boolean ok, which is false if the ID does not exist
     * @param _ID The ID being examined
     * @param _rwaType The type of CTMRWA. Must be 1 here, to match CTMRWA1
     * @param _version The version of this CTMRWAErrorParam. Latest version is 1
     * @return ok True if the ID exists, false otherwise
     * @return tuple (ok, dividendAddr) ok True if the ID exists, false otherwise, dividendAddr The address of the CTMRWA1Dividend contract
     */
    function getDividendContract(uint256 _ID, uint256 _rwaType, uint256 _version) public view returns (bool, address) {
        string memory _dividendStr = idToDividend[_ID];
        bool ok = _checkRwaTypeVersion(_dividendStr, _rwaType, _version);
        return ok ? (true, _dividendStr._stringToAddress()) : (false, address(0));
    }

    /**
     * @notice Return the CTMRWA1Storage contract address for a given ID
     * NOTE The function also returns a boolean ok, which is false if the ID does not exist
     * @param _ID The ID being examined
     * @param _rwaType The type of CTMRWA. Must be 1 here, to match CTMRWA1
     * @param _version The version of this CTMRWAErrorParam. Latest version is 1
     * @return ok True if the ID exists, false otherwise
     * @return tuple (ok, storageAddr) ok True if the ID exists, false otherwise, storageAddr The address of the CTMRWA1Storage contract
     */
    function getStorageContract(uint256 _ID, uint256 _rwaType, uint256 _version) public view returns (bool, address) {
        string memory _storageStr = idToStorage[_ID];
        bool ok = _checkRwaTypeVersion(_storageStr, _rwaType, _version);
        return ok ? (true, _storageStr._stringToAddress()) : (false, address(0));
    }

    /**
     * @notice Return the CTMRWA1Sentry contract address for a given ID
     * NOTE The function also returns a boolean ok, which is false if the ID does not exist
     * @param _ID The ID being examined
     * @param _rwaType The type of CTMRWA. Must be 1 here, to match CTMRWA1
     * @param _version The version of this CTMRWAErrorParam. Latest version is 1
     * @return ok True if the ID exists, false otherwise
     * @return tuple (ok, sentryAddr) ok True if the ID exists, false otherwise, sentryAddr The address of the CTMRWA1Sentry contract
     */
    function getSentryContract(uint256 _ID, uint256 _rwaType, uint256 _version) public view returns (bool, address) {
        string memory _sentryStr = idToSentry[_ID];
        bool ok = _checkRwaTypeVersion(_sentryStr, _rwaType, _version);
        return ok ? (true, _sentryStr._stringToAddress()) : (false, address(0));
    }

    /**
     * @notice Return the CTMRWADeployInvest contract address for a given ID
     * NOTE The function also returns a boolean ok, which is false if the ID does not exist
     * @param _ID The ID being examined
     * @param _rwaType The type of CTMRWA. Must be 1 here, to match CTMRWA1
     * @param _version The version of this CTMRWAErrorParam. Latest version is 1
     * @return ok True if the ID exists, false otherwise
     * @return tuple (ok, investAddr) ok True if the ID exists, false otherwise, investAddr The address of the CTMRWADeployInvest contract
     */
    function getInvestContract(uint256 _ID, uint256 _rwaType, uint256 _version) public view returns (bool, address) {
        string memory _investStr = idToInvest[_ID];
        bool ok = _checkRwaTypeVersion(_investStr, _rwaType, _version);
        return ok ? (true, _investStr._stringToAddress()) : (false, address(0));
    }

    /**
     * @notice Return the CTMRWAERC20 contract address for a given ID and slot
     * NOTE The function also returns a boolean ok, which is false if the ID or slot does not exist
     * @param _ID The ID being examined
     * @param _rwaType The type of CTMRWA. Must be 1 here, to match CTMRWA1
     * @param _version The version of this CTMRWAErrorParam. Latest version is 1
     * @param _slot The slot number being examined
     * @return ok True if the ID and slot exist, false otherwise
     * @return tuple (ok, erc20Addr) ok True if the ID and slot exist, false otherwise, erc20Addr The address of the CTMRWAERC20 contract
     */
    function getErc20Contract(uint256 _ID, uint256 _rwaType, uint256 _version, uint256 _slot) public view returns (bool, address) {
        string memory _erc20Str = idToErc20[_ID][_slot];
        bool ok = _checkRwaTypeVersion(_erc20Str, _rwaType, _version);
        return ok ? (true, _erc20Str._stringToAddress()) : (false, address(0));
    }

    /**
     * @dev This function is called by CTMRWADeployer after the deployment of the
     * CTMRWA1, CTMRWA1Dividend, CTMRWA1Storage and CTMRWA1Sentry contracts on a chain.
     * It links them together by setting the same ID for the one CTMRWA token and storing their
     * contract addresses.
     * NOTE Only the deployer of the CTMRWAMap contract can call this function.
     * @param _ID The ID of the CTMRWA token
     * @param _tokenAddr The address of the CTMRWA1 contract
     * @param _dividendAddr The address of the CTMRWA1Dividend contract
     * @param _storageAddr The address of the CTMRWA1Storage contract
     * @param _sentryAddr The address of the CTMRWA1Sentry contract
     */
    function attachContracts(
        uint256 _ID,
        address _tokenAddr,
        address _dividendAddr,
        address _storageAddr,
        address _sentryAddr
    ) external onlyDeployer {

        if (_tokenAddr == address(0)) {
            revert CTMRWAMap_IsZeroAddress(CTMRWAErrorParam.Token);
        }
        if (_dividendAddr == address(0)) {
            revert CTMRWAMap_IsZeroAddress(CTMRWAErrorParam.Dividend);
        }
        if (_storageAddr == address(0)) {
            revert CTMRWAMap_IsZeroAddress(CTMRWAErrorParam.Storage);
        }
        if (_sentryAddr == address(0)) {
            revert CTMRWAMap_IsZeroAddress(CTMRWAErrorParam.Sentry);
        }

        bool ok = _attachCTMRWAID(_ID, _tokenAddr, _dividendAddr, _storageAddr, _sentryAddr);
        if (!ok) {
            revert CTMRWAMap_AlreadyAttached(_ID, _tokenAddr);
        }

        ok = ICTMRWAAttachment(_tokenAddr).attachDividend(_dividendAddr);
        if (!ok) {
            revert CTMRWAMap_FailedAttachment(CTMRWAErrorParam.Dividend);
        }

        ok = ICTMRWAAttachment(_tokenAddr).attachStorage(_storageAddr);
        if (!ok) {
            revert CTMRWAMap_FailedAttachment(CTMRWAErrorParam.Storage);
        }

        ok = ICTMRWAAttachment(_tokenAddr).attachSentry(_sentryAddr);
        if (!ok) {
            revert CTMRWAMap_FailedAttachment(CTMRWAErrorParam.Sentry);
        }
    }

    /**
     * @dev Set the investment contract for a given ID
     * NOTE Only the deployer of the CTMRWAMap contract can call this function.
     * @param _ID The ID of the CTMRWA token
     * @param _rwaType The type of CTMRWA. Must be 1 here, to match CTMRWA1
     * @param _version The version of this CTMRWAErrorParam. Latest version is 1
     * @param _investAddr The address of the CTMRWADeployInvest contract
     * @return success True if the investment contract was set, false otherwise
     */
    function setInvestmentContract(uint256 _ID, uint256 _rwaType, uint256 _version, address _investAddr)
        external
        onlyDeployer
        returns (bool)
    {
        if (_investAddr == address(0)) {
            revert CTMRWAMap_IsZeroAddress(CTMRWAErrorParam.Invest);
        }

        string memory investAddrStr = _investAddr.toHexString()._toLower();

        _checkRwaTypeVersion(investAddrStr, _rwaType, _version);

        // NOTE: Ensure that the contract has not been deployed yet
        if (investToId[investAddrStr] != 0) {
            return (false);
        } else {
            idToInvest[_ID] = investAddrStr;
            investToId[investAddrStr] = _ID;
            return (true);
        }
    }

    /**
     * @dev Set the ERC20 contract for a given ID and slot
     * NOTE Only the deployer of the CTMRWAMap contract can call this function.
     * @param _ID The ID of the CTMRWA token
     * @param _rwaType The type of CTMRWA. Must be 1 here, to match CTMRWA1
     * @param _version The version of this CTMRWAErrorParam. Latest version is 1
     * @param _slot The slot number for the ERC20
     * @param _erc20Addr The address of the CTMRWAERC20 contract
     * @return success True if the ERC20 contract was set, false otherwise
     */
    function setErc20Contract(uint256 _ID, uint256 _rwaType, uint256 _version, uint256 _slot, address _erc20Addr) external onlyDeployer returns (bool) {
        if (_erc20Addr == address(0)) {
            revert CTMRWAMap_IsZeroAddress(CTMRWAErrorParam.RWAERC20);
        }

        string memory erc20AddrStr = _erc20Addr.toHexString()._toLower();
        
        _checkRwaTypeVersion(erc20AddrStr, _rwaType, _version);

        // NOTE: Ensure that the contract has not been deployed yet
        if (erc20ToId[_slot][erc20AddrStr] != 0) {
            return (false);
        } else {
            idToErc20[_ID][_slot] = erc20AddrStr;
            erc20ToId[_slot][erc20AddrStr] = _ID;
            return (true);
        }
    }

    /// @dev Internal helper function for attachContracts
    /// @param _ID The ID of the CTMRWA token
    /// @param _ctmRwaAddr The address of the CTMRWA1 contract
    /// @param _dividendAddr The address of the CTMRWA1Dividend contract
    /// @param _storageAddr The address of the CTMRWA1Storage contract
    /// @param _sentryAddr The address of the CTMRWA1Sentry contract
    /// @return success True if the contracts were attached, false otherwise
    function _attachCTMRWAID(
        uint256 _ID,
        address _ctmRwaAddr,
        address _dividendAddr,
        address _storageAddr,
        address _sentryAddr
    ) internal returns (bool) {
        string memory ctmRwaAddrStr = _ctmRwaAddr.toHexString()._toLower();
        string memory dividendAddr = _dividendAddr.toHexString()._toLower();
        string memory storageAddr = _storageAddr.toHexString()._toLower();
        string memory sentryAddr = _sentryAddr.toHexString()._toLower();

        uint256 lenContract = bytes(idToContract[_ID]).length;

        if (lenContract != 0 || contractToId[ctmRwaAddrStr] != 0) {
            return (false);
        } else {
            idToContract[_ID] = ctmRwaAddrStr;
            contractToId[ctmRwaAddrStr] = _ID;

            idToDividend[_ID] = dividendAddr;
            dividendToId[dividendAddr] = _ID;

            idToStorage[_ID] = storageAddr;
            storageToId[storageAddr] = _ID;

            idToSentry[_ID] = sentryAddr;
            sentryToId[sentryAddr] = _ID;

            return (true);
        }
    }

    function cID() internal view returns (uint256) {
        return block.chainid;
    }

    /// @dev Fallback function for failed c3call cross-chain. Only emits an event at present
    /// @param _selector The selector of the function that failed
    /// @param _data The data of the function that failed
    /// @param _reason The reason for the failure
    /// @return ok True if the fallback was successful, false otherwise.
    function _c3Fallback(bytes4 _selector, bytes calldata _data, bytes calldata _reason)
        internal
        override
        returns (bool)
    {
        emit LogFallback(_selector, _data, _reason);
        return true;
    }

    /// @dev Internal helper function to check the CTMRWA type and version of a contract
    /// @param _addrStr The address of the contract to check
    /// @param _rwaType The type of CTMRWAErrorParam. Must be 1 here, to match CTMRWA1
    /// @param _version The version of this CTMRWAErrorParam. Latest version is 1
    /// @return ok True if the CTMRWAErrorParam type and version are compatible, false otherwise
    function _checkRwaTypeVersion(string memory _addrStr, uint256 _rwaType, uint256 _version)
        internal
        view
        returns (bool)
    {
        // NOTE: Skip check if the token validly does not exist
        if (bytes(_addrStr).length == 0) {
            return false;
        }
        address _contractAddr = _addrStr._stringToAddress();
        uint256 rwaType = ICTMRWA(_contractAddr).RWA_TYPE();
        uint256 version = ICTMRWA(_contractAddr).VERSION();
        if (_rwaType != rwaType) {
            revert CTMRWAMap_IncompatibleRWA(CTMRWAErrorParam.Type);
        }
        if (_version != version) {
            revert CTMRWAMap_IncompatibleRWA(CTMRWAErrorParam.Version);
        }
        return true;
    }
}
