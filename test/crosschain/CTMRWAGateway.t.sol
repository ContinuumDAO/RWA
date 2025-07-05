// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {Helpers} from "../helpers/Helpers.sol";

contract TestGateway is Helpers {
    using Strings for *;

    function test_CTMRWAGateway() public view {
        string memory gatewayStr = gateway.getChainContract(cID().toString());
        //console.log(gatewayStr);
        address gway = stringToAddress(gatewayStr);
        //console.log(gway);
        assertEq(gway, address(gateway));
    }

}
