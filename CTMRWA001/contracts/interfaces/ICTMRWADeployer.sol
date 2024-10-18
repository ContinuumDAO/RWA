// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.23;

interface ICTMRWADeployer {

    function setRwa001X(address _rwaX) external;
    function setMap(address _map) external;

    function deploy(
        uint256 ID,
        uint256 rwaType,
        uint256 version,
        bytes memory deployData
    ) external returns(address);

    function setTokenFactory(uint256 rwaType, uint256 version, address tokenFactory) external;
    function setDividendFactory(uint256 rwaType, uint256 version, address dividendFactory) external;
    function setStorageFactory(uint256 rwaType, uint256 version, address storageFactory) external;
}
