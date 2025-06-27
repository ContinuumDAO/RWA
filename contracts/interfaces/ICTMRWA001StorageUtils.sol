// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;


interface ICTMRWA001StorageUtils {

    function ctmRwa001Map() external returns(address);
    function storageManager() external returns(address);
    function lastSelector() external returns(bytes4);
    function lastData() external returns(bytes calldata);

    function deployStorage(
        uint256 ID,
        address tokenAddr,
        uint256 rwaType,
        uint256 version,
        address map
    ) external returns(address);

    function getLastReason() external view returns(string memory);

    function smC3Fallback(
        bytes4 selector,
        bytes calldata data,
        bytes calldata reason
    ) external returns(bool);


}