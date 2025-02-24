// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

// import "forge-std/console.sol";

import "./CTMRWA001Dividend.sol";

interface TokenID {
    function ID() external view returns(uint256);
}

contract CTMRWA001DividendFactory {
    address public deployer;

    modifier onlyDeployer {
        require(msg.sender == deployer, "CTMRWA001DividendFactory: onlyDeployer function");
        _;
    }

    constructor(
        address _deployer
    ) {
        deployer = _deployer;
    }

    function deployDividend(
        uint256 _ID,
        address _tokenAddr,
        uint256 _rwaType,
        uint256 _version,
        address _map
    ) external onlyDeployer returns(address) {

        CTMRWA001Dividend ctmRwa001Dividend = new CTMRWA001Dividend{
            salt: bytes32(_ID) 
        }(_ID,_tokenAddr, _rwaType, _version, _map);

        return(address(ctmRwa001Dividend));
    }
}