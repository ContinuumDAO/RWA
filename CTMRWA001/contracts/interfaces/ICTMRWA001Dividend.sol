// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

interface ICTMRWA001Dividend {
    function ID() external view returns(uint256);
    function setDividendToken(address _dividendToken) external returns(bool);
    function dividendToken() external returns(address);
    function unclaimedDividend(address holder) external returns(uint256);
    function changeDividendRate(uint256 _slot, uint256 _dividend) external returns(bool);
    function getDividendRateBySlot(uint256 _slot) external view returns(uint256);
    function getTotalDividendBySlot(uint256 _slot) external view returns(uint256);
    function getTotalDividend() external view returns(uint256);
    function fundDividend() external payable returns(uint256);
    
    function claimDividend() external returns(bool);
}