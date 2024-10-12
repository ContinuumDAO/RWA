// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;


import "forge-std/console.sol";


import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {GovernDapp} from "./routerV2/GovernDapp.sol";

import {ICTMRWA001} from "./interfaces/ICTMRWA001.sol";
import {ICTMRWAFactory} from "./interfaces/ICTMRWAFactory.sol";
import {ICTMRWAMap} from "./interfaces/ICTMRWAMap.sol";

interface TokenType {
    function getRWAType() external returns(uint256);
    function getVersion() external returns(uint256);
}


contract CTMRWADeployer is Context, GovernDapp {
    using Strings for *;

    address public rwaX;
    address public ctmRwaMap;

    mapping(uint256 => address[1_000_000_000]) public tokenFactory;
    mapping(uint256 => address[1_000_000_000]) public dividendFactory;
    mapping(uint256 => address[1_000_000_000]) public storageFactory;


    event LogFallback(bytes4 selector, bytes data, bytes reason);

    modifier onlyRwaX {
        require(_msgSender() == rwaX, "CTMRWADeployer: OnlyRwaX function");
        _;
    }

    constructor(
        address _gov,
        address _rwaX,
        address _map,
        address _c3callerProxy,
        address _txSender,
        uint256 _dappID
    ) GovernDapp(_gov, _c3callerProxy, _txSender, _dappID) {
        rwaX = _rwaX;
        ctmRwaMap = _map;
    }

    function deploy(
        uint256 _ID,
        uint256 _rwaType,
        uint256 _version,
        bytes memory deployData
    ) external onlyRwaX returns(address, address, address) {
        address tokenAddr = ICTMRWAFactory(tokenFactory[_rwaType][_version]).deploy(deployData);

        require(TokenType(tokenAddr).getRWAType() == _rwaType, "CTMRWADeployer: Wrong RWA type");
        require(TokenType(tokenAddr).getVersion() == _version, "CTMRWADeployer: Wrong RWA version");
        
        address dividendAddr = deployDividend(_ID, tokenAddr, _rwaType, _version);
        address storageAddr = deployStorage(_ID, _rwaType, _version);

        ICTMRWAMap(ctmRwaMap).attachContracts(_ID, _rwaType, _version, tokenAddr, dividendAddr, storageAddr);

        return(tokenAddr, dividendAddr, storageAddr);
    }

    function deployDividend(
        uint256 _ID,
        address _tokenAddr,
        uint256 _rwaType,
        uint256 _version
    ) internal returns(address) {
        if(dividendFactory[_rwaType][_version] != address(0)) {
            address dividendAddr = ICTMRWAFactory(dividendFactory[_rwaType][_version]).deployDividend(
                _ID, 
                _tokenAddr, 
                _rwaType, 
                _version, 
                ctmRwaMap
            );
            return(dividendAddr);
        }
        else return(address(0));
    }

    function deployStorage(
        uint256 _ID,
        uint256 _rwaType,
        uint256 _version
    ) internal returns(address) {
        if(storageFactory[_rwaType][_version] != address(0)){
            address storageAddr = ICTMRWAFactory(storageFactory[_rwaType][_version]).deployStorage(
                _ID,
                _rwaType, 
                _version, 
                ctmRwaMap
            );
            return(storageAddr);
        }
        else return(address(0));
    }

    function setTokenFactory(uint256 _rwaType, uint256 _version, address _tokenFactory) external onlyGov {
        tokenFactory[_rwaType][_version] = _tokenFactory;
    }

    function setDividendFactory(uint256 _rwaType, uint256 _version, address _dividendFactory) external onlyGov {
        dividendFactory[_rwaType][_version] = _dividendFactory;
    }

    function setStorageFactory(uint256 _rwaType, uint256 _version, address _storageFactory) external onlyGov {
        storageFactory[_rwaType][_version] = _storageFactory;
    }

    function cID() internal view returns (uint256) {
        return block.chainid;
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