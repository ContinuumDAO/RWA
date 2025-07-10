// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.22;

interface ICTMRWA {
    function RWA_TYPE() external view returns (uint256);
    function VERSION() external view returns (uint256);
}
