// SPDX-License-Identifier: BSL-1.1

pragma solidity 0.8.27;

import { ICTMRWA } from "../core/ICTMRWA.sol";
import { CTMRWAErrorParam } from "../utils/CTMRWAUtils.sol";

interface ICTMRWA1SentryManager is ICTMRWA {
    error CTMRWA1SentryManager_OnlyAuthorized(CTMRWAErrorParam, CTMRWAErrorParam);
    error CTMRWA1SentryManager_IsZeroAddress(CTMRWAErrorParam);
    error CTMRWA1SentryManager_InvalidContract(CTMRWAErrorParam);

    error CTMRWA1SentryManager_OptionsAlreadySet();
    error CTMRWA1SentryManager_NoKYC();
    error CTMRWA1SentryManager_KYCDisabled();
    error CTMRWA1SentryManager_AccreditationDisabled();
    error CTMRWA1SentryManager_LengthMismatch(CTMRWAErrorParam);
    error CTMRWA1SentryManager_SameChain();
    error CTMRWA1SentryManager_InvalidLength(CTMRWAErrorParam);

    error CTMRWA1SentryManager_InvalidList(CTMRWAErrorParam);

    function gateway() external view returns (address);
    function feeManager() external view returns (address);
    function ctmRwaDeployer() external view returns (address);
    function ctmRwaMap() external view returns (address);
    function utilsAddr() external view returns (address);
    function identity() external view returns (address);

    function setGateway(address gateway) external;
    function setFeeManager(address feeManager) external;
    function setCtmRwaDeployer(address deployer) external;
    function setCtmRwaMap(address map) external;
    function setSentryUtils(address utilsAddr) external;
    function setIdentity(address id, address zkMeVerifierAddr) external;

    function getLastReason() external view returns (string memory);

    function deploySentry(uint256 ID, address tokenAddr, uint256 rwaType, uint256 version, address map)
        external
        returns (address);

    function setSentryOptions(
        uint256 ID,
        bool whitelistOnly,
        bool kyc,
        bool kyb,
        bool over18,
        bool accredited,
        bool countryWL,
        bool countryBL,
        string[] memory chainIdsStr,
        string memory feeTokenStr
    ) external;

    function goPublic(uint256 _ID, string[] memory _chainIdsStr, string memory _feeTokenStr) external;

    function addWhitelist(
        uint256 ID,
        string[] memory wallets,
        bool[] memory choices,
        string[] memory chainIdsStr,
        string memory feeTokenStr
    ) external;

    function addCountrylist(
        uint256 ID,
        string[] memory countries,
        bool[] memory choices,
        string[] memory chainIdsStr,
        string memory feeTokenStr
    ) external;
}
