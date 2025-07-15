// SPDX-License-Identifier: BSL-1.1

pragma solidity ^0.8.22;

import { Address, Uint } from "../CTMRWAUtils.sol";
import { ICTMRWA } from "../core/ICTMRWA.sol";

interface ICTMRWA1Dividend is ICTMRWA {
    error CTMRWA1Dividend_Unauthorized(Address);
    error CTMRWA1Dividend_InvalidDividend(Uint);
    error CTMRWA1Dividend_FailedTransaction();

    function ID() external view returns (uint256);
    function tokenAdmin() external view returns (address);
    function setTokenAdmin(address _tokenAdmin) external returns (bool);
    function setDividendToken(address dividendToken) external returns (bool);
    function dividendToken() external returns (address);
    function unclaimedDividend(address holder) external returns (uint256);
    function changeDividendRate(uint256 slot, uint256 dividend) external returns (bool);
    function getDividendRateBySlot(uint256 slot) external view returns (uint256);
    function getTotalDividendBySlot(uint256 slot) external view returns (uint256);
    function getTotalDividend() external view returns (uint256);
    function fundDividend() external returns (uint256);
    function dividendByTokenId(uint256 tokenId) external returns (uint256);
    function resetDividendByToken(uint256 tokenId) external;

    function claimDividend() external returns (bool);
}
