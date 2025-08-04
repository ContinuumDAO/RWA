// SPDX-License-Identifier: BSL-1.1

pragma solidity 0.8.27;

import { ICTMRWA } from "../core/ICTMRWA.sol";
import { CTMRWAErrorParam, CTMRWAUtils } from "../utils/CTMRWAUtils.sol";
import { ICTMRWAAttachment, ICTMRWAMap } from "./ICTMRWAMap.sol";
import { C3GovernDappUpgradeable } from "@c3caller/upgradeable/gov/C3GovernDappUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title AssetX Multi-chain Semi-Fungible-Token for Real-World-Assets (RWAs)
 * @author @Selqui ContinuumDAO
 *
 * @notice This contract links together the various parts of the CTMRWA1 RWA.
 * For every ID, which is unique to one RWA, there are different contracts as follows -
 *
 * (1) The CTMRWA1 contract itself, which is the Semi-Fungible-Token
 * (2) A Dividend contract called CTMRWA1Dividend
 * (3) A Storage contract called CTMRWA1Storage
 * (4) A Sentry contract called CTMRWA1Sentry
 *
 * This set all share a single ID, which is the same on all chains that the RWA is deployed to
 * The whole set is deployed by CTMRWADeployer.
 * This contract, deployed just once on each chain, stores the state linking the ID to each of the
 * constituent contract addresses. The links from the contract addresses back to the ID are also stored.
 *
 * The 'attach' functions are called by CTMRWADeployer when the contracts are deployed.
 */
contract CTMRWAMap is ICTMRWAMap, C3GovernDappUpgradeable, UUPSUpgradeable {
    using Strings for *;
    using CTMRWAUtils for string;

    /// @dev Address of the CTMRWAGateway contract
    address public gateway;

    /// @dev Address of the CTMRWADeployer contract
    address public ctmRwaDeployer;

    /// @dev Address of the CTMRWA1X contract
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

    event LogFallback(bytes4 selector, bytes data, bytes reason);

    function initialize(
        address _gov,
        address _c3callerProxy,
        address _txSender,
        uint256 _dappID,
        address _gateway,
        address _rwa1X
    ) external initializer {
        __C3GovernDapp_init(_gov, _c3callerProxy, _txSender, _dappID);
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
        ctmRwaDeployer = _deployer;
        gateway = _gateway;
        ctmRwa1X = _rwa1X;
    }

    /**
     * @notice Return the ID of a given CTMRWA1 contract
     * NOTE The input address is a string.
     * NOTE The function also returns a boolean ok, which is false if the ID does not exist
     * @param _tokenAddrStr String version of the CTMRWA1 contract address
     * @param _rwaType The type of RWA. Must be 1 here, to match CTMRWA1
     * @param _version The version of this RWA. Latest version is 1
     * @return ok True if the ID exists, false otherwise
     * @return id The ID of the CTMRWA1 contract
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
     * @param _rwaType The type of RWA. Must be 1 here, to match CTMRWA1
     * @param _version The version of this RWA. Latest version is 1
     * @return ok True if the ID exists, false otherwise
     * @return contractStr The address of the CTMRWA1 contract
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
     * @param _rwaType The type of RWA. Must be 1 here, to match CTMRWA1
     * @param _version The version of this RWA. Latest version is 1
     * @return ok True if the ID exists, false otherwise
     * @return dividendStr The address of the CTMRWA1Dividend contract
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
     * @param _rwaType The type of RWA. Must be 1 here, to match CTMRWA1
     * @param _version The version of this RWA. Latest version is 1
     * @return ok True if the ID exists, false otherwise
     * @return storageStr The address of the CTMRWA1Storage contract
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
     * @param _rwaType The type of RWA. Must be 1 here, to match CTMRWA1
     * @param _version The version of this RWA. Latest version is 1
     * @return ok True if the ID exists, false otherwise
     * @return sentryStr The address of the CTMRWA1Sentry contract
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
     * @param _rwaType The type of RWA. Must be 1 here, to match CTMRWA1
     * @param _version The version of this RWA. Latest version is 1
     * @return ok True if the ID exists, false otherwise
     * @return investStr The address of the CTMRWADeployInvest contract
     */
    function getInvestContract(uint256 _ID, uint256 _rwaType, uint256 _version) public view returns (bool, address) {
        string memory _investStr = idToInvest[_ID];
        bool ok = _checkRwaTypeVersion(_investStr, _rwaType, _version);
        return ok ? (true, _investStr._stringToAddress()) : (false, address(0));
    }

    /**
     * @dev This function is called by CTMRWADeployer after the deployment of the
     * CTMRWA1, CTMRWA1Dividend, CTMRWA1Storage and CTMRWA1Sentry contracts on a chain.
     * It links them together by setting the same ID for the one RWA and storing their
     * contract addresses.
     * @param _ID The ID of the RWA token
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
     * @param _ID The ID of the RWA token
     * @param _rwaType The type of RWA. Must be 1 here, to match CTMRWA1
     * @param _version The version of this RWA. Latest version is 1
     * @param _investAddr The address of the CTMRWADeployInvest contract
     * @return success True if the investment contract was set, false otherwise
     */
    function setInvestmentContract(uint256 _ID, uint256 _rwaType, uint256 _version, address _investAddr)
        external
        onlyDeployer
        returns (bool)
    {
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

    /// @dev Internal helper function for attachContracts
    /// @param _ID The ID of the RWA token
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

    /// @dev Internal helper function to check the RWA type and version of a contract
    /// @param _addrStr The address of the contract to check
    /// @param _rwaType The type of RWA. Must be 1 here, to match CTMRWA1
    /// @param _version The version of this RWA. Latest version is 1
    /// @return ok True if the RWA type and version are compatible, false otherwise
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
