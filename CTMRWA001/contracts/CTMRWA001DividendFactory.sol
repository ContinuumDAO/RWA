// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.20;

import "./CTMRWA001Dividend.sol";

interface TokenID {
    function ID() external view returns(uint256);
}

contract CTMRWA001DividendFactory {
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

    function deployDividend(
        address tokenAddr
    ) external onlyDeployer returns(address) {
        uint256 ID = TokenID(tokenAddr).ID();

        CTMRWA001Dividend ctmRwa001Dividend = new CTMRWA001Dividend{
            salt: bytes32(ID) 
        }(
            tokenAddr
        );

        return(address(ctmRwa001Dividend));
    }
}