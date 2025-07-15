// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.27;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";

import { C3GovernDapp } from "@c3caller/gov/C3GovernDapp.sol";

import { FeeType, IFeeManager, IERC20Extended } from "./IFeeManager.sol";

import { CTMRWAUtils, Uint } from "../CTMRWAUtils.sol";

contract FeeManager is IFeeManager, ReentrancyGuardUpgradeable, C3GovernDapp, UUPSUpgradeable, PausableUpgradeable {
    using Strings for *;
    using SafeERC20 for IERC20;
    using CTMRWAUtils for string;

    address[] public feeTokenList;
    /**
     * @dev feeTokenIndexMap is 1-based. If a token is removed and re-added, its index will change.
     * Off-chain consumers should not rely on index stability.
     */
    mapping(address => uint256) public feeTokenIndexMap;
    address[] feetokens;
    uint256[29] public feeMultiplier;
    uint256 public constant MAX_SAFE_MULTIPLIER = 1e55;

    event LogFallback(bytes4 selector, bytes data, bytes reason);

    event AddFeeToken(address indexed feeToken);
    event DelFeeToken(address indexed feeToken);
    event SetFeeMultiplier(FeeType indexed feeType, uint256 multiplier);
    event WithdrawFee(address indexed feeToken, address indexed treasury, uint256 amount);

    /// @dev key is toChainIDStr, value key is tokenAddress
    mapping(string => mapping(address => uint256)) private _toFeeConfigs; 

    function initialize(address govAddr, address c3callerProxyAddr, address txSender, uint256 dappID2)
        public
        initializer
    {
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();
        __C3GovernDapp_init(govAddr, c3callerProxyAddr, txSender, dappID2);
        __Pausable_init();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyGov { }

    function pause() external onlyGov {
        _pause();
    }

    function unpause() external onlyGov {
        _unpause();
    }

    function addFeeToken(string memory feeTokenStr) external onlyGov whenNotPaused nonReentrant returns (bool) {
        // require(bytes(feeTokenStr).length == 42, "FeeManager: feeTokenStr has the wrong length");
        if (bytes(feeTokenStr).length != 42) revert FeeManager_InvalidLength(Uint.Address);
        address feeToken = feeTokenStr._stringToAddress();
        uint256 index = feeTokenList.length;
        feeTokenList.push(feeToken);
        feeTokenIndexMap[feeToken] = index + 1;
        emit AddFeeToken(feeToken);
        return true;
    }

    function delFeeToken(string memory feeTokenStr) external onlyGov whenNotPaused nonReentrant returns (bool) {
        // require(bytes(feeTokenStr).length == 42, "FeeManager: feeTokenStr has the wrong length");
        if (bytes(feeTokenStr).length != 42) revert FeeManager_InvalidLength(Uint.Address);
        address feeToken = feeTokenStr._stringToAddress();
        // require(feeTokenIndexMap[feeToken] > 0, "FeeManager: token not exist");
        if (feeTokenIndexMap[feeToken] == 0) revert FeeManager_NonExistentToken(feeToken);
        uint256 index = feeTokenIndexMap[feeToken];
        uint256 len = feeTokenList.length;
        if (index == len) {
            feeTokenList.pop();
        } else {
            address _token = feeTokenList[feeTokenList.length - 1];
            feeTokenList.pop();
            feeTokenList[index - 1] = _token;
            feeTokenIndexMap[_token] = index;
        }
        feeTokenIndexMap[feeToken] = 0;
        emit DelFeeToken(feeToken);
        return true;
    }

    function getFeeTokenList() external view virtual returns (address[] memory) {
        return feeTokenList;
    }

    function isValidFeeToken(string memory feeTokenStr) public view returns (bool) {
        address feeToken = feeTokenStr._toLower()._stringToAddress();

        for (uint256 i = 0; i < feeTokenList.length; i++) {
            if (feeTokenList[i] == feeToken) {
                return (true);
            }
        }

        return (false);
    }

    function getFeeTokenIndexMap(string memory feeTokenStr) external view returns (uint256) {
        // require(bytes(feeTokenStr).length == 42, "FeeManager: feeTokenStr has the wrong length");
        if (bytes(feeTokenStr).length != 42) revert FeeManager_InvalidLength(Uint.Address);
        address feeToken = feeTokenStr._toLower()._stringToAddress();
        return (feeTokenIndexMap[feeToken]);
    }

    /**
     * @notice Add the parameters for fee tokens that are in the feeTokenList
     * @param dstChainIDStr The destination chainId as a string for which parameters are being set
     * @param feeTokensStr An array of fee tokens, as strings, that the fees are being set for
     * @param baseFee This is an array of fees, in wei, for each fee token and to the destination chainId
     * NOTE The actual fee paid for an operation to a chainId is the baseFee multiplied by the fee multiplier
     */
    function addFeeToken(
        string memory dstChainIDStr,
        string[] memory feeTokensStr,
        uint256[] memory baseFee
    ) external onlyGov whenNotPaused nonReentrant returns (bool) {
        // require(bytes(dstChainIDStr).length > 0, "FeeManager: ChainID empty");
        if (bytes(dstChainIDStr).length == 0) revert FeeManager_InvalidLength(Uint.ChainID);

        // require(feeTokensStr.length == baseFee.length, "FeeManager: Invalid list size");
        if (feeTokensStr.length != baseFee.length) revert FeeManager_InvalidLength(Uint.Input);

        dstChainIDStr = dstChainIDStr._toLower();

        address[] memory localFeetokens = new address[](feeTokensStr.length);
        for (uint256 i = 0; i < feeTokensStr.length; i++) {
            // require(bytes(feeTokensStr[i]).length == 42, "FeeManager: Fee token has incorrect length");
            if (bytes(feeTokensStr[i]).length != 42) revert FeeManager_InvalidLength(Uint.Address);
            localFeetokens[i] = feeTokensStr[i]._toLower()._stringToAddress();
        }

        for (uint256 index = 0; index < feeTokensStr.length; index++) {
            // require(feeTokenIndexMap[localFeetokens[index]] > 0, "FeeManager: fee token does not exist");
            if (feeTokenIndexMap[localFeetokens[index]] == 0) revert FeeManager_NonExistentToken(localFeetokens[index]);
            _toFeeConfigs[dstChainIDStr][localFeetokens[index]] = baseFee[index];
        }
        return true;
    }

    function setFeeMultiplier(FeeType _feeType, uint256 _multiplier)
        external
        onlyGov
        whenNotPaused
        nonReentrant
        returns (bool)
    {
        uint256 idx = uint256(_feeType);
        // require(idx < feeMultiplier.length, "FeeManager: Invalid FeeType");
        if (idx >= feeMultiplier.length) revert FeeManager_InvalidLength(Uint.Input);
        // require(_multiplier <= MAX_SAFE_MULTIPLIER, "FeeManager: Multiplier too large");
        if (_multiplier > MAX_SAFE_MULTIPLIER) revert FeeManager_InvalidLength(Uint.Multiplier);
        feeMultiplier[idx] = _multiplier;
        emit SetFeeMultiplier(_feeType, _multiplier);
        return true;
    }

    function getFeeMultiplier(FeeType _feeType) public view returns (uint256) {
        uint256 idx = uint256(_feeType);
        // require(idx < feeMultiplier.length, "FeeManager: Invalid FeeType");
        if (idx >= feeMultiplier.length) revert FeeManager_InvalidLength(Uint.Input);
        return feeMultiplier[idx];
    }

    function getXChainFee(
        string[] memory _toChainIDsStr,
        bool _includeLocal,
        FeeType _feeType,
        string memory _feeTokenStr
    ) public view returns (uint256) {
        address _feeToken = _feeTokenStr._toLower()._stringToAddress();
        bool ok;
        for (uint256 i = 0; i < feeTokenList.length; i++) {
            if (feeTokenList[i] == _feeToken) {
                ok = true;
                break;
            }
        }

        // require(isValidFeeToken(_feeTokenStr), "FeeManager: Not a valid fee token");
        if (!ok) revert FeeManager_NonExistentToken(_feeToken);
        uint256 baseFee;
        for (uint256 i = 0; i < _toChainIDsStr.length; i++) {
            // require(bytes(_toChainIDsStr[i]).length > 0, "FeeManager: Invalid chainIDStr");
            if (bytes(_toChainIDsStr[i]).length == 0) revert FeeManager_InvalidLength(Uint.ChainID);
            baseFee += getToChainBaseFee(_toChainIDsStr[i], _feeTokenStr);
        }

        if (_includeLocal) {
            baseFee += getToChainBaseFee(block.chainid.toString(), _feeTokenStr);
        }

        address feeToken = _feeTokenStr._stringToAddress();
        uint256 fee = baseFee * getFeeMultiplier(_feeType)*10**IERC20Extended(feeToken).decimals();

        return fee;
    }

    function payFee(uint256 fee, string memory feeTokenStr) external nonReentrant whenNotPaused returns (uint256) {
        // require(bytes(feeTokenStr).length == 42, "FeeManager: feeTokenStr has the wrong length");
        if (bytes(feeTokenStr).length != 42) revert FeeManager_InvalidLength(Uint.Address);
        address feeToken = feeTokenStr._stringToAddress();
        // require(IERC20(feeToken).transferFrom(msg.sender, address(this), fee), "FM: Fee payment failed");
        if (!IERC20(feeToken).transferFrom(msg.sender, address(this), fee)) revert FeeManager_FailedTransfer();
        return (fee);
    }

    function withdrawFee(string memory feeTokenStr, uint256 amount, string memory treasuryStr)
        external
        onlyGov
        nonReentrant
        whenNotPaused
        returns (bool)
    {
        // require(bytes(feeTokenStr).length == 42, "FeeManager: feeTokenStr has an incorrect length");
        if (bytes(feeTokenStr).length != 42) revert FeeManager_InvalidLength(Uint.Address);
        address feeToken = feeTokenStr._stringToAddress();
        // require(bytes(treasuryStr).length == 42, "FeeManager: treasuryStr has an incorrect length");
        if (bytes(treasuryStr).length != 42) revert FeeManager_InvalidLength(Uint.Address);
        address treasury = treasuryStr._stringToAddress();

        uint256 bal = IERC20(feeToken).balanceOf(address(this));
        if (bal < amount) {
            amount = bal;
        }
        // require(IERC20(feeToken).transfer(treasury, amount), "FeeManager: transfer fail");
        if (!IERC20(feeToken).transfer(treasury, amount)) revert FeeManager_FailedTransfer();
        emit WithdrawFee(feeToken, treasury, amount);
        return true;
    }

    function getToChainBaseFee(string memory toChainIDStr, string memory feeTokenStr) public view returns (uint256) {
        // require(bytes(toChainIDStr).length > 0, "FeeManager: toChainIDStr has zero length");
        if (bytes(toChainIDStr).length == 0) revert FeeManager_InvalidLength(Uint.ChainID);
        // require(bytes(feeTokenStr).length == 42, "FeeManager: feeTokenStr incorrect length");
        if (bytes(feeTokenStr).length != 42) revert FeeManager_InvalidLength(Uint.Address);
        address feeToken = feeTokenStr._stringToAddress();
        toChainIDStr = toChainIDStr._toLower();
        return _toFeeConfigs[toChainIDStr][feeToken];
    }

    function _c3Fallback(bytes4 _selector, bytes calldata _data, bytes calldata _reason)
        internal
        virtual
        override
        returns (bool)
    {
        emit LogFallback(_selector, _data, _reason);

        return true;
    }

    function cID() internal view returns (uint256) {
        return block.chainid;
    }
}
