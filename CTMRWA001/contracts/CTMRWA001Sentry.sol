// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import "forge-std/console.sol";


import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";


import {ICTMRWA001, ITokenContract} from "./interfaces/ICTMRWA001.sol";
import {ICTMRWAMap} from "./interfaces/ICTMRWAMap.sol";

contract CTMRWA001Sentry is Context {
    using Strings for *;

    address public tokenAddr;
    uint256 public ID;
    uint256 rwaType;
    uint256 version;
    address sentryManagerAddr;
    address public tokenAdmin;
    address public ctmRwa001X;
    address public ctmRwa001Map;

    bool public sentryOptionsSet;

    // // Whitelist of wallets permitted to hold CTMRWA001
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
        require(
            _msgSender() == tokenAdmin || _msgSender() == ctmRwa001X, 
            "CTMRWA001Storage: onlyTokenAdmin function"
        );
        _;
    }

    modifier onlySentryManager() {
        require(
            _msgSender() == sentryManagerAddr,
            "CTMRWA001Sentry: onlySentryManager function"
        );
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
        rwaType = _rwaType;
        version = _version;
        ctmRwa001Map = _map;

        tokenAddr = _tokenAddr;

        tokenAdmin = ICTMRWA001(tokenAddr).tokenAdmin();
        ctmRwa001X = ICTMRWA001(tokenAddr).ctmRwa001X();
        
        sentryManagerAddr = _sentryManager;

        ctmWhitelist.push("0xffffffffffffffffffffffffffffffffffffffff"); // indx 0 is no go
        _setWhitelist(_stringToArray(tokenAdmin.toHexString()), _boolToArray(true));

        countryList.push("NOGO");

    }

    function setTokenAdmin(address _tokenAdmin) external onlyTokenAdmin returns(bool) {

        tokenAdmin = _tokenAdmin;

        if (tokenAdmin != address(0)) {
            string memory tokenAdminStr = _toLower(tokenAdmin.toHexString());
            tokenAdminStr = _toLower(_tokenAdmin.toHexString());
            _setWhitelist(_stringToArray(tokenAdminStr), _boolToArray(true)); // don't strand tokens held by the old tokenAdmin
        }
        
        return(true);
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

        require(_ID == ID, "CTMRWA001Sentry: Attempt to setSentryOptionsLocal to an incorrect ID");

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


    function setWhitelistSentry(uint256 _ID, string[] memory _wallets, bool[] memory _choices) external onlySentryManager {
        require(_ID == ID, "CTMRWA001Sentry: Attempt to setSentryOptionsLocal to an incorrect ID");
        _setWhitelist(_wallets, _choices);
    }

    function setCountryListLocal(
        uint256 _ID,
        string[] memory _countryList,
        bool[] memory _choices
    ) external onlySentryManager {

        require(_ID == ID, "CTMRWA001Sentry: Attempt to setSentryOptionsLocal to an incorrect ID");

        _setCountryList(_countryList, _choices);
    }


    function _setWhitelist(string[] memory _wallets, bool[] memory _choices) internal {
        uint256 len = _wallets.length;
        
        uint256 indx;
        string memory adminStr = _toLower(tokenAdmin.toHexString());
        string memory walletStr;
        string memory oldLastStr;
        

        for (uint256 i=0; i<len; i++) {
            walletStr = _toLower(_wallets[i]);
            indx = whitelistIndx[walletStr];
            
            if (stringsEqual(walletStr, adminStr) && !_choices[i]) {
                revert("CTMRWA001Sentry: Cannot remove tokenAdmin from the whitelist");
            } else if (
                indx != 0 && 
                indx == ctmWhitelist.length - 1 && 
                !_choices[i]
            ) { // last entry to be removed
                whitelistIndx[walletStr] = 0;
                ctmWhitelist.pop();
            } else if (indx != 0 && !_choices[i]) {  // existing entry to be removed and precludes changing tokenAdmin
                oldLastStr = ctmWhitelist[ctmWhitelist.length - 1];
                ctmWhitelist[indx] = oldLastStr;
                whitelistIndx[walletStr] = 0;
                whitelistIndx[oldLastStr] = indx;
                ctmWhitelist.pop();
            } else if (indx == 0 && _choices[i]) { // New entry
                ctmWhitelist.push(walletStr);
                whitelistIndx[walletStr] = ctmWhitelist.length - 1;
            }
        }
    }

    // This function uses the 2 letter ISO Country Codes listed here: 
    // https://docs.dnb.com/partner/en-US/iso_country_codes
    function _setCountryList(
        string[] memory _countries,
        bool[] memory _choices
    ) internal {

        uint256 len = _countries.length;
        uint256 indx;
        string memory oldLastStr;

        for (uint256 i=0; i<len; i++) {
            require(bytes(_countries[i]).length == 2, "CTMRWA001Sentry: ISO Country must have 2 letters");

            indx = countryIndx[_countries[i]];

            if (
                indx != 0 && 
                indx == countryList.length - 1 && 
                !_choices[i]
            ) { // last entry to be removed
                countryIndx[_countries[i]] = 0;
                countryList.pop();
            } else if (indx != 0 && !_choices[i]) {  // existing entry to be removed
                oldLastStr = countryList[countryList.length - 1];
                countryList[indx] = oldLastStr;
                countryIndx[_countries[i]] = 0;
                countryIndx[oldLastStr] = indx;
                countryList.pop();
            } else if (indx == 0 && _choices[i]) { // New entry
                countryList.push(_countries[i]);
                countryIndx[_countries[i]] = countryList.length - 1;
            }
        }
    }

    function isAllowableTransfer(string memory _user) public view returns(bool) {
        if (!whitelistSwitch || stringToAddress(_user) == address(0)) {
            return(true);
        } else {
            string memory walletStr = _toLower(_user);
            return(_isWhitelisted(walletStr));
        }
    }

    function getWhitelistLength() public view returns(uint256) {
        return(ctmWhitelist.length - 1);
    }

    function getWhitelistAddressAtIndx(uint256 _indx) public view returns(string memory) {
        return(ctmWhitelist[_indx]);
    }

    function _isWhitelisted(string memory _walletStr) internal view returns(bool) {
        uint256 indx = whitelistIndx[_walletStr];
       
        if (indx == 0) {
            return(false);
        } else {
            return(true);
        }
    }


     function cID() internal view returns (uint256) {
        return block.chainid;
    }

    function strToUint(
        string memory _str
    ) internal pure returns (uint256 res, bool err) {
        if (bytes(_str).length == 0) {
            return (0, true);
        }
        for (uint256 i = 0; i < bytes(_str).length; i++) {
            if (
                (uint8(bytes(_str)[i]) - 48) < 0 ||
                (uint8(bytes(_str)[i]) - 48) > 9
            ) {
                return (0, false);
            }
            res +=
                (uint8(bytes(_str)[i]) - 48) *
                10 ** (bytes(_str).length - i - 1);
        }

        return (res, true);
    }

    function stringToAddress(string memory str) internal pure returns (address) {
        bytes memory strBytes = bytes(str);
        require(strBytes.length == 42, "CTMRWA001Sentry: Invalid address length");
        bytes memory addrBytes = new bytes(20);

        for (uint i = 0; i < 20; i++) {
            addrBytes[i] = bytes1(
                hexCharToByte(strBytes[2 + i * 2]) *
                    16 +
                    hexCharToByte(strBytes[3 + i * 2])
            );
        }

        return address(uint160(bytes20(addrBytes)));
    }

    function hexCharToByte(bytes1 char) internal pure returns (uint8) {
        uint8 byteValue = uint8(char);
        if (
            byteValue >= uint8(bytes1("0")) && byteValue <= uint8(bytes1("9"))
        ) {
            return byteValue - uint8(bytes1("0"));
        } else if (
            byteValue >= uint8(bytes1("a")) && byteValue <= uint8(bytes1("f"))
        ) {
            return 10 + byteValue - uint8(bytes1("a"));
        } else if (
            byteValue >= uint8(bytes1("A")) && byteValue <= uint8(bytes1("F"))
        ) {
            return 10 + byteValue - uint8(bytes1("A"));
        }
        revert("Invalid hex character");
    }

    function stringsEqual(
        string memory a,
        string memory b
    ) internal pure returns (bool) {
        bytes32 ka = keccak256(abi.encode(a));
        bytes32 kb = keccak256(abi.encode(b));
        return (ka == kb);
    }

    function _toLower(string memory str) internal pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint i = 0; i < bStr.length; i++) {
            // Uppercase character...
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                // So we add 32 to make it lowercase
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }
    
    function _stringToArray(string memory _string) internal pure returns(string[] memory) {
        string[] memory strArray = new string[](1);
        strArray[0] = _string;
        return(strArray);
    }

    function _boolToArray(bool _bool) internal pure returns(bool[] memory) {
        bool[] memory boolArray = new bool[](1);
        boolArray[0] = _bool;
        return(boolArray);
    }

}