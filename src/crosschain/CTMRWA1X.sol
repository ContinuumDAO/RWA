// SPDX-License-Identifier: BSL-1.1

pragma solidity 0.8.27;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import { C3GovernDapp } from "@c3caller/gov/C3GovernDapp.sol";

import { ICTMRWA1, ITokenContract, SlotData, TokenContract } from "../core/ICTMRWA1.sol";
import { ICTMRWA1XFallback } from "../crosschain/ICTMRWA1XFallback.sol";
import { ICTMRWAGateway } from "../crosschain/ICTMRWAGateway.sol";
import { ICTMRWADeployer } from "../deployment/ICTMRWADeployer.sol";
import { FeeType, IFeeManager } from "../managers/IFeeManager.sol";

import { ICTMRWA1X } from "./ICTMRWA1X.sol";

import { ICTMRWAMap } from "../shared/ICTMRWAMap.sol";

import { Address, CTMRWAUtils, List, Uint } from "../CTMRWAUtils.sol";
import { ICTMRWA1Dividend } from "../dividend/ICTMRWA1Dividend.sol";
import { ICTMRWA1Sentry } from "../sentry/ICTMRWA1Sentry.sol";
import { ICTMRWA1Storage, URICategory, URIType } from "../storage/ICTMRWA1Storage.sol";

/**
 * @title AssetX Multi-chain Semi-Fungible-Token for Real-World-Assets (RWAs)
 * @author @Selqui ContinuumDAO
 *
 * @notice This contract manages the basic cross-chain deployment of CTMRWA1
 * as well as the creation of Asset Classes (slots), minting value on local chains,
 * changing tokenAdmin (Issuer), transferring value cross-chain.
 *
 * This contract is only deployed ONCE on each chain and manages all CTMRWA1 contract interactions
 */
contract CTMRWA1X is ICTMRWA1X, ReentrancyGuardUpgradeable, C3GovernDapp, UUPSUpgradeable {
    using Strings for *;
    using SafeERC20 for IERC20;
    using CTMRWAUtils for string;

    /// @dev The address of the CTMRWAGateway contract
    address public gateway;

    /// @dev rwaType is the RWA type defining CTMRWA1
    uint256 public constant RWA_TYPE = 1;

    /// @dev version is the single integer version of this RWA type
    uint256 public constant VERSION = 1;

    /// @dev The address of the FeeManager contract
    address public feeManager;

    /// @dev The address of the CTMRWADeployer contract
    address public ctmRwaDeployer;

    /// @dev The address of the CTMRWAMap contract
    address public ctmRwa1Map;

    /// @dev The address of the CTMRWA1XFallback contract
    address public fallbackAddr;

    /// @dev string representation of the chainID
    string cIdStr;

    /// @dev Addresses of routers, including ContinuumDAO, permitted to bridge tokens cross-chain
    mapping(address => bool) public isMinter;

    /// @dev tokenAdmin address => array of CTMRWA1 contracts. List of contracts controlled by each tokenAdmin
    mapping(address => address[]) public adminTokens;

    /**
     * @dev  owner address => array of CTMRWA1 contracts.
     * List  of CTMRWA1 contracts that an owner address has one or more tokenIds
     */
    mapping(address => address[]) public ownedCtmRwa1;

    function initialize(
        address _gateway,
        address _feeManager,
        address _gov,
        address _c3callerProxy,
        address _txSender,
        uint256 _dappID
    ) external initializer {
        __ReentrancyGuard_init();
        __C3GovernDapp_init(_gov, _c3callerProxy, _txSender, _dappID);
        gateway = _gateway;
        feeManager = _feeManager;
        cIdStr = cID().toString();
        isMinter[address(this)] = true;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyGov { }

    /**
     * @notice Governance adds or removes a router able to bridge tokens or value cross-chain
     * @param _minter The router address
     * @param _set Boolean setting or un-setting minter
     */
    function changeMinterStatus(address _minter, bool _set) external onlyGov {
        if (_minter == address(this) || _minter == fallbackAddr) {
            revert CTMRWA1X_InvalidAddress(Address.Minter);
        }
        isMinter[_minter] = _set;
    }

    /**
     * @notice Governance can change to a new FeeManager contract
     * @param _feeManager address of the new FeeManager contract
     */
    function changeFeeManager(address _feeManager) external onlyGov {
        feeManager = _feeManager;
    }

    /**
     * @notice Governance can change to a new CTMRWAGateway contract
     * @param _gateway address of the new CTMRWAGateway contract
     */
    function setGateway(address _gateway) external onlyGov {
        gateway = _gateway;
    }

    /**
     * @notice Governance can change to a new CTMRWAMap contract and also
     * to reset the deployer, gateway and rwaX addresses in CTMRWAMap should this contract
     * need to be redeployed.
     * @param _map address of the new CTMRWAMap contract
     */
    function setCtmRwaMap(address _map) external onlyGov {
        if (ctmRwaDeployer == address(0)) {
            revert CTMRWA1X_IsZeroAddress(Address.Deployer);
        }
        ctmRwa1Map = _map;
        ICTMRWAMap(ctmRwa1Map).setCtmRwaDeployer(ctmRwaDeployer, gateway, address(this));
    }

    /**
     * @notice Governance can change to a new CTMRWADeployer
     * @param _deployer address of the new CTMRWADeployer contract
     */
    function setCtmRwaDeployer(address _deployer) external onlyGov {
        ctmRwaDeployer = _deployer;
    }

    /**
     * @notice Governance can change to a new CTMRWA1Fallback contract
     * @param _fallbackAddr address of the new CTMRWA1Fallback contract
     */
    function setFallback(address _fallbackAddr) external onlyGov {
        if (_fallbackAddr == address(this)) {
            revert CTMRWA1X_InvalidAddress(Address.Fallback);
        }
        if (_fallbackAddr == address(0)) {
            revert CTMRWA1X_IsZeroAddress(Address.Fallback);
        }
        isMinter[fallbackAddr] = false;
        isMinter[_fallbackAddr] = true;
        fallbackAddr = _fallbackAddr;
    }

    /**
     * @notice Deploy, or extend the deployment of an RWA.
     * If _includeLocal is TRUE, a new CTMRWA1 is deployed on the local chain and optionally on other chains.
     * If _includeLocal is FALSE, an EXISTING RWA on the local chain with ID is extended from the
     * local chain to other chains.
     * NOTE A RWA can only be extended to other chains if it already exists on the locally connected chain.
     * @param _includeLocal If set, a new RWA is created. If not set, an existing one is expanded to other chains.
     * @param _existingID Set to ZERO to create a new RWA, or set to an existing ID to extend it.
     * @dev A user cannot determine the ID for a new RWA. It is effectively random (keccak256)
     * @param _rwaType Type of RWA. For CTMRWA1, set to 1 etc.
     * @param _version Version of this RWA. The current version is 1
     * @param _tokenName The name of the RWA. The name must be between 10 and 512 characters
     * @param _symbol The symbol name for the RWA.
     * NOTE Convention is that it is alphabetic, UPPER CASE and between 1 and 6 characters, with no spaces.
     * @param _decimals Same as for an ERC20. The decimal precision to use for fungible balances or values
     * Set to 0 for integer only quantities and up to typically 18 for maximum precision
     * @param _baseURI Is a string describing how the data linked to the RWA is stored (or not).
     * "GFLD" is the default to store data on decentralized BNB Greenfield.
     * "IPFS" is to store the RWA data on the Inter-planetary-file-system (to be added soon. Not active yet)
     * "NONE" NO data storage for this RWA.
     * NOTE The _baseURI CANNOT later be modified.
     * @param _toChainIdsStr This is an array of strings of chainIDs to deploy to.
     * NOTE For EVM chains, you must convert the integer chainID values to strings
     * NOTE Do NOT include the local chainID string in this array
     * @param _feeTokenStr This is fee token on the source chain (local chain) that you wish to use to pay
     * for the deployment. See the function feeTokenList in the FeeManager contract for allowable values.
     * NOTE For EVM chains, the address of the fee token must be converted to a string
     */
    function deployAllCTMRWA1X(
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
    ) public virtual returns (uint256) {
        if (_includeLocal == (_existingID != 0)) {
            revert CTMRWA1X_InvalidCallLogic();
        }
        uint256 len = bytes(_tokenName).length;
        if (_includeLocal) {
            if (len < 10 || len > 512) {
                revert CTMRWA1X_InvalidLength(Uint.TokenName);
            }
        }

        len = bytes(_symbol).length;
        if (len < 1 || len > 6) {
            revert CTMRWA1X_InvalidLength(Uint.Symbol);
        }

        uint256 nChains = _toChainIdsStr.length;

        string memory ctmRwa1AddrStr;
        address ctmRwa1Addr;
        address currentAdmin;
        uint256 ID;
        string memory tokenName;
        string memory symbol;
        uint8 decimals;
        string memory baseURI;

        uint256[] memory slotNumbers;
        string[] memory slotNames;

        if (_includeLocal) {
            // generate a new ID
            ID = uint256(keccak256(abi.encode(_tokenName, _symbol, _decimals, block.timestamp, msg.sender)));

            tokenName = _tokenName;
            symbol = _symbol;
            decimals = _decimals;
            baseURI = _baseURI;

            currentAdmin = msg.sender;
            ctmRwa1Addr =
                _deployCTMRWA1Local(ID, _tokenName, _symbol, _decimals, baseURI, slotNumbers, slotNames, currentAdmin);

            emit CreateNewCTMRWA1(ID);
        } else {
            // a CTMRWA1 token must be deployed already, so use the existing ID
            ID = _existingID;
            (bool ok, address rwa1Addr) = ICTMRWAMap(ctmRwa1Map).getTokenContract(ID, _rwaType, _version);
            if (!ok) {
                revert CTMRWA1X_InvalidTokenContract();
            }
            ctmRwa1Addr = rwa1Addr;

            _checkTokenAdmin(ctmRwa1Addr);

            (, address sentryAddr) = ICTMRWAMap(ctmRwa1Map).getSentryContract(ID, _rwaType, _version);
            bool whitelist = ICTMRWA1Sentry(sentryAddr).whitelistSwitch();
            bool kyc = ICTMRWA1Sentry(sentryAddr).kycSwitch();
            if (whitelist) {
                revert CTMRWA1X_InvalidList(List.WhiteListEnabled);
            }
            if (kyc) {
                revert CTMRWA1X_KYCEnabled();
            }

            tokenName = ICTMRWA1(ctmRwa1Addr).name();
            symbol = ICTMRWA1(ctmRwa1Addr).symbol();
            decimals = ICTMRWA1(ctmRwa1Addr).valueDecimals();
            baseURI = ICTMRWA1(ctmRwa1Addr).baseURI();

            (slotNumbers, slotNames) = ICTMRWA1(ctmRwa1Addr).getAllSlots();
        }

        ctmRwa1AddrStr = ctmRwa1Addr.toHexString()._toLower();

        _payFee(FeeType.DEPLOY, _feeTokenStr, _toChainIdsStr, _includeLocal);

        for (uint256 i = 0; i < nChains; i++) {
            _deployCTMRWA1X(
                tokenName, symbol, decimals, baseURI, _toChainIdsStr[i], slotNumbers, slotNames, ctmRwa1AddrStr
            );
        }

        return (ID);
    }

    /**
     * @dev This function deploys a new RWA on the local chain. It is called ONLY by deployCTMRWA1
     */
    function _deployCTMRWA1Local(
        uint256 _ID,
        string memory _tokenName,
        string memory _symbol,
        uint8 _decimals,
        string memory _baseURI,
        uint256[] memory _slotNumbers,
        string[] memory _slotNames,
        address _tokenAdmin
    ) internal returns (address) {
        (bool ok,) = ICTMRWAMap(ctmRwa1Map).getTokenContract(_ID, RWA_TYPE, VERSION);
        if (ok) {
            revert CTMRWA1X_InvalidTokenContract();
        }

        bytes memory deployData = abi.encode(
            _ID, _tokenAdmin, _tokenName, _symbol, _decimals, _baseURI, _slotNumbers, _slotNames, address(this)
        );

        (address ctmRwa1Token,,,) = ICTMRWADeployer(ctmRwaDeployer).deploy(_ID, RWA_TYPE, VERSION, deployData);

        ICTMRWA1(ctmRwa1Token).changeAdmin(_tokenAdmin);

        ok = ICTMRWA1(ctmRwa1Token).attachId(_ID, _tokenAdmin);
        if (!ok) {
            revert CTMRWA1X_InvalidAttachmentState();
        }

        adminTokens[_tokenAdmin].push(ctmRwa1Token);

        emit CreateNewCTMRWA1(_ID);

        return (ctmRwa1Token);
    }

    /**
     * Deploys a new CTMRWA1 instance on a destination chain, recovering the ID from
     * a required local instance of CTMRWA1, owned by tokenAdmin.
     * NOTE This function is ONLY called by deployAllCTMRWA1X
     */
    function _deployCTMRWA1X(
        string memory _tokenName,
        string memory _symbol,
        uint8 _decimals,
        string memory _baseURI,
        string memory _toChainIdStr,
        uint256[] memory _slotNumbers,
        string[] memory _slotNames,
        string memory _ctmRwa1AddrStr
    ) internal returns (bool) {
        if (_toChainIdStr.equal(cID().toString())) {
            revert CTMRWA1X_SameChain();
        }
        address ctmRwa1Addr = _ctmRwa1AddrStr._stringToAddress();

        (, string memory currentAdminStr) = _checkTokenAdmin(ctmRwa1Addr);

        uint256 ID = ICTMRWA1(ctmRwa1Addr).ID();

        string memory toChainIdStr = _toChainIdStr._toLower();

        (, string memory toRwaXStr) = _getRWAX(toChainIdStr);

        string memory funcCall = "deployCTMRWA1(string,uint256,string,string,uint8,string,uint256[],string[])";
        bytes memory callData = abi.encodeWithSignature(
            funcCall, currentAdminStr, ID, _tokenName, _symbol, _decimals, _baseURI, _slotNumbers, _slotNames
        );

        _c3call(toRwaXStr, toChainIdStr, callData);

        emit DeployCTMRWA1(ID, toChainIdStr);

        return (true);
    }

    /**
     * @dev Deploys a new CTMRWA1 instance on a destination chain, with the ID sent from a required
     * local instance of CTMRWA1 on the source chain, owned by tokenAdmin.
     * NOTE This function is ONLY called by the MPC network.
     */
    function deployCTMRWA1(
        string memory _newAdminStr,
        uint256 _ID,
        string memory _tokenName,
        string memory _symbol,
        uint8 _decimals,
        string memory _baseURI,
        uint256[] memory _slotNumbers,
        string[] memory _slotNames
    ) external onlyCaller returns (bool) {
        (bool ok,) = ICTMRWAMap(ctmRwa1Map).getTokenContract(_ID, RWA_TYPE, VERSION);
        if (ok) {
            revert CTMRWA1X_InvalidTokenContract();
        }

        address newAdmin = _newAdminStr._stringToAddress();

        _deployCTMRWA1Local(_ID, _tokenName, _symbol, _decimals, _baseURI, _slotNumbers, _slotNames, newAdmin);

        return (true);
    }

    /**
     * @dev Change the tokenAdmin (Issuer) on the local chain for an RWA with _ID
     * NOTE The tokenAdmin is also changed in the linked contracts CTMRWA1Storage and CTMRWA1Sentry
     */
    function _changeAdmin(address _currentAdmin, address _newAdmin, uint256 _ID) internal returns (bool) {
        (address ctmRwa1Addr,) = _getTokenAddr(_ID);

        ICTMRWA1(ctmRwa1Addr).changeAdmin(_newAdmin);

        (, address ctmRwa1DividendAddr) = ICTMRWAMap(ctmRwa1Map).getDividendContract(_ID, RWA_TYPE, VERSION);
        ICTMRWA1Dividend(ctmRwa1DividendAddr).setTokenAdmin(_newAdmin);

        (, address ctmRwa1StorageAddr) = ICTMRWAMap(ctmRwa1Map).getStorageContract(_ID, RWA_TYPE, VERSION);
        ICTMRWA1Storage(ctmRwa1StorageAddr).setTokenAdmin(_newAdmin);

        (, address ctmRwa1SentryAddr) = ICTMRWAMap(ctmRwa1Map).getSentryContract(_ID, RWA_TYPE, VERSION);

        ICTMRWA1Sentry(ctmRwa1SentryAddr).setTokenAdmin(_newAdmin);

        ICTMRWA1(ctmRwa1Addr).changeAdmin(_newAdmin);

        swapAdminAddress(_currentAdmin, _newAdmin, ctmRwa1Addr);
        return (true);
    }

    /**
     * @notice Change the tokenAdmin address of a deployed CTMRWA1. Only the current tokenAdmin can call.
     * @param _newAdminStr The new tokenAdmin. NOTE This is a string, not an address.
     * @param _toChainIdsStr An array of chainID strings for which to change to tokenAdmin address.
     * NOTE This INCLUDES the local chain
     * @param _ID The ID of the RWA you wish to change the tokenAdmin of.
     * @param _feeTokenStr This is fee token on the source chain (local chain) that you wish to use to pay
     * for the deployment. See the function feeTokenList in the FeeManager contract for allowable values.
     * NOTE For EVM chains, the address of the fee token must be converted to a string.
     * NOTE to LOCK this RWA, set _newAdminStr = address(0).toHexString()
     */
    function changeTokenAdmin(
        string memory _newAdminStr,
        string[] memory _toChainIdsStr,
        uint256 _ID,
        string memory _feeTokenStr
    ) public returns (bool) {
        string memory toChainIdStr;
        string memory funcCall;
        bytes memory callData;

        (address ctmRwa1Addr,) = _getTokenAddr(_ID);
        (address currentAdmin, string memory currentAdminStr) = _checkTokenAdmin(ctmRwa1Addr);
        address newAdmin = _newAdminStr._stringToAddress();

        bool includeLocal = false;
        _payFee(FeeType.ADMIN, _feeTokenStr, _toChainIdsStr, includeLocal);

        for (uint256 i = 0; i < _toChainIdsStr.length; i++) {
            toChainIdStr = _toChainIdsStr[i]._toLower();

            if (toChainIdStr.equal(cIdStr)) {
                _changeAdmin(currentAdmin, newAdmin, _ID);
            } else {
                (, string memory toRwaXStr) = _getRWAX(toChainIdStr);

                funcCall = "adminX(uint256,string,string)";
                callData = abi.encodeWithSignature(funcCall, _ID, currentAdminStr, _newAdminStr);

                _c3call(toRwaXStr, toChainIdStr, callData);

                emit ChangingAdmin(_ID, toChainIdStr);
            }
        }

        return (true);
    }

    /**
     * @dev Change the tokenAdmin of RWA with _ID on a chain.
     * This function can only be called by the MPC network.
     */
    function adminX(uint256 _ID, string memory _oldAdminStr, string memory _newAdminStr)
        external
        onlyCaller
        returns (bool)
    {
        (bool ok, address ctmRwa1Addr) = ICTMRWAMap(ctmRwa1Map).getTokenContract(_ID, RWA_TYPE, VERSION);
        if (!ok) {
            revert CTMRWA1X_InvalidTokenContract();
        }

        address newAdmin = _newAdminStr._stringToAddress();

        (, string memory fromChainIdStr,) = _context();
        fromChainIdStr = fromChainIdStr._toLower();

        address currentAdmin = ICTMRWA1(ctmRwa1Addr).tokenAdmin();
        address oldAdmin = _oldAdminStr._stringToAddress();
        if (currentAdmin != oldAdmin) {
            revert CTMRWA1X_InvalidAddress(Address.Admin);
        }

        _changeAdmin(currentAdmin, newAdmin, _ID);

        emit AdminChanged(_ID, _newAdminStr);

        return (true);
    }

    /**
     * @notice Mint new fungible value for an RWA with _ID to an Asset Class (slot).
     * @param _toAddress Address to mint new value for
     * @param _toTokenId The tokenId to add the new value to. If set to 0, create a new tokenId
     * @param _slot The Asset Class (slot) for which to mint value.
     * @param _value The fungible value to create. This is in wei if CTMRWA1().valueDecimals() == 18
     * @param _ID The ID to create new value in
     * @param _feeTokenStr This is fee token on the source chain (local chain) that you wish to use to pay
     * for the deployment. See the function feeTokenList in the FeeManager contract for allowable values.
     * NOTE For EVM chains, the address of the fee token must be converted to a string.
     * NOTE This is not a cross-chain function. You must switch to each chain that you wish to mint value to.
     */
    function mintNewTokenValueLocal(
        address _toAddress,
        uint256 _toTokenId,
        uint256 _slot,
        uint256 _value,
        uint256 _ID,
        string memory _feeTokenStr
    ) public returns (uint256) {
        (address ctmRwa1Addr,) = _getTokenAddr(_ID);
        _checkTokenAdmin(ctmRwa1Addr);

        _payFee(FeeType.MINT, _feeTokenStr, cIdStr._stringToArray(), false);

        if (_toTokenId > 0) {
            ICTMRWA1(ctmRwa1Addr).mintValueX(_toTokenId, _slot, _value);
            return (_toTokenId);
        } else {
            bool slotExists = ICTMRWA1(ctmRwa1Addr).slotExists(_slot);
            if (!slotExists) {
                revert CTMRWA1X_NonExistentSlot(_slot);
            }
            string memory thisSlotName = ICTMRWA1(ctmRwa1Addr).slotName(_slot);

            uint256 newTokenId = ICTMRWA1(ctmRwa1Addr).mintFromX(_toAddress, _slot, thisSlotName, _value);
            address owner = ICTMRWA1(ctmRwa1Addr).ownerOf(newTokenId);
            _updateOwnedCtmRwa1(owner, ctmRwa1Addr);

            return (newTokenId);
        }
    }

    /**
     * @notice Create a new Asset Class (slot).
     * @param _ID The ID for which to create a new slot
     * @param _slot The new slot number. Must be unique.
     * @param _slotName The name of the new Asset Class. Can be blank. Must be less than 257 characters
     * @param _toChainIdsStr An array of strings of chainIDs for the RWA. Must include them all,
     * including the local chain.
     * @param _feeTokenStr This is fee token on the source chain (local chain) that you wish to use to pay
     * for the deployment. See the function feeTokenList in the FeeManager contract for allowable values.
     * NOTE For EVM chains, the address of the fee token must be converted to a string.
     */
    function createNewSlot(
        uint256 _ID,
        uint256 _slot,
        string memory _slotName,
        string[] memory _toChainIdsStr,
        string memory _feeTokenStr
    ) public returns (bool) {
        if (bytes(_slotName).length > 256) {
            revert CTMRWA1X_InvalidLength(Uint.SlotName);
        }
        (address ctmRwa1Addr,) = _getTokenAddr(_ID);
        if (ICTMRWA1(ctmRwa1Addr).slotExists(_slot)) {
            revert CTMRWA1X_SlotExists(_slot);
        }

        _checkTokenAdmin(ctmRwa1Addr);

        string memory toChainIdStr;
        string memory toRwaXStr;
        string memory fromAddressStr;

        _payFee(FeeType.ADMIN, _feeTokenStr, _toChainIdsStr, true);

        uint256 len = _toChainIdsStr.length;

        for (uint256 i = 0; i < len; i++) {
            toChainIdStr = _toChainIdsStr[i]._toLower();
            if (!cIdStr.equal(toChainIdStr)) {
                (fromAddressStr, toRwaXStr) = _getRWAX(toChainIdStr);
                string memory funcCall = "createNewSlotX(uint256,string,uint256,string)";
                bytes memory callData = abi.encodeWithSignature(funcCall, _ID, fromAddressStr, _slot, _slotName);

                _c3call(toRwaXStr, toChainIdStr, callData);

                emit CreateSlot(_ID, _slot, toChainIdStr);
            }
        }

        ICTMRWA1(ctmRwa1Addr).createSlotX(_slot, _slotName);

        return (true);
    }

    /**
     * @dev Create a new slot for RWA with ID.
     * This function is only callable by the MPC network. It checks that the tokenAdmin of the
     * RWA on the source chain is the same as the tokenAdmin of the RWA on this chain.
     */
    function createNewSlotX(uint256 _ID, string memory _fromAddressStr, uint256 _slot, string memory _slotName)
        external
        onlyCaller
        returns (bool)
    {
        (bool ok, address ctmRwa1Addr) = ICTMRWAMap(ctmRwa1Map).getTokenContract(_ID, RWA_TYPE, VERSION);
        if (!ok) {
            revert CTMRWA1X_InvalidTokenContract();
        }
        if (ICTMRWA1(ctmRwa1Addr).slotExists(_slot)) {
            revert CTMRWA1X_SlotExists(_slot);
        }

        (, string memory fromChainIdStr,) = _context();

        address fromAddress = _fromAddressStr._stringToAddress();

        address currentAdmin = ICTMRWA1(ctmRwa1Addr).tokenAdmin();
        if (fromAddress != currentAdmin) {
            revert CTMRWA1X_InvalidAddress(Address.Admin);
        }

        ICTMRWA1(ctmRwa1Addr).createSlotX(_slot, _slotName);

        emit SlotCreated(_ID, _slot, fromChainIdStr);

        return (true);
    }

    /**
     * @notice Transfer part of the fungible balance of a tokenId to an address on another chain
     * @param _fromTokenId The tokenId from which to transfer. The caller must own it or be approved
     * @param _toAddressStr The address AS A STRING to which to send the value on the destination chain
     * @param _toChainIdStr The destination chainID AS A STRING
     * @param _value The fungible value to send. This is in wei if CTMRWA1().valueDecimals() == 18
     * @param _ID The ID of the RWA
     * @param _feeTokenStr This is fee token on the source chain (local chain) that you wish to use to pay
     * for the deployment. See the function feeTokenList in the FeeManager contract for allowable values.
     * NOTE For EVM chains, the address of the fee token must be converted to a string.
     * NOTE A new tokenId will be created for the _toAddressStr on the destination chain. They can then
     * move this balance to an existing tokenId if they wish to using CTMRWA1().transferFrom
     */
    function transferPartialTokenX(
        uint256 _fromTokenId,
        string memory _toAddressStr,
        string memory _toChainIdStr,
        uint256 _value,
        uint256 _ID,
        string memory _feeTokenStr
    ) public nonReentrant returns (uint256) {
        string memory toChainIdStr = _toChainIdStr._toLower();

        (address ctmRwa1Addr,) = _getTokenAddr(_ID);
        if (!ICTMRWA1(ctmRwa1Addr).isApprovedOrOwner(msg.sender, _fromTokenId)) {
            revert CTMRWA1X_Unauthorized(Address.Sender);
        }

        if (toChainIdStr.equal(cIdStr)) {
            address toAddr = _toAddressStr._stringToAddress();
            ICTMRWA1(ctmRwa1Addr).approveFromX(address(this), _fromTokenId);
            uint256 newTokenId = ICTMRWA1(ctmRwa1Addr).transferFrom(_fromTokenId, toAddr, _value);
            ICTMRWA1(ctmRwa1Addr).approveFromX(address(0), _fromTokenId);
            _updateOwnedCtmRwa1(toAddr, ctmRwa1Addr);

            return newTokenId;
        } else {
            (string memory fromAddressStr, string memory toRwaXStr) = _getRWAX(toChainIdStr);

            ICTMRWA1(ctmRwa1Addr).spendAllowance(msg.sender, _fromTokenId, _value);

            _payFee(FeeType.TX, _feeTokenStr, toChainIdStr._stringToArray(), false);

            uint256 slot = ICTMRWA1(ctmRwa1Addr).slotOf(_fromTokenId);

            ICTMRWA1(ctmRwa1Addr).burnValueX(_fromTokenId, _value);

            string memory funcCall = "mintX(uint256,string,string,uint256,uint256)";

            bytes memory callData = abi.encodeWithSignature(funcCall, _ID, fromAddressStr, _toAddressStr, slot, _value);

            _c3call(toRwaXStr, toChainIdStr, callData);

            return 0;
        }
    }

    /**
     * @notice Transfer a whole tokenId to an address on another chain
     * @param _fromAddrStr The address from which to transfer the tokenId. The caller must have approval.
     * @param _toAddressStr The address AS A STRING to which to send the value on the destination chain
     * @param _toChainIdStr The destination chainID AS A STRING
     * @param _fromTokenId The tokenId from which to transfer. The caller must own it or be approved
     * @param _ID The ID of the RWA
     * @param _feeTokenStr This is fee token on the source chain (local chain) that you wish to use to pay
     * for the deployment. See the function feeTokenList in the FeeManager contract for allowable values.
     * NOTE For EVM chains, the address of the fee token must be converted to a string.
     */
    function transferWholeTokenX(
        string memory _fromAddrStr,
        string memory _toAddressStr,
        string memory _toChainIdStr,
        uint256 _fromTokenId,
        uint256 _ID,
        string memory _feeTokenStr
    ) public nonReentrant {
        string memory toChainIdStr = _toChainIdStr._toLower();

        (address ctmRwa1Addr,) = _getTokenAddr(_ID);
        address fromAddr = _fromAddrStr._stringToAddress();
        if (!ICTMRWA1(ctmRwa1Addr).isApprovedOrOwner(msg.sender, _fromTokenId)) {
            revert CTMRWA1X_Unauthorized(Address.Sender);
        }

        if (toChainIdStr.equal(cIdStr)) {
            address toAddr = _toAddressStr._stringToAddress();
            ICTMRWA1(ctmRwa1Addr).approveFromX(address(this), _fromTokenId);
            ICTMRWA1(ctmRwa1Addr).transferFrom(fromAddr, toAddr, _fromTokenId);
            ICTMRWA1(ctmRwa1Addr).approveFromX(toAddr, _fromTokenId);
            _updateOwnedCtmRwa1(toAddr, ctmRwa1Addr);
        } else {
            (, string memory toRwaXStr) = _getRWAX(toChainIdStr);

            _payFee(FeeType.TX, _feeTokenStr, toChainIdStr._stringToArray(), false);

            (, uint256 value,, uint256 slot,,) = ICTMRWA1(ctmRwa1Addr).getTokenInfo(_fromTokenId);

            ICTMRWA1(ctmRwa1Addr).approveFromX(address(0), _fromTokenId);
            ICTMRWA1(ctmRwa1Addr).clearApprovedValues(_fromTokenId);

            ICTMRWA1(ctmRwa1Addr).removeTokenFromOwnerEnumeration(msg.sender, _fromTokenId);

            string memory funcCall = "mintX(uint256,string,string,uint256,uint256)";
            bytes memory callData = abi.encodeWithSignature(funcCall, _ID, _fromAddrStr, _toAddressStr, slot, value);

            _c3call(toRwaXStr, toChainIdStr, callData);

            emit Minting(_ID, _toAddressStr, toChainIdStr);
        }
    }

    /**
     * @dev Mint value in a new slot to an address
     * NOTE: This function is only callable by the MPC network
     * NOTE: It creates a new tokenId
     */
    function mintX(
        uint256 _ID,
        string memory _fromAddressStr,
        string memory _toAddressStr,
        uint256 _slot,
        uint256 _balance
    ) external onlyCaller returns (bool) {
        (, string memory fromChainIdStr,) = _context();

        address toAddr = _toAddressStr._stringToAddress();

        (bool ok, address ctmRwa1Addr) = ICTMRWAMap(ctmRwa1Map).getTokenContract(_ID, RWA_TYPE, VERSION);
        if (!ok) {
            revert CTMRWA1X_InvalidTokenContract();
        }

        bool slotExists = ICTMRWA1(ctmRwa1Addr).slotExists(_slot);
        if (!slotExists) {
            revert CTMRWA1X_NonExistentSlot(_slot);
        }

        string memory thisSlotName = ICTMRWA1(ctmRwa1Addr).slotName(_slot);

        ICTMRWA1(ctmRwa1Addr).mintFromX(toAddr, _slot, thisSlotName, _balance);

        _updateOwnedCtmRwa1(toAddr, ctmRwa1Addr);

        emit Minted(_ID, fromChainIdStr, _fromAddressStr);

        return (true);
    }

    // End of cross chain transfers

    /// @dev Update a list of CTMRWA1 addresses that _ownerAddr has one or more tokenIds in
    function _updateOwnedCtmRwa1(address _ownerAddr, address _tokenAddr) internal returns (bool) {
        uint256 len = ownedCtmRwa1[_ownerAddr].length;

        for (uint256 i = 0; i < len; i++) {
            if (ownedCtmRwa1[_ownerAddr][i] == _tokenAddr) {
                return (true);
            }
        }

        ownedCtmRwa1[_ownerAddr].push(_tokenAddr);
        return (false);
    }

    /**
     * @notice Get a list of CTMRWA1 addresses that has a tokenAdmin of _admin on this chain
     * @param _admin The tokenAdmin address that you want to check
     */
    function getAllTokensByAdminAddress(address _admin) public view returns (address[] memory) {
        return (adminTokens[_admin]);
    }

    /**
     * @notice Get a list of CTMRWA1 addresses that an address owns one or more tokenIds in
     * on this chain.
     * @param _owner The owner address that you want to check
     */
    function getAllTokensByOwnerAddress(address _owner) public view returns (address[] memory) {
        return (ownedCtmRwa1[_owner]);
    }

    /**
     * @notice Check if an address has any tokenIds in a CTMRWA1 on this chain.
     * @param _owner The address that you want to check ownership for.
     * @param _ctmRwa1Addr The CTMRWA1 address on this chain that you are checking
     */
    function isOwnedToken(address _owner, address _ctmRwa1Addr) public view returns (bool) {
        if (ICTMRWA1(_ctmRwa1Addr).balanceOf(_owner) > 0) {
            return (true);
        } else {
            return (false);
        }
    }

    /// @dev Get the CTMRWA1 address and string version on this chain for an ID
    function _getTokenAddr(uint256 _ID) internal view returns (address, string memory) {
        (bool ok, address tokenAddr) = ICTMRWAMap(ctmRwa1Map).getTokenContract(_ID, RWA_TYPE, VERSION);
        if (!ok) {
            revert CTMRWA1X_InvalidTokenContract();
        }
        string memory tokenAddrStr = tokenAddr.toHexString()._toLower();

        return (tokenAddr, tokenAddrStr);
    }

    /// @dev Get the corresponding CTMRWA1X address on another chain with chainId _toChainIdStr
    function _getRWAX(string memory _toChainIdStr) internal view returns (string memory, string memory) {
        if (_toChainIdStr.equal(cIdStr)) {
            revert CTMRWA1X_SameChain();
        }

        string memory fromAddressStr = msg.sender.toHexString()._toLower();

        (bool ok, string memory toRwaXStr) = ICTMRWAGateway(gateway).getAttachedRWAX(RWA_TYPE, VERSION, _toChainIdStr);
        if (!ok) {
            revert CTMRWA1X_InvalidAttachmentState();
        }

        return (fromAddressStr, toRwaXStr);
    }

    /**
     * @dev Return the tokenAdmin address for a CTMRWA1 with address _tokenAddr and
     * check that the msg.sender is the tokenAdmin and revert if not so.
     * OPTIMIZE: this function could be removed (in favour of local errors) if size reduction is needed
     */
    function _checkTokenAdmin(address _tokenAddr) internal returns (address, string memory) {
        address currentAdmin = ICTMRWA1(_tokenAddr).tokenAdmin();
        string memory currentAdminStr = currentAdmin.toHexString()._toLower();

        if (msg.sender != currentAdmin) {
            revert CTMRWA1X_Unauthorized(Address.Sender);
        }

        return (currentAdmin, currentAdminStr);
    }

    /// @dev Swap two tokenAdmins for a CTMRWA1
    function swapAdminAddress(address _oldAdmin, address _newAdmin, address _ctmRwa1Addr) internal {
        uint256 len = adminTokens[_oldAdmin].length;

        for (uint256 i = 0; i < len; i++) {
            if (adminTokens[_oldAdmin][i] == _ctmRwa1Addr) {
                if (i != len - 1) {
                    adminTokens[_oldAdmin][i] = adminTokens[_oldAdmin][len - 1];
                }
                adminTokens[_oldAdmin].pop();
                adminTokens[_newAdmin].push(_ctmRwa1Addr);
                break;
            }
        }
    }

    /// @dev Pay a fee, calculated by the feeType, the fee token and the chains in question
    function _payFee(FeeType _feeType, string memory _feeTokenStr, string[] memory _toChainIdsStr, bool _includeLocal)
        internal
        returns (bool)
    {
        uint256 feeWei = IFeeManager(feeManager).getXChainFee(_toChainIdsStr, _includeLocal, _feeType, _feeTokenStr);

        if (feeWei > 0) {
            address feeToken = _feeTokenStr._stringToAddress();

            IERC20(feeToken).transferFrom(msg.sender, address(this), feeWei);

            IERC20(feeToken).approve(feeManager, feeWei);
            IFeeManager(feeManager).payFee(feeWei, _feeTokenStr);
        }
        return (true);
    }

    function cID() internal view returns (uint256) {
        return block.chainid;
    }

    /**
     * @dev Handle failures in a cross-chain call. The logic is managed in a separate contract
     * CTMRWA1XFallback. See there for details.
     */
    function _c3Fallback(bytes4 _selector, bytes calldata _data, bytes calldata _reason)
        internal
        override
        returns (bool)
    {
        bool ok = ICTMRWA1XFallback(fallbackAddr).rwa1XC3Fallback(_selector, _data, _reason);

        return ok;
    }
}
