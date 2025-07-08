// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.22;

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
import { FeeType, IERC20Extended, IFeeManager } from "../managers/IFeeManager.sol";
import { ICTMRWA1Sentry } from "../sentry/ICTMRWA1Sentry.sol";
import { ICTMRWAMap } from "../shared/ICTMRWAMap.sol";
import { ICTMRWA1Storage, URICategory, URIType } from "../storage/ICTMRWA1Storage.sol";
import { ICTMRWA1X } from "./ICTMRWA1X.sol";

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

    /// @dev The address of the CTMRWAGateway contract
    address public gateway;

    /// @dev rwaType is the RWA type defining CTMRWA1
    uint256 rwaType;

    /// @dev version is the single integer version of this RWA type
    uint256 version;

    /// @dev The address of the FeeManager contract
    address public feeManager;

    /// @dev The address of the CTMRWADeployer contract
    address public ctmRwaDeployer;

    /// @dev The address of the CTMRWAMap contract
    address public ctmRwa1Map;

    /// @dev The address of the CTMRWA1XFallback contract
    address public fallbackAddr;

    /// @dev string representation of the chainID
    string cIDStr;

    /// @dev Addresses of routers, including ContinuumDAO, permitted to bridge tokens cross-chain
    mapping(address => bool) public isMinter;

    /// @dev tokenAdmin address => array of CTMRWA1 contracts. List of contracts controlled by each tokenAdmin
    mapping(address => address[]) public adminTokens;

    /**
     * @dev  owner address => array of CTMRWA1 contracts.
     * List  of CTMRWA1 contracts that an owner address has one or more tokenIds
     */
    mapping(address => address[]) public ownedCtmRwa1;

    uint256 constant MAX_SLOTS = 5;

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
        rwaType = 1;
        version = 1;
        feeManager = _feeManager;
        cIDStr = cID().toString();
        isMinter[address(this)] = true;
    }

    // constructor() {
    //     _disableInitializers();
    // }

    function _authorizeUpgrade(address newImplementation) internal override onlyGov { }

    /**
     * @notice Governance adds or removes a router able to bridge tokens or value cross-chain
     * @param _minter The router address
     * @param _set Boolean setting or un-setting minter
     */
    function changeMinterStatus(address _minter, bool _set) external onlyGov {
        require(_minter != address(this) && _minter != fallbackAddr, "RWAX: Cannot unset minter");
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
        require(ctmRwaDeployer != address(0), "RWAX: address ctmRwaDeployer is zero");
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
        // require(_fallbackAddr != address(this) && _fallbackAddr != address(0), "RWAX: Invalid fallBackAddr");
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
    ) public returns (uint256) {
        require(!_includeLocal && _existingID > 0 || _includeLocal && _existingID == 0, "RWAX: Incorrect call logic");
        uint256 len = bytes(_tokenName).length;
        if (_includeLocal) {
            require(len >= 10 && len <= 512, "RWAX: Token length is < 10 or > 512");
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
            require(ok, "RWAX: The token is not on this chain");
            ctmRwa1Addr = rwa1Addr;

            _checkTokenAdmin(ctmRwa1Addr);

            (, address sentryAddr) = ICTMRWAMap(ctmRwa1Map).getSentryContract(ID, _rwaType, _version);
            bool whitelist = ICTMRWA1Sentry(sentryAddr).whitelistSwitch();
            bool kyc = ICTMRWA1Sentry(sentryAddr).kycSwitch();
            require((!whitelist && !kyc), "RWAX: Whitelist or kyc set No new chains");

            tokenName = ICTMRWA1(ctmRwa1Addr).name();
            symbol = ICTMRWA1(ctmRwa1Addr).symbol();
            decimals = ICTMRWA1(ctmRwa1Addr).valueDecimals();
            baseURI = ICTMRWA1(ctmRwa1Addr).baseURI();

            (slotNumbers, slotNames) = ICTMRWA1(ctmRwa1Addr).getAllSlots();
        }

        ctmRwa1AddrStr = _toLower(ctmRwa1Addr.toHexString());

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
        (bool ok,) = ICTMRWAMap(ctmRwa1Map).getTokenContract(_ID, rwaType, version);
        require(!ok, "RWAX: ID already exists");

        bytes memory deployData = abi.encode(
            _ID, _tokenAdmin, _tokenName, _symbol, _decimals, _baseURI, _slotNumbers, _slotNames, address(this)
        );

        (address ctmRwa1Token,,,) = ICTMRWADeployer(ctmRwaDeployer).deploy(_ID, rwaType, version, deployData);

        ICTMRWA1(ctmRwa1Token).changeAdmin(_tokenAdmin);

        ok = ICTMRWA1(ctmRwa1Token).attachId(_ID, _tokenAdmin);
        require(ok, "RWAX: Could not attachId");

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
        require(!stringsEqual(_toChainIdStr, cID().toString()), "RWAX: Not cross-chain");
        address ctmRwa1Addr = stringToAddress(_ctmRwa1AddrStr);

        (, string memory currentAdminStr) = _checkTokenAdmin(ctmRwa1Addr);

        uint256 ID = ICTMRWA1(ctmRwa1Addr).ID();

        string memory toChainIdStr = _toLower(_toChainIdStr);

        (, string memory toRwaXStr) = _getRWAX(toChainIdStr);

        string memory funcCall = "deployCTMRWA1(string,uint256,string,string,uint8,string,uint256[],string[])";
        bytes memory callData = abi.encodeWithSignature(
            funcCall, currentAdminStr, ID, _tokenName, _symbol, _decimals, _baseURI, _slotNumbers, _slotNames
        );

        c3call(toRwaXStr, toChainIdStr, callData);

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
        (bool ok,) = ICTMRWAMap(ctmRwa1Map).getTokenContract(_ID, rwaType, version);
        require(!ok, "RWAX: ID already exists");

        address newAdmin = stringToAddress(_newAdminStr);

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
        (, address ctmRwa1StorageAddr) = ICTMRWAMap(ctmRwa1Map).getStorageContract(_ID, rwaType, version);
        ICTMRWA1Storage(ctmRwa1StorageAddr).setTokenAdmin(_newAdmin);

        (, address ctmRwa1SentryAddr) = ICTMRWAMap(ctmRwa1Map).getSentryContract(_ID, rwaType, version);

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
        address newAdmin = stringToAddress(_newAdminStr);

        bool includeLocal = false;
        _payFee(FeeType.ADMIN, _feeTokenStr, _toChainIdsStr, includeLocal);

        for (uint256 i = 0; i < _toChainIdsStr.length; i++) {
            toChainIdStr = _toLower(_toChainIdsStr[i]);

            if (stringsEqual(toChainIdStr, cIDStr)) {
                _changeAdmin(currentAdmin, newAdmin, _ID);
            } else {
                (, string memory toRwaXStr) = _getRWAX(toChainIdStr);

                funcCall = "adminX(uint256,string,string)";
                callData = abi.encodeWithSignature(funcCall, _ID, currentAdminStr, _newAdminStr);

                c3call(toRwaXStr, toChainIdStr, callData);

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
        (bool ok, address ctmRwa1Addr) = ICTMRWAMap(ctmRwa1Map).getTokenContract(_ID, rwaType, version);
        require(ok, "RWAX: Destination ID does not exist");

        address newAdmin = stringToAddress(_newAdminStr);

        (, string memory fromChainIdStr,) = context();
        fromChainIdStr = _toLower(fromChainIdStr);

        address currentAdmin = ICTMRWA1(ctmRwa1Addr).tokenAdmin();
        address oldAdmin = stringToAddress(_oldAdminStr);
        require(currentAdmin == oldAdmin, "RWAX: Not admin or token is locked");

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

        _payFee(FeeType.MINT, _feeTokenStr, _stringToArray(cIDStr), false);

        if (_toTokenId > 0) {
            ICTMRWA1(ctmRwa1Addr).mintValueX(_toTokenId, _slot, _value);
            return (_toTokenId);
        } else {
            bool slotExists = ICTMRWA1(ctmRwa1Addr).slotExists(_slot);
            require(slotExists, "RWAX: Slot not exist");
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
        require(bytes(_slotName).length <= 256, "RWAX: Slot > 256");
        (address ctmRwa1Addr,) = _getTokenAddr(_ID);
        require(!ICTMRWA1(ctmRwa1Addr).slotExists(_slot), "RWAX: Slot that already exists");
        require(ICTMRWA1(ctmRwa1Addr).slotCount() < MAX_SLOTS, "RWAX: Too many slots");

        _checkTokenAdmin(ctmRwa1Addr);

        string memory toChainIdStr;
        string memory toRwaXStr;
        string memory fromAddressStr;

        _payFee(FeeType.ADMIN, _feeTokenStr, _toChainIdsStr, true);

        uint256 len = _toChainIdsStr.length;

        for (uint256 i = 0; i < len; i++) {
            toChainIdStr = _toLower(_toChainIdsStr[i]);
            if (!stringsEqual(cIDStr, toChainIdStr)) {
                (fromAddressStr, toRwaXStr) = _getRWAX(toChainIdStr);
                string memory funcCall = "createNewSlotX(uint256,string,uint256,string)";
                bytes memory callData = abi.encodeWithSignature(funcCall, _ID, fromAddressStr, _slot, _slotName);

                c3call(toRwaXStr, toChainIdStr, callData);

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
        (bool ok, address ctmRwa1Addr) = ICTMRWAMap(ctmRwa1Map).getTokenContract(_ID, rwaType, version);
        require(ok, "RWAX: ID does not exist");
        require(!ICTMRWA1(ctmRwa1Addr).slotExists(_slot), "RWAX: Slot that already exists");

        (, string memory fromChainIdStr,) = context();

        address fromAddress = stringToAddress(_fromAddressStr);

        address currentAdmin = ICTMRWA1(ctmRwa1Addr).tokenAdmin();
        require(fromAddress == currentAdmin, "RWAX: Only tokenAdmin can add slots, or locked");

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
    ) public returns (uint256) {
        string memory toChainIdStr = _toLower(_toChainIdStr);

        (address ctmRwa1Addr, string memory ctmRwa1AddrStr) = _getTokenAddr(_ID);
        require(ICTMRWA1(ctmRwa1Addr).isApprovedOrOwner(msg.sender, _fromTokenId), "RWAX: Not approved or owner");

        if (stringsEqual(toChainIdStr, cIDStr)) {
            address toAddr = stringToAddress(_toAddressStr);
            ICTMRWA1(ctmRwa1Addr).approveFromX(address(this), _fromTokenId);
            uint256 newTokenId = ICTMRWA1(ctmRwa1Addr).transferFrom(_fromTokenId, toAddr, _value);
            ICTMRWA1(ctmRwa1Addr).approveFromX(address(0), _fromTokenId);
            _updateOwnedCtmRwa1(toAddr, ctmRwa1Addr);

            return newTokenId;
        } else {
            (string memory fromAddressStr, string memory toRwaXStr) = _getRWAX(toChainIdStr);

            ICTMRWA1(ctmRwa1Addr).spendAllowance(msg.sender, _fromTokenId, _value);

            _payFee(FeeType.TX, _feeTokenStr, _stringToArray(toChainIdStr), false);

            uint256 slot = ICTMRWA1(ctmRwa1Addr).slotOf(_fromTokenId);

            ICTMRWA1(ctmRwa1Addr).burnValueX(_fromTokenId, _value);

            string memory funcCall = "mintX(uint256,string,string,uint256,uint256,uint256,string)";

            bytes memory callData = abi.encodeWithSignature(
                funcCall, _ID, fromAddressStr, _toAddressStr, _fromTokenId, slot, _value, ctmRwa1AddrStr
            );

            c3call(toRwaXStr, toChainIdStr, callData);

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
    ) public {
        string memory toChainIdStr = _toLower(_toChainIdStr);

        (address ctmRwa1Addr, string memory ctmRwa1AddrStr) = _getTokenAddr(_ID);
        address fromAddr = stringToAddress(_fromAddrStr);
        require(ICTMRWA1(ctmRwa1Addr).isApprovedOrOwner(msg.sender, _fromTokenId), "RWAX: Not owner/approved");

        if (stringsEqual(toChainIdStr, cIDStr)) {
            address toAddr = stringToAddress(_toAddressStr);
            ICTMRWA1(ctmRwa1Addr).approveFromX(address(this), _fromTokenId);
            ICTMRWA1(ctmRwa1Addr).transferFrom(fromAddr, toAddr, _fromTokenId);
            ICTMRWA1(ctmRwa1Addr).approveFromX(toAddr, _fromTokenId);
            _updateOwnedCtmRwa1(toAddr, ctmRwa1Addr);
        } else {
            (, string memory toRwaXStr) = _getRWAX(toChainIdStr);

            _payFee(FeeType.TX, _feeTokenStr, _stringToArray(toChainIdStr), false);

            (, uint256 value,, uint256 slot,,) = ICTMRWA1(ctmRwa1Addr).getTokenInfo(_fromTokenId);

            ICTMRWA1(ctmRwa1Addr).approveFromX(address(0), _fromTokenId);
            ICTMRWA1(ctmRwa1Addr).clearApprovedValues(_fromTokenId);

            ICTMRWA1(ctmRwa1Addr).removeTokenFromOwnerEnumeration(msg.sender, _fromTokenId);

            string memory funcCall = "mintX(uint256,string,string,uint256,uint256,uint256,string)";
            bytes memory callData = abi.encodeWithSignature(
                funcCall, _ID, _fromAddrStr, _toAddressStr, _fromTokenId, slot, value, ctmRwa1AddrStr
            );

            c3call(toRwaXStr, toChainIdStr, callData);

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
        uint256 _fromTokenId,
        uint256 _slot,
        uint256 _balance,
        string memory _fromTokenStr
    ) external onlyCaller returns (bool) {
        (, string memory fromChainIdStr,) = context();

        address toAddr = stringToAddress(_toAddressStr);

        (bool ok, address ctmRwa1Addr) = ICTMRWAMap(ctmRwa1Map).getTokenContract(_ID, rwaType, version);
        require(ok, "RWAX: ID does not exist");

        bool slotExists = ICTMRWA1(ctmRwa1Addr).slotExists(_slot);
        require(slotExists, "RWAX: Slot does not exist");

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
        (bool ok, address tokenAddr) = ICTMRWAMap(ctmRwa1Map).getTokenContract(_ID, rwaType, version);
        require(ok, "RWAX: tokenID not exist");
        string memory tokenAddrStr = _toLower(tokenAddr.toHexString());

        return (tokenAddr, tokenAddrStr);
    }

    /// @dev Get the corresponding CTMRWA1X address on another chain with chainId _toChainIdStr
    function _getRWAX(string memory _toChainIdStr) internal view returns (string memory, string memory) {
        require(!stringsEqual(_toChainIdStr, cIDStr), "RWAX: Not Xchain");

        string memory fromAddressStr = _toLower(msg.sender.toHexString());

        (bool ok, string memory toRwaXStr) = ICTMRWAGateway(gateway).getAttachedRWAX(rwaType, version, _toChainIdStr);
        require(ok, "RWAX: Address not found");

        return (fromAddressStr, toRwaXStr);
    }

    /**
     * @dev Return the tokenAdmin address for a CTMRWA1 with address _tokenAddr and
     * check that the msg.sender is the tokenAdmin and revert if not so.
     */
    function _checkTokenAdmin(address _tokenAddr) internal returns (address, string memory) {
        address currentAdmin = ICTMRWA1(_tokenAddr).tokenAdmin();
        string memory currentAdminStr = _toLower(currentAdmin.toHexString());

        require(msg.sender == currentAdmin, "RWAX: Not tokenAdmin or locked");

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
        uint256 fee = IFeeManager(feeManager).getXChainFee(_toChainIdsStr, _includeLocal, _feeType, _feeTokenStr);

        // TODO Remove hardcoded multiplier 10**2

        if (fee > 0) {
            address feeToken = stringToAddress(_feeTokenStr);
            uint256 feeWei = fee * 10 ** (IERC20Extended(feeToken).decimals() - 2);

            IERC20(feeToken).transferFrom(msg.sender, address(this), feeWei);

            IERC20(feeToken).approve(feeManager, feeWei);
            IFeeManager(feeManager).payFee(feeWei, _feeTokenStr);
        }
        return (true);
    }

    function cID() internal view returns (uint256) {
        return block.chainid;
    }

    /// @dev Convert a string to an EVM address. Also checks the string length
    function stringToAddress(string memory str) internal pure returns (address) {
        bytes memory strBytes = bytes(str);
        require(strBytes.length == 42, "RWAX: Invalid addr length");
        bytes memory addrBytes = new bytes(20);

        for (uint256 i = 0; i < 20; i++) {
            addrBytes[i] = bytes1(hexCharToByte(strBytes[2 + i * 2]) * 16 + hexCharToByte(strBytes[3 + i * 2]));
        }

        return address(uint160(bytes20(addrBytes)));
    }

    function hexCharToByte(bytes1 char) internal pure returns (uint8) {
        uint8 byteValue = uint8(char);
        if (byteValue >= uint8(bytes1("0")) && byteValue <= uint8(bytes1("9"))) {
            return byteValue - uint8(bytes1("0"));
        } else if (byteValue >= uint8(bytes1("a")) && byteValue <= uint8(bytes1("f"))) {
            return 10 + byteValue - uint8(bytes1("a"));
        } else if (byteValue >= uint8(bytes1("A")) && byteValue <= uint8(bytes1("F"))) {
            return 10 + byteValue - uint8(bytes1("A"));
        }
        revert("Invalid hex character");
    }

    /// @dev Check if two strings are equal (in fact if their hashes are equal)
    function stringsEqual(string memory a, string memory b) internal pure returns (bool) {
        bytes32 ka = keccak256(abi.encode(a));
        bytes32 kb = keccak256(abi.encode(b));
        return (ka == kb);
    }

    /// @dev Convert a string to lower case
    function _toLower(string memory str) internal pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint256 i = 0; i < bStr.length; i++) {
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

    /// @dev Convert an individual string to an array with a single value
    function _stringToArray(string memory _string) internal pure returns (string[] memory) {
        string[] memory strArray = new string[](1);
        strArray[0] = _string;
        return (strArray);
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
