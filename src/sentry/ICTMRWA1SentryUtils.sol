// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.22;

interface ICTMRWA1SentryUtils {
    function ctmRwa1Map() external returns (address);
    function storageManager() external returns (address);
    function lastSelector() external returns (bytes4);
    function lastData() external returns (bytes calldata);

    function RWA_TYPE() external view returns (uint256);
    function VERSION() external view returns (uint256);

    function deploySentry(uint256 ID, address tokenAddr, uint256 rwaType, uint256 version, address map)
        external
        returns (address);

    function getLastReason() external view returns (string memory);

    function sentryC3Fallback(bytes4 selector, bytes calldata data, bytes calldata reason) external returns (bool);
}
