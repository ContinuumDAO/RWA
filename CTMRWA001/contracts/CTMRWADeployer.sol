// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;


import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import {GovernDapp} from "./routerV2/GovernDapp.sol";

import {ICTMRWA001} from "./interfaces/ICTMRWA001.sol";
import {ICTMRWAFactory} from "./interfaces/ICTMRWAFactory.sol";
import {ICTMRWAMap} from "./interfaces/ICTMRWAMap.sol";
import {ICTMRWADeployInvest} from "./interfaces/ICTMRWADeployInvest.sol";

/**
 * @title AssetX Multi-chain Semi-Fungible-Token for Real-World-Assets (RWAs)
 * @author @Selqui ContinuumDAO
 *
 * @notice The deploy function in this contract is called by CTMRWA001X on each chain that an 
 * RWA is deployed to. It calls other contracts that use CREATE2 to deploy the suite of contracts for the RWA.
 * These are CTMRWA001TokenFactory to deploy CTMRWA001, CTMRWA001StorageManager to deploy CTMRWA001Storage,
 * CTMRWA001DividendFactory to deploy CTMRWA001Dividend and CTMRWA001SentryManager to deploy CTMRWA001Sentry.
 * This unique set of contracts is deployed for every ID and then the contract addresses are stored in CTMRWAMap.
 * The contracts that do the deployment can be updated by Governance, with different addresses dependent on
 * the rwaType and version. The data passed to CTMRWA001TokenFactory is abi encoded deployData for maximum
 * flexibility for future types of RWA.
 *
 * This contract is only deployed ONCE on each chain and manages all CTMRWA001 contract interactions
 */

contract CTMRWADeployer is Context, GovernDapp {
    using Strings for *;

    /// @dev The address of the CTMRWAGateway contract
    address gateway;

    /// @dev The address the FeeManager contract
    address feeManager;

    /// @dev The address of the CTMRWA001X contract
    address public rwaX;

    /// @dev The address of the CTMRWAMap contract
    address public ctmRwaMap;

    /// @dev The address of the CTMRWAERC20Deployer contract
    address public erc20Deployer;

    /// @dev The address of the CTMRWADeployInvest contract
    address public deployInvest;

    /// @dev Storage for the addresses of the CTMRWA001TokenFactory contracts
    mapping(uint256 => address[1_000_000_000]) public tokenFactory;

    /// @dev Storage for the addresses of the CTMRWA001DividendFactory addresses
    mapping(uint256 => address[1_000_000_000]) public dividendFactory;

    /// @dev Storage for the addresses of the CTMRWA001StorageManager addresses
    mapping(uint256 => address[1_000_000_000]) public storageFactory;

    /// @dev Storage for the addresses of the CTMRWA001SentryManager addresses
    mapping(uint256 => address[1_000_000_000]) public sentryFactory;


    event LogFallback(bytes4 selector, bytes data, bytes reason);

    modifier onlyRwaX {
        require(_msgSender() == rwaX, "CTMRWADeployer: OnlyRwaX function");
        _;
    }

    constructor(
        address _gov,
        address _gateway,
        address _feeManager,
        address _rwaX,
        address _map,
        address _c3callerProxy,
        address _txSender,
        uint256 _dappID
    ) GovernDapp(_gov, _c3callerProxy, _txSender, _dappID) {
        gateway = _gateway;
        feeManager = _feeManager;
        rwaX = _rwaX;
        ctmRwaMap = _map;
    }

    /// @notice Governance function to change the CTMRWAGateway contract address
    function setGateway(address _gateway) external onlyGov {
        gateway = _gateway;
    }

    /// @notice Governance function to change the FeeManager contract address
    function setFeeManager(address _feeManager) external onlyGov {
        feeManager = _feeManager;
    }

    /// @notice Governance function to change the CTMRWA001X contract address
    function setRwaX(address _rwaX) external onlyGov {
        rwaX = _rwaX;
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
    function deploy(
        uint256 _ID,
        uint256 _rwaType,
        uint256 _version,
        bytes memory deployData
    ) external onlyRwaX returns(address, address, address, address) {
        address tokenAddr = ICTMRWAFactory(tokenFactory[_rwaType][_version]).deploy(deployData);

        require(ICTMRWA001(tokenAddr).rwaType() == _rwaType, "CTMRWADeployer: Wrong RWA type");
        require(ICTMRWA001(tokenAddr).version() == _version, "CTMRWADeployer: Wrong RWA version");
        
        address dividendAddr = deployDividend(_ID, tokenAddr, _rwaType, _version);
        address storageAddr = deployStorage(_ID, tokenAddr, _rwaType, _version);
        address sentryAddr = deploySentry(_ID, tokenAddr, _rwaType, _version);

        ICTMRWAMap(ctmRwaMap).attachContracts(_ID, _rwaType, _version, tokenAddr, dividendAddr, storageAddr, sentryAddr);

        return(tokenAddr, dividendAddr, storageAddr, sentryAddr);
    }

    /// @dev Calls the contract function to deploy the CTMRWA001Dividend for this _ID
    function deployDividend(
        uint256 _ID,
        address _tokenAddr,
        uint256 _rwaType,
        uint256 _version
    ) internal returns(address) {
        if(dividendFactory[_rwaType][_version] != address(0)) {
            address dividendAddr = ICTMRWAFactory(dividendFactory[_rwaType][_version]).deployDividend(
                _ID, 
                _tokenAddr, 
                _rwaType, 
                _version, 
                ctmRwaMap
            );
            return(dividendAddr);
        }
        else return(address(0));
    }

    /// @dev Calls the contract function to deploy the CTMRWA001Storage for this _ID
    function deployStorage(
        uint256 _ID,
        address _tokenAddr,
        uint256 _rwaType,
        uint256 _version
    ) internal returns(address) {
        if(storageFactory[_rwaType][_version] != address(0)){
            address storageAddr = ICTMRWAFactory(storageFactory[_rwaType][_version]).deployStorage(
                _ID,
                _tokenAddr,
                _rwaType, 
                _version, 
                ctmRwaMap
            );
            return(storageAddr);
        }
        else return(address(0));
    }

    /// @notice Governance function to change the CTMRWA001Sentry contract address
    function deploySentry(
        uint256 _ID,
        address _tokenAddr,
        uint256 _rwaType,
        uint256 _version
    ) internal returns(address) {
        if(sentryFactory[_rwaType][_version] != address(0)){
            address sentryAddr = ICTMRWAFactory(sentryFactory[_rwaType][_version]).deploySentry(
                _ID,
                _tokenAddr,
                _rwaType, 
                _version, 
                ctmRwaMap
            );
            return(sentryAddr);
        }
        else return(address(0));
    }

    /// @dev Governance function to set a new CTMRWA001TokenFactory
    function setTokenFactory(uint256 _rwaType, uint256 _version, address _tokenFactory) external onlyGov {
        tokenFactory[_rwaType][_version] = _tokenFactory;
    }

    /// @dev Governance function to set a new CTMRWA001DividendFactory
    function setDividendFactory(uint256 _rwaType, uint256 _version, address _dividendFactory) external onlyGov {
        dividendFactory[_rwaType][_version] = _dividendFactory;
    }

    /// @dev Governance function to set a new CTMRWA001StorageManager
    function setStorageFactory(uint256 _rwaType, uint256 _version, address _storageFactory) external onlyGov {
        storageFactory[_rwaType][_version] = _storageFactory;
    }

    /// @dev Governance function to set a new CTMRWA001SentryManager
    function setSentryFactory(uint256 _rwaType, uint256 _version, address _sentryFactory) external onlyGov {
        sentryFactory[_rwaType][_version] = _sentryFactory;
    }

    /// @dev Governance function to set the commission rate on funds raised
    /// @param _commissionRate ia number between 0 and 10000, so in 0.01% increments
    function setInvestCommissionRate(uint256 _commissionRate) external onlyGov {
        ICTMRWADeployInvest(deployInvest).setCommissionRate(_commissionRate);
    }

    function deployNewInvestment(
        uint256 _ID,
        uint256 _rwaType,
        uint256 _version,
        address _feeToken
    ) public {
        (bool ok,) = ICTMRWAMap(ctmRwaMap).getInvestContract(_ID, _rwaType, _version);
        require(!ok, "CTMDeploy: Investment contract already deployed");

        require(deployInvest != address(0), "CTMDeployer: deployInvest address not set");

        address investAddress = ICTMRWADeployInvest(deployInvest).deployInvest(_ID, _rwaType, _version, _feeToken);
        ICTMRWAMap(ctmRwaMap).setInvestmentContract(_ID, _rwaType, _version, investAddress);
    }

    function cID() internal view returns (uint256) {
        return block.chainid;
    }

    /// @dev Convert a string to an EVM address. Also checks the string length
    function stringToAddress(string memory str) internal pure returns (address) {
        bytes memory strBytes = bytes(str);
        require(strBytes.length == 42, "CTMRWADeployer: Invalid address length");
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

    /// @dev Check if two strings are equal (in fact if their hashes are equal)
    function stringsEqual(
        string memory a,
        string memory b
    ) internal pure returns (bool) {
        bytes32 ka = keccak256(abi.encode(a));
        bytes32 kb = keccak256(abi.encode(b));
        return (ka == kb);
    }

    /// @dev Convert a string to lower case
    function _toLower(string memory str) internal pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint i = 0; i < bStr.length; i++) {
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
    
    /// @dev Fallback function for failed c3call cross-chain. Only emits an event at present
    function _c3Fallback(bytes4 _selector,
        bytes calldata _data,
        bytes calldata _reason) internal override returns (bool) {


        emit LogFallback(_selector, _data, _reason);
        return true;
    }

}