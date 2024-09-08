// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./routerV2/GovernDapp.sol";
import "./IFeeManager.sol";

contract FeeManager is GovernDapp, IFeeManager {
    using Math for uint256;
    using SafeERC20 for IERC20;

    address[] public feeTokenList;
    mapping(address => uint256) public feeTokenIndexMap;

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

    constructor(
        address _gov,
        address _c3callerProxy,
        address _txSender,
        uint256 _dappID
    ) GovernDapp(_gov, _c3callerProxy, _txSender, _dappID) {}

    event Withdrawal(
        address _oldFeeToken,
        address _recipient,
        uint256 _oldTokenContractBalance
    );

    event AddFeeToken(address indexed _feeToken);
    event DelFeeToken(address indexed _feeToken);

    //event SetLiqFee(address indexed _feeToken, uint256 _fee);

    uint256 public constant FROM_CHAIN_PAY = 1;
    uint256 public constant TO_CHAIN_PAY = 2;

    mapping(uint256 => mapping(address => uint256)) private _fromFeeConfigs; // key is fromChainID, value key is tokenAddress
    mapping(uint256 => mapping(address => uint256)) private _toFeeConfigs; // key is toChainID, value key is tokenAddress

    mapping(address => uint256) private _liqBaseFeeConfigs; // key is tokenAddress

    function addFeeToken(address _feeToken) external onlyGov returns (bool) {
        uint256 index = feeTokenList.length;
        feeTokenList.push(_feeToken);
        feeTokenIndexMap[_feeToken] = index + 1;
        emit AddFeeToken(_feeToken);
        return true;
    }

    function delFeeToken(address _feeToken) external onlyGov returns (bool) {
        require(feeTokenIndexMap[_feeToken] > 0, "FM: token not exist");
        uint256 index = feeTokenIndexMap[_feeToken];
        uint256 len = feeTokenList.length;
        if (index == len) {
            feeTokenList.pop();
        } else {
            address _token = feeTokenList[feeTokenList.length - 1];
            feeTokenList.pop();
            feeTokenList[index - 1] = _token;
            feeTokenIndexMap[_token] = index;
            feeTokenIndexMap[_feeToken] = 0;
        }
        emit DelFeeToken(_feeToken);
        return true;
    }

    function getFeeTokenList() external view returns(address[] memory) {
        return feeTokenList;
    }

    function getFeeTokenIndexMap(address feeToken) external view returns (uint256) {
        return(feeTokenIndexMap[feeToken]);
    }

    function setFeeConfig(
        uint256 srcChainID,
        uint256 dstChainID,
        uint256 payFrom, // 1:from 2:to 0:free
        address[] memory feetokens,
        uint256[] memory fee // human readable * 100
    ) external onlyGov returns (bool) {
        require(srcChainID > 0 || dstChainID > 0, "FM: ChainID empty");
        require(
            payFrom == FROM_CHAIN_PAY || payFrom == TO_CHAIN_PAY,
            "FM: Invalid payFrom"
        );
        require(feetokens.length == fee.length, "FM: Invalid list size");

        for (uint256 index = 0; index < feetokens.length; index++) {
            require(
                feeTokenIndexMap[feetokens[index]] > 0,
                "FM: token not exist"
            );
            if (payFrom == FROM_CHAIN_PAY) {
                _fromFeeConfigs[block.chainid][feetokens[index]] = fee[index];
            } else if (payFrom == TO_CHAIN_PAY) {
                _toFeeConfigs[dstChainID][feetokens[index]] = fee[index];
            }
        }
        return true;
    }

    function getXChainFee(
        uint256 fromChainID,
        uint256 toChainID,
        address feeToken
    ) public view returns (uint256) {
        require(fromChainID > 0 || toChainID > 0, "FM: Invalid chainID");
        uint256 fee = getFromChainFee(fromChainID, feeToken);
        if (fee == 0) {
            fee = getToChainFee(toChainID, feeToken);
        }
        return fee;
    }

    function payFee(uint256 fee, address feeToken) external returns (uint256) {
        require(
            IERC20(feeToken).transferFrom(
                msg.sender,
                address(this),
                fee
            ),
            "FeeConfig: Fee payment failed"
        );
        return (fee);
    }

    
    function withdrawFee(
        address feeToken,
        uint256 amount
    ) external onlyGov returns (bool) {
        uint256 bal = IERC20(feeToken).balanceOf(address(this));
        if (bal < amount) {
            amount = bal;
        }
        require(IERC20(feeToken).transfer(msg.sender, amount), "transfer fail");
        return true;
    }

    function getFromChainFee(
        uint256 fromChainID,
        address feeToken
    ) public view returns (uint256) {
        return _fromFeeConfigs[fromChainID][feeToken];
    }

    function getToChainFee(
        uint256 toChainID,
        address feeToken
    ) public view returns (uint256) {
        return _toFeeConfigs[toChainID][feeToken];
    }

    function _c3Fallback(
        bytes4 /*_selector*/,
        bytes calldata /*_data*/,
        bytes calldata /*_reason*/
    ) internal virtual override returns (bool) {
        return true;
    }

    function setFeeTokenParams(
        address _feeToken,
        FeeParams memory fee
    ) external onlyGov returns (bool) {
        feeParams[_feeToken] = fee;
        return true;
    }

    function getFeeTokenParams(
        address _feeToken
    ) public view returns (FeeParams memory) {
        return (feeParams[_feeToken]);
    }

    function getGasFee(
        uint256 toChainId,
        address feeToken
    ) public view returns (uint256) {
        if (feeParams[feeToken].basePrice == 0) {
            return 0;
        }

        uint256 gasPrice;
        assembly {
            gasPrice := gasprice()
        }

        if (toChainId == 1) {
            if (gasPrice < feeParams[feeToken].lowGas) {
                return (feeParams[feeToken].basePrice *
                    feeParams[feeToken].lowGasFee);
            } else if (gasPrice < feeParams[feeToken].normalGas) {
                return (feeParams[feeToken].basePrice *
                    feeParams[feeToken].normalGasFee);
            } else if (gasPrice < feeParams[feeToken].highGas) {
                return (feeParams[feeToken].basePrice *
                    feeParams[feeToken].highGasFee);
            } else {
                return (feeParams[feeToken].basePrice *
                    feeParams[feeToken].veryHighGasFee);
            }
        } else return (0); // only bother with Ethereum gas fees
    }
}