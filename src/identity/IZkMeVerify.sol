// SPDX-License-Identifier: BSL-1.1

pragma solidity ^0.8.22;

interface IZkMeVerify {
    function hasApproved(address cooperator, address user) external view returns (bool);
}
