// SPDX-License-Identifier: BSL-1.1

pragma solidity 0.8.27;

import { Address } from "../CTMRWAUtils.sol";

interface ICTMRWA1TokenFactory {
    error CTMRWA1TokenFactory_Unauthorized(Address);

    function deploy(bytes memory deployData) external returns (address);
}
