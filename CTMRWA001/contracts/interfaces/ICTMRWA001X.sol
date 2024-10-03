// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.20;


interface ICTMRWA001X {
    
    function changeAdmin(address _newAdmin, uint256 _ID) external returns(bool);
    function changeFeeManager(address _feeManager) external;
    function setCtmRwaDeployer(address _deployer) external;
    function fallbackAddr() external returns(address);

    //function tokenContract() external returns(TokenContract[] memory);
    function totalSupply() external view returns (uint256);
    
    function deployCTMRWA001(
        string memory newAdminStr,
        uint256 ID,
        uint256 rwaType,
        uint256 version,
        string memory tokenName, 
        string memory symbol, 
        uint8 decimals,
        string memory baseURI,
        string memory fromContractStr
    ) external returns(bool);  // onlyCaller

    function adminX(
        string memory currentAdminStr,
        string memory newAdminStr,
        string memory fromContractStr,
        string memory ctmRwa001AddrStr
    ) external returns(bool);  // onlyCaller

    // function lockCTMRWA001(
    //     uint256 _ID,
    //     string memory feeTokenStr
    // ) external;

    function getAttachedID(address ctmRwa001Addr) external view returns(bool, uint256);
    function getAttachedTokenAddress(uint256 ID) external view returns(bool, address);

    function addNewChainIdAndTokenX(
        uint256 Id,
        string memory adminStr,
        string[] memory chainIdsStr,
        string[] memory otherCtmRwa001AddrsStr,
        string memory fromTokenStr,
        string memory ctmRwa001AddrStr
    ) external returns(bool);   //  onlyCaller

    function checkTokenCompatibility(
        string memory _otherChainIdStr,
        string memory _otherContractStr
    ) external view returns(bool);
    
    // transferFromX
    function transferFromX( // transfer from/to same tokenid with value
        uint256 fromTokenId_,
        string memory toAddressStr_,
        string memory toChainIdStr_,
        uint256 value_,
        string memory _ctmRwa001AddrStr,
        string memory feeTokenStr
    ) external payable;
    function transferFromX( // transfer from/to same tokenid without value
        string memory toAddressStr_,
        string memory toChainIdStr_,
        uint256 fromTokenId_,
        string memory _ctmRwa001AddrStr,
        string memory feeTokenStr
    ) external;
    function transferFromX( // transfer from tokenid to different tokenid with value
        uint256 fromTokenId_,
        string memory toAddressStr_,
        uint256 toTokenId_,
        string memory toChainIdStr_,
        uint256 value_,
        string memory _ctmRwa001AddrStr,
        string memory feeTokenStr
    ) external;

    function mintX(
        uint256 _ID,
        string memory _fromAddressStr,
        string memory _toAddressStr,
        uint256 _fromTokenId,
        uint256 _toTokenId,
        uint256 _slot,
        uint256 _value,
        string memory _fromContractStr,
        string memory _ctmRwa001AddrStr
    ) external returns(bool);  // onlyCaller

    function mintX(
        uint256 _ID,
        string memory _fromAddressStr,
        string memory _toAddressStr,
        uint256 _fromTokenId,
        uint256 _slot,
        uint256 _balance,
        string memory _fromContractStr,
        string memory _ctmRwa001AddrStr
    ) external returns(bool); // onlyCaller


}