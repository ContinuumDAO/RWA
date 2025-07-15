// SPDX-License-Identifier: BSL-1.1

pragma solidity ^0.8.22;

import {Address} from "../CTMRWAUtils.sol";

interface ICTMRWA1TokenFactory {
    error CTMRWA1TokenFactory_Unauthorized(Address);

    function deploy(bytes memory deployData) external returns (address);

    // TODO: do we implement these functions?
    // function deployDividend(uint256 ID, address tokenAddr, uint256 rwaType, uint256 version, address ctmRwaMap)
    //     external
    //     returns (address);

    // function deployStorage(uint256 ID, address tokenAddr, uint256 rwaType, uint256 version, address ctmRwaMap)
    //     external
    //     returns (address);

    // function deploySentry(uint256 ID, address tokenAddr, uint256 rwaType, uint256 version, address ctmRwaMap)
    //     external
    //     returns (address);

    // function setCtmRwaDeployer(address deployer) external;
}
