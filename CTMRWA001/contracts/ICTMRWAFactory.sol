// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

interface ICTMRWATokenFactory {
    function deploy(
        bytes memory deployData
    ) external returns(address);

    function deployDividend(
        bytes memory deployData
    ) external returns(address);
}