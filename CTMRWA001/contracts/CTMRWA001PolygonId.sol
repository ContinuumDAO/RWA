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
import {RequestId} from "./interfaces/ICTMRWA001PolygonId.sol";

import {PrimitiveTypeUtils} from '@iden3/contracts/lib/PrimitiveTypeUtils.sol';
import {ICircuitValidator} from '@iden3/contracts/interfaces/ICircuitValidator.sol';
import {EmbeddedZKPVerifier} from '@iden3/contracts/verifiers/EmbeddedZKPVerifier.sol';
import {UniversalVerifier} from '@iden3/contracts/verifiers/UniversalVerifier.sol';

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
    address public verifierAddress;
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

    modifier onlyPolygonId() {
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
        ctmRwa001Map = _map;
        sentryManager = _sentryManager;
        feeManager = _feeManager;

        cIdStr = block.chainid.toString();
    }

    function setVerifierAddress(address _verifierAddress) external onlyGov {
        require(_verifierAddress != address(0), "CTMRWA001PolygonId: Invalid verifier address");
        verifierAddress = _verifierAddress;
        verifier = UniversalVerifier(_verifierAddress);
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

    function setRequestId(RequestId _requestId, uint64 _value) public onlyGov returns(bool) {
        require(_value > 0, "CTMRWA001PolygonId: Request ID cannot be zero");

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
            revert("CTMRWA001PolygonId: Invalid zkProof set Request ID");
        }

        return(true);

    }


    function verifyPerson(
        uint256 _ID,
        string[] memory _chainIdsStr,
        string memory _feeTokenStr
    ) onlyPolygonId public returns(bool) {
        
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
            isValid = isVerifiedBusiness(_msgSender());
            require(isValid, "CTMRWA001PolygonId: Invalid proof of business");
        } else {
            isValid = isVerifiedPerson(_msgSender());
            require(isValid, "CTMRWA001PolygonId: Invalid proof of personhood");
        }

        if (ICTMRWA001Sentry(sentryAddr).accreditedSwitch()) {
            isValid = isAccreditedPerson(_msgSender());
            require(isValid, "CTMRWA001PolygonId: Invalid proof of being an Accredited Investor");
        }

        if (ICTMRWA001Sentry(sentryAddr).age18Switch()) {
            isValid = isOver18(_msgSender());
            require(isValid, "CTMRWA001PolygonId: Invalid proof of being over 18 years of age");
        }

        if (ICTMRWA001Sentry(sentryAddr).countryWLSwitch()) {
            isValid = isVerifiedCountry(_msgSender());
            require(isValid, "CTMRWA001PolygonId: Invalid proof of residency in whitelisted country");
        } else if (ICTMRWA001Sentry(sentryAddr).countryBLSwitch()) {
            isValid = isVerifiedCountry(_msgSender());
            require(!isValid, "CTMRWA001PolygonId: Invalid proof of not residing in blacklisted country");
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

        return(true);

    }

    function submitCountryProof(
        uint256 _ID,
        uint256[] calldata inputs,
        uint256[2] calldata a,
        uint256[2][2] calldata b,
        uint256[2] calldata c
    ) external onlyPolygonId returns(bool) {

        (bool ok, address sentryAddr) = ICTMRWAMap(ctmRwa001Map).getSentryContract(_ID, rwaType, version);
        require(ok, "CTMRWA001PolygonId: Could not find _ID or its sentry address");

        string[] memory countryList = ICTMRWA001Sentry(sentryAddr).countryList();

        uint256[] memory publicInputs = new uint256[](countryList.length + 1);
        publicInputs[0] = countryRequestId;
        for (uint256 i = 0; i < countryList.length; i++) {
            (publicInputs[i + 1],) = strToUint(countryList[i]);
        }
        
        verifier.submitZKPResponse(
            countryRequestId,
            inputs,
            a,
            b,
            c
        );

        return(true);

    }

    function submitProof(
        RequestId _requestIdType,
        uint64 _requestId,
        uint256[] calldata inputs,
        uint256[2] calldata a,
        uint256[2][2] calldata b,
        uint256[2] calldata c
    ) external onlyPolygonId returns(bool) {

        require(_requestId > 0, "CTMRWA001PolygonId: Request ID cannot be zero in submitProof");

        require(
            _requestIdType == RequestId.PERSONHOOD ||
            _requestIdType == RequestId.KYB ||
            _requestIdType == RequestId.OVER18 ||
            _requestIdType == RequestId.ACCREDITED,
            "CTMRWA001PolygonId: Invalid Request ID Type in submitProof"
        );


        verifier.submitZKPResponse(
            _requestId,
            inputs,
            a,
            b,
            c
        );

        return(true);
    }

    function isKycChain() public view returns(bool) {
        return(verifierAddress != address(0));
    }

    function isVerifiedPerson(address _wallet) public view returns (bool) {
        require(personhoodRequestId != 0, "CTMRWA001PolygonId: personhoodRequestId has not been set");
        return verifier.getProofStatus(_wallet, personhoodRequestId).isVerified;
    }

    function isVerifiedBusiness(address _wallet) public view returns (bool) {
        require(businessRequestId != 0, "CTMRWA001PolygonId: businessRequestId has not been set");
        return verifier.getProofStatus(_wallet, businessRequestId).isVerified;
    }

    function isOver18(address _wallet) public view returns (bool) {
        require(over18RequestId != 0, "CTMRWA001PolygonId: over18RequestId has not been set");
        return verifier.getProofStatus(_wallet, over18RequestId).isVerified;
    }

    function isAccreditedPerson(address _wallet) public view returns (bool) {
        require(accreditedRequestId != 0, "CTMRWA001PolygonId: accreditedRequestId has not been set");
        return verifier.getProofStatus(_wallet, accreditedRequestId).isVerified;
    }

    function isVerifiedCountry(address _wallet) public view returns (bool) {
        require(countryRequestId != 0, "CTMRWA001PolygonId: countryRequestId has not been set");
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



    function _c3Fallback(bytes4 _selector,
        bytes calldata _data,
        bytes calldata _reason) internal override returns (bool) {

        lastReason = string(_reason);

        emit LogFallback(_selector, _data, _reason);
        return true;
    }

}


/////////////////////////////////////////////////////////////////////////////////////////////

// Answer from Grok 3

// pragma solidity ^0.8.20;

// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "@iden3/contracts/interfaces/ICircuitValidator.sol";
// import "@iden3/contracts/verifiers/UniversalVerifier.sol";

// contract CountrySelectiveDisclosure is ERC20 {
//     uint64 public constant COUNTRY_REQUEST_ID_SIG = 1;
//     UniversalVerifier public verifier;
    
//     // Fixed-size array of valid country codes (e.g., uint256 representation of "US" = 0x5553)
//     uint256[10] public validCountries; // Max 10 countries for this example
//     uint256 public validCountriesCount;
    
//     mapping(address => bool) public isCountryVerified;
//     uint256 public constant VERIFICATION_REWARD = 100 * 10**18;
    
//     event CountryVerified(address indexed user);
//     event CountryListUpdated();
    
//     modifier onlyVerifiedCountry(address user) {
//         require(isCountryVerified[user] || 
//                 verifier.getProofStatus(user, COUNTRY_REQUEST_ID_SIG).isVerified,
//                 "User's country not verified");
//         _;
//     }
    
//     constructor(
//         address verifierAddress,
//         string memory name_,
//         string memory symbol_
//     ) ERC20(name_, symbol_) {
//         verifier = UniversalVerifier(verifierAddress);
//     }
    
//     // Admin function to set valid countries
//     function setValidCountries(uint256[] calldata countries) external {
//         require(countries.length <= 10, "Too many countries");
//         for (uint256 i = 0; i < countries.length; i++) {
//             validCountries[i] = countries[i];
//         }
//         validCountriesCount = countries.length;
//         emit CountryListUpdated();
//     }
    
//     // Submit ZK proof with country verification
//     function submitCountryProof(
//         uint256[] calldata inputs,
//         uint256[2] calldata a,
//         uint256[2][2] calldata b,
//         uint256[2] calldata c
//     ) external {
//         // Pass valid countries as public inputs
//         uint256[] memory publicInputs = new uint256[](validCountriesCount + 1);
//         publicInputs[0] = COUNTRY_REQUEST_ID_SIG;
//         for (uint256 i = 0; i < validCountriesCount; i++) {
//             publicInputs[i + 1] = validCountries[i];
//         }
        
//         require(
//             verifier.submitZKPResponse(
//                 COUNTRY_REQUEST_ID_SIG,
//                 msg.sender,
//                 inputs,
//                 a,
//                 b,
//                 c
//             ),
//             "Invalid country proof"
//         );
        
//         isCountryVerified[msg.sender] = true;
//         emit CountryVerified(msg.sender);
//     }
    
//     function claimReward() external onlyVerifiedCountry(msg.sender) {
//         require(balanceOf(msg.sender) == 0, "Reward already claimed");
//         _mint(msg.sender, VERIFICATION_REWARD);
//     }
// }


//////////////////////////////////////////////////////////////////////////////////////

// pragma circom 2.0.0;

// template CountryVerifier(maxCountries) {
//     signal input userCountry;      // Private: User's country code from credential
//     signal input validCountries[maxCountries]; // Public: List from contract
//     signal input countryCount;     // Public: Number of valid countries
    
//     signal output isValid;
    
//     // Check if userCountry matches any valid country
//     signal matches[maxCountries];
//     signal sum;
    
//     for (var i = 0; i < maxCountries; i++) {
//         matches[i] <== (i < countryCount) * (userCountry - validCountries[i] === 0);
//         sum += matches[i];
//     }
    
//     isValid <== sum > 0;
// }

// component main {public [validCountries, countryCount]} = CountryVerifier(10);

//////////////////////////////////////////////////////////////////////////////////////////////

// How It Works:
// The contract stores up to 10 country codes as uint256 (e.g., "US" = 0x5553).
// The circuit takes the user's country (private) and the contract's valid countries list (public).
// It checks if the user's country matches any in the list, outputting isValid = 1 if true.
// The specific country remains private.
// Limitations:
// Fixed maximum size (10 in this case).
// Gas cost increases with list size.
// Circuit must be recompiled for different max sizes.