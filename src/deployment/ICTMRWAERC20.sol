// SPDX-License-Identifier: BSL-1.1

pragma solidity 0.8.27;

import { Address } from "../utils/CTMRWAUtils.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ICTMRWAERC20 is IERC20 {
    error CTMRWAERC20_InvalidContract(Address);
    error CTMRWAERC20_NonExistentSlot(uint256);
    error CTMRWAERC20_IsZeroAddress(Address);
    error CTMRWAERC20_MaxTokens();

    function ID() external view returns (uint256);
    function ctmRwaName() external view returns (string memory);
    function slot() external view returns (uint256);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    function RWA_TYPE() external view returns (uint256);
    function VERSION() external view returns (uint256);
}
