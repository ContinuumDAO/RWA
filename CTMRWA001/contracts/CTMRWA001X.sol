// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/Strings.sol";
import {GovernDapp} from "./routerV2/GovernDapp.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import {ICTMRWA001X} from "./ICTMRWA001X.sol";

import "./FeeManager.sol";

contract CTMRWA001X is  GovernDapp {
    using Strings for *;
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public feeManager;
    string public chainIdStr;

    event LogFallback(bytes4 selector, bytes data, bytes reason);

    event SetChainContract(string[] chainIdsStr, string[] contractAddrsStr, string fromContractStr, string fromChainIdStr);

    event ChangeAdminDest(string currentAdminStr, string newAdminStr, string fromChainIdStr);

    event TransferFromSourceX(
        string fromAddressStr,
        string toAddressStr,
        uint256 fromtokenId,
        uint256 toTokenId,
        uint256 slot,
        uint256 value,
        string fromCtmRwa001AddrStr,
        string toCtmRwa001AddrStr
    );

    event TransferToDestX(
        string fromAddressStr,
        string toAddressStr,
        uint256 fromTokenId,
        uint256 toTokenId,
        uint256 slot,
        uint256 value,
        string fromContractStr,
        string ctmRwa001AddrStr
    );

    struct ChainContract {
        string chainIdStr;
        string contractStr;
    }

    ChainContract[] _chainContract;

    constructor(
        address _feeManager,
        address _gov,
        address _c3callerProxy,
        address _txSender,
        uint256 _dappID
    ) GovernDapp(_gov, _c3callerProxy, _txSender, _dappID) {
        feeManager = _feeManager;
        
        chainIdStr = cID().toString();
        _addChainContract(cID(), address(this));
        
    }

 

    function _addChainContract(uint256 _chainId, address contractAddr) internal returns(bool) {
        string memory newChainIdStr = _chainId.toString();
        string memory contractStr = _toLower(contractAddr.toHexString());

        for(uint256 i=0; i<_chainContract.length; i++) {
            if(stringsEqual(_chainContract[i].chainIdStr, newChainIdStr)) {
                return(false); // Cannot change an entry
            }
        }

        _chainContract.push(ChainContract(chainIdStr, contractStr));
        return(true);
    }

    function getChainContract(string memory _chainIdStr) external view returns(string memory) {
        for(uint256 i=0; i<_chainContract.length; i++) {
            if(stringsEqual(_chainContract[i].chainIdStr, _toLower(_chainIdStr))) {
                return(_chainContract[i].contractStr);
            }
        }
        return("");
    }

     // Cross chain functions

    // Synchronise the CTMRWA001X GateKeeper contract address across other chains. Governance controlled
    function addXChainInfo(
        string memory _tochainIdStr,
        string memory _toContractStr,
        string[] memory _chainIdsStr,
        string[] memory _contractAddrsStr
    ) external payable onlyGov {
        require(_chainIdsStr.length>0, "CTMRWA001X: Zero length _chainIdsStr");
        require(_chainIdsStr.length == _contractAddrsStr.length, "CTMRWA001X: Length mismatch chainIds and contractAddrs");
        string memory fromContractStr = address(this).toHexString();

        string memory funcCall = "addXChainInfoX(string,string[],string[],string)";
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

    // Deploys a new CTMRWA001 instance, with one tokenID/slot owned by admin with value _value
    function deployCTMRWA001(
        string memory _adminStr,
        uint256 _value

    ) external onlyCaller returns(bool) {
        // TODO call CREATE2 with contract ABI, then call c3call to return deployed contract address
        return(true);
    }

    // Change the admin address of a deployed CTMRWA001 instance
    function changeAdminCrossChain(
        string memory _newAdminStr,
        string memory toChainIdStr_,
        string memory _ctmRwa001AddrStr,
        address feeToken
    ) public payable virtual returns(bool) {
        address ctmRwa001Addr = stringToAddress(_ctmRwa001AddrStr);
        address currentAdmin = ICTMRWA001X(ctmRwa001Addr).admin();
        require(msg.sender == currentAdmin, "CTMRWA001X: Only admin can change the admin");

        string memory currentAdminStr = currentAdmin.toHexString();
        string memory _toContractStr = ICTMRWA001X(ctmRwa001Addr).getTokenContract(toChainIdStr_);

        string memory targetStr = this.getChainContract(toChainIdStr_);
        require(bytes(targetStr).length>0, "CTMRWA001X: Target contract address not found");

        (uint256 toChainId, bool ok) = strToUint(toChainIdStr_);
        require(ok && toChainId!=0, "CTMRWA001X: Invalid toChainIdStr_");
        uint256 xChainFee = FeeManager(feeManager).getXChainFee(cID(), toChainId, feeToken);
        FeeManager(feeManager).payFee(xChainFee, feeToken);

        string memory funcCall = "adminX(string,string,string,string,string)";
        bytes memory callData = abi.encodeWithSignature(
            funcCall,
            currentAdminStr,
            _newAdminStr,
            _ctmRwa001AddrStr,
            _toContractStr
        );

        c3call(targetStr, toChainIdStr_, callData);

        return(true);
    }


    function adminX(
        string memory _currentAdminStr,
        string memory _newAdminStr,
        string memory _fromContractStr,
        string memory _ctmRwa001AddrStr
    ) external onlyCaller returns(bool) {
        address ctmRwa001Addr = stringToAddress(_ctmRwa001AddrStr);
        address newAdmin = stringToAddress(_newAdminStr);

        (, string memory fromChainIdStr,) = context();
        fromChainIdStr = _toLower(fromChainIdStr);

        string memory storedContractStr = ICTMRWA001X(ctmRwa001Addr).getTokenContract(fromChainIdStr);
        require(stringsEqual(storedContractStr, _fromContractStr), "CTMRWA001X: From an invalid CTMRWA001");

        ICTMRWA001X(ctmRwa001Addr).changeAdminX(newAdmin);

        emit ChangeAdminDest(_currentAdminStr, _newAdminStr, fromChainIdStr);

        return(true);
    }

    // Add a new chainId/ctmRwa001Addr pair corresponding to other chains deployments
    function addNewChainIdAndToken(
        address _admin,
        string memory _ctmRwa001AddrStr,
        string[] memory _chainIdsStr,
        string[] memory _otherCtmRwa001AddrsStr
    ) external onlyCaller returns(bool) {

        address ctmRwa001Addr = stringToAddress(_ctmRwa001AddrStr);

        bool success = ICTMRWA001X(ctmRwa001Addr).addXTokenInfo(
            _admin, 
            _chainIdsStr, 
            _otherCtmRwa001AddrsStr
        );

        if(!success) revert("CTMRWA001X: addNewChainIdAndToken failed");

        return(true);
    }

    
    
    function transferFromX(
        uint256 fromTokenId_,
        string memory toAddressStr_,
        string memory toChainIdStr_,
        uint256 value_,
        string memory _ctmRwa001AddrStr,
        address feeToken
    ) public payable virtual {
        (uint256 toChainId, bool ok) = strToUint(toChainIdStr_);
        require(ok && toChainId!=0, "CTMRWA001:Destination Chain invalid");
        require(toChainId != cID(), "CTMRWA001: Not a cross-chain transfer");
        address ctmRwa001Addr = stringToAddress(_ctmRwa001AddrStr);
        ICTMRWA001X(ctmRwa001Addr).spendAllowance(msg.sender, fromTokenId_, value_);

        require(bytes(toAddressStr_).length>0, "CTMRWA001: Destination address has zero length");
        string memory fromAddressStr = msg.sender.toHexString();

        string memory targetStr = this.getChainContract(toChainIdStr_);
        require(bytes(targetStr).length>0, "CTMRWA001: Target contract address not found");

        uint256 xChainFee = FeeManager(feeManager).getXChainFee(cID(), toChainId, feeToken);
        FeeManager(feeManager).payFee(xChainFee, feeToken);

        (,,,uint256 slot) = ICTMRWA001X(ctmRwa001Addr).getTokenInfo(fromTokenId_);
        string memory _toContractStr = ICTMRWA001X(ctmRwa001Addr).getTokenContract(toChainIdStr_);

        _beforeValueTransferX(fromAddressStr, toAddressStr_, toChainIdStr_, fromTokenId_, fromTokenId_, slot, value_);
    
        ok = ICTMRWA001X(ctmRwa001Addr).burnValueX(fromTokenId_, value_);

        string memory funcCall = "mintX(string,string,string,uint256,uint256,uint256,string,string)";
        
        bytes memory callData = abi.encodeWithSignature(
            funcCall,
            fromAddressStr,
            toAddressStr_,
            fromTokenId_,
            slot,
            value_,
            _ctmRwa001AddrStr,
            _toContractStr
        );
        
        c3call(targetStr, toChainIdStr_, callData);

        emit TransferFromSourceX(
            fromAddressStr,
            toAddressStr_,
            fromTokenId_,
            0,
            slot,
            value_,
            _ctmRwa001AddrStr,
            _toContractStr
        );
    }

    function transferFromX(
        uint256 fromTokenId_,
        string memory toAddressStr_,
        uint256 toTokenId_,
        string memory toChainIdStr_,
        uint256 value_,
        string memory _ctmRwa001AddrStr,
        address feeToken
    ) public payable virtual {
        (uint256 toChainId, bool ok) = strToUint(toChainIdStr_);
        require(ok && toChainId!=0, "CTMRWA001:Destination Chain invalid");
        require(toChainId != cID(), "CTMRWA001: Not a cross-chain transfer");
        address ctmRwa001Addr = stringToAddress(_ctmRwa001AddrStr);
        
        ICTMRWA001X(ctmRwa001Addr).spendAllowance(msg.sender, fromTokenId_, value_);
        require(bytes(toAddressStr_).length>0, "CTMRWA001: Destination address has zero length");
        string memory fromAddressStr = msg.sender.toHexString();

        uint256 xChainFee = FeeManager(feeManager).getXChainFee(cID(), toChainId, feeToken);
        FeeManager(feeManager).payFee(xChainFee, feeToken);

        string memory targetStr = this.getChainContract(toChainIdStr_);
        require(bytes(targetStr).length>0, "CTMRWA001: Target contract address not found");

        (,,,uint256 slot) = ICTMRWA001X(ctmRwa001Addr).getTokenInfo(fromTokenId_);
        string memory _toContractStr = ICTMRWA001X(ctmRwa001Addr).getTokenContract(toChainIdStr_);

        _beforeValueTransferX(fromAddressStr, toAddressStr_, toChainIdStr_, toTokenId_, toTokenId_, slot, value_);

        ok = ICTMRWA001X(ctmRwa001Addr).burnValueX(fromTokenId_, value_);

        string memory funcCall = "mintX(string,string,string,uint256,uint256,uint256,uint256,string,string)";
        
        bytes memory callData = abi.encodeWithSignature(
            funcCall,
            fromAddressStr,
            toAddressStr_,
            fromTokenId_,
            toTokenId_,
            slot,
            value_,
            _ctmRwa001AddrStr,
            _toContractStr
        );
        
        c3call(targetStr, toChainIdStr_, callData);

        emit TransferFromSourceX(
            fromAddressStr,
            toAddressStr_,
            fromTokenId_,
            toTokenId_,
            slot,
            value_,
            _ctmRwa001AddrStr,
            _toContractStr
        );
    }

    function mintX(
        string memory fromAddressStr_,
        string memory toAddressStr_,
        uint256 fromTokenId_,
        uint256 toTokenId_,
        uint256 slot_,
        uint256 value_,
        string memory _fromContractStr,
        string memory _ctmRwa001AddrStr
    ) external onlyCaller returns(bool){

        address ctmRwa001Addr = stringToAddress(_ctmRwa001AddrStr);

        (, string memory fromChainIdStr,) = context();
        fromChainIdStr = _toLower(fromChainIdStr);

        string memory storedContractStr = ICTMRWA001X(ctmRwa001Addr).getTokenContract(fromChainIdStr);
        require(stringsEqual(storedContractStr, _fromContractStr), "CTMRWA001X: From an invalid CTMRWA001");

        ICTMRWA001X(ctmRwa001Addr).mintValueX(toTokenId_, slot_, value_);

        emit TransferToDestX(
            fromAddressStr_,
            toAddressStr_,
            fromTokenId_,
            toTokenId_,
            slot_,
            value_,
            _fromContractStr,
            _ctmRwa001AddrStr
        );

        return(true);
    }

    function transferFromX(
        string memory toAddressStr_,
        string memory toChainIdStr_,
        uint256 fromTokenId_,
        string memory _ctmRwa001AddrStr,
        address feeToken
    ) public payable virtual {
        (uint256 toChainId, bool ok) = strToUint(toChainIdStr_);
        require(ok && toChainId!=0, "CTMRWA001:Destination Chain invalid");
        require(toChainId != cID(), "CTMRWA001: Not a cross-chain transfer");
        address ctmRwa001Addr = stringToAddress(_ctmRwa001AddrStr);
        require(ICTMRWA001X(ctmRwa001Addr).isApprovedOrOwner(msg.sender, fromTokenId_), "CTMRWA001: transfer caller is not owner nor approved");
        string memory fromAddressStr = msg.sender.toHexString();

        uint256 xChainFee = FeeManager(feeManager).getXChainFee(cID(), toChainId, feeToken);
        FeeManager(feeManager).payFee(xChainFee, feeToken);

        string memory targetStr = this.getChainContract(toChainIdStr_);
        require(bytes(targetStr).length>0, "CTMRWA001: Target contract address not found");

        string memory _toContractStr = ICTMRWA001X(ctmRwa001Addr).getTokenContract(toChainIdStr_);

        (,uint256 value,,uint256 slot) = ICTMRWA001X(ctmRwa001Addr).getTokenInfo(fromTokenId_);

        _beforeValueTransferX(fromAddressStr, toAddressStr_, toChainIdStr_, fromTokenId_, fromTokenId_, slot, value);

        ICTMRWA001X(ctmRwa001Addr).approveFromX(address(0), fromTokenId_);
        ICTMRWA001X(ctmRwa001Addr).clearApprovedValues(fromTokenId_);

        ICTMRWA001X(ctmRwa001Addr).removeTokenFromOwnerEnumeration(msg.sender, fromTokenId_);

        string memory funcCall = "mintX(string,string,string,uint256,uint256,uint256,string,string)";
        bytes memory callData = abi.encodeWithSignature(
            funcCall,
            fromAddressStr,
            toAddressStr_,
            fromTokenId_,
            slot,
            value,
            _ctmRwa001AddrStr,
            _toContractStr
        );

        c3call(targetStr, toChainIdStr_, callData);

        emit TransferFromSourceX(
            fromAddressStr,
            toAddressStr_,
            fromTokenId_,
            0,
            slot,
            value,
            _ctmRwa001AddrStr,
            _toContractStr
        );
    }

    function mintX(
        string memory fromAddressStr_,
        string memory toAddressStr_,
        uint256 fromTokenId_,
        uint256 slot_,
        uint256 balance_,
        string memory _fromContractStr,
        string memory _ctmRwa001AddrStr
    ) external onlyCaller returns(bool){

        (, string memory fromChainIdStr,) = context();
        fromChainIdStr = _toLower(fromChainIdStr);

        address ctmRwa001Addr = stringToAddress(_ctmRwa001AddrStr);
        address toAddr = stringToAddress(toAddressStr_);

        string memory storedContractStr = ICTMRWA001X(ctmRwa001Addr).getTokenContract(fromChainIdStr);
        require(stringsEqual(storedContractStr, _fromContractStr), "CTMRWA001X: From an invalid CTMRWA001");

        uint256 newTokenId = ICTMRWA001X(ctmRwa001Addr).mintFromX(toAddr, slot_, balance_);

        emit TransferToDestX(
            fromAddressStr_,
            toAddressStr_,
            fromTokenId_,
            newTokenId,
            slot_,
            balance_,
            _fromContractStr,
            _ctmRwa001AddrStr
        );

        return(true);
    }


    // End of cross chain transfers


    function _beforeValueTransferX(
        string memory fromAddressStr_,
        string memory toAddressStr,
        string memory toChainIdStr_,
        uint256 fromTokenId_,
        uint256 toTokenId_,
        uint256 slot_,
        uint256 value_
    ) internal virtual {}


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
        require(strBytes.length == 42, "CTMRWA001: Invalid address length");
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