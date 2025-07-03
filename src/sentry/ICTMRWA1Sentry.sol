// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

interface ICTMRWA1Sentry {
    function ID() external returns(uint256);
    function tokenAdmin() external returns(address);
    function setTokenAdmin(address _tokenAdmin) external returns(bool);
    function ctmWhitelist() external returns(string[] memory);
    function countryList() external returns(string[] memory);

    function setSentryOptionsFlag() external;
    function sentryOptionsSet() external returns(bool);

    function setZkMeParams(string memory merchantNo, string memory programNo, address cooperator) external;
    function getZkMeParams() external view returns(string memory, string memory, address);

    function whitelistSwitch() external view returns(bool);
    function kycSwitch() external view returns(bool);
    function kybSwitch() external view returns(bool);
    function countryWLSwitch() external view returns(bool);
    function countryBLSwitch() external view returns(bool);
    function accreditedSwitch() external view returns(bool);
    function age18Switch() external view returns(bool);

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

    function setCountryListLocal(
        uint256 ID,
        string[] memory countryList,
        bool[] memory choices
    ) external;


    function getWhitelistAddressAtIndx(uint256 _indx) external view returns(string memory);
    function getWhitelistLength() external returns(uint256);

    function setWhitelist() external;
    function switchCountry(bool choice) external;


    function isAllowableTransfer(string memory _user) external view returns(bool);
    function setWhitelistSentry(uint256 ID, string[] memory _wallets, bool[] memory _choices) external;
}
