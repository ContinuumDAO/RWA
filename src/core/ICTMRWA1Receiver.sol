// SPDX-License-Identifier: BSL-1.1

pragma solidity 0.8.27;

/**
 * @title CTMRWA1 token receiver interface
 * @dev Interface for a smart contract that wants to be informed by CTMRWA1 contracts when
 *  receiving values from ANY addresses or CTMRWA1 tokens.
 * Note: the EIP-165 identifier for this interface is 0x009ce20b.
 */
interface ICTMRWA1Receiver {
    /**
     * @notice Handle the receipt of an CTMRWA1 token value.
     * @dev An CTMRWA1 smart contract MUST check whether this function is implemented by the
     *  recipient contract, if the recipient contract implements this function, the CTMRWA1
     *  contract MUST call this function after a value transfer (i.e. `transferFrom(uint256,
     *  uint256,uint256,bytes)`).
     *  MUST return 0x009ce20b (i.e. `bytes4(keccak256('onCTMRWA1Received(address,uint256,uint256,
     *  uint256,bytes)'))`) if the transfer is accepted.
     *  MUST revert or return any value other than 0x009ce20b if the transfer is rejected.
     * @param _operator The address which triggered the transfer
     * @param _fromTokenId The token id to transfer value from
     * @param _toTokenId The token id to transfer value to
     * @param _value The transferred value
     * @param _data Additional data with no specified format
     * @return `bytes4(keccak256('onCTMRWA1Received(address,uint256,uint256,uint256,bytes)'))`
     *  unless the transfer is rejected.
     */
    function onCTMRWA1Received(
        address _operator,
        uint256 _fromTokenId,
        uint256 _toTokenId,
        uint256 _value,
        bytes calldata _data
    ) external returns (bytes4);
}
