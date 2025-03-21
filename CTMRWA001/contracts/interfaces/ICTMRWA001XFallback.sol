// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;


interface ICTMRWA001XFallback {

    function rwa001X() external returns(address);
    function lastSelector() external returns(bytes4);
    function lastData() external returns(bytes calldata);
    function lastReason() external returns(bytes calldata);

    function getLastReason() external view returns(string memory);

    function rwa001XC3Fallback(
        bytes4 selector,
        bytes calldata data,
        bytes calldata reason
    ) external returns(bool);


}