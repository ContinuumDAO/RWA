// SPDX-License-Identifier: BSL-1.1

pragma solidity 0.8.27;

import { CTMRWAProxy } from "../utils/CTMRWAProxy.sol";
import { CTMRWAErrorParam } from "../utils/CTMRWAUtils.sol";

interface ICTMRWA1TokenFactory {
    error CTMRWA1TokenFactory_OnlyAuthorized(CTMRWAErrorParam, CTMRWAErrorParam);
    error CTMRWA1TokenFactory_InvalidID(uint256);
    error CTMRWA1TokenFactory_InvalidRWAType(uint256);
    error CTMRWA1TokenFactory_InvalidVersion(uint256);

    function deploy(uint256 _rwaType, uint256 _version, bytes memory deployData) external returns (address);
}
