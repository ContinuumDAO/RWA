// SPDX-License-Identifier: BSL-1.1

pragma solidity 0.8.27;

import { CTMRWAProxy } from "../utils/CTMRWAProxy.sol";
import { CTMRWAErrorParam } from "../utils/CTMRWAUtils.sol";

interface ICTMRWADeployInvest {
    error CTMRWADeployInvest_OnlyAuthorized(CTMRWAErrorParam, CTMRWAErrorParam);
    error CTMRWADeployInvest_IsZeroAddress(CTMRWAErrorParam);
    error CTMRWADeployInvest_FailedTransfer();
    error CTMRWADeployInvest_InvalidVersion(uint256);
    error CTMRWADeployInvest_InvalidRWAType(uint256);
    

    function commissionRate() external view returns (uint256);

    function setCommissionRate(uint256 commissionRate) external;

    function setDeployerMapFee(address deployer, address ctmRwaMap, address feeManager) external;

    function deployInvest(uint256 ID, uint256 rwaType, uint256 version, address feeToken, address originalCaller) external returns (address);
}
