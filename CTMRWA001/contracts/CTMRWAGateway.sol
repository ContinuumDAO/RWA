// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.20;

import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {GovernDapp} from "./routerV2/GovernDapp.sol";



contract CTMRWAGateway is Context, GovernDapp {
    using Strings for *;

    string public cIdStr;

    mapping(string => ChainContract[]) rwaX;

    event SetChainContract(string[] chainIdsStr, string[] contractAddrsStr, string fromContractStr, string fromChainIdStr);
    event LogFallback(bytes4 selector, bytes data, bytes reason);

    //  This holds the chainID and GateKeeper contract address of a single chain
    struct ChainContract {
        string chainIdStr;
        string contractStr;
    }
    //  This array holds ChainContract structs for all chains
    ChainContract[] public chainContract;

    constructor(
        address _gov,
        address _c3callerProxy,
        address _txSender,
        uint256 _dappID
    ) GovernDapp(_gov, _c3callerProxy, _txSender, _dappID) {
        cIdStr = cID().toString();
        _addChainContract(cID(), address(this));
    }

    function _addChainContract(uint256 _chainId, address contractAddr) internal returns(bool) {
        string memory newChainIdStr = _chainId.toString();
        string memory contractStr = _toLower(contractAddr.toHexString());

        for(uint256 i=0; i<chainContract.length; i++) {
            if(stringsEqual(chainContract[i].chainIdStr, newChainIdStr)) {
                return(false); // Cannot change an entry
            }
        }

        chainContract.push(ChainContract(newChainIdStr, contractStr));
        return(true);
    }

    function addChainContract(string memory _newChainIdStr, string memory _contractAddrStr) external returns (bool) {
        string memory newChainIdStr = _toLower(_newChainIdStr);
        string memory contractAddrStr = _toLower(_contractAddrStr);

        for(uint256 i=0; i<chainContract.length; i++) {
            if(stringsEqual(chainContract[i].chainIdStr, newChainIdStr)) {
                return(false); // Cannot change an entry
            }
        }

        chainContract.push(ChainContract(newChainIdStr, contractAddrStr));
        return(true);
    }

    function getChainContract(string memory _chainIdStr) external view returns(string memory) {
        for(uint256 i=0; i<chainContract.length; i++) {
            if(stringsEqual(chainContract[i].chainIdStr, _toLower(_chainIdStr))) {
                return(chainContract[i].contractStr);
            }
        }
        return("");
    }

    function getChainContract(uint256 _pos) public view returns(string memory, string memory) {
        return(chainContract[_pos].chainIdStr, chainContract[_pos].contractStr);
    }

    // Synchronise the CTMRWA001X GateKeeper contract address across other chains. Governance controlled
    function addXChainInfo(
        string memory _tochainIdStr,
        string memory _toContractStr,
        string[] memory _chainIdsStr,
        string[] memory _contractAddrsStr
    ) external onlyGov {
        require(_chainIdsStr.length>0, "CTMRWA001X: Zero length _chainIdsStr");
        require(_chainIdsStr.length == _contractAddrsStr.length, "CTMRWA001X: Length mismatch chainIds and contractAddrs");
        string memory fromContractStr = address(this).toHexString();

        string memory funcCall = "addXChainInfoX(string[],string[],string)";
        bytes memory callData = abi.encodeWithSignature(
            funcCall,
            _chainIdsStr,
            _contractAddrsStr,
            fromContractStr
        );

        c3call(_toContractStr, _tochainIdStr, callData);

    }

    function addXChainInfoX(
        string[] memory _chainIdsStr,
        string[] memory _contractAddrsStr,
        string memory _fromContractStr
    ) external onlyCaller returns(bool){
        uint256 chainId;
        bool ok;

        (, string memory fromChainIdStr,) = context();
        fromChainIdStr = _toLower(fromChainIdStr);

        for(uint256 i=0; i<_chainIdsStr.length; i++) {
            (chainId, ok) = strToUint(_chainIdsStr[i]);
            require(ok && chainId!=0,"CTMRWA001X: Illegal chainId");
            address contractAddr = stringToAddress(_contractAddrsStr[i]);
            if(chainId != cID()) {
                bool success = _addChainContract(chainId, contractAddr);
                if(!success) revert("CTMRWA001X: _addXChainInfoX failed");
            }
        }

        emit SetChainContract(_chainIdsStr, _contractAddrsStr, _fromContractStr, fromChainIdStr);

        return(true);
    }

    function getAttachedRWAX(
        string memory _rwaTypeStr, 
        string memory _chainIdStr
    ) public view returns(bool, string memory) {
        for(uint256 i=0; i<rwaX[_rwaTypeStr].length; i++) {
            if(stringsEqual(rwaX[_rwaTypeStr][i].chainIdStr, _chainIdStr)) {
                return(true, rwaX[_rwaTypeStr][i].contractStr);
            }
        }
        return(false, "0");
    }

    // Keeps a record of RWA contracts on this chain for other chains.
    function attachRWAX (
        string memory _rwaTypeStr, 
        string memory _chainIdStr, 
        string memory _rwaXAddrStr
    ) external onlyGov returns(bool) {
        if(bytes(_rwaXAddrStr).length != 42) return(false);
        string memory rwaXAddrStr = _toLower(_rwaXAddrStr);

        for(uint256 i=0; i<rwaX[_rwaTypeStr].length; i++) {
            if(stringsEqual(rwaX[_rwaTypeStr][i].chainIdStr, _chainIdStr)) {
                rwaX[_rwaTypeStr][i].contractStr = rwaXAddrStr;
                return(true);
            }
        }
        ChainContract memory newAttach = ChainContract(_chainIdStr, rwaXAddrStr);
        rwaX[_rwaTypeStr].push(newAttach);
        return(true);
    }



    function cID() internal view returns (uint256) {
        return block.chainid;
    }

    function strToUint(
        string memory _str
    ) public pure returns (uint256 res, bool err) {
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

    function stringToAddress(string memory str) public pure returns (address) {
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
    ) public pure returns (bool) {
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


    function _c3Fallback(bytes4 _selector,
        bytes calldata _data,
        bytes calldata _reason) internal override returns (bool) {


        emit LogFallback(_selector, _data, _reason);
        return true;
    }

}