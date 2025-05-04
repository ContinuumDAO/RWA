// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;


import "./CTMRWA001Dividend.sol";

interface TokenID {
    function ID() external view returns(uint256);
}

/**
 * @title AssetX Multi-chain Semi-Fungible-Token for Real-World-Assets (RWAs)
 * @author @Selqui ContinuumDAO
 *
 * @notice This contract has one task, which is to deploy a new CTMRWA001Dividend contract on 
 * one chain. The deploy function is called by CTMRWADeployer. It uses the CREATE2 instruction
 * to deploy the contract, returning its address.
 *
 * This contract is only deployed ONCE on each chain and manages all CTMRWA001Dividend contract 
 * deployments.
 */

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

    /**
     * @dev Deploy a new CTMRWA001Dividend using 'salt' ID to ensure a unique contract address
     */
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