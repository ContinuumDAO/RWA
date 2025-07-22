// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.27;

import { CTMRWAUtils, Uint } from "../utils/CTMRWAUtils.sol";
import { FeeType, IERC20Extended, IFeeManager } from "./IFeeManager.sol";
import { C3GovernDapp } from "@c3caller/gov/C3GovernDapp.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title AssetX Multi-chain Semi-Fungible-Token for Real-World-Assets (RWAs)
 * @author @Selqui ContinuumDAO
 *
 * This contract is used by the whole of AssetX to calculate and charge fees for the AssetX service.
 * Multiple fee currencies can be established, so that users and Issuers can pay in a currency of their
 * choosing.
 * The fees are split up into different enum FeeTypes. The actual fees to be paid depend on the chains
 * involved and different base fees can be set up for each chain. The service fees are multiples of the base fee.
 * Some fees include the local chain and some only for cross-chain components, depending on the includeLocal flag
 * Governance can withdraw fees from this contract to a treasury address.
 * This contract is deployed once on each chain.
 */
contract FeeManager is IFeeManager, ReentrancyGuardUpgradeable, C3GovernDapp, UUPSUpgradeable, PausableUpgradeable {
    using Strings for *;
    using SafeERC20 for IERC20;
    using CTMRWAUtils for string;

    /// @dev A curent list of the allowable fee token ERC20 addresses on this chain
    address[] public feeTokenList;
    /**
     * @dev feeTokenIndexMap is 1-based. If a token is removed and re-added, its index will change.
     * Off-chain consumers should not rely on index stability.
     */
    mapping(address => uint256) public feeTokenIndexMap;
    address[] feetokens;

    /// @dev The multiplier of the baseFee aplpicable for each FeeType
    uint256[29] public feeMultiplier;

    /// @dev A safe multiplier, so that Governance cannot set up an overflow of any FeeType.
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

    /**
     * @notice Add a new fee token to the list of fee tokens allowed to be used
     * @param _feeTokenStr The fee token address (as a string) to add
     * NOTE This only adds a fee token to the list. Its parameters must still be configured
     * with a call to the other addFeeToken function
     */
    function addFeeToken(string memory _feeTokenStr) external onlyGov whenNotPaused nonReentrant returns (bool) {
        if (bytes(_feeTokenStr).length != 42) {
            revert FeeManager_InvalidLength(Uint.Address);
        }
        address feeToken = _feeTokenStr._stringToAddress();
        uint256 index = feeTokenList.length;
        feeTokenList.push(feeToken);
        feeTokenIndexMap[feeToken] = index + 1;
        emit AddFeeToken(feeToken);
        return true;
    }

    /**
     * @notice Remove a fee token from the list of allowable fee tokens
     * @param _feeTokenStr The fee token address (as a string) to remove
     */
    function delFeeToken(string memory _feeTokenStr) external onlyGov whenNotPaused nonReentrant returns (bool) {
        if (bytes(_feeTokenStr).length != 42) {
            revert FeeManager_InvalidLength(Uint.Address);
        }
        address feeToken = _feeTokenStr._stringToAddress();
        if (feeTokenIndexMap[feeToken] == 0) {
            revert FeeManager_NonExistentToken(feeToken);
        }
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

    /**
     * @notice Get a list of all allowable fee token addresses as an array of strings
     */
    function getFeeTokenList() external view virtual returns (address[] memory) {
        return feeTokenList;
    }

    /**
     * @notice Get the index into the fee token list for a particular fee token
     * @param _feeTokenStr The fee token address (as a string) to examine
     */
    function getFeeTokenIndexMap(string memory _feeTokenStr) external view returns (uint256) {
        if (bytes(_feeTokenStr).length != 42) {
            revert FeeManager_InvalidLength(Uint.Address);
        }
        address feeToken = _feeTokenStr._toLower()._stringToAddress();
        return (feeTokenIndexMap[feeToken]);
    }

    /**
     * @notice Add the parameters for fee tokens that are in the feeTokenList
     * @param dstChainIDStr The destination chainId as a string for which parameters are being set
     * @param feeTokensStr An array of fee tokens, as strings, that the fees are being set for
     * @param baseFee This is an array of fees, in wei, for each fee token and to the destination chainId
     * NOTE The actual fee paid for an operation to a chainId is the baseFee multiplied by the fee multiplier
     */
    function addFeeToken(string memory dstChainIDStr, string[] memory feeTokensStr, uint256[] memory baseFee)
        external
        onlyGov
        whenNotPaused
        nonReentrant
        returns (bool)
    {
        if (bytes(dstChainIDStr).length == 0) {
            revert FeeManager_InvalidLength(Uint.ChainID);
        }

        if (feeTokensStr.length != baseFee.length) {
            revert FeeManager_InvalidLength(Uint.Input);
        }

        dstChainIDStr = dstChainIDStr._toLower();

        address[] memory localFeetokens = new address[](feeTokensStr.length);
        for (uint256 i = 0; i < feeTokensStr.length; i++) {
            if (bytes(feeTokensStr[i]).length != 42) {
                revert FeeManager_InvalidLength(Uint.Address);
            }
            localFeetokens[i] = feeTokensStr[i]._toLower()._stringToAddress();
        }

        for (uint256 index = 0; index < feeTokensStr.length; index++) {
            if (feeTokenIndexMap[localFeetokens[index]] == 0) {
                revert FeeManager_NonExistentToken(localFeetokens[index]);
            }
            _toFeeConfigs[dstChainIDStr][localFeetokens[index]] = baseFee[index];
        }
        return true;
    }

    /// @dev Set the fee multiplier (of baseFee) for a particular FeeType
    function setFeeMultiplier(FeeType _feeType, uint256 _multiplier)
        external
        onlyGov
        whenNotPaused
        nonReentrant
        returns (bool)
    {
        uint256 idx = uint256(_feeType);
        if (idx >= feeMultiplier.length) {
            revert FeeManager_InvalidLength(Uint.Input);
        }

        if (_multiplier > MAX_SAFE_MULTIPLIER) {
            revert FeeManager_InvalidLength(Uint.Multiplier);
        }
        feeMultiplier[idx] = _multiplier;
        emit SetFeeMultiplier(_feeType, _multiplier);
        return true;
    }

    /// @dev Get the fee multiplier for a given FeeType
    function getFeeMultiplier(FeeType _feeType) public view returns (uint256) {
        uint256 idx = uint256(_feeType);
        if (idx >= feeMultiplier.length) {
            revert FeeManager_InvalidLength(Uint.Input);
        }
        return feeMultiplier[idx];
    }

    /**
     * @notice Get the fee for a given AssetX operation, depending on the FeeType and the array of
     * chains involved and whether to include the the local chain or not
     * @param _toChainIDsStr An array of chainIds (as strings) to include in the fee calculation
     * @param _includeLocal When to include the local chain in the fee calculation or not
     * @param _feeType The FeeType enum to get the fee for
     * @param _feeTokenStr The fee token address (as a string) to calculate the fee in
     */
    function getXChainFee(
        string[] memory _toChainIDsStr,
        bool _includeLocal,
        FeeType _feeType,
        string memory _feeTokenStr
    ) public view returns (uint256) {
        address feeToken = _feeTokenStr._toLower()._stringToAddress();
        bool ok;
        for (uint256 i = 0; i < feeTokenList.length; i++) {
            if (feeTokenList[i] == feeToken) {
                ok = true;
                break;
            }
        }

        if (!ok) {
            revert FeeManager_NonExistentToken(feeToken);
        }
        uint256 baseFee;
        for (uint256 i = 0; i < _toChainIDsStr.length; i++) {
            if (bytes(_toChainIDsStr[i]).length == 0) {
                revert FeeManager_InvalidLength(Uint.ChainID);
            }
            baseFee += getToChainBaseFee(_toChainIDsStr[i], _feeTokenStr);
        }

        if (_includeLocal) {
            baseFee += getToChainBaseFee(block.chainid.toString(), _feeTokenStr);
        }

        uint256 fee = baseFee * getFeeMultiplier(_feeType);

        return fee;
    }

    /**
     * @notice Pay a fee to this contract for an AssetX service
     * @param _fee The fee to pay in wei
     * @param _feeTokenStr The fee token address (as a string) to pay in
     */
    function payFee(uint256 _fee, string memory _feeTokenStr) external nonReentrant whenNotPaused returns (uint256) {
        if (bytes(_feeTokenStr).length != 42) {
            revert FeeManager_InvalidLength(Uint.Address);
        }
        address feeToken = _feeTokenStr._stringToAddress();
        if (!IERC20(feeToken).transferFrom(msg.sender, address(this), _fee)) {
            revert FeeManager_FailedTransfer();
        }
        return (_fee);
    }

    /**
     * @notice Allow Governance to withdraw the fees collected in this contract to a treasury address
     * @param _feeTokenStr The fee contract address (as a string) to withdraw
     * @param _amount The amount to withdraw in wei
     * @param _treasuryStr The wallet address (as a string) to withdraw to.
     */
    function withdrawFee(string memory _feeTokenStr, uint256 _amount, string memory _treasuryStr)
        external
        onlyGov
        nonReentrant
        whenNotPaused
        returns (bool)
    {
        if (bytes(_feeTokenStr).length != 42) {
            revert FeeManager_InvalidLength(Uint.Address);
        }
        address feeToken = _feeTokenStr._stringToAddress();
        if (bytes(_treasuryStr).length != 42) {
            revert FeeManager_InvalidLength(Uint.Address);
        }
        address treasury = _treasuryStr._stringToAddress();

        uint256 bal = IERC20(feeToken).balanceOf(address(this));
        if (bal < _amount) {
            _amount = bal;
        }
        if (!IERC20(feeToken).transfer(treasury, _amount)) {
            revert FeeManager_FailedTransfer();
        }
        emit WithdrawFee(feeToken, treasury, _amount);
        return true;
    }

    /**
     * @notice Get the configured base fee for a cross chain operation
     * @param _toChainIDStr The chainID (as a string) to consider the fee for
     * @param _feeTokenStr The fee token address (as a string)
     */
    function getToChainBaseFee(string memory _toChainIDStr, string memory _feeTokenStr) public view returns (uint256) {
        if (bytes(_toChainIDStr).length == 0) {
            revert FeeManager_InvalidLength(Uint.ChainID);
        }

        if (bytes(_feeTokenStr).length != 42) {
            revert FeeManager_InvalidLength(Uint.Address);
        }

        address feeToken = _feeTokenStr._stringToAddress();
        string memory toChainIDStr = _toChainIDStr._toLower();
        return _toFeeConfigs[toChainIDStr][feeToken];
    }

    /// @dev The c3caller required fallback contract in the event of a cross-chain error
    function _c3Fallback(bytes4 _selector, bytes calldata _data, bytes calldata _reason)
        internal
        virtual
        override
        returns (bool)
    {
        emit LogFallback(_selector, _data, _reason);

        return true;
    }
}
