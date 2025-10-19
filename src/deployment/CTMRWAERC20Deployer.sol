// SPDX-License-Identifier: BSL-1.1

pragma solidity 0.8.27;

import { ICTMRWA1 } from "../core/ICTMRWA1.sol";
import { ICTMRWA1X } from "../crosschain/ICTMRWA1X.sol";
import { FeeType, IFeeManager } from "../managers/IFeeManager.sol";
import { ICTMRWAMap } from "../shared/ICTMRWAMap.sol";
import { CTMRWAProxy } from "../utils/CTMRWAProxy.sol";
import { CTMRWAUtils, CTMRWAErrorParam } from "../utils/CTMRWAUtils.sol";
import { CTMRWAERC20 } from "./CTMRWAERC20.sol";
import { ICTMRWAERC20Deployer } from "./ICTMRWAERC20Deployer.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title AssetX Multi-chain Semi-Fungible-Token for Real-World-Assets (RWAs)
 * @author @Selqui ContinuumDAO
 *
 * @notice This contract manages the deployment of an ERC20 token from CTMRWADeployer that is an interface to the
 * underlying CTMRWA1 token. It allows the tokenAdmin of the CTMRWA contract to deploy a unique ERC20 representing
 * a single Asset Class (slot).
 *
 * This contract is only deployed ONCE on each chain and manages all CTMRWAERC20 contract
 * deployments.
 */
contract CTMRWAERC20Deployer is ICTMRWAERC20Deployer, ReentrancyGuard {
    using Strings for *;
    using CTMRWAUtils for string;
    using SafeERC20 for IERC20;

    /// @dev The address of the CTMRWAMap contract
    address public ctmRwaMap;

    /// @dev The address of the deployer contract
    address public deployer;

    /// @dev The address of the FeeManager contract
    address public feeManager;

    /// @dev String representation of the local chainID
    string cIdStr;

    constructor(address _ctmRwaMap, address _deployer, address _feeManager) {
        ctmRwaMap = _ctmRwaMap;
        deployer = _deployer;
        feeManager = _feeManager;
        cIdStr = block.chainid.toString();
    }

    modifier onlyDeployer() {
        if (msg.sender != deployer) {
            revert CTMRWAERC20Deployer_OnlyAuthorized(CTMRWAErrorParam.Sender, CTMRWAErrorParam.Deployer);
        }
        _;
    }
    

    /**
     * @notice Deploy a new ERC20 contract linked to a CTMRWA1 with ID, for ONE slot
     * @param _ID The unique ID number for the CTMRWA1
     * @param _rwaType The type of RWA token
     * @param _version The version of the RWA token
     * @param _slot The slot number selected for this ERC20.
     * @param _name The name for the ERC20. This will be pre-pended with "slot X | ", where X is
     * the slot number
     * @param  _feeToken The fee token address to pay. The contract address must be
     * in the return from feeTokenList() in FeeManager
     * @param _originalCaller The address of the original caller who should pay the fee
     * @return erc20Address The address of the deployed ERC20 contract
     * NOTE The public function to deploy the ERC20 is deployERC20 in CTMRWADeployer.
     */
    function deployERC20(
        uint256 _ID,
        uint256 _rwaType,
        uint256 _version,
        uint256 _slot,
        string memory _name,
        address _feeToken,
        address _originalCaller
    ) external onlyDeployer returns (address) {
        (bool ok, address ctmRwaToken) = ICTMRWAMap(ctmRwaMap).getTokenContract(_ID, _rwaType, _version);
        if (!ok) {
            revert CTMRWAERC20Deployer_InvalidContract(CTMRWAErrorParam.Token);
        }
        
        if (bytes(_name).length > 128) {
            revert CTMRWAERC20Deployer_NameTooLong();
        }

        _payFee(FeeType.ERC20, _feeToken, _originalCaller);

        bytes32 salt = keccak256(abi.encode(_ID, _rwaType, _version, _slot));

        CTMRWAERC20 newErc20 = new CTMRWAERC20{ salt: salt }(_ID, _rwaType, _version, _slot, _name, ICTMRWA1(ctmRwaToken).symbol(), ctmRwaMap);

        if (_version != newErc20.VERSION()) {
            revert CTMRWAERC20Deployer_InvalidVersion(_version);
        }
        if (_rwaType != newErc20.RWA_TYPE()) {
            revert CTMRWAERC20Deployer_InvalidRWAType(_rwaType);
        }
        if (_slot != newErc20.slot()) {
            revert CTMRWAERC20Deployer_InvalidSlot(_slot);
        }

        ICTMRWA1(ctmRwaToken).setErc20(address(newErc20), _slot);

        return (address(newErc20));
    }


    /// @dev Pay the fee for deploying the ERC20
    /// @param _feeType The type of fee to pay
    /// @param _feeToken The address of the fee token
    /// @param _originalCaller The address of the original caller who should pay the fee
    /// @return success True if the fee was paid, false otherwise
    function _payFee(FeeType _feeType, address _feeToken, address _originalCaller) internal nonReentrant returns (bool) {
        string memory feeTokenStr = _feeToken.toHexString();
        uint256 feeWei = IFeeManager(feeManager).getXChainFee(cIdStr._stringToArray(), false, _feeType, feeTokenStr);
        feeWei = feeWei * (10000 - IFeeManager(feeManager).getFeeReduction(_originalCaller)) / 10000;

        if (feeWei > 0) {
            // Record spender balance before transfer
            uint256 senderBalanceBefore = IERC20(_feeToken).balanceOf(_originalCaller);

            IERC20(_feeToken).safeTransferFrom(_originalCaller, address(this), feeWei);

            // Assert spender balance change
            uint256 senderBalanceAfter = IERC20(_feeToken).balanceOf(_originalCaller);
            if (senderBalanceBefore - senderBalanceAfter != feeWei) {
                revert CTMRWAERC20Deployer_FailedTransfer();
            }

            IERC20(_feeToken).forceApprove(feeManager, feeWei);
            IFeeManager(feeManager).payFee(feeWei, feeTokenStr);
        }
        return (true);
    }
}
