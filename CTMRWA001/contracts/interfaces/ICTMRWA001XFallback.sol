// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.23;


interface ICTMRWA001XFallback {

    function rwa001X() external returns(address);

    function rwa001XC3Fallback(
        bytes4 selector,
        bytes calldata data,
        bytes calldata reason
    ) external returns(bool);


}