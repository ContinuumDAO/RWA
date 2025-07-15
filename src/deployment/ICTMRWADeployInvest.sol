// SPDX-License-Identifier: BSL-1.1

pragma solidity 0.8.27;

import { Address } from "../CTMRWAUtils.sol";

interface ICTMRWADeployInvest {
    error CTMRWADeployInvest_Unauthorized(Address);

    // TODO: implement this function/variable
    // function ID() external view returns (uint256);

    function commissionRate() external view returns (uint256);

    function setCommissionRate(uint256 commissionRate) external;

    function setDeployerMapFee(address deployer, address ctmRwaMap, address feeManager) external;

    function deployInvest(uint256 ID, uint256 rwaType, uint256 version, address feeToken) external returns (address);
}
