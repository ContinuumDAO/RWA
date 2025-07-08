// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.22;

enum RequestId {
    PERSONHOOD,
    KYB,
    OVER18,
    ACCREDITED,
    COUNTRY
}

interface ICTMRWA1Identity {
    function setZkMeVerifierAddress(address verifierAddress) external;
    function setSentryManager(address _sentryManager) external;
    function setFeeManager(address _feeManager) external;
    function setCtmRwaMap(address _map) external;

    function verifyPerson(uint256 ID, string[] memory chainIdsStr, string memory feeTokenStr) external returns (bool);

    function isKycChain() external view returns (bool);

    function isVerifiedPerson(uint256 ID, address wallet) external view returns (bool);
}
