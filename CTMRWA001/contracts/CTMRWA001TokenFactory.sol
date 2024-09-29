// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "./CTMRWA001Token.sol";

contract CTMRWA001TokenFactory {

    address public deployer;

    modifier onlyDeployer {
        require(msg.sender == deployer, "CTMRWA001TokenFactory: onlyDeployer function");
        _;
    }

    constructor(
        address _deployer
    ) {
        deployer = _deployer;
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
            address gateway
        ) = abi.decode(_deployData, (uint256, address, string, string, uint8, string, address));

        CTMRWA001Token ctmRwa001Token = new CTMRWA001Token{
            salt: bytes32(ID) 
        }(
            admin,
            tokenName, 
            symbol,
            decimals,
            baseURI,
            gateway
        );

        return(address(ctmRwa001Token));
    }

}