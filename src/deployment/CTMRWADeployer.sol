// SPDX-License-Identifier: BSL-1.1

pragma solidity 0.8.27;

import { ICTMRWA1 } from "../core/ICTMRWA1.sol";
import { ICTMRWA1DividendFactory } from "../dividend/ICTMRWA1DividendFactory.sol";
import { ICTMRWA1SentryManager } from "../sentry/ICTMRWA1SentryManager.sol";
import { ICTMRWAMap } from "../shared/ICTMRWAMap.sol";
import { ICTMRWA1StorageManager } from "../storage/ICTMRWA1StorageManager.sol";
import { CTMRWAProxy } from "../utils/CTMRWAProxy.sol";
import { CTMRWAErrorParam } from "../utils/CTMRWAUtils.sol";
import { ICTMRWA1TokenFactory } from "./ICTMRWA1TokenFactory.sol";
import { ICTMRWADeployInvest } from "./ICTMRWADeployInvest.sol";
import { ICTMRWADeployer } from "./ICTMRWADeployer.sol";
import { C3GovernDAppUpgradeable } from "@c3caller/upgradeable/gov/C3GovernDAppUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";


/**
 * @title AssetX Multi-chain Semi-Fungible-Token for Real-World-Assets (RWAs)
 * @author @Selqui ContinuumDAO
 *
 * @notice The deploy function in this contract is called by CTMRWA1X on each chain that an
 * CTMRWAErrorParam is deployed to. It calls other contracts that use CREATE2 to deploy the suite of contracts for the CTMRWAErrorParam.
 * These are CTMRWA1TokenFactory to deploy CTMRWA1, CTMRWA1StorageManager to deploy CTMRWA1Storage,
 * CTMRWA1DividendFactory to deploy CTMRWA1Dividend and CTMRWA1SentryManager to deploy CTMRWA1Sentry.
 * This unique set of contracts is deployed for every ID and then the contract addresses are stored in CTMRWAMap.
 * The contracts that do the deployment can be updated by Governance, with different addresses dependent on
 * the rwaType and version. The data passed to CTMRWA1TokenFactory is abi encoded deployData for maximum
 * flexibility for future types of CTMRWAErrorParam.
 *
 * This contract is only deployed ONCE on each chain and manages all CTMRWA1 contract interactions
 */
contract CTMRWADeployer is ICTMRWADeployer, C3GovernDAppUpgradeable, UUPSUpgradeable {
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

    /// @dev The timestamp of the last commission rate change
    uint256 public lastCommissionRateChange;

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
        if (msg.sender != rwaX) {
            revert CTMRWADeployer_OnlyAuthorized(CTMRWAErrorParam.Sender, CTMRWAErrorParam.RWAX);
        }
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
        __C3GovernDApp_init(_gov, _c3callerProxy, _txSender, _dappID);
        gateway = _gateway;
        feeManager = _feeManager;
        rwaX = _rwaX;
        ctmRwaMap = _map;
        lastCommissionRateChange = 0;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyGov { }

    /// @notice Governance function to change the CTMRWAGateway contract address
    function setGateway(address _gateway) external onlyGov {
        if (_gateway == address(0)) {
            revert CTMRWADeployer_IsZeroAddress(CTMRWAErrorParam.Gateway);
        }
        gateway = _gateway;
    }

    /// @notice Governance function to change the FeeManager contract address
    function setFeeManager(address _feeManager) external onlyGov {
        if (_feeManager == address(0)) {
            revert CTMRWADeployer_IsZeroAddress(CTMRWAErrorParam.FeeManager);
        }
        feeManager = _feeManager;
    }

    /// @notice Governance function to change the CTMRWA1X contract address
    function setRwaX(address _rwaX) external onlyGov {
        if (_rwaX == address(0)) {
            revert CTMRWADeployer_IsZeroAddress(CTMRWAErrorParam.RWAX);
        }
        rwaX = _rwaX;
    }

    function setMap(address _ctmRwaMap) external onlyGov {
        if (_ctmRwaMap == address(0)) {
            revert CTMRWADeployer_IsZeroAddress(CTMRWAErrorParam.Map);
        }
        ctmRwaMap = _ctmRwaMap;
    }

    /**
     * @notice Governance can change to a new CTMRWAERC20Deployer contract
     * @param _erc20Deployer address of the new CTMRWAERC20Deployer contract
     */
    function setErc20DeployerAddress(address _erc20Deployer) external onlyGov {
        if (_erc20Deployer == address(0)) {
            revert CTMRWADeployer_IsZeroAddress(CTMRWAErrorParam.ERC20Deployer);
        }
        erc20Deployer = _erc20Deployer;
    }

    /// @notice Governance function to change the CTMRWADeployInvest contract address
    function setDeployInvest(address _deployInvest) external onlyGov {
        if (_deployInvest == address(0)) {
            revert CTMRWADeployer_IsZeroAddress(CTMRWAErrorParam.DeployInvest);
        }
        deployInvest = _deployInvest;
    }

    /// @notice Governance function to set the CTMRWADeployInvest contract addresses
    /// for this contract (CTMRWADeployer), CTMRWAMap and FeeManager
    function setDeployerMapFee() external onlyGov {
        ICTMRWADeployInvest(deployInvest).setDeployerMapFee(address(this), ctmRwaMap, feeManager);
    }

    /// @dev The main deploy function that calls the various deploy functions that call CREATE2 for this ID
    function deploy(uint256 _ID, uint256 _rwaType, uint256 _version, bytes memory deployData)
        external
        virtual
        onlyRwaX
        returns (address, address, address, address)
    {
        address tokenAddr = ICTMRWA1TokenFactory(tokenFactory[_rwaType][_version]).deploy(_rwaType, _version, deployData);

        if (ICTMRWA1(tokenAddr).RWA_TYPE() != _rwaType) {
            revert CTMRWADeployer_IncompatibleRWA(CTMRWAErrorParam.Type);
        }
        if (ICTMRWA1(tokenAddr).VERSION() != _version) {
            revert CTMRWADeployer_IncompatibleRWA(CTMRWAErrorParam.Version);
        }

        address dividendAddr = dividendDeployer(_ID, tokenAddr, _rwaType, _version);
        address storageAddr = storageDeployer(_ID, tokenAddr, _rwaType, _version);
        address sentryAddr = sentryDeployer(_ID, tokenAddr, _rwaType, _version);

        ICTMRWAMap(ctmRwaMap).attachContracts(_ID, tokenAddr, dividendAddr, storageAddr, sentryAddr);

        return (tokenAddr, dividendAddr, storageAddr, sentryAddr);
    }

    /// @dev Calls the contract function to deploy the CTMRWA1Dividend for this _ID
    function dividendDeployer(uint256 _ID, address _tokenAddr, uint256 _rwaType, uint256 _version)
        internal
        returns (address)
    {
        if (dividendFactory[_rwaType][_version] != address(0)) {
            address dividendAddr = ICTMRWA1DividendFactory(dividendFactory[_rwaType][_version]).deployDividend(
                _ID, _tokenAddr, _rwaType, _version, ctmRwaMap
            );
            return (dividendAddr);
        } else {
            return (address(0));
        }
    }

    /// @dev Calls the contract function to deploy the CTMRWA1Storage for this _ID
    function storageDeployer(uint256 _ID, address _tokenAddr, uint256 _rwaType, uint256 _version)
        internal
        returns (address)
    {
        if (storageFactory[_rwaType][_version] != address(0)) {
            address storageAddr = ICTMRWA1StorageManager(storageFactory[_rwaType][_version]).deployStorage(
                _ID, _tokenAddr, _rwaType, _version, ctmRwaMap
            );
            return (storageAddr);
        } else {
            return (address(0));
        }
    }

    /// @notice Governance function to change the CTMRWA1Sentry contract address
    function sentryDeployer(uint256 _ID, address _tokenAddr, uint256 _rwaType, uint256 _version)
        internal
        returns (address)
    {
        if (sentryFactory[_rwaType][_version] != address(0)) {
            address sentryAddr = ICTMRWA1SentryManager(sentryFactory[_rwaType][_version]).deploySentry(
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
    /// @dev the commission rate can only be increased by 100 or more (1%)
    /// @dev the commission rate can only be increased every 30 days, but can be decreased at any time
    function setInvestCommissionRate(uint256 _commissionRate) external onlyGov {
        if (deployInvest == address(0)) {
            revert CTMRWADeployer_IsZeroAddress(CTMRWAErrorParam.DeployInvest);
        }

        uint256 commissionRate = ICTMRWADeployInvest(deployInvest).commissionRate();

        if (_commissionRate > 10000) {
            revert CTMRWADeployer_CommissionRateOutOfBounds(CTMRWAErrorParam.Commission);
        } else if (_commissionRate > commissionRate + 100) {
            revert CTMRWADeployer_CommissionRateIncreasedTooMuch(CTMRWAErrorParam.Commission);
        } else if (_commissionRate > commissionRate && lastCommissionRateChange != 0 && block.timestamp - lastCommissionRateChange < 30 days) {
            revert CTMRWADeployer_CommissionRateChangeTooSoon(CTMRWAErrorParam.Commission);
        }

        ICTMRWADeployInvest(deployInvest).setCommissionRate(_commissionRate);

        lastCommissionRateChange = block.timestamp;
        emit CommissionRateChanged(_commissionRate);
    }

    /// @dev Get the commission rate on funds raised
    function getInvestCommissionRate() external view returns (uint256) {
        return ICTMRWADeployInvest(deployInvest).commissionRate();
    }

    /// @dev Get the timestamp of the last commission rate change
    function getLastCommissionRateChange() external view returns (uint256) {
        if (deployInvest == address(0)) {
            revert CTMRWADeployer_IsZeroAddress(CTMRWAErrorParam.DeployInvest);
        }

        return lastCommissionRateChange;
    }

    /**
     * @notice Deploy a new CTMRWA1Invest contract. Anyone can call this, but only tokenAdmin
     * can create an offering and collect invested funds
     * @param _ID The ID of the CTMRWAErrorParam token
     * @param _rwaType The type of CTMRWAErrorParam (set to 1 for CTMRWA1)
     * @param _version The version of CTMRWAErrorParam (set to 1 for current version)
     * @param _feeToken CTMRWAErrorParam of a valid fee token. See getFeeTokenList in FeeManager.
     * NOTE only one CTMRWA1Invest contract can be deployed on each chain.
     */
    function deployNewInvestment(uint256 _ID, uint256 _rwaType, uint256 _version, address _feeToken)
        public
        returns (address)
    {
        (bool ok,) = ICTMRWAMap(ctmRwaMap).getInvestContract(_ID, _rwaType, _version);
        if (ok) {
            revert CTMRWADeployer_InvalidContract(CTMRWAErrorParam.Invest);
        }

        if (deployInvest == address(0)) {
            revert CTMRWADeployer_IsZeroAddress(CTMRWAErrorParam.DeployInvest);
        }

        address investAddress = ICTMRWADeployInvest(deployInvest).deployInvest(_ID, _rwaType, _version, _feeToken, msg.sender);
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
