// SPDX-License-Identifier: BSL-1.1

pragma solidity 0.8.27;

import { Address } from "../utils/CTMRWAUtils.sol";
import { CTMRWA1Dividend } from "./CTMRWA1Dividend.sol";
import { ICTMRWA1DividendFactory } from "./ICTMRWA1DividendFactory.sol";

/**
 * @title AssetX Multi-chain Semi-Fungible-Token for Real-World-Assets (RWAs)
 * @author @Selqui ContinuumDAO
 *
 * @notice This contract has one task, which is to deploy a new CTMRWA1Dividend contract on
 * one chain. The deploy function is called by CTMRWADeployer. It uses the CREATE2 instruction
 * to deploy the contract, returning its address.
 *
 * This contract is only deployed ONCE on each chain and manages all CTMRWA1Dividend contract
 * deployments.
 */
contract CTMRWA1DividendFactory is ICTMRWA1DividendFactory {
    address public deployer;

    modifier onlyDeployer() {
        if (msg.sender != deployer) {
            revert CTMRWA1DividendFactory_Unauthorized(Address.Sender);
        }
        _;
    }

    constructor(address _deployer) {
        deployer = _deployer;
    }

    /**
     * @dev Deploy a new CTMRWA1Dividend using 'salt' ID to ensure a unique contract address
     */
    function deployDividend(uint256 _ID, address _tokenAddr, uint256 _rwaType, uint256 _version, address _map)
        external
        onlyDeployer
        returns (address)
    {
        CTMRWA1Dividend ctmRwa1Dividend =
            new CTMRWA1Dividend{ salt: bytes32(_ID) }(_ID, _tokenAddr, _rwaType, _version, _map);

        return (address(ctmRwa1Dividend));
    }
}
