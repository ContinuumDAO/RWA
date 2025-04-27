// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import {Context} from "@openzeppelin/contracts/utils/Context.sol";

import {ICTMRWA001} from "./interfaces/ICTMRWA001.sol";

/**
 * @title AssetX Multi-chain Semi-Fungible-Token for Real-World-Assets (RWAs)
 * @author @Selqui ContinuumDAO
 *
 * @notice This contract is a helper contract for CTMRWA001X. It manages any cross-chain call failures
 *
 * This contract is only deployed ONCE on each chain and manages all CTMRWA001 contract interactions
 */

contract CTMRWA001XFallback is Context {

    address public rwa001X;

    bytes4 public lastSelector;
    bytes public lastData;
    bytes public lastReason;

    modifier onlyRwa001X {
        require(_msgSender() == rwa001X, "CTMRWA001XFallback: onlyRwa001X function");
        _;
    }

    event LogFallback(bytes4 selector, bytes data, bytes reason);
    event ReturnValueFallback(address to, uint256 slot, uint256 value);

    bytes4 public MintX =
        bytes4(
            keccak256(
                "mintX(uint256,string,string,uint256,uint256,uint256,string)"
            )
        );
        


    constructor(
        address _rwa001X
    ) {
        rwa001X = _rwa001X;
    }

    /// @dev Returns the last revert string after c3Fallback from another chain
    function getLastReason() public view returns(string memory) {
        return(string(lastReason));
    }

    /**
     * @dev Manage a failure in a cross-chain call with c3Caller
     * @param _selector is the function selector called by c3Caller's execute on the destination
     * @param _data is the abi encoded data sent to the destinatin chain
     * @param _reason is the revert string from the destination chain
     * @dev If the failing function was mintX (used for transferFrom), then this function will mint the fungible 
     * balance in the CTMRWA001 with ID, as a new tokenId, effectively replacing the value that was
     * burned. 
     */
    function rwa001XC3Fallback(
        bytes4 _selector,
        bytes calldata _data,
        bytes calldata _reason
    ) external onlyRwa001X returns(bool) {

        lastSelector = _selector;
        lastData = _data;
        lastReason = _reason;


        if(_selector == MintX) {

            uint256 ID_;
            string memory fromAddressStr_;
            string memory toAddressStr_;
            uint256 fromTokenId_;
            uint256 slot_;
            uint256 value_;
            string memory ctmRwa001AddrStr_;

            (
                ID_,
                fromAddressStr_,
                toAddressStr_,
                fromTokenId_,
                slot_,
                value_,
                ctmRwa001AddrStr_
            ) = abi.decode(_data,
                (uint256,string,string,uint256,uint256,uint256,string)
            );

            address ctmRwa001Addr = stringToAddress(ctmRwa001AddrStr_);
            address fromAddr = stringToAddress(fromAddressStr_);

            string memory thisSlotName = ICTMRWA001(ctmRwa001Addr).slotName(slot_);

            ICTMRWA001(ctmRwa001Addr).mintFromX(fromAddr, slot_, thisSlotName, value_);

            emit ReturnValueFallback(fromAddr, slot_, value_);
        }

        emit LogFallback(_selector, _data, _reason);

        return(true);
    }

    /// @dev Convert a string to an EVM address. Also checks the string length 
    function stringToAddress(string memory str) internal pure returns (address) {
        bytes memory strBytes = bytes(str);
        require(strBytes.length == 42, "CTMRWA001X: Invalid address length");
        bytes memory addrBytes = new bytes(20);

        for (uint i = 0; i < 20; i++) {
            addrBytes[i] = bytes1(
                hexCharToByte(strBytes[2 + i * 2]) *
                    16 +
                    hexCharToByte(strBytes[3 + i * 2])
            );
        }

        return address(uint160(bytes20(addrBytes)));
    }

    function hexCharToByte(bytes1 char) internal pure returns (uint8) {
        uint8 byteValue = uint8(char);
        if (
            byteValue >= uint8(bytes1("0")) && byteValue <= uint8(bytes1("9"))
        ) {
            return byteValue - uint8(bytes1("0"));
        } else if (
            byteValue >= uint8(bytes1("a")) && byteValue <= uint8(bytes1("f"))
        ) {
            return 10 + byteValue - uint8(bytes1("a"));
        } else if (
            byteValue >= uint8(bytes1("A")) && byteValue <= uint8(bytes1("F"))
        ) {
            return 10 + byteValue - uint8(bytes1("A"));
        }
        revert("Invalid hex character");
    }


}