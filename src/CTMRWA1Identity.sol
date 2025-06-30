// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.27;

// import "forge-std/console.sol";

import {GovernDapp} from "./routerV2/GovernDapp.sol";

import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {ICTMRWA1, ITokenContract} from "./interfaces/ICTMRWA1.sol";
import {ICTMRWAMap} from "./interfaces/ICTMRWAMap.sol";
import {IFeeManager, FeeType, IERC20Extended} from "./interfaces/IFeeManager.sol";
import {ICTMRWA1Sentry} from "./interfaces/ICTMRWA1Sentry.sol";
import {ICTMRWA1SentryManager} from "./interfaces/ICTMRWA1SentryManager.sol";
import {RequestId} from "./interfaces/ICTMRWA1Identity.sol";

import {PrimitiveTypeUtils} from '@iden3/contracts/lib/PrimitiveTypeUtils.sol';
import {ICircuitValidator} from '@iden3/contracts/interfaces/ICircuitValidator.sol';
import {EmbeddedZKPVerifier} from '@iden3/contracts/verifiers/EmbeddedZKPVerifier.sol';
import {UniversalVerifier} from '@iden3/contracts/verifiers/UniversalVerifier.sol';

interface IPolygonIDVerifier {
    function verifyProof(address user, bytes memory proof) external view returns (bool);
}

interface IZkMeVerify {
    function hasApproved(address cooperator, address user) external view returns (bool);
}


contract CTMRWA1Identity is Context, GovernDapp {
    using Strings for *;
    using SafeERC20 for IERC20;

    uint256 rwaType;
    uint256 version;
    address public ctmRwa1Map;
    address public sentryManager;
    address public verifierAddress;
    address public zkMeVerifierAddress;
    UniversalVerifier public verifier;
    address public feeManager;
    string cIdStr;
    string public lastReason;

    IPolygonIDVerifier public polygonIDVerifier;

    uint64 public personhoodRequestId;
    uint64 public businessRequestId;
    uint64 public over18RequestId;
    uint64 public accreditedRequestId;
    uint64 public countryRequestId;

    modifier onlyIdChain() {
        require(verifierAddress != address(0));
        _;
    }


    event LogFallback(bytes4 selector, bytes data, bytes reason);
    event UserVerified(address indexed user);


    constructor(
        address _gov,
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
        ctmRwa1Map = _map;
        sentryManager = _sentryManager;
        feeManager = _feeManager;

        cIdStr = block.chainid.toString();
    }

    /// @dev Use setVerifierAddress for PrivadoID verifier only
    function setVerifierAddress(address _verifierAddress) external onlyGov {
        require(_verifierAddress != address(0), "CTMRWA1Identity: Invalid verifier address");
        verifierAddress = _verifierAddress;
        verifier = UniversalVerifier(_verifierAddress);
    }

    /// @dev Use setZkMeVerifierAddress for zkMe verifier only
    function setZkMeVerifierAddress(address _verifierAddress) external onlyGov {
        require(_verifierAddress != address(0), "CTMRWA1Identity: Invalid verifier address");
        zkMeVerifierAddress = _verifierAddress;
    }

    function setSentryManager(address _sentryManager) external onlyGov {
        sentryManager = _sentryManager;
    }

    function setFeeManager(address _feeManager) external onlyGov {
        feeManager = _feeManager;
    }

    function setCtmRwaMap(address _map) external onlyGov {
        ctmRwa1Map = _map;
    }

    function setRequestId(RequestId _requestId, uint64 _value) public onlyGov returns(bool) {
        require(_value > 0, "CTMRWA1Identity: Request ID cannot be zero");

        if (_requestId == RequestId.PERSONHOOD) {
            personhoodRequestId = _value;
        } else if (_requestId == RequestId.KYB) {
            businessRequestId = _value;
        } else if (_requestId == RequestId.OVER18) {
            over18RequestId = _value;
        } else if (_requestId == RequestId.ACCREDITED) {
            accreditedRequestId = _value;
        } else if (_requestId == RequestId.COUNTRY) {
            countryRequestId = _value;
        } else {
            revert("CTMRWA1Identity: Invalid zkProof set Request ID");
        }

        return(true);

    }


    function verifyPerson(
        uint256 _ID,
        string[] memory _chainIdsStr,
        string memory _feeTokenStr
    ) onlyIdChain public returns(bool) {

        require(verifierAddress != address(0) || zkMeVerifierAddress != address(0),
            "CTMRWA1Identity: Either PrivadoId or zkMe verifier has to be set"
        );
        
        (bool ok, address sentryAddr) = ICTMRWAMap(ctmRwa1Map).getSentryContract(_ID, rwaType, version);
        require(ok, "CTMRWA1Identity: Could not find _ID or its sentry address");

        require(ICTMRWA1Sentry(sentryAddr).kycSwitch(),
            "CTMRWA1Identity: KYC is not enabled for this CTMRWA1"
        );
        
        require(!ICTMRWA1Sentry(sentryAddr).isAllowableTransfer(_msgSender().toHexString()),
            "CTMRWA1Identity: User is already whitelisted"
        );


        bool isValid;

        if (verifierAddress != address(0)) {
            if (ICTMRWA1Sentry(sentryAddr).kybSwitch()) {
                isValid = isVerifiedBusiness(_msgSender());
                require(isValid, "CTMRWA1Identity: Invalid proof of business");
            } else {
                isValid = isVerifiedPerson(_msgSender());
                require(isValid, "CTMRWA1Identity: Invalid proof of personhood");
            }

            if (ICTMRWA1Sentry(sentryAddr).accreditedSwitch()) {
                isValid = isAccreditedPerson(_msgSender());
                require(isValid, "CTMRWA1Identity: Invalid proof of being an Accredited Investor");
            }

            if (ICTMRWA1Sentry(sentryAddr).age18Switch()) {
                isValid = isOver18(_msgSender());
                require(isValid, "CTMRWA1Identity: Invalid proof of being over 18 years of age");
            }

            if (ICTMRWA1Sentry(sentryAddr).countryWLSwitch()) {
                isValid = isVerifiedCountry(_msgSender());
                require(isValid, "CTMRWA1Identity: Invalid proof of residency in whitelisted country");
            } else if (ICTMRWA1Sentry(sentryAddr).countryBLSwitch()) {
                isValid = isVerifiedCountry(_msgSender());
                require(!isValid, "CTMRWA1Identity: Invalid proof of not residing in blacklisted country");
            }
        } else { // zkMe solution
            (,, address cooperator) = ICTMRWA1Sentry(sentryAddr).getZkMeParams();
            require(cooperator != address(0), "CTMRWA1Identity: zkMe cooperator address has not been set");
            isValid = IZkMeVerify(zkMeVerifierAddress).hasApproved(cooperator, _msgSender());

            require(!isValid, "CTMRWA1Identity: Invalid KYC");
        }


        uint256 fee = _getFee(FeeType.KYC, 1, _chainIdsStr, _feeTokenStr);
        _payFee(fee, _feeTokenStr);

        ICTMRWA1SentryManager(sentryManager).addWhitelist(
            _ID, 
            _stringToArray(_msgSender().toHexString()), 
            _boolToArray(true), 
            _chainIdsStr, 
            _feeTokenStr
        );

        return(true);

    }


    function isKycChain() public view returns(bool) {
        return(verifierAddress != address(0));
    }

    function isVerifiedPerson(address _wallet) public view returns (bool) {
        require(personhoodRequestId != 0, "CTMRWA1Identity: personhoodRequestId has not been set");
        return verifier.getProofStatus(_wallet, personhoodRequestId).isVerified;
    }

    function isVerifiedBusiness(address _wallet) public view returns (bool) {
        require(businessRequestId != 0, "CTMRWA1Identity: businessRequestId has not been set");
        return verifier.getProofStatus(_wallet, businessRequestId).isVerified;
    }

    function isOver18(address _wallet) public view returns (bool) {
        require(over18RequestId != 0, "CTMRWA1Identity: over18RequestId has not been set");
        return verifier.getProofStatus(_wallet, over18RequestId).isVerified;
    }

    // TODO enforce accreditation per country and possibly only for 12 months
    function isAccreditedPerson(address _wallet) public view returns (bool) {
        require(accreditedRequestId != 0, "CTMRWA1Identity: accreditedRequestId has not been set");
        return verifier.getProofStatus(_wallet, accreditedRequestId).isVerified;
    }

    function isVerifiedCountry(address _wallet) public view returns (bool) {
        require(countryRequestId != 0, "CTMRWA1Identity: countryRequestId has not been set");
        return verifier.getProofStatus(_wallet, countryRequestId).isVerified;
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

        bool includeLocal = false;
        
        uint256 fee = IFeeManager(feeManager).getXChainFee(_toChainIdsStr, includeLocal, _feeType, _feeTokenStr);
 
        return(fee * _nItems);
    }

    function stringToAddress(string memory str) internal pure returns (address) {
        bytes memory strBytes = bytes(str);
        require(strBytes.length == 42, "CTMRWA1StorageManager: Invalid address length");
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
