// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import "./CTMRWA001.sol";
import {SlotData, ICTMRWA001} from "./interfaces/ICTMRWA001.sol";

/**
 * @title AssetX Multi-chain Semi-Fungible-Token for Real-World-Assets (RWAs)
 * @author @Selqui ContinuumDAO
 *
 * @notice This contract has one task, which is to deploy a new CTMRWA001 contract on one chain
 * The deploy function is called by CTMRWADeployer. It uses the CREATE2 instruction to deploy the
 * contract, returning its address.
 *
 * This contract is only deployed ONCE on each chain and manages all CTMRWA001 contract deployments
 */

contract CTMRWA001TokenFactory {

    address public ctmRwaMap;
    address public ctmRwaDeployer;

    modifier onlyDeployer {
        require(msg.sender == ctmRwaDeployer, "RWATF: onlyDeployer");
        _;
    }

    constructor(
        address _ctmRwaMap,
        address _ctmRwaDeployer
    ) {
        ctmRwaMap = _ctmRwaMap;
        ctmRwaDeployer = _ctmRwaDeployer;
    }

    /**
     * @dev Deploy a new CTMRWA001 using 'salt' ID to ensure a unique contract address
     */
    function deploy(
        bytes memory _deployData
    ) external onlyDeployer returns(address) {

        (
            uint256 ID,
            address admin,
            string memory tokenName,
            string memory symbol,
            uint8 decimals,
            string memory baseURI,
            uint256[] memory slotNumbers,
            string[] memory slotNames,
            address ctmRwa001X
        ) = abi.decode(_deployData, (uint256, address, string, string, uint8, string, uint256[], string[], address));

        CTMRWA001 ctmRwa001Token = new CTMRWA001{
            salt: bytes32(ID) 
        }(
            admin,
            ctmRwaMap,
            tokenName, 
            symbol,
            decimals,
            baseURI,
            ctmRwa001X
        );

        address ctmRwa001Addr = address(ctmRwa001Token);
        if(slotNumbers.length >0 ) {
            ICTMRWA001(ctmRwa001Addr).initializeSlotData(slotNumbers, slotNames);
        }

        return(ctmRwa001Addr);
    }

}