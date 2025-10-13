// SPDX-License-Identifier: BSL-1.1

pragma solidity 0.8.27;

import { ICTMRWA } from "../core/ICTMRWA.sol";
import { CTMRWAErrorParam } from "../utils/CTMRWAUtils.sol";

enum RequestId {
    PERSONHOOD,
    KYB,
    OVER18,
    ACCREDITED,
    COUNTRY
}

interface ICTMRWA1Identity is ICTMRWA {
    error CTMRWA1Identity_OnlyAuthorized(CTMRWAErrorParam, CTMRWAErrorParam);
    error CTMRWA1Identity_IsZeroAddress(CTMRWAErrorParam);
    error CTMRWA1Identity_InvalidContract(CTMRWAErrorParam);
    error CTMRWA1Identity_KYCDisabled();
    error CTMRWA1Identity_AlreadyWhitelisted(address);
    error CTMRWA1Identity_InvalidKYC(address);
    error CTMRWA1Identity_FailedTransfer();

    function setZkMeVerifierAddress(address verifierAddress) external;

    function verifyPerson(uint256 ID, uint256 version, string[] memory chainIdsStr, string memory feeTokenStr) external returns (bool);

    function isKycChain() external view returns (bool);

    function isVerifiedPerson(uint256 ID, uint256 version, address wallet) external view returns (bool);
}
