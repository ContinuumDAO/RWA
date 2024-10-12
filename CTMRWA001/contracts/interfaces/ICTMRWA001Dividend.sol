// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

interface ICTMRWA001Dividend {
    function ID() external view returns(uint256);
    function setDividendToken(address _dividendToken) external returns(bool);
    function dividendToken() external returns(address);
    function changeDividendRate(uint256 _slot, uint256 _dividend) external returns(bool);
    function getDividendRateBySlot(uint256 _slot) external view returns(uint256);
    function getDividendByToken(uint256 _tokenId) external view returns(uint256);
    function getTotalDividendBySlot(uint256 _slot) external view returns(uint256);
    function getTotalDividend() external view returns(uint256);
    function fundDividend(uint256 _dividendPayable) external payable returns(uint256);
    
    function claimDividend(uint256 _tokenId) external returns(bool);
}