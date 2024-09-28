// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/Strings.sol";
import {GovernDapp} from "./routerV2/GovernDapp.sol";

import {ICTMRWATokenFactory} from "./ICTMRWAFactory.sol";

contract CTMRWA001Deployer is GovernDapp {
    using Strings for *;

    address gateway;

    mapping(uint256 => address[]) public tokenFactory;
    mapping(uint256 => address[]) public dividendFactory;

    event LogFallback(bytes4 selector, bytes data, bytes reason);

    modifier onlyGateway {
        require(msg.sender == gateway, "CTMRWADeployer: OnlyGateway function");
        _;
    }

    constructor(
        address _gov,
        address _gateway,
        address _c3callerProxy,
        address _txSender,
        uint256 _dappID
    ) GovernDapp(_gov, _c3callerProxy, _txSender, _dappID) {
        gateway = _gateway;
    }

    function deploy(
        uint256 rwaType,
        uint256 version,
        bytes memory deployData
    ) external onlyGateway returns(address) {
       address tokenAddr = ICTMRWATokenFactory(tokenFactory[rwaType][version]).deploy(deployData);
       return(tokenAddr);
    }

    function deployDividend(
        uint256 rwaType,
        uint256 version,
        bytes memory deployData
    ) external onlyGateway returns(address) {
       address tokenAddr = ICTMRWATokenFactory(dividendFactory[rwaType][version]).deploy(deployData);
       return(tokenAddr);
    }

    function setTokenFactory(uint256 _rwaType, uint256 _version, address _tokenFactory) external onlyGov {
        tokenFactory[_rwaType][_version] = _tokenFactory;
    }

    function setDividendFactory(uint256 _rwaType, uint256 _version, address _dividendFactory) external onlyGov {
        dividendFactory[_rwaType][_version] = _dividendFactory;
    }

    function _c3Fallback(bytes4 _selector,
        bytes calldata _data,
        bytes calldata _reason) internal override returns (bool) {


        emit LogFallback(_selector, _data, _reason);
        return true;
    }

}