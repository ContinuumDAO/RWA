// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.20;

import {Context} from "@openzeppelin/contracts/utils/Context.sol";


contract CTMRWA001XFallback is Context {

    address public rwa001X;

    modifier onlyRwa001X {
        require(_msgSender() == rwa001X, "CTMRWA001XFallback: onlyRwa001X function");
        _;
    }

    event LogFallback(bytes4 selector, bytes data, bytes reason);

    constructor(
        address _rwa001X
    ) {
        rwa001X = _rwa001X;
    }

    function setRwa001X(address _rwa001X) external onlyRwa001X returns(bool) {

    }

    function rwa001XC3Fallback(
        bytes4 _selector,
        bytes calldata _data,
        bytes calldata _reason
    ) external returns(bool) {

        emit LogFallback(_selector, _data, _reason);

        return(true);
    }


}