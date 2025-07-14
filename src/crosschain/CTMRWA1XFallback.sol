// SPDX-License-Identifier: BSL-1.1

pragma solidity ^0.8.22;

import { ICTMRWA1 } from "../core/ICTMRWA1.sol";
import { ICTMRWA1XFallback } from "./ICTMRWA1XFallback.sol";

import { CTMRWAUtils } from "../CTMRWAUtils.sol";

/**
 * @title AssetX Multi-chain Semi-Fungible-Token for Real-World-Assets (RWAs)
 * @author @Selqui ContinuumDAO
 *
 * @notice This contract is a helper contract for CTMRWA1X. It manages any cross-chain call failures
 *
 * This contract is only deployed ONCE on each chain and manages all CTMRWA1 contract interactions
 */
contract CTMRWA1XFallback is ICTMRWA1XFallback {
    using CTMRWAUtils for string;

    address public rwa1X;

    bytes4 public lastSelector;
    bytes public lastData;
    bytes public lastReason;

    modifier onlyRwa1X() {
        // require(msg.sender == rwa1X, "CTMRWA1XFallback: onlyRwa1X function");
        if (msg.sender != rwa1X) revert CTMRWA1XFallback_Unauthorized(Address.Sender);
        _;
    }

    bytes4 public MintX = bytes4(keccak256("mintX(uint256,string,string,uint256,uint256,uint256,string)"));

    constructor(address _rwa1X) {
        rwa1X = _rwa1X;
    }

    /// @dev Returns the last revert string after c3Fallback from another chain
    function getLastReason() public view returns (string memory) {
        return (string(lastReason));
    }

    /**
     * @dev Manage a failure in a cross-chain call with c3Caller
     * @param _selector is the function selector called by c3Caller's execute on the destination
     * @param _data is the abi encoded data sent to the destinatin chain
     * @param _reason is the revert string from the destination chain
     * @dev If the failing function was mintX (used for transferFrom), then this function will mint the fungible
     * balance in the CTMRWA1 with ID, as a new tokenId, effectively replacing the value that was
     * burned.
     */
    function rwa1XC3Fallback(bytes4 _selector, bytes calldata _data, bytes calldata _reason)
        external
        onlyRwa1X
        returns (bool)
    {
        lastSelector = _selector;
        lastData = _data;
        lastReason = _reason;

        if (_selector == MintX) {
            uint256 ID_;
            string memory fromAddressStr_;
            string memory toAddressStr_;
            uint256 fromTokenId_;
            uint256 slot_;
            uint256 value_;
            string memory ctmRwa1AddrStr_;

            (ID_, fromAddressStr_, toAddressStr_, fromTokenId_, slot_, value_, ctmRwa1AddrStr_) =
                abi.decode(_data, (uint256, string, string, uint256, uint256, uint256, string));

            address ctmRwa1Addr = ctmRwa1AddrStr_._stringToAddress();
            address fromAddr = fromAddressStr_._stringToAddress();

            string memory thisSlotName = ICTMRWA1(ctmRwa1Addr).slotName(slot_);

            ICTMRWA1(ctmRwa1Addr).mintFromX(fromAddr, slot_, thisSlotName, value_);

            emit ReturnValueFallback(fromAddr, slot_, value_);
        }

        emit LogFallback(_selector, _data, _reason);

        return (true);
    }
}
