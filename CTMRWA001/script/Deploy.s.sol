// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.20;

import "forge-std/console.sol";
import {Script} from "forge-std/Script.sol";

import {CTMRWADeployer} from "../contracts/CTMRWADeployer.sol";
import {CTMRWA001Deployer} from "../contracts/CTMRWA001Deployer.sol";
import {CTMRWA001TokenFactory} from "../contracts/CTMRWA001TokenFactory.sol";
import {CTMRWA001DividendFactory} from "../contracts/CTMRWA001DividendFactory.sol";

import {FeeManager} from "../contracts/FeeManager.sol";
import {CTMRWAGateway} from "../contracts/CTMRWAGateway.sol";
import {CTMRWA001X} from "../contracts/CTMRWA001X.sol";

contract Deploy is Script {

    CTMRWADeployer ctmRwaDeployer;
    CTMRWAGateway gateway;
    CTMRWA001X ctmRwa001X;
    CTMRWA001TokenFactory tokenFactory;
    CTMRWA001DividendFactory dividendFactory;


    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        // env variables (changes based on deployment chain, edit in .env)
        address c3callerProxyAddr = vm.envAddress("C3_DEPLOY");
        address govAddr = deployer;
        uint256 dappID1 = vm.envUint("DAPP_ID1");
        uint256 dappID2 = vm.envUint("DAPP_ID2");
        uint256 dappID3 = vm.envUint("DAPP_ID3");
        uint256 dappID4 = vm.envUint("DAPP_ID4");
        

        address txSender = deployer;

        vm.startBroadcast(deployerPrivateKey);

        // deploy fee manager
        FeeManager feeManager = new FeeManager(govAddr, c3callerProxyAddr, txSender, dappID1);
        address feeManagerAddr = address(feeManager);


        // deploy gateway
        gateway = new CTMRWAGateway(
            govAddr, 
            c3callerProxyAddr, 
            txSender,
            dappID4
        );

        console.log("gateway address");
        console.log(address(gateway));


        // deploy RWA001X
        ctmRwa001X = new CTMRWA001X(
            address(gateway),
            feeManagerAddr,
            govAddr,
            c3callerProxyAddr,
            txSender,
            dappID2
        );

        console.log("ctmRwa001X address");
        console.log(address(ctmRwa001X));

        deployCTMRWA001Deployer(
            1,
            1,
            govAddr,
            address(ctmRwa001X),
            c3callerProxyAddr,
            txSender,
            dappID3
        );

        vm.stopBroadcast();
    }

    function deployCTMRWA001Deployer(
        uint256 _rwaType,
        uint256 _version,
        address _gov,
        address _rwa001X,
        address _c3callerProxy,
        address _txSender,
        uint256 _dappID
    ) internal {
        ctmRwaDeployer = new CTMRWADeployer(
            _gov,
            _rwa001X,
            _c3callerProxy,
            _txSender,
            _dappID
        );

        ctmRwa001X.setCtmRwaDeployer(address(ctmRwaDeployer));

        tokenFactory = new CTMRWA001TokenFactory(address(ctmRwaDeployer));
        ctmRwaDeployer.setTokenFactory(_rwaType, _version, address(tokenFactory));
        dividendFactory = new CTMRWA001DividendFactory(address(ctmRwaDeployer));
        ctmRwaDeployer.setDividendFactory(_rwaType, _version, address(dividendFactory));

    }
}
