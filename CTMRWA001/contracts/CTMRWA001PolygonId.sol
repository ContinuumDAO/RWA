// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.23;

import "forge-std/console.sol";

import {GovernDapp} from "./routerV2/GovernDapp.sol";

import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {ICTMRWA001, ITokenContract} from "./interfaces/ICTMRWA001.sol";
import {ICTMRWAMap} from "./interfaces/ICTMRWAMap.sol";
import {IFeeManager, FeeType, IERC20Extended} from "./interfaces/IFeeManager.sol";
import {ICTMRWA001Sentry} from "./interfaces/ICTMRWA001Sentry.sol";
import {ICTMRWA001SentryManager} from "./interfaces/ICTMRWA001SentryManager.sol";

interface IPolygonIDVerifier {
    function verifyProof(address user, bytes memory proof) external view returns (bool);
}


contract CTMRWA001PolygonId is Context, GovernDapp {
    using Strings for *;
    using SafeERC20 for IERC20;

    uint256 rwaType;
    uint256 version;
    address public ctmRwa001Map;
    address public sentryManager;
    address public polygonIdServer;
    address public feeManager;
    string cIdStr;
    string public lastReason;

    modifier onlyPolygonId() {
        require(polygonIdServer != address(0));
        _;
    }

    IPolygonIDVerifier public polygonIDVerifier;

    event LogFallback(bytes4 selector, bytes data, bytes reason);
    event UserVerified(address indexed user);


    constructor(
        address _gov,
        address _tokenAddr,
        uint256 _rwaType,
        uint256 _version,
        address _c3callerProxy,
        address _txSender,
        uint256 _dappID,
        address _map,
        address _sentryManager,
        address _feeManager
    ) GovernDapp(_gov, _c3callerProxy, _txSender, _dappID) {
        rwaType = _rwaType;
        version = _version;
        ctmRwa001Map = _map;
        sentryManager = _sentryManager;
        feeManager = _feeManager;

        cIdStr = block.chainid.toString();
    }

    function setPolygonIdServer(address _polygonIdServer) external onlyGov {
        polygonIdServer = _polygonIdServer;
        polygonIDVerifier = IPolygonIDVerifier(polygonIdServer);
    }

    function setSentryManager(address _sentryManager) external onlyGov {
        sentryManager = _sentryManager;
    }

    function setFeeManager(address _feeManager) external onlyGov {
        feeManager = _feeManager;
    }

    function setCtmRwaMap(address _map) external onlyGov {
        ctmRwa001Map = _map;
    }


    function verifyPerson(
        uint256 _ID,
        bytes memory _personhoodProof,
        bytes memory _businessProof,
        bytes memory _accreditedProof,
        bytes memory _over18Proof,
        bytes memory _inCountryWLProof,
        bytes memory _notInCountryBLProof,
        string[] memory _chainIdsStr,
        string memory _feeTokenStr
    ) public returns(bool) {
        require(polygonIdServer != address(0), "CTMRWA001PolygonId: No PolygonID Verifier on this chain. Try another one");
        
        (bool ok, address sentryAddr) = ICTMRWAMap(ctmRwa001Map).getSentryContract(_ID, rwaType, version);
        require(ok, "CTMRWA001PolygonId: Could not find _ID or its sentry address");

        require(ICTMRWA001Sentry(sentryAddr).kycSwitch(),
            "CTMRWA001PolygonId: KYC is not enabled for this CTMRWA001"
        );
        
        require(!ICTMRWA001Sentry(sentryAddr).isAllowableTransfer(_msgSender().toHexString()),
            "CTMRWA001PolygonId: User is already whitelisted"
        );

        bool isValid;

        if (ICTMRWA001Sentry(sentryAddr).kybSwitch()) {
            isValid = polygonIDVerifier.verifyProof(_msgSender(), _businessProof);
            require(isValid, "CTMRWA001PolygonId: Invalid proof of business");
        } else {
            isValid = polygonIDVerifier.verifyProof(_msgSender(), _personhoodProof);
            require(isValid, "CTMRWA001PolygonId: Invalid proof of personhood");
        }

        if (ICTMRWA001Sentry(sentryAddr).accreditedSwitch()) {
            isValid = polygonIDVerifier.verifyProof(_msgSender(), _accreditedProof);
            require(isValid, "CTMRWA001PolygonId: Invalid proof of being an Accredited Investor");
        }

        if (ICTMRWA001Sentry(sentryAddr).age18Switch()) {
            isValid = polygonIDVerifier.verifyProof(_msgSender(), _over18Proof);
            require(isValid, "CTMRWA001PolygonId: Invalid proof of being over 18 years of age");
        }

        if (ICTMRWA001Sentry(sentryAddr).countryWLSwitch()) {
            isValid = polygonIDVerifier.verifyProof(_msgSender(), _inCountryWLProof);
            require(isValid, "CTMRWA001PolygonId: Invalid proof of being in a whitelisted country");
        } else if (ICTMRWA001Sentry(sentryAddr).countryBLSwitch()) {
            isValid = polygonIDVerifier.verifyProof(_msgSender(), _notInCountryBLProof);
            require(isValid, "CTMRWA001PolygonId: Invalid proof of not being in a blacklisted country");
        }

        uint256 fee = _getFee(FeeType.KYC, 1, _chainIdsStr, _feeTokenStr);
        _payFee(fee, _feeTokenStr);

        ICTMRWA001SentryManager(sentryManager).addWhitelist(
            _ID, 
            _stringToArray(_msgSender().toHexString()), 
            _boolToArray(true), 
            _chainIdsStr, 
            _feeTokenStr
        );

    }

    function isKycChain() public view returns(bool) {
        return(polygonIdServer != address(0));
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

        bool includeLocal = true;
        
        uint256 fee = IFeeManager(feeManager).getXChainFee(_toChainIdsStr, includeLocal, _feeType, _feeTokenStr);
 
        return(fee * _nItems);
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

    function _stringToArray(string memory _string) internal pure returns(string[] memory) {
        string[] memory strArray = new string[](1);
        strArray[0] = _string;
        return(strArray);
    }

    function _boolToArray(bool _bool) internal pure returns(bool[] memory) {
        bool[] memory boolArray = new bool[](1);
        boolArray[0] = _bool;
        return(boolArray);
    }


    function _c3Fallback(bytes4 _selector,
        bytes calldata _data,
        bytes calldata _reason) internal override returns (bool) {

        lastReason = string(_reason);

        emit LogFallback(_selector, _data, _reason);
        return true;
    }

}