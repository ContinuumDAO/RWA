// SPDX-License-Identifier: BSL-1.1

pragma solidity ^0.8.22;

import { ICTMRWA } from "../core/ICTMRWA.sol";

enum RequestId {
    PERSONHOOD,
    KYB,
    OVER18,
    ACCREDITED,
    COUNTRY
}

interface ICTMRWA1Identity is ICTMRWA {
    function setZkMeVerifierAddress(address verifierAddress) external;
    function setSentryManager(address _sentryManager) external;
    function setFeeManager(address _feeManager) external;
    function setCtmRwaMap(address _map) external;

    function verifyPerson(uint256 ID, string[] memory chainIdsStr, string memory feeTokenStr) external returns (bool);

    function isKycChain() external view returns (bool);

    function isVerifiedPerson(uint256 ID, address wallet) external view returns (bool);
}
