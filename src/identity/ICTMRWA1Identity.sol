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
    error CTMRWA1Identity_Unauthorized(Address);
    error CTMRWA1Identity_IsZeroAddress(Address);
    error CTMRWA1Identity_InvalidContract(Address);
    error CTMRWA1Identity_KYCDisabled();
    error CTMRWA1Identity_AlreadyWhitelisted(address);
    error CTMRWA1Identity_InvalidKYC(address);

    function setZkMeVerifierAddress(address verifierAddress) external;

    function verifyPerson(uint256 ID, string[] memory chainIdsStr, string memory feeTokenStr) external returns (bool);

    function isKycChain() external view returns (bool);

    function isVerifiedPerson(uint256 ID, address wallet) external view returns (bool);
}
