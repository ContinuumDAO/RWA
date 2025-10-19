// SPDX-License-Identifier: BSL-1.1

pragma solidity 0.8.27;

import { ICTMRWA1, ITokenContract, SlotData, TokenContract } from "../core/ICTMRWA1.sol";

import { ICTMRWA1InvestWithTimeLock } from "../deployment/CTMRWA1InvestWithTimeLock.sol";
import { ICTMRWADeployer } from "../deployment/ICTMRWADeployer.sol";
import { ICTMRWA1Dividend } from "../dividend/ICTMRWA1Dividend.sol";
import { FeeType, IFeeManager } from "../managers/IFeeManager.sol";
import { ICTMRWA1Sentry } from "../sentry/ICTMRWA1Sentry.sol";
import { ICTMRWAMap } from "../shared/ICTMRWAMap.sol";
import { ICTMRWA1Storage, URICategory, URIType } from "../storage/ICTMRWA1Storage.sol";
import { CTMRWAUtils, CTMRWAErrorParam } from "../utils/CTMRWAUtils.sol";
import { ICTMRWA1X } from "./ICTMRWA1X.sol";
import { ICTMRWA1XUtils } from "./ICTMRWA1XUtils.sol";
import { ICTMRWAGateway } from "./ICTMRWAGateway.sol";
import { C3GovernDAppUpgradeable } from "@c3caller/upgradeable/gov/C3GovernDAppUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

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
contract CTMRWA1X is ICTMRWA1X, ReentrancyGuardUpgradeable, C3GovernDAppUpgradeable, UUPSUpgradeable {
    using Strings for *;
    using SafeERC20 for IERC20;
    using CTMRWAUtils for string;

    /// @dev The latest version of RWA type. New versions of RWA are only allowed to be deployed on the latest version of the RWA.
    uint256 public LATEST_VERSION;

    /// @dev The address of the CTMRWAGateway contract
    address public gateway;

    /// @dev rwaType is the RWA type defining CTMRWA1. It CANNOT be changed with proxy upgrades
    uint256 public immutable RWA_TYPE = 1;

    /// @dev The address of the FeeManager contract
    address public feeManager;

    /// @dev The address of the CTMRWADeployer contract
    address public ctmRwaDeployer;

    /// @dev The address of the CTMRWAMap contract
    address public ctmRwaMap;

    /// @dev The address of the CTMRWA1XUtils contract, which extenda CTMRWA1X functionality
    address public ctmRwa1XUtilsAddr;

    /// @dev string representation of the chainID
    string public cIdStr;

    /// @dev Addresses of routers, including ContinuumDAO, permitted to bridge tokens cross-chain
    mapping(address => bool) public isMinter;




    function initialize(
        address _gateway,
        address _feeManager,
        address _gov,
        address _c3callerProxy,
        address _txSender,
        uint256 _dappID
    ) external initializer {
        __ReentrancyGuard_init();
        __C3GovernDApp_init(_gov, _c3callerProxy, _txSender, _dappID);
        LATEST_VERSION = 1;
        gateway = _gateway;
        feeManager = _feeManager;
        cIdStr = cID().toString();
        isMinter[address(this)] = true;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyGov { }

    /**
     * @notice Governance can update the latest version
     * @param _newVersion The new latest version
     */
    function updateLatestVersion(uint256 _newVersion) external onlyGov {
        if (_newVersion == 0) {
            revert CTMRWA1X_InvalidVersion(_newVersion);
        }
        LATEST_VERSION = _newVersion;
    }

    /**
     * @notice Governance adds or removes a router able to bridge tokens or value cross-chain
     * @param _minter The router address
     * @param _set Boolean setting or un-setting minter
     */
    function changeMinterStatus(address _minter, bool _set) external onlyGov {
        if (_minter == address(this) || _minter == ctmRwa1XUtilsAddr) {
            revert CTMRWA1X_InvalidAddress(CTMRWAErrorParam.Minter);
        }
        isMinter[_minter] = _set;
    }

    /**
     * @notice Governance can change to a new FeeManager contract
     * @param _feeManager address of the new FeeManager contract
     */
    function changeFeeManager(address _feeManager) external onlyGov {
        if (_feeManager == address(0)) {
            revert CTMRWA1X_IsZeroAddress(CTMRWAErrorParam.FeeManager);
        }
        feeManager = _feeManager;
    }

    /**
     * @notice Governance can change to a new CTMRWAGateway contract
     * @param _gateway address of the new CTMRWAGateway contract
     */
    function setGateway(address _gateway) external onlyGov {
        if (_gateway == address(0)) {
            revert CTMRWA1X_IsZeroAddress(CTMRWAErrorParam.Gateway);
        }
        gateway = _gateway;
    }

    /**
     * @notice Governance can change to a new CTMRWAMap contract and also
     * to reset the deployer, gateway and rwaX addresses in CTMRWAMap should this contract
     * need to be redeployed.
     * @param _map address of the new CTMRWAMap contract
     */
    function setCtmRwaMap(address _map) external onlyGov {
        if (_map == address(0)) {
            revert CTMRWA1X_IsZeroAddress(CTMRWAErrorParam.Map);
        }
        ctmRwaMap = _map;
        ICTMRWAMap(ctmRwaMap).setCtmRwaDeployer(ctmRwaDeployer, gateway, address(this));
    }

    /**
     * @notice Governance can change to a new CTMRWADeployer
     * @param _deployer address of the new CTMRWADeployer contract
     */
    function setCtmRwaDeployer(address _deployer) external onlyGov {
        if (_deployer == address(0)) {
            revert CTMRWA1X_IsZeroAddress(CTMRWAErrorParam.Deployer);
        }
        ctmRwaDeployer = _deployer;
    }

    /**
     * @notice Governance can change to a new CTMRWA1XUtils contract
     * @param _ctmRwa1XUtilsAddr address of the new CTMRWA1XUtils contract
     */
    function setFallback(address _ctmRwa1XUtilsAddr) external onlyGov {
        if (_ctmRwa1XUtilsAddr == address(this)) {
            revert CTMRWA1X_InvalidAddress(CTMRWAErrorParam.Fallback);
        }
        if (_ctmRwa1XUtilsAddr == address(0)) {
            revert CTMRWA1X_IsZeroAddress(CTMRWAErrorParam.Fallback);
        }
        isMinter[ctmRwa1XUtilsAddr] = false;
        isMinter[_ctmRwa1XUtilsAddr] = true;
        ctmRwa1XUtilsAddr = _ctmRwa1XUtilsAddr;
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
     * @param _version Version of this RWA. The latest version is 1
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
                revert CTMRWA1X_InvalidLength(CTMRWAErrorParam.TokenName);
            }
        }

        len = bytes(_symbol).length;
        if (len < 1 || len > 6) {
            revert CTMRWA1X_InvalidLength(CTMRWAErrorParam.Symbol);
        }

        len = bytes(_baseURI).length;
        if (len > 4) {
            revert CTMRWA1X_InvalidLength(CTMRWAErrorParam.BaseURI);
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
            // Restrict new CTMRWA1 tokens to be deployed to the latest version
            if (_version != LATEST_VERSION) {
                revert CTMRWA1X_InvalidVersion(_version);
            }
            // generate a new ID
            ID = uint256(keccak256(abi.encode(_tokenName, _symbol, _decimals, block.timestamp, msg.sender)));

            tokenName = _tokenName;
            symbol = _symbol;
            decimals = _decimals;
            baseURI = _baseURI;

            currentAdmin = msg.sender;
            ctmRwa1Addr =
                _deployCTMRWA1Local(ID, _version, _tokenName, _symbol, _decimals, baseURI, slotNumbers, slotNames, currentAdmin);

            if (ID != ICTMRWA1(ctmRwa1Addr).ID()) {
                revert CTMRWA1X_InvalidID(ID);
            }

        } else {
            // a CTMRWA1 token must be deployed already, so use the existing ID
            ID = _existingID;
            (bool ok, address rwa1Addr) = ICTMRWAMap(ctmRwaMap).getTokenContract(ID, RWA_TYPE, _version);
            if (!ok) {
                revert CTMRWA1X_InvalidContract(CTMRWAErrorParam.Token);
            }
            ctmRwa1Addr = rwa1Addr;

            _checkTokenAdmin(ctmRwa1Addr);

            (, address sentryAddr) = ICTMRWAMap(ctmRwaMap).getSentryContract(ID, RWA_TYPE, _version);
            bool whitelist = ICTMRWA1Sentry(sentryAddr).whitelistSwitch();
            bool kyc = ICTMRWA1Sentry(sentryAddr).kycSwitch();
            if (whitelist) {
                revert CTMRWA1X_InvalidList(CTMRWAErrorParam.WL_Enabled);
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
                _version,tokenName, symbol, decimals, baseURI, _toChainIdsStr[i], slotNumbers, slotNames, ctmRwa1AddrStr
            );
        }

        return (ID);
    }

    /**
     * @dev This function deploys a new RWA on the local chain. It is called ONLY by deployAllCTMRWA1X
     * on the local chain or by deployCTMRWA1 on other chains.
     */
    function _deployCTMRWA1Local(
        uint256 _ID,
        uint256 _version,
        string memory _tokenName,
        string memory _symbol,
        uint8 _decimals,
        string memory _baseURI,
        uint256[] memory _slotNumbers,
        string[] memory _slotNames,
        address _tokenAdmin
    ) internal returns (address) {
        (bool ok,) = ICTMRWAMap(ctmRwaMap).getTokenContract(_ID, RWA_TYPE, _version);
        if (ok) {
            revert CTMRWA1X_InvalidContract(CTMRWAErrorParam.Token);
        }

        bytes memory deployData = abi.encode(
            _ID, _tokenAdmin, _tokenName, _symbol, _decimals, _baseURI, _slotNumbers, _slotNames, address(this)
        );

        (address ctmRwa1Token,,,) = ICTMRWADeployer(ctmRwaDeployer).deploy(_ID, RWA_TYPE, _version, deployData);

        ICTMRWA1(ctmRwa1Token).changeAdmin(_tokenAdmin);

        ok = ICTMRWA1(ctmRwa1Token).attachId(_ID, _tokenAdmin);
        if (!ok) {
            revert CTMRWA1X_InvalidAttachmentState();
        }

        ICTMRWA1XUtils(ctmRwa1XUtilsAddr).addAdminToken(_tokenAdmin, ctmRwa1Token, _version);

        emit CreateNewCTMRWA1(_ID);

        return (ctmRwa1Token);
    }

    /**
     * Deploys a new CTMRWA1 instance on a destination chain, recovering the ID from
     * a required local instance of CTMRWA1, owned by tokenAdmin.
     * NOTE This function is ONLY called by deployAllCTMRWA1X
     */
    function _deployCTMRWA1X(
        uint256 _version,
        string memory _tokenName,
        string memory _symbol,
        uint8 _decimals,
        string memory _baseURI,
        string memory _toChainIdStr,
        uint256[] memory _slotNumbers,
        string[] memory _slotNames,
        string memory _ctmRwa1AddrStr
    ) internal {
        if (_toChainIdStr.equal(cID().toString())) {
            revert CTMRWA1X_SameChain();
        }
        address ctmRwa1Addr = _ctmRwa1AddrStr._stringToAddress();

        (, string memory currentAdminStr) = _checkTokenAdmin(ctmRwa1Addr);

        uint256 ID = ICTMRWA1(ctmRwa1Addr).ID();

        string memory toChainIdStr = _toChainIdStr._toLower();

        (, string memory toRwaXStr) = _getRWAX(toChainIdStr, _version);

        string memory funcCall = "deployCTMRWA1(uint256,string,uint256,string,string,uint8,string,uint256[],string[])";
        bytes memory callData = abi.encodeWithSignature(
            funcCall, _version, currentAdminStr, ID, _tokenName, _symbol, _decimals, _baseURI, _slotNumbers, _slotNames
        );

        _c3call(toRwaXStr, toChainIdStr, callData);

        emit DeployCTMRWA1(ID, toChainIdStr);
    }

    /**
     * @dev Deploys a new CTMRWA1 instance on a destination chain, with the ID sent from a required
     * local instance of CTMRWA1 on the source chain, owned by tokenAdmin.
     * NOTE This function is ONLY called by the MPC network.
     */
    function deployCTMRWA1(
        uint256 _version,
        string memory _newAdminStr,
        uint256 _ID,
        string memory _tokenName,
        string memory _symbol,
        uint8 _decimals,
        string memory _baseURI,
        uint256[] memory _slotNumbers,
        string[] memory _slotNames
    ) external onlyCaller returns (bool) {
        (bool ok,) = ICTMRWAMap(ctmRwaMap).getTokenContract(_ID, RWA_TYPE, _version);
        if (ok) {
            revert CTMRWA1X_InvalidContract(CTMRWAErrorParam.Token);
        }

        address newAdmin = _newAdminStr._stringToAddress();

        _deployCTMRWA1Local(_ID, _version, _tokenName, _symbol, _decimals, _baseURI, _slotNumbers, _slotNames, newAdmin);

        return (true);
    }

    /**
     * @dev Change the tokenAdmin (Issuer) on the local chain for an RWA with _ID
     * NOTE The tokenAdmin is also changed in the linked contracts CTMRWA1Storage and CTMRWA1Sentry
     */
    function _changeAdmin(address _currentAdmin, address _newAdmin, uint256 _ID, uint256 _version) internal {
        (address ctmRwa1Addr,) = _getTokenAddr(_ID, _version);

        ICTMRWA1(ctmRwa1Addr).changeAdmin(_newAdmin);

        (, address ctmRwa1DividendAddr) = ICTMRWAMap(ctmRwaMap).getDividendContract(_ID, RWA_TYPE, _version);
        ICTMRWA1Dividend(ctmRwa1DividendAddr).setTokenAdmin(_newAdmin);

        (, address ctmRwa1StorageAddr) = ICTMRWAMap(ctmRwaMap).getStorageContract(_ID, RWA_TYPE, _version);
        ICTMRWA1Storage(ctmRwa1StorageAddr).setTokenAdmin(_newAdmin);

        (, address ctmRwa1SentryAddr) = ICTMRWAMap(ctmRwaMap).getSentryContract(_ID, RWA_TYPE, _version);

        (bool ok, address ctmRwaInvestAddr) = ICTMRWAMap(ctmRwaMap).getInvestContract(_ID, RWA_TYPE, _version);
        if (ok) {
            ICTMRWA1InvestWithTimeLock(ctmRwaInvestAddr).setTokenAdmin(_newAdmin, false);
        }

        ICTMRWA1Sentry(ctmRwa1SentryAddr).setTokenAdmin(_newAdmin);

        ICTMRWA1(ctmRwa1Addr).changeAdmin(_newAdmin);

        ICTMRWA1XUtils(ctmRwa1XUtilsAddr).swapAdminAddress(_currentAdmin, _newAdmin, ctmRwa1Addr, _version);
    }

    /**
     * @notice Change the tokenAdmin address of a deployed CTMRWA1. Only the current tokenAdmin can call this function.
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
        uint256 _version,
        string memory _feeTokenStr
    ) public {
        string memory toChainIdStr;
        string memory funcCall;
        bytes memory callData;

        (address ctmRwa1Addr,) = _getTokenAddr(_ID, _version);
        (address currentAdmin, string memory currentAdminStr) = _checkTokenAdmin(ctmRwa1Addr);
        address newAdmin = _newAdminStr._stringToAddress();

        bool includeLocal = false;
        _payFee(FeeType.ADMIN, _feeTokenStr, _toChainIdsStr, includeLocal);

        for (uint256 i = 0; i < _toChainIdsStr.length; i++) {
            toChainIdStr = _toChainIdsStr[i]._toLower();

            if (toChainIdStr.equal(cIdStr)) {
                _changeAdmin(currentAdmin, newAdmin, _ID, _version);
            } else {
                (, string memory toRwaXStr) = _getRWAX(toChainIdStr, _version);

                funcCall = "adminX(uint256,uint256,string,string)";
                callData = abi.encodeWithSignature(funcCall, _ID, _version, currentAdminStr, _newAdminStr);

                _c3call(toRwaXStr, toChainIdStr, callData);

                emit ChangingAdmin(_ID, toChainIdStr);
            }
        }
    }

    /**
     * @dev Change the tokenAdmin of RWA with _ID on a chain.
     * This function can only be called by the MPC network.
     */
    function adminX(uint256 _ID, uint256 _version, string memory _oldAdminStr, string memory _newAdminStr)
        external
        onlyCaller
        returns (bool)
    {
        (bool ok, address ctmRwa1Addr) = ICTMRWAMap(ctmRwaMap).getTokenContract(_ID, RWA_TYPE, _version);
        if (!ok) {
            revert CTMRWA1X_InvalidContract(CTMRWAErrorParam.Token);
        }

        address newAdmin = _newAdminStr._stringToAddress();

        (, string memory fromChainIdStr,) = _context();
        fromChainIdStr = fromChainIdStr._toLower();

        address currentAdmin = ICTMRWA1(ctmRwa1Addr).tokenAdmin();
        address oldAdmin = _oldAdminStr._stringToAddress();
        if (currentAdmin != oldAdmin) {
            revert CTMRWA1X_InvalidAddress(CTMRWAErrorParam.Admin);
        }

        _changeAdmin(currentAdmin, newAdmin, _ID, _version);

        emit AdminChanged(_ID, _newAdminStr);

        return (true);
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
        uint256 _version,
        uint256 _slot,
        string memory _slotName,
        string[] memory _toChainIdsStr,
        string memory _feeTokenStr
    ) public {
        if (bytes(_slotName).length > 256) {
            revert CTMRWA1X_InvalidLength(CTMRWAErrorParam.SlotName);
        }
        (address ctmRwa1Addr,) = _getTokenAddr(_ID, _version);
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
                (fromAddressStr, toRwaXStr) = _getRWAX(toChainIdStr, _version);
                string memory funcCall = "createNewSlotX(uint256,uint256,string,uint256,string)";
                bytes memory callData = abi.encodeWithSignature(funcCall, _ID, _version, fromAddressStr, _slot, _slotName);

                _c3call(toRwaXStr, toChainIdStr, callData);

                emit CreateSlot(_ID, _slot, toChainIdStr);
            }
        }

        ICTMRWA1(ctmRwa1Addr).createSlotX(_slot, _slotName);
    }

    /**
     * @dev Create a new slot for RWA with ID.
     * This function is only callable by the MPC network. It checks that the tokenAdmin of the
     * RWA on the source chain is the same as the tokenAdmin of the RWA on this chain.
     */
    function createNewSlotX(uint256 _ID, uint256 _version, string memory _fromAddressStr, uint256 _slot, string memory _slotName)
        external
        onlyCaller
        returns (bool)
    {
        // (bool ok, address ctmRwa1Addr) = ICTMRWAMap(ctmRwaMap).getTokenContract(_ID, RWA_TYPE, _version);
        (address ctmRwa1Addr,) = _getTokenAddr(_ID, _version);
            
        if (ICTMRWA1(ctmRwa1Addr).slotExists(_slot)) {
            revert CTMRWA1X_SlotExists(_slot);
        }

        (, string memory fromChainIdStr,) = _context();

        address fromAddress = _fromAddressStr._stringToAddress();

        address currentAdmin = ICTMRWA1(ctmRwa1Addr).tokenAdmin();
        if (fromAddress != currentAdmin) {
            revert CTMRWA1X_InvalidAddress(CTMRWAErrorParam.Admin);
        }

        ICTMRWA1(ctmRwa1Addr).createSlotX(_slot, _slotName);

        emit SlotCreated(_ID, _slot, fromChainIdStr);

        return (true);
    }

    /**
     * @notice Transfer part of the fungible balance of a tokenId to an address on the same chain or another chain
     * @param _fromTokenId The tokenId from which to transfer. The caller must own it or be approved
     * @param _toAddressStr The address AS A STRING to which to send the value on the destination chain
     * @param _toChainIdStr The destination chainID AS A STRING. This can be the same chain as the source chain.
     * @param _value The fungible value to send. This is in wei if CTMRWA1().valueDecimals() == 18
     * @param _ID The ID of the RWA
     * @param _version The version of the RWA contract
     * @param _feeTokenStr This is fee token on the source chain (local chain) that you wish to use to pay
     * for the deployment. See the function feeTokenList in the FeeManager contract for allowable values.
     * NOTE For EVM chains, the address of the fee token must be converted to a string.
     * NOTE A new tokenId will be created for the _toAddressStr on the destination chain. They can then
     * move this balance to an existing tokenId if they wish to using CTMRWA1().transferFrom
     * @return newTokenId The tokenId that was minted.
     */
    function transferPartialTokenX(
        uint256 _fromTokenId,
        string memory _toAddressStr,
        string memory _toChainIdStr,
        uint256 _value,
        uint256 _ID,
        uint256 _version,
        string memory _feeTokenStr
    ) public nonReentrant returns (uint256) {
        string memory toChainIdStr = _toChainIdStr._toLower();

        (address ctmRwa1Addr,) = _getTokenAddr(_ID, _version);
        if (!ICTMRWA1(ctmRwa1Addr).isApprovedOrOwner(msg.sender, _fromTokenId)) {
            revert CTMRWA1X_OnlyAuthorized(CTMRWAErrorParam.Sender, CTMRWAErrorParam.ApprovedOrOwner);
        }

        if (toChainIdStr.equal(cIdStr)) {
            address toAddr = _toAddressStr._stringToAddress();
            ICTMRWA1(ctmRwa1Addr).approveFromX(address(this), _fromTokenId);
            uint256 newTokenId = ICTMRWA1(ctmRwa1Addr).transferFrom(_fromTokenId, toAddr, _value);
            ICTMRWA1(ctmRwa1Addr).approveFromX(address(0), _fromTokenId);
            ICTMRWA1XUtils(ctmRwa1XUtilsAddr).updateOwnedCtmRwa1(toAddr, ctmRwa1Addr, _version);

            return newTokenId;
        } else {
            (string memory fromAddressStr, string memory toRwaXStr) = _getRWAX(toChainIdStr, _version);

            ICTMRWA1(ctmRwa1Addr).spendAllowance(msg.sender, _fromTokenId, _value);

            _payFee(FeeType.TX, _feeTokenStr, toChainIdStr._stringToArray(), false);

            uint256 slot = ICTMRWA1(ctmRwa1Addr).slotOf(_fromTokenId);

            ICTMRWA1(ctmRwa1Addr).burnValueX(_fromTokenId, _value);

            string memory funcCall = "mintX(uint256,uint256,string,string,uint256,uint256)";

            bytes memory callData = abi.encodeWithSignature(funcCall, _ID, _version, fromAddressStr, _toAddressStr, slot, _value);

            _c3call(toRwaXStr, toChainIdStr, callData);

            return 0;
        }
    }

    /**
     * @notice Transfer a whole tokenId to an address on the same chain or another chain
     * @param _fromAddrStr The address from which to transfer the tokenId. The caller must have approval.
     * @param _toAddressStr The address AS A STRING to which to send the value on the destination chain
     * @param _toChainIdStr The destination chainID AS A STRING. This can be the same chain as the source chain.
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
        uint256 _version,
        string memory _feeTokenStr
    ) public nonReentrant {
        string memory toChainIdStr = _toChainIdStr._toLower();

        (address ctmRwa1Addr,) = _getTokenAddr(_ID, _version);
        address fromAddr = _fromAddrStr._stringToAddress();
        if (!ICTMRWA1(ctmRwa1Addr).isApprovedOrOwner(msg.sender, _fromTokenId)) {
            revert CTMRWA1X_OnlyAuthorized(CTMRWAErrorParam.Sender, CTMRWAErrorParam.ApprovedOrOwner);
        }

        if (toChainIdStr.equal(cIdStr)) {
            address toAddr = _toAddressStr._stringToAddress();
            ICTMRWA1(ctmRwa1Addr).approveFromX(address(this), _fromTokenId);
            ICTMRWA1(ctmRwa1Addr).transferFrom(fromAddr, toAddr, _fromTokenId);
            ICTMRWA1(ctmRwa1Addr).approveFromX(toAddr, _fromTokenId);
            ICTMRWA1XUtils(ctmRwa1XUtilsAddr).updateOwnedCtmRwa1(toAddr, ctmRwa1Addr, _version);
        } else {
            (, string memory toRwaXStr) = _getRWAX(toChainIdStr, _version);

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
     * @return success True if the value was minted, false otherwise.
     */
    function mintX(
        uint256 _ID,
        uint256 _version,
        string memory _fromAddressStr,
        string memory _toAddressStr,
        uint256 _slot,
        uint256 _balance
    ) external onlyCaller returns (bool) {
        (, string memory fromChainIdStr,) = _context();

        address toAddr = _toAddressStr._stringToAddress();

        (bool ok, address ctmRwa1Addr) = ICTMRWAMap(ctmRwaMap).getTokenContract(_ID, RWA_TYPE, _version);
        if (!ok) {
            revert CTMRWA1X_InvalidContract(CTMRWAErrorParam.Token);
        }

        bool slotExists = ICTMRWA1(ctmRwa1Addr).slotExists(_slot);
        if (!slotExists) {
            revert CTMRWA1X_NonExistentSlot(_slot);
        }

        string memory thisSlotName = ICTMRWA1(ctmRwa1Addr).slotName(_slot);

        ICTMRWA1(ctmRwa1Addr).mintFromX(toAddr, _slot, thisSlotName, _balance);

        ICTMRWA1XUtils(ctmRwa1XUtilsAddr).updateOwnedCtmRwa1(toAddr, ctmRwa1Addr, _version);

        emit Minted(_ID, fromChainIdStr, _fromAddressStr);

        return (true);
    }

    // End of cross chain transfers



    /// @dev Get the corresponding CTMRWA1X address on another chain with chainId _toChainIdStr
    /// @return fromAddressStr The address of the CTMRWA1X contract on this chain
    /// @return toRwaXStr The address of the CTMRWA1X contract on the destination chain
    function _getRWAX(string memory _toChainIdStr, uint256 _version) internal view returns (string memory, string memory) {
        if (_toChainIdStr.equal(cIdStr)) {
            revert CTMRWA1X_SameChain();
        }

        string memory fromAddressStr = msg.sender.toHexString()._toLower();

        (bool ok, string memory toRwaXStr) = ICTMRWAGateway(gateway).getAttachedRWAX(RWA_TYPE, _version, _toChainIdStr);
        if (!ok) {
            revert CTMRWA1X_InvalidAttachmentState();
        }

        return (fromAddressStr, toRwaXStr);
    }

    /**
     * @dev Return the tokenAdmin address for a CTMRWA1 with address _tokenAddr and
     * check that the msg.sender is the tokenAdmin and revert if not so.
     * @return currentAdmin The tokenAdmin address
     * @return currentAdminStr The string version of the tokenAdmin address
     */
    function _checkTokenAdmin(address _tokenAddr) internal returns (address, string memory) {
        address currentAdmin = ICTMRWA1(_tokenAddr).tokenAdmin();
        string memory currentAdminStr = currentAdmin.toHexString()._toLower();

        if (msg.sender != currentAdmin) {
            revert CTMRWA1X_OnlyAuthorized(CTMRWAErrorParam.Sender, CTMRWAErrorParam.Admin);
        }

        return (currentAdmin, currentAdminStr);
    }

    /// @dev Get the CTMRWA1 address and string version on this chain for an ID
    /// @param _ID The ID of the RWA token
    /// @param _version The version of the RWA contract
    /// @return tokenAddr The CTMRWA1 address on this chain for an ID
    /// @return tokenAddrStr The string version of the CTMRWA1 address on this chain for an ID
    function _getTokenAddr(uint256 _ID, uint256 _version) internal view returns (address, string memory) {
        (bool ok, address tokenAddr) = ICTMRWAMap(ctmRwaMap).getTokenContract(_ID, RWA_TYPE, _version);
        if (!ok) {
            revert CTMRWA1X_InvalidContract(CTMRWAErrorParam.Token);
        }
        if (_version > LATEST_VERSION || _version != ICTMRWA1(tokenAddr).VERSION()) {
            revert CTMRWA1X_InvalidVersion(_version);
        }
        string memory tokenAddrStr = tokenAddr.toHexString()._toLower();

        return (tokenAddr, tokenAddrStr);
    }
   

    /// @dev Pay a fee, calculated by the feeType, the fee token and the chains in question
    /// @return success True if the fee was paid, false otherwise.
    function _payFee(FeeType _feeType, string memory _feeTokenStr, string[] memory _toChainIdsStr, bool _includeLocal)
        internal
        returns (bool)
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
                revert CTMRWA1X_FailedTransfer();
            }

            IERC20(feeToken).forceApprove(feeManager, feeWei);
            IFeeManager(feeManager).payFee(feeWei, _feeTokenStr);
        }
        return (true);
    }

    function cID() internal view returns (uint256) {
        return block.chainid;
    }

    /**
     * @dev Handle failures in a cross-chain call. The logic is managed in a separate contract
     * CTMRWA1XUtils. See there for details.
     * @return ok True if the fallback was successful, false otherwise.
     */
    function _c3Fallback(bytes4 _selector, bytes calldata _data, bytes calldata _reason)
        internal
        override
        returns (bool)
    {
        bool ok = ICTMRWA1XUtils(ctmRwa1XUtilsAddr).rwa1XC3Fallback(_selector, _data, _reason, ctmRwaMap);

        return ok;
    }

}
