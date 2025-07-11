// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.22;

import {ICTMRWA} from "../core/ICTMRWA.sol";

interface ICTMRWA1SentryManager is ICTMRWA {
    function setGateway(address gateway) external;
    function setFeeManager(address feeManager) external;
    function setCtmRwaDeployer(address deployer) external;
    function setCtmRwaMap(address map) external;
    function setSentryUtils(address utilsAddr) external;
    function utilsAddr() external returns (address);

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
