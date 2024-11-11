// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.23;

import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {GovernDapp} from "./routerV2/GovernDapp.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


import {IFeeManager, FeeType, IERC20Extended} from "./interfaces/IFeeManager.sol";
import {ICTMRWAGateway} from "./interfaces/ICTMRWAGateway.sol";
import {ICTMRWA001, SlotData, TokenContract, ITokenContract} from "./interfaces/ICTMRWA001.sol";
import {ICTMRWADeployer} from "./interfaces/ICTMRWADeployer.sol";
import {ICTMRWAMap} from "./interfaces/ICTMRWAMap.sol";
import {URICategory, URIType, ICTMRWA001Storage} from "./interfaces/ICTMRWA001Storage.sol";
import {ICTMRWA001XFallback} from "./interfaces/ICTMRWA001XFallback.sol";
import {ICTMRWA001Token} from "./interfaces/ICTMRWA001Token.sol";


contract CTMRWA001X is Context, GovernDapp {
    using Strings for *;
    using SafeERC20 for IERC20;

    address public gateway;
    uint256 rwaType;
    uint256 version;
    address public feeManager;
    address public ctmRwaDeployer;
    address public ctmRwa001Map;
    address public fallbackAddr;
    string public cIDStr;

    SlotData[] emptySlots;
    SlotData[] allSlots;


    mapping(address => address[]) public adminTokens;  // tokenAdmin address => array of CTMRWA001 contracts
    mapping(address => address[]) public ownedCtmRwa001;  // owner address => array of CTMRWA001 contracts

    event CreateNewCTMRWA001(uint256 ID);

    event CreateSlot(uint256 ID, uint256 slot, string fromChainIdStr);

    event TransferToDestX(uint256 ID);


    constructor(
        address _gateway,
        address _feeManager,
        address _gov,
        address _c3callerProxy,
        address _txSender,
        uint256 _dappID
    ) GovernDapp(_gov, _c3callerProxy, _txSender, _dappID) {
        gateway = _gateway;
        rwaType = 1;
        version = 1;
        feeManager = _feeManager;
        cIDStr = cID().toString();
    }

    function changeFeeManager(address _feeManager) external onlyGov {
        feeManager = _feeManager;
    }

    function setGateway(address _gateway) external onlyGov {
        gateway = _gateway;
    }


    function setCtmRwaMap(address _map) external onlyGov {
        ctmRwa001Map = _map;
    }

    function setCtmRwaDeployer(address _deployer) external onlyGov {
        ctmRwaDeployer = _deployer;
    }

    function setFallback(address _fallbackAddr) external onlyGov {
        fallbackAddr = _fallbackAddr;

    }
   

    function deployAllCTMRWA001X(
        bool _includeLocal,
        uint256 _existingID,
        uint256 _rwaType,
        uint256 _version,
        string memory _tokenName, 
        string memory _symbol, 
        uint8 _decimals,
        string memory _baseURI,
        string[] memory _toChainIdsStr,
        string memory _feeTokenStr
    ) public returns(uint256) {
        require(!_includeLocal && _existingID>0 || _includeLocal && _existingID == 0, "CTMRWA001X: Incorrect call logic");
        uint256 nChains = _toChainIdsStr.length;

        string memory ctmRwa001AddrStr;
        address ctmRwa001Addr;
        address currentAdmin;
        uint256 ID;
        string memory tokenName;
        string memory symbol;
        uint8 decimals;
        string memory baseURI;
        

        if(_includeLocal) {
            // generate a new ID
            ID = uint256(keccak256(abi.encode(
                _tokenName,
                _symbol,
                _decimals,
                block.timestamp,
                _msgSender()
            )));

            tokenName = _tokenName;
            symbol = _symbol;
            decimals = _decimals;
            baseURI = _baseURI;

            currentAdmin = _msgSender();
            allSlots = emptySlots;
            ctmRwa001Addr = _deployCTMRWA001Local(
                ID, 
                _rwaType, 
                _version, 
                _tokenName, 
                _symbol, 
                _decimals, 
                baseURI, 
                allSlots, 
                currentAdmin
            );
            

            emit CreateNewCTMRWA001(ID);
        } else {  // a CTMRWA001 token must be deployed already, so use the existing ID
            ID = _existingID;
            (bool ok, address rwa001Addr) = ICTMRWAMap(ctmRwa001Map).getTokenContract(ID, _rwaType, _version);
            require(ok, "CTMRWA001X: ID does not exist on local chain");
            ctmRwa001Addr = rwa001Addr;

            _checkTokenAdmin(ctmRwa001Addr);

            tokenName = ICTMRWA001(ctmRwa001Addr).name();
            symbol = ICTMRWA001(ctmRwa001Addr).symbol();
            decimals = ICTMRWA001(ctmRwa001Addr).valueDecimals();
            baseURI = ICTMRWA001(ctmRwa001Addr).baseURI();

            allSlots = ICTMRWA001(ctmRwa001Addr).getAllSlots();
            for(uint256 i=0; i<allSlots.length; i++) {
                allSlots[i].slotTokens= new uint256[](0);
            }
        }

        ctmRwa001AddrStr = _toLower(ctmRwa001Addr.toHexString());

        _payFee(FeeType.DEPLOY, _feeTokenStr, _toChainIdsStr, _includeLocal);

        for(uint256 i=0; i<nChains; i++){
            _deployCTMRWA001X(
                tokenName, 
                symbol,
                decimals, 
                baseURI,
                _toChainIdsStr[i],
                allSlots,
                ctmRwa001AddrStr
            );
        }

        return(ID);

    }

        
    function _deployCTMRWA001Local(
        uint256 _ID,
        uint256 _rwaType,
        uint256 _version,
        string memory _tokenName, 
        string memory _symbol, 
        uint8 _decimals,
        string memory _baseURI,
        SlotData[] memory _allSlots,
        address _tokenAdmin
    ) internal returns(address) {
        (bool ok,) = ICTMRWAMap(ctmRwa001Map).getTokenContract(_ID, _rwaType, _version);
        require(!ok, "CTMRWA001X: A local contract with this ID already exists");

        bytes memory deployData = abi.encode(
            _ID, 
            _tokenAdmin, 
            _tokenName, 
            _symbol, 
            _decimals, 
            _baseURI,
            _allSlots,
            address(this)
        );

        address ctmRwa001Token = ICTMRWADeployer(ctmRwaDeployer).deploy(
            _ID,
            _rwaType,
            _version,
            deployData
        );

        ICTMRWA001(ctmRwa001Token).changeAdmin(_tokenAdmin);

        ok = ICTMRWA001(ctmRwa001Token).attachId(_ID, _tokenAdmin);
        require(ok, "CTMRWA001X: Could not attachId to new token");

        adminTokens[_tokenAdmin].push(ctmRwa001Token);

        return(ctmRwa001Token);
    }


    // Deploys a new CTMRWA001 instance on a destination chain, 
    // recovering the ID from a required local instance of CTMRWA001, owned by tokenAdmin
    function _deployCTMRWA001X(
        string memory _tokenName, 
        string memory _symbol, 
        uint8 _decimals,
        string memory _baseURI,
        string memory _toChainIdStr,
        SlotData[] memory _allSlots,
        string memory _ctmRwa001AddrStr
    ) internal returns (bool) {
        require(!stringsEqual(_toChainIdStr, cID().toString()), "CTMRWA001X: Not a cross-chain transfer");
        address ctmRwa001Addr = stringToAddress(_ctmRwa001AddrStr);

        (, string memory currentAdminStr) = _checkTokenAdmin(ctmRwa001Addr);

        uint256 ID = ICTMRWA001(ctmRwa001Addr).ID();

        string memory toChainIdStr = _toLower(_toChainIdStr);

        (, string memory toRwaXStr) = _getRWAX(toChainIdStr);

        string memory funcCall = "deployCTMRWA001(string,uint256,uint256,uint256,string,string,uint8,string,SlotData[],string)";
        bytes memory callData = abi.encodeWithSignature(
            funcCall,
            currentAdminStr,
            ID,
            rwaType,
            version,
            _tokenName,
            _symbol,
            _decimals,
            _baseURI,
            _allSlots,
            _ctmRwa001AddrStr
        );

        c3call(toRwaXStr, toChainIdStr, callData);

        return(true);
        
    }

    // Deploys a new CTMRWA001 instance on a destination chain, 
    // with the ID sent from a required local instance of CTMRWA001, owned by tokenAdmin
    function deployCTMRWA001(
        string memory _newAdminStr,
        uint256 _ID,
        uint256 _rwaType,
        uint256 _version,
        string memory _tokenName, 
        string memory _symbol, 
        uint8 _decimals,
        string memory _baseURI,
        SlotData[] memory _allSlots,
        string memory _fromContractStr
    ) external onlyCaller returns(bool) { 

        (bool ok,) = ICTMRWAMap(ctmRwa001Map).getTokenContract(_ID, _rwaType, _version);
        require(!ok, "CTMRWA001X: A local contract with this ID already exists");

        address newAdmin = stringToAddress(_newAdminStr);

        // (, string memory fromChainIdStr,) = context();
        // fromChainIdStr = _toLower(fromChainIdStr);

        address ctmRwa001Token = _deployCTMRWA001Local(
            _ID, 
            _rwaType, 
            _version, 
            _tokenName, 
            _symbol, 
            _decimals, 
            _baseURI,
            _allSlots,
            newAdmin
        );

        emit CreateNewCTMRWA001(_ID);

        return(true);
    }


    function changeAdmin(address _newAdmin, uint256 _ID) public returns(bool) {

        (address ctmRwa001Addr,) = _getTokenAddr(_ID);
        _checkTokenAdmin(ctmRwa001Addr);

        ICTMRWA001(ctmRwa001Addr).changeAdmin(_newAdmin);
        (, address ctmRwa001StorageAddr) = ICTMRWAMap(ctmRwa001Map).getStorageContract(_ID, rwaType, version);
        ICTMRWA001Storage(ctmRwa001StorageAddr).setTokenAdmin(_newAdmin);
        return(true);

    }

    
    // Change the tokenAdmin address of a deployed CTMRWA001 instance on another chain
    function changeAdminCrossChain(
        string memory _newAdminStr,
        string memory _toChainIdStr,
        uint256 _ID,
        string memory _feeTokenStr
    ) public returns(bool) {

        string memory toChainIdStr = _toLower(_toChainIdStr);
        
        (address ctmRwa001Addr, ) = _getTokenAddr(_ID);
        (, string memory toRwaXStr) = _getRWAX(toChainIdStr);
        (, string memory currentAdminStr) = _checkTokenAdmin(ctmRwa001Addr);

        _payFee(FeeType.ADMIN, _feeTokenStr, _stringToArray(toChainIdStr), false);

        string memory funcCall = "adminX(uint256,string,string)";
        bytes memory callData = abi.encodeWithSignature(
            funcCall,
            _ID,
            currentAdminStr,
            _newAdminStr
        );

        c3call(toRwaXStr, toChainIdStr, callData);
        

        return(true);
    }


    function adminX(
        uint256 _ID,
        string memory _oldAdminStr,
        string memory _newAdminStr
    ) external onlyCaller returns(bool) {
        
        (bool ok, address ctmRwa001Addr) = ICTMRWAMap(ctmRwa001Map).getTokenContract(_ID, rwaType, version);
        require(ok, "CTMRWA001X: Destination token contract with this ID does not exist");

        address newAdmin = stringToAddress(_newAdminStr);

        (, string memory fromChainIdStr,) = context();
        fromChainIdStr = _toLower(fromChainIdStr);

        address currentAdmin = ICTMRWA001(ctmRwa001Addr).tokenAdmin();
        address oldAdmin = stringToAddress(_oldAdminStr);
        require(currentAdmin == oldAdmin, "CTMRWA001X: Not admin. Cannot change admin address");

        changeAdmin(newAdmin, _ID );

        return(true);
    
    }


    function mintNewTokenValueLocal(
        address toAddress_,
        uint256 toTokenId_,  // Set to 0 to create a newTokenId
        uint256 slot_,
        uint256 value_,
        uint256 _ID
    ) public returns(uint256) {

        (address ctmRwa001Addr, ) = _getTokenAddr(_ID);
        _checkTokenAdmin(ctmRwa001Addr);

        if(toTokenId_>0) {
            ICTMRWA001(ctmRwa001Addr).mintValueX(toTokenId_, slot_, value_);
            return(toTokenId_);
        } else {
            bool slotExists = ICTMRWA001(ctmRwa001Addr).slotExists(slot_);
            require(slotExists, "CTMRWA001X: Slot does nor exist");
            string memory thisSlotName = ICTMRWA001(ctmRwa001Addr).slotName(slot_);
           
            uint256 newTokenId = ICTMRWA001(ctmRwa001Addr).mintFromX(toAddress_, slot_, thisSlotName, value_);
            address owner = ICTMRWA001(ctmRwa001Addr).ownerOf(newTokenId);
            ownedCtmRwa001[owner].push(ctmRwa001Addr);

            return(newTokenId);
        }

    }


    function createNewSlot(
        uint256 _ID,
        uint256 _slot,
        string memory _slotName,
        string[] memory _toChainIdsStr,
        string memory _feeTokenStr
    ) public returns(bool) {
        require(bytes(_slotName).length <= 128, "CTMRWA001X: Slot name > 128 characters");
        (address ctmRwa001Addr, string memory ctmRwa001AddrStr) = _getTokenAddr(_ID);
        
        _checkTokenAdmin(ctmRwa001Addr);

        string memory toChainIdStr;
        string memory toRwaXStr;
        string memory fromAddressStr;

        _payFee(FeeType.ADMIN, _feeTokenStr, _toChainIdsStr, true);

        uint256 len = _toChainIdsStr.length;

        for(uint256 i=0; i<len; i++) {
            require(!ICTMRWA001(ctmRwa001Addr).slotExists(_slot), "CTMRWA001X: Trying to create a slot that already exists");
            toChainIdStr = _toLower(_toChainIdsStr[i]);
            if(!stringsEqual(cIDStr, toChainIdStr)){
                (fromAddressStr, toRwaXStr) = _getRWAX(toChainIdStr);
                string memory funcCall = "createNewSlotX(uint256,string,uint256,string)";
                bytes memory callData = abi.encodeWithSignature(
                    funcCall,
                    _ID,
                    fromAddressStr,
                    _slot,
                    _slotName
                );

                c3call(toRwaXStr, toChainIdStr, callData);
            }
        }

        ICTMRWA001(ctmRwa001Addr).createSlotX(_slot, _slotName);

        emit CreateSlot(_ID, _slot, cIDStr);
        return(true);
    }

    function createNewSlotX(
        uint256 _ID,
        string memory _fromAddressStr,
        uint256 _slot,
        string memory _slotName
    ) external onlyCaller returns(bool) {
        (bool ok, address ctmRwa001Addr) = ICTMRWAMap(ctmRwa001Map).getTokenContract(_ID, rwaType, version);
        require(ok, "CTMRWA001X: Destination token contract with this ID does not exist");
        require(!ICTMRWA001(ctmRwa001Addr).slotExists(_slot), "CTMRWA001X: Slot already exists. Cannot add");

        (, string memory fromChainIdStr,) = context();

        address fromAddress = stringToAddress(_fromAddressStr);

        address currentAdmin = ICTMRWA001(ctmRwa001Addr).tokenAdmin();
        require(fromAddress == currentAdmin, "CTMRWA001X: Only current admin can add slots");

        ICTMRWA001(ctmRwa001Addr).createSlotX(_slot, _slotName);

        emit CreateSlot(_ID, _slot, fromChainIdStr);

        return(true);

    }

    
    function transferFromX(
        uint256 _fromTokenId,
        string memory _toAddressStr,
        string memory _toChainIdStr,
        uint256 _value,
        uint256 _ID,
        string memory _feeTokenStr
    ) public {
        require(bytes(_toAddressStr).length>0, "CTMRWA001X: Destination address has zero length");

        string memory toChainIdStr = _toLower(_toChainIdStr);

        (address ctmRwa001Addr, string memory ctmRwa001AddrStr) = _getTokenAddr(_ID);
        (string memory fromAddressStr, string memory toRwaXStr) = _getRWAX(toChainIdStr);
        
        ICTMRWA001(ctmRwa001Addr).spendAllowance(_msgSender(), _fromTokenId, _value);

        _payFee(FeeType.TX, _feeTokenStr, _stringToArray(toChainIdStr), false);

        uint256 slot = ICTMRWA001(ctmRwa001Addr).slotOf(_fromTokenId);

        ICTMRWA001(ctmRwa001Addr).burnValueX(_fromTokenId, _value);

        string memory funcCall = "mintX(uint256,string,string,uint256,uint256,uint256,string)";
        
        bytes memory callData = abi.encodeWithSignature(
            funcCall,
            _ID,
            fromAddressStr,
            _toAddressStr,
            _fromTokenId,
            slot,
            _value,
            ctmRwa001AddrStr
        );
        
        c3call(toRwaXStr, toChainIdStr, callData);

    }
    

    function transferFromX(
        string memory _toAddressStr,
        string memory _toChainIdStr,
        uint256 _fromTokenId,
        uint256 _ID,
        string memory _feeTokenStr
    ) public {
        string memory toChainIdStr = _toLower(_toChainIdStr);

        (address ctmRwa001Addr, string memory ctmRwa001AddrStr) = _getTokenAddr(_ID);
        (string memory fromAddressStr, string memory toRwaXStr) = _getRWAX(toChainIdStr);
        
        require(ICTMRWA001(ctmRwa001Addr).isApprovedOrOwner(_msgSender(), _fromTokenId), "CTMRWA001X: transfer caller is not owner nor approved");

        _payFee(FeeType.TX, _feeTokenStr, _stringToArray(toChainIdStr), false);

        (,uint256 value,,uint256 slot,) = ICTMRWA001(ctmRwa001Addr).getTokenInfo(_fromTokenId);

        ICTMRWA001(ctmRwa001Addr).approveFromX(address(0), _fromTokenId);
        ICTMRWA001(ctmRwa001Addr).clearApprovedValues(_fromTokenId);

        ICTMRWA001(ctmRwa001Addr).removeTokenFromOwnerEnumeration(_msgSender(), _fromTokenId);

        string memory funcCall = "mintX(uint256,string,string,uint256,uint256,uint256,string)";
        bytes memory callData = abi.encodeWithSignature(
            funcCall,
            _ID,
            fromAddressStr,
            _toAddressStr,
            _fromTokenId,
            slot,
            value,
            ctmRwa001AddrStr
        );

        c3call(toRwaXStr, toChainIdStr, callData);

    }


    function mintX(
        uint256 _ID,
        string memory _fromAddressStr,
        string memory _toAddressStr,
        uint256 _fromTokenId,
        uint256 _slot,
        uint256 _balance,
        string memory _fromTokenStr
    ) external onlyCaller returns(bool){

        (, string memory fromChainIdStr,) = context();

        address toAddr = stringToAddress(_toAddressStr);

        (bool ok, address ctmRwa001Addr) = ICTMRWAMap(ctmRwa001Map).getTokenContract(_ID, rwaType, version);
        require(ok, "CTMRWA001X: Destination token contract with this ID does not exist"); 

        string memory ctmRwa001AddrStr = _toLower(ctmRwa001Addr.toHexString());

        bool slotExists = ICTMRWA001(ctmRwa001Addr).slotExists(_slot);
        require(slotExists, "CTMRWA001X: Destination slot does not exist");

        string memory thisSlotName = ICTMRWA001(ctmRwa001Addr).slotName(_slot);

        uint256 newTokenId = ICTMRWA001(ctmRwa001Addr).mintFromX(toAddr, _slot, thisSlotName, _balance);

        ownedCtmRwa001[toAddr].push(ctmRwa001Addr);

        emit TransferToDestX(_ID);

        return(true);
    }


    // End of cross chain transfers


    function getAllTokensByAdminAddress(address _admin) public view returns(address[] memory) {
        return(adminTokens[_admin]);
    }

    function getAllTokensByOwnerAddress(address _owner) public view returns(address[] memory) {
        return(ownedCtmRwa001[_owner]);
    }

    function isOwnedToken(address _owner, address _ctmRwa001Addr) public view returns(bool) {
        if(ICTMRWA001(_ctmRwa001Addr).balanceOf(_owner) > 0) return(true);
        else return(false);
    }

    function _getTokenAddr(uint256 _ID) internal view returns(address, string memory) {
        (bool ok, address tokenAddr) = ICTMRWAMap(ctmRwa001Map).getTokenContract(_ID, rwaType, version);
        require(ok, "CTMRWA001X: The requested tokenID does not exist");
        string memory tokenAddrStr = _toLower(tokenAddr.toHexString());

        return(tokenAddr, tokenAddrStr);
    }

    function _getRWAX(string memory _toChainIdStr) internal view returns(string memory, string memory) {
        require(!stringsEqual(_toChainIdStr, cIDStr), "CTMRWA001X: Not a cross-chain tokenAdmin change");

        string memory fromAddressStr = _toLower(_msgSender().toHexString());

        (bool ok, string memory toRwaXStr) = ICTMRWAGateway(gateway).getAttachedRWAX(rwaType, version, _toChainIdStr);
        require(ok, "CTMRWA001X: Target contract address not found");

        return(fromAddressStr, toRwaXStr);
    }

    function _checkTokenAdmin(address _tokenAddr) internal returns(address, string memory) {
        address currentAdmin = ICTMRWA001(_tokenAddr).tokenAdmin();
        string memory currentAdminStr = _toLower(currentAdmin.toHexString());

        require(_msgSender() == currentAdmin, "CTMRWA001X: Only tokenAdmin can change the tokenAdmin");

        return(currentAdmin, currentAdminStr);
    }


    function _payFee(
        FeeType _feeType, 
        string memory _feeTokenStr, 
        string[] memory _toChainIdsStr,
        bool _includeLocal
    ) internal returns(bool) {
        uint256 fee = IFeeManager(feeManager).getXChainFee(_toChainIdsStr, _includeLocal, _feeType, _feeTokenStr);
        
        if(fee>0) {
            address feeToken = stringToAddress(_feeTokenStr);
            uint256 feeWei = fee*10**(IERC20Extended(feeToken).decimals()-2);

            IERC20(feeToken).transferFrom(_msgSender(), address(this), feeWei);
            
            IERC20(feeToken).approve(feeManager, feeWei);
            IFeeManager(feeManager).payFee(feeWei, _feeTokenStr);
        }
        return(true);
    }

    function cID() internal view returns (uint256) {
        return block.chainid;
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

    function _c3Fallback(
        bytes4 _selector,
        bytes calldata _data,
        bytes calldata _reason
    ) internal override returns (bool) {

        bool ok = ICTMRWA001XFallback(fallbackAddr).rwa001XC3Fallback(
            _selector,
            _data,
            _reason
        );

        return ok;
    }

}