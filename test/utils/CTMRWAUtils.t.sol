// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.27;

import { Test } from "forge-std/Test.sol";
import { CTMRWAUtils, CTMRWAErrorParam } from "../../src/utils/CTMRWAUtils.sol";

contract StringToAddressWrapper {
    function stringToAddress(string memory str) external pure returns (address) {
        return CTMRWAUtils._stringToAddress(str);
    }
}

contract CTMRWAUtilsTest is Test {
    using CTMRWAUtils for string;
    
    StringToAddressWrapper wrapper;
    
    function setUp() public {
        wrapper = new StringToAddressWrapper();
    }

    function test_StringToAddress_ValidAddress() public {
        address expected = address(0x1234567890123456789012345678901234567890);
        string memory addrStr = "0x1234567890123456789012345678901234567890";
        
        address result = wrapper.stringToAddress(addrStr);
        assertEq(result, expected);
    }

    function test_StringToAddress_InvalidLength_TooShort() public {
        string memory addrStr = "0x123456789012345678901234567890123456789"; // 41 chars
        
        vm.expectRevert(abi.encodeWithSelector(CTMRWAUtils.CTMRWAUtils_InvalidLength.selector, CTMRWAErrorParam.Address));
        wrapper.stringToAddress(addrStr);
    }

    function test_StringToAddress_InvalidLength_TooLong() public {
        string memory addrStr = "0x12345678901234567890123456789012345678901"; // 43 chars
        
        vm.expectRevert(abi.encodeWithSelector(CTMRWAUtils.CTMRWAUtils_InvalidLength.selector, CTMRWAErrorParam.Address));
        wrapper.stringToAddress(addrStr);
    }

    function test_StringToAddress_Missing0xPrefix() public {
        string memory addrStr = "1234567890123456789012345678901234567890"; // 40 chars without 0x
        
        vm.expectRevert(abi.encodeWithSelector(CTMRWAUtils.CTMRWAUtils_InvalidLength.selector, CTMRWAErrorParam.Address));
        wrapper.stringToAddress(addrStr);
    }

    function test_StringToAddress_InvalidPrefix() public {
        string memory addrStr = "0X1234567890123456789012345678901234567890"; // Wrong case X
        
        vm.expectRevert(abi.encodeWithSelector(CTMRWAUtils.CTMRWAUtils_InvalidLength.selector, CTMRWAErrorParam.Address));
        wrapper.stringToAddress(addrStr);
    }

    function test_StringToAddress_InvalidPrefix2() public {
        string memory addrStr = "0a1234567890123456789012345678901234567890"; // Wrong prefix
        
        vm.expectRevert(abi.encodeWithSelector(CTMRWAUtils.CTMRWAUtils_InvalidLength.selector, CTMRWAErrorParam.Address));
        wrapper.stringToAddress(addrStr);
    }

    function test_StringToAddress_EmptyString() public {
        string memory addrStr = "";
        
        vm.expectRevert(abi.encodeWithSelector(CTMRWAUtils.CTMRWAUtils_InvalidLength.selector, CTMRWAErrorParam.Address));
        wrapper.stringToAddress(addrStr);
    }

    function test_StringToAddress_ZeroAddress() public {
        address expected = address(0);
        string memory addrStr = "0x0000000000000000000000000000000000000000";
        
        address result = wrapper.stringToAddress(addrStr);
        assertEq(result, expected);
    }

    function test_StringToAddress_MaxAddress() public {
        address expected = address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF);
        string memory addrStr = "0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF";
        
        address result = wrapper.stringToAddress(addrStr);
        assertEq(result, expected);
    }
}
