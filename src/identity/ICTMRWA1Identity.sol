// SPDX-License-Identifier: BSL-1.1

pragma solidity 0.8.27;

import { ICTMRWA } from "../core/ICTMRWA.sol";
import { Address } from "../utils/CTMRWAUtils.sol";

enum RequestId {
    PERSONHOOD,
    KYB,
    OVER18,
    ACCREDITED,
    COUNTRY
}

interface ICTMRWA1Identity is ICTMRWA {
    error CTMRWA1Identity_OnlyAuthorized(Address, Address);
    error CTMRWA1Identity_IsZeroAddress(Address);
    error CTMRWA1Identity_InvalidContract(Address);
    error CTMRWA1Identity_KYCDisabled();
    error CTMRWA1Identity_AlreadyWhitelisted(address);
    error CTMRWA1Identity_InvalidKYC(address);
    error CTMRWA1Identity_VerifyPersonPaused();

    function setZkMeVerifierAddress(address verifierAddress) external;

    function pause(uint256 ID) external;
    function unpause(uint256 ID) external;
    function isPaused() external view returns (bool);

    function verifyPerson(uint256 ID, string[] memory chainIdsStr, string memory feeTokenStr) external returns (bool);

    function isKycChain() external view returns (bool);

    function isVerifiedPerson(uint256 ID, address wallet) external view returns (bool);
}
