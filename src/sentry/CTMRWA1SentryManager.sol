// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import { C3GovernDapp } from "@c3caller/gov/C3GovernDapp.sol";

import { ICTMRWA1, ITokenContract, TokenContract } from "../core/ICTMRWA1.sol";
import { ITokenContract } from "../core/ICTMRWA1.sol";
import { ICTMRWAGateway } from "../crosschain/ICTMRWAGateway.sol";
import { FeeType, IERC20Extended, IFeeManager } from "../managers/IFeeManager.sol";

import { ICTMRWAMap } from "../shared/ICTMRWAMap.sol";
import { ICTMRWA1Sentry } from "./ICTMRWA1Sentry.sol";
import { ICTMRWA1SentryManager } from "./ICTMRWA1SentryManager.sol";
import { ICTMRWA1SentryUtils } from "./ICTMRWA1SentryUtils.sol";
import {CTMRWAUtils} from "../CTMRWAUtils.sol";

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
contract CTMRWA1SentryManager is ICTMRWA1SentryManager, C3GovernDapp, UUPSUpgradeable {
    using Strings for *;
    using SafeERC20 for IERC20;
    using CTMRWAUtils for string;

    /// @dev The address of the CTMRWADeployer contract
    address public ctmRwaDeployer;

    /// @dev The address of the CTMRWAMap contract
    address public ctmRwa1Map;

    /// @dev The address of the CTMRWA1SentryUtils contract (adjunct to this contract)
    address public utilsAddr;

    /// @dev rwaType is the RWA type defining CTMRWA1
    uint256 public constant RWA_TYPE = 1;

    /// @dev version is the single integer version of this RWA type
    uint256 public constant VERSION = 1;

    /// @dev The address of the CTMRWAGateway contract
    address gateway;

    /// @dev The address of the FeeManager contract
    address feeManager;

    /// The address of the CTMRWA1Identity contract
    address identity;

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
        require(msg.sender == ctmRwaDeployer, "CTMRWA1SentryManager: onlyDeployer function");
        _;
    }

    // TODO: Remove redundant _rwaType and _version parameters
    function initialize(
        address _gov,
        // uint256 _rwaType,
        // uint256 _version,
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
        ctmRwa1Map = _map;
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
    function setIdentity(address _id) external onlyGov {
        identity = _id;
    }

    /**
     * @dev This function is called by CTMRWADeployer, allowing CTMRWA1SentryUtils to
     * deploy a CTMRWA1Sentry contract with the same ID as for the CTMRWA1 contract
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
     * @notice The tokenAdmin (Issuer) can optionally set conditions for trading the RWA via zkProofs.
     *
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

        (bool ok, address sentryAddr) = ICTMRWAMap(ctmRwa1Map).getSentryContract(_ID, RWA_TYPE, VERSION);
        require(ok, "CTMRWA1SentryManager: Could not find _ID or its sentry address");

        bool sentryOptionsSet = ICTMRWA1Sentry(sentryAddr).sentryOptionsSet();
        require(!sentryOptionsSet, "CTMRWA1SentryManager: Error. setSentryOptions has already been called");

        if (!_whitelist && !_kyc) {
            revert("CTMRWA1SentryManager: Must set either whitelist or KYC");
        }

        if (_kyb && !_kyc) {
            revert("CTMRWA1SentryManager: Must set KYC to use KYB");
        }

        if (_over18 && !_kyc) {
            revert("CTMRWA1SentryManager: Must set KYC to use over18 flag");
        }

        if (_accredited && !_kyc) {
            revert("CTMRWA1SentryManager: Must set KYC to use Accredited flag");
        }

        if (_accredited && !_countryWL) {
            revert("CTMRWA1SentryManager: Must set Country white lists to use Accredited");
        }

        if ((_countryWL || _countryBL) && !_kyc) {
            revert("CTMRWA1SentryManager: Must set KYC to use Country black or white lists");
        }

        if (_countryWL && _countryBL) {
            revert("CTMRWA1SentryManager: Cannot set Country blacklist and Country whitelist together");
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

                c3call(toRwaSentryStr, chainIdStr, callData);

                emit SettingSentryOptions(_ID, chainIdStr);
            }
        }
    }

    function setZkMeParams(uint256 _ID, string memory _appId, string memory _programNo, address _cooperator) public {
        require(identity != address(0), "CTMRWA1SentryManager: the CTMRWA1Identity contract has not been set");

        (address ctmRwa1Addr,) = _getTokenAddr(_ID);
        _checkTokenAdmin(ctmRwa1Addr);

        (address sentryAddr,) = _getSentryAddr(_ID);

        ICTMRWA1Sentry(sentryAddr).setZkMeParams(_appId, _programNo, _cooperator);
    }

    // removes the Accredited flag if KYC set
    function goPublic(uint256 _ID, string[] memory _chainIdsStr, string memory _feeTokenStr) public {
        (address ctmRwa1Addr,) = _getTokenAddr(_ID);
        _checkTokenAdmin(ctmRwa1Addr);

        (address sentryAddr,) = _getSentryAddr(_ID);

        bool kyc = ICTMRWA1Sentry(sentryAddr).kycSwitch();
        require(kyc, "CTMRWA1SentryManager: KYC was not set, so cannot go public");

        bool accredited = ICTMRWA1Sentry(sentryAddr).accreditedSwitch();
        require(accredited, "CTMRWA1SentryManager: Accredited was not set, so cannot go public");

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

                c3call(toRwaSentryStr, chainIdStr, callData);

                emit SettingSentryOptions(_ID, chainIdStr);
            }
        }
    }

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

    function addWhitelist(
        uint256 _ID,
        string[] memory _wallets,
        bool[] memory _choices,
        string[] memory _chainIdsStr,
        string memory _feeTokenStr
    ) public {
        require(_choices.length == _wallets.length, "CTMRWA1SentryManager: addWhitelist parameters lengths not equal");

        (address sentryAddr,) = _getSentryAddr(_ID);

        (address ctmRwa1Addr,) = _getTokenAddr(_ID);
        _checkTokenAdmin(ctmRwa1Addr);

        bool whitelistSwitch = ICTMRWA1Sentry(sentryAddr).whitelistSwitch();
        require(whitelistSwitch, "CTMRWA1SentryManager: The whitelistSwitch has not been set");

        uint256 len = _wallets.length;

        if (msg.sender != identity) {
            // charge a different fee if FeeType.KYC
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

                c3call(toRwaSentryStr, chainIdStr, callData);

                emit AddingWhitelist(_ID, chainIdStr);
            }
        }
    }

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

    function addCountrylist(
        uint256 _ID,
        string[] memory _countries,
        bool[] memory _choices,
        string[] memory _chainIdsStr,
        string memory _feeTokenStr
    ) public {
        require(
            _choices.length == _countries.length, "CTMRWA1SentryManager: addCountryList parameters lengths not equal"
        );

        (address sentryAddr,) = _getSentryAddr(_ID);

        (address ctmRwa1Addr,) = _getTokenAddr(_ID);
        _checkTokenAdmin(ctmRwa1Addr);

        bool countryWLSwitch = ICTMRWA1Sentry(sentryAddr).countryWLSwitch();
        bool countryBLSwitch = ICTMRWA1Sentry(sentryAddr).countryBLSwitch();
        require(
            (countryWLSwitch || countryBLSwitch),
            "CTMRWA1SentryManager: Neither country whitelist or blacklist has been set"
        );

        uint256 len = _countries.length;

        uint256 fee = _getFee(FeeType.COUNTRY, len, _chainIdsStr, _feeTokenStr);

        _payFee(fee, _feeTokenStr);

        for (uint256 i = 0; i < _chainIdsStr.length; i++) {
            string memory chainIdStr = _chainIdsStr[i]._toLower();

            if (chainIdStr.equal(cIdStr)) {
                ICTMRWA1Sentry(sentryAddr).setCountryListLocal(_ID, _countries, _choices);
            } else {
                (, string memory toRwaSentryStr) = _getSentry(chainIdStr);

                string memory funcCall = "setCountryListX(uint256,string[],bool[])";
                bytes memory callData = abi.encodeWithSignature(funcCall, _ID, _countries, _choices);

                c3call(toRwaSentryStr, chainIdStr, callData);

                emit AddingCountryList(_ID, chainIdStr);
            }
        }
    }

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

    function _payFee(uint256 _fee, string memory _feeTokenStr) internal returns (bool) {
        if (_fee > 0) {
            address feeToken = _feeTokenStr._stringToAddress();
            uint256 feeWei = _fee * 10 ** (IERC20Extended(feeToken).decimals() - 2);

            IERC20(feeToken).transferFrom(msg.sender, address(this), feeWei);

            IERC20(feeToken).approve(feeManager, feeWei);
            IFeeManager(feeManager).payFee(feeWei, _feeTokenStr);
        }
        return (true);
    }

    function _getFee(FeeType _feeType, uint256 _nItems, string[] memory _toChainIdsStr, string memory _feeTokenStr)
        internal
        view
        returns (uint256)
    {
        bool includeLocal = false; // local chain is already included in _toChainIdsStr

        uint256 fee = IFeeManager(feeManager).getXChainFee(_toChainIdsStr, includeLocal, _feeType, _feeTokenStr);

        return (fee * _nItems);
    }

    function getLastReason() public view returns (string memory) {
        string memory lastReason = ICTMRWA1SentryUtils(utilsAddr).getLastReason();
        return (lastReason);
    }

    function _getTokenAddr(uint256 _ID) internal view returns (address, string memory) {
        (bool ok, address tokenAddr) = ICTMRWAMap(ctmRwa1Map).getTokenContract(_ID, RWA_TYPE, VERSION);
        require(ok, "CTMRWA1SentryManager: The requested tokenID does not exist");
        string memory tokenAddrStr = tokenAddr.toHexString()._toLower();

        return (tokenAddr, tokenAddrStr);
    }

    function _getSentryAddr(uint256 _ID) internal view returns (address, string memory) {
        (bool ok, address sentryAddr) = ICTMRWAMap(ctmRwa1Map).getSentryContract(_ID, RWA_TYPE, VERSION);
        require(ok, "CTMRWA1SentryManager: Could not find _ID or its sentry address");
        string memory sentryAddrStr = sentryAddr.toHexString()._toLower();

        return (sentryAddr, sentryAddrStr);
    }

    function _getSentry(string memory _toChainIdStr) internal view returns (string memory, string memory) {
        require(!_toChainIdStr.equal(cIdStr), "CTMRWA1SentryManager: Not a cross-chain tokenAdmin change");

        string memory fromAddressStr = msg.sender.toHexString()._toLower();

        (bool ok, string memory toSentryStr) =
            ICTMRWAGateway(gateway).getAttachedSentryManager(RWA_TYPE, VERSION, _toChainIdStr);
        require(ok, "CTMRWA1SentryManager: Target contract address not found");

        return (fromAddressStr, toSentryStr);
    }

    function _checkTokenAdmin(address _tokenAddr) internal returns (address, string memory) {
        address currentAdmin = ICTMRWA1(_tokenAddr).tokenAdmin();
        string memory currentAdminStr = currentAdmin.toHexString()._toLower();

        require(msg.sender == currentAdmin || msg.sender == identity, "CTMRWA1SentryManager: Not tokenAdmin");

        return (currentAdmin, currentAdminStr);
    }

    function _c3Fallback(bytes4 _selector, bytes calldata _data, bytes calldata _reason)
        internal
        override
        returns (bool)
    {
        bool ok = ICTMRWA1SentryUtils(utilsAddr).sentryC3Fallback(_selector, _data, _reason);
        return ok;
    }
}
