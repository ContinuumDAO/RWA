// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.22;

import { SlotData } from "../core/ICTMRWA1.sol";

import {ICTMRWA} from "../core/ICTMRWA.sol";

interface ICTMRWA1X is ICTMRWA {
    /// @dev New c3call for CTMRWA1 deployment on destination chain toChainIdStr
    event DeployCTMRWA1(uint256 ID, string toChainIdStr);

    /// @dev New CTMRWA1 deployed on the local chain
    event CreateNewCTMRWA1(uint256 ID);

    /// @dev New c3call to create a new Asset Class (slot) on chain toChainIdStr
    event CreateSlot(uint256 ID, uint256 slot, string toChainIdStr);

    /// @dev New Asset Class (slot) created on the local chain from fromChainIdStr
    event SlotCreated(uint256 ID, uint256 slot, string fromChainIdStr);

    /// @dev New c3call to mint value to chain toChainIdStr to address toAddressStr
    event Minting(uint256 ID, string toAddressStr, string toChainIdStr);

    /// @dev New value minted from another chain fromChainIdStr and fromAddrStr
    event Minted(uint256 ID, string fromChainIdStr, string fromAddrStr);

    /// @dev New c3call to change the token admin on chain toChainIdStr
    event ChangingAdmin(uint256 ID, string toChainIdStr);

    /// @dev New token admin set on the local chain
    event AdminChanged(uint256 ID, string newAdmin);

    function isMinter(address) external returns (bool);
    function changeMinterStatus(address minter, bool set) external;

    function changeTokenAdmin(
        string memory newAdminStr,
        string[] memory toChainIdsStr,
        uint256 ID,
        string memory feeTokenStr
    ) external returns (bool);

    function changeFeeManager(address feeManager) external;
    function setGateway(address gateway) external;
    function setFallback(address fallbackAddr) external;
    function setCtmRwaMap(address ctmRwaMap) external;
    function setCtmRwaDeployer(address deployer) external;
    function fallbackAddr() external returns (address);
    function gateway() external returns (address);
    function feeManager() external returns (address);
    function ctmRwaDeployer() external returns (address);

    function deployAllCTMRWA1X(
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
    ) external returns (uint256);

    function deployCTMRWA1(
        string memory newAdminStr,
        uint256 ID,
        string memory tokenName,
        string memory symbol,
        uint8 decimals,
        string memory baseURI,
        uint256[] memory slotNumbers,
        string[] memory slotNames
    ) external returns (bool); // onlyCaller function (added for DEBUG purposes)

    function adminX(uint256 ID, string memory oldAdminStr, string memory newAdminStr) external returns (bool); // onlyCaller

    function getAllTokensByAdminAddress(address admin) external view returns (address[] memory);
    function getAllTokensByOwnerAddress(address owner) external view returns (address[] memory);

    function mintNewTokenValueLocal(
        address toAddress,
        uint256 toTokenId, // Set to 0 to create a newTokenId
        uint256 slot,
        uint256 value,
        uint256 ID,
        string memory feeTokenStr
    ) external returns (uint256);

    function createNewSlot(
        uint256 ID,
        uint256 slot,
        string memory slotName,
        string[] memory toChainIdsStr,
        string memory feeTokenStr
    ) external returns (bool);

    function transferPartialTokenX( // transfer from/to same tokenid with value
        uint256 fromTokenId,
        string memory toAddressStr,
        string memory toChainIdStr,
        uint256 value,
        uint256 ID,
        string memory feeTokenStr
    ) external returns (uint256);

    function transferWholeTokenX( // transfer from/to same tokenid without value
        string memory fromAddressStr,
        string memory toAddressStr,
        string memory toChainIdStr,
        uint256 fromTokenId,
        uint256 ID,
        string memory feeTokenStr
    ) external;

    // TODO: remove `_fromTokenId` & `_fromTokenStr`
    function mintX(
        uint256 _ID,
        string memory _fromAddressStr,
        string memory _toAddressStr,
        uint256 _slot,
        uint256 _balance
    ) external returns (bool); // onlyCaller
}
