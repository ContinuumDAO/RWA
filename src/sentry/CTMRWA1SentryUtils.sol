// SPDX-License-Identifier: BSL-1.1

pragma solidity 0.8.27;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { ICTMRWA1 } from "../core/ICTMRWA1.sol";

import { CTMRWAUtils } from "../CTMRWAUtils.sol";
import { CTMRWA1Sentry } from "../sentry/CTMRWA1Sentry.sol";
import { ICTMRWA1Sentry } from "../sentry/ICTMRWA1Sentry.sol";
import { ICTMRWAMap } from "../shared/ICTMRWAMap.sol";

contract CTMRWA1SentryUtils {
    using Strings for *;
    using CTMRWAUtils for string;

    uint256 public immutable RWA_TYPE;
    uint256 public immutable VERSION;
    address public ctmRwa1Map;
    address public sentryManager;

    bytes4 public lastSelector;
    bytes public lastData;
    bytes public lastReason;

    modifier onlySentryManager() {
        require(msg.sender == sentryManager, "CTMRWA1SentryUtils: onlySentryManager function");
        _;
    }

    event LogFallback(bytes4 selector, bytes data, bytes reason);

    constructor(uint256 _rwaType, uint256 _version, address _map, address _sentryManager) {
        RWA_TYPE = _rwaType;
        VERSION = _version;
        ctmRwa1Map = _map;
        sentryManager = _sentryManager;
    }

    function deploySentry(uint256 _ID, address _tokenAddr, uint256 _rwaType, uint256 _version, address _map)
        external
        onlySentryManager
        returns (address)
    {
        CTMRWA1Sentry ctmRwa1Sentry =
            new CTMRWA1Sentry{ salt: bytes32(_ID) }(_ID, _tokenAddr, _rwaType, _version, msg.sender, _map);

        return (address(ctmRwa1Sentry));
    }

    function getLastReason() public view returns (string memory) {
        return (string(lastReason));
    }

    function sentryC3Fallback(bytes4 _selector, bytes calldata _data, bytes calldata _reason)
        external
        onlySentryManager
        returns (bool)
    {
        lastSelector = _selector;
        lastData = _data;
        lastReason = _reason;

        emit LogFallback(_selector, _data, _reason);

        return (true);
    }

    function _getTokenAddr(uint256 _ID) internal view returns (address, string memory) {
        (bool ok, address tokenAddr) = ICTMRWAMap(ctmRwa1Map).getTokenContract(_ID, RWA_TYPE, VERSION);
        require(ok, "CTMRWA1StorageFallback: The requested tokenID does not exist");
        string memory tokenAddrStr = tokenAddr.toHexString()._toLower();

        return (tokenAddr, tokenAddrStr);
    }
}
