// SPDX-License-Identifier: BSL-1.1

pragma solidity 0.8.27;

import { FeeType, IFeeManager } from "../managers/IFeeManager.sol";
import { CTMRWAProxy } from "../utils/CTMRWAProxy.sol";
import { Address, CTMRWAUtils } from "../utils/CTMRWAUtils.sol";
import { CTMRWA1InvestWithTimeLock } from "./CTMRWA1InvestWithTimeLock.sol";
import { ICTMRWADeployInvest } from "./ICTMRWADeployInvest.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title AssetX Multi-chain Semi-Fungible-Token for Real-World-Assets (RWAs)
 * @author @Selqui ContinuumDAO
 *
 * @notice This contract deploys an CTMRWA1InvestWithTimeLock contract. Only one such contract
 * can be deployed for an RWA token per chain, since the salt is tied to the _ID, _rwaType, _version.
 * The contract address of the CTMRWA1InvestWithTimeLock can be got using CTMRWAMap.
 */
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
    string cIdStr;

    modifier onlyDeployer() {
        if (msg.sender != ctmRwaDeployer) {
            revert CTMRWADeployInvest_OnlyAuthorized(Address.Sender, Address.Deployer);
        }
        _;
    }

    constructor(address _ctmRwaMap, address _deployer, uint256 _commissionRate, address _feeManager) {
        ctmRwaMap = _ctmRwaMap;
        ctmRwaDeployer = _deployer;
        commissionRate = _commissionRate;
        feeManager = _feeManager;

        cIdStr = block.chainid.toString();
    }

    /// @dev This allows the deployer, map and fee manager to be set
    /// @param _deployer The address of the deployer
    /// @param _ctmRwaMap The address of the CTMRWAMap contract
    /// @param _feeManager The address of the FeeManager contract
    function setDeployerMapFee(address _deployer, address _ctmRwaMap, address _feeManager) external onlyDeployer {
        ctmRwaDeployer = _deployer;
        ctmRwaMap = _ctmRwaMap;
        feeManager = _feeManager;
    }

    /// @dev This allows a commission to be charged on the offering, payable to the FeeManager contract
    /// @param _commissionRate The commission rate to set
    function setCommissionRate(uint256 _commissionRate) external onlyDeployer {
        commissionRate = _commissionRate;
    }

    /// @dev This deploys a new CTMRWA1Invest contract
    /// @param _ID The ID of the RWA token
    /// @param _rwaType The type of RWA token
    /// @param _version The version of the RWA token
    /// @param _feeToken The address of the fee token
    /// @param _originalCaller The address of the original caller who should pay the fee
    /// @return The address of the deployed CTMRWA1Invest contract
    function deployInvest(uint256 _ID, uint256 _rwaType, uint256 _version, address _feeToken, address _originalCaller)
        external
        onlyDeployer
        returns (address)
    {
        _payFee(FeeType.DEPLOYINVEST, _feeToken, _originalCaller);

        bytes32 salt = keccak256(abi.encode(_ID, _rwaType, _version));

        CTMRWA1InvestWithTimeLock newInvest =
            new CTMRWA1InvestWithTimeLock{ salt: salt }(_ID, ctmRwaMap, commissionRate, feeManager);

        return (address(newInvest));
    }

    /// @dev Pay the fee for deploying the Invest contract
    /// @param _feeType The type of fee to pay
    /// @param _feeToken The address of the fee token
    /// @param _originalCaller The address of the original caller who should pay the fee
    function _payFee(FeeType _feeType, address _feeToken, address _originalCaller) internal returns (bool) {
        string memory feeTokenStr = _feeToken.toHexString();
        uint256 feeWei = IFeeManager(feeManager).getXChainFee(cIdStr._stringToArray(), false, _feeType, feeTokenStr);

        if (feeWei > 0) {
            // Transfer the fee from the original caller to this contract
            IERC20(_feeToken).transferFrom(_originalCaller, address(this), feeWei);

            IERC20(_feeToken).approve(feeManager, feeWei);
            IFeeManager(feeManager).payFee(feeWei, feeTokenStr);
        }
        return (true);
    }
}
