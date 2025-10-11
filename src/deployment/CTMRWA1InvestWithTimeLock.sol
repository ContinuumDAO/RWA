// SPDX-License-Identifier: BSL-1.1

pragma solidity 0.8.27;

import { ICTMRWA1 } from "../core/ICTMRWA1.sol";
import { ICTMRWA1X } from "../crosschain/ICTMRWA1X.sol";
import { ICTMRWA1Dividend } from "../dividend/ICTMRWA1Dividend.sol";
import { FeeType, IERC20Extended, IFeeManager } from "../managers/IFeeManager.sol";
import { ICTMRWA1Sentry } from "../sentry/ICTMRWA1Sentry.sol";
import { ICTMRWAMap } from "../shared/ICTMRWAMap.sol";
import { CTMRWAUtils, CTMRWAErrorParam } from "../utils/CTMRWAUtils.sol";
import { Holding, ICTMRWA1InvestWithTimeLock, Offering } from "./ICTMRWA1InvestWithTimeLock.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title AssetX Multi-chain Semi-Fungible-Token for Real-World-Assets (RWAs)
 * @author @Selqui ContinuumDAO
 *
 * This is a contract to allow an Issuer (tokenAdmin) to raise finance from investors.
 * It can be deployed once on each chain that the RWA token is deployed to.
 * The Issuer can create Offerings with start and end dates, min and max amounts to invest
 * and with a lock up escrow period.
 * The investors can still claim rewards, sent to them by the Issuer, whilst their investments are locked up.
 * Once the lockup period is over, the investors can withdraw their tokenIds
 *
 * Issuers can create multiple simultaneous Offerings.
 *
 */
contract CTMRWA1InvestWithTimeLock is ICTMRWA1InvestWithTimeLock, ReentrancyGuard {
    using Strings for *;
    using SafeERC20 for IERC20;
    using CTMRWAUtils for string;

    /// @dev Unique ID of the CTMRWA token contract
    uint256 public ID;

    /// @dev rwaType is the RWA type defining CTMRWA1
    uint256 public constant RWA_TYPE = 1;

    /// @dev version is the single integer version of this RWA type
    uint256 public constant VERSION = 1;

    /// @dev A list of offerings to investors
    Offering[] public offerings;

    /// @dev limit the number of Offerings to stop DDoS attacks
    uint256 public constant MAX_OFFERINGS = 100;

    /// @dev Mapping of address to holdings
    mapping(address => Holding[]) private holdingsByAddress;

    /// @dev The token contract address corresponding to this ID
    address ctmRwaToken;

    /// @dev the decimals of the CTMRWA1
    uint8 decimalsRwa;

    /// @dev The Dividend contract address corresponding to this ID
    address public ctmRwaDividend;

    /// @dev The Sentry contract address corresponding to this ID
    address public ctmRwaSentry;

    /// @dev The CTMRWA1X contract address corresponding to this ID
    address public ctmRwa1X;

    /// @dev CTMRWAErrorParam of the CTMRWAMap contract
    address public ctmRwaMap;

    /// @dev The commission rate payable to FeeManager 0-10000 (0.01%)
    uint256 public commissionRate;

    /// @dev CTMRWAErrorParam of the FeeManager contract
    address public feeManager;

    /// @dev The Token Admin of this CTMRWA
    address public tokenAdmin;

    /// @dev String representation of the local chainID
    string cIdStr;

    /// @dev Arrays of tokenIds and owners in escrow
    uint256[] private tokensInEscrow;
    address[] private ownersInEscrow;

    modifier onlyTokenAdmin(address _ctmRwaToken) {
        _checkTokenAdmin(_ctmRwaToken);
        _;
    }

    /// @dev Mapping to track pause state for each offering index
    mapping(uint256 => bool) private _isOfferingPaused;



    constructor(uint256 _ID, address _ctmRwaMap, uint256 _commissionRate, address _feeManager) {
        ID = _ID;
        ctmRwaMap = _ctmRwaMap;
        commissionRate = _commissionRate;
        feeManager = _feeManager;
        bool ok;

        (ok, ctmRwaToken) = ICTMRWAMap(ctmRwaMap).getTokenContract(ID, RWA_TYPE, VERSION);
        if (!ok) {
            revert CTMRWA1InvestWithTimeLock_InvalidContract(CTMRWAErrorParam.Token);
        }

        decimalsRwa = ICTMRWA1(ctmRwaToken).valueDecimals();

        (ok, ctmRwaDividend) = ICTMRWAMap(ctmRwaMap).getDividendContract(ID, RWA_TYPE, VERSION);
        if (!ok) {
            revert CTMRWA1InvestWithTimeLock_InvalidContract(CTMRWAErrorParam.Dividend);
        }

        (ok, ctmRwaSentry) = ICTMRWAMap(ctmRwaMap).getSentryContract(ID, RWA_TYPE, VERSION);
        if (!ok) {
            revert CTMRWA1InvestWithTimeLock_InvalidContract(CTMRWAErrorParam.Sentry);
        }

        ctmRwa1X = ICTMRWA1(ctmRwaToken).ctmRwa1X();

        cIdStr = block.chainid.toString();
    }

    /**
     * @notice Change the tokenAdmin address
     * NOTE This function can only be called by CTMRWA1X, or the existing tokenAdmin
     * @param _tokenAdmin The new tokenAdmin address
     * @param _force Whether to force the change even if there are Offerings
     * @return success True if the tokenAdmin was changed, false otherwise.
     */
    function setTokenAdmin(address _tokenAdmin, bool _force) public onlyTokenAdmin(ctmRwaToken) returns (bool) {
        /// @dev if the CTMRWA1 is being locked and there are Offerings, DO NOT change tokenAdmin
        /// for this Investment contract. The tokenAdmin can manually set to address(0) with the
        /// override _force == true
        if (_tokenAdmin == address(0) && offerings.length != 0 && !_force) {
            return false;
        }

        tokenAdmin = _tokenAdmin;
        return (true);
    }

    /**
     * @notice Pause a specific offering (only tokenAdmin)
     * @param _indx The index of the Offering to pause
     */
    function pauseOffering(uint256 _indx) public onlyTokenAdmin(ctmRwaToken) {
        if (_indx >= offerings.length) {
            revert CTMRWA1InvestWithTimeLock_InvalidOfferingIndex();
        }
        _isOfferingPaused[_indx] = true;
        emit OfferingPaused(ID, _indx, msg.sender);
    }

    /**
     * @notice Unpause a specific offering (only tokenAdmin)
     * @param _indx The index of the Offering to unpause
     */
    function unpauseOffering(uint256 _indx) public onlyTokenAdmin(ctmRwaToken) {
        if (_indx >= offerings.length) {
            revert CTMRWA1InvestWithTimeLock_InvalidOfferingIndex();
        }
        _isOfferingPaused[_indx] = false;
        emit OfferingUnpaused(ID, _indx, msg.sender);
    }

    /**
     * @notice Check if a specific offering is paused
     * @param _indx The index of the Offering to check if it is paused
     * @return isPaused True if the Offering is paused, false otherwise.
     */
    function isOfferingPaused(uint256 _indx) public view returns (bool) {
        if (_indx >= offerings.length) {
            revert CTMRWA1InvestWithTimeLock_InvalidOfferingIndex();
        }
        return _isOfferingPaused[_indx];
    }

    /**
     * @notice Allow an Issuer(tokenAdmin) to create a new investment Offering, with all parameters.
     * One of the tokenAdmin's tokenIds is transferred to the contract and then when an investor invests,
     * they get a tokenId, which is held by this contract for an escrow period, after which they can withdraw it.
     * @param _tokenId This is the tokenId of the tokenAdmin that is transferred to this contract.
     * Its balance is the amount of the Offering and its Asset Class(slot) defines what is being offered
     * @param _price The price of 1 unit of value in the tokenId.
     * @param _currency The ERC20 address of the  token required to be invested
     * @param _minInvestment The minimum allowable investment
     * @param _maxInvestment The maximum allowable investment
     * @param _regulatorCountry The 2 letter Country Code of the Regulator
     * @param _regulatorAcronym The acronym of the Regulator
     * @param _offeringType The short AssetX description of the offering
     * @param _bnbGreenfieldObjectName The name of the object describing the offering in the BNB Greenfield Storage
     * @param _startTime The time after which offers will be accepted
     * @param _endTime The end time, after which offers will no longer be allowed
     * @param _lockDuration The time for which the investors tokenId will be held in escrow for.
     * After this time they may unlock their tokenId into their own wallet. They may claim rewards
     * during the escrow period.
     * @param _rewardToken The address of the ERC20 token used for rewards. address(0) means no rewards.
     * @param _feeToken The address of the ERC20 token used to pay fees to AssetX. See getFeeTokenList in
     * the FeeManager contract for allowable fee addresses
     */
    function createOffering(
        uint256 _tokenId,
        uint256 _price,
        address _currency,
        uint256 _minInvestment,
        uint256 _maxInvestment,
        string memory _regulatorCountry,
        string memory _regulatorAcronym,
        string memory _offeringType,
        string memory _bnbGreenfieldObjectName,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _lockDuration,
        address _rewardToken,
        address _feeToken
    ) public onlyTokenAdmin(ctmRwaToken) {
        if (!ICTMRWA1(ctmRwaToken).exists(_tokenId)) {
            revert CTMRWA1InvestWithTimeLock_NonExistentToken(_tokenId);
        }
        if (offerings.length > MAX_OFFERINGS) {
            revert CTMRWA1InvestWithTimeLock_MaxOfferings();
        }
        if (bytes(_regulatorCountry).length > 2) {
            revert CTMRWA1InvestWithTimeLock_InvalidLength(CTMRWAErrorParam.CountryCode);
        }
        if (bytes(_offeringType).length > 128) {
            revert CTMRWA1InvestWithTimeLock_InvalidLength(CTMRWAErrorParam.Offering);
        }

        // Check that _rewardToken is a contract and implements totalSupply (ERC20), unless it is address(0)
        if (_rewardToken != address(0)) {
            (bool success, ) = _rewardToken.staticcall(abi.encodeWithSignature("totalSupply()"));
            if (!success) {
                revert CTMRWA1InvestWithTimeLock_InvalidContract(CTMRWAErrorParam.Token);
            }
        }

        uint256 offer = ICTMRWA1(ctmRwaToken).balanceOf(_tokenId);
        uint256 slot = ICTMRWA1(ctmRwaToken).slotOf(_tokenId);

        if (_minInvestment > offer * _price / 10 ** decimalsRwa) {
            revert CTMRWA1InvestWithTimeLock_InvalidLength(CTMRWAErrorParam.MinInvestment);
        }
        if (_minInvestment > _maxInvestment) {
            revert CTMRWA1InvestWithTimeLock_InvalidLength(CTMRWAErrorParam.MinInvestment);
        }

        _payFee(FeeType.OFFERING, _feeToken);

        ICTMRWA1X(ctmRwa1X).transferWholeTokenX(
            tokenAdmin.toHexString(), address(this).toHexString(), cIdStr, _tokenId, ID, _feeToken.toHexString()
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
                _bnbGreenfieldObjectName,
                _startTime,
                _endTime,
                _lockDuration,
                _rewardToken,
                holdings
            )
        );

        uint256 indx = offerings.length - 1;

        _isOfferingPaused[indx] = false;

        emit CreateOffering(ID, indx, slot, offer);
    }

    /**
     * @notice An investor makes an investment for an Offering and is given a tokenId with a value
     * corresponding to their investment and with the same Asset Class (slot). This is held in escrow
     * in the contract for a period, during which they may still receive dividends.
     * @param _indx The zero based index of the Offering. The tokenAdmin may have created several such Offerings
     * @param _investment The investment amount being made. It must conform to the parameters in the Offering.
     * @param _feeToken The address of the ERC20 token used to pay fees to AssetX. See getFeeTokenList in
     * the FeeManager contract for allowable fee addresses.
     * @return newTokenId The tokenId that was invested.
     */
    function investInOffering(uint256 _indx, uint256 _investment, address _feeToken)
        public
        nonReentrant
        returns (uint256)
    {
        if (_indx >= offerings.length) {
            revert CTMRWA1InvestWithTimeLock_InvalidOfferingIndex();
        }

        if (_isOfferingPaused[_indx]) {
            revert CTMRWA1InvestWithTimeLock_Paused();
        }

        if (block.timestamp < offerings[_indx].startTime) {
            revert CTMRWA1InvestWithTimeLock_InvalidTimestamp(CTMRWAErrorParam.Early);
        }

        if (block.timestamp > offerings[_indx].endTime) {
            revert CTMRWA1InvestWithTimeLock_InvalidTimestamp(CTMRWAErrorParam.Late);
        }

        if (_investment == 0) {
            revert CTMRWA1InvestWithTimeLock_InvalidAmount(CTMRWAErrorParam.Value);
        }

        address currency = offerings[_indx].currency;
        if (IERC20(currency).balanceOf(msg.sender) < _investment) {
            revert CTMRWA1InvestWithTimeLock_InvalidAmount(CTMRWAErrorParam.Balance);
        }

        if (_investment < offerings[_indx].minInvestment) {
            revert CTMRWA1InvestWithTimeLock_InvalidAmount(CTMRWAErrorParam.InvestmentLow);
        }

        if (offerings[_indx].maxInvestment > 0 && _investment > offerings[_indx].maxInvestment) {
            revert CTMRWA1InvestWithTimeLock_InvalidAmount(CTMRWAErrorParam.InvestmentHigh);
        }

        if (offerings[_indx].balRemaining < _investment) {
            revert CTMRWA1InvestWithTimeLock_InvalidAmount(CTMRWAErrorParam.Balance);
        }

        bool permitted = ICTMRWA1Sentry(ctmRwaSentry).isAllowableTransfer(msg.sender.toHexString());
        if (!permitted) {
            revert CTMRWA1InvestWithTimeLock_NotWhiteListed(msg.sender);
        }

        uint256 tokenId = offerings[_indx].tokenId;
        string memory feeTokenStr = _feeToken.toHexString();

        _payFee(FeeType.INVEST, _feeToken);

        uint8 decimalsCurrency = IERC20Extended(currency).decimals();

        uint256 value;
        if (decimalsRwa >= decimalsCurrency) {
            uint256 scale = 10 ** (decimalsRwa - decimalsCurrency);
            value = (_investment * scale) / offerings[_indx].price;
        } else {
            uint256 scale = 10 ** (decimalsCurrency - decimalsRwa);
            value = _investment / (offerings[_indx].price * scale);
        }

        IERC20(currency).transferFrom(msg.sender, address(this), _investment);
        offerings[_indx].investment += _investment;

        offerings[_indx].balRemaining -= value;

        uint256 newTokenId = ICTMRWA1X(ctmRwa1X).transferPartialTokenX(
            tokenId, address(this).toHexString(), cIdStr, value, ID, feeTokenStr
        );

        Holding memory newHolding =
            Holding(_indx, msg.sender, newTokenId, block.timestamp + offerings[_indx].lockDuration, 0);

        offerings[_indx].holdings.push(newHolding);
        uint256 holdingIndx = offerings[_indx].holdings.length - 1;

        holdingsByAddress[msg.sender].push(newHolding);

        _addTokenIdInEscrow(newTokenId, msg.sender);

        emit InvestInOffering(ID, _indx, holdingIndx, _investment);

        return newTokenId;
    }


    /**
     * @notice Allow an Issuer (tokenAdmin) to withdraw funds that have been invested in an Offering
     * @param _indx The zero based index of the Offering for which to withdraw funds from.
     * NOTE The tokenAdmin can withdraw funds whenevr there are finds to withdraw. No need to wait until
     * after the Offering is over.
     * @return funds The amount of funds withdrawn.
     */
    function withdrawInvested(uint256 _indx) public onlyTokenAdmin(ctmRwaToken) nonReentrant returns (uint256) {
        if (_indx >= offerings.length) {
            revert CTMRWA1InvestWithTimeLock_InvalidOfferingIndex();
        }

        uint256 investment = offerings[_indx].investment;
        uint256 commission = commissionRate * investment / 10_000;

        if (commission == 0 && commissionRate != 0) {
            revert CTMRWA1InvestWithTimeLock_InvalidAmount(CTMRWAErrorParam.Commission);
        }

        if (investment > 0) {
            address currency = offerings[_indx].currency;
            uint256 funds = investment - commission;
            offerings[_indx].investment = 0;
            
            if (commission > 0) {
                IERC20(currency).transfer(feeManager, commission);
            }
            IERC20(currency).transfer(msg.sender, funds);

            emit WithdrawFunds(ID, _indx, funds);
            return funds;
        } else {
            return 0;
        }
    }

    /**
     * @notice A holder of an investment can withdraw their tokenId from escrow into their possesion.
     * @param _myIndx The zero based index of the Holding to unlock. An investor can have multipe Holdings
     * in this Offering
     * @param _feeToken The address of the ERC20 token used to pay fees to AssetX. See getFeeTokenList in
     * the FeeManager contract for allowable fee addresses.
     * @return tokenId The tokenId that was unlocked.
     */
    function unlockTokenId(uint256 _myIndx, address _feeToken) public nonReentrant returns (uint256) {
        if (_myIndx >= holdingsByAddress[msg.sender].length) {
            revert CTMRWA1InvestWithTimeLock_OutOfBounds();
        }

        Holding memory thisHolding = holdingsByAddress[msg.sender][_myIndx];

        uint256 tokenId = thisHolding.tokenId;
        address owner = ICTMRWA1(ctmRwaToken).ownerOf(tokenId);

        if (owner == address(this)) {
            if (block.timestamp < thisHolding.escrowTime) {
                revert CTMRWA1InvestWithTimeLock_InvalidTimestamp(CTMRWAErrorParam.Early);
            }

            // ICTMRWA1Dividend(ctmRwaDividend).resetDividendByToken(tokenId);
            _removeTokenIdInEscrow(tokenId);

            ICTMRWA1X(ctmRwa1X).transferWholeTokenX(
                address(this).toHexString(), msg.sender.toHexString(), cIdStr, tokenId, ID, _feeToken.toHexString()
            );

            emit UnlockInvestmentToken(ID, msg.sender, _myIndx);

            return tokenId;
        } else {
            // revert("CTMInvest: tokenId already withdrawn");
            revert CTMRWA1InvestWithTimeLock_AlreadyWithdrawn(tokenId);
        }
    }

    /**
     * @notice Get the tokenIds and owners in escrow
     * @return tokensInEscrow The tokenIds in escrow
     * @return ownersInEscrow The owners of the tokenIds in escrow
     */
    function getTokenIdsInEscrow() public view returns (uint256[] memory, address[] memory) {
        return (tokensInEscrow, ownersInEscrow);
    }

    /// @dev Add a tokenId and owner to the escrow arrays
    function _addTokenIdInEscrow(uint256 _tokenId, address _owner) internal {
        tokensInEscrow.push(_tokenId);
        ownersInEscrow.push(_owner);
    }

    /// @dev Remove a tokenId and owner from the escrow arrays
    function _removeTokenIdInEscrow(uint256 _tokenId) internal {
        uint256 len = tokensInEscrow.length;
        for (uint256 i = 0; i < len; i++) {
            if (tokensInEscrow[i] == _tokenId) {
                // If not last, move last to this position
                if (i != len - 1) {
                    tokensInEscrow[i] = tokensInEscrow[len - 1];
                    ownersInEscrow[i] = ownersInEscrow[len - 1];
                }
                tokensInEscrow.pop();
                ownersInEscrow.pop();
                break;
            }
        }
    }


    /**
     * @notice Get the total number of Offerings generated by the Issuer (tokenAdmin).
     * @return The total number of Offerings generated by the Issuer (tokenAdmin).
     */
    function offeringCount() public view returns (uint256) {
        return (offerings.length);
    }

    /**
     * @notice Return all the Offerings generated by the Issuer (tokenAdmin).
     * @return offerings The Offering records.
     */
    function listOfferings() public view returns (Offering[] memory) {
        return (offerings);
    }

    /**
     * @notice Return the Offering made by the Issuer (tokenAdmin) at an index.
     * @param _offerIndx The zero based index of the Offering to return.
     * @return thisOffering The Offering record at the index.
     */
    function listOffering(uint256 _offerIndx) public view returns (Offering memory) {
        if (_offerIndx >= offerings.length) {
            revert CTMRWA1InvestWithTimeLock_InvalidOfferingIndex();
        }
        return (offerings[_offerIndx]);
    }

    /**
     * @notice Return the number of Holdings held by an address in this contract
     * @param _holder The address of the holder.
     * @return The number of Holdings held by the address.
     */
    function escrowHoldingCount(address _holder) public view returns (uint256) {
        return holdingsByAddress[_holder].length;
    }

    /**
     * @notice Return a all the Holding records held by an address.
     * @param _holder The address of the holder.
     * @return holdings The Holding records held by the address.
     */
    function listEscrowHoldings(address _holder) public view returns (Holding[] memory) {
        return holdingsByAddress[_holder];
    }

    /**
     * @notice Return a Holding record of an address at an index.
     * @param _holder The address of the holder.
     * @param _myIndx The zero based index of the Holding to return.
     * @return thisHolding The Holding record at the index.
     */
    function listEscrowHolding(address _holder, uint256 _myIndx) public view returns (Holding memory) {
        if (_myIndx >= holdingsByAddress[_holder].length) {
            revert CTMRWA1InvestWithTimeLock_OutOfBounds();
        }
        Holding memory thisHolding = holdingsByAddress[_holder][_myIndx];

        return (thisHolding);
    }

    /**
     * @notice Allows the tokenAdmin to fund the ERC20 rewardToken for an offering and distribute rewards to all current holders.
     * @param _offeringIndex The index of the offering to fund.
     * @param _fundAmount The amount of rewardToken to transfer to the contract.
     * @param _rewardMultiplier The reward rate (reward tokens per 1 CTMRWA1, in smallest units).
     * @param _rateDivisor The scaling divisor to normalize decimals (e.g., 1e18 for 18 decimals).
     */
    function fundRewardTokenForOffering(uint256 _offeringIndex, uint256 _fundAmount, uint256 _rewardMultiplier, uint256 _rateDivisor)
        external
        nonReentrant
        onlyTokenAdmin(ctmRwaToken)
    {
        if (_offeringIndex >= offerings.length) {
            revert CTMRWA1InvestWithTimeLock_InvalidOfferingIndex();
        }
        Offering storage offering = offerings[_offeringIndex];
        address rewardToken = offering.rewardToken;
        if (rewardToken == address(0)) {
            revert CTMRWA1InvestWithTimeLock_InvalidContract(CTMRWAErrorParam.Token);
        }
        // Transfer the reward tokens from the tokenAdmin to this contract
        IERC20(rewardToken).transferFrom(msg.sender, address(this), _fundAmount);
        // Distribute rewards to all current holders
        for (uint256 i = 0; i < offering.holdings.length; i++) {
            Holding storage holding = offering.holdings[i];
            
            // Skip holders whose escrow lock time has passed
            if (block.timestamp >= holding.escrowTime) {
                continue;
            }
            
            uint256 balance = ICTMRWA1(ctmRwaToken).balanceOf(holding.tokenId);
            uint256 reward = (balance * _rewardMultiplier) / _rateDivisor;
            holding.rewardAmount += reward;
            // Also update the mapping for the holder
            // Find the correct holding in holdingsByAddress
            Holding[] storage holderHoldings = holdingsByAddress[holding.investor];
            for (uint256 j = 0; j < holderHoldings.length; j++) {
                if (holderHoldings[j].tokenId == holding.tokenId && holderHoldings[j].offerIndex == holding.offerIndex) {
                    holderHoldings[j].rewardAmount += reward;
                    break;
                }
            }
        }
        emit FundedRewardToken(_offeringIndex, _fundAmount, _rewardMultiplier);
    }

    /**
     * @notice Returns the rewardToken contract address for an offering and the rewardAmount for a specific Holding of a holder.
     * @param holder The address of the holder.
     * @param offerIndex The index of the offering.
     * @param holdingIndex The index of the holding for the holder.
     * @return rewardToken The reward token contract address for the offering.
     * @return rewardAmount The reward amount for the specified holding.
     */
    function getRewardInfo(address holder, uint256 offerIndex, uint256 holdingIndex) external view returns (address rewardToken, uint256 rewardAmount) {
        if (offerIndex >= offerings.length) {
            revert CTMRWA1InvestWithTimeLock_InvalidOfferingIndex();
        }
        if (holdingIndex >= holdingsByAddress[holder].length) {
            revert CTMRWA1InvestWithTimeLock_InvalidHoldingIndex();
        }
        rewardToken = offerings[offerIndex].rewardToken;
        rewardAmount = holdingsByAddress[holder][holdingIndex].rewardAmount;
    }

    /**
     * @notice Allows a holder to claim their reward for a specific holding.
     * @param offerIndex The index of the offering.
     * @param holdingIndex The index of the holding for the msg.sender.
     */
    function claimReward(uint256 offerIndex, uint256 holdingIndex) external nonReentrant {
        if (offerIndex >= offerings.length) {
            revert CTMRWA1InvestWithTimeLock_InvalidOfferingIndex();
        }
        if (holdingIndex >= holdingsByAddress[msg.sender].length) {
            revert CTMRWA1InvestWithTimeLock_InvalidHoldingIndex();
        }
        Offering storage offering = offerings[offerIndex];
        address rewardToken = offering.rewardToken;
        if (rewardToken == address(0)) {
            revert CTMRWA1InvestWithTimeLock_NoRewardToken();
        }
        Holding storage userHolding;
        uint256 foundIndex = type(uint256).max;
        for (uint256 i = 0; i < offering.holdings.length; i++) {
            if (offering.holdings[i].investor == msg.sender && offering.holdings[i].offerIndex == offerIndex && offering.holdings[i].tokenId == holdingsByAddress[msg.sender][holdingIndex].tokenId) {
                userHolding = offering.holdings[i];
                foundIndex = i;
                break;
            }
        }
        if (foundIndex == type(uint256).max) {
            revert CTMRWA1InvestWithTimeLock_HoldingNotFound();
        }
        uint256 rewardAmount = holdingsByAddress[msg.sender][holdingIndex].rewardAmount;
        if (rewardAmount == 0) {
            revert CTMRWA1InvestWithTimeLock_NoRewardsToClaim();
        }
        // Set rewardAmount to 0 in both mappings
        holdingsByAddress[msg.sender][holdingIndex].rewardAmount = 0;
        offering.holdings[foundIndex].rewardAmount = 0;
        // Transfer reward
        IERC20(rewardToken).transfer(msg.sender, rewardAmount);
        emit RewardClaimed(msg.sender, offerIndex, holdingIndex, rewardAmount);
    }

    /**
     * @notice Allows the tokenAdmin to remove the remaining balance of a tokenId in an Offering after the end time.
     * This function can only be called after the offering has ended and only if there is remaining balance.
     * @param _indx The index of the Offering to remove remaining balance from.
     * @param _feeToken The address of the ERC20 token used to pay fees to AssetX.
     * @return newTokenId The new tokenId created for the tokenAdmin with the remaining balance.
     */
    function removeRemainingTokenId(uint256 _indx, address _feeToken) 
        public 
        onlyTokenAdmin(ctmRwaToken) 
        nonReentrant 
        returns (uint256) 
    {
        if (_indx >= offerings.length) {
            revert CTMRWA1InvestWithTimeLock_InvalidOfferingIndex();
        }

        Offering storage offering = offerings[_indx];

        // Check if the offering has ended
        if (block.timestamp <= offering.endTime) {
            revert CTMRWA1InvestWithTimeLock_OfferingNotEnded();
        }

        // Check if there is remaining balance to remove
        if (offering.balRemaining == 0) {
            revert CTMRWA1InvestWithTimeLock_NoRemainingBalance();
        }

        uint256 remainingBalance = offering.balRemaining;
        uint256 tokenId = offering.tokenId;

        // Pay the fee for removing remaining balance
        _payFee(FeeType.OFFERING, _feeToken);

        // Transfer the remaining balance back to the tokenAdmin
        // We need to create a new tokenId for the tokenAdmin with the remaining balance
        uint256 newTokenId = ICTMRWA1X(ctmRwa1X).transferPartialTokenX(
            tokenId, 
            tokenAdmin.toHexString(), 
            cIdStr, 
            remainingBalance, 
            ID, 
            _feeToken.toHexString()
        );

        // Set the remaining balance to 0
        offering.balRemaining = 0;

        emit RemoveRemainingBalance(ID, _indx, remainingBalance);

        return newTokenId;
    }

    /// @dev Check that msg.sender is the tokenAdmin of a CTMRWA1 address
    function _checkTokenAdmin(address _ctmRwaToken) internal {
        tokenAdmin = ICTMRWA1(_ctmRwaToken).tokenAdmin();
        if (msg.sender != tokenAdmin && msg.sender != ctmRwa1X) {
            revert CTMRWA1InvestWithTimeLock_OnlyAuthorized(CTMRWAErrorParam.Sender, CTMRWAErrorParam.TokenAdmin);
        }
    }

    /// @dev Pay offering fees
    function _payFee(FeeType _feeType, address _feeToken) internal returns (bool) {
        string memory feeTokenStr = _feeToken.toHexString();
        uint256 feeWei = IFeeManager(feeManager).getXChainFee(cIdStr._stringToArray(), false, _feeType, feeTokenStr);
        feeWei = feeWei * (10000 - IFeeManager(feeManager).getFeeReduction(msg.sender)) / 10000;

        if (feeWei > 0) {
            IERC20(_feeToken).transferFrom(msg.sender, address(this), feeWei);

            IERC20(_feeToken).approve(feeManager, feeWei);
            IFeeManager(feeManager).payFee(feeWei, feeTokenStr);
        }
        return (true);
    }
}
