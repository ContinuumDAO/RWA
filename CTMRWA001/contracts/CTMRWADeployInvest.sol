// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {ICTMRWA001} from "./interfaces/ICTMRWA001.sol";
import {ICTMRWA001X} from "./interfaces/ICTMRWA001X.sol";
import {ICTMRWAMap} from "./interfaces/ICTMRWAMap.sol";
import {ICTMRWA001Dividend} from "./interfaces/ICTMRWA001Dividend.sol";
import {ICTMRWA001Sentry} from "./interfaces/ICTMRWA001Sentry.sol";
import {IFeeManager, FeeType, IERC20Extended} from "./interfaces/IFeeManager.sol";

import {Offering, Holding} from "./interfaces/ICTMRWADeployInvest.sol";


interface IRwaMap {
    function ctmRwaMap() external returns(address);
}


contract CTMRWADeployInvest is Context {
    using Strings for *;

    /// @dev Address of the CTMRWAMap contract
    address public ctmRwaMap;

    /// @dev Address of the CTMRWADeployer contract
    address public ctmRwaDeployer;

    /// @dev The commission rate payable to FeeManager is a number from 0 to 10000 (%0.01)
    uint256 public commissionRate;

    /// @dev Address of the FeeManager contract
    address public feeManager;

    /// @dev String representation of the local chainID
    string cIDStr;

    modifier onlyDeployer {
        require(_msgSender() == ctmRwaDeployer);
        _;
    }


    constructor(
        address _ctmRwaMap,
        address _deployer,
        uint256 _commissionRate,
        address _feeManager
    ) {
        ctmRwaMap = _ctmRwaMap;
        ctmRwaDeployer = _deployer;
        commissionRate = _commissionRate;
        feeManager = _feeManager;

        cIDStr = block.chainid.toString();
    }

    function setDeployerMapFee(
        address _deployer, 
        address _ctmRwaMap, 
        address _feeManager
    ) external onlyDeployer {
        ctmRwaDeployer = _deployer;
        ctmRwaMap = _ctmRwaMap;
        feeManager = _feeManager;
    }

    function setCommissionRate(uint256 _commissionRate) external onlyDeployer {
        commissionRate = _commissionRate;
    }

    function deployInvest(
        uint256 _ID,
        uint256 _rwaType,
        uint256 _version,
        address _feeToken
    ) external onlyDeployer returns(address) {

        _payFee(FeeType.DEPLOYINVEST, _feeToken);

        CTMRWA001InvestWithTimeLock newInvest = new CTMRWA001InvestWithTimeLock(
            _ID,
            _rwaType,
            _version,
            ctmRwaMap,
            commissionRate,
            feeManager
        );

        return(address(newInvest));
    }
       

    /// @dev Pay the fee for deploying the Invest contract
    function _payFee(
        FeeType _feeType, 
        address _feeToken
    ) internal returns(bool) {
        string memory feeTokenStr = _feeToken.toHexString();
        uint256 fee = IFeeManager(feeManager).getXChainFee(_stringToArray(cIDStr), false, _feeType, feeTokenStr);
        
        // TODO Remove hardcoded multiplier 10**2

        if(fee>0) {
            uint256 feeWei = fee*10**(IERC20Extended(_feeToken).decimals()-2);

            IERC20(_feeToken).transferFrom(_msgSender(), address(this), feeWei);
            
            IERC20(_feeToken).approve(feeManager, feeWei);
            IFeeManager(feeManager).payFee(feeWei, feeTokenStr);
        }
        return(true);
    }

     /// @dev Convert an individual string to an array with a single value
    function _stringToArray(string memory _string) internal pure returns(string[] memory) {
        string[] memory strArray = new string[](1);
        strArray[0] = _string;
        return(strArray);
    }

}



contract CTMRWA001InvestWithTimeLock is Context {
    using Strings for *;
    using SafeERC20 for IERC20;

    /// @dev Unique ID of the CTMRWA token contract
    uint256 public ID;

    /// @dev rwaType is the RWA type defining CTMRWA001
    uint256 public rwaType;

    /// @dev version is the single integer version of this RWA type
    uint256 public version;

    /// @dev A list of offerings to investors
    Offering[] public offerings;

    mapping(address => Holding[]) private holdingsByAddress;


    /// @dev The token contract address corresponding to this ID
    address ctmRwaToken;

    /// @dev the decimals of the CTMRWA001
    uint8 decimalsRwa;

    /// @dev The Dividend contract address corresponding to this ID
    address public ctmRwaDividend;

    /// @dev The Sentry contract address corresponding to this ID
    address public ctmRwaSentry;

    /** @dev ctmRwa001X is the single contract on each chain responsible for 
     *   Initiating deployment of an CTMRWA001 and its components
     *   Changing the tokenAdmin
     *   Defining Asset Classes (slots)
     *   Minting new value to slots
     *   Transfering value cross-chain via other ctmRwa001X contracts on other chains
     */
    address public ctmRwa001X; 

    /// @dev Address of the CTMRWAMap contract
    address public ctmRwaMap;

    /// @dev The commission rate payable to FeeManager 0-10000 (0.01%)
    uint256 public commissionRate;

    /// @dev Address of the FeeManager contract
    address public feeManager;

    /// @dev The Token Admin of this CTMRWA
    address public tokenAdmin;

    /// @dev String representation of the local chainID
    string cIDStr;

    modifier onlyTokenAdmin(address _ctmRwaToken) {
        _checkTokenAdmin(_ctmRwaToken);
        _;
    }


    constructor(
        uint256 _ID,
        uint256 _rwaType,
        uint256 _version,
        address _ctmRwaMap,
        uint256 _commissionRate,
        address _feeManager
    ) {
        ID = _ID;
        rwaType = _rwaType;
        version = _version;
        ctmRwaMap = _ctmRwaMap;
        commissionRate = _commissionRate;
        feeManager = _feeManager;
        bool ok;

        (ok, ctmRwaToken) = ICTMRWAMap(ctmRwaMap).getTokenContract(ID, rwaType, version);
        require(ok, "CTMInvest: There is no CTMRWA001 contract backing this ID");

        decimalsRwa = ICTMRWA001(ctmRwaToken).valueDecimals();

        (ok, ctmRwaDividend) = ICTMRWAMap(ctmRwaMap).getDividendContract(ID, rwaType, version);
        require(ok, "CTMInvest: There is no CTMRWA001Dividend contract backing this ID");

        (ok, ctmRwaSentry) = ICTMRWAMap(ctmRwaMap).getSentryContract(ID, rwaType, version);
        require(ok, "CTMInvest: There is no CTMRWA001Sentry contract backing this ID");

        ctmRwa001X = ICTMRWA001(ctmRwaToken).ctmRwa001X();

        cIDStr = block.chainid.toString();

    }


    function createOffering(
        uint256 _tokenId,
        uint256 _price,
        address _currency,
        uint256 _minInvestment,
        uint256 _maxInvestment,
        string memory _regulatorCountry,
        string memory _regulatorAcronym,
        string memory _offeringType,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _lockDuration,
        address _feeToken
    ) public onlyTokenAdmin(ctmRwaToken) {

        require(ICTMRWA001(ctmRwaToken).requireMinted(_tokenId), "CTMInvest: Token does not exist");
        require(bytes(_regulatorCountry).length <= 2, "CTMInvest: not 2 digit country code");
        require(bytes(_offeringType).length <= 128, "CTMInvest: offering Type length > 128");

        uint256 offer = ICTMRWA001(ctmRwaToken).balanceOf(_tokenId);

        require(_minInvestment <= offer*_price/10**decimalsRwa, "CTMInvest: minInvestment too high");
        require(_maxInvestment > _minInvestment, "CTMInvest: minInvestment>maxInvestment");


        _payFee(FeeType.OFFERING, _feeToken);

        ICTMRWA001X(ctmRwa001X).transferWholeTokenX(
            tokenAdmin.toHexString(), 
            address(this).toHexString(), 
            cIDStr, 
            _tokenId, 
            ID, 
            _feeToken.toHexString()
        );

        Holding[] memory holdings;


        offerings.push(Offering (
            _tokenId,
            offer,
            offer,
            _price,
            _currency,
            _minInvestment,
            _maxInvestment,
            0,
            _regulatorCountry,
            _regulatorAcronym,
            _offeringType,
            _startTime,
            _endTime,
            _lockDuration,
            holdings
        ));

    }


    function investInOffering(
        uint256 _indx, 
        uint256 _investment,
        address _feeToken
    ) public returns(uint256) {

        require(block.timestamp >= offerings[_indx].startTime, "CTMInvest: Offer not yet started");
        require(block.timestamp <= offerings[_indx].endTime, "CTMInvest: Offer expired");
        address currency = offerings[_indx].currency;
        require(IERC20(currency).balanceOf(_msgSender()) >= _investment, "CTMInvest: Investor has insufficient balance");
        require(_investment >= offerings[_indx].minInvestment, "CTMInvest: investment too low");
        if(offerings[_indx].maxInvestment > 0) {
            require(_investment <= offerings[_indx].maxInvestment, "CTMInvest: investment too high");
        }
        require(offerings[_indx].balRemaining >= _investment, "CTMInvest: Investment > balance left");

        bool permitted = ICTMRWA001Sentry(ctmRwaSentry).isAllowableTransfer(_msgSender().toHexString());
        require(permitted, "CTMInvest: Not whitelisted");

        uint256 tokenId = offerings[_indx].tokenId;
        string memory feeTokenStr = _feeToken.toHexString();

        _payFee(FeeType.INVEST, _feeToken);

        IERC20(currency).transferFrom(_msgSender(), address(this), _investment);
        offerings[_indx].investment += _investment;

        uint256 value = _investment*10**decimalsRwa/offerings[_indx].price;


        uint256 newTokenId = ICTMRWA001X(ctmRwa001X).transferPartialTokenX(
            tokenId, 
            address(this).toHexString(), 
            cIDStr, 
            value, 
            ID, 
            feeTokenStr
        );

        offerings[_indx].balRemaining -= value;

        Holding memory newHolding = Holding(
            _indx,
            _msgSender(),
            newTokenId,
            block.timestamp + offerings[_indx].lockDuration
        );

        offerings[_indx].holdings.push(newHolding);

        holdingsByAddress[_msgSender()].push(newHolding);

        return newTokenId;
    }


    // function withdraw(address _contractAddr) public onlyTokenAdmin(ctmRwaToken) returns(uint256) {
    //     uint256 bal = IERC20(_contractAddr).balanceOf(address(this));
    //     require(bal > 0, "CTMInvest: Zero balance");

    //     IERC20(_contractAddr).transferFrom(address(this), tokenAdmin, bal);

    //     return bal;
    // }

    function withdrawInvested(uint256 _indx) public onlyTokenAdmin(ctmRwaToken) returns(uint256) {
        require(_indx < offerings.length, "CTMInvest: exceed offerings bounds");

        uint256 investment = offerings[_indx].investment;
        uint256 commission = commissionRate * investment/10000;

        if(investment > 0) {
            address currency = offerings[_indx].currency;
            IERC20(currency).transferFrom(feeManager, _msgSender(), commission);
            offerings[_indx].investment = 0;
            IERC20(currency).transferFrom(address(this), _msgSender(), (investment - commission));
            return investment - commission;
        } else {
            return 0;
        }
    }

    function unlockTokenId(uint256 _myIndx, address _feeToken) public returns(uint256) {
        require(_myIndx < holdingsByAddress[_msgSender()].length, "CTMInvest: exceed bounds");

        Holding memory thisHolding = holdingsByAddress[_msgSender()][_myIndx];

        uint256 tokenId = thisHolding.tokenId;
        address owner = ICTMRWA001(ctmRwaToken).ownerOf(tokenId);

        if(owner == address(this)) {
            require(block.timestamp >= thisHolding.escrowTime, "CTMInvest: tokenId is still locked");

            ICTMRWA001Dividend(ctmRwaDividend).resetDividendByToken(tokenId);

            ICTMRWA001X(ctmRwa001X).transferWholeTokenX( 
                address(this).toHexString(),
                _msgSender().toHexString(),
                cIDStr, 
                tokenId, 
                ID, 
                _feeToken.toHexString()
            );

            return tokenId;
        } else {
            revert("CTMInvest: tokenId already withdrawn");
        }
    }

    function claimDividendInEscrow(uint256 _myIndx) public returns(uint256) {
        require(_myIndx < holdingsByAddress[_msgSender()].length, "CTMInvest: exceed bounds");

        /// @dev caller can only access tokenIds in their holdingsByAddress mapping
        Holding memory thisHolding = holdingsByAddress[_msgSender()][_myIndx];

        uint256 tokenId = thisHolding.tokenId;
        address owner = ICTMRWA001(ctmRwaToken).ownerOf(tokenId);

        uint256 unclaimed = ICTMRWA001Dividend(ctmRwaDividend).dividendByTokenId(tokenId);

        if(owner == address(this)) {
            if(unclaimed == 0) {
                return 0;
            }

            if(ICTMRWA001Dividend(ctmRwaDividend).unclaimedDividend(address(this)) > 0) {
                ICTMRWA001Dividend(ctmRwaDividend).claimDividend();
            }

            address dividendToken = ICTMRWA001Dividend(ctmRwaDividend).dividendToken();

            require(IERC20(dividendToken).balanceOf(address(this)) >= unclaimed, "CTMInvest: insufficient dividend to payout");
            ICTMRWA001Dividend(ctmRwaDividend).resetDividendByToken(tokenId);
            IERC20(dividendToken).transfer(_msgSender(), unclaimed);

            return unclaimed;

        } else {
            revert("CTMInvest: tokenId already withdrawn");
        }
    }


    function offeringCount() public view returns(uint256) {
        return(offerings.length);
    }

    function listOfferings() public view returns(Offering[] memory) {
        return(offerings);
    }

    function listOffering(uint256 _offerIndx) public view returns(Offering memory) {
        require(_offerIndx < offerings.length, "CTMInvest: Offering out of bounds");
        return(offerings[_offerIndx]);
    }

    function escrowHoldingCount(address _holder) public view returns(uint256) {
        return holdingsByAddress[_holder].length;
    }

    function listEscrowHoldings(address _holder) public view returns(Holding[] memory) {
      return holdingsByAddress[_holder];
    }

    function listEscrowHolding(
        address _holder, 
        uint256 _myIndx
    ) public view returns(Holding memory) {
        require(_myIndx < holdingsByAddress[_holder].length, "CTMInvest: exceed bounds");
        Holding memory thisHolding = holdingsByAddress[_holder][_myIndx];

        return(thisHolding);
    }

    function _checkTokenAdmin(address _ctmRwaToken) internal {
        tokenAdmin = ICTMRWA001(_ctmRwaToken).tokenAdmin();
        require(_msgSender() == tokenAdmin, "CTMInvest: Not tokenAdmin");
    }

    /// @dev Pay offering fees
    function _payFee(
        FeeType _feeType,
        address _feeToken
    ) internal returns(bool) {
        string memory feeTokenStr = _feeToken.toHexString();
        uint256 fee = IFeeManager(feeManager).getXChainFee(_stringToArray(cIDStr), false, _feeType, feeTokenStr);
        
        // TODO Remove hardcoded multiplier 10**2

        if(fee>0) {
            uint256 feeWei = fee*10**(IERC20Extended(_feeToken).decimals()-2);

            IERC20(_feeToken).transferFrom(_msgSender(), address(this), feeWei);
            
            IERC20(_feeToken).approve(feeManager, feeWei);
            IFeeManager(feeManager).payFee(feeWei, feeTokenStr);
        }
        return(true);
    }

     /// @dev Convert an individual string to an array with a single value
    function _stringToArray(string memory _string) internal pure returns(string[] memory) {
        string[] memory strArray = new string[](1);
        strArray[0] = _string;
        return(strArray);
    }

}