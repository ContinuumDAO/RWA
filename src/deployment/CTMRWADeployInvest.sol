// SPDX-License-Identifier: BSL-1.1

pragma solidity ^0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { Address, CTMRWAUtils } from "../CTMRWAUtils.sol";
import { FeeType, IERC20Extended, IFeeManager } from "../managers/IFeeManager.sol";
import { CTMRWA1InvestWithTimeLock } from "./CTMRWA1InvestWithTimeLock.sol";
import { ICTMRWADeployInvest } from "./ICTMRWADeployInvest.sol";

contract CTMRWADeployInvest is ICTMRWADeployInvest {
    using Strings for *;
    using CTMRWAUtils for string;

    /// @dev Address of the CTMRWAMap contract
    address public ctmRwaMap;

    /// @dev Address of the CTMRWADeployer contract
    address public ctmRwaDeployer;

    /// @dev The commission rate payable to FeeManager is a number from 0 to 10000 (%0.01)
    uint256 public commissionRate;

    /// @dev Address of the FeeManager contract
    address public feeManager;

    /// @dev String representation of the local chainID
    string cIDStr;

    modifier onlyDeployer() {
        // require(msg.sender == ctmRwaDeployer);
        if (msg.sender != ctmRwaDeployer) {
            revert CTMRWADeployInvest_Unauthorized(Address.Sender);
        }
        _;
    }

    constructor(address _ctmRwaMap, address _deployer, uint256 _commissionRate, address _feeManager) {
        ctmRwaMap = _ctmRwaMap;
        ctmRwaDeployer = _deployer;
        commissionRate = _commissionRate;
        feeManager = _feeManager;

        cIDStr = block.chainid.toString();
    }

    function setDeployerMapFee(address _deployer, address _ctmRwaMap, address _feeManager) external onlyDeployer {
        ctmRwaDeployer = _deployer;
        ctmRwaMap = _ctmRwaMap;
        feeManager = _feeManager;
    }

    function setCommissionRate(uint256 _commissionRate) external onlyDeployer {
        commissionRate = _commissionRate;
    }

    function deployInvest(uint256 _ID, uint256 _rwaType, uint256 _version, address _feeToken)
        external
        onlyDeployer
        returns (address)
    {
        _payFee(FeeType.DEPLOYINVEST, _feeToken);

        bytes32 salt = keccak256(abi.encode(_ID, _rwaType, _version));

        CTMRWA1InvestWithTimeLock newInvest =
            new CTMRWA1InvestWithTimeLock{ salt: salt }(_ID, ctmRwaMap, commissionRate, feeManager);

        return (address(newInvest));
    }

    /// @dev Pay the fee for deploying the Invest contract
    function _payFee(FeeType _feeType, address _feeToken) internal returns (bool) {
        string memory feeTokenStr = _feeToken.toHexString();
        uint256 fee = IFeeManager(feeManager).getXChainFee(cIDStr._stringToArray(), false, _feeType, feeTokenStr);

        // TODO Remove hardcoded multiplier 10**2

        if (fee > 0) {
            uint256 feeWei = fee * 10 ** (IERC20Extended(_feeToken).decimals() - 2);

            IERC20(_feeToken).transferFrom(msg.sender, address(this), feeWei);

            IERC20(_feeToken).approve(feeManager, feeWei);
            IFeeManager(feeManager).payFee(feeWei, feeTokenStr);
        }
        return (true);
    }
}
