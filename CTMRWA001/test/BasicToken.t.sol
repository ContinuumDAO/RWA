// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";

// import {Upgrades} from "@openzeppelin/foundry-upgrades/Upgrades.sol";
// import { Options } from "@openzeppelin/foundry-upgrades/Options.sol";

import "@openzeppelin/contracts/utils/Strings.sol";

import {C3UUIDKeeper} from "contracts/c3Caller/C3UUIDKeeper.sol";
import {IUUIDKeeper} from "contracts/c3Caller/IUUIDKeeper.sol";
import {C3CallerDapp} from "contracts/c3Caller/C3CallerDapp.sol";
import {C3Caller} from "contracts/c3Caller/C3Caller.sol";
import {IC3Caller, IC3CallerProxy, IC3GovClient} from "contracts/c3Caller/IC3Caller.sol";
import {C3CallerProxy} from "contracts/c3Caller/C3CallerProxy.sol";
import {C3CallerProxyERC1967} from "contracts/c3Caller/C3CallerProxyERC1967.sol";
import {C3GovClient} from "contracts/c3Caller/C3GovClient.sol";

import {TestERC20} from "contracts/mocks/TestERC20.sol";

import {FeeManager} from "contracts/FeeManager.sol";
import {CTMRWA001Deployer} from "contracts/CTMRWA001Deployer.sol";
import {CTMRWA001X} from "contracts/CTMRWA001X.sol";


contract SetUp is Test {
    using Strings for *;

    address admin;
    address gov;
    address user1;
    address user2;
    address tokenAdmin;
    address tokenAdmin2;
    address treasury;

    // address c3;

    // Options opt;
    
    TestERC20 ctm;
    TestERC20 usdc;

    address ADDRESS_ZERO = address(0);
    
    uint256 chainID;
    uint256 dappId = 1;

    string[]  tokensStr;
    uint256[] fees;

    C3UUIDKeeper c3UUIDKeeper;

    C3CallerProxyERC1967 c3CallerProxy;
    C3CallerProxy c3CallerImpl;
    C3Caller c3CallerLogic;
    IC3CallerProxy c3;
    IC3GovClient c3Gov;

    C3CallerDapp c3CallerDapp;
    C3GovClient c3GovClient;

    FeeManager feeManager;
    CTMRWA001Deployer deployer;
    CTMRWA001X rwa001X;


    function setUp() public virtual {
        string memory mnemonic = "test test test test test test test test test test test junk";
        uint256 privKey0 = vm.deriveKey(mnemonic, 0);
        uint256 privKey1 = vm.deriveKey(mnemonic, 1);
        uint256 privKey2 = vm.deriveKey(mnemonic, 2);
        uint256 privKey3 = vm.deriveKey(mnemonic, 3);
        uint256 privKey4 = vm.deriveKey(mnemonic, 4);
        uint256 privKey5 = vm.deriveKey(mnemonic, 5);
        uint256 privKey6 = vm.deriveKey(mnemonic, 6);

        admin = vm.addr(privKey0);
        gov = vm.addr(privKey1);
        user1 = vm.addr(privKey2);
        user2 = vm.addr(privKey3);
        tokenAdmin = vm.addr(privKey4);
        tokenAdmin2 = vm.addr(privKey5);
        treasury = vm.addr(privKey6);

        vm.startPrank(admin);

        ctm = new TestERC20("Continuum", "CTM", 18);
        usdc = new TestERC20("Circle USD", "USDC", 6);

        uint256 usdcBal = 100000*10**usdc.decimals();
        usdc.mint(admin, usdcBal);

        //console.log("admin bal USDC = ", usdc.balanceOf(address(admin))/1e6);
        usdc.transfer(user1, usdcBal);
        
        deployC3Caller();
        deployFeeManager();
        deployCTMRWA001Deployer();
        deployCTMRWA001X();

        vm.stopPrank();

        vm.startPrank(user1);
        uint256 initialUserBal = usdc.balanceOf(address(user1));
        usdc.approve(address(feeManager), initialUserBal);
        vm.stopPrank();

    }

    function deployCTMRWA001X() internal {

        // address _feeManager,
        // address _ctmRwa001Deployer,
        // address _gov,
        // address _c3callerProxy,
        // address _txSender,
        // uint256 _dappID

        rwa001X = new CTMRWA001X(
            address(feeManager),
            address(deployer),
            gov,
            address(c3Gov),
            admin,
            2
        );
    }

    function deployCTMRWA001Deployer() internal {
        deployer = new CTMRWA001Deployer();
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


    function deployC3Caller() internal {
        vm.startPrank(gov);
        c3UUIDKeeper = new C3UUIDKeeper();

        // this is actually the c3Caller address that gets passed to c3CallerProxy
        c3CallerLogic = new C3Caller(address(c3UUIDKeeper));

        // this is actually the C3CallerProxy, but is implementation in the eyes of UUPS
        c3CallerImpl = new C3CallerProxy();

        // initialize the "implementation" (actually C3CallerProxy) with address of logic contract
        bytes memory implInitializerData = abi.encodeWithSignature("initialize(address)", address(c3CallerLogic));
        // this is actually not C3CallerProxy, but a simple instance of ERC1967
        c3CallerProxy = new C3CallerProxyERC1967(address(c3CallerImpl), implInitializerData);

        // this is just an instance of the proxy, callable with functions found in C3CallerProxy purely for the sake of testing here.
        c3 = IC3CallerProxy(address(c3CallerProxy));

        c3Gov = IC3GovClient(address(c3));

        c3Gov.addOperator(gov);

        vm.stopPrank();

        assertEq(c3.isCaller(address(c3CallerLogic)), true);
    }

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
}

contract TestBasicToken is SetUp {
    using Strings for *;


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
        uint256 fee = feeManager.getXChainFee("1", tokenStr);
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
        feeManager.delFeeToken(tokenStr);
        feeTokenList = feeManager.getFeeTokenList();
        assertEq(feeTokenList.length, 1);
        assertEq(feeTokenList[0], address(ctm));
        vm.stopPrank();
    }

    function test_CTMRWA001XBasic() public {
        string memory gatewayStr = rwa001X.getChainContract(cID().toString());
        //console.log(gatewayStr);
        address gateway = stringToAddress(gatewayStr);
        //console.log(gateway);
        assertEq(gateway, address(rwa001X));
    }

    function test_CTMRWA001Deploy() public {
        // function deployAllCTMRWA001X(
        // bool includeLocal,
        // string memory tokenName_, 
        // string memory symbol_, 
        // uint8 decimals_,
        // string[] memory toChainIdsStr_,
        // string memory feeTokenStr

        string memory tokenStr = _toLower((address(usdc).toHexString()));
        string[] memory chainIdsStr;

        uint256 ID = rwa001X.deployAllCTMRWA001X(
            true,  // include local mint
            "Semi Fungible Token XChain",
            "SFTX",
            18,
            chainIdsStr,  // empty array - no cross-chain minting
            tokenStr
        );
        console.log("ID");
        console.log(ID);
    }
}
