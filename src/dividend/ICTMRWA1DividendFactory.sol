// SPDX-License-Identifier: BSL-1.1

pragma solidity 0.8.27;

import { Address } from "../utils/CTMRWAUtils.sol";

interface ICTMRWA1DividendFactory {
    error CTMRWA1DividendFactory_Unauthorized(Address);

    function deployDividend(uint256 ID, address tokenAddr, uint256 rwaType, uint256 version, address map)
        external
        returns (address);
}
