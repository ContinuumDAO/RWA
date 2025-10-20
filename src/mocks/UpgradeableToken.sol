// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.27;

/**
 * @title UpgradeableToken
 * @dev Mock contract for testing rejection of upgradeable contracts
 * This token implements upgrade functions that make it detectable as upgradeable
 */
contract UpgradeableToken {
    address public implementation;
    
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
        return 18;
    }
    
    // Upgrade functions that make this token upgradeable
    function upgradeTo(address newImplementation) external pure {
        // This function exists to make the contract detectable as upgradeable
        // In a real upgradeable contract, this would modify state
        // But for testing purposes, we make it pure to avoid staticcall issues
        newImplementation; // Silence unused parameter warning
    }
    
    function upgradeToAndCall(address newImplementation, bytes calldata) external pure {
        // This function exists to make the contract detectable as upgradeable
        // In a real upgradeable contract, this would modify state
        // But for testing purposes, we make it pure to avoid staticcall issues
        newImplementation; // Silence unused parameter warning
    }
    
    function _authorizeUpgrade(address) external {
        // UUPS pattern function
    }
}
