// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.22;

interface ICTMRWA1XFallback {
    event LogFallback(bytes4 selector, bytes data, bytes reason);
    event ReturnValueFallback(address to, uint256 slot, uint256 value);

    function rwa1X() external returns (address);
    function lastSelector() external returns (bytes4);
    function lastData() external returns (bytes calldata);
    function lastReason() external returns (bytes calldata);

    function getLastReason() external view returns (string memory);

    function rwa1XC3Fallback(bytes4 selector, bytes calldata data, bytes calldata reason) external returns (bool);
}
