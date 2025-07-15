// SPDX-License-Identifier: BSL-1.1

pragma solidity 0.8.27;

import { ICTMRWA } from "../core/ICTMRWA.sol";
import {Address} from "../CTMRWAUtils.sol";

interface ICTMRWA1SentryUtils is ICTMRWA {
    error CTMRWA1SentryUtils_Unauthorized(Address);
    error CTMRWA1SentryUtils_InvalidContract(Address);

    function ctmRwa1Map() external returns (address);
    function storageManager() external returns (address);
    function lastSelector() external returns (bytes4);
    function lastData() external returns (bytes calldata);

    function deploySentry(uint256 ID, address tokenAddr, uint256 rwaType, uint256 version, address map)
        external
        returns (address);

    function getLastReason() external view returns (string memory);

    function sentryC3Fallback(bytes4 selector, bytes calldata data, bytes calldata reason) external returns (bool);
}
