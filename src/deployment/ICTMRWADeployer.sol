// SPDX-License-Identifier: BSL-1.1

pragma solidity 0.8.27;

import { CTMRWAProxy } from "../utils/CTMRWAProxy.sol";
import { CTMRWAErrorParam } from "../utils/CTMRWAUtils.sol";

interface ICTMRWADeployer {
    // Events
    event CommissionRateChanged(uint256 commissionRate);

    // Errors
    error CTMRWADeployer_OnlyAuthorized(CTMRWAErrorParam, CTMRWAErrorParam);
    error CTMRWADeployer_InvalidContract(CTMRWAErrorParam);
    error CTMRWADeployer_IncompatibleRWA(CTMRWAErrorParam);
    error CTMRWADeployer_IsZeroAddress(CTMRWAErrorParam);
    error CTMRWADeployer_CommissionRateOutOfBounds(CTMRWAErrorParam);
    error CTMRWADeployer_CommissionRateIncreasedTooMuch(CTMRWAErrorParam);
    error CTMRWADeployer_CommissionRateChangeTooSoon(CTMRWAErrorParam);

    // Public functions
    function gateway() external view returns (address);
    function feeManager() external view returns (address);
    function rwaX() external view returns (address);
    function ctmRwaMap() external view returns (address);
    function erc20Deployer() external view returns (address);
    function deployInvest() external view returns (address);
    function lastCommissionRateChange() external view returns (uint256);
    function getInvestCommissionRate() external view returns (uint256);
    function tokenFactory(uint256 rwaType, uint256 version) external returns (address);
    function dividendFactory(uint256 rwaType, uint256 version) external returns (address);
    function storageFactory(uint256 rwaType, uint256 version) external returns (address);
    function sentryFactory(uint256 rwaType, uint256 version) external returns (address);

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
    function deployERC20(uint256 ID, uint256 rwaType, uint256 version, uint256 slot, string memory name, address feeToken) external returns (address);
}
