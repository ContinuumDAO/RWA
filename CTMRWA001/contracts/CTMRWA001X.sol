// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.20;

import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {GovernDapp} from "./routerV2/GovernDapp.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./FeeManager.sol";

import {ICTMRWAGateway} from "./interfaces/ICTMRWAGateway.sol";
import {ICTMRWA001, TokenContract, ITokenContract} from "./interfaces/ICTMRWA001.sol";
import {ICTMRWADeployer} from "./interfaces/ICTMRWADeployer.sol";
import {ICTMRWA001Token} from "./interfaces/ICTMRWA001Token.sol";

//import "forge-std/console.sol";


contract CTMRWA001X is Context, GovernDapp {
    using Strings for *;
    using SafeERC20 for IERC20;

    address gateway;
    address public feeManager;
    address public ctmRwaDeployer;
    string public cIdStr;


    mapping(address => address[]) public adminTokens;  // tokenAdmin address => array of CTMRWA001 contracts
    mapping(address => address[]) public ownedCtmRwa001;  // owner address => array of CTMRWA001 contracts

    event LogFallback(bytes4 selector, bytes data, bytes reason);

    event CreateNewCTMRWA001(
        address ctmRwa001Token, 
        uint256 ID, 
        address newAdmin, 
        string fromChainIdStr, 
        string fromContractStr
    );

    // event ChangeAdmin(uint256 ID, string currentAdminStr, string newAdminStr, string toChainIdStr);
    event ChangeAdminDest(string currentAdminStr, string newAdminStr, string fromChainIdStr);
    event AddNewChainAndToken(string fromChainIdStr, string fromContractStr, string[] chainIdsStr, string[] ctmRwa001AddrsStr);
    // event LockToken(uint256 ID, address ctmRwa001Addr, uint256 nChains);

    // event TransferFromSourceX(
    //     uint256 ID,
    //     string fromAddressStr,
    //     string toAddressStr,
    //     uint256 fromtokenId,
    //     uint256 toTokenId,
    //     uint256 slot,
    //     uint256 value,
    //     string fromCtmRwa001AddrStr,
    //     string toCtmRwa001AddrStr
    // );

    event TransferToDestX(
        uint256 ID,
        string fromAddressStr,
        string toAddressStr,
        uint256 fromTokenId,
        uint256 toTokenId,
        uint256 slot,
        uint256 value,
        string fromContractStr,
        string ctmRwa001AddrStr
    );

    // event MintIncrementalTokenValue(
    //     uint256 ID,
    //     address minter,
    //     uint256 toTokenId,
    //     uint256 slot,
    //     uint256 value
    // );

    // event MintTokenValueNewId(
    //             uint256 ID,
    //             address minter,
    //             uint256 newTokenId,
    //             uint256 slot,
    //             uint256 value
    // );


    mapping(uint256 => string) public idToContract;
    mapping(string => uint256) public contractToId;

    constructor(
        address _gateway,
        address _feeManager,
        address _gov,
        address _c3callerProxy,
        address _txSender,
        uint256 _dappID
    ) GovernDapp(_gov, _c3callerProxy, _txSender, _dappID) {
        gateway = _gateway;
        feeManager = _feeManager;
        cIdStr = cID().toString();
    }

    function changeFeeManager(address _feeManager) external onlyGov {
        feeManager = _feeManager;
    }

    function setCtmRwaDeployer(address _deployer) external onlyGov {
        ctmRwaDeployer = _deployer;
    }

    
    function _deployCTMRWA001Local(
        uint256 _ID,
        uint256 _rwaType,
        uint256 _version,
        string memory tokenName_, 
        string memory symbol_, 
        uint8 decimals_,
        string memory baseURI_,
        address tokenAdmin
    ) internal returns(address) {
        bool ok = bytes(idToContract[_ID]).length == 0; // only checks local deployments!
        require(ok, "CTMRWA001X: A local contract with this ID already exists");

        bytes memory deployData = abi.encode(_ID, tokenAdmin, tokenName_, symbol_, decimals_, baseURI_, address(this));

        (address ctmRwa001Token, address dividendAddr) = ICTMRWADeployer(ctmRwaDeployer).deploy(
            _rwaType,
            _version,
            deployData
        );

        ok = _attachCTMRWA001ID(_ID, ctmRwa001Token);
        require(ok, "CTMRWA001X: Failed to set token ID");

        ok = ICTMRWA001(ctmRwa001Token).attachDividend(dividendAddr);
        require(ok, "CTMRWA001X: Failed to set the dividend contract address");

        ICTMRWA001(ctmRwa001Token).changeAdminX(tokenAdmin);
        adminTokens[tokenAdmin].push(ctmRwa001Token);

        emit CreateNewCTMRWA001(ctmRwa001Token, _ID, tokenAdmin, cID().toString(), "");

        return(ctmRwa001Token);
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

            ctmRwa001Addr = _deployCTMRWA001Local(ID, _rwaType, _version, _tokenName, _symbol, _decimals, baseURI, _msgSender());
            ICTMRWA001(ctmRwa001Addr).changeAdminX(_msgSender());
            
            currentAdmin = _msgSender();
        } else {  // a CTMRWA001 token must be deployed already, so use the existing ID
            ID = _existingID;
            (bool ok, address rwa001Addr) = this.getAttachedTokenAddress(ID);
            require(ok, "CTMRWA001X: ID does not exist on local chain");
            ctmRwa001Addr = rwa001Addr;
            currentAdmin = ICTMRWA001(ctmRwa001Addr).tokenAdmin();
            require(msg.sender == currentAdmin, "CTMRWA001X: Only tokenAdmin can deploy");

            tokenName = ICTMRWA001(ctmRwa001Addr).name();
            symbol = ICTMRWA001(ctmRwa001Addr).symbol();
            decimals = ICTMRWA001(ctmRwa001Addr).valueDecimals();
            baseURI = ICTMRWA001(ctmRwa001Addr).baseURI();
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
                ctmRwa001AddrStr
            );
        }

        return(ID);

    }

    // Deploys a new CTMRWA001 instance on a destination chain, 
    // recovering the ID from a required local instance of CTMRWA001, owned by tokenAdmin
    function _deployCTMRWA001X(
        string memory _tokenName, 
        string memory _symbol, 
        uint8 _decimals,
        string memory _baseURI,
        string memory _toChainIdStr,
        string memory _ctmRwa001AddrStr
    ) internal returns (bool) {
        require(!stringsEqual(_toChainIdStr, cID().toString()), "CTMRWA001X: Not a cross-chain transfer");
        address ctmRwa001Addr = stringToAddress(_ctmRwa001AddrStr);

        (, string memory currentAdminStr) = _checkTokenAdmin(ctmRwa001Addr);

        uint256 ID = ICTMRWA001(ctmRwa001Addr).ID();
        uint256 rwaType = ICTMRWA001Token(ctmRwa001Addr).getRWAType();
        uint256 version = ICTMRWA001Token(ctmRwa001Addr).getVersion();
        
        string memory gatewayStr = ICTMRWAGateway(gateway).getChainContract(_toChainIdStr);
        require(bytes(gatewayStr).length>0, "CTMRWA001X: Target contract address not found");

        string memory funcCall = "deployCTMRWA001(string,uint256,uint256,uint256,string,string,uint8,string,string)";
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
            _ctmRwa001AddrStr
        );

        c3call(gatewayStr, _toChainIdStr, callData);

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
        string memory _fromContractStr
    ) external onlyCaller returns(bool) {

        address newAdmin = stringToAddress(_newAdminStr);

        (, string memory fromChainIdStr,) = context();
        fromChainIdStr = _toLower(fromChainIdStr);

        bytes memory deployData = abi.encode(_ID, newAdmin, _tokenName, _symbol, _decimals, _baseURI, address(this));

        (address ctmRwa001Token, address dividendAddr) = ICTMRWADeployer(ctmRwaDeployer).deploy(
            _rwaType,
            _version,
            deployData
        );

        bool ok = _attachCTMRWA001ID(_ID, ctmRwa001Token);
        require(ok, "CTMRWA001X: Failed to set token ID");

        ok = ICTMRWA001(ctmRwa001Token).attachDividend(dividendAddr);
        require(ok, "CTMRWA001X: Failed to set the dividend contract address");

        ICTMRWA001(ctmRwa001Token).changeAdminX(newAdmin);
        adminTokens[newAdmin].push(ctmRwa001Token);

        emit CreateNewCTMRWA001(ctmRwa001Token, _ID, newAdmin, fromChainIdStr, _fromContractStr);

        return(true);
    }

    function changeAdmin(address _newAdmin, uint256 _ID) external returns(bool) {

        (address ctmRwa001Addr, string memory ctmRwa001AddrStr) = _getTokenAddr(_ID);
        (, string memory currentAdminStr) = _checkTokenAdmin(ctmRwa001Addr);

        ICTMRWA001(ctmRwa001Addr).changeAdminX(_newAdmin);
        adminTokens[_newAdmin].push(ctmRwa001Addr);

        // emit ChangeAdmin(_ID, currentAdminStr, _newAdmin.toHexString(), "");

        return(true);
    }

    
    // Change the tokenAdmin address of a deployed CTMRWA001 instance on another chain
    function changeAdminCrossChain(
        string memory _newAdminStr,
        string memory _toChainIdStr,
        uint256 _ID,
        string memory _feeTokenStr
    ) public returns(bool) {
        
        (address ctmRwa001Addr, string memory ctmRwa001AddrStr) = _getTokenAddr(_ID);
        (, string memory toRwaXStr, string memory toTokenStr) = _getRWAXAndToken(_toChainIdStr, ctmRwa001Addr);
        (, string memory currentAdminStr) = _checkTokenAdmin(ctmRwa001Addr);

        _payFee(FeeType.ADMIN, _feeTokenStr, _stringToArray(_toChainIdStr), false);

        string memory funcCall = "adminX(string,string,string,string)";
        bytes memory callData = abi.encodeWithSignature(
            funcCall,
            currentAdminStr,
            _newAdminStr,
            ctmRwa001AddrStr,
            toTokenStr
        );

        c3call(toRwaXStr, _toChainIdStr, callData);

        // emit ChangeAdmin(_ID, currentAdminStr, _newAdminStr, _toChainIdStr);

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

        string memory storedContractStr = ICTMRWA001(ctmRwa001Addr).getTokenContract(fromChainIdStr);
        require(stringsEqual(storedContractStr, _fromContractStr), "CTMRWA001X: From an invalid CTMRWA001");

        ICTMRWA001(ctmRwa001Addr).changeAdminX(newAdmin);
        adminTokens[newAdmin].push(ctmRwa001Addr);

        emit ChangeAdminDest(_currentAdminStr, _newAdminStr, fromChainIdStr);

        return(true);
    }

    function lockCTMRWA001(
        uint256 _ID,
        string memory _feeTokenStr
    ) external {

        (address ctmRwa001Addr, string memory ctmRwa001AddrStr) = _getTokenAddr(_ID);
        (address currentAdmin, string memory currentAdminStr) = _checkTokenAdmin(ctmRwa001Addr);
        
        TokenContract[] memory tokenContracts =  ITokenContract(ctmRwa001Addr).tokenContract();

        uint256 nChains = tokenContracts.length;
        string memory toChainIdStr;
        string memory gatewayTargetStr;
        string memory ctmRwa001TokenStr;

        _payFee(FeeType.ADMIN, _feeTokenStr, ITokenContract(ctmRwa001Addr).tokenChainIdStrs(), false);


        for(uint256 i=1; i<nChains; i++) {  // leave local chain to the end, so start at 1
            toChainIdStr = tokenContracts[i].chainIdStr;
            ctmRwa001TokenStr = tokenContracts[i].contractStr;

            (, string memory toRwaXStr, string memory toTokenStr) = _getRWAXAndToken(toChainIdStr, ctmRwa001Addr);

            string memory funcCall = "adminX(string,string,string,string)";
            bytes memory callData = abi.encodeWithSignature(
                funcCall,
                currentAdminStr,
                "0",
                ctmRwa001AddrStr,
                toTokenStr
            );

            c3call(toRwaXStr, toChainIdStr, callData);

        }

        ICTMRWA001(ctmRwa001Addr).changeAdminX(stringToAddress("0"));

        // emit LockToken(_ID, ctmRwa001Addr, nChains);

    }

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


    function getAttachedID(address _ctmRwa001Addr) external view returns(bool, uint256) {
        // for(uint256 i=0; i<ctmRwa001Ids.length; i++) {
        //     if(stringsEqual(ctmRwa001Ids[i].contractStr, _toLower(_ctmRwa001Addr.toHexString()))) {
        //         return(true, ctmRwa001Ids[i].ID);
        //     }
        // }
        // return(false, 0);

        string memory ctmRwa001Addr = _toLower(_ctmRwa001Addr.toHexString());
        uint256 id = contractToId[ctmRwa001Addr];
        return (id != 0, id);
    }

    function getAttachedTokenAddress(uint256 _ID) external view returns(bool, address) {
        // for(uint256 i=0; i<ctmRwa001Ids.length; i++) {
        //     if(ctmRwa001Ids[i].ID == _ID) {
        //         return(true, stringToAddress(ctmRwa001Ids[i].contractStr));
        //     }
        // }
            
        // return(false, address(0));
        
        string memory _contractStr = idToContract[_ID];
        return bytes(_contractStr).length == 0 ? (true, stringToAddress(_contractStr)) : (false, address(0));
    }

    // Keeps a record of token IDs in this contract. Check offline to see if other contracts have it
    function _attachCTMRWA001ID(uint256 _ID, address _ctmRwa001Addr) internal returns(bool) {
        // (bool attached,) = this.getAttachedID(_ctmRwa001Addr);
        // if (!attached) {
        //     bool ok = ICTMRWA001(_ctmRwa001Addr).attachId(_ID, msg.sender);
        //     if(ok) {
        //         CTMRWA001ID memory newAttach = CTMRWA001ID(_ID, _toLower(_ctmRwa001Addr.toHexString()));
        //         ctmRwa001Ids.push(newAttach);
        //         return(true);
        //     } else return(false);
        // } else return(false);

        if (bytes(idToContract[_ID]).length == 0) {
            bool ok = ICTMRWA001(_ctmRwa001Addr).attachId(_ID, msg.sender);
            if (ok) {
                string memory ctmRwa001Addr = _toLower(_ctmRwa001Addr.toHexString());
                idToContract[_ID] = ctmRwa001Addr;
                contractToId[ctmRwa001Addr] = _ID;
                return true;
            }
        }

        return false;
    }

    // Add an array of new chainId/ctmRwa001Addr pairs corresponding to other chain deployments
    function addNewChainIdAndToken(
        string memory _toChainIdStr,
        string[] memory _chainIdsStr,
        string[] memory _otherCtmRwa001AddrsStr,
        uint256 _ID
    ) public {
       
        (address ctmRwa001Addr, string memory ctmRwa001AddrStr) = _getTokenAddr(_ID);
        (string memory fromAddressStr, string memory toRwaXStr, string memory toTokenStr) = _getRWAXAndToken(_toChainIdStr, ctmRwa001Addr);
        (address currentAdmin, string memory currentAdminStr) = _checkTokenAdmin(ctmRwa001Addr);

        string memory funcCall = "addNewChainIdAndTokenX(uint256,string,string[],string[],string,string)";
        bytes memory callData = abi.encodeWithSignature(
            funcCall,
            _ID,
            currentAdminStr,
            _chainIdsStr,
            _otherCtmRwa001AddrsStr,
            ctmRwa001AddrStr,
            toTokenStr
        );

        c3call(toRwaXStr, _toChainIdStr, callData);

    }

    function addNewChainIdAndTokenX(
        uint256 _Id,
        string memory _adminStr,
        string[] memory _chainIdsStr,
        string[] memory _otherCtmRwa001AddrsStr,
        string memory _fromTokenStr,
        string memory _ctmRwa001AddrStr
    ) external onlyCaller returns(bool) {

        (, string memory fromChainIdStr,) = context();
        fromChainIdStr = _toLower(fromChainIdStr);

        address tokenAdmin = stringToAddress(_adminStr);
        address ctmRwa001Addr = stringToAddress(_ctmRwa001AddrStr);

        address currentAdmin = ICTMRWA001(ctmRwa001Addr).tokenAdmin();
        require(tokenAdmin == currentAdmin, "CTMRWA001X: No tokenAdmin access to add chains/contracts");

        (bool ok, uint256 ID) = this.getAttachedID(ctmRwa001Addr);
        require(ok && ID == _Id, "CTMRWA001X: Incorrect or unattached CTMRWA001 contract");

        bool success = ICTMRWA001(ctmRwa001Addr).addXTokenInfo(
            tokenAdmin, 
            _chainIdsStr, 
            _otherCtmRwa001AddrsStr
        );

        if(!success) revert("CTMRWA001X: addNewChainIdAndToken failed");

        emit AddNewChainAndToken(fromChainIdStr, _fromTokenStr, _chainIdsStr, _otherCtmRwa001AddrsStr);

        return(true);
    }

    function mintNewTokenValueLocal(
        address toAddress_,
        uint256 toTokenId_,  // Set to 0 to create a newTokenId
        uint256 slot_,
        uint256 value_,
        uint256 _ID
    ) public returns(uint256) {

        (address ctmRwa001Addr, string memory ctmRwa001AddrStr) = _getTokenAddr(_ID);
        (address currentAdmin, string memory currentAdminStr) = _checkTokenAdmin(ctmRwa001Addr);

        if(toTokenId_>0) {
            ICTMRWA001(ctmRwa001Addr).mintValueX(toTokenId_, slot_, value_);

            // emit MintIncrementalTokenValue(
            //     _ID,
            //     _msgSender(),
            //     toTokenId_,
            //     slot_,
            //     value_
            // );
            return(toTokenId_);
        } else {
            uint256 newTokenId = ICTMRWA001(ctmRwa001Addr).mintFromX(toAddress_, slot_, value_);
            (,,address owner,) = ICTMRWA001(ctmRwa001Addr).getTokenInfo(newTokenId);
            ownedCtmRwa001[owner].push(ctmRwa001Addr);

            // emit MintTokenValueNewId(
            //     _ID,
            //     _msgSender(),
            //     newTokenId,
            //     slot_,
            //     value_
            // );
            return(newTokenId);
        }

    }

    function mintNewTokenValueX(
        string memory _toAddressStr,
        string memory _toChainIdStr,
        uint256 _slot,
        uint256 _value,
        uint256 _ID,
        string memory _feeTokenStr
    ) public {

        (address ctmRwa001Addr, string memory ctmRwa001AddrStr) = _getTokenAddr(_ID);
        (string memory fromAddressStr, string memory toRwaXStr, string memory toTokenStr) = _getRWAXAndToken(_toChainIdStr, ctmRwa001Addr);
        (address currentAdmin, string memory currentAdminStr) = _checkTokenAdmin(ctmRwa001Addr);

        _payFee(FeeType.MINT, _feeTokenStr, _stringToArray(_toChainIdStr), false);

        string memory funcCall = "mintX(uint256,string,string,uint256,uint256,uint256,string,string)";
        bytes memory callData = abi.encodeWithSignature(
            funcCall,
            _ID,
            fromAddressStr,
            _toAddressStr,
            0,  // Not used, since we are not transferring value from a tokenId, but creating new value
            _slot,
            _value,
            ctmRwa001AddrStr,
            toTokenStr
        );

        c3call(toRwaXStr, _toChainIdStr, callData);
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

        (address ctmRwa001Addr, string memory ctmRwa001AddrStr) = _getTokenAddr(_ID);
        (string memory fromAddressStr, string memory toRwaXStr, string memory toTokenStr) = _getRWAXAndToken(_toChainIdStr, ctmRwa001Addr);
        
        ICTMRWA001(ctmRwa001Addr).spendAllowance(msg.sender, _fromTokenId, _value);

        _payFee(FeeType.TX, _feeTokenStr, _stringToArray(_toChainIdStr), false);

        uint256 slot = ICTMRWA001(ctmRwa001Addr).slotOf(_fromTokenId);

        ICTMRWA001(ctmRwa001Addr).burnValueX(_fromTokenId, _value);

        string memory funcCall = "mintX(uint256,string,string,uint256,uint256,uint256,string,string)";
        
        bytes memory callData = abi.encodeWithSignature(
            funcCall,
            _ID,
            fromAddressStr,
            _toAddressStr,
            _fromTokenId,
            slot,
            _value,
            ctmRwa001Addr,
            toTokenStr
        );
        
        c3call(toRwaXStr, _toChainIdStr, callData);

        // emit TransferFromSourceX(
        //     _ID,
        //     fromAddressStr,
        //     _toAddressStr,
        //     _fromTokenId,
        //     0,
        //     slot,
        //     _value,
        //     ctmRwa001AddrStr,
        //     toTokenStr
        // );
    }

    function transferFromX(
        uint256 _fromTokenId,
        string memory _toAddressStr,
        uint256 _toTokenId,
        string memory _toChainIdStr,
        uint256 _value,
        uint256 _ID,
        string memory _feeTokenStr
    ) public {
        
        (address ctmRwa001Addr, string memory ctmRwa001AddrStr) = _getTokenAddr(_ID);
        (string memory fromAddressStr, string memory toRwaXStr, string memory toTokenStr) = _getRWAXAndToken(_toChainIdStr, ctmRwa001Addr);
        
        ICTMRWA001(ctmRwa001Addr).spendAllowance(msg.sender, _fromTokenId, _value);
        require(bytes(_toAddressStr).length>0, "CTMRWA001X: Destination address has zero length");

        _payFee(FeeType.TX, _feeTokenStr, _stringToArray(_toChainIdStr), false);

        uint256 slot = ICTMRWA001(ctmRwa001Addr).slotOf(_fromTokenId);

        ICTMRWA001(ctmRwa001Addr).burnValueX(_fromTokenId, _value);

        string memory funcCall = "mintX(uint256,string,string,uint256,uint256,uint256,uint256,string,string)";
        
        bytes memory callData = abi.encodeWithSignature(
            funcCall,
            _ID,
            fromAddressStr,
            _toAddressStr,
            _fromTokenId,
            _toTokenId,
            slot,
            _value,
            ctmRwa001AddrStr,
            toTokenStr
        );
        
        c3call(toRwaXStr, _toChainIdStr, callData);

        // emit TransferFromSourceX(
        //     _ID,
        //     fromAddressStr,
        //     _toAddressStr,
        //     _fromTokenId,
        //     _toTokenId,
        //     slot,
        //     _value,
        //     ctmRwa001AddrStr,
        //     toRwaXStr
        // );
    }

    function mintX(
        uint256 _ID,
        string memory _fromAddressStr,
        string memory _toAddressStr,
        uint256 _fromTokenId,
        uint256 _toTokenId,
        uint256 _slot,
        uint256 _value,
        string memory _fromContractStr,
        string memory _ctmRwa001AddrStr
    ) external onlyCaller returns(bool){

        address ctmRwa001Addr = stringToAddress(_ctmRwa001AddrStr);

        (, string memory fromChainIdStr,) = context();
        fromChainIdStr = _toLower(fromChainIdStr);

        require(ICTMRWA001(ctmRwa001Addr).ID() == _ID, "CTMRWA001X: Destination CTMRWA001 ID is incorrect");

        string memory storedContractStr = ICTMRWA001(ctmRwa001Addr).getTokenContract(fromChainIdStr);
        require(stringsEqual(storedContractStr, _fromContractStr), "CTMRWA001X: From an invalid CTMRWA001");

        ICTMRWA001(ctmRwa001Addr).mintValueX(_toTokenId, _slot, _value);
        (,,address owner,) = ICTMRWA001(ctmRwa001Addr).getTokenInfo(_toTokenId);
        ownedCtmRwa001[owner].push(ctmRwa001Addr);

        emit TransferToDestX(
            _ID,
            _fromAddressStr,
            _toAddressStr,
            _fromTokenId,
            _toTokenId,
            _slot,
            _value,
            _fromContractStr,
            _ctmRwa001AddrStr
        );

        return(true);
    }

    function transferFromX(
        string memory _toAddressStr,
        string memory _toChainIdStr,
        uint256 _fromTokenId,
        uint256 _ID,
        string memory _feeTokenStr
    ) public {

        (address ctmRwa001Addr, string memory ctmRwa001AddrStr) = _getTokenAddr(_ID);
        (string memory fromAddressStr, string memory toRwaXStr, string memory toTokenStr) = _getRWAXAndToken(_toChainIdStr, ctmRwa001Addr);
        
        require(ICTMRWA001(ctmRwa001Addr).isApprovedOrOwner(_msgSender(), _fromTokenId), "CTMRWA001X: transfer caller is not owner nor approved");

        _payFee(FeeType.TX, _feeTokenStr, _stringToArray(_toChainIdStr), false);

        (,uint256 value,,uint256 slot) = ICTMRWA001(ctmRwa001Addr).getTokenInfo(_fromTokenId);

        ICTMRWA001(ctmRwa001Addr).approveFromX(address(0), _fromTokenId);
        ICTMRWA001(ctmRwa001Addr).clearApprovedValues(_fromTokenId);

        ICTMRWA001(ctmRwa001Addr).removeTokenFromOwnerEnumeration(_msgSender(), _fromTokenId);

        string memory funcCall = "mintX(uint256,string,string,uint256,uint256,uint256,string,string)";
        bytes memory callData = abi.encodeWithSignature(
            funcCall,
            _ID,
            fromAddressStr,
            _toAddressStr,
            _fromTokenId,
            slot,
            value,
            ctmRwa001AddrStr,
            toTokenStr
        );

        c3call(toRwaXStr, _toChainIdStr, callData);

        // emit TransferFromSourceX(
        //     _ID,
        //     fromAddressStr,
        //     _toAddressStr,
        //     _fromTokenId,
        //     0,
        //     slot,
        //     value,
        //     ctmRwa001AddrStr,
        //     toTokenStr
        // );
    }

    function mintX(
        uint256 _ID,
        string memory _fromAddressStr,
        string memory _toAddressStr,
        uint256 _fromTokenId,
        uint256 _slot,
        uint256 _balance,
        string memory _fromContractStr,
        string memory _ctmRwa001AddrStr
    ) external onlyCaller returns(bool){

        (, string memory fromChainIdStr,) = context();
        fromChainIdStr = _toLower(fromChainIdStr);

        address ctmRwa001Addr = stringToAddress(_ctmRwa001AddrStr);
        address toAddr = stringToAddress(_toAddressStr);

        require(ICTMRWA001(ctmRwa001Addr).ID() == _ID, "CTMRWA001X: Destination CTMRWA001 ID is incorrect");

        string memory storedContractStr = ICTMRWA001(ctmRwa001Addr).getTokenContract(fromChainIdStr);
        require(stringsEqual(storedContractStr, _fromContractStr), "CTMRWA001X: From an invalid CTMRWA001");

        uint256 newTokenId = ICTMRWA001(ctmRwa001Addr).mintFromX(toAddr, _slot, _balance);

        emit TransferToDestX(
            _ID,
            _fromAddressStr,
            _toAddressStr,
            _fromTokenId,
            newTokenId,
            _slot,
            _balance,
            _fromContractStr,
            _ctmRwa001AddrStr
        );

        return(true);
    }


    // End of cross chain transfers

    function _getTokenAddr(uint256 _ID) internal view returns(address, string memory) {
        (bool ok, address ctmRwa001Addr) = this.getAttachedTokenAddress(_ID);
        require(ok, "CTMRWA001X: The requested tokenID does not exist");
        string memory ctmRwa001AddrStr = _toLower(ctmRwa001Addr.toHexString());

        return(ctmRwa001Addr, ctmRwa001AddrStr);
    }

    function _getRWAXAndToken(string memory _toChainIdStr, address _tokenAddr) internal view returns(string memory, string memory, string memory) {
        require(!stringsEqual(_toChainIdStr, cIdStr), "CTMRWA001X: Not a cross-chain tokenAdmin change");
        
        string memory fromAddressStr = _msgSender().toHexString();
        string memory toTokenStr = ICTMRWA001(_tokenAddr).getTokenContract(_toChainIdStr);

        (bool ok, string memory toRwaXStr) = ICTMRWAGateway(gateway).getAttachedRWAX("RWA001", _toChainIdStr);
        require(ok, "CTMRWA001X: Target contract address not found");

        return(fromAddressStr, toRwaXStr, toTokenStr);
    }

    function _checkTokenAdmin(address _tokenAddr) internal returns(address, string memory) {
        address currentAdmin = ICTMRWA001(_tokenAddr).tokenAdmin();
        string memory currentAdminStr = currentAdmin.toHexString();

        require(_msgSender() == currentAdmin, "CTMRWA001X: Only tokenAdmin can change the tokenAdmin");

        return(currentAdmin, currentAdminStr);
    }

    function _payFee(
        FeeType _feeType, 
        string memory _feeTokenStr, 
        string[] memory _toChainIdsStr,
        bool _includeLocal
    ) internal returns(bool) {
        uint256 fee = FeeManager(feeManager).getXChainFee(_toChainIdsStr, _includeLocal, _feeType, _feeTokenStr);
        if(fee>0) {
            address feeToken = stringToAddress(_feeTokenStr);
            IERC20(feeToken).transferFrom(_msgSender(), address(this), fee);
            IERC20(feeToken).approve(feeManager, fee);
            FeeManager(feeManager).payFee(fee, _feeTokenStr);
        }
        return(true);
    }

    function _stringToArray(string memory _string) internal pure returns(string[] memory) {
        string[] memory strArray = new string[](1);
        strArray[0] = _string;
        return(strArray);
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