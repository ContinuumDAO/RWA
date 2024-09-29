// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

interface ICTMRWAFactory {
    function deploy(
        bytes memory deployData
    ) external returns(address);

    function deployDividend(
        address tokenAddr
    ) external returns(address);
}