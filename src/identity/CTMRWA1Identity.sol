// SPDX-License-Identifier: BSL-1.1

pragma solidity 0.8.27;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { console } from "forge-std/console.sol";

import {ICTMRWA1Identity} from "./ICTMRWA1Identity.sol";
import { ICTMRWA1, ITokenContract } from "../core/ICTMRWA1.sol";

import { CTMRWAUtils, Address } from "../CTMRWAUtils.sol";
import { FeeType, IFeeManager } from "../managers/IFeeManager.sol";
import { ICTMRWA1Sentry } from "../sentry/ICTMRWA1Sentry.sol";
import { ICTMRWA1SentryManager } from "../sentry/ICTMRWA1SentryManager.sol";
import { ICTMRWAMap } from "../shared/ICTMRWAMap.sol";

interface IZkMeVerify {
    function hasApproved(address cooperator, address user) external view returns (bool);
}

contract CTMRWA1Identity is ICTMRWA1Identity {
    using Strings for *;
    using SafeERC20 for IERC20;
    using CTMRWAUtils for string;

    uint256 public immutable RWA_TYPE;
    uint256 public immutable VERSION;
    address public ctmRwa1Map;
    address public sentryManager;
    address public zkMeVerifierAddress;
    address public feeManager;
    string cIdStr;

    modifier onlyIdChain() {
        // require(zkMeVerifierAddress != address(0));
        if (zkMeVerifierAddress == address(0)) revert CTMRWA1Identity_IsZeroAddress(Address.ZKMe);
        _;
    }

    modifier onlySentryManager() {
        if(msg.sender != sentryManager) revert CTMRWA1Identity_Unauthorized(Address.Sender);
        _;
    }

    event LogFallback(bytes4 selector, bytes data, bytes reason);
    event UserVerified(address indexed user);

    constructor(
        uint256 _rwaType,
        uint256 _version,
        address _map,
        address _sentryManager,
        address _verifierAddress,
        address _feeManager
    ) {
        RWA_TYPE = _rwaType;
        VERSION = _version;
        ctmRwa1Map = _map;
        sentryManager = _sentryManager;
        zkMeVerifierAddress = _verifierAddress;
        feeManager = _feeManager;

        cIdStr = block.chainid.toString();
    }

    function setZkMeVerifierAddress(address _verifierAddress) external onlySentryManager {
        zkMeVerifierAddress = _verifierAddress;
    }

    function verifyPerson(uint256 _ID, string[] memory _chainIdsStr, string memory _feeTokenStr)
        public
        onlyIdChain
        returns (bool)
    {
        // require(zkMeVerifierAddress != address(0), "CTMRWA1Identity: zkMe verifier has to be set");
        if (zkMeVerifierAddress == address(0)) revert CTMRWA1Identity_IsZeroAddress(Address.ZKMe);

        (bool ok, address sentryAddr) = ICTMRWAMap(ctmRwa1Map).getSentryContract(_ID, RWA_TYPE, VERSION);
        // require(ok, "CTMRWA1Identity: Could not find _ID or its sentry address");
        if (!ok) revert CTMRWA1Identity_InvalidContract(Address.Sentry);

        // require(ICTMRWA1Sentry(sentryAddr).kycSwitch(), "CTMRWA1Identity: KYC is not enabled for this CTMRWA1");
        if (!ICTMRWA1Sentry(sentryAddr).kycSwitch()) revert CTMRWA1Identity_KYCDisabled();

        // require(
        //     !ICTMRWA1Sentry(sentryAddr).isAllowableTransfer(msg.sender.toHexString()),
        //     "CTMRWA1Identity: User is already whitelisted"
        // );
        if (ICTMRWA1Sentry(sentryAddr).isAllowableTransfer(msg.sender.toHexString())) revert CTMRWA1Identity_AlreadyWhitelisted(msg.sender);

        (,, address cooperator) = ICTMRWA1Sentry(sentryAddr).getZkMeParams();
        // require(cooperator != address(0), "CTMRWA1Identity: zkMe cooperator address has not been set");
        if (cooperator == address(0)) revert CTMRWA1Identity_IsZeroAddress(Address.Cooperator);
        bool isValid = IZkMeVerify(zkMeVerifierAddress).hasApproved(cooperator, msg.sender);

        // require(isValid, "CTMRWA1Identity: Invalid KYC");
        if (!isValid) revert CTMRWA1Identity_InvalidKYC(msg.sender);

        _payFee(_feeTokenStr);

        ICTMRWA1SentryManager(sentryManager).addWhitelist(
            _ID, msg.sender.toHexString()._stringToArray(), CTMRWAUtils._boolToArray(true), _chainIdsStr, _feeTokenStr
        );

        return (true);
    }

    function isKycChain() public view returns (bool) {
        return (zkMeVerifierAddress != address(0));
    }

    function isVerifiedPerson(uint256 _ID, address _wallet) public view onlyIdChain returns (bool) {
        (bool ok, address sentryAddr) = ICTMRWAMap(ctmRwa1Map).getSentryContract(_ID, RWA_TYPE, VERSION);
        // require(ok, "CTMRWA1Identity: Could not find _ID or its sentry address");
        if (!ok) revert CTMRWA1Identity_InvalidContract(Address.Sentry);
        // require(ICTMRWA1Sentry(sentryAddr).kycSwitch(), "CTMRWA1Identity: KYC not set");
        if (!ICTMRWA1Sentry(sentryAddr).kycSwitch()) revert CTMRWA1Identity_KYCDisabled();

        (,, address cooperator) = ICTMRWA1Sentry(sentryAddr).getZkMeParams();
        // require(cooperator != address(0), "CTMRWA1Identity: zkMe cooperator address not set");
        if (cooperator == address(0)) revert CTMRWA1Identity_IsZeroAddress(Address.Cooperator);

        bool isValid = IZkMeVerify(zkMeVerifierAddress).hasApproved(cooperator, _wallet);

        return isValid;
    }

    function _payFee(string memory _feeTokenStr) internal returns (bool) {
        bool includeLocal = false;
        uint256 feeWei = IFeeManager(feeManager).getXChainFee(cIdStr._stringToArray(), includeLocal, FeeType.KYC, _feeTokenStr);

        if (feeWei > 0) {
            address feeToken = _feeTokenStr._stringToAddress();

            IERC20(feeToken).transferFrom(msg.sender, address(this), feeWei);

            IERC20(feeToken).approve(feeManager, feeWei);
            IFeeManager(feeManager).payFee(feeWei, _feeTokenStr);
        }
        return (true);
    }

}
