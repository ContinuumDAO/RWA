// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.22;

interface ICTMRWADeployer {
    function gateway() external view returns (address);
    function feeManager() external view returns (address);
    function rwaX() external view returns (address);
    function ctmRwaMap() external view returns (address);
    function erc20Deployer() external view returns (address);
    function deployInvest() external view returns (address);

    function setGateway(address gateway) external;
    function setFeeManager(address _feeManager) external;
    function setRwaX(address rwaX) external;
    function setMap(address _map) external;
    function setDeployInvest(address deployInvest) external;
    function setDeployerMapFee() external;
    function setInvestCommissionRate(uint256 commissionRate) external;

    function deploy(uint256 _ID, uint256 _rwaType, uint256 _version, bytes memory deployData)
        external
        returns (address, address, address, address);

    function setTokenFactory(uint256 rwaType, uint256 version, address tokenFactory) external;
    function setDividendFactory(uint256 rwaType, uint256 version, address dividendFactory) external;
    function setStorageFactory(uint256 rwaType, uint256 version, address storageFactory) external;
    function setSentryFactory(uint256 rwaType, uint256 version, address storageFactory) external;

    function deployNewInvestment(uint256 ID, uint256 rwaType, uint256 version, address feeToken)
        external
        returns (address);

    function setErc20DeployerAddress(address erc20Deployer) external;
}
