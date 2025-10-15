// SPDX-License-Identifier: BSL-1.1

pragma solidity 0.8.27;

import { ICTMRWA1 } from "../core/ICTMRWA1.sol";
import { ICTMRWA1X } from "./ICTMRWA1X.sol";
import { ICTMRWAMap } from "../shared/ICTMRWAMap.sol";
import { FeeType, IFeeManager } from "../managers/IFeeManager.sol";
import { CTMRWAUtils, CTMRWAErrorParam } from "../utils/CTMRWAUtils.sol";
import { ICTMRWA1XUtils } from "./ICTMRWA1XUtils.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title AssetX Multi-chain Semi-Fungible-Token for Real-World-Assets (RWAs)
 * @author @Selqui ContinuumDAO
 *
 * @notice This contract is a helper contract for CTMRWA1X. It provides additional functionality to the CTMRWA1X contract.
 *
 * This contract is only deployed ONCE on each chain
 */
contract CTMRWA1XUtils is ICTMRWA1XUtils, ReentrancyGuard {
    using Strings for *;
    using CTMRWAUtils for string;
    using SafeERC20 for IERC20;
    
    uint256 immutable RWA_TYPE = 1;

    address public rwa1X;
    address public ctmRwaMap;
    address public feeManager;
    bytes4 public lastSelector;
    bytes public lastData;
    bytes public lastReason;
    string public cIdStr;


    /// @dev tokenAdmin address => version => array of CTMRWA1 contracts. CTMRWAErrorParam of contracts controlled by each tokenAdmin
    mapping(address => mapping(uint256 => address[])) public adminTokens;

    /**
     * @dev  owner address => version =>array of CTMRWA1 contracts.
     * CTMRWAErrorParam  of CTMRWA1 contracts that an owner address has one or more tokenIds
     */
    mapping(address => mapping(uint256 => address[])) public ownedCtmRwa1;


    modifier onlyRwa1X() {
        // Allow calls originating from the RWAX proxy (external) or from self (internal delegatecall)
        if (msg.sender != rwa1X && msg.sender != address(this)) {
            revert CTMRWA1XUtils_OnlyAuthorized(CTMRWAErrorParam.Sender, CTMRWAErrorParam.RWAX);
        }
        _;
    }

    bytes4 public MintX = bytes4(keccak256("mintX(uint256,uint256,string,string,uint256,uint256)"));

    constructor(address _rwa1X) {
        rwa1X = _rwa1X;
        ctmRwaMap = ICTMRWA1X(rwa1X).ctmRwaMap();
        feeManager = ICTMRWA1X(rwa1X).feeManager();

        cIdStr = ICTMRWA1X(rwa1X).cIdStr();
    }


    /// @dev Add a CTMRWA1 address to an admin's token list
    function addAdminToken(address _admin, address _tokenAddr, uint256 _version) external onlyRwa1X {
        adminTokens[_admin][_version].push(_tokenAddr);
    }

    /// @dev Update a list of CTMRWA1 addresses that _ownerAddr has one or more tokenIds in
    /// @return success True if the address was updated, false otherwise.
    function updateOwnedCtmRwa1(address _ownerAddr, address _tokenAddr, uint256 _version) external onlyRwa1X returns (bool) {
        uint256 len = ownedCtmRwa1[_ownerAddr][_version].length;

        for (uint256 i = 0; i < len; i++) {
            if (ownedCtmRwa1[_ownerAddr][_version][i] == _tokenAddr) {
                return (true);
            }
        }

        ownedCtmRwa1[_ownerAddr][_version].push(_tokenAddr);
        return (false);
    }

    /**
     * @notice Get a list of CTMRWA1 addresses that has a tokenAdmin of _admin on this chain
     * @param _admin The tokenAdmin address that you want to check
     * @param _version The version of the CTMRWA1 contract
     * @return tokens The list of CTMRWA1 addresses that have a tokenAdmin of _admin on this chain
     */
    function getAllTokensByAdminAddress(address _admin, uint256 _version) public view returns (address[] memory) {
        return (adminTokens[_admin][_version]);
    }

    /**
     * @notice Get a list of CTMRWA1 addresses that an address owns one or more tokenIds in
     * on this chain.
     * @param _owner The owner address that you want to check
     * @param _version The version of the CTMRWA1 contract
     * @return tokens The list of CTMRWA1 addresses that an address owns one or more tokenIds in
     * on this chain.
     */
    function getAllTokensByOwnerAddress(address _owner, uint256 _version) public view returns (address[] memory) {
        return (ownedCtmRwa1[_owner][_version]);
    }

    /**
     * @notice Check if an address has any tokenIds in a CTMRWA1 on this chain.
     * @param _owner The address that you want to check ownership for.
     * @param _ctmRwa1Addr The CTMRWA1 address on this chain that you are checking
     * @return success True if the address has any tokenIds in a CTMRWA1 on this chain, false otherwise.
     */
    function isOwnedToken(address _owner, address _ctmRwa1Addr) public view returns (bool) {
        if (ICTMRWA1(_ctmRwa1Addr).balanceOf(_owner) > 0) {
            return (true);
        } else {
            return (false);
        }
    }

   

    /// @dev Swap two tokenAdmins for a CTMRWA1
    function swapAdminAddress(address _oldAdmin, address _newAdmin, address _ctmRwa1Addr, uint256 _version) external onlyRwa1X {
        uint256 len = adminTokens[_oldAdmin][_version].length;

        for (uint256 i = 0; i < len; i++) {
            if (adminTokens[_oldAdmin][_version][i] == _ctmRwa1Addr) {
                if (i != len - 1) {
                    adminTokens[_oldAdmin][_version][i] = adminTokens[_oldAdmin][_version][len - 1];
                }
                adminTokens[_oldAdmin][_version].pop();
                adminTokens[_newAdmin][_version].push(_ctmRwa1Addr);
                break;
            }
        }
    }

    /**
     * @notice Mint a new tokenId for ERC20 contract operations. This function ensures proper tracking
     * of token ownership in the ownedCtmRwa1 mapping.
     * @param _ID The ID of the CTMRWA1 contract
     * @param _to The recipient address
     * @param _slot The slot number
     * @param _slotName The slot name
     * @return newTokenId The newly created tokenId
     */
    function mintFromXForERC20(
        uint256 _ID,
        uint256 _version,
        address _to,
        uint256 _slot,
        string memory _slotName
    ) external returns (uint256) {
        // (address ctmRwa1Addr,) = _getTokenAddr(_ID, _version);
        (bool ok, address ctmRwa1Addr) = ICTMRWAMap(ctmRwaMap).getTokenContract(_ID, RWA_TYPE, _version);
        if (!ok) {
            revert CTMRWA1XUtils_InvalidContract(CTMRWAErrorParam.Token);
        }
        
        // Validate that the caller is an authorized ERC20 contract for this slot
        address erc20Addr = ICTMRWA1(ctmRwa1Addr).getErc20(_slot);
        if (erc20Addr != msg.sender) {
            revert CTMRWA1XUtils_OnlyAuthorized(CTMRWAErrorParam.Sender, CTMRWAErrorParam.RWAERC20);
        }
        
        // Mint the tokenId through CTMRWA1
        uint256 newTokenId = ICTMRWA1(ctmRwa1Addr).mintFromX(_to, _slot, _slotName, 0);
        
        // Update the ownedCtmRwa1 mapping to track this ownership
        this.updateOwnedCtmRwa1(_to, ctmRwa1Addr, _version);
        
        return newTokenId;
    }


    /// @dev Returns the last revert string after c3Fallback from another chain
    function getLastReason() public view returns (string memory) {
        return (string(lastReason));
    }

    /**
     * @notice Mint new fungible value for an RWA with _ID to an Asset Class (slot).
     * @param _toAddress CTMRWAErrorParam to mint new value for
     * @param _toTokenId The tokenId to add the new value to. If set to 0, create a new tokenId
     * @param _slot The Asset Class (slot) for which to mint value if _toTokenId == 0, else must be zero.
     * @param _value The fungible value to create. This is in wei if CTMRWA1().valueDecimals() == 18
     * @param _ID The ID to create new value in
     * @param _version The version of the RWA contract
     * @param _feeTokenStr This is fee token on the source chain (local chain) that you wish to use to pay
     * for the deployment. See the function feeTokenList in the FeeManager contract for allowable values.
     * NOTE For EVM chains, the address of the fee token must be converted to a string.
     * NOTE This is not a cross-chain function. You must switch to each chain that you wish to mint value to.
     * @return newTokenId The tokenId that was minted.
     */
    function mintNewTokenValueLocal(
        address _toAddress,
        uint256 _toTokenId,
        uint256 _slot,
        uint256 _value,
        uint256 _ID,
        uint256 _version,
        string memory _feeTokenStr
    ) public nonReentrant returns (uint256) {
        (bool ok, address ctmRwa1Addr) = ICTMRWAMap(ctmRwaMap).getTokenContract(_ID, RWA_TYPE, _version);
        if (!ok) {
            revert CTMRWA1XUtils_InvalidContract(CTMRWAErrorParam.Token);
        }
        address currentAdmin;
        string memory currentAdminStr;      
        (currentAdmin, currentAdminStr) = _checkTokenAdmin(ctmRwa1Addr);

        _payFee(FeeType.MINT, _feeTokenStr, cIdStr._stringToArray(), true);

        if (_toTokenId > 0) {
            if (_slot != 0) {
                revert CTMRWA1XUtils_NonZeroSlot(_slot);
            }
            ICTMRWA1(ctmRwa1Addr).mintValueX(_toTokenId, _value);
            return (_toTokenId);
        } else {
            bool slotExists = ICTMRWA1(ctmRwa1Addr).slotExists(_slot);
            if (!slotExists) {
                revert CTMRWA1XUtils_NonExistentSlot(_slot);
            }
            string memory thisSlotName = ICTMRWA1(ctmRwa1Addr).slotName(_slot);

            uint256 newTokenId = ICTMRWA1(ctmRwa1Addr).mintFromX(_toAddress, _slot, thisSlotName, _value);
            address owner = ICTMRWA1(ctmRwa1Addr).ownerOf(newTokenId);
            this.updateOwnedCtmRwa1(owner, ctmRwa1Addr, _version);

            return (newTokenId);
        }
    }

    /// @dev Pay a fee, calculated by the feeType, the fee token and the chains in question
    function _payFee(FeeType _feeType, string memory _feeTokenStr, string[] memory _toChainIdsStr, bool _includeLocal)
        internal
    {
        uint256 feeWei = IFeeManager(feeManager).getXChainFee(_toChainIdsStr, _includeLocal, _feeType, _feeTokenStr);
        feeWei = feeWei * (10000 - IFeeManager(feeManager).getFeeReduction(msg.sender)) / 10000;

        if (feeWei > 0) {
            address feeToken = _feeTokenStr._stringToAddress();

            // Record spender balance before transfer
            uint256 senderBalanceBefore = IERC20(feeToken).balanceOf(msg.sender);

            IERC20(feeToken).safeTransferFrom(msg.sender, address(this), feeWei);

            // Assert spender balance change
            uint256 senderBalanceAfter = IERC20(feeToken).balanceOf(msg.sender);
            if (senderBalanceBefore - senderBalanceAfter != feeWei) {
                revert CTMRWA1XUtils_FailedTransfer();
            }

            IERC20(feeToken).forceApprove(feeManager, feeWei);
            IFeeManager(feeManager).payFee(feeWei, _feeTokenStr);
        }
    }

    function _checkTokenAdmin(address _tokenAddr) internal returns (address, string memory) {
        address currentAdmin = ICTMRWA1(_tokenAddr).tokenAdmin();
        string memory currentAdminStr = currentAdmin.toHexString()._toLower();
        if (msg.sender != currentAdmin) {
            revert CTMRWA1XUtils_OnlyAuthorized(CTMRWAErrorParam.Sender, CTMRWAErrorParam.Admin);
        }
        return (currentAdmin, currentAdminStr);
    }

    /**
     * @dev Manage a failure in a cross-chain call with c3Caller
     * @param _selector is the function selector called by c3Caller's execute on the destination
     * @param _data is the abi encoded data sent to the destinatin chain
     * @param _reason is the revert string from the destination chain
     * @param _map is the address of the CTMRWAMap contract
     * @dev If the failing function was mintX (used for transferFrom), then this function will mint the fungible
     * balance in the CTMRWA1 with ID, as a new tokenId, effectively replacing the value that was
     * burned.
     * @return success True if the fallback was successful, false otherwise.
     */
    function rwa1XC3Fallback(bytes4 _selector, bytes calldata _data, bytes calldata _reason, address _map)
        external
        onlyRwa1X
        returns (bool)
    {
        lastSelector = _selector;
        lastData = _data;
        lastReason = _reason;

        if (_selector == MintX) {
            uint256 ID_;
            uint256 version;
            string memory fromAddressStr;
            string memory toAddressStr;
            uint256 slot;
            uint256 value;
            address ctmRwa1Addr;

            (ID_, version, fromAddressStr, toAddressStr, slot, value) =
                abi.decode(_data, (uint256, uint256, string, string, uint256, uint256));

            (, ctmRwa1Addr) = ICTMRWAMap(_map).getTokenContract(ID_, RWA_TYPE, version);

            address fromAddr = fromAddressStr._stringToAddress();
            
            try ICTMRWA1(ctmRwa1Addr).slotName(slot) returns (string memory thisSlotName) {
                ICTMRWA1(ctmRwa1Addr).mintFromX(fromAddr, slot, thisSlotName, value);
                emit ReturnValueFallback(fromAddr, slot, value);
            } catch {
                // Slot doesn't exist, revert
                revert();
            }
        }

        emit LogFallback(_selector, _data, _reason);

        return (true);
    }
}
