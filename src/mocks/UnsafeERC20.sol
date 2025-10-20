// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.27;

/**
 * @title UnsafeERC20
 * @dev Mock contract for testing rejection of non-SafeERC20 compliant tokens
 * This token doesn't implement balanceOf properly and always returns false for transfers
 */
contract UnsafeERC20 {
    // This token doesn't implement balanceOf properly
    function balanceOf(address) external pure returns (uint256) {
        revert("Unsafe token");
    }
    
    function totalSupply() external pure returns (uint256) {
        return 1000000;
    }
    
    function transfer(address, uint256) external pure returns (bool) {
        return false;
    }
    
    function transferFrom(address, address, uint256) external pure returns (bool) {
        return false;
    }
    
    function approve(address, uint256) external pure returns (bool) {
        return false;
    }
    
    function allowance(address, address) external pure returns (uint256) {
        return 0;
    }
    
    function name() external pure returns (string memory) {
        return "Unsafe Token";
    }
    
    function symbol() external pure returns (string memory) {
        return "UNSAFE";
    }
    
    function decimals() external pure returns (uint8) {
        return 18;
    }
}