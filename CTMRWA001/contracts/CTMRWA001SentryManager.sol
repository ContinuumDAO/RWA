// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


import {GovernDapp} from "./routerV2/GovernDapp.sol";

import {IFeeManager, FeeType, IERC20Extended} from "./interfaces/IFeeManager.sol";
import {ICTMRWAGateway} from "./interfaces/ICTMRWAGateway.sol";
import {ICTMRWA001, TokenContract, ITokenContract} from "./interfaces/ICTMRWA001.sol";

import {ICTMRWAMap} from "./interfaces/ICTMRWAMap.sol";
import {ITokenContract} from "./interfaces/ICTMRWA001.sol";
import {ICTMRWA001SentryUtils} from "./interfaces/ICTMRWA001SentryUtils.sol";

import {ICTMRWA001Sentry} from "./interfaces/ICTMRWA001Sentry.sol";

/**
 * @title AssetX Multi-chain Semi-Fungible-Token for Real-World-Assets (RWAs)
 * @author @Selqui ContinuumDAO
 *
 * @notice This contract manages the cross-chain synchronization of all controlled access
 * functionality to RWAs. This controls any whitelist of addresses allowed to trade,
 * adding the requirement for KYC, KYB, over 18 years, Accredited Investor status and geo-fencing.
 *
 * This contract is only deployed ONCE on each chain and manages all CTMRWA001Sentry contract 
 * deployments and functions.
 */

contract CTMRWA001SentryManager is Context, GovernDapp {
    using Strings for *;
    using SafeERC20 for IERC20;

    /// @dev The address of the CTMRWADeployer contract
    address public ctmRwaDeployer;

    /// @dev The address of the CTMRWAMap contract
    address public ctmRwa001Map;

    /// @dev The address of the CTMRWA001SentryUtils contract (adjunct to this contract)
    address public utilsAddr;

    /// @dev rwaType is the RWA type defining CTMRWA001
    uint256 public rwaType;

    /// @dev version is the single integer version of this RWA type
    uint256 public version;

    /// @dev The address of the CTMRWAGateway contract
    address gateway;

    /// @dev The address of the FeeManager contract
    address feeManager;

    /// The address of the CTMRWA001PolygonId contract
    address polygonId;

    /// @dev A string respresentation of this chainID
    string cIdStr;
    

    modifier onlyDeployer {
        require(msg.sender == ctmRwaDeployer, "CTMRWA001SentryManager: onlyDeployer function");
        _;
    }

    constructor(
        address _gov,
        uint256 _rwaType,
        uint256 _version,
        address _c3callerProxy,
        address _txSender,
        uint256 _dappID,
        address _ctmRwaDeployer,
        address _gateway,
        address _feeManager
    ) GovernDapp(_gov, _c3callerProxy, _txSender, _dappID) {
        ctmRwaDeployer = _ctmRwaDeployer;
        rwaType = _rwaType;
        version = _version;
        gateway = _gateway;
        feeManager = _feeManager;
        cIdStr = block.chainid.toString();
    }

    /**
     * @notice Governance can change to a new CTMRWAGateway contract
     * @param _gateway address of the new CTMRWAGateway contract
     */
    function setGateway(address _gateway) external onlyGov {
        gateway = _gateway;
    }

    /**
     * @notice Governance can change to a new FeeManager contract
     * @param _feeManager address of the new FeeManager contract
     */
    function setFeeManager(address _feeManager) external onlyGov {
        feeManager = _feeManager;
    }

    /**
     * @notice Governance can change to a new CTMRWADeployer and CTMRWAERC20Deployer contracts
     * @param _deployer address of the new CTMRWADeployer contract
     */
    function setCtmRwaDeployer(address _deployer) external onlyGov {
        ctmRwaDeployer = _deployer;
    }

    /**
     * @notice Governance can change to a new CTMRWAMap contract
     * @param _map address of the new CTMRWAMap contract
     */
    function setCtmRwaMap(address _map) external onlyGov {
        ctmRwa001Map = _map;
    }

    /**
     * @notice Governance can change to a new CTMRWA001SentryUtils contract
     * @param _utilsAddr address of the new CTMRWA001SentryUtils contract
     */
    function setSentryUtils(address _utilsAddr) external onlyGov {
        utilsAddr = _utilsAddr;
    }

    /**
     * @notice Governance can switch to a new CTMRWA001PolygonId contract
     */
    function setPolygonId(address _polygonId) external onlyGov {
        polygonId = _polygonId;
    }

    /**
     * @dev This function is called by CTMRWADeployer, allowing CTMRWA001SentryUtils to 
     * deploy a CTMRWA001Sentry contract with the same ID as for the CTMRWA001 contract
     */
    function deploySentry(
        uint256 _ID,
        address _tokenAddr,
        uint256 _rwaType,
        uint256 _version,
        address _map
    ) external onlyDeployer returns(address) {

       address sentryAddr = ICTMRWA001SentryUtils(utilsAddr).deploySentry(
            _ID,
            _tokenAddr,
            _rwaType,
            _version,
            _map
        );

        return(sentryAddr);
    }

    /**
     * @notice The tokenAdmin (Issuer) can optionally set conditions for trading the RWA via zkProofs.
     * 
     */
    function setSentryOptions(
        uint256 _ID,
        bool _whitelist,
        bool _kyc,
        bool _kyb,
        bool _over18,
        bool _accredited,
        bool _countryWL,
        bool _countryBL,
        string[] memory _chainIdsStr,
        string memory _feeTokenStr
    ) public {

        (address ctmRwa001Addr, ) = _getTokenAddr(_ID);
        _checkTokenAdmin(ctmRwa001Addr);

        (bool ok, address sentryAddr) = ICTMRWAMap(ctmRwa001Map).getSentryContract(_ID, rwaType, version);
        require(ok, "CTMRWA001SentryManager: Could not find _ID or its sentry address");

        bool sentryOptionsSet = ICTMRWA001Sentry(sentryAddr).sentryOptionsSet();
        require(!sentryOptionsSet, "CTMRWA001SentryManager: Error. setSentryOptions has already been called");


        if (!_whitelist && !_kyc){
            revert("CTMRWA001SentryManager: Must set either whitelist or KYC");
        }

        if (_kyb && !_kyc) {
            revert("CTMRWA001SentryManager: Must set KYC to use KYB");
        }

        if (_over18 && !_kyc) {
            revert("CTMRWA001SentryManager: Must set KYC to use over18 flag");
        }

        if (_accredited && !_kyc) {
            revert("CTMRWA001SentryManager: Must set KYC to use Accredited flag");
        }

        if (_accredited && !_countryWL) {
            revert("CTMRWA001SentryManager: Must set Country white lists to use Accredited");
        }

        if ((_countryWL || _countryBL) && !_kyc) {
            revert("CTMRWA001SentryManager: Must set KYC to use Country black or white lists");
        }

        if (_countryWL && _countryBL) {
            revert("CTMRWA001SentryManager: Cannot set Country blacklist and Country whitelist together");
        }

        uint256 fee = _getFee(FeeType.ADMIN, 1, _chainIdsStr, _feeTokenStr);

        _payFee(fee, _feeTokenStr);

        for(uint256 i=0; i<_chainIdsStr.length; i++) {
            string memory chainIdStr = _toLower(_chainIdsStr[i]);

            if(stringsEqual(chainIdStr, cIdStr)) {
                ICTMRWA001Sentry(sentryAddr).setSentryOptionsLocal(
                    _ID,
                    _whitelist,
                    _kyc,
                    _kyb,
                    _over18,
                    _accredited,
                    _countryWL,
                    _countryBL
                );
            } else {
                (, string memory toRwaSentryStr) = _getSentry(chainIdStr);

                string memory funcCall = "setSentryOptionsX(uint256,bool,bool,bool,bool,bool,bool,bool)";
                bytes memory callData = abi.encodeWithSignature(
                    funcCall,
                    _ID,
                    _whitelist,
                    _kyc,
                    _kyb,
                    _over18,
                    _accredited,
                    _countryWL,
                    _countryBL
                );

                c3call(toRwaSentryStr, chainIdStr, callData);
            }
        }

    }

    // removes the Accredited flag if KYC set
    function goPublic(
        uint256 _ID,
        string[] memory _chainIdsStr,
        string memory _feeTokenStr
    ) public {

        (address ctmRwa001Addr, ) = _getTokenAddr(_ID);
        _checkTokenAdmin(ctmRwa001Addr);

        (bool ok, address sentryAddr) = ICTMRWAMap(ctmRwa001Map).getSentryContract(_ID, rwaType, version);
        require(ok, "CTMRWA001SentryManager: Could not find _ID or its sentry address");

        bool kyc = ICTMRWA001Sentry(sentryAddr).kycSwitch();
        require(kyc, "CTMRWA001SentryManager: KYC was not set, so cannot go public");

        bool accredited = ICTMRWA001Sentry(sentryAddr).accreditedSwitch();
        require(accredited, "CTMRWA001SentryManager: Accredited was not set, so cannot go public");

        bool kyb = ICTMRWA001Sentry(sentryAddr).kybSwitch();
        bool over18 = ICTMRWA001Sentry(sentryAddr).age18Switch();
        bool countryWL = ICTMRWA001Sentry(sentryAddr).countryWLSwitch();
        bool countryBL = ICTMRWA001Sentry(sentryAddr).countryBLSwitch();

        uint256 fee = _getFee(FeeType.ADMIN, 1, _chainIdsStr, _feeTokenStr);

        _payFee(fee, _feeTokenStr);

         for(uint256 i=0; i<_chainIdsStr.length; i++) {
            string memory chainIdStr = _toLower(_chainIdsStr[i]);

            if(stringsEqual(chainIdStr, cIdStr)) {
                ICTMRWA001Sentry(sentryAddr).setSentryOptionsLocal(
                    _ID,
                    false,
                    true,
                    kyb,
                    over18,
                    false,
                    countryWL,
                    countryBL
                );
            } else {
                (, string memory toRwaSentryStr) = _getSentry(chainIdStr);

                string memory funcCall = "setSentryOptionsX(uint256,bool,bool,bool,bool,bool,bool,bool)";
                bytes memory callData = abi.encodeWithSignature(
                    funcCall,
                    _ID,
                    false,
                    true,
                    kyb,
                    over18,
                    false,
                    countryWL,
                    countryBL
                );

                c3call(toRwaSentryStr, chainIdStr, callData);
            }
        }

    }

    function setSentryOptionsX(
        uint256 _ID,
        bool _whitelist,
        bool _kyc,
        bool _kyb,
        bool _over18,
        bool _accredited,
        bool _countryWL,
        bool _countryBL
    ) external onlyCaller returns(bool) {

        (bool ok, address sentryAddr) = ICTMRWAMap(ctmRwa001Map).getSentryContract(_ID, rwaType, version);
        require(ok, "CTMRWA001SentryManager: Could not find _ID or its sentry address");

        ICTMRWA001Sentry(sentryAddr).setSentryOptionsLocal(
            _ID,
            _whitelist,
            _kyc,
            _kyb,
            _over18,
            _accredited,
            _countryWL,
            _countryBL
        );

        return(true);
    }


    function addWhitelist(
        uint256 _ID,
        string[] memory _wallets,
        bool[] memory _choices,
        string[] memory _chainIdsStr,
        string memory _feeTokenStr
    ) public {

        require(_choices.length == _wallets.length, "CTMRWA001SentryManager: addWhitelist parameters lengths not equal");

        (bool ok, address sentryAddr) = ICTMRWAMap(ctmRwa001Map).getSentryContract(_ID, rwaType, version);
        require(ok, "CTMRWA001SentryManager: Could not find _ID or its sentry address");

        (address ctmRwa001Addr, ) = _getTokenAddr(_ID);
        _checkTokenAdmin(ctmRwa001Addr);

        bool whitelistSwitch = ICTMRWA001Sentry(sentryAddr).whitelistSwitch();
        require(whitelistSwitch, "CTMRWA001SentryManager: The whitelistSwitch has not been set");

        uint256 len = _wallets.length;

        if (_msgSender() != polygonId) { // charge a different fee if FeeType.KYC
            uint256 fee = _getFee(FeeType.WHITELIST, len, _chainIdsStr, _feeTokenStr);
            _payFee(fee, _feeTokenStr);
        }


        for(uint256 i=0; i<_chainIdsStr.length; i++) {
            string memory chainIdStr = _toLower(_chainIdsStr[i]);

            if(stringsEqual(chainIdStr, cIdStr)) {
                ICTMRWA001Sentry(sentryAddr).setWhitelistSentry(_ID, _wallets, _choices);
            } else {
                (, string memory toRwaSentryStr) = _getSentry(chainIdStr);

                string memory funcCall = "setWhitelistX(uint256,string[],bool[])";
                bytes memory callData = abi.encodeWithSignature(
                    funcCall,
                    _ID,
                    _wallets,
                    _choices
                );

                c3call(toRwaSentryStr, chainIdStr, callData);
            }
        }
    }

    function setWhitelistX(
        uint256 _ID,
        string[] memory _wallets,
        bool[] memory _choices
    ) external onlyCaller returns(bool) {

        (bool ok, address sentryAddr) = ICTMRWAMap(ctmRwa001Map).getSentryContract(_ID, rwaType, version);
        require(ok, "CTMRWA001SentryManager: Could not find _ID or its sentry address");

        ICTMRWA001Sentry(sentryAddr).setWhitelistSentry(_ID, _wallets, _choices);

        return(true);
    }

    
    function addCountrylist(
        uint256 _ID,
        string[] memory _countries,
        bool[] memory _choices,
        string[] memory _chainIdsStr,
        string memory _feeTokenStr
    ) public {

        require(_choices.length == _countries.length, "CTMRWA001SentryManager: addCountryList parameters lengths not equal");

        (bool ok, address sentryAddr) = ICTMRWAMap(ctmRwa001Map).getSentryContract(_ID, rwaType, version);
        require(ok, "CTMRWA001SentryManager: Could not find _ID or its sentry address");

        (address ctmRwa001Addr, ) = _getTokenAddr(_ID);
        _checkTokenAdmin(ctmRwa001Addr);

        bool countryWLSwitch = ICTMRWA001Sentry(sentryAddr).countryWLSwitch();
        bool countryBLSwitch = ICTMRWA001Sentry(sentryAddr).countryBLSwitch();
        require((countryWLSwitch || countryBLSwitch), "CTMRWA001SentryManager: Neither country whitelist or blacklist has been set");

        uint256 len = _countries.length;

        uint256 fee = _getFee(FeeType.COUNTRY, len, _chainIdsStr, _feeTokenStr);

        _payFee(fee, _feeTokenStr);


        for(uint256 i=0; i<_chainIdsStr.length; i++) {
            string memory chainIdStr = _toLower(_chainIdsStr[i]);

            if(stringsEqual(chainIdStr, cIdStr)) {
                ICTMRWA001Sentry(sentryAddr).setCountryListLocal(_ID, _countries, _choices);
            } else {
                (, string memory toRwaSentryStr) = _getSentry(chainIdStr);

                string memory funcCall = "setCountryListX(uint256,string[],bool[])";
                bytes memory callData = abi.encodeWithSignature(
                    funcCall,
                    _ID,
                    _countries,
                    _choices
                );

                c3call(toRwaSentryStr, chainIdStr, callData);
            }
        }
    }

    function setCountryListX(
        uint256 _ID,
        string[] memory _countries,
        bool[] memory _choices
    ) external onlyCaller returns(bool) {

        (bool ok, address sentryAddr) = ICTMRWAMap(ctmRwa001Map).getSentryContract(_ID, rwaType, version);
        require(ok, "CTMRWA001SentryManager: Could not find _ID or its sentry address");

        ICTMRWA001Sentry(sentryAddr).setCountryListLocal(_ID, _countries, _choices);

        return(true);
    }


    function _payFee(
        uint256 _fee,
        string memory _feeTokenStr
    ) internal returns(bool) {

               
        if(_fee>0) {
            address feeToken = stringToAddress(_feeTokenStr);
            uint256 feeWei = _fee*10**(IERC20Extended(feeToken).decimals()-2);

            IERC20(feeToken).transferFrom(_msgSender(), address(this), feeWei);
            
            IERC20(feeToken).approve(feeManager, feeWei);
            IFeeManager(feeManager).payFee(feeWei, _feeTokenStr);
        }
        return(true);
    }

    function _getFee(
        FeeType _feeType,
        uint256 _nItems,
        string[] memory _toChainIdsStr,
        string memory _feeTokenStr
    ) internal view returns(uint256) {

        bool includeLocal = false; // local chain is already included in _toChainIdsStr
        
        uint256 fee = IFeeManager(feeManager).getXChainFee(_toChainIdsStr, includeLocal, _feeType, _feeTokenStr);
 
        return(fee * _nItems);
    }

    function getLastReason() public view returns(string memory) {
        string memory lastReason = ICTMRWA001SentryUtils(utilsAddr).getLastReason();
        return(lastReason);
    }


    function _getTokenAddr(uint256 _ID) internal view returns(address, string memory) {
        (bool ok, address tokenAddr) = ICTMRWAMap(ctmRwa001Map).getTokenContract(_ID, rwaType, version);
        require(ok, "CTMRWA001StorageManager: The requested tokenID does not exist");
        string memory tokenAddrStr = _toLower(tokenAddr.toHexString());

        return(tokenAddr, tokenAddrStr);
    }

    function _getSentry(string memory _toChainIdStr) internal view returns(string memory, string memory) {
        require(!stringsEqual(_toChainIdStr, cIdStr), "CTMRWA001SentryManager: Not a cross-chain tokenAdmin change");

        string memory fromAddressStr = _toLower(_msgSender().toHexString());

        (bool ok, string memory toSentryStr) = ICTMRWAGateway(gateway).getAttachedSentryManager(rwaType, version, _toChainIdStr);
        require(ok, "CTMRWA001SentryManager: Target contract address not found");

        return(fromAddressStr, toSentryStr);
    }

    function _checkTokenAdmin(address _tokenAddr) internal returns(address, string memory) {
        address currentAdmin = ICTMRWA001(_tokenAddr).tokenAdmin();
        string memory currentAdminStr = _toLower(currentAdmin.toHexString());

        require(
            _msgSender() == currentAdmin ||
            _msgSender() == polygonId,
            "CTMRWA001SentryManager: Not tokenAdmin");

        return(currentAdmin, currentAdminStr);
    }


    function stringToAddress(string memory str) internal pure returns (address) {
        bytes memory strBytes = bytes(str);
        require(strBytes.length == 42, "CTMRWA001StorageManager: Invalid address length");
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


    function _c3Fallback(bytes4 _selector,
        bytes calldata _data,
        bytes calldata _reason) internal override returns (bool) {

        bool ok = ICTMRWA001SentryUtils(utilsAddr).sentryC3Fallback(
            _selector,
            _data,
            _reason
        );
        return ok;
    }


}