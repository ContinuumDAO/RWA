// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.27;

/**
 * @title HighDecimalsToken
 * @dev Mock contract for testing rejection of tokens with decimals > 18
 * This token has 25 decimals which is above the maximum allowed 18
 */
contract HighDecimalsToken {
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
        return 25; // Invalid: more than 18
    }
}
