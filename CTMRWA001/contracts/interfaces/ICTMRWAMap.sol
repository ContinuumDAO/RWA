// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

interface ICTMRWAMap {
    function gateway() external returns(address);
    function rwaX() external returns(address);
    function ctmRwaDeployer() external returns(address);

    function setGateway(address _gateway) external;
    function setRwa001X(address _ctmRwa001X) external;
    function setCtmRwaDeployer(address deployer) external;

    function attachContracts(
        uint256 ID, 
        uint256 rwaType, 
        uint256 version,
        address tokenAddr, 
        address dividendAddr, 
        address storageAddr,
        address sentryAddr
    ) external;

    
    function getTokenContract(
        uint256 ID,
        uint256 rwaType,
        uint256 version
    ) external view returns(bool ok, address tokenAddr);

    function getTokenId(
        string memory tokenAddrStr,
        uint256 rwaType,
        uint256 version
    ) external view returns(bool ok, uint256 ID);

    function getDividendContract(
        uint256 _ID, 
        uint256 _rwaType, 
        uint256 _version
    ) external view returns(bool, address);

    function getStorageContract(
        uint256 _ID, 
        uint256 _rwaType, 
        uint256 _version
    ) external view returns(bool, address);

    function getSentryContract(
        uint256 _ID, 
        uint256 _rwaType, 
        uint256 _version
    ) external view returns(bool, address);

}

interface ICTMRWAAttachment {
    function tokenAdmin() external returns(address);
    function attachDividend(address dividendAddr) external returns(bool);
    function attachStorage(address storageAddr) external returns(bool);
    function attachSentry(address sentryAddr) external returns(bool);
    function dividendAddr() external view returns(address);
    function storageAddr() external view returns(address);
    function sentryAddr() external view returns(address);
}

