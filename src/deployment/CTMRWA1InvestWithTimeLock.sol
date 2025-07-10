// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { CTMRWAUtils } from "../CTMRWAUtils.sol";
import { ICTMRWA1 } from "../core/ICTMRWA1.sol";
import { ICTMRWA1X } from "../crosschain/ICTMRWA1X.sol";
import { ICTMRWA1Dividend } from "../dividend/ICTMRWA1Dividend.sol";
import { FeeType, IERC20Extended, IFeeManager } from "../managers/IFeeManager.sol";
import { ICTMRWA1Sentry } from "../sentry/ICTMRWA1Sentry.sol";
import { ICTMRWAMap } from "../shared/ICTMRWAMap.sol";
import { Holding, Offering } from "./ICTMRWADeployInvest.sol";

contract CTMRWA1InvestWithTimeLock is ReentrancyGuard {
    using Strings for *;
    using SafeERC20 for IERC20;
    using CTMRWAUtils for string;

    /// @dev Unique ID of the CTMRWA token contract
    uint256 public ID;

    /// @dev rwaType is the RWA type defining CTMRWA1
    uint256 public immutable RWA_TYPE;

    /// @dev version is the single integer version of this RWA type
    uint256 public immutable VERSION;

    /// @dev A list of offerings to investors
    Offering[] public offerings;

    /// @dev limit the number of Offerings to stop DDoS attacks
    uint256 public constant MAX_OFFERINGS = 100;

    mapping(address => Holding[]) private holdingsByAddress;

    /// @dev The token contract address corresponding to this ID
    address ctmRwaToken;

    /// @dev the decimals of the CTMRWA1
    uint8 decimalsRwa;

    /// @dev The Dividend contract address corresponding to this ID
    address public ctmRwaDividend;

    /// @dev The Sentry contract address corresponding to this ID
    address public ctmRwaSentry;

    /**
     * @dev ctmRwa1X is the single contract on each chain responsible for
     *   Initiating deployment of an CTMRWA1 and its components
     *   Changing the tokenAdmin
     *   Defining Asset Classes (slots)
     *   Minting new value to slots
     *   Transfering value cross-chain via other ctmRwa1X contracts on other chains
     */
    address public ctmRwa1X;

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

    /// @dev Mapping to track pause state for each offering index
    mapping(uint256 => bool) private _isOfferingPaused;

    event CreateOffering(uint256 indexed ID, uint256 indx, uint256 slot, uint256 offer);

    event OfferingPaused(uint256 indexed ID, uint256 indexed indx, address account);
    event OfferingUnpaused(uint256 indexed ID, uint256 indexed indx, address account);

    event InvestInOffering(uint256 indexed ID, uint256 indx, uint256 holdingIndx, uint256 investment);

    event WithdrawFunds(uint256 indexed ID, uint256 indx, uint256 funds);

    event UnlockInvestmentToken(uint256 indexed ID, address holder, uint256 holdingIndx);

    event ClaimDividendInEscrow(uint256 indexed ID, address holder, uint256 unclaimed);

    constructor(
        uint256 _ID,
        uint256 _rwaType,
        uint256 _version,
        address _ctmRwaMap,
        uint256 _commissionRate,
        address _feeManager
    ) {
        ID = _ID;
        RWA_TYPE = _rwaType;
        VERSION = _version;
        ctmRwaMap = _ctmRwaMap;
        commissionRate = _commissionRate;
        feeManager = _feeManager;
        bool ok;

        (ok, ctmRwaToken) = ICTMRWAMap(ctmRwaMap).getTokenContract(ID, _rwaType, _version);
        require(ok, "CTMInvest: There is no CTMRWA1 contract backing this ID");

        decimalsRwa = ICTMRWA1(ctmRwaToken).valueDecimals();

        (ok, ctmRwaDividend) = ICTMRWAMap(ctmRwaMap).getDividendContract(ID, _rwaType, _version);
        require(ok, "CTMInvest: There is no CTMRWA1Dividend contract backing this ID");

        (ok, ctmRwaSentry) = ICTMRWAMap(ctmRwaMap).getSentryContract(ID, _rwaType, _version);
        require(ok, "CTMInvest: There is no CTMRWA1Sentry contract backing this ID");

        ctmRwa1X = ICTMRWA1(ctmRwaToken).ctmRwa1X();

        cIDStr = block.chainid.toString();
    }

    // Pause a specific offering (only tokenAdmin)
    function pauseOffering(uint256 _indx) public onlyTokenAdmin(ctmRwaToken) {
        require(_indx < offerings.length, "CTMInvest: Offering index out of bounds");
        _isOfferingPaused[_indx] = true;
        emit OfferingPaused(ID, _indx, msg.sender);
    }

    /// @dev  Unpause a specific offering (only tokenAdmin)
    function unpauseOffering(uint256 _indx) public onlyTokenAdmin(ctmRwaToken) {
        require(_indx < offerings.length, "CTMInvest: Offering index out of bounds");
        _isOfferingPaused[_indx] = false;
        emit OfferingUnpaused(ID, _indx, msg.sender);
    }

    /// @dev Check if a specific offering is paused
    function isOfferingPaused(uint256 _indx) public view returns (bool) {
        require(_indx < offerings.length, "CTMInvest: Offering index out of bounds");
        return _isOfferingPaused[_indx];
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
        require(ICTMRWA1(ctmRwaToken).requireMinted(_tokenId), "CTMInvest: Token does not exist");
        require(offerings.length < MAX_OFFERINGS, "CTMInvest: Max offerings reached");
        require(bytes(_regulatorCountry).length <= 2, "CTMInvest: not 2 digit country code");
        require(bytes(_offeringType).length <= 128, "CTMInvest: offering Type length > 128");

        uint256 offer = ICTMRWA1(ctmRwaToken).balanceOf(_tokenId);
        uint256 slot = ICTMRWA1(ctmRwaToken).slotOf(_tokenId);

        require(_minInvestment <= offer * _price / 10 ** decimalsRwa, "CTMInvest: minInvestment too high");
        require(_maxInvestment > _minInvestment, "CTMInvest: minInvestment>maxInvestment");

        _payFee(FeeType.OFFERING, _feeToken);

        ICTMRWA1X(ctmRwa1X).transferWholeTokenX(
            tokenAdmin.toHexString(), address(this).toHexString(), cIDStr, _tokenId, ID, _feeToken.toHexString()
        );

        Holding[] memory holdings;

        offerings.push(
            Offering(
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
            )
        );

        uint256 indx = offerings.length - 1;

        _isOfferingPaused[indx] = false;

        emit CreateOffering(ID, indx, slot, offer);
    }

    function investInOffering(uint256 _indx, uint256 _investment, address _feeToken) public returns (uint256) {
        require(_indx < offerings.length, "CTMInvest: Offering index out of bounds");
        require(!_isOfferingPaused[_indx], "CTMInvest: Offering is paused");
        require(block.timestamp >= offerings[_indx].startTime, "CTMInvest: Offer not yet started");
        require(block.timestamp <= offerings[_indx].endTime, "CTMInvest: Offer expired");
        address currency = offerings[_indx].currency;
        require(IERC20(currency).balanceOf(msg.sender) >= _investment, "CTMInvest: Investor has insufficient balance");
        require(_investment >= offerings[_indx].minInvestment, "CTMInvest: investment too low");
        if (offerings[_indx].maxInvestment > 0) {
            require(_investment <= offerings[_indx].maxInvestment, "CTMInvest: investment too high");
        }
        require(offerings[_indx].balRemaining >= _investment, "CTMInvest: Investment > balance left");

        bool permitted = ICTMRWA1Sentry(ctmRwaSentry).isAllowableTransfer(msg.sender.toHexString());
        require(permitted, "CTMInvest: Not whitelisted");

        uint256 tokenId = offerings[_indx].tokenId;
        string memory feeTokenStr = _feeToken.toHexString();

        _payFee(FeeType.INVEST, _feeToken);

        uint256 value = _investment * 10 ** decimalsRwa / offerings[_indx].price;

        offerings[_indx].balRemaining -= value;

        IERC20(currency).transferFrom(msg.sender, address(this), _investment);
        offerings[_indx].investment += _investment;

        uint256 newTokenId = ICTMRWA1X(ctmRwa1X).transferPartialTokenX(
            tokenId, address(this).toHexString(), cIDStr, value, ID, feeTokenStr
        );

        Holding memory newHolding =
            Holding(_indx, msg.sender, newTokenId, block.timestamp + offerings[_indx].lockDuration);

        offerings[_indx].holdings.push(newHolding);
        uint256 holdingIndx = offerings[_indx].holdings.length - 1;

        holdingsByAddress[msg.sender].push(newHolding);

        emit InvestInOffering(ID, _indx, holdingIndx, _investment);

        return newTokenId;
    }

    // function withdraw(address _contractAddr) public onlyTokenAdmin(ctmRwaToken) returns(uint256) {
    //     uint256 bal = IERC20(_contractAddr).balanceOf(address(this));
    //     require(bal > 0, "CTMInvest: Zero balance");

    //     IERC20(_contractAddr).transferFrom(address(this), tokenAdmin, bal);

    //     return bal;
    // }

    function withdrawInvested(uint256 _indx) public onlyTokenAdmin(ctmRwaToken) returns (uint256) {
        require(_indx < offerings.length, "CTMInvest: exceed offerings bounds");

        uint256 investment = offerings[_indx].investment;
        uint256 commission = commissionRate * investment / 10_000;

        require(commission > 0 || commissionRate == 0, "CTMInvest: Commission too low");

        if (investment > 0) {
            address currency = offerings[_indx].currency;
            if (commission > 0) {
                IERC20(currency).transferFrom(feeManager, msg.sender, commission);
            }
            uint256 funds = investment - commission;
            offerings[_indx].investment = 0;
            IERC20(currency).transferFrom(address(this), msg.sender, funds);

            emit WithdrawFunds(ID, _indx, funds);
            return funds;
        } else {
            return 0;
        }
    }

    function unlockTokenId(uint256 _myIndx, address _feeToken) public returns (uint256) {
        require(_myIndx < holdingsByAddress[msg.sender].length, "CTMInvest: exceed bounds");

        Holding memory thisHolding = holdingsByAddress[msg.sender][_myIndx];

        uint256 tokenId = thisHolding.tokenId;
        address owner = ICTMRWA1(ctmRwaToken).ownerOf(tokenId);

        if (owner == address(this)) {
            require(block.timestamp >= thisHolding.escrowTime, "CTMInvest: tokenId is still locked");

            ICTMRWA1Dividend(ctmRwaDividend).resetDividendByToken(tokenId);

            ICTMRWA1X(ctmRwa1X).transferWholeTokenX(
                address(this).toHexString(), msg.sender.toHexString(), cIDStr, tokenId, ID, _feeToken.toHexString()
            );

            emit UnlockInvestmentToken(ID, msg.sender, _myIndx);

            return tokenId;
        } else {
            revert("CTMInvest: tokenId already withdrawn");
        }
    }

    function claimDividendInEscrow(uint256 _myIndx) public returns (uint256) {
        require(_myIndx < holdingsByAddress[msg.sender].length, "CTMInvest: exceed bounds");

        /// @dev caller can only access tokenIds in their holdingsByAddress mapping
        Holding memory thisHolding = holdingsByAddress[msg.sender][_myIndx];

        uint256 tokenId = thisHolding.tokenId;
        address owner = ICTMRWA1(ctmRwaToken).ownerOf(tokenId);

        uint256 unclaimed = ICTMRWA1Dividend(ctmRwaDividend).dividendByTokenId(tokenId);

        if (owner == address(this)) {
            if (unclaimed == 0) {
                return 0;
            }

            if (ICTMRWA1Dividend(ctmRwaDividend).unclaimedDividend(address(this)) > 0) {
                ICTMRWA1Dividend(ctmRwaDividend).claimDividend();
            }

            address dividendToken = ICTMRWA1Dividend(ctmRwaDividend).dividendToken();

            require(
                IERC20(dividendToken).balanceOf(address(this)) >= unclaimed,
                "CTMInvest: insufficient dividend to payout"
            );
            ICTMRWA1Dividend(ctmRwaDividend).resetDividendByToken(tokenId);
            IERC20(dividendToken).transfer(msg.sender, unclaimed);

            emit ClaimDividendInEscrow(ID, msg.sender, unclaimed);

            return unclaimed;
        } else {
            revert("CTMInvest: tokenId already withdrawn");
        }
    }

    function offeringCount() public view returns (uint256) {
        return (offerings.length);
    }

    function listOfferings() public view returns (Offering[] memory) {
        return (offerings);
    }

    function listOffering(uint256 _offerIndx) public view returns (Offering memory) {
        require(_offerIndx < offerings.length, "CTMInvest: Offering out of bounds");
        return (offerings[_offerIndx]);
    }

    function escrowHoldingCount(address _holder) public view returns (uint256) {
        return holdingsByAddress[_holder].length;
    }

    function listEscrowHoldings(address _holder) public view returns (Holding[] memory) {
        return holdingsByAddress[_holder];
    }

    function listEscrowHolding(address _holder, uint256 _myIndx) public view returns (Holding memory) {
        require(_myIndx < holdingsByAddress[_holder].length, "CTMInvest: exceed bounds");
        Holding memory thisHolding = holdingsByAddress[_holder][_myIndx];

        return (thisHolding);
    }

    function _checkTokenAdmin(address _ctmRwaToken) internal {
        tokenAdmin = ICTMRWA1(_ctmRwaToken).tokenAdmin();
        require(msg.sender == tokenAdmin, "CTMInvest: Not tokenAdmin");
    }

    /// @dev Pay offering fees
    function _payFee(FeeType _feeType, address _feeToken) internal returns (bool) {
        string memory feeTokenStr = _feeToken.toHexString();
        uint256 fee = IFeeManager(feeManager).getXChainFee(cIDStr._stringToArray(), false, _feeType, feeTokenStr);

        // TODO Remove hardcoded multiplier 10**2

        if (fee > 0) {
            uint256 feeWei = fee * 10 ** (IERC20Extended(_feeToken).decimals() - 2);

            IERC20(_feeToken).transferFrom(msg.sender, address(this), feeWei);

            IERC20(_feeToken).approve(feeManager, feeWei);
            IFeeManager(feeManager).payFee(feeWei, feeTokenStr);
        }
        return (true);
    }
}
