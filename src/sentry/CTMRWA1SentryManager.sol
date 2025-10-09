// SPDX-License-Identifier: BSL-1.1

pragma solidity 0.8.27;

import { ICTMRWA1, ITokenContract, TokenContract } from "../core/ICTMRWA1.sol";
import { ITokenContract } from "../core/ICTMRWA1.sol";
import { ICTMRWAGateway } from "../crosschain/ICTMRWAGateway.sol";

import { ICTMRWA1Identity } from "../identity/ICTMRWA1Identity.sol";
import { FeeType, IFeeManager } from "../managers/IFeeManager.sol";
import { ICTMRWAMap } from "../shared/ICTMRWAMap.sol";
import { Address, CTMRWAUtils, List, Uint } from "../utils/CTMRWAUtils.sol";
import { ICTMRWA1Sentry } from "./ICTMRWA1Sentry.sol";
import { ICTMRWA1SentryManager } from "./ICTMRWA1SentryManager.sol";
import { ICTMRWA1SentryUtils } from "./ICTMRWA1SentryUtils.sol";
import { C3GovernDAppUpgradeable } from "@c3caller/upgradeable/gov/C3GovernDAppUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title AssetX Multi-chain Semi-Fungible-Token for Real-World-Assets (RWAs)
 * @author @Selqui ContinuumDAO
 *
 * @notice This contract manages the cross-chain synchronization of all controlled access
 * functionality to RWAs. This controls any whitelist of addresses allowed to trade,
 * adding the requirement for KYC, KYB, over 18 years, Accredited Investor status and geo-fencing.
 *
 * This contract is only deployed ONCE on each chain and manages all CTMRWA1Sentry contract
 * deployments and functions.
 */
contract CTMRWA1SentryManager is ICTMRWA1SentryManager, C3GovernDAppUpgradeable, UUPSUpgradeable {
    using Strings for *;
    using SafeERC20 for IERC20;
    using CTMRWAUtils for string;

    /// @dev The address of the CTMRWADeployer contract
    address public ctmRwaDeployer;

    /// @dev The address of the CTMRWAMap contract
    address public ctmRwaMap;

    /// @dev The address of the CTMRWA1SentryUtils contract (adjunct to this contract)
    address public utilsAddr;

    /// @dev rwaType is the RWA type defining CTMRWA1
    uint256 public constant RWA_TYPE = 1;

    /// @dev version is the single integer version of this RWA type
    uint256 public constant VERSION = 1;

    /// @dev The address of the CTMRWAGateway contract
    address public gateway;

    /// @dev The address of the FeeManager contract
    address public feeManager;

    /// The address of the CTMRWA1Identity contract
    address public identity;

    /// @dev A string respresentation of this chainID
    string cIdStr;

    /// @dev A new c3call for ID to set the Sentry Options on chain toChainIdStr
    event SettingSentryOptions(uint256 ID, string toChainIdStr);

    /// @dev New Sentry Options set for ID
    event SentryOptionsSet(uint256 ID);

    /// @dev New c3call to set Whitelist for ID to chain toChainIdStr
    event AddingWhitelist(uint256 ID, string toChainIdStr);

    /// @dev New Whitelist added on local chain for ID
    event WhitelistAdded(uint256 ID);

    /// @dev New c3call to Add a Country List for ID to chain toChainIdStr
    event AddingCountryList(uint256 ID, string toChainIdStr);

    /// @dev New Country List added on local chain for ID
    event CountryListAdded(uint256 ID);

    modifier onlyDeployer() {
        if (msg.sender != ctmRwaDeployer) {
            revert CTMRWA1SentryManager_OnlyAuthorized(Address.Sender, Address.Deployer);
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
        __C3GovernDApp_init(_gov, _c3callerProxy, _txSender, _dappID);
        ctmRwaDeployer = _ctmRwaDeployer;
        gateway = _gateway;
        feeManager = _feeManager;
        cIdStr = block.chainid.toString();
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
        ctmRwaMap = _map;
    }

    /**
     * @notice Governance can change to a new CTMRWA1SentryUtils contract
     * @param _utilsAddr address of the new CTMRWA1SentryUtils contract
     */
    function setSentryUtils(address _utilsAddr) external onlyGov {
        utilsAddr = _utilsAddr;
    }

    /**
     * @notice Governance can switch to a new CTMRWA1Identity contract
     */
    function setIdentity(address _id, address _zkMeVerifierAddr) external onlyGov {
        if (_id == address(0)) {
            revert CTMRWA1SentryManager_IsZeroAddress(Address.Identity);
        }
        identity = _id;
        ICTMRWA1Identity(_id).setZkMeVerifierAddress(_zkMeVerifierAddr);
    }

    /**
     * @dev This function is called by CTMRWADeployer, allowing CTMRWA1SentryUtils to
     * deploy a CTMRWA1Sentry contract with the same ID as for the CTMRWA1 contract
     * @param _ID The ID of the RWA token
     * @param _tokenAddr The address of the CTMRWA1 contract
     * @param _rwaType The type of RWA (set to 1 for CTMRWA1)
     * @param _version The version of RWA (set to 1 for current version)
     * @param _map The address of the CTMRWAMap contract
     * @return sentryAddr The address of the deployed CTMRWA1Sentry contract
     */
    function deploySentry(uint256 _ID, address _tokenAddr, uint256 _rwaType, uint256 _version, address _map)
        external
        onlyDeployer
        returns (address)
    {
        address sentryAddr = ICTMRWA1SentryUtils(utilsAddr).deploySentry(_ID, _tokenAddr, _rwaType, _version, _map);

        return (sentryAddr);
    }

    /**
     * @notice The tokenAdmin (Issuer) can optionally set options to control which wallet addresses
     * can be transferred to using a Whitelist, identical on all chains that the RWA token is deployed to.
     * The tokenAdmin can also require KYC via zkProofs, which then allows a user to add themselves to the Whitelist
     * using the verifyPerson function in CTMRWAI1dentity function. Either or both _whitelist and _kyc
     * can be set. The other options can only be set if _kyc is set. These are not required for all
     * zkProof verifiers though, since some control geo-fencing and age criteria themselves (e.g. zkMe).
     * These other options are still useful for on-chain information purposes though.
     * @param _ID The ID of the RWA token
     * @param _whitelist A switch which, if set, enables the tokenAdmin to control a Whitelist of wallets
     * that may be sent value.
     * @param _kyc A switch which, if set, allows KYC via a zkProof to allow users to add themselves to the
     * Whitelist.
     * @param _kyb A switch which, if set, allows a business to undergo KYB via zkProofs. To set this
     * switch, _kyc must also be set. The zkMe system does not require this to be set. Note however that
     * the switch cannot be set later.
     * @param _over18 A switch, if set, only allows those over 18 years of age to trade. To set this
     * switch, _kyc must also be set. The zkMe system does not require this to be set. Note however that
     * the switch cannot be set later.
     * @param _accredited A switch, if set, only allows Accredited, or Sophisticated Investors to trade.
     * To set this switch, _kyc must also be set. The zkMe system does not require this to be set.
     * Note however that the switch cannot be set later.
     * @param _countryWL a switch, which if set, allows a tokenAdmin to maintain a Whitelist of countries
     * from which investors are allowed to trade value. This does not specify whether citizenship or residency
     * is the criterion. If _countrWL is set, then _countryBL must NOT be set. The zkMe system does not require
     * this to be set. Note however that the switch cannot be set later.
     * @param _countryBL a switch, which if set, allows a tokenAdmin to maintain a Blacklist of countries
     * from which investors are allowed to trade value.This does not specify whether citizenship or residency
     * is the criterion. If _countrBL is set, then _countryWL must NOT be set. The zkMe system does not require
     * this to be set. Note however that the switch cannot be set later.
     * @param _chainIdsStr This is an array of strings of chainIDs to deploy to.
     * @param _feeTokenStr This is fee token on the source chain (local chain) that you wish to use to pay
     * for the deployment. See the function feeTokenList in the FeeManager contract for allowable values.
     * NOTE For EVM chains, the address of the fee token must be converted to a string
     * NOTE The function setSentryOptions CAN ONLY BE CALLED ONCE.
     * NOTE Once the function setSentryOptions has beed called, NO NEW CHAINS CAN BE ADDED TO THIS RWA TOKEN
     */
    function setSentryOptions(
        uint256 _ID,
        bool _whitelist,
        bool _kyc,
        bool _kyb,
        bool _over18,
        bool _accredited,
        bool _countryWL,
        bool _countryBL,
        string[] memory _chainIdsStr,
        string memory _feeTokenStr
    ) public {
        (address ctmRwa1Addr,) = _getTokenAddr(_ID);
        _checkTokenAdmin(ctmRwa1Addr);

        (bool ok, address sentryAddr) = ICTMRWAMap(ctmRwaMap).getSentryContract(_ID, RWA_TYPE, VERSION);
        if (!ok) {
            revert CTMRWA1SentryManager_InvalidContract(Address.Sentry);
        }

        bool sentryOptionsSet = ICTMRWA1Sentry(sentryAddr).sentryOptionsSet();
        if (sentryOptionsSet) {
            revert CTMRWA1SentryManager_OptionsAlreadySet();
        }

        if (!_kyc) {
            if (!_whitelist) {
                revert CTMRWA1SentryManager_InvalidList(List.WL_KYC_Disabled);
            }

            if (_kyb || _over18 || _accredited || _countryWL || _countryBL) {
                revert CTMRWA1SentryManager_NoKYC();
            }
        } else {
            if (_countryWL && _countryBL) {
                revert CTMRWA1SentryManager_InvalidList(List.WL_BL_Defined);
            }
        }

        uint256 fee = _getFee(FeeType.ADMIN, 1, _chainIdsStr, _feeTokenStr);

        _payFee(fee, _feeTokenStr);

        for (uint256 i = 0; i < _chainIdsStr.length; i++) {
            string memory chainIdStr = _chainIdsStr[i]._toLower();

            if (chainIdStr.equal(cIdStr)) {
                ICTMRWA1Sentry(sentryAddr).setSentryOptionsLocal(
                    _ID, _whitelist, _kyc, _kyb, _over18, _accredited, _countryWL, _countryBL
                );
            } else {
                (, string memory toRwaSentryStr) = _getSentry(chainIdStr);

                string memory funcCall = "setSentryOptionsX(uint256,bool,bool,bool,bool,bool,bool,bool)";
                bytes memory callData = abi.encodeWithSignature(
                    funcCall, _ID, _whitelist, _kyc, _kyb, _over18, _accredited, _countryWL, _countryBL
                );

                _c3call(toRwaSentryStr, chainIdStr, callData);

                emit SettingSentryOptions(_ID, chainIdStr);
            }
        }
    }

    /**
     * @notice This function is used to store important parameters relating to the zKMe zkProof KYC
     * implementation. It can only be called by the tokenAdmin (Issuer). It can only be called if the
     * _kyc switch has been set in setSentryOptions. See https://dashboard.zk.me for details.
     * @param _ID The ID of the RWA token
     * @param _appId The appId that the tokenAdmin can generate in the zkMe Dashboard from their apiKey
     * @param _programNo The programNo for the Schema, which details access restrictions (e.g. geo-fencing).
     * NOTE The tokenAdmin can change the _programNo if they update the access restrictions, so that all
     * new users undergoing KYC will be subject to these updated restrictions.
     * @param _cooperator This address is the zkMe verifier contract that allows AssetX to check if a user
     * has undergone KYC AND passes the access restrictions in the Schema (_programNo). AssetX calls the
     * hasApproved function in this contract.
     */
    function setZkMeParams(uint256 _ID, string memory _appId, string memory _programNo, address _cooperator) public {
        if (identity == address(0)) {
            revert CTMRWA1SentryManager_IsZeroAddress(Address.Identity);
        }

        (address ctmRwa1Addr,) = _getTokenAddr(_ID);
        _checkTokenAdmin(ctmRwa1Addr);

        (address sentryAddr,) = _getSentryAddr(_ID);

        bool kyc = ICTMRWA1Sentry(sentryAddr).kycSwitch();

        if (!kyc) {
            revert CTMRWA1SentryManager_NoKYC();
        }

        ICTMRWA1Sentry(sentryAddr).setZkMeParams(_appId, _programNo, _cooperator);
    }

    /**
     * @notice This function removes the Accredited flag, _accredited, if KYC is set. It is designed
     * to remove the obstacle of allowing only Accredited Investors to trade the RWA token and typically
     * would be called after a time period had elapsed as determined by a Regulator, so that the token
     * can be publicly traded.
     * @param _ID The ID of the RWA token
     * @param _chainIdsStr This is an array of strings of chainIDs to deploy to.
     * @param _feeTokenStr This is fee token on the source chain (local chain) that you wish to use to pay
     * for the deployment. See the function feeTokenList in the FeeManager contract for allowable values.
     * NOTE This function has no effect if zkMe is the KYC provider and is then only for information purposes.
     */
    function goPublic(uint256 _ID, string[] memory _chainIdsStr, string memory _feeTokenStr) public {
        (address ctmRwa1Addr,) = _getTokenAddr(_ID);
        _checkTokenAdmin(ctmRwa1Addr);

        (address sentryAddr,) = _getSentryAddr(_ID);

        bool kyc = ICTMRWA1Sentry(sentryAddr).kycSwitch();
        if (!kyc) {
            revert CTMRWA1SentryManager_KYCDisabled();
        }

        bool accredited = ICTMRWA1Sentry(sentryAddr).accreditedSwitch();
        if (!accredited) {
            revert CTMRWA1SentryManager_AccreditationDisabled();
        }

        bool kyb = ICTMRWA1Sentry(sentryAddr).kybSwitch();
        bool over18 = ICTMRWA1Sentry(sentryAddr).age18Switch();
        bool countryWL = ICTMRWA1Sentry(sentryAddr).countryWLSwitch();
        bool countryBL = ICTMRWA1Sentry(sentryAddr).countryBLSwitch();

        uint256 fee = _getFee(FeeType.ADMIN, 1, _chainIdsStr, _feeTokenStr);

        _payFee(fee, _feeTokenStr);

        for (uint256 i = 0; i < _chainIdsStr.length; i++) {
            string memory chainIdStr = _chainIdsStr[i]._toLower();

            if (chainIdStr.equal(cIdStr)) {
                ICTMRWA1Sentry(sentryAddr).setSentryOptionsLocal(
                    _ID, false, true, kyb, over18, false, countryWL, countryBL
                );
            } else {
                (, string memory toRwaSentryStr) = _getSentry(chainIdStr);

                string memory funcCall = "setSentryOptionsX(uint256,bool,bool,bool,bool,bool,bool,bool)";
                bytes memory callData =
                    abi.encodeWithSignature(funcCall, _ID, false, true, kyb, over18, false, countryWL, countryBL);

                _c3call(toRwaSentryStr, chainIdStr, callData);

                emit SettingSentryOptions(_ID, chainIdStr);
            }
        }
    }

    /// @dev This is the function called on the destination chain by the setSentryoptions function.
    /// See this function for the parameter descriptions. It is an onlyCaller function.
    function setSentryOptionsX(
        uint256 _ID,
        bool _whitelist,
        bool _kyc,
        bool _kyb,
        bool _over18,
        bool _accredited,
        bool _countryWL,
        bool _countryBL
    ) external onlyCaller returns (bool) {
        (address sentryAddr,) = _getSentryAddr(_ID);

        ICTMRWA1Sentry(sentryAddr).setSentryOptionsLocal(
            _ID, _whitelist, _kyc, _kyb, _over18, _accredited, _countryWL, _countryBL
        );

        emit SentryOptionsSet(_ID);

        return (true);
    }

    /**
     * @notice This function allows the tokenAdmin (Issuer) to maintain a Whitelist of user wallets
     * on all chains that may receive value in the RWA token.
     * @param _ID The ID of the RWA token
     * @param _wallets An array of wallets as strings for which the access status is being updated.
     * @param _choices An array of switches corresponding to _wallets. If an entry is true, then this
     * wallet address may receive value. The function _isAllowableTransfer in CTMRWA1Sentry is called to check
     * @param _chainIdsStr This is an array of strings of chainIDs to deploy to.
     * @param _feeTokenStr This is fee token on the source chain (local chain) that you wish to use to pay
     * for the deployment. See the function feeTokenList in the FeeManager contract for allowable values.
     * NOTE This function can only be called if the _whitelist switch has been set in setSentryOptions
     */
    function addWhitelist(
        uint256 _ID,
        string[] memory _wallets,
        bool[] memory _choices,
        string[] memory _chainIdsStr,
        string memory _feeTokenStr
    ) public {
        if (_choices.length != _wallets.length) {
            revert CTMRWA1SentryManager_LengthMismatch(Uint.Input);
        }

        (address sentryAddr,) = _getSentryAddr(_ID);

        (address ctmRwa1Addr,) = _getTokenAddr(_ID);
        _checkTokenAdmin(ctmRwa1Addr);

        bool whitelistSwitch = ICTMRWA1Sentry(sentryAddr).whitelistSwitch();
        if (!whitelistSwitch) {
            revert CTMRWA1SentryManager_InvalidList(List.WL_Disabled);
        }

        uint256 len = _wallets.length;

        if (msg.sender != identity) {
            // charge a different fee if FeeType.KYC, paid in the CTMRWAIdentity contract
            uint256 fee = _getFee(FeeType.WHITELIST, len, _chainIdsStr, _feeTokenStr);
            _payFee(fee, _feeTokenStr);
        }

        for (uint256 i = 0; i < _chainIdsStr.length; i++) {
            string memory chainIdStr = _chainIdsStr[i]._toLower();

            if (chainIdStr.equal(cIdStr)) {
                ICTMRWA1Sentry(sentryAddr).setWhitelistSentry(_ID, _wallets, _choices);
            } else {
                (, string memory toRwaSentryStr) = _getSentry(chainIdStr);

                string memory funcCall = "setWhitelistX(uint256,string[],bool[])";
                bytes memory callData = abi.encodeWithSignature(funcCall, _ID, _wallets, _choices);

                _c3call(toRwaSentryStr, chainIdStr, callData);

                emit AddingWhitelist(_ID, chainIdStr);
            }
        }
    }

    /// @dev This function is only called on the destination chain by addWhitelist. It is an onlyCaller function
    /// @param _ID The ID of the RWA token
    /// @param _wallets The list of wallets to set the state for
    /// @param _choices The list of choices for the wallets
    /// @return success True if the whitelist was set, false otherwise.
    function setWhitelistX(uint256 _ID, string[] memory _wallets, bool[] memory _choices)
        external
        onlyCaller
        returns (bool)
    {
        (address sentryAddr,) = _getSentryAddr(_ID);

        ICTMRWA1Sentry(sentryAddr).setWhitelistSentry(_ID, _wallets, _choices);

        emit WhitelistAdded(_ID);

        return (true);
    }

    /**
     * @notice This function allows the tokenAdmin to maintain a list of countries from which users are allowed to
     * trade.
     * The list can be either a Country Whitelist OR a Country Blacklist as determined by setSentryOptions
     * @param _ID The ID of the RWA token.
     * @param _countries Is an array of strings representing the countries whose access is being set here
     * The strings must each be an ISO3166 2 letter country code. See https://datahub.io/core/country-list
     * @param _choices An array of switches corresponding to the _countries array.
     * @param _chainIdsStr This is an array of strings of chainIDs to deploy to.
     * @param _feeTokenStr This is fee token on the source chain (local chain) that you wish to use to pay
     * for the deployment. See the function feeTokenList in the FeeManager contract for allowable values.
     * NOTE This function can only be called if both _kyc and either _countryWL, or _countryBL has been set
     * in setSentryOptions.
     * NOTE This function has no effect if zkMe is the KYC provider and is then only for information purposes.
     */
    function addCountrylist(
        uint256 _ID,
        string[] memory _countries,
        bool[] memory _choices,
        string[] memory _chainIdsStr,
        string memory _feeTokenStr
    ) public {
        if (_choices.length != _countries.length) {
            revert CTMRWA1SentryManager_LengthMismatch(Uint.Input);
        }

        (address sentryAddr,) = _getSentryAddr(_ID);

        (address ctmRwa1Addr,) = _getTokenAddr(_ID);
        _checkTokenAdmin(ctmRwa1Addr);

        bool countryWLSwitch = ICTMRWA1Sentry(sentryAddr).countryWLSwitch();
        bool countryBLSwitch = ICTMRWA1Sentry(sentryAddr).countryBLSwitch();
        if (!countryWLSwitch && !countryBLSwitch) {
            revert CTMRWA1SentryManager_InvalidList(List.WL_BL_Undefined);
        }

        uint256 len = _countries.length;

        uint256 fee = _getFee(FeeType.COUNTRY, len, _chainIdsStr, _feeTokenStr);

        _payFee(fee, _feeTokenStr);

        for (uint256 i = 0; i < _chainIdsStr.length; i++) {
            if (bytes(_countries[i]).length != 2) {
                revert CTMRWA1SentryManager_InvalidLength(Uint.CountryCode);
            }

            string memory chainIdStr = _chainIdsStr[i]._toLower();

            if (chainIdStr.equal(cIdStr)) {
                ICTMRWA1Sentry(sentryAddr).setCountryListLocal(_ID, _countries, _choices);
            } else {
                (, string memory toRwaSentryStr) = _getSentry(chainIdStr);

                string memory funcCall = "setCountryListX(uint256,string[],bool[])";
                bytes memory callData = abi.encodeWithSignature(funcCall, _ID, _countries, _choices);

                _c3call(toRwaSentryStr, chainIdStr, callData);

                emit AddingCountryList(_ID, chainIdStr);
            }
        }
    }

    /// @dev This function is only called on the destination chain by addCountrylist. It is an onlyCaller function.
    /// See addCountrylist for details of the params.
    /// @param _ID The ID of the RWA token
    /// @param _countries The list of countries to set the state for
    /// @param _choices The list of choices for the countries
    /// @return success True if the country list was set, false otherwise.
    function setCountryListX(uint256 _ID, string[] memory _countries, bool[] memory _choices)
        external
        onlyCaller
        returns (bool)
    {
        (address sentryAddr,) = _getSentryAddr(_ID);

        ICTMRWA1Sentry(sentryAddr).setCountryListLocal(_ID, _countries, _choices);

        emit CountryListAdded(_ID);

        return (true);
    }

    /// @dev Pay a fee, calculated by the feeType, the fee token and the chains in question
    /// @param _feeWei The fee to pay in wei
    /// @param _feeTokenStr The fee token address (as a string) to pay in
    /// @return success True if the fee was paid, false otherwise.
    function _payFee(uint256 _feeWei, string memory _feeTokenStr) internal returns (bool) {
        if (_feeWei > 0) {
            address feeToken = _feeTokenStr._stringToAddress();

            IERC20(feeToken).transferFrom(msg.sender, address(this), _feeWei);

            IERC20(feeToken).approve(feeManager, _feeWei);
            IFeeManager(feeManager).payFee(_feeWei, _feeTokenStr);
        }
        return (true);
    }

    /// @dev Get the fee payable, depending on the _feeType
    /// @param _feeType The type of fee to get
    /// @param _nItems The number of items to get the fee for
    /// @param _toChainIdsStr The list of chainIds to get the fee for
    /// @param _feeTokenStr The fee token address (as a string) to get the fee in
    /// @return fee The fee to pay in wei
    function _getFee(FeeType _feeType, uint256 _nItems, string[] memory _toChainIdsStr, string memory _feeTokenStr)
        internal
        view
        returns (uint256)
    {
        bool includeLocal = false; // local chain is already included in _toChainIdsStr

        uint256 fee = IFeeManager(feeManager).getXChainFee(_toChainIdsStr, includeLocal, _feeType, _feeTokenStr);

        return (fee * _nItems);
    }

    /// @dev This reports on the latest revert string if a cross-chain call failed for whatever reason
    /// @return lastReason The latest revert string if a cross-chain call failed for whatever reason
    function getLastReason() public view returns (string memory) {
        string memory lastReason = ICTMRWA1SentryUtils(utilsAddr).getLastReason();
        return (lastReason);
    }

    /// @dev Get the CTMRWA1 contract address corresponding to the ID on this chain
    /// @param _ID The ID of the RWA token
    /// @return tokenAddr The address of the CTMRWA1 contract
    /// @return tokenAddrStr The string version of the CTMRWA1 contract address
    function _getTokenAddr(uint256 _ID) internal view returns (address, string memory) {
        (bool ok, address tokenAddr) = ICTMRWAMap(ctmRwaMap).getTokenContract(_ID, RWA_TYPE, VERSION);
        if (!ok) {
            revert CTMRWA1SentryManager_InvalidContract(Address.Token);
        }
        string memory tokenAddrStr = tokenAddr.toHexString()._toLower();

        return (tokenAddr, tokenAddrStr);
    }

    /// @dev Get the CTMRWA1Sentry address corresponding to the ID on this chain
    /// @param _ID The ID of the RWA token
    /// @return sentryAddr The address of the CTMRWA1Sentry contract
    /// @return sentryAddrStr The string version of the CTMRWA1Sentry contract address
    function _getSentryAddr(uint256 _ID) internal view returns (address, string memory) {
        (bool ok, address sentryAddr) = ICTMRWAMap(ctmRwaMap).getSentryContract(_ID, RWA_TYPE, VERSION);
        if (!ok) {
            revert CTMRWA1SentryManager_InvalidContract(Address.Sentry);
        }
        string memory sentryAddrStr = sentryAddr.toHexString()._toLower();

        return (sentryAddr, sentryAddrStr);
    }

    /// @dev Get the sentryManager address on a destination chain for a c3call
    /// @param _toChainIdStr The chainId of the destination chain
    /// @return fromAddressStr The address of the CTMRWA1SentryManager contract on this chain
    /// @return toSentryStr The address of the CTMRWA1SentryManager contract on the destination chain
    function _getSentry(string memory _toChainIdStr) internal view returns (string memory, string memory) {
        if (_toChainIdStr.equal(cIdStr)) {
            revert CTMRWA1SentryManager_SameChain();
        }

        string memory fromAddressStr = msg.sender.toHexString()._toLower();

        (bool ok, string memory toSentryStr) =
            ICTMRWAGateway(gateway).getAttachedSentryManager(RWA_TYPE, VERSION, _toChainIdStr);
        if (!ok) {
            revert CTMRWA1SentryManager_InvalidContract(Address.SentryManager);
        }

        return (fromAddressStr, toSentryStr);
    }

    /// @dev Check that the msg.sender is the same as the tokenAdmin for this RWA token
    /// @param _tokenAddr The address of the CTMRWA1 contract
    /// @return currentAdmin The current tokenAdmin address
    /// @return currentAdminStr The string version of the current tokenAdmin address
    function _checkTokenAdmin(address _tokenAddr) internal returns (address, string memory) {
        address currentAdmin = ICTMRWA1(_tokenAddr).tokenAdmin();
        string memory currentAdminStr = currentAdmin.toHexString()._toLower();

        if (msg.sender != currentAdmin && msg.sender != identity) {
            revert CTMRWA1SentryManager_OnlyAuthorized(Address.Sender, Address.TokenAdmin);
        }

        return (currentAdmin, currentAdminStr);
    }

    /// @dev The fallback function for this GovernDApp in the event of a cross-chain call failure
    /// @param _selector The selector of the function that failed
    /// @param _data The data of the function that failed
    /// @param _reason The reason for the failure
    /// @return ok True if the fallback was successful, false otherwise.
    function _c3Fallback(bytes4 _selector, bytes calldata _data, bytes calldata _reason)
        internal
        override
        returns (bool)
    {
        bool ok = ICTMRWA1SentryUtils(utilsAddr).sentryC3Fallback(_selector, _data, _reason);
        return ok;
    }
}
