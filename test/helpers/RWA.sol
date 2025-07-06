// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { Utils } from "../helpers/Utils.sol";

import { ICTMRWA1X } from "../../src/crosschain/ICTMRWA1X.sol";

import { ICTMRWAMap } from "../../src/shared/ICTMRWAMap.sol";

contract RWA is Utils {
    using Strings for *;

    function _createSomeSlots(uint256 _ID, address usdc, address rwa1X) internal {
        string[] memory someChainIdsStr = _stringToArray(cIdStr);
        string memory tokenStr = _toLower(usdc.toHexString());

        bool ok = ICTMRWA1X(rwa1X).createNewSlot(_ID, 5, "slot 5 is the best RWA", someChainIdsStr, tokenStr);

        ok = ICTMRWA1X(rwa1X).createNewSlot(_ID, 3, "", someChainIdsStr, tokenStr);

        ok = ICTMRWA1X(rwa1X).createNewSlot(_ID, 1, "this is a basic offering", someChainIdsStr, tokenStr);
    }

    function _deployAFewTokensLocal(address _ctmRwaAddr, address usdc, address map, address rwa1X, address account)
        internal
        returns (uint256, uint256, uint256)
    {
        string memory ctmRwaAddrStr = _toLower(_ctmRwaAddr.toHexString());
        (, uint256 ID) = ICTMRWAMap(map).getTokenId(ctmRwaAddrStr, RWA_TYPE, VERSION);

        _createSomeSlots(ID, usdc, rwa1X);

        string memory tokenStr = _toLower(usdc.toHexString());

        uint256 tokenId1 = ICTMRWA1X(rwa1X).mintNewTokenValueLocal(account, 0, 5, 2000, ID, tokenStr);

        uint256 tokenId2 = ICTMRWA1X(rwa1X).mintNewTokenValueLocal(account, 0, 3, 4000, ID, tokenStr);

        uint256 tokenId3 = ICTMRWA1X(rwa1X).mintNewTokenValueLocal(account, 0, 1, 6000, ID, tokenStr);

        return (tokenId1, tokenId2, tokenId3);
    }
}
