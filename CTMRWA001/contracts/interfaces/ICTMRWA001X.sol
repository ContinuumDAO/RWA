// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.23;



interface ICTMRWA001X {
    
    function changeAdmin(address _newAdmin, uint256 _ID) external returns(bool);
    function changeFeeManager(address _feeManager) external;
    function setGateway(address _gateway) external;
    function setFallback(address _fallbackAddr) external;
    function setCtmRwaMap(address ctmRwaMap) external;
    function setCtmRwaDeployer(address _deployer) external;
    function fallbackAddr() external returns(address);
    function gateway() external returns(address);
    function feeManager() external returns(address);
    function ctmRwaDeployer() external returns(address);

    

    
    function deployAllCTMRWA001X(
        bool includeLocal,
        uint256 existingID,
        uint256 rwaType,
        uint256 version,
        string memory tokenName, 
        string memory symbol, 
        uint8 decimals,
        string memory baseURI,
        string[] memory toChainIdsStr,
        string memory feeTokenStr
    ) external returns(uint256);

    function changeAdminCrossChain(
        string memory newAdminStr,
        string memory toChainIdStr,
        uint256 ID,
        string memory feeTokenStr
    ) external;

    function adminX(
        uint256 ID,
        string memory currentAdminStr,
        string memory newAdminStr,
        string memory fromContractStr
    ) external returns(bool);  // onlyCaller


    function getAllTokensByAdminAddress(address admin) external view returns(address[] memory);
    function getAllTokensByOwnerAddress(address owner) external view returns(address[] memory);

    function mintNewTokenValueLocal(
        address toAddress,
        uint256 toTokenId,  // Set to 0 to create a newTokenId
        uint256 slot,
        uint256 value,
        uint256 ID
    ) external returns(uint256);


    function createNewSlot(
        uint256 ID,
        uint256 slot,
        string memory slotName,
        string[] memory toChainIdsStr,
        string memory feeTokenStr
    ) external returns(bool);


    // transferFromX
    function transferFromX( // transfer from/to same tokenid with value
        uint256 fromTokenId_,
        string memory toAddressStr_,
        string memory toChainIdStr_,
        uint256 value_,
        uint256 ID,
        string memory feeTokenStr
    ) external;
    

    function transferFromX( // transfer from/to same tokenid without value
        string memory toAddressStr_,
        string memory toChainIdStr_,
        uint256 fromTokenId_,
        uint256 ID,
        string memory feeTokenStr
    ) external;


    function mintX(
        uint256 ID,
        string memory fromAddressStr,
        string memory toAddressStr,
        uint256 fromTokenId,
        uint256 slot,
        uint256 balance,
        string memory fromTokenStr
    ) external returns(bool); // onlyCaller

}