// SPDX-License-Identifier: BSL-1.1

pragma solidity 0.8.27;

import { CTMRWAErrorParam } from "../utils/CTMRWAUtils.sol";

interface ICTMRWA1XUtils {
    // Events
    event LogFallback(bytes4 selector, bytes data, bytes reason);
    event ReturnValueFallback(address to, uint256 slot, uint256 value);

    // Errors
    error CTMRWA1XUtils_InvalidContract(CTMRWAErrorParam param);
    error CTMRWA1XUtils_InvalidVersion(uint256 version);
    error CTMRWA1XUtils_OnlyAuthorized(CTMRWAErrorParam addr, CTMRWAErrorParam auth); 
    error CTMRWA1XUtils_FailedTransfer();
    error CTMRWA1XUtils_NonZeroSlot(uint256 slot);
    error CTMRWA1XUtils_NonExistentSlot(uint256 slot);

    // Functions
    function rwa1X() external returns (address);
    function ctmRwaMap() external returns (address);
    function updateOwnedCtmRwa1(address _ownerAddr, address _tokenAddr, uint256 _version) external returns (bool);
    function isOwnedToken(address _owner, address _ctmRwa1Addr) external view returns (bool);
    function addAdminToken(address _admin, address _tokenAddr, uint256 _version) external;
    function swapAdminAddress(address _oldAdmin, address _newAdmin, address _ctmRwa1Addr, uint256 _version) external;
    function getAllTokensByAdminAddress(address _admin, uint256 _version) external view returns (address[] memory);
    function getAllTokensByOwnerAddress(address _owner, uint256 _version) external view returns (address[] memory);

    function mintFromXForERC20(
        uint256 ID,
        uint256 version,
        address to,
        uint256 slot,
        string memory slotName
    ) external returns (uint256);
   
    function lastSelector() external returns (bytes4);
    function lastData() external returns (bytes calldata);
    function lastReason() external returns (bytes calldata);

    function getLastReason() external view returns (string memory);

    function rwa1XC3Fallback(bytes4 selector, bytes calldata data, bytes calldata reason, address map)
        external
        returns (bool);
}
