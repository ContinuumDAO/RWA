// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import { ICTMRWA1Receiver } from "../core/ICTMRWA1Receiver.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

contract CTMRWA1ReceiverMock is IERC165, ICTMRWA1Receiver {
    enum Error {
        None,
        RevertWithMessage,
        RevertWithoutMessage,
        Panic
    }

    bytes4 private immutable _retval;
    Error private immutable _error;

    event Received(address operator, uint256 fromTokenId, uint256 toTokenId, uint256 value, bytes data, uint256 gas);

    constructor(bytes4 retval, Error error) {
        _retval = retval;
        _error = error;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId || interfaceId == type(ICTMRWA1Receiver).interfaceId;
    }

    function onCTMRWA1Received(
        address operator,
        uint256 fromTokenId,
        uint256 toTokenId,
        uint256 value,
        bytes calldata data
    ) public override returns (bytes4) {
        if (_error == Error.RevertWithMessage) {
            revert("CTMRWA1ReceiverMock: reverting");
        } else if (_error == Error.RevertWithoutMessage) {
            revert();
        } else if (_error == Error.Panic) {
            uint256 a = uint256(0) / uint256(0);
            a;
        }
        emit Received(operator, fromTokenId, toTokenId, value, data, gasleft());
        return _retval;
    }
}
