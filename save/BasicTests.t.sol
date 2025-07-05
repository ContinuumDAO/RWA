// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {C3UUIDKeeper} from "@c3caller/C3UUIDKeeper.sol";
import {IUUIDKeeper} from "@c3caller/IUUIDKeeper.sol";
import {C3CallerDapp} from "@c3caller/C3CallerDapp.sol";
import {C3Caller} from "@c3caller/C3Caller.sol";
import {C3CallerStructLib, IC3Caller, IC3CallerProxy} from "@c3caller/IC3Caller.sol";
import {C3CallerProxy} from "@c3caller/C3CallerProxy.sol";
import {C3GovClient} from "@c3caller/C3GovClient.sol";

import {CTMRWA1DividendFactory} from "../src/core/CTMRWA1DividendFactory.sol";
import {CTMRWAERC20Deployer} from "../src/core/CTMRWAERC20Deployer.sol";
import {ICTMRWA1, SlotData} from "../src/core/ICTMRWA1.sol";
import {ICTMRWA1Dividend} from "../src/core/ICTMRWA1Dividend.sol";
import {ICTMRWAERC20} from "../src/core/ICTMRWAERC20.sol";

import {CTMRWA1XFallback} from "../src/crosschain/CTMRWA1XFallback.sol";
import {CTMRWAGateway} from "../src/crosschain/CTMRWAGateway.sol";
import {CTMRWA1X} from "../src/crosschain/CTMRWA1X.sol";
import {ICTMRWAGateway} from "../src/crosschain/ICTMRWAGateway.sol";
import {ICTMRWA1X} from "../src/crosschain/ICTMRWA1X.sol";
import {ICTMRWA1XFallback} from "../src/crosschain/ICTMRWA1XFallback.sol";

import {CTMRWADeployer} from "../src/deployment/CTMRWADeployer.sol";
import {CTMRWA1TokenFactory} from "../src/deployment/CTMRWA1TokenFactory.sol";
import {CTMRWADeployInvest} from "../src/deployment/CTMRWADeployInvest.sol";
import {ICTMRWADeployer} from "../src/deployment/ICTMRWADeployer.sol";
import {ICTMRWAFactory} from "../src/deployment/ICTMRWAFactory.sol";
import {Offering, Holding, ICTMRWA1InvestWithTimeLock} from "../src/deployment/ICTMRWADeployInvest.sol";

import {FeeManager} from "../src/managers/FeeManager.sol";
import {FeeType, IFeeManager} from "../src/managers/IFeeManager.sol";

import {TestERC20} from "../src/mocks/TestERC20.sol";

import {CTMRWA1SentryManager} from "../src/sentry/CTMRWA1SentryManager.sol";
import {CTMRWA1SentryUtils} from "../src/sentry/CTMRWA1SentryUtils.sol";
import {ICTMRWA1Sentry} from "../src/sentry/ICTMRWA1Sentry.sol";
import {ICTMRWA1SentryManager} from "../src/sentry/ICTMRWA1SentryManager.sol";

import {CTMRWAMap} from "../src/shared/CTMRWAMap.sol";
import {ICTMRWAMap} from "../src/shared/ICTMRWAMap.sol";

import {CTMRWA1StorageManager} from "../src/storage/CTMRWA1StorageManager.sol";
import {CTMRWA1StorageUtils} from "../src/storage/CTMRWA1StorageUtils.sol";
import {URIType, URICategory, URIData, ICTMRWA1Storage} from "../src/storage/ICTMRWA1Storage.sol";

contract SetUp is Test {
    using Strings for *;

    /// @dev used for testing events
    event LogC3Call(
        uint256 indexed dappID,
        bytes32 indexed uuid,
        address caller,
        string toChainID,
        string to,
        bytes data,
        bytes extra
    );

    uint256 constant rwaType = 1;
    uint256 constant version = 1;

    address admin;
    address gov;

    address user1;
    address user2;
    address tokenAdmin;
    address tokenAdmin2;
    address treasury;
    address ctmDividend;
    address ctmRwaDeployer;
    address deployInvest;
    address ctmRwaErc20DeployerAddr;
    address ctmRwa1Map;

    string  cIdStr;

    string[] chainIdsStr;
    string[] someChainIdsStr;
    string[] gwaysStr;
    string[] rwaXsStr;
    string[] storageAddrsStr;
    string[] objNames;
    URICategory[] uricats;
    URIType[] uriTypes;
    string[] uriNames;
    bytes32[] hashes;

    uint256[] slotNumbers;
    string[] slotNames;


    TestERC20 ctm;
    TestERC20 usdc;

    address ADDRESS_ZERO = address(0);

    uint256 chainID;
    uint256 dappId = 1;

    string[]  tokensStr;
    uint256[] fees;

    C3UUIDKeeper c3UUIDKeeper;

    // C3CallerProxyERC1967 c3CallerProxy;
    C3CallerProxy c3CallerImpl;
    C3Caller c3CallerLogic;
    IC3CallerProxy c3;
    C3GovClient c3Gov;

    C3CallerDapp c3CallerDapp;
    C3GovClient c3GovClient;

    FeeManager feeManager;
    CTMRWADeployer deployer;
    CTMRWAMap map;
    CTMRWA1TokenFactory tokenFactory;
    CTMRWAGateway gateway;
    CTMRWA1X rwa1X;
    CTMRWA1XFallback rwa1XFallback;
    CTMRWADeployInvest ctmRwaDeployInvest;
    CTMRWAERC20Deployer ctmRwaErc20Deployer;
    CTMRWA1DividendFactory dividendFactory;
    CTMRWA1StorageManager storageManager;
    CTMRWA1StorageUtils storageUtils;
    CTMRWA1SentryManager sentryManager;
    CTMRWA1SentryUtils sentryUtils;


    function setUp() public virtual {
        string memory mnemonic = "test test test test test test test test test test test junk";
        uint256 privKey0 = vm.deriveKey(mnemonic, 0);
        uint256 privKey1 = vm.deriveKey(mnemonic, 1);
        uint256 privKey2 = vm.deriveKey(mnemonic, 2);
        uint256 privKey3 = vm.deriveKey(mnemonic, 3);
        uint256 privKey4 = vm.deriveKey(mnemonic, 4);
        uint256 privKey5 = vm.deriveKey(mnemonic, 5);
        uint256 privKey6 = vm.deriveKey(mnemonic, 6);

        cIdStr = block.chainid.toString();

        admin = vm.addr(privKey0);
        gov = vm.addr(privKey1);
        user1 = vm.addr(privKey2);
        user2 = vm.addr(privKey3);
        tokenAdmin = vm.addr(privKey4);
        tokenAdmin2 = vm.addr(privKey5);
        treasury = vm.addr(privKey6);

        vm.startPrank(admin);  // gov is admin for these tests

        ctm = new TestERC20("Continuum", "CTM", 18);
        usdc = new TestERC20("Circle USD", "USDC", 6);

        uint256 usdcBal = 100000*10**usdc.decimals();
        usdc.mint(admin, 3*usdcBal/5);
        usdc.mint(tokenAdmin, 1*usdcBal/5);
        usdc.mint(user2, 1*usdcBal/5);

        uint256 ctmBal = 100000 ether;
        ctm.mint(admin, ctmBal);

        /// @dev adding CTM balance to user1 so they can pay the fee
        ctm.mint(user1, ctmBal);

        // console.log("admin bal USDC = ", usdc.balanceOf(address(admin))/1e6);
        usdc.transfer(user1, usdcBal/2);

        // deployC3Caller();
        deployFeeManager();

        deployGateway();

        deployCTMRWA1X();
        vm.stopPrank();

        vm.startPrank(address(c3Gov));

        deployRwa1XFallback(address(rwa1X));

        chainIdsStr.push("1");
        rwaXsStr.push(address(rwa1X).toHexString());

        bool ok = gateway.attachRWAX(
            rwaType,
            version,
            chainIdsStr,
            rwaXsStr
        );
        assertEq(ok, true);
        assertEq(chainIdsStr.length, 1);
        chainIdsStr.pop();
        rwaXsStr.pop();

        ctmRwa1Map = deployMap();

        deployCTMRWA1Deployer(
            rwaType,
            version,
            address(c3Gov),
            address(rwa1X),
            address(map),
            address(c3),
            admin,
            3,
            88,
            89
        );

        storageManager.setCtmRwaMap(address(ctmRwa1Map));

        ok = gateway.attachStorageManager(
            rwaType, 
            version, 
            _stringToArray("1"),
            _stringToArray(address(storageManager).toHexString())
        );
        assertEq(ok, true);

        sentryManager.setCtmRwaMap(address(ctmRwa1Map));

        ok = gateway.attachSentryManager(
            rwaType, 
            version, 
            _stringToArray("1"),
            _stringToArray(address(sentryManager).toHexString())
        );
        assertEq(ok, true);
        

        ctmRwaDeployer = address(deployer);
        deployInvest = address(ctmRwaDeployInvest);
        deployer.setDeployInvest(deployInvest);
        ctmRwaErc20DeployerAddr = address(ctmRwaErc20Deployer);
        deployer.setErc20DeployerAddress(ctmRwaErc20DeployerAddr);

        rwa1X.setCtmRwaDeployer(ctmRwaDeployer);

        rwa1X.setCtmRwaMap(address(map));

        chainIdsStr.push("1");
        gwaysStr.push("ethereumGateway");
        gateway.addChainContract(chainIdsStr, gwaysStr);
        chainIdsStr.pop();
        gwaysStr.pop();

        vm.stopPrank();

        vm.startPrank(user1);
        uint256 initialUserBal = usdc.balanceOf(address(user1));
        usdc.approve(address(feeManager), initialUserBal);
        ctm.approve(address(rwa1X), ctmBal);
        vm.stopPrank();

        vm.startPrank(admin);
        usdc.approve(address(rwa1X), usdcBal/2);
        ctm.approve(address(rwa1X), ctmBal);
        vm.stopPrank();

        vm.prank(user1);
    }

    function deployGateway() internal {
        gateway = new CTMRWAGateway(
            address(c3Gov),
            address(c3),
            admin,
            4
        );
    }

    function deployCTMRWA1X() internal {
        rwa1X = new CTMRWA1X(
            address(gateway),
            address(feeManager),
            address(c3Gov),
            address(c3),
            admin,
            2
        );
    }

    function deployRwa1XFallback(address _rwa1X) internal {
        rwa1XFallback = new CTMRWA1XFallback(_rwa1X);
        rwa1X.setFallback(address(rwa1XFallback));
    }

    function deployMap() internal returns(address) {
        map = new CTMRWAMap(
            address(gateway),
            address(rwa1X)
        );

        return(address(map));
    }


    function deployCTMRWA1Deployer(
        uint256 _rwaType,
        uint256 _version,
        address _gov,
        address _rwa1X,
        address _map,
        address _c3callerProxy,
        address _txSender,
        uint256 _dappIDDeployer,
        uint256 _dappIDStorageManager,
        uint256 _dappIDSentryManager
    ) internal {
        deployer = new CTMRWADeployer(
            _gov,
            address(gateway),
            address(feeManager),
            _rwa1X,
            _map,
            _c3callerProxy,
            _txSender,
            3 // dappID = 3
        );

        ctmRwaDeployInvest = new CTMRWADeployInvest(
            _map,
            address(deployer),
            0,
            address(feeManager)
        );

        ctmRwaErc20Deployer = new CTMRWAERC20Deployer(
            _map,
            address(feeManager)
        );


        tokenFactory = new CTMRWA1TokenFactory(_map, address(deployer));
        deployer.setTokenFactory(_rwaType, _version, address(tokenFactory));
        address deployerAddr = address(deployer);
        dividendFactory = new CTMRWA1DividendFactory(address(deployer));
        ctmDividend = address(dividendFactory);
        deployer.setDividendFactory(_rwaType, _version, address(dividendFactory));
        storageManager = new CTMRWA1StorageManager(
            _gov,
            _rwaType,
            _version,
            _c3callerProxy,
            _txSender,
            _dappIDStorageManager,
            _map,
            address(gateway),
            address(feeManager)
        );

        address storageManagerAddr = address(storageManager);

        storageUtils = new CTMRWA1StorageUtils(
            _rwaType,
            _version,
            _map,
            storageManagerAddr
        );

        storageManager.setStorageUtils(address(storageUtils));

        storageManager.setCtmRwaDeployer(deployerAddr);
        storageManager.setCtmRwaMap(_map);

        deployer.setStorageFactory(_rwaType, _version, storageManagerAddr);


        sentryManager = new CTMRWA1SentryManager(
            _gov,
            _rwaType,
            _version,
            _c3callerProxy,
            _txSender,
            _dappIDStorageManager,
            _map,
            address(gateway),
            address(feeManager)
        );

        address sentryManagerAddr = address(sentryManager);

        deployer.setSentryFactory(_rwaType, _version, sentryManagerAddr);


        sentryUtils = new CTMRWA1SentryUtils(
            _rwaType,
            _version,
            _map,
            sentryManagerAddr
        );

        sentryManager.setSentryUtils(address(sentryUtils));

        sentryManager.setCtmRwaDeployer(deployerAddr);
        sentryManager.setCtmRwaMap(_map);

        ICTMRWAFactory(address(sentryManager)).setCtmRwaDeployer(address(deployer));

    }

    function deployFeeManager() internal {

        feeManager = new FeeManager(
            gov,
            address(c3Gov),
            admin,
            dappId
        );

        vm.startPrank(gov);
        feeManager.addFeeToken(address(ctm).toHexString());
        feeManager.addFeeToken(address(usdc).toHexString());

        feeManager.setFeeMultiplier(FeeType.ADMIN, 5);
        feeManager.setFeeMultiplier(FeeType.DEPLOY, 100);
        feeManager.setFeeMultiplier(FeeType.MINT, 5);
        feeManager.setFeeMultiplier(FeeType.BURN, 5);
        feeManager.setFeeMultiplier(FeeType.TX, 1);
        feeManager.setFeeMultiplier(FeeType.WHITELIST, 1);
        feeManager.setFeeMultiplier(FeeType.COUNTRY, 1);

        string memory destChain = "1";
        string memory ctmAddrStr = _toLower(address(ctm).toHexString());
        string memory usdcAddrStr = _toLower(address(usdc).toHexString());

        tokensStr.push(ctmAddrStr);
        tokensStr.push(usdcAddrStr);

        fees.push(1000);
        fees.push(1000);

        feeManager.addFeeToken(
            destChain,
            tokensStr,
            fees
        );
        vm.stopPrank();
    }

    // function deployC3Caller() internal {
    //     vm.startPrank(gov);
    //     c3UUIDKeeper = new C3UUIDKeeper();

    //     // this is actually the c3Caller address that gets passed to c3CallerProxy
    //     c3CallerLogic = new C3Caller(address(c3UUIDKeeper));

    //     // this is actually the C3CallerProxy, but is implementation in the eyes of UUPS
    //     c3CallerImpl = new C3CallerProxy();

    //     // initialize the "implementation" (actually C3CallerProxy) with address of logic contract
    //     bytes memory implInitializerData = abi.encodeWithSignature("initialize(address)", address(c3CallerLogic));
    //     // this is actually not C3CallerProxy, but a simple instance of ERC1967
    //     c3CallerProxy = new C3CallerProxyERC1967(address(c3CallerImpl), implInitializerData);

    //     // this is just an instance of the proxy, callable with functions found in C3CallerProxy purely for the sake of testing here.
    //     c3 = IC3CallerProxy(address(c3CallerProxy));

    //     c3Gov = C3GovClient(address(c3));

    //     c3Gov.addOperator(gov);
    //     c3UUIDKeeper.addOperator(address(c3CallerLogic));

    //     vm.stopPrank();

    //     assertEq(c3.isCaller(address(c3CallerLogic)), true);
    // }

    function getRevert(bytes calldata _payload) external pure returns(bytes memory) {
        return(abi.decode(_payload[4:], (bytes)));
    }

    function stringToAddress(string memory str) public pure returns (address) {
        bytes memory strBytes = bytes(str);
        require(strBytes.length == 42, "Invalid address length");
        bytes memory addrBytes = new bytes(20);

        for (uint i = 0; i < 20; i++) {
            addrBytes[i] = bytes1(hexCharToByte(strBytes[2 + i * 2]) * 16 + hexCharToByte(strBytes[3 + i * 2]));
        }

        return address(uint160(bytes20(addrBytes)));
    }


    function hexCharToByte(bytes1 char) internal pure returns (uint8) {
        uint8 byteValue = uint8(char);
        if (byteValue >= uint8(bytes1('0')) && byteValue <= uint8(bytes1('9'))) {
            return byteValue - uint8(bytes1('0'));
        } else if (byteValue >= uint8(bytes1('a')) && byteValue <= uint8(bytes1('f'))) {
            return 10 + byteValue - uint8(bytes1('a'));
        } else if (byteValue >= uint8(bytes1('A')) && byteValue <= uint8(bytes1('F'))) {
            return 10 + byteValue - uint8(bytes1('A'));
        }
        revert("Invalid hex character");
    }

    function stringsEqual(
        string memory a,
        string memory b
    ) public pure returns (bool) {
        bytes32 ka = keccak256(abi.encode(a));
        bytes32 kb = keccak256(abi.encode(b));
        return (ka == kb);
    }

    function cID() view internal returns(uint256) {
        return block.chainid;
    }

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

    function _stringToArray(string memory _string) internal pure returns(string[] memory) {
        string[] memory strArray = new string[](1);
        strArray[0] = _string;
        return(strArray);
    }

    function _boolToArray(bool _bool) internal pure returns(bool[] memory) {
        bool[] memory boolArray = new bool[](1);
        boolArray[0] = _bool;
        return(boolArray);
    }

     function _uint256ToArray(uint256 _myUint256) internal pure returns(uint256[] memory) {
        uint256[] memory uintArray = new uint256[](1);
        uintArray[0] = _myUint256;
        return(uintArray);
    }

    function _uint8ToArray(uint8 _myUint8) internal pure returns(uint8[] memory) {
        uint8[] memory uintArray = new uint8[](1);
        uintArray[0] = _myUint8;
        return(uintArray);
    }

    function _uriCategoryToArray(URICategory _myCat) internal pure returns(URICategory[] memory) {
        URICategory[] memory uriCatArray = new URICategory[](1);
        uriCatArray[0] = _myCat;
        return(uriCatArray);
    }

    function _uriTypeToArray(URIType _myType) internal pure returns(URIType[] memory) {
        URIType[] memory uriTypeArray = new URIType[](1);
        uriTypeArray[0] = _myType;
        return(uriTypeArray);
    }

    function _bytes32ToArray(bytes32 _myBytes32) internal pure returns(bytes32[] memory) {
        bytes32[] memory bytes32Array = new bytes32[](1);
        bytes32Array[0] = _myBytes32;
        return(bytes32Array);
    }

    function CTMRWA1Deploy() public returns(uint256, address) {
        string memory tokenStr = _toLower((address(usdc).toHexString()));
        string[] memory dummyChainIdsStr;

        uint256 ID = rwa1X.deployAllCTMRWA1X(
            true,  // include local mint
            0,
            rwaType,
            version,
            "Semi Fungible Token XChain",
            "SFTX",
            18,
            "GFLD",
            dummyChainIdsStr,  // empty array - no cross-chain minting
            tokenStr
        );
        (bool ok, address tokenAddress) =  map.getTokenContract(ID, rwaType, version);
        assertEq(ok, true);

        return(ID, tokenAddress);
    }

    function createSomeSlots(uint256 _ID) public {

        someChainIdsStr.push(cID().toString());
        string memory tokenStr = _toLower((address(usdc).toHexString()));

        bool ok = rwa1X.createNewSlot(
            _ID,
            5,
            "slot 5 is the best RWA",
            someChainIdsStr,
            tokenStr
        );

        ok = rwa1X.createNewSlot(
            _ID,
            3,
            "",
            someChainIdsStr,
            tokenStr
        );

        ok = rwa1X.createNewSlot(
            _ID,
            1,
            "this is a basic offering",
            someChainIdsStr,
            tokenStr
        );
    }

    function deployAFewTokensLocal(address _ctmRwaAddr) public returns(uint256,uint256,uint256) {
        string memory ctmRwaAddrStr = _toLower(_ctmRwaAddr.toHexString());
        (bool ok, uint256 ID) = map.getTokenId(ctmRwaAddrStr, rwaType, version);
        assertEq(ok, true);

        createSomeSlots(ID);

        string memory tokenStr = _toLower((address(usdc).toHexString()));

        uint256 tokenId1 = rwa1X.mintNewTokenValueLocal(
            user1,
            0,
            5,
            2000,
            ID,
            tokenStr
        );

        uint256 tokenId2 = rwa1X.mintNewTokenValueLocal(
            user1,
            0,
            3,
            4000,
            ID,
            tokenStr
        );

        uint256 tokenId3 = rwa1X.mintNewTokenValueLocal(
            user1,
            0,
            1,
            6000,
            ID,
            tokenStr
        );

        return(tokenId1, tokenId2, tokenId3);
    }

    function listAllTokensByAddress(address tokenAddr, address user) public view {
        uint256 bal = ICTMRWA1(tokenAddr).balanceOf(user);

        for(uint256 i=0; i<bal; i++) {
            uint256 tokenId = ICTMRWA1(tokenAddr).tokenOfOwnerByIndex(user, i);
            (, uint256 balance, , uint256 slot, string memory slotName,) = ICTMRWA1(tokenAddr).getTokenInfo(tokenId);
            console.log("tokenId");
            console.log(tokenId);
            console.log("balance");
            console.log(balance);
            console.log("slot");
            console.log(slot);
            console.log("slot name");
            console.log(slotName);
            console.log("*************************");
        }
    }
}

contract TestBasicToken is SetUp {
    using Strings for *;

    string[] toChainIdsStr;


    modifier prankUser0() {
        vm.startPrank(admin);
        _;
        vm.stopPrank();
    }

    modifier prankUser(address user) {
        vm.startPrank(user);
        _;
        vm.stopPrank();
    }

    function setUp() public override {
        super.setUp();
    }


    function test_c3Caller() public {
        bool govIsExecutor = c3.isExecutor(gov);
        bool govIsOperator = c3Gov.isOperator(gov);
        assertEq(govIsOperator, govIsExecutor);
        assertEq(govIsOperator, true);
    }


    function test_feeManager() public {
        address[] memory feeTokenList = feeManager.getFeeTokenList();
        assertEq(feeTokenList[0], address(ctm));
        assertEq(feeTokenList[1], address(usdc));

        string memory tokenStr = _toLower((address(usdc).toHexString()));

        uint256 fee = feeManager.getXChainFee(
            _stringToArray("1"),
            false,
            FeeType.TX,
            tokenStr
        );

        assertEq(fee, 1000);

        fee = fee*10**usdc.decimals()/100;

        vm.startPrank(user1);
        uint256 initBal = usdc.balanceOf(address(user1));
        uint256 feePaid = feeManager.payFee(fee, tokenStr);
        uint256 endBal = usdc.balanceOf(address(user1));
        assertEq(initBal-feePaid, endBal);
        vm.stopPrank();

        vm.startPrank(gov);
        feeManager.withdrawFee(tokenStr, endBal, treasury.toHexString());
        uint256 treasuryBal = usdc.balanceOf(address(treasury));
        assertEq(treasuryBal, feePaid);
        vm.stopPrank();

        vm.startPrank(gov);
        feeTokenList = feeManager.getFeeTokenList();
        assertEq(feeTokenList.length, 2);
        feeManager.delFeeToken(tokenStr);
        feeTokenList = feeManager.getFeeTokenList();
        assertEq(feeTokenList.length, 1);
        assertEq(feeTokenList[0], address(ctm));
        vm.stopPrank();
    }

    function test_CTMRWA1XBasic() public view {
        string memory gatewayStr = gateway.getChainContract(cID().toString());
        //console.log(gatewayStr);
        address gway = stringToAddress(gatewayStr);
        //console.log(gway);
        assertEq(gway, address(gateway));
    }

    function test_CTMRWA1Deploy() public {
        string memory tokenStr = _toLower((address(usdc).toHexString()));
        string[] memory chainIdsStr;

        uint256 rwaType = 1;
        uint256 version = 1;

        vm.startPrank(admin);
        uint256 ID = rwa1X.deployAllCTMRWA1X(
            true,  // include local mint
            0,
            rwaType,
            version,
            "Semi Fungible Token XChain",
            "SFTX",
            18,
            "GFLD",
            chainIdsStr,  // empty array - no cross-chain minting
            tokenStr
        );

        console.log("finished deploy, ID = ");
        console.log(ID);

        (bool ok, address ctmRwaAddr) = map.getTokenContract(ID, rwaType, version);
        console.log("ctmRwaAddr");
        console.log(ctmRwaAddr);
        assertEq(ok, true);

        uint256 tokenType = ICTMRWA1(ctmRwaAddr).rwaType();
        assertEq(tokenType, rwaType);

        uint256 deployedVersion = ICTMRWA1(ctmRwaAddr).version();
        assertEq(deployedVersion, version);

        address[] memory aTokens = rwa1X.getAllTokensByAdminAddress(admin);
        console.log('aTokens');
        assertEq(aTokens[0], ctmRwaAddr);

        vm.stopPrank();
    }

    function test_CTMRWA1Mint() public {
        (uint256 ID, address ctmRwaAddr) = CTMRWA1Deploy();

        createSomeSlots(ID);

        string memory tokenStr = _toLower((address(usdc).toHexString()));

        uint256 tokenId = rwa1X.mintNewTokenValueLocal(
            user1,
            0,
            5,
            2000,
            ID,
            tokenStr
        );

        assertEq(tokenId, 1);
        (uint256 id, uint256 bal, address owner, uint256 slot, string memory slotName,) = ICTMRWA1(ctmRwaAddr).getTokenInfo(tokenId);
        //console.log(id, bal, owner, slot);
        assertEq(id,1);
        assertEq(bal, 2000);
        assertEq(owner, user1);
        assertEq(slot, 5);
        assertEq(stringsEqual(slotName, "slot 5 is the best RWA"), true);

        vm.startPrank(user1);
        bool exists = ICTMRWA1(ctmRwaAddr).requireMinted(tokenId);
        assertEq(exists, true);
        ICTMRWA1(ctmRwaAddr).burn(tokenId);
        exists = ICTMRWA1(ctmRwaAddr).requireMinted(tokenId);
        assertEq(exists, false);
        vm.stopPrank();
    }

    function test_invest() public {

        vm.startPrank(tokenAdmin);
        (uint256 ID, address ctmRwaAddr) = CTMRWA1Deploy();
        createSomeSlots(ID);

        uint256 oneUsdc = 10**usdc.decimals();
        uint8 decimalsRwa = ICTMRWA1(ctmRwaAddr).valueDecimals();
        uint256 oneRwaUnit = 10**decimalsRwa;

        string memory tokenStr = _toLower((address(usdc).toHexString()));

        uint256 slot = 1;

        uint256 tokenIdAdmin = rwa1X.mintNewTokenValueLocal(
            tokenAdmin,
            0,
            slot,
            4 * oneRwaUnit,  // 4 apartments (2 bed)
            ID,
            tokenStr
        );

        slot = 5;

        uint256 tokenIdAdmin2 = rwa1X.mintNewTokenValueLocal(
            tokenAdmin,
            0,
            slot,
            2 * oneRwaUnit,  // 2 apartments (3 bed)
            ID,
            tokenStr
        );

        feeManager.setFeeMultiplier(FeeType.DEPLOYINVEST, 50);
        feeManager.setFeeMultiplier(FeeType.OFFERING, 50);
        feeManager.setFeeMultiplier(FeeType.INVEST, 5);

        bool ok;
        address investContract;


        address ctmInvest = deployer.deployNewInvestment(
            ID,
            rwaType,
            version,
            address(usdc)
        );

        vm.expectRevert("CTMDeploy: Investment contract already deployed");
        deployer.deployNewInvestment(
            ID,
            rwaType,
            version,
            address(usdc)
        );

        (ok, investContract) = map.getInvestContract(ID, rwaType, version);
        assertEq(ok, true);
        assertEq(investContract, ctmInvest);

        vm.stopPrank();


        uint256 price = 200000*oneUsdc; // price of an apartment
        address currency = address(usdc);
        uint256 minInvest = 1000*oneUsdc;
        uint256 maxInvest = 4000*oneUsdc;
        string memory regulatorCountry = "US";
        string memory regulatorAcronym = "SEC";
        string memory offeringType = "Private Placement | Schedule D, 506(c)";
        uint256 startTime = block.timestamp + 1*24*3600;
        uint256 endTime = startTime + 30*24*3600;
        uint256 lockDuration = 366*24*3600;

        vm.startPrank(user1);

        vm.expectRevert("CTMInvest: Not tokenAdmin");
        ICTMRWA1InvestWithTimeLock(investContract).createOffering(
            tokenIdAdmin, 
            price, 
            currency, 
            minInvest, 
            maxInvest, 
            regulatorCountry, 
            regulatorAcronym, 
            offeringType, 
            startTime, 
            endTime, 
            lockDuration, 
            address(usdc)
        );

        vm.stopPrank();

        vm.startPrank(tokenAdmin);

        vm.expectRevert("RWAX: Not owner/approved");
        ICTMRWA1InvestWithTimeLock(investContract).createOffering(
            tokenIdAdmin, 
            price, 
            currency, 
            minInvest, 
            maxInvest, 
            regulatorCountry, 
            regulatorAcronym, 
            offeringType, 
            startTime, 
            endTime, 
            lockDuration, 
            address(usdc)
        );

        ICTMRWA1(ctmRwaAddr).approve(investContract, tokenIdAdmin);
        ICTMRWA1InvestWithTimeLock(investContract).createOffering(
            tokenIdAdmin, 
            price, 
            currency, 
            minInvest, 
            maxInvest, 
            regulatorCountry, 
            regulatorAcronym, 
            offeringType, 
            startTime, 
            endTime, 
            lockDuration, 
            address(usdc)
        );

        uint256 count = ICTMRWA1InvestWithTimeLock(investContract).offeringCount();
        assertEq(count,1);

        Offering[] memory offerings = ICTMRWA1InvestWithTimeLock(investContract).listOfferings();
        assertEq(offerings[0].tokenId, tokenIdAdmin);
        assertEq(offerings[0].currency, currency);

        address tokenOwner = ICTMRWA1(ctmRwaAddr).ownerOf(tokenIdAdmin);
        assertEq(tokenOwner, investContract);

        // try to add the same tokenId again
        vm.expectRevert("RWA: transfer from invalid owner");
        ICTMRWA1InvestWithTimeLock(investContract).createOffering(
            tokenIdAdmin, 
            price, 
            currency, 
            minInvest, 
            maxInvest, 
            regulatorCountry, 
            regulatorAcronym, 
            offeringType, 
            startTime, 
            endTime, 
            lockDuration, 
            address(usdc)
        );


        vm.stopPrank();

        vm.startPrank(user1);

        uint256 indx = 0;
        uint256 investment = 2000 * oneUsdc;

        vm.expectRevert("CTMInvest: Offer not yet started");
        uint256 tokenInEscrow = ICTMRWA1InvestWithTimeLock(investContract).investInOffering(
            indx, investment, address(usdc)
        );

        skip(1*24*3600 + 1);

        vm.expectRevert("CTMInvest: investment too low");
        tokenInEscrow = ICTMRWA1InvestWithTimeLock(investContract).investInOffering(
            indx, 500*oneUsdc, address(usdc)
        );

        vm.expectRevert("CTMInvest: investment too high");
        tokenInEscrow = ICTMRWA1InvestWithTimeLock(investContract).investInOffering(
            indx, 5000*oneUsdc, address(usdc)
        );

        usdc.approve(investContract, investment);
        tokenInEscrow = ICTMRWA1InvestWithTimeLock(investContract).investInOffering(
            indx, investment, address(usdc)
        );

        uint256 balInEscrow = ICTMRWA1(ctmRwaAddr).balanceOf(tokenInEscrow);
        assertEq(balInEscrow*price, investment*oneRwaUnit);

        Holding memory myHolding = 
            ICTMRWA1InvestWithTimeLock(investContract).listEscrowHolding(user1, 0);
        assertEq(myHolding.offerIndex, 0);
        assertEq(myHolding.investor, user1);
        assertEq(myHolding.tokenId, tokenInEscrow);
        // block.timestamp hasn't advanced since the investOffering call
        assertEq(myHolding.escrowTime, offerings[myHolding.offerIndex].lockDuration + block.timestamp);

        address owner = ICTMRWA1(ctmRwaAddr).ownerOf(tokenInEscrow);
        assertEq(owner, investContract);

        // skip(30*24*3600);

        // vm.expectRevert("CTMInvest: Offer expired");
        // usdc.approve(investContract, investment);
        // uint256 tokenInEscrow2 = ICTMRWA1InvestWithTimeLock(investContract).investInOffering(
        //     indx, investment, address(usdc)
        // );

        skip(365*24*3600); // Day is now 1 day before lockDuration for tokenInEscrow

        vm.expectRevert("CTMInvest: tokenId is still locked");
        ICTMRWA1InvestWithTimeLock(investContract).unlockTokenId(myHolding.offerIndex, address(usdc));

        skip(1*24*3600);
        ICTMRWA1InvestWithTimeLock(investContract).unlockTokenId(myHolding.offerIndex, address(usdc));

        owner = ICTMRWA1(ctmRwaAddr).ownerOf(tokenInEscrow);
        assertEq(owner, user1);

        // Try again
        vm.expectRevert("CTMInvest: tokenId already withdrawn");
        ICTMRWA1InvestWithTimeLock(investContract).unlockTokenId(myHolding.offerIndex, address(usdc));

        vm.stopPrank();

        vm.startPrank(tokenAdmin);

        sentryManager.setSentryOptions(
            ID,
            true,  // whitelistSwitch
            false,  // kycSwitch
            false,  // kybSwitch
            false,  // over18Switch
            false,  // accreditedSwitch
            false,  // countryWLSwitch
            false,   // countryBLSwitch
            _stringToArray(cIdStr),
            tokenStr
        );

        // Create another holding for slot 5 this time
        ICTMRWA1(ctmRwaAddr).approve(investContract, tokenIdAdmin2);
        ICTMRWA1InvestWithTimeLock(investContract).createOffering(
            tokenIdAdmin2, 
            price, 
            currency, 
            minInvest, 
            maxInvest, 
            regulatorCountry, 
            regulatorAcronym, 
            offeringType, 
            block.timestamp, 
            block.timestamp+30*24*3600, 
            lockDuration, 
            address(usdc)
        );
        count = ICTMRWA1InvestWithTimeLock(investContract).offeringCount();
        assertEq(count,2);

        vm.stopPrank();

        vm.startPrank(user1);

        indx = 1;  // This new second offering
        usdc.approve(investContract, investment);
        vm.expectRevert("CTMInvest: Not whitelisted");
        tokenInEscrow = ICTMRWA1InvestWithTimeLock(investContract).investInOffering(
            indx, investment, address(usdc)
        );

        vm.stopPrank();

        vm.startPrank(tokenAdmin);

        sentryManager.addWhitelist(
            ID,
            _stringToArray(user1.toHexString()), 
            _boolToArray(true),
            _stringToArray(cIdStr),
            tokenStr
        );

        vm.stopPrank();

        vm.startPrank(user1);

        tokenInEscrow = ICTMRWA1InvestWithTimeLock(investContract).investInOffering(
            indx, investment, address(usdc)
        );

        uint256 holdingCount = ICTMRWA1InvestWithTimeLock(investContract).escrowHoldingCount(user1);
        assertEq(holdingCount, 2); // The first one has already been redeemed

        vm.stopPrank();

        vm.startPrank(tokenAdmin);
        // Test to see if pause works
        ICTMRWA1InvestWithTimeLock(investContract).pauseOffering(indx);
        vm.stopPrank();

        vm.startPrank(user1);
        usdc.approve(investContract, investment);
        vm.expectRevert("CTMInvest: Offering is paused");
        ICTMRWA1InvestWithTimeLock(investContract).investInOffering(
            indx, investment, address(usdc)
        );
        vm.stopPrank();

        vm.startPrank(tokenAdmin);
        // Test to see if pause works
        ICTMRWA1InvestWithTimeLock(investContract).unpauseOffering(indx);
        vm.stopPrank();

        vm.startPrank(user1);
        ICTMRWA1InvestWithTimeLock(investContract).investInOffering(
            indx, investment, address(usdc)
        );
        holdingCount = ICTMRWA1InvestWithTimeLock(investContract).escrowHoldingCount(user1);
        assertEq(holdingCount, 3);
        vm.stopPrank();


        vm.startPrank(tokenAdmin);

        // Test to see if we can claim dividends whilst token is in escrow

        address ctmDividend = ICTMRWA1(ctmRwaAddr).dividendAddr();

        ICTMRWA1Dividend(ctmDividend).setDividendToken(address(usdc));

        uint256 divRate = 2;
        ICTMRWA1Dividend(ctmDividend).changeDividendRate(5, divRate);

        uint256 dividendTotal = ICTMRWA1Dividend(ctmDividend).getTotalDividend();

        // usdc.approve(ctmDividend, dividendTotal);
        // uint256 unclaimed = ICTMRWA1Dividend(ctmDividend).fundDividend();



        vm.stopPrank();

    }

    function test_deployErc20() public {

        vm.startPrank(tokenAdmin);
        (uint256 ID, address ctmRwaAddr) = CTMRWA1Deploy();
        createSomeSlots(ID);

        uint256 slot = 1;
        string memory name = "Basic Stuff";

        string memory tokenStr = _toLower((address(usdc).toHexString()));


        ICTMRWA1(ctmRwaAddr).deployErc20(slot, name, address(usdc));

        address newErc20 = ICTMRWA1(ctmRwaAddr).getErc20(slot);

        // console.log(newErc20);
        string memory newName = ICTMRWAERC20(newErc20).name();
        string memory newSymbol = ICTMRWAERC20(newErc20).symbol();
        uint8 newDecimals = ICTMRWAERC20(newErc20).decimals();
        uint256 ts = ICTMRWAERC20(newErc20).totalSupply();

        assertEq(stringsEqual(newName, "slot 1| Basic Stuff"), true);
        // console.log(newName);
        assertEq(stringsEqual(newSymbol, "SFTX"),true);
        assertEq(newDecimals, 18);
        assertEq(ts, 0);

        vm.expectRevert("RWA: ERC20 slot already exists");
        ICTMRWA1(ctmRwaAddr).deployErc20(slot, name, address(usdc));

        vm.expectRevert("RWA: Slot does not exist");
        ICTMRWA1(ctmRwaAddr).deployErc20(99, name, address(usdc));

        uint256 tokenId1User1 = rwa1X.mintNewTokenValueLocal(
            user1,
            0,
            slot,
            2000,
            ID,
            tokenStr
        );

        uint256 balUser1 = ICTMRWAERC20(newErc20).balanceOf(user1);
        assertEq(balUser1, 2000);

        ts = ICTMRWAERC20(newErc20).totalSupply();
        assertEq(ts, 2000);

        uint256 tokenId1User2 = rwa1X.mintNewTokenValueLocal(
            user2,
            0,
            slot,
            3000,
            ID,
            tokenStr
        );

        ts = ICTMRWAERC20(newErc20).totalSupply();
        assertEq(ts, 5000);

        uint256 tokenId2User2 = rwa1X.mintNewTokenValueLocal(
            user2,
            0,
            slot,
            4000,
            ID,
            tokenStr
        );

        uint256 balUser2 = ICTMRWAERC20(newErc20).balanceOf(user2);
        assertEq(balUser2, 7000);

        ts = ICTMRWAERC20(newErc20).totalSupply();
        assertEq(ts, 9000);

        vm.stopPrank();


        vm.startPrank(user1);
        ICTMRWAERC20(newErc20).transfer(user2, 1000);
        uint256 balUser1After = ICTMRWAERC20(newErc20).balanceOf(user1);
        uint256 balUser2After = ICTMRWAERC20(newErc20).balanceOf(user2);
        assertEq(balUser1After, balUser1-1000);
        assertEq(balUser2After, balUser2+1000);
        assertEq(ts, ICTMRWAERC20(newErc20).totalSupply());

        vm.expectRevert();
        ICTMRWAERC20(newErc20).transfer(user2, balUser1After + 1);
        assertEq(ICTMRWAERC20(newErc20).balanceOf(user1), balUser1After);

        vm.stopPrank();

        vm.startPrank(tokenAdmin);
        uint256 tokenId2User1 = rwa1X.mintNewTokenValueLocal(  // adding an extra tokenId
            user1,
            0,
            slot,
            3000,
            ID,
            tokenStr
        );
        vm.stopPrank();

        vm.startPrank(user1);
        uint256 balTokenId2 = ICTMRWA1(ctmRwaAddr).balanceOf(tokenId2User1);
        assertEq(balTokenId2, 3000);
        ICTMRWAERC20(newErc20).transfer(user2, 2000);
        assertEq(ICTMRWA1(ctmRwaAddr).balanceOf(tokenId1User1), 0); // 1000 - 1000
        assertEq(ICTMRWA1(ctmRwaAddr).balanceOf(tokenId2User1), 2000); // 3000 - 1000
        assertEq(ICTMRWAERC20(newErc20).balanceOf(user1), 2000); // 4000 => 2000
        assertEq(ICTMRWAERC20(newErc20).balanceOf(user2), 10000); // 3000 + 4000 + 1000 + 2000
        assertEq(ts + 3000, ICTMRWAERC20(newErc20).totalSupply());
        vm.stopPrank();

        vm.startPrank(user2);
        assertEq(ICTMRWAERC20(newErc20).allowance(user2, admin), 0);
        ICTMRWAERC20(newErc20).approve(admin, 9000);
        assertEq(ICTMRWAERC20(newErc20).allowance(user2, admin), 9000);
        vm.stopPrank();

        vm.startPrank(admin);
        ICTMRWAERC20(newErc20).transferFrom(user2, user1, 4000);
        assertEq(ICTMRWAERC20(newErc20).balanceOf(user1), 6000);
        assertEq(ICTMRWAERC20(newErc20).balanceOf(user2), 6000);
        assertEq(ICTMRWAERC20(newErc20).allowance(user2, admin), 5000);

        vm.expectRevert();
        ICTMRWAERC20(newErc20).transferFrom(user2, user1, 5001);

        ICTMRWAERC20(newErc20).transferFrom(user2, user1, 5000);
        assertEq(ICTMRWAERC20(newErc20).balanceOf(user1), 11000);
        assertEq(ICTMRWAERC20(newErc20).balanceOf(user2), 1000);

        vm.stopPrank();

    }

    function test_forceTransfer() public {
        vm.startPrank(tokenAdmin);
        (uint256 ID, address ctmRwaAddr) = CTMRWA1Deploy();
        createSomeSlots(ID);

        uint256 slot = 1;
        string memory name = "Basic Stuff";

        string memory tokenStr = _toLower((address(usdc).toHexString()));

        uint256 tokenId1User1 = rwa1X.mintNewTokenValueLocal(
            user1,
            0,
            slot,
            2000,
            ID,
            tokenStr
        );

        uint256 tokenId2User1 = rwa1X.mintNewTokenValueLocal(
            user1,
            0,
            slot,
            1000,
            ID,
            tokenStr
        );

        vm.expectRevert("RWA: Licensed Security override not set up");
        ICTMRWA1(ctmRwaAddr).forceTransfer(user1, user2, tokenId1User1);

        string memory randomData = "this is any old data";
        bytes32 junkHash = keccak256(abi.encode(randomData));

        storageManager.addURI(
            ID,
            "2",
            URICategory.ISSUER,
            URIType.CONTRACT,
            "Basic RWA for testing",
            0, // dummy
            junkHash,
            _stringToArray(cIdStr),
            tokenStr
        );

        (, address stor) = map.getStorageContract(ID, rwaType, version);

        // Attempt to set admin as the Regulator's wallet
        vm.expectRevert("CTMRWA1Storage: No description of the Security is present");
        ICTMRWA1Storage(stor).createSecurity(admin);

        randomData = "this is a dummy security";
        junkHash = keccak256(abi.encode(randomData));

        storageManager.addURI(
            ID,
            "1",
            URICategory.LICENSE,
            URIType.CONTRACT,
            "Dummy security",
            0, // dummy
            junkHash,
            _stringToArray(cIdStr),
            tokenStr
        );

        vm.expectRevert("RWA: Licensed Security override not set up");
        ICTMRWA1(ctmRwaAddr).forceTransfer(user1, user2, tokenId1User1);


        // set admin as the Regulator's wallet
        ICTMRWA1Storage(stor).createSecurity(admin);
        assertEq(ICTMRWA1Storage(stor).regulatorWallet(), admin);

        vm.expectRevert("RWA: Licensed Security override not set up");
        ICTMRWA1(ctmRwaAddr).forceTransfer(user1, user2, tokenId1User1);

        ICTMRWA1(ctmRwaAddr).setOverrideWallet(tokenAdmin2);
        assertEq(ICTMRWA1(ctmRwaAddr).overrideWallet(), tokenAdmin2);

        vm.expectRevert("RWA: Cannot forceTransfer");
        ICTMRWA1(ctmRwaAddr).forceTransfer(user1, user2, tokenId1User1);

        vm.stopPrank();

        vm.startPrank(tokenAdmin2);  // tokenAdmin2 is the override wallet
        ICTMRWA1(ctmRwaAddr).forceTransfer(user1, user2, tokenId1User1);
        assertEq(ICTMRWA1(ctmRwaAddr).ownerOf(tokenId1User1), user2); // successful forceTransfer
        vm.stopPrank();

        vm.startPrank(user2);
        vm.expectRevert("RWA: Cannot forceTransfer");
        ICTMRWA1(ctmRwaAddr).forceTransfer(user1, user2, tokenId2User1);

        vm.stopPrank();

        vm.startPrank(tokenAdmin);
        rwa1X.changeTokenAdmin(tokenAdmin2.toHexString(), _stringToArray(cIdStr), ID, tokenStr);
        vm.stopPrank();

        vm.startPrank(tokenAdmin2);
        vm.expectRevert("RWA: Licensed Security override not set up"); // Must re-setup override wallet if tokenAdmin has changed
        ICTMRWA1(ctmRwaAddr).forceTransfer(user1, user2, tokenId2User1);
        vm.stopPrank();

    }

    function test_addURI() public {
        (uint256 ID, address ctmRwaAddr) = CTMRWA1Deploy();
        createSomeSlots(ID);

        string memory tokenStr = _toLower((address(usdc).toHexString()));


        string memory randomData = "this is any old data";
        bytes32 junkHash = keccak256(abi.encode(randomData));

        vm.expectRevert("CTMRWA1Storage: Type CONTRACT and CATEGORY ISSUER must be the first stored element");
        storageManager.addURI(
            ID,
            "1",
            URICategory.IMAGE,
            URIType.CONTRACT,
            "Basic RWA for testing",
            0, // dummy
            junkHash,
            _stringToArray(cIdStr),
            tokenStr
        );


        storageManager.addURI(
            ID,
            "1",
            URICategory.ISSUER,
            URIType.CONTRACT,
            "Basic RWA for testing",
            0, // dummy
            junkHash,
            _stringToArray(cIdStr),
            tokenStr
        );

        (bool ok, address thisStorage) = map.getStorageContract(ID, rwaType, version);

        bool existObject = ICTMRWA1Storage(thisStorage).existObjectName("1");
        assertEq(existObject, true);

        uint256 num = ICTMRWA1Storage(thisStorage).getURIHashCount(URICategory.ISSUER, URIType.CONTRACT);
        assertEq(num, 1);

        URIData memory thisHash = ICTMRWA1Storage(thisStorage).getURIHash(junkHash);
        assertEq(uint8(thisHash.uriCategory), uint8(URICategory.ISSUER));

        uint256 indx = 0;
        bytes32 issuerHash;
        string memory objectName;

        (issuerHash, objectName) = ICTMRWA1Storage(thisStorage).getURIHashByIndex(URICategory.ISSUER, URIType.CONTRACT, indx);
        // console.log("ObjectName");
        // console.log(objectName);
        // console.log("Issuer hash");
        // console.logBytes32(issuerHash);
        assertEq(issuerHash, junkHash);

    }

    function test_addURIX() public {
        (uint256 ID, address ctmRwaAddr) = CTMRWA1Deploy();
        createSomeSlots(ID);

        string memory tokenStr = _toLower((address(usdc).toHexString()));

        URICategory _uriCategory = URICategory.ISSUER;
        URIType _uriType = URIType.CONTRACT;

        string memory randomData = "this is any old data";
        bytes32 junkHash = keccak256(abi.encode(randomData));

        vm.expectRevert("CTMRWA0CTMRWA1StorageManager: addURI Starting nonce mismatch");
        storageManager.addURIX(
            ID,
            2,  // incorrect nonce
            _stringToArray("1"),
            _uint8ToArray(uint8(_uriCategory)),
            _uint8ToArray(uint8(_uriType)),
            _stringToArray("A Title"),
            _uint256ToArray(0),
            _uint256ToArray(block.timestamp),
            _bytes32ToArray(junkHash)
        );

        storageManager.addURIX(
            ID,
            1,
            _stringToArray("1"),
            _uint8ToArray(uint8(_uriCategory)),
            _uint8ToArray(uint8(_uriType)),
            _stringToArray("A Title"),
            _uint256ToArray(0),
            _uint256ToArray(block.timestamp),
            _bytes32ToArray(junkHash)
        );

        (bool ok, address thisStorage) = map.getStorageContract(ID, rwaType, version);

        uint256 newNonce = ICTMRWA1Storage(thisStorage).nonce();
        assertEq(newNonce,2);

        bool exists = ICTMRWA1Storage(thisStorage).existObjectName("1");
        assertEq(exists, true);

        URIData memory uri = ICTMRWA1Storage(thisStorage).getURIHash(junkHash);
        assertEq(stringsEqual(uri.title, "A Title"), true);

    }

    function test_getTokenList() public {
        vm.startPrank(user1);
        (, address ctmRwaAddr) = CTMRWA1Deploy();
        deployAFewTokensLocal(ctmRwaAddr);
        vm.stopPrank();

        address[] memory adminTokens = rwa1X.getAllTokensByAdminAddress(user1);
        assertEq(adminTokens.length, 1);  // only one CTMRWA1 token deployed
        assertEq(ctmRwaAddr, adminTokens[0]);

        address[] memory nRWA1 = rwa1X.getAllTokensByOwnerAddress(user1);  // List of CTMRWA1 tokens that user1 has or still has tokens in
        assertEq(nRWA1.length, 1);

        uint256 tokenId;
        uint256 id;
        uint256 bal;
        address owner;
        uint256 slot;
        string memory slotName;

        for(uint256 i=0; i<nRWA1.length; i++) {
            tokenId = ICTMRWA1(nRWA1[i]).tokenOfOwnerByIndex(user1, i);
            (id, bal, owner, slot, slotName,) = ICTMRWA1(nRWA1[i]).getTokenInfo(tokenId);
            // console.log(tokenId);
            // console.log(id);
            // console.log(bal);
            // console.log(owner);
            // console.log(slot);
            // console.log(slotName);
            // console.log(admin);
            // console.log("************");

            /// @dev added 1 to the ID, as they are 1-indexed as opposed to this loop which is 0-indexed
            uint256 currentId = i + 1;
            assertEq(owner, user1);
            assertEq(tokenId, currentId);
            assertEq(id, currentId);
        }
    }

    function test_dividends() public {
        vm.startPrank(admin);  // this CTMRWA1 has an admin of admin
        (, address ctmRwaAddr) = CTMRWA1Deploy();
        (uint256 tokenId1, uint256 tokenId2, uint256 tokenId3) = deployAFewTokensLocal(ctmRwaAddr);

        address ctmDividend = ICTMRWA1(ctmRwaAddr).dividendAddr();

        ICTMRWA1Dividend(ctmDividend).setDividendToken(address(usdc));
        address token = ICTMRWA1Dividend(ctmDividend).dividendToken();
        assertEq(token, address(usdc));

        uint256 divRate = ICTMRWA1Dividend(ctmDividend).getDividendRateBySlot(3);
        assertEq(divRate, 0);

        uint256 divRate3 = 2500;
        ICTMRWA1Dividend(ctmDividend).changeDividendRate(3, divRate3);
        divRate = ICTMRWA1Dividend(ctmDividend).getDividendRateBySlot(3);
        assertEq(divRate, divRate3);

        uint256 divRate1 = 8000;
        ICTMRWA1Dividend(ctmDividend).changeDividendRate(1, divRate1);

        uint256 balSlot1 = ICTMRWA1(ctmRwaAddr).totalSupplyInSlot(1);

        uint256 dividend = ICTMRWA1Dividend(ctmDividend).getTotalDividendBySlot(1);
        assertEq(dividend, balSlot1*divRate1);

        uint256 balSlot3 = ICTMRWA1(ctmRwaAddr).totalSupplyInSlot(3);

        uint256 balSlot5 = ICTMRWA1(ctmRwaAddr).totalSupplyInSlot(5);

        uint256 divRate5 = ICTMRWA1Dividend(ctmDividend).getDividendRateBySlot(5);

        uint256 dividendTotal = ICTMRWA1Dividend(ctmDividend).getTotalDividend();
        assertEq(dividendTotal, balSlot1*divRate1 + balSlot3*divRate3 + balSlot5*divRate5);


        usdc.approve(ctmDividend, dividendTotal);
        uint256 unclaimed = ICTMRWA1Dividend(ctmDividend).fundDividend();
        vm.stopPrank();
        assertEq(unclaimed, dividendTotal);

        vm.stopPrank();  // end of prank admin

        vm.startPrank(user1);
        bool ok = ICTMRWA1Dividend(ctmDividend).claimDividend();
        vm.stopPrank();
        assertEq(ok, true);
        uint balAfter = usdc.balanceOf(user1);

        vm.stopPrank();
    }

    function test_sentryOptions() public {
        vm.startPrank(admin);  // this CTMRWA1 has an admin of admin
        (uint256 ID, address ctmRwaAddr) = CTMRWA1Deploy();
        createSomeSlots(ID);

        string memory tokenStr = _toLower((address(usdc).toHexString()));

        (bool ok, address sentry) = map.getSentryContract(ID, rwaType, version);

        string memory adminStr = admin.toHexString();
        string memory user1Str = user1.toHexString();
        string memory user2Str = user2.toHexString();

        vm.stopPrank();

        vm.startPrank(user1);

        vm.expectRevert("CTMRWA1SentryManager: Not tokenAdmin");
        sentryManager.setSentryOptions(
            ID,
            true,  // whitelistSwitch
            false,
            false,
            false,
            false,
            false,
            false,
            _stringToArray(cIdStr),
            tokenStr
        );
        vm.stopPrank();

        vm.startPrank(admin);

        vm.expectRevert("CTMRWA1SentryManager: Must set either whitelist or KYC");
        sentryManager.setSentryOptions(
            ID,
            false, // whitelistSwitch
            false, // kycSwitch
            false, // KYB
            false, // over18
            false, // accredited
            false, // country WL
            false, // country BL
            _stringToArray(cIdStr),
            tokenStr
        );

        vm.expectRevert("CTMRWA1SentryManager: Must set KYC to use KYB");
        sentryManager.setSentryOptions(
            ID,
            true, // whitelistSwitch
            false, // kycSwitch
            true,  // kybSwitch
            false,
            false,
            false,
            false,
            _stringToArray(cIdStr),
            tokenStr
        );

        vm.expectRevert("CTMRWA1SentryManager: Must set KYC to use over18 flag");
        sentryManager.setSentryOptions(
            ID,
            true, // whitelistSwitch
            false, // kycSwitch
            false, // kybSwitch
            true,  // over18Switch
            false, // accredited
            false, // country WL
            false, // country BL
            _stringToArray(cIdStr),
            tokenStr
        );

        vm.expectRevert("CTMRWA1SentryManager: Must set KYC to use Accredited flag");
        sentryManager.setSentryOptions(
            ID,
            true,  // whitelistSwitch
            false,  // kycSwitch
            false,  // kybSwitch
            false,  // over18Switch
            true,   // accreditedSwitch
            false,
            false,
            _stringToArray(cIdStr),
            tokenStr
        );

        vm.expectRevert("CTMRWA1SentryManager: Must set KYC to use Country black or white lists");
        sentryManager.setSentryOptions(
            ID,
            true,  // whitelistSwitch
            false,  // kycSwitch
            false,  // kybSwitch
            false,  // over18Switch
            false,  // accreditedSwitch
            true,   // countryWLSwitch
            false,
            _stringToArray(cIdStr),
            tokenStr
        );

        vm.expectRevert("CTMRWA1SentryManager: Must set KYC to use Country black or white lists");
        sentryManager.setSentryOptions(
            ID,
            true,  // whitelistSwitch
            false,  // kycSwitch
            false,  // kybSwitch
            false,  // over18Switch
            false,  // accreditedSwitch
            false,  // countryWLSwitch
            true,   // countryBLSwitch
            _stringToArray(cIdStr),
            tokenStr
        );

        vm.expectRevert("CTMRWA1SentryManager: Cannot set Country blacklist and Country whitelist together");
        sentryManager.setSentryOptions(
            ID,
            false,  // whitelistSwitch
            true,  // kycSwitch
            false,  // kybSwitch
            false,  // over18Switch
            false,  // accreditedSwitch
            true,  // countryWLSwitch
            true,   // countryBLSwitch
            _stringToArray(cIdStr),
            tokenStr
        );

        vm.expectRevert("CTMRWA1SentryManager: Must set Country white lists to use Accredited");
        sentryManager.setSentryOptions(
            ID,
            false,  // whitelistSwitch
            true,  // kycSwitch
            false,  // kybSwitch
            true,  // over18Switch
            true,  // accreditedSwitch
            false,  // countryWLSwitch
            false,   // countryBLSwitch
            _stringToArray(cIdStr),
            tokenStr
        );

        sentryManager.setSentryOptions(
            ID,
            false,  // whitelistSwitch
            true,  // kycSwitch
            false,  // kybSwitch
            true,  // over18Switch
            true,  // accreditedSwitch
            true,  // countryWLSwitch
            false,   // countryBLSwitch
            _stringToArray(cIdStr),
            tokenStr
        );

        bool newAccredited = ICTMRWA1Sentry(sentry).accreditedSwitch();
        assertEq(newAccredited, true);

        sentryManager.goPublic(
            ID,
            _stringToArray(cIdStr),
            tokenStr
        );

        newAccredited = ICTMRWA1Sentry(sentry).accreditedSwitch();
        assertEq(newAccredited, false);

        vm.expectRevert("CTMRWA1SentryManager: Error. setSentryOptions has already been called");
        sentryManager.setSentryOptions(
            ID,
            false,  // whitelistSwitch
            true,  // kycSwitch
            false,  // kybSwitch
            true,  // over18Switch
            false,  // accreditedSwitch
            false,  // countryWLSwitch
            false,   // countryBLSwitch
            _stringToArray(cIdStr),
            tokenStr
        );

        vm.expectRevert("RWAX: Whitelist or kyc set No new chains");
        rwa1X.deployAllCTMRWA1X(
            false,  // include local mint
            ID,
            rwaType,
            version,
            "",
            "",
            18,
            "",
            _stringToArray("1"), // extend to another chain
            tokenStr
        );

        vm.stopPrank();

    }

    function test_setSentryOptionsX() public {

        // function setSentryOptionsX(
        //     uint256 _ID,
        //     bool _whitelist,
        //     bool _kyc,
        //     bool _kyb,
        //     bool _over18,
        //     bool _accredited,
        //     bool _countryWL,
        //     bool _countryBL
        // ) external onlyCaller returns(bool) {

        vm.startPrank(admin);  // this CTMRWA1 has an admin of admin
        (uint256 ID, address ctmRwaAddr) = CTMRWA1Deploy();

        sentryManager.setSentryOptionsX(
            ID,
            true,  // whitelistSwitch
            true,  // kycSwitch
            false,  // kybSwitch
            true,  // over18Switch
            false,  // accreditedSwitch
            false,  // countryWLSwitch
            false   // countryBLSwitch
        );

        (bool ok, address sentry) = map.getSentryContract(ID, rwaType, version);

        bool whitelistSwitch = ICTMRWA1Sentry(sentry).whitelistSwitch();
        assertEq(whitelistSwitch, true);
        bool kycSwitch = ICTMRWA1Sentry(sentry).kycSwitch();
        assertEq(kycSwitch, true);

        vm.stopPrank();

    }

    function test_whitelists() public {
        vm.startPrank(admin);  // this CTMRWA1 has an admin of admin
        // console.log("admin");
        // console.log(admin);
        // console.log("user1");
        // console.log(user1);
        // console.log("user2");
        // console.log(user2);

        (uint256 ID, address ctmRwaAddr) = CTMRWA1Deploy();
        createSomeSlots(ID);

        string memory tokenStr = _toLower((address(usdc).toHexString()));

        (bool ok, address sentry) = map.getSentryContract(ID, rwaType, version);

        string memory adminStr = admin.toHexString();
        string memory user1Str = user1.toHexString();
        string memory user2Str = user2.toHexString();


        ok = ICTMRWA1Sentry(sentry).isAllowableTransfer(user2Str);
        assertEq(ok, true); // whitelistSwitch not called yet, so all addresses are allowable

        bool wl = ICTMRWA1Sentry(sentry).whitelistSwitch();
        assertEq(wl, false); // whitelistSwitch not called yet
        // ICTMRWA1Sentry(sentry).setWhitelist();

        sentryManager.setSentryOptions(
            ID,
            true,  // whitelistSwitch
            false,
            false,
            false,
            false,
            false,
            false,
            _stringToArray(cIdStr),
            tokenStr
        );

        wl = ICTMRWA1Sentry(sentry).whitelistSwitch();
        assertEq(wl, true); // whitelistSwitch now set

        ok = ICTMRWA1Sentry(sentry).isAllowableTransfer(user2.toHexString());
        assertEq(ok, false); // user2 not in whitelist, so is not now allowable

        sentryManager.addWhitelist(
            ID,
            _stringToArray(user1Str), 
            _boolToArray(true),
            _stringToArray(cIdStr),
            tokenStr
        );

        sentryManager.addWhitelist(
            ID,
            _stringToArray(user2Str), 
            _boolToArray(true),
            _stringToArray(cIdStr),
            tokenStr
        );

        ok = ICTMRWA1Sentry(sentry).isAllowableTransfer(user2Str);
        assertEq(ok, true); // user2 is now allowable

        sentryManager.addWhitelist(
            ID,
            _stringToArray(user1Str), 
            _boolToArray(false),
            _stringToArray(cIdStr),
            tokenStr
        );

        ok = ICTMRWA1Sentry(sentry).isAllowableTransfer(user1Str);
        assertEq(ok, false); // user1 was removed and is not now allowable
        ok = ICTMRWA1Sentry(sentry).isAllowableTransfer(user2Str);
        assertEq(ok, true); // user2 remains in whitelist


        string memory addr1 = ICTMRWA1Sentry(sentry).getWhitelistAddressAtIndx(1);
        assertEq(stringToAddress(addr1), admin);
        string memory addr2 = ICTMRWA1Sentry(sentry).getWhitelistAddressAtIndx(2);
        assertEq(stringToAddress(addr2), user2);

        rwa1X.changeTokenAdmin(user1Str, _stringToArray(cIdStr), ID, tokenStr);
        address newAdmin = ICTMRWA1Sentry(sentry).tokenAdmin();
        assertEq(newAdmin, user1);

        // admin was replaced with user1 as tokenAdmin, but still remains in whitelist (at the end)
        ok = ICTMRWA1Sentry(sentry).isAllowableTransfer(adminStr);
        assertEq(ok, true);

        vm.expectRevert("CTMRWA1SentryManager: Not tokenAdmin");
        sentryManager.addWhitelist(
            ID,
            _stringToArray(adminStr), 
            _boolToArray(false),
            _stringToArray(cIdStr),
            tokenStr
        );

        vm.stopPrank();

        vm.startPrank(user1);

        vm.expectRevert("CTMRWA1Sentry: Cannot remove tokenAdmin from the whitelist");
        sentryManager.addWhitelist(
            ID,
            _stringToArray(user1Str), 
            _boolToArray(false),
            _stringToArray(cIdStr),
            tokenStr
        );

        // Now we test token minting by the tokenAdmin

        uint256 newTokenId = rwa1X.mintNewTokenValueLocal(
            user2,
            0,
            5,
            1000,
            ID,
            tokenStr
        );

        vm.expectRevert("RWA: Transfer token to address is not allowable");
        newTokenId = rwa1X.mintNewTokenValueLocal(
            treasury,
            0,
            5,
            1000,
            ID,
            tokenStr
        );


        vm.stopPrank();

        // here we can test transferring some tokens owned by user2
        vm.startPrank(user2);

        vm.expectRevert("RWA: Transfer token to address is not allowable");
        rwa1X.transferWholeTokenX(
            user2Str,
            treasury.toHexString(),
            cIdStr,
            newTokenId,
            ID,
            tokenStr
        );

        vm.expectRevert("RWA: Transfer token to address is not allowable");
        rwa1X.transferPartialTokenX(
            newTokenId,
            treasury.toHexString(),
            cIdStr,
            10,
            ID,
            tokenStr
        );

        ICTMRWA1(ctmRwaAddr).approve(treasury, newTokenId);

        vm.stopPrank();

        vm.startPrank(treasury);
        rwa1X.transferWholeTokenX(
            user2Str,
            adminStr,
            cIdStr,
            newTokenId,
            ID,
            tokenStr
        );

        vm.stopPrank();

    }

    function test_countryList() public {

         vm.startPrank(admin);  // this CTMRWA1 has an admin of admin
        // console.log("admin");
        // console.log(admin);
        // console.log("user1");
        // console.log(user1);
        // console.log("user2");
        // console.log(user2);

        (uint256 ID, address ctmRwaAddr) = CTMRWA1Deploy();
        createSomeSlots(ID);

        string memory tokenStr = _toLower((address(usdc).toHexString()));

        (bool ok, address sentry) = map.getSentryContract(ID, rwaType, version);

        string memory adminStr = admin.toHexString();
        string memory user1Str = user1.toHexString();
        string memory user2Str = user2.toHexString();




    }

    function test_localTransferX() public {
        vm.startPrank(admin);  // this CTMRWA1 has an admin of admin
        (uint256 ID, address ctmRwaAddr) = CTMRWA1Deploy();
        (uint256 tokenId, uint256 tokenId2, uint256 tokenId3) = deployAFewTokensLocal(ctmRwaAddr);

        address[] memory feeTokenList = feeManager.getFeeTokenList();
        string memory feeTokenStr = feeTokenList[0].toHexString();


        vm.expectRevert("RWAX: Not approved or owner");
        rwa1X.transferPartialTokenX(tokenId, user1.toHexString(), cIdStr, 5, ID, feeTokenStr);
        vm.stopPrank();


        vm.startPrank(user1);
        uint256 balBefore = ICTMRWA1(ctmRwaAddr).balanceOf(tokenId);
        rwa1X.transferPartialTokenX(tokenId, user2.toHexString(), cIdStr, 5, ID, feeTokenStr);
        uint256 balAfter = ICTMRWA1(ctmRwaAddr).balanceOf(tokenId);
        assertEq(balBefore, balAfter+5);

        address owned = rwa1X.getAllTokensByOwnerAddress(user2)[0];
        assertEq(owned, ctmRwaAddr);

        uint256 newTokenId = ICTMRWA1(ctmRwaAddr).tokenOfOwnerByIndex(user2,0);
        assertEq(ICTMRWA1(ctmRwaAddr).ownerOf(newTokenId), user2);
        uint256 balNewToken = ICTMRWA1(ctmRwaAddr).balanceOf(newTokenId);
        assertEq(balNewToken, 5);

        // ICTMRWA1(ctmRwaAddr).approve(tokenId2, user2, 50);
        ICTMRWA1(ctmRwaAddr).approve(user2, tokenId2);
        vm.stopPrank();

        vm.startPrank(user2);
        rwa1X.transferWholeTokenX(user1.toHexString(), admin.toHexString(), cIdStr, tokenId2, ID, feeTokenStr);
        address owner = ICTMRWA1(ctmRwaAddr).ownerOf(tokenId2);
        assertEq(owner, admin);
        assertEq(ICTMRWA1(ctmRwaAddr).getApproved(tokenId2), admin);

        vm.stopPrank();

    }

    function test_changeAdmin() public {

        address[] memory feeTokenList = feeManager.getFeeTokenList();
        string memory feeTokenStr = feeTokenList[0].toHexString(); // CTM

        vm.startPrank(admin);  // this CTMRWA1 has an admin of admin
        (uint256 ID, address ctmRwaAddr) = CTMRWA1Deploy();
        skip(10);
        (uint256 ID2, address ctmRwaAddr2) = CTMRWA1Deploy();
        address[] memory aTokens = rwa1X.getAllTokensByAdminAddress(admin);
        assertEq(aTokens.length, 2);
        
        assertEq(aTokens[0], ctmRwaAddr);
        assertEq(aTokens[1], ctmRwaAddr2);

        rwa1X.changeTokenAdmin(
            _toLower(user2.toHexString()),
            _stringToArray(cIdStr),
            ID,
            feeTokenStr
        );

        aTokens = rwa1X.getAllTokensByAdminAddress(admin);
        assertEq(aTokens.length, 1);

        aTokens = rwa1X.getAllTokensByAdminAddress(user2);
        assertEq(aTokens.length, 1);
        assertEq(aTokens[0], ctmRwaAddr);


        rwa1X.changeTokenAdmin(
            _toLower(address(0).toHexString()),
            _stringToArray(cIdStr),
            ID2,
            feeTokenStr
        );

        aTokens = rwa1X.getAllTokensByAdminAddress(admin);
        assertEq(aTokens.length, 0);

        address dustbin = ICTMRWA1(ctmRwaAddr2).tokenAdmin();
        assertEq(dustbin, address(0));


        vm.stopPrank();

    }

    function test_remoteDeploy() public {

        vm.startPrank(user1);
        (, address ctmRwaAddr) = CTMRWA1Deploy();
        vm.stopPrank();
        (bool ok, uint256 ID) = map.getTokenId(ctmRwaAddr.toHexString(), rwaType, version);
        assertEq(ok, true);

        // admin of the CTMRWA1 token
        string memory currentAdminStr = _toLower(user1.toHexString());

        address tokenAdmin = ICTMRWA1(ctmRwaAddr).tokenAdmin();
        assertEq(tokenAdmin, user1);

        address[] memory feeTokenList = feeManager.getFeeTokenList();
        string memory ctmRwaAddrStr = ctmRwaAddr.toHexString();
        string memory feeTokenStr = feeTokenList[0].toHexString(); // CTM
        toChainIdsStr.push("1");


        string memory targetStr;
        (ok, targetStr) = gateway.getAttachedRWAX(rwaType, version, "1");
        assertEq(ok, true);
        uint256 currentNonce = c3UUIDKeeper.currentNonce();

        uint256 rwaType = ICTMRWA1(ctmRwaAddr).rwaType();
        uint256 version = ICTMRWA1(ctmRwaAddr).version();

        string memory sig = "deployCTMRWA1(string,uint256,uint256,uint256,string,string,uint8,string,string)";

        string memory tokenName = "Semi Fungible Token XChain";
        string memory symbol = "SFTX";
        uint8 decimals = 18;

        // string memory funcCall = "deployCTMRWA1(string,uint256,uint256,uint256,string,string,uint8,string,string)";
        // bytes memory callData = abi.encodeWithSignature(
        //     funcCall,
        //     currentAdminStr,
        //     ID,
        //     rwaType,
        //     version,
        //     tokenName_,
        //     symbol_,
        //     decimals_,
        //     baseURI_,
        //     _ctmRwa1AddrStr
        // );

        bytes memory callData = abi.encodeWithSignature(
            sig,
            currentAdminStr,
            ID,
            tokenName,
            symbol,
            decimals,
            "GFLD",
            ctmRwaAddrStr
        );

        bytes32 testUUID = keccak256(abi.encode(
            address(c3UUIDKeeper),
            address(c3CallerLogic),
            block.chainid,
            2,
            targetStr,
            toChainIdsStr[0],
            currentNonce + 1,
            callData
        ));

        vm.expectEmit(true, true, false, true);
        emit LogC3Call(2, testUUID, address(rwa1X), toChainIdsStr[0], targetStr, callData, bytes(""));

        // function deployAllCTMRWA1X(
        //     bool includeLocal,
        //     uint256 existingID_,
        //     string memory tokenName_, 
        //     string memory symbol_, 
        //     uint8 decimals_,
        //     string memory baseURI_,
        //     string[] memory toChainIdsStr_,
        //     string memory feeTokenStr
        // ) public payable returns(uint256) {

        vm.prank(user1);
        rwa1X.deployAllCTMRWA1X(false, ID, rwaType, version, tokenName, symbol, decimals, "", toChainIdsStr, feeTokenStr);

    }

    function test_deployExecute() public {

        // function deployCTMRWA1(
        //     string memory _newAdminStr,
        //     uint256 _ID,
        //     uint256 _rwaType,
        //     uint256 _version,
        //     string memory _tokenName, 
        //     string memory _symbol, 
        //     uint8 _decimals,
        //     string memory _baseURI,
        //     string memory _fromContractStr
        // ) external onlyCaller returns(bool) {

        string memory newAdminStr = _toLower(user1.toHexString());

        string memory tokenName = "RWA Test token";
        string memory symbol = "RWA";
        uint8 decimals = 18;
        uint256 timestamp = 12776;
        slotNumbers.push(7);
        slotNames.push("test RWA");

        uint256 ID = uint256(keccak256(abi.encode(
            tokenName,
            symbol,
            decimals,
            timestamp,
            user1
        )));

        string memory baseURI = "GFLD";


        vm.prank(address(c3CallerLogic));
        bool ok = rwa1X.deployCTMRWA1(
            newAdminStr,
            ID,
            tokenName,
            symbol,
            decimals,
            baseURI,
            slotNumbers,
            slotNames
        );

        assertEq(ok, true);

        address tokenAddr;

        (ok, tokenAddr) = ICTMRWAMap(ctmRwa1Map).getTokenContract(ID, rwaType, version);

        assertEq(ICTMRWA1(tokenAddr).tokenAdmin(), user1);

        console.log("tokenAddr");
        console.log(tokenAddr);

        string memory sName = ICTMRWA1(tokenAddr).slotName(7);
        console.log(sName);

    }

    function test_transferToAddressExecute() public {

        vm.startPrank(user1);
        (uint256 ID, address ctmRwaAddr) = CTMRWA1Deploy();

        (, uint256 tokenId2,) = deployAFewTokensLocal(ctmRwaAddr);
         vm.stopPrank();

        console.log("tokenId2");
        console.log(tokenId2);

        uint256 slot = ICTMRWA1(ctmRwaAddr).slotOf(tokenId2);
        console.log("slot");
        console.log(slot);


        // address[] memory ops = c3GovClient.getAllOperators();
        // console.log("operators");
        // console.log(ops[0]);

        uint dapp = 2;


        string memory funcCall = "mintX(uint256,string,string,uint256,uint256,uint256,string)";
        bytes memory inputData = abi.encodeWithSignature(
            funcCall,
            ID,
            user1.toHexString(),
            user2.toHexString(),
            0,
            slot,
            10,
            ctmRwaAddr.toHexString()
        );

        // library C3CallerStructLib {
        //     struct C3EvmMessage {
        //         bytes32 uuid;
        //         address to;
        //         string fromChainID;
        //         string sourceTx;
        //         string fallbackTo;
        //         bytes data;
        //     }
        // }


        C3CallerStructLib.C3EvmMessage memory c3message = C3CallerStructLib.C3EvmMessage(
            0x0dd256c5649d5658f91dc4fe936c407ab6dd42183a795d5a256f4508631d0ccb,
            address(rwa1X),
            "421614",
            "0x04f1802a1e9f4c8de6f80e4c2e31b1ea32e019fd59aa38e8e20393ff7770026a",
            address(rwa1X).toHexString(),
            inputData
        );

        // console.log("transfering value of 10 from tokenId 2, slot 3 from user1 to user2");

        // console.log("BEFORE user1");
        // listAllTokensByAddress(ctmRwaAddr, user1);

        vm.prank(address(rwa1X));
        ICTMRWA1(ctmRwaAddr).burnValueX(tokenId2, 10);

        vm.prank(address(gov)); // blank onlyOperator require in C3Gov to test
        c3.execute(dapp, c3message);

        // console.log("AFTER user1");
        // listAllTokensByAddress(ctmRwaAddr, user1);
        // console.log("AFTER user2");
        // listAllTokensByAddress(ctmRwaAddr, user2);
    }

    function test_transferTokenIdToAddressExecute() public {

    // function mintX(
    //     uint256 _ID,
    //     string memory _fromAddressStr,
    //     string memory _toAddressStr,
    //     uint256 _fromTokenId,
    //     uint256 _slot,
    //     uint256 _balance,
    //     string memory _fromTokenStr
    // ) external onlyCaller returns(bool){

        vm.startPrank(admin);
        (uint256 ID, address ctmRwaAddr) = CTMRWA1Deploy();
        (uint256 tokenId1,,) = deployAFewTokensLocal(ctmRwaAddr);
        vm.stopPrank();

        vm.startPrank(address(c3CallerLogic));

        uint256 balStart = ICTMRWA1(ctmRwaAddr).balanceOf(tokenId1);
        console.log("balStart");
        console.log(balStart);

        bool ok = rwa1X.mintX(
            ID,
            user1.toHexString(),
            user2.toHexString(),
            // tokenId1,
            5,
            140/*,
            ctmRwaAddr.toHexString()*/
        );

        assertEq(ok, true);

        vm.stopPrank();

        uint256 newTokenId = ICTMRWA1(ctmRwaAddr).tokenOfOwnerByIndex(user2, 0);
        uint256 balEnd = ICTMRWA1(ctmRwaAddr).balanceOf(newTokenId);
        assertEq(balEnd, 140);

        string memory slotDescription = ICTMRWA1(ctmRwaAddr).slotName(5);
        // console.log("slotDescription = ");
        // console.log(slotDescription);
        assertEq(stringsEqual(slotDescription, "slot 5 is the best RWA"), true);

    }



    function test_transferToken() public {
        vm.startPrank(admin);
        (uint256 ID, address ctmRwaAddr) = CTMRWA1Deploy();
        (uint256 tokenId1,,) = deployAFewTokensLocal(ctmRwaAddr);
        vm.stopPrank();

        /*token1
            to: user1
            to token: 0 (new token)
            slot: 5
            value: 2000
            token addr: _ctmRwaAddr
        */

        /*token2
            to: user1
            to token: 0 (new token)
            slot: 3
            value: 4000
            token addr: _ctmRwaAddr
        */

        /*token2
            to: user1
            to token: 0 (new token)
            slot: 1
            value: 6000
            token addr: _ctmRwaAddr
        */



        string memory user1Str = user1.toHexString();
        address[] memory feeTokenList = feeManager.getFeeTokenList();
        string memory ctmRwaAddrStr = ctmRwaAddr.toHexString();
        string memory feeTokenStr = feeTokenList[0].toHexString(); // CTM
        string memory toChainIdStr = "1";
        string memory sig = "mintX(uint256,string,string,uint256,uint256,uint256,string)";

 
        (, string memory toRwaXStr) = gateway.getAttachedRWAX(rwaType, version, toChainIdStr);
        (,uint256 value,,uint256 slot, string memory slotName,) = ICTMRWA1(ctmRwaAddr).getTokenInfo(tokenId1);
        uint256 currentNonce = c3UUIDKeeper.currentNonce();

        string memory thisSlotName = ICTMRWA1(ctmRwaAddr).slotName(slot);


        // string memory funcCall = "mintX(uint256,string,string,uint256,uint256,uint256,string)";
        // bytes memory callData = abi.encodeWithSignature(
        //     funcCall,
        //     _ID,
        //     fromAddressStr,
        //     _toAddressStr,
        //     _fromTokenId,
        //     slot,
        //     slotName,
        //     value,
        //     ctmRwa1AddrStr
        // );

        bytes memory callData = abi.encodeWithSignature(
            sig,
            ID,
            user1Str,
            user1Str,
            tokenId1,
            slot,
            thisSlotName,
            value,
            ctmRwaAddrStr
        );


        bytes32 testUUID = keccak256(abi.encode(
            address(c3UUIDKeeper),
            address(c3CallerLogic),
            block.chainid,
            2,
            toRwaXStr,
            toChainIdStr,
            currentNonce + 1,
            callData
        ));

        vm.expectEmit(true, true, false, true);
        emit LogC3Call(2, testUUID, address(rwa1X), toChainIdStr, toRwaXStr, callData, bytes(""));

        // function transferWholeTokenX(
        //     string memory _fromAddressStr,
        //     string memory _toAddressStr,
        //     string memory _toChainIdStr,
        //     uint256 _fromTokenId,
        //     uint256 _ID,
        //     string memory _feeTokenStr
        // ) public {

        vm.prank(user1);
        rwa1X.transferWholeTokenX(user1Str, user1Str, toChainIdStr, tokenId1, ID, feeTokenStr);
    }


    function test_valueTransferNewTokenCreation() public {

        vm.startPrank(admin);
        (uint256 ID, address ctmRwaAddr) = CTMRWA1Deploy();
        (uint256 tokenId1,,) = deployAFewTokensLocal(ctmRwaAddr);
        vm.stopPrank();

        string memory user1Str = user1.toHexString();
        address[] memory feeTokenList = feeManager.getFeeTokenList();
        string memory ctmRwaAddrStr = ctmRwaAddr.toHexString();
        string memory feeTokenStr = feeTokenList[0].toHexString(); // CTM
        string memory toChainIdStr = "1";

        (bool ok, string memory toRwaXStr) = gateway.getAttachedRWAX(rwaType, version, toChainIdStr);
        require(ok, "CTMRWA1X: Target contract address not found");
        (,uint256 value,,uint256 slot, string memory thisSlotName,) = ICTMRWA1(ctmRwaAddr).getTokenInfo(tokenId1);
        uint256 currentNonce = c3UUIDKeeper.currentNonce();

        string memory sig = "mintX(uint256,string,string,uint256,uint256,uint256,string)";

        // string memory funcCall = "mintX(uint256,string,string,uint256,uint256,string,uint256,string)";
        // bytes memory callData = abi.encodeWithSignature(
        //     funcCall,
        //     _ID,
        //     fromAddressStr,
        //     _toAddressStr,
        //     _fromTokenId,
        //     slot,
        //     thisSlotName,
        //     _value,
        //     ctmRwa1AddrStr
        // );


        console.log("SLOTNAME");
        console.log(thisSlotName);

        bytes memory callData = abi.encodeWithSignature(
            sig,
            ID,
            user1Str,
            user1Str,
            tokenId1,
            slot,
            thisSlotName,
            value/2,  // send half the value to other chain
            ctmRwaAddrStr
        );

        bytes32 testUUID = keccak256(abi.encode(
            address(c3UUIDKeeper),
            address(c3CallerLogic),
            block.chainid,
            2,
            toRwaXStr,
            toChainIdStr,
            currentNonce + 1,
            callData
        ));

        vm.expectEmit(true, true, false, true);
        emit LogC3Call(2, testUUID, address(rwa1X), toChainIdStr, toRwaXStr, callData, bytes(""));

        // function transferPartialTokenX(
        //      uint256 _fromTokenId,
        //      string memory _toAddressStr,
        //      string memory _toChainIdStr,
        //      uint256 _value,
        //      uint256 _ID,
        //      string memory _feeTokenStr
        // ) public 

        vm.prank(user1);
        rwa1X.transferPartialTokenX(tokenId1, user1Str, toChainIdStr, value/2, ID, feeTokenStr);

    }
}
