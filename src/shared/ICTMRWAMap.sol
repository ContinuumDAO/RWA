// SPDX-License-Identifier: BSL-1.1

pragma solidity 0.8.27;

import {Address, RWA} from "../CTMRWAUtils.sol";

interface ICTMRWAMap {
    error CTMRWAMap_Unauthorized(Address);
    error CTMRWAMap_AlreadyAttached(uint256 ID, address tokenAddr);
    error CTMRWAMap_FailedAttachment(Address);
    error CTMRWAMap_IncompatibleRWA(RWA);

    function gateway() external view returns (address);
    function ctmRwa1X() external view returns (address);
    function ctmRwaDeployer() external view returns (address);

    function setCtmRwaDeployer(address deployer, address gateway, address rwa1X) external;

    function attachContracts(
        uint256 ID,
        address tokenAddr,
        address dividendAddr,
        address storageAddr,
        address sentryAddr
    ) external;

    function setInvestmentContract(uint256 ID, uint256 rwaType, uint256 version, address investAddr)
        external
        returns (bool);

    function getTokenContract(uint256 ID, uint256 rwaType, uint256 version)
        external
        view
        returns (bool ok, address tokenAddr);

    function getTokenId(string memory tokenAddrStr, uint256 rwaType, uint256 version)
        external
        view
        returns (bool ok, uint256 ID);

    function getDividendContract(uint256 ID, uint256 rwaType, uint256 version) external view returns (bool, address);

    function getStorageContract(uint256 ID, uint256 rwaType, uint256 version) external view returns (bool, address);

    function getSentryContract(uint256 ID, uint256 rwaType, uint256 version) external view returns (bool, address);

    function getInvestContract(uint256 ID, uint256 rwaType, uint256 version) external view returns (bool, address);
}

interface ICTMRWAAttachment {
    function tokenAdmin() external returns (address);
    function attachDividend(address dividendAddr) external returns (bool);
    function attachStorage(address storageAddr) external returns (bool);
    function attachSentry(address sentryAddr) external returns (bool);
    function dividendAddr() external view returns (address);
    function storageAddr() external view returns (address);
    function sentryAddr() external view returns (address);
}
