// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.23;


interface ICTMRWA001PolygonId {

    function setPolygonIdServer(address _polygonIdServer) external;
    function setSentryManager(address _sentryManager) external;
    function setFeeManager(address _feeManager) external;
    function setCtmRwaMap(address _map) external;

    function lastReason() external;

    function verifyPerson(
        uint256 ID,
        bytes memory personhoodProof,
        bytes memory businessProof,
        bytes memory accreditedProof,
        bytes memory over18Proof,
        bytes memory inCountryWLProof,
        bytes memory notInCountryBLProof,
        string[] memory _chainIdsStr,
        string memory _feeTokenStr
    ) external returns(bool);

    function isKycChain() external view returns(bool);
    
}