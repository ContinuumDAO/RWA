// SPDX-License-Identifier: BSL-1.1

pragma solidity 0.8.27;

import { ICTMRWA1 } from "../core/ICTMRWA1.sol";
import { ICTMRWA1X } from "../crosschain/ICTMRWA1X.sol";
import { FeeType, IFeeManager } from "../managers/IFeeManager.sol";
import { ICTMRWAMap } from "../shared/ICTMRWAMap.sol";
import { CTMRWAProxy } from "../utils/CTMRWAProxy.sol";
import { Address, CTMRWAUtils } from "../utils/CTMRWAUtils.sol";
import { CTMRWAERC20 } from "./CTMRWAERC20.sol";
import { ICTMRWAERC20Deployer } from "./ICTMRWAERC20Deployer.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title AssetX Multi-chain Semi-Fungible-Token for Real-World-Assets (RWAs)
 * @author @Selqui ContinuumDAO
 *
 * @notice This contract manages the deployment of an ERC20 token that is an interface to the
 * underlying CTMRWA1 token. It allows the tokenAdmin (Issuer) to deploy a unique ERC20 representing
 * a single Asset Class (slot).
 *
 * Whereas anyone could call deployERC20() in this contract, there is no point, since it has to be
 * called by CTMRWA1 to be valid and linked to the CTMRWA1.
 *
 * This contract is only deployed ONCE on each chain and manages all CTMRWA1Dividend contract
 * deployments.
 */
contract CTMRWAERC20Deployer is ICTMRWAERC20Deployer, ReentrancyGuard {
    using Strings for *;
    using CTMRWAUtils for string;

    /// @dev Address of the CTMRWAMap contract
    address public ctmRwaMap;

    /// @dev Address of the FeeManager contract
    address public feeManager;

    /// @dev String representation of the local chainID
    string cIdStr;

    constructor(address _ctmRwaMap, address _feeManager) {
        if (_ctmRwaMap == address(0)) {
            revert CTMRWAERC20Deployer_IsZeroAddress(Address.Map);
        }
        if (_feeManager == address(0)) {
            revert CTMRWAERC20Deployer_IsZeroAddress(Address.FeeManager);
        }

        ctmRwaMap = _ctmRwaMap;
        feeManager = _feeManager;

        cIdStr = block.chainid.toString();
    }

    /**
     * @notice Deploy a new ERC20 contract linked to a CTMRWA1 with ID, for ONE slot
     * @param _ID The unique ID number for the CTMRWA1
     * @param _slot The slot number selected for this ERC20.
     * @param _name The name for the ERC20. This will be pre-pended with "slot X | ", where X is
     * the slot number
     * @param  _symbol The symbol to use for the ERC20
     * @param  _feeToken The fee token address to pay. The contract address must be
     * in the return from feeTokenList() in FeeManager
     * NOTE The resulting ERC20 is only valid if this function is called from a CTMRWA1 contract
     * otherwise it will not be linked to it.
     */
    function deployERC20(
        uint256 _ID,
        uint256 _rwaType,
        uint256 _version,
        uint256 _slot,
        string memory _name,
        string memory _symbol,
        address _feeToken
    ) external returns (address) {
        (bool ok, address ctmRwaToken) = ICTMRWAMap(ctmRwaMap).getTokenContract(_ID, _rwaType, _version);
        if (!ok) {
            revert CTMRWAERC20Deployer_InvalidContract(Address.Token);
        }
        if (msg.sender != ctmRwaToken) {
            revert CTMRWAERC20Deployer_Unauthorized(Address.Sender);
        }

        _payFee(FeeType.ERC20, _feeToken);

        bytes32 salt = keccak256(abi.encode(_ID, _rwaType, _version, _slot));

        CTMRWAERC20 newErc20 = new CTMRWAERC20{ salt: salt }(_ID, _rwaType, _version, _slot, _name, _symbol, ctmRwaMap);

        return (address(newErc20));
    }

    /// @dev Pay the fee for deploying the ERC20
    function _payFee(FeeType _feeType, address _feeToken) internal nonReentrant returns (bool) {
        string memory feeTokenStr = _feeToken.toHexString();
        uint256 feeWei = IFeeManager(feeManager).getXChainFee(cIdStr._stringToArray(), false, _feeType, feeTokenStr);

        if (feeWei > 0) {
            IERC20(_feeToken).transferFrom(msg.sender, address(this), feeWei);

            IERC20(_feeToken).approve(feeManager, feeWei);
            IFeeManager(feeManager).payFee(feeWei, feeTokenStr);
        }
        return (true);
    }
}
