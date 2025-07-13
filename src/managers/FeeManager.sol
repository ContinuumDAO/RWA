// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import { C3GovernDapp } from "@c3caller/gov/C3GovernDapp.sol";

import { FeeType, IFeeManager } from "./IFeeManager.sol";

import {CTMRWAUtils} from "../CTMRWAUtils.sol";

contract FeeManager is IFeeManager, ReentrancyGuardUpgradeable, C3GovernDapp, UUPSUpgradeable {
    using Strings for *;
    using SafeERC20 for IERC20;
    using CTMRWAUtils for string;

    address[] public feeTokenList;
    mapping(address => uint256) public feeTokenIndexMap;
    address[] feetokens;
    uint256[29] public feeMultiplier;

    event LogFallback(bytes4 selector, bytes data, bytes reason);

    mapping(address => FeeParams) public feeParams;

    struct FeeParams {
        uint256 basePrice; // price in wei per gwei of relevent gasFee
        uint256 lowGas; // price in gwei
        uint256 normalGas;
        uint256 highGas;
        uint256 veryHighGas;
        uint256 lowGasFee; // price in gwei corresponding to lowGas
        uint256 normalGasFee; // price in gwei corresponding to normalGas
        uint256 highGasFee;
        uint256 veryHighGasFee;
    }

    function initialize(address _gov, address _c3callerProxy, address _txSender, uint256 _dappID)
        external
        initializer
    {
        __ReentrancyGuard_init();
        __C3GovernDapp_init(_gov, _c3callerProxy, _txSender, _dappID);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyGov { }

    event Withdrawal(address _oldFeeToken, address _recipient, uint256 _oldTokenContractBalance);

    event AddFeeToken(address indexed _feeToken);
    event DelFeeToken(address indexed _feeToken);

    mapping(string => mapping(address => uint256)) private _toFeeConfigs; // key is toChainIDStr, value key is
        // tokenAddress

    function addFeeToken(string memory feeTokenStr) external onlyGov returns (bool) {
        require(bytes(feeTokenStr).length == 42, "FeeManager: feeTokenStr has the wrong length");
        address feeToken = feeTokenStr._stringToAddress();
        uint256 index = feeTokenList.length;
        feeTokenList.push(feeToken);
        feeTokenIndexMap[feeToken] = index + 1;
        emit AddFeeToken(feeToken);
        return true;
    }

    function delFeeToken(string memory feeTokenStr) external onlyGov returns (bool) {
        require(bytes(feeTokenStr).length == 42, "FeeManager: feeTokenStr has the wrong length");
        address feeToken = feeTokenStr._stringToAddress();
        require(feeTokenIndexMap[feeToken] > 0, "FeeManager: token not exist");
        uint256 index = feeTokenIndexMap[feeToken];
        uint256 len = feeTokenList.length;
        if (index == len) {
            feeTokenList.pop();
        } else {
            address _token = feeTokenList[feeTokenList.length - 1];
            feeTokenList.pop();
            feeTokenList[index - 1] = _token;
            feeTokenIndexMap[_token] = index;
            feeTokenIndexMap[feeToken] = 0;
        }
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
        require(bytes(feeTokenStr).length == 42, "FeeManager: feeTokenStr has the wrong length");
        address feeToken = feeTokenStr._toLower()._stringToAddress();
        return (feeTokenIndexMap[feeToken]);
    }

    function addFeeToken(
        string memory dstChainIDStr,
        string[] memory feeTokensStr,
        uint256[] memory fee // human readable * 100
    ) external onlyGov returns (bool) {
        require(bytes(dstChainIDStr).length > 0, "FeeManager: ChainID empty");

        require(feeTokensStr.length == fee.length, "FeeManager: Invalid list size");

        dstChainIDStr = dstChainIDStr._toLower();

        for (uint256 i = 0; i < feeTokensStr.length; i++) {
            require(bytes(feeTokensStr[i]).length == 42, "FeeManager: Fee token has incorrect length");
            feetokens.push(feeTokensStr[i]._toLower()._stringToAddress());
        }

        for (uint256 index = 0; index < feeTokensStr.length; index++) {
            require(feeTokenIndexMap[feetokens[index]] > 0, "FeeManager: fee token does not exist");
            _toFeeConfigs[dstChainIDStr][feetokens[index]] = fee[index];
        }
        return true;
    }

    function setFeeMultiplier(FeeType _feeType, uint256 _multiplier) external onlyGov returns (bool) {
        if (_feeType == FeeType.ADMIN) {
            feeMultiplier[0] = _multiplier;
            return (true);
        } else if (_feeType == FeeType.DEPLOY) {
            feeMultiplier[1] = _multiplier;
            return (true);
        } else if (_feeType == FeeType.TX) {
            feeMultiplier[2] = _multiplier;
            return (true);
        } else if (_feeType == FeeType.MINT) {
            feeMultiplier[3] = _multiplier;
            return (true);
        } else if (_feeType == FeeType.BURN) {
            feeMultiplier[4] = _multiplier;
            return (true);
        } else if (_feeType == FeeType.ISSUER) {
            feeMultiplier[5] = _multiplier;
            return (true);
        } else if (_feeType == FeeType.PROVENANCE) {
            feeMultiplier[6] = _multiplier;
            return (true);
        } else if (_feeType == FeeType.VALUATION) {
            feeMultiplier[7] = _multiplier;
            return (true);
        } else if (_feeType == FeeType.PROSPECTUS) {
            feeMultiplier[8] = _multiplier;
            return (true);
        } else if (_feeType == FeeType.RATING) {
            feeMultiplier[9] = _multiplier;
            return (true);
        } else if (_feeType == FeeType.LEGAL) {
            feeMultiplier[10] = _multiplier;
            return (true);
        } else if (_feeType == FeeType.FINANCIAL) {
            feeMultiplier[11] = _multiplier;
            return (true);
        } else if (_feeType == FeeType.LICENSE) {
            feeMultiplier[12] = _multiplier;
            return (true);
        } else if (_feeType == FeeType.DUEDILIGENCE) {
            feeMultiplier[13] = _multiplier;
            return (true);
        } else if (_feeType == FeeType.NOTICE) {
            feeMultiplier[14] = _multiplier;
            return (true);
        } else if (_feeType == FeeType.DIVIDEND) {
            feeMultiplier[15] = _multiplier;
            return (true);
        } else if (_feeType == FeeType.REDEMPTION) {
            feeMultiplier[16] = _multiplier;
            return (true);
        } else if (_feeType == FeeType.WHOCANINVEST) {
            feeMultiplier[17] = _multiplier;
            return (true);
        } else if (_feeType == FeeType.IMAGE) {
            feeMultiplier[18] = _multiplier;
            return (true);
        } else if (_feeType == FeeType.VIDEO) {
            feeMultiplier[19] = _multiplier;
            return (true);
        } else if (_feeType == FeeType.ICON) {
            feeMultiplier[20] = _multiplier;
            return (true);
        } else if (_feeType == FeeType.WHITELIST) {
            feeMultiplier[21] = _multiplier;
            return (true);
        } else if (_feeType == FeeType.COUNTRY) {
            feeMultiplier[22] = _multiplier;
            return (true);
        } else if (_feeType == FeeType.KYC) {
            feeMultiplier[23] = _multiplier;
            return (true);
        } else if (_feeType == FeeType.ERC20) {
            feeMultiplier[24] = _multiplier;
            return (true);
        } else if (_feeType == FeeType.DEPLOYINVEST) {
            feeMultiplier[25] = _multiplier;
            return (true);
        } else if (_feeType == FeeType.OFFERING) {
            feeMultiplier[26] = _multiplier;
            return (true);
        } else if (_feeType == FeeType.INVEST) {
            feeMultiplier[27] = _multiplier;
            return (true);
        } else {
            return (false);
        }
    }

    function getFeeMultiplier(FeeType _feeType) public view returns (uint256) {
        if (_feeType == FeeType.ADMIN) {
            return (feeMultiplier[0]);
        } else if (_feeType == FeeType.DEPLOY) {
            return (feeMultiplier[1]);
        } else if (_feeType == FeeType.TX) {
            return (feeMultiplier[2]);
        } else if (_feeType == FeeType.MINT) {
            return (feeMultiplier[3]);
        } else if (_feeType == FeeType.BURN) {
            return (feeMultiplier[4]);
        } else if (_feeType == FeeType.ISSUER) {
            return (feeMultiplier[5]);
        } else if (_feeType == FeeType.PROVENANCE) {
            return (feeMultiplier[6]);
        } else if (_feeType == FeeType.VALUATION) {
            return (feeMultiplier[7]);
        } else if (_feeType == FeeType.PROSPECTUS) {
            return (feeMultiplier[8]);
        } else if (_feeType == FeeType.RATING) {
            return (feeMultiplier[9]);
        } else if (_feeType == FeeType.LEGAL) {
            return (feeMultiplier[10]);
        } else if (_feeType == FeeType.FINANCIAL) {
            return (feeMultiplier[11]);
        } else if (_feeType == FeeType.LICENSE) {
            return (feeMultiplier[12]);
        } else if (_feeType == FeeType.DUEDILIGENCE) {
            return (feeMultiplier[13]);
        } else if (_feeType == FeeType.NOTICE) {
            return (feeMultiplier[14]);
        } else if (_feeType == FeeType.DIVIDEND) {
            return (feeMultiplier[15]);
        } else if (_feeType == FeeType.REDEMPTION) {
            return (feeMultiplier[16]);
        } else if (_feeType == FeeType.WHOCANINVEST) {
            return (feeMultiplier[17]);
        } else if (_feeType == FeeType.IMAGE) {
            return (feeMultiplier[18]);
        } else if (_feeType == FeeType.VIDEO) {
            return (feeMultiplier[19]);
        } else if (_feeType == FeeType.ICON) {
            return (feeMultiplier[20]);
        } else if (_feeType == FeeType.WHITELIST) {
            return (feeMultiplier[21]);
        } else if (_feeType == FeeType.COUNTRY) {
            return (feeMultiplier[22]);
        } else if (_feeType == FeeType.KYC) {
            return (feeMultiplier[23]);
        } else if (_feeType == FeeType.ERC20) {
            return (feeMultiplier[24]);
        } else if (_feeType == FeeType.DEPLOYINVEST) {
            return (feeMultiplier[25]);
        } else if (_feeType == FeeType.OFFERING) {
            return (feeMultiplier[26]);
        } else if (_feeType == FeeType.INVEST) {
            return (feeMultiplier[27]);
        } else {
            revert("FeeManager: Bad FeeType");
        }
    }

    function getXChainFee(
        string[] memory _toChainIDsStr,
        bool _includeLocal,
        FeeType _feeType,
        string memory _feeTokenStr
    ) public view returns (uint256) {
        require(isValidFeeToken(_feeTokenStr), "FeeManager: Not a valid fee token");
        uint256 baseFee;

        for (uint256 i = 0; i < _toChainIDsStr.length; i++) {
            require(bytes(_toChainIDsStr[i]).length > 0, "FeeManager: Invalid chainIDStr");
            baseFee += getToChainBaseFee(_toChainIDsStr[i], _feeTokenStr);
        }

        if (_includeLocal) {
            baseFee += getToChainBaseFee(block.chainid.toString(), _feeTokenStr);
        }

        uint256 fee = baseFee * getFeeMultiplier(_feeType);

        return fee;
    }

    function payFee(uint256 fee, string memory feeTokenStr) external returns (uint256) {
        require(bytes(feeTokenStr).length == 42, "FeeManager: feeTokenStr has the wrong length");
        address feeToken = feeTokenStr._stringToAddress();
        require(IERC20(feeToken).transferFrom(msg.sender, address(this), fee), "FM: Fee payment failed");
        return (fee);
    }

    function withdrawFee(string memory feeTokenStr, uint256 amount, string memory treasuryStr)
        external
        onlyGov
        returns (bool)
    {
        require(bytes(feeTokenStr).length == 42, "FeeManager: feeTokenStr has an incorrect length");
        address feeToken = feeTokenStr._stringToAddress();
        require(bytes(treasuryStr).length == 42, "FeeManager: treasuryStr has an incorrect length");
        address treasury = treasuryStr._stringToAddress();

        uint256 bal = IERC20(feeToken).balanceOf(address(this));
        if (bal < amount) {
            amount = bal;
        }
        require(IERC20(feeToken).transfer(treasury, amount), "FeeManager: transfer fail");
        return true;
    }

    function getToChainBaseFee(string memory toChainIDStr, string memory feeTokenStr) public view returns (uint256) {
        require(bytes(toChainIDStr).length > 0, "FeeManager: toChainIDStr has zero length");
        require(bytes(feeTokenStr).length == 42, "FeeManager: feeTokenStr incorrect length");
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

    function setFeeTokenParams(string memory feeTokenStr, FeeParams memory fee) external onlyGov returns (bool) {
        require(bytes(feeTokenStr).length == 42, "FeeManager: feeTokenStr incorrect length");
        address feeToken = feeTokenStr._stringToAddress();
        feeParams[feeToken] = fee;
        return true;
    }

    function getFeeTokenParams(address _feeToken) public view returns (FeeParams memory) {
        return (feeParams[_feeToken]);
    }

    function cID() internal view returns (uint256) {
        return block.chainid;
    }
}
