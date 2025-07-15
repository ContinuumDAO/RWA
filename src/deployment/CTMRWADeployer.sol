// SPDX-License-Identifier: BSL-1.1

pragma solidity ^0.8.22;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import { C3GovernDapp } from "@c3caller/gov/C3GovernDapp.sol";

import { ICTMRWA1 } from "../core/ICTMRWA1.sol";
import { ICTMRWADeployInvest } from "./ICTMRWADeployInvest.sol";
import { ICTMRWA1TokenFactory } from "./ICTMRWA1TokenFactory.sol";
import { ICTMRWAMap } from "../shared/ICTMRWAMap.sol";
import { ICTMRWADeployer } from "./ICTMRWADeployer.sol";
import {Address, RWA} from "../CTMRWAUtils.sol";

/**
 * @title AssetX Multi-chain Semi-Fungible-Token for Real-World-Assets (RWAs)
 * @author @Selqui ContinuumDAO
 *
 * @notice The deploy function in this contract is called by CTMRWA1X on each chain that an
 * RWA is deployed to. It calls other contracts that use CREATE2 to deploy the suite of contracts for the RWA.
 * These are CTMRWA1TokenFactory to deploy CTMRWA1, CTMRWA1StorageManager to deploy CTMRWA1Storage,
 * CTMRWA1DividendFactory to deploy CTMRWA1Dividend and CTMRWA1SentryManager to deploy CTMRWA1Sentry.
 * This unique set of contracts is deployed for every ID and then the contract addresses are stored in CTMRWAMap.
 * The contracts that do the deployment can be updated by Governance, with different addresses dependent on
 * the rwaType and version. The data passed to CTMRWA1TokenFactory is abi encoded deployData for maximum
 * flexibility for future types of RWA.
 *
 * This contract is only deployed ONCE on each chain and manages all CTMRWA1 contract interactions
 */
contract CTMRWADeployer is ICTMRWADeployer, C3GovernDapp, UUPSUpgradeable {
    using Strings for *;

    /// @dev The address of the CTMRWAGateway contract
    address public gateway;

    /// @dev The address the FeeManager contract
    address public feeManager;

    /// @dev The address of the CTMRWA1X contract
    address public rwaX;

    /// @dev The address of the CTMRWAMap contract
    address public ctmRwaMap;

    /// @dev The address of the CTMRWAERC20Deployer contract
    address public erc20Deployer;

    /// @dev The address of the CTMRWADeployInvest contract
    address public deployInvest;

    /// @dev Storage for the addresses of the CTMRWA1TokenFactory contracts
    mapping(uint256 => address[1_000_000_000]) public tokenFactory;

    /// @dev Storage for the addresses of the CTMRWA1DividendFactory addresses
    mapping(uint256 => address[1_000_000_000]) public dividendFactory;

    /// @dev Storage for the addresses of the CTMRWA1StorageManager addresses
    mapping(uint256 => address[1_000_000_000]) public storageFactory;

    /// @dev Storage for the addresses of the CTMRWA1SentryManager addresses
    mapping(uint256 => address[1_000_000_000]) public sentryFactory;

    event LogFallback(bytes4 selector, bytes data, bytes reason);

    modifier onlyRwaX() {
        // require(msg.sender == rwaX, "CTMRWADeployer: OnlyRwaX function");
        if (msg.sender != rwaX) revert CTMRWADeployer_Unauthorized(Address.Sender);
        _;
    }

    function initialize(
        address _gov,
        address _gateway,
        address _feeManager,
        address _rwaX,
        address _map,
        address _c3callerProxy,
        address _txSender,
        uint256 _dappID
    ) external initializer {
        __C3GovernDapp_init(_gov, _c3callerProxy, _txSender, _dappID);
        gateway = _gateway;
        feeManager = _feeManager;
        rwaX = _rwaX;
        ctmRwaMap = _map;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyGov { }

    /// @notice Governance function to change the CTMRWAGateway contract address
    function setGateway(address _gateway) external onlyGov {
        gateway = _gateway;
    }

    /// @notice Governance function to change the FeeManager contract address
    function setFeeManager(address _feeManager) external onlyGov {
        feeManager = _feeManager;
    }

    /// @notice Governance function to change the CTMRWA1X contract address
    function setRwaX(address _rwaX) external onlyGov {
        rwaX = _rwaX;
    }

    function setMap(address _ctmRwaMap) external onlyGov {
        ctmRwaMap = _ctmRwaMap;
    }

    /**
     * @notice Governance can change to a new CTMRWAERC20Deployer contract
     * @param _erc20Deployer address of the new CTMRWAERC20Deployer contract
     */
    function setErc20DeployerAddress(address _erc20Deployer) external onlyGov {
        erc20Deployer = _erc20Deployer;
    }

    /// @notice Governance function to change the CTMRWADeployInvest contract address
    function setDeployInvest(address _deployInvest) external onlyGov {
        deployInvest = _deployInvest;
    }

    /// @notice Governance function to set the CTMRWADeployInvest contract addresses
    /// @notice for this contract (CTMRWADeployer), CTMRWAMap and FeeManager
    function setDeployerMapFee() external onlyGov {
        ICTMRWADeployInvest(deployInvest).setDeployerMapFee(address(this), ctmRwaMap, feeManager);
    }

    /// @dev The main deploy function that calls the various deploy functions that call CREATE2 for this ID
    function deploy(uint256 _ID, uint256 _rwaType, uint256 _version, bytes memory deployData)
        external
        onlyRwaX
        virtual
        returns (address, address, address, address)
    {
        address tokenAddr = ICTMRWA1TokenFactory(tokenFactory[_rwaType][_version]).deploy(deployData);

        // require(ICTMRWA1(tokenAddr).RWA_TYPE() == _rwaType, "CTMRWADeployer: Wrong RWA type");
        if (ICTMRWA1(tokenAddr).RWA_TYPE() != _rwaType) revert CTMRWADeployer_IncompatibleRWA(RWA.Type);
        // require(ICTMRWA1(tokenAddr).VERSION() == _version, "CTMRWADeployer: Wrong RWA version");
        if (ICTMRWA1(tokenAddr).VERSION() != _version) revert CTMRWADeployer_IncompatibleRWA(RWA.Version);

        address dividendAddr = deployDividend(_ID, tokenAddr, _rwaType, _version);
        address storageAddr = deployStorage(_ID, tokenAddr, _rwaType, _version);
        address sentryAddr = deploySentry(_ID, tokenAddr, _rwaType, _version);

        ICTMRWAMap(ctmRwaMap).attachContracts(_ID, tokenAddr, dividendAddr, storageAddr, sentryAddr);

        return (tokenAddr, dividendAddr, storageAddr, sentryAddr);
    }

    /// @dev Calls the contract function to deploy the CTMRWA1Dividend for this _ID
    function deployDividend(uint256 _ID, address _tokenAddr, uint256 _rwaType, uint256 _version)
        internal
        returns (address)
    {
        if (dividendFactory[_rwaType][_version] != address(0)) {
            address dividendAddr = ICTMRWA1TokenFactory(dividendFactory[_rwaType][_version]).deployDividend(
                _ID, _tokenAddr, _rwaType, _version, ctmRwaMap
            );
            return (dividendAddr);
        } else {
            return (address(0));
        }
    }

    /// @dev Calls the contract function to deploy the CTMRWA1Storage for this _ID
    function deployStorage(uint256 _ID, address _tokenAddr, uint256 _rwaType, uint256 _version)
        internal
        returns (address)
    {
        if (storageFactory[_rwaType][_version] != address(0)) {
            address storageAddr = ICTMRWA1TokenFactory(storageFactory[_rwaType][_version]).deployStorage(
                _ID, _tokenAddr, _rwaType, _version, ctmRwaMap
            );
            return (storageAddr);
        } else {
            return (address(0));
        }
    }

    /// @notice Governance function to change the CTMRWA1Sentry contract address
    function deploySentry(uint256 _ID, address _tokenAddr, uint256 _rwaType, uint256 _version)
        internal
        returns (address)
    {
        if (sentryFactory[_rwaType][_version] != address(0)) {
            address sentryAddr = ICTMRWA1TokenFactory(sentryFactory[_rwaType][_version]).deploySentry(
                _ID, _tokenAddr, _rwaType, _version, ctmRwaMap
            );
            return (sentryAddr);
        } else {
            return (address(0));
        }
    }

    /// @dev Governance function to set a new CTMRWA1TokenFactory
    function setTokenFactory(uint256 _rwaType, uint256 _version, address _tokenFactory) external onlyGov {
        tokenFactory[_rwaType][_version] = _tokenFactory;
    }

    /// @dev Governance function to set a new CTMRWA1DividendFactory
    function setDividendFactory(uint256 _rwaType, uint256 _version, address _dividendFactory) external onlyGov {
        dividendFactory[_rwaType][_version] = _dividendFactory;
    }

    /// @dev Governance function to set a new CTMRWA1StorageManager
    function setStorageFactory(uint256 _rwaType, uint256 _version, address _storageFactory) external onlyGov {
        storageFactory[_rwaType][_version] = _storageFactory;
    }

    /// @dev Governance function to set a new CTMRWA1SentryManager
    function setSentryFactory(uint256 _rwaType, uint256 _version, address _sentryFactory) external onlyGov {
        sentryFactory[_rwaType][_version] = _sentryFactory;
    }

    /// @dev Governance function to set the commission rate on funds raised
    /// @param _commissionRate ia number between 0 and 10000, so in 0.01% increments
    function setInvestCommissionRate(uint256 _commissionRate) external onlyGov {
        ICTMRWADeployInvest(deployInvest).setCommissionRate(_commissionRate);
    }

    function deployNewInvestment(uint256 _ID, uint256 _rwaType, uint256 _version, address _feeToken)
        public
        returns (address)
    {
        (bool ok,) = ICTMRWAMap(ctmRwaMap).getInvestContract(_ID, _rwaType, _version);
        // require(!ok, "CTMDeploy: Investment contract already deployed"); 
        if (ok) revert CTMRWADeployer_InvalidContract(Address.Invest);

        // require(deployInvest != address(0), "CTMDeployer: deployInvest address not set");
        if (deployInvest == address(0)) revert CTMRWADeployer_IsZeroAddress(Address.DeployInvest);

        address investAddress = ICTMRWADeployInvest(deployInvest).deployInvest(_ID, _rwaType, _version, _feeToken);
        ICTMRWAMap(ctmRwaMap).setInvestmentContract(_ID, _rwaType, _version, investAddress);

        return investAddress;
    }

    function cID() internal view returns (uint256) {
        return block.chainid;
    }

    /// @dev Fallback function for failed c3call cross-chain. Only emits an event at present
    function _c3Fallback(bytes4 _selector, bytes calldata _data, bytes calldata _reason)
        internal
        override
        returns (bool)
    {
        emit LogFallback(_selector, _data, _reason);
        return true;
    }
}
