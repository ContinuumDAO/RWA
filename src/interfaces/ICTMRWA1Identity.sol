// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

enum RequestId {
    PERSONHOOD,
    KYB,
    OVER18,
    ACCREDITED,
    COUNTRY    
}

interface ICTMRWA1Identity {

    function setVerifierAddress(address _verifierAddress) external;
    function setZkMeVerifierAddress(address verifierAddress) external;
    function setSentryManager(address _sentryManager) external;
    function setFeeManager(address _feeManager) external;
    function setCtmRwaMap(address _map) external;

    function lastReason() external;

    function setRequestId(RequestId _requestId, uint64 _value) external returns(bool);

    function verifyPerson(
        uint256 ID,
        string[] memory chainIdsStr,
        string memory feeTokenStr
    ) external returns(bool);

    function submitCountryProof(
        uint256 ID,
        uint256[] calldata inputs,
        uint256[2] calldata a,
        uint256[2][2] calldata b,
        uint256[2] calldata c
    ) external returns(bool);

    function submitProof(
        RequestId requestIdType,
        uint64 requestId,
        uint256[] calldata inputs,
        uint256[2] calldata a,
        uint256[2][2] calldata b,
        uint256[2] calldata c
    ) external returns(bool);

    function isKycChain() external view returns(bool);

    function isVerifiedPerson(address wallet) external view returns (bool);
    function isVerifiedBusiness(address wallet) external view returns (bool);
    function isOver18(address wallet) external view returns (bool);
    function isAccreditedPerson(address wallet) external view returns (bool);
    function isVerifiedCountry(address wallet) external view returns (bool);
    
}
