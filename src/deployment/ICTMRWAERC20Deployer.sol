// SPDX-License-Identifier: BSL-1.1

pragma solidity 0.8.27;

import {Address} from "../CTMRWAUtils.sol";

interface ICTMRWAERC20Deployer {
    error CTMRWAERC20Deployer_IsZeroAddress(Address);
    error CTMRWAERC20Deployer_InvalidContract(Address);
    error CTMRWAERC20Deployer_Unauthorized(Address);

    function deployERC20(
        uint256 ID,
        uint256 rwaType,
        uint256 version,
        uint256 slot,
        string memory name,
        string memory symbol,
        address feeToken
    ) external returns (address);
}
