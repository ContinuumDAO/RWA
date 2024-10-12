// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.23;

interface ICTMRWADeployer {
    function deploy(
        uint256 ID,
        uint256 rwaType,
        uint256 version,
        bytes memory deployData
    ) external returns(address);
}
