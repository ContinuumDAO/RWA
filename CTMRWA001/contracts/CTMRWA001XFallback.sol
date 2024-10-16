// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.23;

import {Context} from "@openzeppelin/contracts/utils/Context.sol";


contract CTMRWA001XFallback is Context {

    address public rwa001X;

    bytes4 public lastSelector;
    bytes public lastData;
    bytes public lastReason;

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

    function getLastReason() public view returns(string memory) {
        return(string(lastReason));
    }

    function rwa001XC3Fallback(
        bytes4 _selector,
        bytes calldata _data,
        bytes calldata _reason
    ) external onlyRwa001X returns(bool) {

        lastSelector = _selector;
        lastData = _data;
        lastReason = _reason;

        emit LogFallback(_selector, _data, _reason);

        return(true);
    }


}