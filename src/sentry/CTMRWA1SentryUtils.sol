// SPDX-License-Identifier: BSL-1.1

pragma solidity 0.8.27;

import { ICTMRWA1 } from "../core/ICTMRWA1.sol";
import { ICTMRWAMap } from "../shared/ICTMRWAMap.sol";
import { Address, CTMRWAUtils } from "../utils/CTMRWAUtils.sol";
import { CTMRWA1Sentry } from "./CTMRWA1Sentry.sol";
import { ICTMRWA1Sentry } from "./ICTMRWA1Sentry.sol";
import { ICTMRWA1SentryUtils } from "./ICTMRWA1SentryUtils.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title AssetX Multi-chain Semi-Fungible-Token for Real-World-Assets (RWAs)
 * @author @Selqui ContinuumDAO
 *
 * @notice The main purpose of this contract is to deploy an instance of CTMRWA1Sentry for a CTMRWA1
 * It also houses the required c3caller fallback function, which currently does not do anything except
 * emit the LogFallback event
 */
contract CTMRWA1SentryUtils is ICTMRWA1SentryUtils {
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
        if (msg.sender != sentryManager) {
            revert CTMRWA1SentryUtils_OnlyAuthorized(Address.Sender, Address.SentryManager);
        }
        _;
    }

    constructor(uint256 _rwaType, uint256 _version, address _map, address _sentryManager) {
        RWA_TYPE = _rwaType;
        VERSION = _version;
        ctmRwa1Map = _map;
        sentryManager = _sentryManager;
    }

    /// @dev Deploy an instance of CTMRWA1Sentry with salt including its unique ID
    /// @param _ID The ID of the RWA token
    /// @param _tokenAddr The address of the CTMRWA1 contract
    /// @param _rwaType The type of RWA token
    /// @param _version The version of the RWA token
    /// @param _map The address of the CTMRWA1Map contract
    /// @return The address of the deployed CTMRWA1Sentry contract
    function deploySentry(uint256 _ID, address _tokenAddr, uint256 _rwaType, uint256 _version, address _map)
        external
        onlySentryManager
        returns (address)
    {
        CTMRWA1Sentry ctmRwa1Sentry =
            new CTMRWA1Sentry{ salt: bytes32(_ID) }(_ID, _tokenAddr, _rwaType, _version, msg.sender, _map);

        return (address(ctmRwa1Sentry));
    }

    /// @dev Get the last revert string for a faile cross-chain c3call. For debug purposes
    /// @return lastReason The latest revert string if a cross-chain call failed for whatever reason
    function getLastReason() public view returns (string memory) {
        return (string(lastReason));
    }

    /// @dev The required c3caller fallback function
    /// @param _selector The selector of the function that failed
    /// @param _data The data of the function that failed
    /// @param _reason The reason for the failure
    /// @return ok True if the fallback was successful, false otherwise.
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

    /// @dev Get the deployed contract address on this chain for this CTMRWA1 ID
    /// @param _ID The ID of the RWA token
    /// @return tokenAddr The address of the CTMRWA1 contract
    /// @return tokenAddrStr The string version of the CTMRWA1 contract address
    function _getTokenAddr(uint256 _ID) internal view returns (address, string memory) {
        (bool ok, address tokenAddr) = ICTMRWAMap(ctmRwa1Map).getTokenContract(_ID, RWA_TYPE, VERSION);
        if (!ok) {
            revert CTMRWA1SentryUtils_InvalidContract(Address.Token);
        }
        string memory tokenAddrStr = tokenAddr.toHexString()._toLower();

        return (tokenAddr, tokenAddrStr);
    }
}
