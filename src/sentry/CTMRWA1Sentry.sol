// SPDX-License-Identifier: BSL-1.1

pragma solidity ^0.8.22;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import {ICTMRWA1Sentry} from "./ICTMRWA1Sentry.sol";
import { CTMRWAUtils, Address, Uint } from "../CTMRWAUtils.sol";
import { ICTMRWA1, ITokenContract } from "../core/ICTMRWA1.sol";
import { ICTMRWAMap } from "../shared/ICTMRWAMap.sol";

contract CTMRWA1Sentry is ICTMRWA1Sentry {
    using Strings for *;
    using CTMRWAUtils for string;

    address public tokenAddr;
    uint256 public ID;
    uint256 public immutable RWA_TYPE;
    uint256 public immutable VERSION;
    address sentryManagerAddr;
    address public tokenAdmin;
    address public ctmRwa1X;
    address public ctmRwa1Map;

    string appId; // same as Merchant No
    string programNo;
    address cooperator;

    bool public sentryOptionsSet;

    // // Whitelist of wallets permitted to hold CTMRWA1
    string[] public ctmWhitelist;
    mapping(string => uint256) private whitelistIndx;

    // List of countries for KYC (white OR black listed, depending on flag)
    string[] public countryList;
    mapping(string => uint256) private countryIndx;

    // Switches to be set by tokenAdmin

    bool public whitelistSwitch;
    bool public kycSwitch;
    bool public kybSwitch;
    bool public countryWLSwitch;
    bool public countryBLSwitch;
    bool public accreditedSwitch;
    bool public age18Switch;

    modifier onlyTokenAdmin() {
        // require(msg.sender == tokenAdmin || msg.sender == ctmRwa1X, "CTMRWA1Storage: onlyTokenAdmin function");
        if (msg.sender != tokenAdmin && msg.sender != ctmRwa1X) revert CTMRWA1Sentry_Unauthorized(Address.Sender);
        _;
    }

    modifier onlySentryManager() {
        // require(msg.sender == sentryManagerAddr, "CTMRWA1Sentry: onlySentryManager function");
        if (msg.sender != sentryManagerAddr) revert CTMRWA1Sentry_Unauthorized(Address.Sender);
        _;
    }

    constructor(
        uint256 _ID,
        address _tokenAddr,
        uint256 _rwaType,
        uint256 _version,
        address _sentryManager,
        address _map
    ) {
        ID = _ID;
        RWA_TYPE = _rwaType;
        VERSION = _version;
        ctmRwa1Map = _map;

        tokenAddr = _tokenAddr;

        tokenAdmin = ICTMRWA1(tokenAddr).tokenAdmin();
        ctmRwa1X = ICTMRWA1(tokenAddr).ctmRwa1X();

        sentryManagerAddr = _sentryManager;

        ctmWhitelist.push("0xffffffffffffffffffffffffffffffffffffffff"); // indx 0 is no go
        _setWhitelist(tokenAdmin.toHexString()._stringToArray(), CTMRWAUtils._boolToArray(true));

        countryList.push("NOGO");
    }

    function setTokenAdmin(address _tokenAdmin) external onlyTokenAdmin returns (bool) {
        tokenAdmin = _tokenAdmin;

        if (tokenAdmin != address(0)) {
            string memory tokenAdminStr = tokenAdmin.toHexString()._toLower();
            tokenAdminStr = _tokenAdmin.toHexString()._toLower();
            _setWhitelist(tokenAdminStr._stringToArray(), CTMRWAUtils._boolToArray(true)); // don't strand tokens held
                // by the old
                // tokenAdmin
        }

        return (true);
    }

    function setZkMeParams(string memory _appId, string memory _programNo, address _cooperator)
        external
        onlySentryManager
    {
        appId = _appId;
        programNo = _programNo;
        cooperator = _cooperator;
    }

    function getZkMeParams() public view returns (string memory, string memory, address) {
        return (appId, programNo, cooperator);
    }

    function setSentryOptionsLocal(
        uint256 _ID,
        bool _whitelist,
        bool _kyc,
        bool _kyb,
        bool _over18,
        bool _accredited,
        bool _countryWL,
        bool _countryBL
    ) external onlySentryManager {
        // require(_ID == ID, "CTMRWA1Sentry: Attempt to setSentryOptionsLocal to an incorrect ID");
        if (_ID != ID) revert CTMRWA1Sentry_InvalidID(ID, _ID);

        if (_whitelist) {
            whitelistSwitch = true;
        }

        if (_kyc) {
            kycSwitch = true;
        }

        if (_kyb && _kyc) {
            kybSwitch = true;
        }

        if (_over18 && _kyc) {
            age18Switch = true;
        }

        if (_countryWL && _kyc) {
            countryWLSwitch = true;
            accreditedSwitch = _accredited;
        } else if (_countryBL && _kyc) {
            countryBLSwitch = true;
        }

        sentryOptionsSet = true;
    }

    function setWhitelistSentry(uint256 _ID, string[] memory _wallets, bool[] memory _choices)
        external
        onlySentryManager
    {
        // require(_ID == ID, "CTMRWA1Sentry: Attempt to setSentryOptionsLocal to an incorrect ID");
        if (_ID != ID) revert CTMRWA1Sentry_InvalidID(ID, _ID);
        _setWhitelist(_wallets, _choices);
    }

    function setCountryListLocal(uint256 _ID, string[] memory _countryList, bool[] memory _choices)
        external
        onlySentryManager
    {
        // require(_ID == ID, "CTMRWA1Sentry: Attempt to setSentryOptionsLocal to an incorrect ID");
        if (_ID != ID) revert CTMRWA1Sentry_InvalidID(ID, _ID);

        _setCountryList(_countryList, _choices);
    }

    function _setWhitelist(string[] memory _wallets, bool[] memory _choices) internal {
        uint256 len = _wallets.length;

        uint256 indx;
        string memory adminStr = tokenAdmin.toHexString()._toLower();
        string memory walletStr;
        string memory oldLastStr;

        for (uint256 i = 0; i < len; i++) {
            walletStr = _wallets[i]._toLower();
            indx = whitelistIndx[walletStr];

            if (walletStr.equal(adminStr) && !_choices[i]) {
                // revert("CTMRWA1Sentry: Cannot remove tokenAdmin from the whitelist");
                if (walletStr.equal(adminStr) && !_choices[i]) revert CTMRWA1Sentry_Unauthorized(Address.Admin);
            } else if (indx != 0 && indx == ctmWhitelist.length - 1 && !_choices[i]) {
                // last entry to be removed
                whitelistIndx[walletStr] = 0;
                ctmWhitelist.pop();
            } else if (indx != 0 && !_choices[i]) {
                // existing entry to be removed and precludes changing tokenAdmin
                oldLastStr = ctmWhitelist[ctmWhitelist.length - 1];
                ctmWhitelist[indx] = oldLastStr;
                whitelistIndx[walletStr] = 0;
                whitelistIndx[oldLastStr] = indx;
                ctmWhitelist.pop();
            } else if (indx == 0 && _choices[i]) {
                // New entry
                ctmWhitelist.push(walletStr);
                whitelistIndx[walletStr] = ctmWhitelist.length - 1;
            }
        }
    }

    // This function uses the 2 letter ISO Country Codes listed here:
    // https://docs.dnb.com/partner/en-US/iso_country_codes
    function _setCountryList(string[] memory _countries, bool[] memory _choices) internal {
        uint256 len = _countries.length;
        uint256 indx;
        string memory oldLastStr;

        for (uint256 i = 0; i < len; i++) {
            // require(bytes(_countries[i]).length == 2, "CTMRWA1Sentry: ISO Country must have 2 letters");
            if (bytes(_countries[i]).length != 2) revert CTMRWA1Sentry_InvalidLength(Uint.CountryCode);

            indx = countryIndx[_countries[i]];

            if (indx != 0 && indx == countryList.length - 1 && !_choices[i]) {
                // last entry to be removed
                countryIndx[_countries[i]] = 0;
                countryList.pop();
            } else if (indx != 0 && !_choices[i]) {
                // existing entry to be removed
                oldLastStr = countryList[countryList.length - 1];
                countryList[indx] = oldLastStr;
                countryIndx[_countries[i]] = 0;
                countryIndx[oldLastStr] = indx;
                countryList.pop();
            } else if (indx == 0 && _choices[i]) {
                // New entry
                countryList.push(_countries[i]);
                countryIndx[_countries[i]] = countryList.length - 1;
            }
        }
    }

    function isAllowableTransfer(string memory _user) public view returns (bool) {
        bool ok;
        address dividendContract;
        (ok, dividendContract) = ICTMRWAMap(ctmRwa1Map).getDividendContract(ID, RWA_TYPE, VERSION);

        address investContract;
        (ok, investContract) = ICTMRWAMap(ctmRwa1Map).getInvestContract(ID, RWA_TYPE, VERSION);

        if (!whitelistSwitch || _user._stringToAddress() == address(0)) {
            return (true);
        } else if (_user.equal(dividendContract.toHexString()) || _user.equal(investContract.toHexString())) {
            return (true);
        } else {
            string memory walletStr = _user._toLower();
            return (_isWhitelisted(walletStr));
        }
    }

    function getWhitelistLength() public view returns (uint256) {
        return (ctmWhitelist.length - 1);
    }

    function getWhitelistAddressAtIndx(uint256 _indx) public view returns (string memory) {
        return (ctmWhitelist[_indx]);
    }

    function _isWhitelisted(string memory _walletStr) internal view returns (bool) {
        uint256 indx = whitelistIndx[_walletStr];

        if (indx == 0) {
            return (false);
        } else {
            return (true);
        }
    }

    function cID() internal view returns (uint256) {
        return block.chainid;
    }

    function strToUint(string memory _str) internal pure returns (uint256 res, bool err) {
        if (bytes(_str).length == 0) {
            return (0, true);
        }
        for (uint256 i = 0; i < bytes(_str).length; i++) {
            if ((uint8(bytes(_str)[i]) - 48) < 0 || (uint8(bytes(_str)[i]) - 48) > 9) {
                return (0, false);
            }
            res += (uint8(bytes(_str)[i]) - 48) * 10 ** (bytes(_str).length - i - 1);
        }

        return (res, true);
    }

    // TODO: implement or remove these functions
    function setSentryOptionsFlag() external {}

    function setWhitelist() external {}

    function switchCountry(bool choice) external {}
}
