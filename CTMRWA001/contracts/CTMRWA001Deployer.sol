// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "./CTMRWA001Token.sol";

contract CTMRWA001Deployer {

    constructor() {}

    function deploy(
        uint256 _ID,
        address admin,
        string memory tokenName_, 
        string memory symbol_, 
        uint8 decimals_,
        string memory baseURI_,
        address gateway_
    ) external returns(address) {
        CTMRWA001Token ctmRwa001Token = new CTMRWA001Token{
            salt: bytes32(_ID) 
        }(
            admin,
            tokenName_, 
            symbol_,
            decimals_,
            baseURI_,
            gateway_
        );

        

        return(address(ctmRwa001Token));
    }
    
}
