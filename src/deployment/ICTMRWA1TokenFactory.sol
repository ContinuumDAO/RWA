// SPDX-License-Identifier: BSL-1.1

pragma solidity 0.8.27;

import { CTMRWAProxy } from "../utils/CTMRWAProxy.sol";
import { CTMRWAErrorParam } from "../utils/CTMRWAUtils.sol";

interface ICTMRWA1TokenFactory {
    error CTMRWA1TokenFactory_OnlyAuthorized(CTMRWAErrorParam, CTMRWAErrorParam);

    function deploy(bytes memory deployData) external returns (address);
}
