// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


import "./routerV2/GovernDapp.sol";
import "./interfaces/IFeeManager.sol";



contract FeeManager is GovernDapp, IFeeManager {
    using Strings for *;
    using SafeERC20 for IERC20;

    address[] public feeTokenList;
    mapping(address => uint256) public feeTokenIndexMap;
    address[] feetokens;
    uint256[7] public feeMultiplier;

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

    mapping(string => mapping(address => uint256)) private _toFeeConfigs; // key is toChainIDStr, value key is tokenAddress

    function addFeeToken(string memory feeTokenStr) external onlyGov returns (bool) {
        require(bytes(feeTokenStr).length == 42, "FeeManager: feeTokenStr has the wrong length");
        address feeToken = stringToAddress(feeTokenStr);
        uint256 index = feeTokenList.length;
        feeTokenList.push(feeToken);
        feeTokenIndexMap[feeToken] = index + 1;
        emit AddFeeToken(feeToken);
        return true;
    }

    function delFeeToken(string memory feeTokenStr) external onlyGov returns (bool) {
        require(bytes(feeTokenStr).length == 42, "FeeManager: feeTokenStr has the wrong length");
        address feeToken = stringToAddress(feeTokenStr);
        require(feeTokenIndexMap[feeToken] > 0, "FM: token not exist");
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

    function getFeeTokenList() external view returns(address[] memory) {
        return feeTokenList;
    }

    function isValidFeeToken(string memory feeTokenStr) public view returns(bool) {
        address feeToken = stringToAddress(_toLower(feeTokenStr));

        for(uint256 i=0;i<feeTokenList.length; i++) {
            if(feeTokenList[i] == feeToken) return(true);
        }

        return(false);
    }

    function getFeeTokenIndexMap(string memory feeTokenStr) external view returns (uint256) {
        require(bytes(feeTokenStr).length == 42, "FeeManager: feeTokenStr has the wrong length");
        address feeToken = stringToAddress(_toLower(feeTokenStr));
        return(feeTokenIndexMap[feeToken]);
    }

    function addFeeToken(
        string memory dstChainIDStr,
        string[] memory feeTokensStr,
        uint256[] memory fee // human readable * 100
    ) external onlyGov returns (bool) {
        require(bytes(dstChainIDStr).length > 0, "FM: ChainID empty");
        
        require(feeTokensStr.length == fee.length, "FM: Invalid list size");

        dstChainIDStr = _toLower(dstChainIDStr);

        for(uint256 i=0; i < feeTokensStr.length; i++) {
            require(bytes(feeTokensStr[i]).length == 42, "FeeManager: Fee token has incorrect length");
            feetokens.push(stringToAddress(_toLower(feeTokensStr[i])));
        }

        for (uint256 index = 0; index < feeTokensStr.length; index++) {
            require(
                feeTokenIndexMap[feetokens[index]] > 0,
                "FM: fee token does not exist"
            );
            _toFeeConfigs[dstChainIDStr][feetokens[index]] = fee[index];
        }
        return true;
    }

    function setFeeMultiplier(FeeType _feeType, uint256 _multiplier) external onlyGov returns (bool) {
        if(_feeType == FeeType.ADMIN) {
            feeMultiplier[0] = _multiplier;
            return(true);
        } else if (_feeType == FeeType.DEPLOY) {
            feeMultiplier[1] = _multiplier;
            return(true);
        } else if (_feeType == FeeType.TX) {
            feeMultiplier[2] = _multiplier;
            return(true);
        } else if (_feeType == FeeType.MINT) {
            feeMultiplier[3] = _multiplier;
            return(true);
        } else if (_feeType == FeeType.BURN) {
            feeMultiplier[4] = _multiplier;
            return(true);
        } else if (_feeType == FeeType.URICONTRACT) {
            feeMultiplier[5] = _multiplier;
            return(true);
        } else if (_feeType == FeeType.URISLOT) {
            feeMultiplier[6] = _multiplier;
            return(true);
        } else {
            return(false);
        }
    }

    function getFeeMultiplier(FeeType _feeType) external view returns (uint256) {
        if(_feeType == FeeType.ADMIN) {
            return(feeMultiplier[0]);
        } else if (_feeType == FeeType.DEPLOY) {
            return(feeMultiplier[1]);
        } else if (_feeType == FeeType.TX) {
            return(feeMultiplier[2]);
        } else if (_feeType == FeeType.MINT) {
            return(feeMultiplier[3]);
        } else if (_feeType == FeeType.BURN) {
            return(feeMultiplier[4]);
        }  else if (_feeType == FeeType.URICONTRACT) {
            return(feeMultiplier[5]);
        }  else if (_feeType == FeeType.URISLOT) {
            return(feeMultiplier[6]);
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
        //
        require(isValidFeeToken(_feeTokenStr), "FeeManager: Not a valid fee token");
        uint256 baseFee;

        for(uint256 i=0; i<_toChainIDsStr.length; i++) {
            require(bytes(_toChainIDsStr[i]).length > 0, "FM: Invalid chainIDStr");
            baseFee += getToChainBaseFee(_toChainIDsStr[i], _feeTokenStr);
        }

        if(_includeLocal) {
            baseFee += getToChainBaseFee(block.chainid.toString(), _feeTokenStr);
        }
        
        uint256 fee = baseFee*this.getFeeMultiplier(_feeType);
        
        return fee;
    }

    function payFee(uint256 fee, string memory feeTokenStr) external returns (uint256) {
        require(bytes(feeTokenStr).length == 42, "FeeManager: feeTokenStr has the wrong length");
        address feeToken = stringToAddress(feeTokenStr);
        require(
            IERC20(feeToken).transferFrom(
                msg.sender,
                address(this),
                fee
            ),
            "FM: Fee payment failed"
        );
        return (fee);
    }

    
    function withdrawFee(
        string memory feeTokenStr,
        uint256 amount,
        string memory treasuryStr
    ) external onlyGov returns (bool) {
        require(bytes(feeTokenStr).length == 42, "FeeManager: feeTokenStr has an incorrect length");
        address feeToken = stringToAddress(feeTokenStr);
        require(bytes(treasuryStr).length == 42, "FeeManager: treasuryStr has an incorrect length");
        address treasury = stringToAddress(treasuryStr);

        uint256 bal = IERC20(feeToken).balanceOf(address(this));
        if (bal < amount) {
            amount = bal;
        }
        require(IERC20(feeToken).transfer(treasury, amount), "FM: transfer fail");
        return true;
    }

    function getToChainBaseFee(
        string memory toChainIDStr,
        string memory feeTokenStr
    ) public view returns (uint256) {
        require(bytes(toChainIDStr).length > 0, "FeeManager: toChainIDStr has zero length");
        require(bytes(feeTokenStr).length == 42, "FeeManager: feeTokenStr incorrect length");
        address feeToken = stringToAddress(feeTokenStr);
        toChainIDStr = _toLower(toChainIDStr);
        return _toFeeConfigs[toChainIDStr][feeToken];
    }

    function _c3Fallback(
        bytes4 /*_selector*/,
        bytes calldata /*_data*/,
        bytes calldata /*_reason*/
    ) internal virtual override returns (bool) {
        return true;
    }

    function setFeeTokenParams(
        string memory feeTokenStr,
        FeeParams memory fee
    ) external onlyGov returns (bool) {
        require(bytes(feeTokenStr).length == 42, "FeeManager: feeTokenStr incorrect length");
        address feeToken = stringToAddress(feeTokenStr);
        feeParams[feeToken] = fee;
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

    function cID() internal view returns (uint256) {
        return block.chainid;
    }

    function strToUint(
        string memory _str
    ) internal pure returns (uint256 res, bool err) {
        if (bytes(_str).length == 0) {
            return (0, true);
        }
        for (uint256 i = 0; i < bytes(_str).length; i++) {
            if (
                (uint8(bytes(_str)[i]) - 48) < 0 ||
                (uint8(bytes(_str)[i]) - 48) > 9
            ) {
                return (0, false);
            }
            res +=
                (uint8(bytes(_str)[i]) - 48) *
                10 ** (bytes(_str).length - i - 1);
        }

        return (res, true);
    }

    function stringToAddress(string memory str) internal pure returns (address) {
        bytes memory strBytes = bytes(str);
        require(strBytes.length == 42, "CTMRWA001X: Invalid address length");
        bytes memory addrBytes = new bytes(20);

        for (uint i = 0; i < 20; i++) {
            addrBytes[i] = bytes1(
                hexCharToByte(strBytes[2 + i * 2]) *
                    16 +
                    hexCharToByte(strBytes[3 + i * 2])
            );
        }

        return address(uint160(bytes20(addrBytes)));
    }

    function hexCharToByte(bytes1 char) internal pure returns (uint8) {
        uint8 byteValue = uint8(char);
        if (
            byteValue >= uint8(bytes1("0")) && byteValue <= uint8(bytes1("9"))
        ) {
            return byteValue - uint8(bytes1("0"));
        } else if (
            byteValue >= uint8(bytes1("a")) && byteValue <= uint8(bytes1("f"))
        ) {
            return 10 + byteValue - uint8(bytes1("a"));
        } else if (
            byteValue >= uint8(bytes1("A")) && byteValue <= uint8(bytes1("F"))
        ) {
            return 10 + byteValue - uint8(bytes1("A"));
        }
        revert("Invalid hex character");
    }

    function stringsEqual(
        string memory a,
        string memory b
    ) internal pure returns (bool) {
        bytes32 ka = keccak256(abi.encode(a));
        bytes32 kb = keccak256(abi.encode(b));
        return (ka == kb);
    }

    function _toLower(string memory str) internal pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint i = 0; i < bStr.length; i++) {
            // Uppercase character...
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                // So we add 32 to make it lowercase
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }
    
    function _stringToArray(string memory _string) internal pure returns(string[] memory) {
        string[] memory strArray = new string[](1);
        strArray[0] = _string;
        return(strArray);
    }

}