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
    Title,
    URI,
    Nonce,
    Address,
    Balance,
    Dividend,
    Commission,
    CountryCode,
    Offering,
    MinInvestment,
    InvestmentLow,
    InvestmentHigh,
    Payable,
    ChainID,
    Multiplier,
    BaseURI
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
    Factory,
    Deployer,
    Dividend,
    Identity,
    Map,
    Storage,
    Sentry,
    SentryManager,
    StorageManager,
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
    ERC20Deployer,
    Allowable,
    ApprovedOrOwner,
    Wallet
}

enum List {
    WL_Disabled, // whitelisting is disabled
    WL_Enabled, // whitelisting is enabled
    WL_BL_Undefined, // neither whitelist nor blacklist are defined
    WL_BL_Defined, // whitelist and blacklist are defined
    WL_KYC_Disabled // neither whitelist nor kyc is enabled

}

library CTMRWAUtils {
    error CTMRWAUtils_InvalidLength(Uint);
    error CTMRWAUtils_InvalidHexCharacter();
    error CTMRWAUtils_StringTooLong();

    /// @dev Convert a string to lower case
    /// @param str The string to convert to lower case
    /// @return The lower case string
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
    /// @param str The string to convert to an EVM address
    /// @return The EVM address
    function _stringToAddress(string memory str) internal pure returns (address) {
        bytes memory strBytes = bytes(str);
        // require(strBytes.length == 42, "RWA: Invalid addr length");
        if (strBytes.length != 42) {
            revert CTMRWAUtils_InvalidLength(Uint.Address);
        }
        bytes memory addrBytes = new bytes(20);

        for (uint256 i = 0; i < 20; i++) {
            addrBytes[i] = bytes1(_hexCharToByte(strBytes[2 + i * 2]) * 16 + _hexCharToByte(strBytes[3 + i * 2]));
        }

        return address(uint160(bytes20(addrBytes)));
    }

    /// @dev Convert a single hex character to its byte representation
    /// @param char The hex character to convert to a byte
    /// @return The byte value of the hex character
    function _hexCharToByte(bytes1 char) internal pure returns (uint8) {
        uint8 byteValue = uint8(char);
        if (byteValue >= uint8(bytes1("0")) && byteValue <= uint8(bytes1("9"))) {
            return byteValue - uint8(bytes1("0"));
        } else if (byteValue >= uint8(bytes1("a")) && byteValue <= uint8(bytes1("f"))) {
            return 10 + byteValue - uint8(bytes1("a"));
        } else if (byteValue >= uint8(bytes1("A")) && byteValue <= uint8(bytes1("F"))) {
            return 10 + byteValue - uint8(bytes1("A"));
        }
        revert CTMRWAUtils_InvalidHexCharacter();
    }

    /// @dev Ensure string length is less than length
    /// @param _str The string to check the length of
    /// @param _len The maximum length of the string
    function _checkStringLength(string memory _str, uint256 _len) internal pure {
        if (bytes(_str).length > _len) {
            revert CTMRWAUtils_StringTooLong();
        }
    }

    /// @dev Convert an individual string to an array with a single value
    /// @param _string The string to convert to an array
    /// @return The array of strings
    function _stringToArray(string memory _string) internal pure returns (string[] memory) {
        string[] memory strArray = new string[](1);
        strArray[0] = _string;
        return (strArray);
    }

    /// @dev Convert an individual boolean to an array with a single value
    /// @param _bool The boolean to convert to an array
    /// @return The array of booleans
    function _boolToArray(bool _bool) internal pure returns (bool[] memory) {
        bool[] memory boolArray = new bool[](1);
        boolArray[0] = _bool;
        return (boolArray);
    }

    /// @dev Convert an individual uint256 to an array with a single value
    /// @param _myUint256 The uint256 to convert to an array
    /// @return The array of uint256s
    function _uint256ToArray(uint256 _myUint256) internal pure returns (uint256[] memory) {
        uint256[] memory uintArray = new uint256[](1);
        uintArray[0] = _myUint256;
        return (uintArray);
    }

    /// @dev Convert an individual uint8 to an array with a single value
    /// @param _myUint8 The uint8 to convert to an array
    /// @return The array of uint8s
    function _uint8ToArray(uint8 _myUint8) internal pure returns (uint8[] memory) {
        uint8[] memory uintArray = new uint8[](1);
        uintArray[0] = _myUint8;
        return (uintArray);
    }

    /// @dev Convert an individual bytes32 to an array with a single value
    /// @param _myBytes32 The bytes32 to convert to an array
    /// @return The array of bytes32s
    function _bytes32ToArray(bytes32 _myBytes32) internal pure returns (bytes32[] memory) {
        bytes32[] memory bytes32Array = new bytes32[](1);
        bytes32Array[0] = _myBytes32;
        return (bytes32Array);
    }
}
