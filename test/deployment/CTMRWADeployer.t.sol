// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";
import { console } from "forge-std/console.sol";

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { Helpers } from "../helpers/Helpers.sol";

contract TestDeployer is Helpers {
    using Strings for *;
}
