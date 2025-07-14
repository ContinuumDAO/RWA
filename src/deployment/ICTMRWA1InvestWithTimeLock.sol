// SPDX-License-Identifier: BSL-1.1

pragma solidity ^0.8.22;

import {Uint, Address, Time} from "../CTMRWAUtils.sol";

interface ICTMRWA1InvestWithTimeLock {
    error CTMRWA1InvestWithTimeLock_Unauthorized(Address);
    error CTMRWA1InvestWithTimeLock_InvalidContract(Address);
    error CTMRWA1InvestWithTimeLock_OutOfBounds();
    error CTMRWA1InvestWithTimeLock_NonExistentToken(uint256);
    error CTMRWA1InvestWithTimeLock_MaxOfferings();
    error CTMRWA1InvestWithTimeLock_InvalidLength(Uint);
    error CTMRWA1InvestWithTimeLock_Paused();
    error CTMRWA1InvestWithTimeLock_InvalidTimestamp(Time);
    error CTMRWA1InvestWithTimeLock_InvalidAmount(Uint);
    error CTMRWA1InvestWithTimeLock_NotWhiteListed(address);
}
