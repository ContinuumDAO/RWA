// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

// import "forge-std/console.sol";

import "./CTMRWA001Token.sol";
import {SlotData, ICTMRWA001} from "./interfaces/ICTMRWA001.sol"; 

contract CTMRWA001TokenFactory {

    address public ctmRwaMap;
    address public ctmRwaDeployer;

    modifier onlyDeployer {
        require(msg.sender == ctmRwaDeployer, "CTMRWA001TokenFactory: onlyDeployer function");
        _;
    }

    constructor(
        address _ctmRwaMap,
        address _ctmRwaDeployer
    ) {
        ctmRwaMap = _ctmRwaMap;
        ctmRwaDeployer = _ctmRwaDeployer;
    }

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
            SlotData[] memory allSlots,
            address ctmRwa001X
        ) = abi.decode(_deployData, (uint256, address, string, string, uint8, string, SlotData[], address));

        CTMRWA001Token ctmRwa001Token = new CTMRWA001Token{
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
        ICTMRWA001(ctmRwa001Addr).setAllSlotData(allSlots);

        return(ctmRwa001Addr);
    }

}