// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "../interfaces/ICTMRWA001Receiver.sol";

contract CTMRWA001ReceiverMock is IERC165, ICTMRWA001Receiver {
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
        return
            interfaceId == type(IERC165).interfaceId || 
            interfaceId == type(ICTMRWA001Receiver).interfaceId;
    } 

    function onCTMRWA001Received(
        address operator, 
        uint256 fromTokenId, 
        uint256 toTokenId, 
        uint256 value, 
        bytes calldata data
    ) public override returns (bytes4) {
        if (_error == Error.RevertWithMessage) {
            revert("CTMRWA001ReceiverMock: reverting");
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