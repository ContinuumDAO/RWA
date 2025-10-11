// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.27;

/**
 * @title InvalidDecimalsToken
 * @dev Mock contract for testing rejection of tokens with decimals < 6
 * This token has 3 decimals which is below the minimum required 6
 */
contract InvalidDecimalsToken {
    function balanceOf(address) external pure returns (uint256) {
        return 1000000;
    }
    
    function totalSupply() external pure returns (uint256) {
        return 1000000;
    }
    
    function transfer(address, uint256) external pure returns (bool) {
        return true;
    }
    
    function transferFrom(address, address, uint256) external pure returns (bool) {
        return true;
    }
    
    function approve(address, uint256) external pure returns (bool) {
        return true;
    }
    
    function allowance(address, address) external pure returns (uint256) {
        return 1000000;
    }
    
    function decimals() external pure returns (uint8) {
        return 3; // Invalid: less than 6
    }
}
