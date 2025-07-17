// SPDX-License-Identifier: BSL-1.1

pragma solidity 0.8.27;

import { ICTMRWA } from "../core/ICTMRWA.sol";
import { Address, Uint } from "../CTMRWAUtils.sol";

interface ICTMRWA1Sentry is ICTMRWA {
    error CTMRWA1Sentry_Unauthorized(Address);
    error CTMRWA1Sentry_InvalidID(uint256 expected, uint256 actual);
    error CTMRWA1Sentry_InvalidLength(Uint);

    function ID() external view returns (uint256);
    function tokenAdmin() external view returns (address);
    function setTokenAdmin(address _tokenAdmin) external returns (bool);
    function ctmWhitelist(uint256 index) external view returns (string memory);
    function countryList(uint256 index) external view returns (string memory);

    function sentryOptionsSet() external returns (bool);

    function setZkMeParams(string memory appId, string memory programNo, address cooperator) external;
    function getZkMeParams() external view returns (string memory, string memory, address);

    function whitelistSwitch() external view returns (bool);
    function kycSwitch() external view returns (bool);
    function kybSwitch() external view returns (bool);
    function countryWLSwitch() external view returns (bool);
    function countryBLSwitch() external view returns (bool);
    function accreditedSwitch() external view returns (bool);
    function age18Switch() external view returns (bool);

    function setSentryOptionsLocal(
        uint256 ID,
        bool whitelistOnly,
        bool kyc,
        bool kyb,
        bool over18,
        bool accredited,
        bool countryWL,
        bool countryBL
    ) external;

    function setCountryListLocal(uint256 ID, string[] memory countryList, bool[] memory choices) external;

    function getWhitelistAddressAtIndx(uint256 _indx) external view returns (string memory);
    function getWhitelistLength() external returns (uint256);

    function isAllowableTransfer(string memory _user) external view returns (bool);
    function setWhitelistSentry(uint256 ID, string[] memory _wallets, bool[] memory _choices) external;
}
