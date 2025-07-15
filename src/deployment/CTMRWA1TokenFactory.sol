// SPDX-License-Identifier: BSL-1.1

pragma solidity ^0.8.22;

import {ICTMRWA1TokenFactory} from "./ICTMRWA1TokenFactory.sol";
import { CTMRWA1 } from "../core/CTMRWA1.sol";
import { ICTMRWA1, SlotData } from "../core/ICTMRWA1.sol";
import {Address} from "../CTMRWAUtils.sol";

/**
 * @title AssetX Multi-chain Semi-Fungible-Token for Real-World-Assets (RWAs)
 * @author @Selqui ContinuumDAO
 *
 * @notice This contract has one task, which is to deploy a new CTMRWA1 contract on one chain
 * The deploy function is called by CTMRWADeployer. It uses the CREATE2 instruction to deploy the
 * contract, returning its address.
 *
 * This contract is only deployed ONCE on each chain and manages all CTMRWA1 contract deployments
 */
contract CTMRWA1TokenFactory is ICTMRWA1TokenFactory {
    address public ctmRwaMap;
    address public ctmRwaDeployer;

    modifier onlyDeployer() {
        // require(msg.sender == ctmRwaDeployer, "RWATF: onlyDeployer");
        if (msg.sender != ctmRwaDeployer) revert CTMRWA1TokenFactory_Unauthorized(Address.Sender);
        _;
    }

    constructor(address _ctmRwaMap, address _ctmRwaDeployer) {
        ctmRwaMap = _ctmRwaMap;
        ctmRwaDeployer = _ctmRwaDeployer;
    }

    // TODO: Implement these functions
    function deployDividend(uint256 _ID, address _tokenAddr, uint256 _rwaType, uint256 _version, address _ctmRwaMap)
        external
        returns (address) {}

    function deployStorage(uint256 _ID, address _tokenAddr, uint256 _rwaType, uint256 _version, address _ctmRwaMap)
        external
        returns (address) {}

    function deploySentry(uint256 _ID, address _tokenAddr, uint256 _rwaType, uint256 _version, address _ctmRwaMap)
        external
        returns (address) {}

    function setCtmRwaDeployer(address _deployer) external {}

    /**
     * @dev Deploy a new CTMRWA1 using 'salt' ID to ensure a unique contract address
     */
    function deploy(bytes memory _deployData) external onlyDeployer returns (address) {
        (
            uint256 ID,
            address admin,
            string memory tokenName,
            string memory symbol,
            uint8 decimals,
            string memory baseURI,
            uint256[] memory slotNumbers,
            string[] memory slotNames,
            address ctmRwa1X
        ) = abi.decode(_deployData, (uint256, address, string, string, uint8, string, uint256[], string[], address));

        CTMRWA1 ctmRwa1Token =
            new CTMRWA1{ salt: bytes32(ID) }(admin, ctmRwaMap, tokenName, symbol, decimals, baseURI, ctmRwa1X);

        address ctmRwa1Addr = address(ctmRwa1Token);
        if (slotNumbers.length > 0) {
            ICTMRWA1(ctmRwa1Addr).initializeSlotData(slotNumbers, slotNames);
        }

        return (ctmRwa1Addr);
    }
}
