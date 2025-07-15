// SPDX-License-Identifier: BSL-1.1

pragma solidity 0.8.27;

/// @dev Numbers that can be referenced in errors
enum Uint {
    TokenId,
    TokenName,
    Symbol,
    SlotLength,
    SlotName,
    Value,
    Input,
    Address,
    Investment,
    Balance,
    Dividend,
    Commission,
    CountryCode,
    Offering,
    MinInvestment,
    Payable,
    ChainID,
    Multiplier
}

enum Time {
    Early,
    Late
}

enum RWA {
    Type,
    Version
}

/// @dev Common addresses referenced in errors in CTMRWA1
enum Address {
    Sender,
    Owner,
    To,
    From,
    Regulator,
    TokenAdmin,
    Deployer,
    Dividend,
    Identity,
    Map,
    Storage,
    Sentry,
    SentryManager,
    RWAERC20,
    Override,
    Admin,
    Minter,
    Fallback,
    Token,
    Invest,
    DeployInvest,
    Spender,
    ZKMe,
    Cooperator,
    Gateway,
    FeeManager,
    RWAX,
    Erc20Deployer
}

enum List {
    WhiteListDisabled, // whitelisting is disabled
    WhiteListEnabled,  // whitelisting is enabled
    NoWLOrBL,          // neither whitelist nor blacklist are defined
    WLAndBL,           // whitelist and blacklist are defined
    NoWLOrKYC          // neither whitelist nor kyc is enabled
}

library CTMRWAUtils {
    /// @dev Convert a string to lower case
    function _toLower(string memory str) internal pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint256 i = 0; i < bStr.length; i++) {
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

    /// @dev Convert a string to an EVM address. Also checks the string length
    function _stringToAddress(string memory str) internal pure returns (address) {
        bytes memory strBytes = bytes(str);
        require(strBytes.length == 42, "RWA: Invalid addr length");
        bytes memory addrBytes = new bytes(20);

        for (uint256 i = 0; i < 20; i++) {
            addrBytes[i] = bytes1(_hexCharToByte(strBytes[2 + i * 2]) * 16 + _hexCharToByte(strBytes[3 + i * 2]));
        }

        return address(uint160(bytes20(addrBytes)));
    }

    /// @dev Convert a single hex character to its byte representation
    function _hexCharToByte(bytes1 char) internal pure returns (uint8) {
        uint8 byteValue = uint8(char);
        if (byteValue >= uint8(bytes1("0")) && byteValue <= uint8(bytes1("9"))) {
            return byteValue - uint8(bytes1("0"));
        } else if (byteValue >= uint8(bytes1("a")) && byteValue <= uint8(bytes1("f"))) {
            return 10 + byteValue - uint8(bytes1("a"));
        } else if (byteValue >= uint8(bytes1("A")) && byteValue <= uint8(bytes1("F"))) {
            return 10 + byteValue - uint8(bytes1("A"));
        }
        revert("Invalid hex character");
    }

    /// @dev Ensure string length is less than length
    function _checkStringLength(string memory _str, uint256 _len) internal pure {
        if (bytes(_str).length > _len) {
            revert("Gateway: max string length exceeded");
        }
    }

    /// @dev Convert an individual string to an array with a single value
    function _stringToArray(string memory _string) internal pure returns (string[] memory) {
        string[] memory strArray = new string[](1);
        strArray[0] = _string;
        return (strArray);
    }

    /// @dev Convert an individual boolean to an array with a single value
    function _boolToArray(bool _bool) internal pure returns (bool[] memory) {
        bool[] memory boolArray = new bool[](1);
        boolArray[0] = _bool;
        return (boolArray);
    }
}
