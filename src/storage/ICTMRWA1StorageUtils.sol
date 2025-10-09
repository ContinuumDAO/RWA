// SPDX-License-Identifier: BSL-1.1

pragma solidity 0.8.27;

import { ICTMRWA } from "../core/ICTMRWA.sol";
import { Address } from "../utils/CTMRWAUtils.sol";

interface ICTMRWA1StorageUtils is ICTMRWA {
    event LogFallback(bytes4 selector, bytes data, bytes reason);

    error CTMRWA1StorageUtils_OnlyAuthorized(Address, Address);
    error CTMRWA1StorageUtils_InvalidContract(Address);

    function ctmRwa1Map() external returns (address);
    function storageManager() external returns (address);
    function lastSelector() external returns (bytes4);
    function lastData() external returns (bytes calldata);

    function deployStorage(uint256 ID, address tokenAddr, uint256 rwaType, uint256 version, address map)
        external
        returns (address);

    function getLastReason() external view returns (string memory);

    function smC3Fallback(bytes4 selector, bytes calldata data, bytes calldata reason) external returns (bool);
}
