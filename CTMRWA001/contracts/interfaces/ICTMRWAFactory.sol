// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

interface ICTMRWAFactory {
    function deploy(
        bytes memory deployData
    ) external returns(address);

    function deployDividend(
        uint256 ID,
        address tokenAddr,
        uint256 rwaType,
        uint256 version,
        address ctmRwaMap
    ) external returns(address);

    function deployStorage(
        uint256 ID,
        uint256 rwaType,
        uint256 version,
        address ctmRwaMap
    ) external returns(address);

    function setCtmRwaDeployer(address deployer) external;
}