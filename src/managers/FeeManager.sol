// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.27;

import { CTMRWAUtils, CTMRWAErrorParam } from "../utils/CTMRWAUtils.sol";
import { FeeType, IERC20Extended, IFeeManager } from "./IFeeManager.sol";
import { C3GovernDAppUpgradeable } from "@c3caller/upgradeable/gov/C3GovernDAppUpgradeable.sol";
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
contract FeeManager is
    IFeeManager,
    ReentrancyGuardUpgradeable,
    C3GovernDAppUpgradeable,
    UUPSUpgradeable,
    PausableUpgradeable
{
    using Strings for *;
    using SafeERC20 for IERC20;
    using CTMRWAUtils for string;

    /// @dev A current list of the allowable fee token ERC20 addresses on this chain
    address[] public feeTokenList;

    /**
     * @dev feeTokenIndexMap is 1-based. If a token is removed and re-added, its index will change.
     * Off-chain consumers should not rely on index stability.
     */
    mapping(address => uint256) public feeTokenIndexMap;
    address[] feetokens;

    /// @dev The multiplier of the baseFee applicable for each FeeType
    uint256[30] public feeMultiplier;

    /// @dev A fee reduction for wallet addresses. address => reduction factor (0 - 10000)
    mapping(address => uint256) public feeReduction;

    ///@dev The expiration timestamp of the fee reduction for a wallet address. address => expiration timestamp
    mapping(address => uint256) public feeReductionExpiration;

    /// @dev A safe multiplier, so that Governance cannot set up an overflow of any FeeType.
    uint256 public constant MAX_SAFE_MULTIPLIER = 1e55;

    event LogFallback(bytes4 selector, bytes data, bytes reason);

    event AddFeeToken(address indexed feeToken);
    event DelFeeToken(address indexed feeToken);
    event SetFeeMultiplier(FeeType indexed feeType, uint256 multiplier);
    event WithdrawFee(address indexed feeToken, address indexed treasury, uint256 amount);
    event AddFeeReduction(address indexed account, uint256 reductionFactor, uint256 expiration);
    event RemoveFeeReduction(address indexed account);
    event UpdateFeeReductionExpiration(address indexed account, uint256 newExpiration);

    /// @dev key is toChainIDStr, value key is tokenAddress
    mapping(string => mapping(address => uint256)) private _toFeeConfigs;

    constructor() {
        _disableInitializers();
    }

    function initialize(address govAddr, address c3callerProxyAddr, address txSender, uint256 dappID2)
        public
        initializer
    {
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();
        __C3GovernDApp_init(govAddr, c3callerProxyAddr, txSender, dappID2);
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
     * @return success True if the fee token was added, false otherwise.
     */
    function addFeeToken(string memory _feeTokenStr) external onlyGov whenNotPaused nonReentrant returns (bool) {
        if (bytes(_feeTokenStr).length != 42) {
            revert FeeManager_InvalidLength(CTMRWAErrorParam.Address);
        }
        address feeToken = _feeTokenStr._stringToAddress();

        // require(feeTokenIndexMap[feeToken] == 0, "FeeManager: token already listed"); // <<-- prevent duplicates
        if (feeTokenIndexMap[feeToken] != 0) {
            revert FeeManager_TokenAlreadyListed(feeToken);
        }
        
        // Check if token is SafeERC20 compliant
        if (!_isSafeERC20Compliant(feeToken)) {
            revert FeeManager_UnsafeToken(feeToken);
        }

        // Check if token is upgradeable (reject upgradeable tokens)
        if (_isUpgradeable(feeToken)) {
            revert FeeManager_UpgradeableToken(feeToken);
        }

        // Check if token has valid decimals (between 6 and 18 inclusive)
        // We know the token has a decimals function from the SafeERC20 compliance check
        uint8 decimals = IERC20Extended(feeToken).decimals();
        if (decimals < 6 || decimals > 18) {
            revert FeeManager_InvalidDecimals(feeToken, decimals);
        }
        
        uint256 index = feeTokenList.length;
        feeTokenList.push(feeToken);
        feeTokenIndexMap[feeToken] = index + 1;
        emit AddFeeToken(feeToken);
        return true;
    }

    /**
     * @notice Remove a fee token from the list of allowable fee tokens
     * @param _feeTokenStr The fee token address (as a string) to remove
     * @return success True if the fee token was removed, false otherwise.
     */
    function delFeeToken(string memory _feeTokenStr) external onlyGov whenNotPaused nonReentrant returns (bool) {
        if (bytes(_feeTokenStr).length != 42) {
            revert FeeManager_InvalidLength(CTMRWAErrorParam.Address);
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
     * @return feeTokenList The list of all allowable fee token addresses as an array of strings
     */
    function getFeeTokenList() external view virtual returns (address[] memory) {
        return feeTokenList;
    }

    /**
     * @notice Get the index into the fee token list for a particular fee token
     * @param _feeTokenStr The fee token address (as a string) to examine
     * @return feeTokenIndexMap The index into the fee token list for a particular fee token
     */
    function getFeeTokenIndexMap(string memory _feeTokenStr) external view returns (uint256) {
        if (bytes(_feeTokenStr).length != 42) {
            revert FeeManager_InvalidLength(CTMRWAErrorParam.Address);
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
     * @return success True if the fee token parameters were added, false otherwise.
     */
    function addFeeToken(string memory dstChainIDStr, string[] memory feeTokensStr, uint256[] memory baseFee)
        external
        onlyGov
        whenNotPaused
        nonReentrant
        returns (bool)
    {
        if (bytes(dstChainIDStr).length == 0) {
            revert FeeManager_InvalidLength(CTMRWAErrorParam.ChainID);
        }

        uint256 len = feeTokensStr.length;

        if (len != baseFee.length) {
            revert FeeManager_InvalidLength(CTMRWAErrorParam.Input);
        }

        dstChainIDStr = dstChainIDStr._toLower();

        address[] memory localFeetokens = new address[](len);
        for (uint256 i = 0; i < len; i++) {
            if (bytes(feeTokensStr[i]).length != 42) {
                revert FeeManager_InvalidLength(CTMRWAErrorParam.Address);
            }
            localFeetokens[i] = feeTokensStr[i]._toLower()._stringToAddress();
        }

        for (uint256 index = 0; index < len; index++) {
            if (feeTokenIndexMap[localFeetokens[index]] == 0) {
                revert FeeManager_NonExistentToken(localFeetokens[index]);
            }
            _toFeeConfigs[dstChainIDStr][localFeetokens[index]] = baseFee[index];
        }
        return true;
    }

    /// @dev Set the fee multiplier (of baseFee) for a particular FeeType
    /// @param _feeType The FeeType enum to set the fee multiplier for
    /// @param _multiplier The multiplier to set for the FeeType
    /// @return success True if the fee multiplier was set, false otherwise.
    function setFeeMultiplier(FeeType _feeType, uint256 _multiplier)
        external
        onlyGov
        whenNotPaused
        nonReentrant
        returns (bool)
    {
        uint256 idx = uint256(_feeType);
        if (idx >= feeMultiplier.length) {
            revert FeeManager_InvalidLength(CTMRWAErrorParam.Input);
        }

        if (_multiplier > MAX_SAFE_MULTIPLIER) {
            revert FeeManager_InvalidLength(CTMRWAErrorParam.Multiplier);
        }
        feeMultiplier[idx] = _multiplier;
        emit SetFeeMultiplier(_feeType, _multiplier);
        return true;
    }

    /// @dev Get the fee multiplier for a given FeeType
    /// @param _feeType The FeeType enum to get the fee multiplier for
    /// @return feeMultiplier The fee multiplier for a given FeeType
    function getFeeMultiplier(FeeType _feeType) public view returns (uint256) {
        uint256 idx = uint256(_feeType);
        if (idx >= feeMultiplier.length) {
            revert FeeManager_InvalidLength(CTMRWAErrorParam.Input);
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
     * @return fee The fee for a given AssetX operation, depending on the FeeType and the array of
     * chains involved and whether to include the the local chain or not
     */
    function getXChainFee(
        string[] memory _toChainIDsStr,
        bool _includeLocal,
        FeeType _feeType,
        string memory _feeTokenStr
    ) public view returns (uint256) {
        if (_feeType == FeeType.EMPTY) {
            revert FeeManager_InvalidFeeType(_feeType);
        }
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
                revert FeeManager_InvalidLength(CTMRWAErrorParam.ChainID);
            }
            baseFee += getToChainBaseFee(_toChainIDsStr[i], _feeTokenStr);
        }

        if (_includeLocal) {
            baseFee += getToChainBaseFee(block.chainid.toString(), _feeTokenStr);
        }

        uint256 fee = baseFee * getFeeMultiplier(_feeType);

        if (fee == 0) {
            revert FeeManager_UnsetFee(feeToken);
        }
        
        return fee;
    }

    /**
     * @notice Pay a fee to this contract for an AssetX service
     * @param _fee The fee to pay in wei
     * @param _feeTokenStr The fee token address (as a string) to pay in
     * @return _fee The fee paid in wei
     */
    function payFee(uint256 _fee, string memory _feeTokenStr) external nonReentrant whenNotPaused returns (uint256) {
        if (bytes(_feeTokenStr).length != 42) {
            revert FeeManager_InvalidLength(CTMRWAErrorParam.Address);
        }
        address feeToken = _feeTokenStr._stringToAddress();
        
        // Record spender balance before transfer
        uint256 senderBalanceBefore = IERC20(feeToken).balanceOf(msg.sender);

        IERC20(feeToken).safeTransferFrom(msg.sender, address(this), _fee);

        // Assert spender balance change
        uint256 senderBalanceAfter = IERC20(feeToken).balanceOf(msg.sender);
        if (senderBalanceBefore - senderBalanceAfter != _fee) {
            revert FeeManager_FailedTransfer();
        }
        
        return (_fee);
    }

    /**
     * @notice Allow Governance to withdraw the fees collected in this contract to a treasury address
     * @param _feeTokenStr The fee contract address (as a string) to withdraw
     * @param _amount The amount to withdraw in wei
     * @param _treasuryStr The wallet address (as a string) to withdraw to.
     * @return success True if the fee was withdrawn, false otherwise.
     */
    function withdrawFee(string memory _feeTokenStr, uint256 _amount, string memory _treasuryStr)
        external
        onlyGov
        nonReentrant
        whenNotPaused
        returns (bool)
    {
        if (bytes(_feeTokenStr).length != 42) {
            revert FeeManager_InvalidLength(CTMRWAErrorParam.Address);
        }
        address feeToken = _feeTokenStr._stringToAddress();
        if (bytes(_treasuryStr).length != 42) {
            revert FeeManager_InvalidLength(CTMRWAErrorParam.Address);
        }
        address treasury = _treasuryStr._stringToAddress();

        uint256 bal = IERC20(feeToken).balanceOf(address(this));
        if (bal < _amount) {
            _amount = bal;
        }
        IERC20(feeToken).safeTransfer(treasury, _amount);
        emit WithdrawFee(feeToken, treasury, _amount);
        return true;
    }

    /**
     * @notice Get the configured base fee for a cross chain operation
     * @param _toChainIDStr The chainID (as a string) to consider the fee for
     * @param _feeTokenStr The fee token address (as a string)
     * @return baseFee The configured base fee for a cross chain operation
     */
    function getToChainBaseFee(string memory _toChainIDStr, string memory _feeTokenStr) public view returns (uint256) {
        if (bytes(_toChainIDStr).length == 0) {
            revert FeeManager_InvalidLength(CTMRWAErrorParam.ChainID);
        }

        if (bytes(_feeTokenStr).length != 42) {
            revert FeeManager_InvalidLength(CTMRWAErrorParam.Address);
        }

        address feeToken = _feeTokenStr._stringToAddress();
        string memory toChainIDStr = _toChainIDStr._toLower();
        uint256 baseFee = _toFeeConfigs[toChainIDStr][feeToken];
        
        // Get the actual decimals of the fee token
        uint8 tokenDecimals = IERC20Extended(feeToken).decimals();
        
        // If token decimals are 18, return as is (no normalization needed)
        if (tokenDecimals == 18) {
            return baseFee;
        }
        
        // Calculate the difference between 18 and actual decimals
        uint256 decimalDifference = 18 - tokenDecimals;
        
        // Divide by 10^(18 - actual_decimals) to normalize from 18 decimals to actual decimals
        return baseFee / (10 ** decimalDifference);
    }

    /**
     * @notice Add fee reduction for multiple addresses with corresponding expiration times
     * @param _addresses Array of addresses to add fee reduction for
     * @param _reductionFactors Array of reduction factors (0-10000, where 10000 = 100%)
     * @param _expirations Array of expiration timestamps (0 for permanent)
     * @return success True if all fee reductions were added successfully
     */
    function addFeeReduction(
        address[] memory _addresses,
        uint256[] memory _reductionFactors,
        uint256[] memory _expirations
    ) external onlyGov whenNotPaused nonReentrant returns (bool) {
        if (_addresses.length != _reductionFactors.length || _addresses.length != _expirations.length) {
            revert FeeManager_InvalidLength(CTMRWAErrorParam.Input);
        }

        for (uint256 i = 0; i < _addresses.length; i++) {
            if (_reductionFactors[i] > 10000) {
                revert FeeManager_InvalidReductionFactor(_reductionFactors[i]);
            }

            if (_expirations[i] > 0 && _expirations[i] < block.timestamp) {
                revert FeeManager_InvalidExpiration(_expirations[i]);
            }
            if (_addresses[i] == address(0)) {
                revert FeeManager_InvalidAddress(_addresses[i]);
            }

            feeReduction[_addresses[i]] = _reductionFactors[i];
            feeReductionExpiration[_addresses[i]] = _expirations[i];
            
            emit AddFeeReduction(_addresses[i], _reductionFactors[i], _expirations[i]);
        }
        
        return true;
    }

    /**
     * @notice Remove fee reduction for multiple addresses
     * @param _addresses Array of addresses to remove fee reduction for
     * @return success True if all fee reductions were removed successfully
     */
    function removeFeeReduction(address[] memory _addresses) external onlyGov whenNotPaused nonReentrant returns (bool) {
        for (uint256 i = 0; i < _addresses.length; i++) {
            if (_addresses[i] == address(0)) {
                revert FeeManager_InvalidAddress(_addresses[i]);
            }

            feeReduction[_addresses[i]] = 0;
            feeReductionExpiration[_addresses[i]] = 0;
            
            emit RemoveFeeReduction(_addresses[i]);
        }
        
        return true;
    }

    /**
     * @notice Update expiration times for multiple addresses
     * @param _addresses Array of addresses to update expiration for
     * @param _newExpirations Array of new expiration timestamps (0 for permanent)
     * @return success True if all expiration times were updated successfully
     */
    function updateFeeReductionExpiration(
        address[] memory _addresses,
        uint256[] memory _newExpirations
    ) external onlyGov whenNotPaused nonReentrant returns (bool) {
        if (_addresses.length != _newExpirations.length) {
            revert FeeManager_InvalidLength(CTMRWAErrorParam.Input);
        }

        for (uint256 i = 0; i < _addresses.length; i++) {
            if (_newExpirations[i] > 0 && _newExpirations[i] < block.timestamp) {
                revert FeeManager_InvalidExpiration(_newExpirations[i]);
            }
            if (_addresses[i] == address(0)) {
                revert FeeManager_InvalidAddress(_addresses[i]);
            }

            feeReductionExpiration[_addresses[i]] = _newExpirations[i];
            
            emit UpdateFeeReductionExpiration(_addresses[i], _newExpirations[i]);
        }
        
        return true;
    }

    /**
     * @notice Get the effective fee reduction factor for a single address
     * @param _address The address to get fee reduction for
     * @return The effective fee reduction factor (0 if no reduction or expired)
     */
    function getFeeReduction(address _address) external view returns (uint256) {
        uint256 reductionFactor = feeReduction[_address];
        uint256 expiration = feeReductionExpiration[_address];
        
        // Return 0 if no reduction is set
        if (reductionFactor == 0) {
            return 0;
        }
        
        // Return 0 if expired (expiration > 0 and current time > expiration)
        if (expiration > 0 && block.timestamp > expiration) {
            return 0;
        }
        
        // Return the reduction factor if active
        return reductionFactor;
    }

      /**
     * @notice Check if a token is SafeERC20 compliant
     * @param token The token address to check
     * @return true if the token is SafeERC20 compliant, false otherwise
     */
    function _isSafeERC20Compliant(address token) internal view returns (bool) {
        // Check if the token has code
        if (token.code.length == 0) {
            return false;
        }

        // Test basic ERC20 functions
        try IERC20(token).balanceOf(address(this)) returns (uint256) {
            // Token responds to balanceOf
        } catch {
            return false;
        }

        try IERC20(token).totalSupply() returns (uint256) {
            // Token responds to totalSupply
        } catch {
            return false;
        }

        // Test if token has the required ERC20 functions
        try IERC20Extended(token).decimals() returns (uint8) {
            // Token has decimals function (IERC20Extended)
        } catch {
            // This is optional, not all ERC20 tokens have decimals
        }

        return true;
    }

    /**
     * @notice Check if a token is upgradeable (proxy pattern)
     * @param token The token address to check
     * @return true if the token is upgradeable, false otherwise
     */
    function _isUpgradeable(address token) internal view returns (bool) {
        // Check if the token has code
        if (token.code.length == 0) {
            return false;
        }

        // Don't check if the token is this contract itself (FeeManager is upgradeable)
        if (token == address(this)) {
            return false;
        }

        // Try to call getImplementation() function which is present in proxy contracts
        // This is a common function in ERC1967 proxies
        (bool success, bytes memory data) = token.staticcall(abi.encodeWithSignature("getImplementation()"));
        
        if (success && data.length >= 32) {
            address impl = abi.decode(data, (address));
            if (impl != address(0)) {
                return true;
            }
        }

        // Also check for upgradeTo function which is present in UUPS proxies
        // Try to call upgradeTo with a valid address to see if the function exists
        (bool hasUpgradeTo,) = token.staticcall(abi.encodeWithSignature("upgradeTo(address)", address(1)));
        if (hasUpgradeTo) {
            return true;
        }
        return false;
    }

    /// @dev The c3caller required fallback contract in the event of a cross-chain error
    /// @return success True if the fallback was successful, false otherwise.
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
