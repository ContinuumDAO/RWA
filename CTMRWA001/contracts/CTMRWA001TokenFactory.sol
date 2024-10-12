// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

// import "forge-std/console.sol";

import "./CTMRWA001Token.sol";

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
            address ctmRwa001X
        ) = abi.decode(_deployData, (uint256, address, string, string, uint8, string, address));

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

        return(address(ctmRwa001Token));
    }

}