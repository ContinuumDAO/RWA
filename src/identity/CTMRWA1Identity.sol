// SPDX-License-Identifier: BSL-1.1

pragma solidity 0.8.27;

import { ICTMRWA1, ITokenContract } from "../core/ICTMRWA1.sol";
import { FeeType, IFeeManager } from "../managers/IFeeManager.sol";
import { ICTMRWA1Sentry } from "../sentry/ICTMRWA1Sentry.sol";
import { ICTMRWA1SentryManager } from "../sentry/ICTMRWA1SentryManager.sol";
import { ICTMRWAMap } from "../shared/ICTMRWAMap.sol";
import { CTMRWAUtils, CTMRWAErrorParam } from "../utils/CTMRWAUtils.sol";
import { ICTMRWA1Identity } from "./ICTMRWA1Identity.sol";
import { IZkMeVerify } from "./IZkMeVerify.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title AssetX Multi-chain Semi-Fungible-Token for Real-World-Assets (RWAs)
 * @author @Selqui ContinuumDAO
 *
 * @notice This contract is to allow a user to register their KYC credentials and if they
 * satisfy the requirements of the KYC Schema, then their address is Whitelisted in the RWA token
 * on all chains. It allows truly decentralized & anonymous cross-chain credential verifications.
 * NOTE: This contract currently is only configured to work with zkMe (https://zk.me), but will be extended
 * in the future to include other zkProof identity systems.
 * NOTE: This contract is only deployed on some chains, corrsponding to where the zkMe verifier contract is.
 * This means that if an Issuer wants to use KYC using zkMe, they must first add one of these chains to their
 * RWA token AND ONLY THEN call setSentryOptions to enable the _kyc flag. IT HAS TO BE DONE IN THIS ORDER.
 */
contract CTMRWA1Identity is ICTMRWA1Identity, ReentrancyGuard {
    using Strings for *;
    using SafeERC20 for IERC20;
    using CTMRWAUtils for string;

    /// @dev rwaType is the RWA type defining CTMRWA1
    uint256 public immutable RWA_TYPE;

    /// @dev version is the single integer version of this RWA type
    uint256 public immutable VERSION;

    /// @dev The address of the CTMRWAMap contract
    address public ctmRwa1Map;

    /// @dev The address of the CTMRWA1SentryManager contract
    address public sentryManager;

    /// @dev The address of the zKMe Verifier contract
    address public zkMeVerifierAddress;

    /// @dev The address of the FeeManager contract
    address public feeManager;

    /// @dev The chainId as a string
    string cIdStr;

    modifier onlyIdChain() {
        if (zkMeVerifierAddress == address(0)) {
            revert CTMRWA1Identity_IsZeroAddress(CTMRWAErrorParam.ZKMe);
        }
        _;
    }

    modifier onlySentryManager() {
        if (msg.sender != sentryManager) {
            revert CTMRWA1Identity_OnlyAuthorized(CTMRWAErrorParam.Sender, CTMRWAErrorParam.SentryManager);
        }
        _;
    }

    modifier onlyTokenAdmin(uint256 _ID) {
        (bool ok, address sentryAddr) = ICTMRWAMap(ctmRwa1Map).getSentryContract(_ID, RWA_TYPE, VERSION);
        if (!ok) {
            revert CTMRWA1Identity_InvalidContract(CTMRWAErrorParam.Sentry);
        }
        address tokenAdmin = ICTMRWA1Sentry(sentryAddr).tokenAdmin();
        if (msg.sender != tokenAdmin) {
            revert CTMRWA1Identity_OnlyAuthorized(CTMRWAErrorParam.Sender, CTMRWAErrorParam.TokenAdmin);
        }
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

    /// @dev Set the zkMe Verifier address (see
    /// https://docs.zk.me/zkme-dochub/verify-with-zkme-protocol/integration-guide)
    function setZkMeVerifierAddress(address _verifierAddress) external onlySentryManager {
        zkMeVerifierAddress = _verifierAddress;
    }

    /**
     * @notice Once a user has performed KYC with the provider, this function lets them
     * submit their credentials to the Verifier by calling the hasApproved function. If they pass,
     * then their wallet address is added tot he RWA token Whitelist via a call to CTMRWASentryManager
     * @param _ID The ID of the RWA token
     * @param _version The version of the RWA token
     * @param _chainIdsStr This is an array of strings of chainIDs to deploy to.
     * @param _feeTokenStr This is fee token on the source chain (local chain) that you wish to use to pay
     * for the deployment. See the function feeTokenList in the FeeManager contract for allowable values.
     * @return success True if the person was verified, false otherwise.
     */
    function verifyPerson(uint256 _ID, uint256 _version, string[] memory _chainIdsStr, string memory _feeTokenStr)
        public
        onlyIdChain
        nonReentrant
        returns (bool)
    {
        if (zkMeVerifierAddress == address(0)) {
            revert CTMRWA1Identity_IsZeroAddress(CTMRWAErrorParam.ZKMe);
        }

        (bool ok, address sentryAddr) = ICTMRWAMap(ctmRwa1Map).getSentryContract(_ID, RWA_TYPE, _version);
        if (!ok) {
            revert CTMRWA1Identity_InvalidContract(CTMRWAErrorParam.Sentry);
        }

        if (!ICTMRWA1Sentry(sentryAddr).kycSwitch()) {
            revert CTMRWA1Identity_KYCDisabled();
        }

        if (ICTMRWA1Sentry(sentryAddr).isAllowableTransfer(msg.sender.toHexString())) {
            revert CTMRWA1Identity_AlreadyWhitelisted(msg.sender);
        }

        (,, address cooperator) = ICTMRWA1Sentry(sentryAddr).getZkMeParams();
        if (cooperator == address(0)) {
            revert CTMRWA1Identity_IsZeroAddress(CTMRWAErrorParam.Cooperator);
        }
        bool isValid = IZkMeVerify(zkMeVerifierAddress).hasApproved(cooperator, msg.sender);

        if (!isValid) {
            revert CTMRWA1Identity_InvalidKYC(msg.sender);
        }

        _payFee(_chainIdsStr, _feeTokenStr);

        ICTMRWA1SentryManager(sentryManager).addWhitelist(
            _ID, _version, msg.sender.toHexString()._stringToArray(), CTMRWAUtils._boolToArray(true), _chainIdsStr, _feeTokenStr
        );

        return (true);
    }

    /**
     * @dev This checks if the zkMe Verifier contract has been set for this chain. If it returns false,
     * then either the zkMeVerifier contract address has not yet been set (a deployment issue), or the
     * current chain does not allow zkMe verification
     * @return success True if the chain is a KYC chain, false otherwise.
     */
    function isKycChain() public view returns (bool) {
        return (zkMeVerifierAddress != address(0));
    }

    /**
     * @notice Check if a wallet address has the correct credentials to satisfy the Schema of
     * the currently implemeted zkMe programNo.
     * @param _ID The ID of the RWA token
     * @param _version The version of the RWA token
     * @param _wallet The wallet address to check
     * NOTE that since the zkMe parameters can be updated, a user wallet can change its status
     * NOTE This function does NOT check if a wallet address is currently Whitelisted
     */
    function isVerifiedPerson(uint256 _ID, uint256 _version, address _wallet) public view onlyIdChain returns (bool) {
        (bool ok, address sentryAddr) = ICTMRWAMap(ctmRwa1Map).getSentryContract(_ID, RWA_TYPE, _version);
        if (!ok) {
            revert CTMRWA1Identity_InvalidContract(CTMRWAErrorParam.Sentry);
        }
        if (!ICTMRWA1Sentry(sentryAddr).kycSwitch()) {
            revert CTMRWA1Identity_KYCDisabled();
        }

        (,, address cooperator) = ICTMRWA1Sentry(sentryAddr).getZkMeParams();
        if (cooperator == address(0)) {
            revert CTMRWA1Identity_IsZeroAddress(CTMRWAErrorParam.Cooperator);
        }

        bool isValid = IZkMeVerify(zkMeVerifierAddress).hasApproved(cooperator, _wallet);

        return isValid;
    }

    /// @dev Pay the fees for verifyPerson KYC
    /// @return success True if the fee was paid, false otherwise.
    function _payFee(string[] memory _chainIdsStr, string memory _feeTokenStr) internal returns (bool) {
        bool includeLocal = false;
        uint256 feeWei = IFeeManager(feeManager).getXChainFee(_chainIdsStr, includeLocal, FeeType.KYC, _feeTokenStr);
        feeWei = feeWei * (10000 - IFeeManager(feeManager).getFeeReduction(msg.sender)) / 10000;

        if (feeWei > 0) {
            address feeToken = _feeTokenStr._stringToAddress();

            // Record spender balance before transfer
            uint256 senderBalanceBefore = IERC20(feeToken).balanceOf(msg.sender);

            IERC20(feeToken).safeTransferFrom(msg.sender, address(this), feeWei);

            // Assert spender balance change
            uint256 senderBalanceAfter = IERC20(feeToken).balanceOf(msg.sender);
            if (senderBalanceBefore - senderBalanceAfter != feeWei) {
                revert CTMRWA1Identity_FailedTransfer();
            }

            IERC20(feeToken).forceApprove(feeManager, feeWei);
            IFeeManager(feeManager).payFee(feeWei, _feeTokenStr);
        }
        return (true);
    }
}
