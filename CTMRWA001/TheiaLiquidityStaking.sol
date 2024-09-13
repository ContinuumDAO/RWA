// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "@openzeppelin/contracts/utils/Strings.sol";

import {USDC, DAI} from "contracts/mock/ERC20.sol";
import {WETH} from "contracts/mock/WETH.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {THEIA} from "contracts/routerV2/THEIA.sol";

import {TheiaCallData} from "contracts/mock/TheiaCallData.sol";
import {TheiaUUIDKeeper} from "contracts/routerV2/TheiaUUIDKeeper.sol";
import {FeeManager} from "contracts/routerV2/FeeManager.sol";
import {TheiaRouterConfig} from "contracts/routerV2/TheiaRouterConfig.sol";
import {TheiaRouter} from "contracts/routerV2/TheiaRouter.sol";
import {TheiaERC20} from "contracts/routerV2/TheiaERC20.sol";
import {ITheiaERC20} from "contracts/routerV2/ITheiaERC20.sol";
import {PoolDeployer} from "contracts/routerV2/PoolDeployer.sol";
import {StagingVault} from "contracts/routerV2/StagingVault.sol";
import {IStagingVault} from "contracts/routerV2/IStagingVault.sol";
import {IVotingEscrow, VotingEscrow} from "contracts/routerV2/VeTHEIA.sol";
import {VeTHEIAProxy} from "contracts/routerV2/VeTHEIAProxy.sol";
import {TheiaRewards} from "contracts/routerV2/TheiaRewards.sol";
import {ITheiaRewards} from "contracts/routerV2/ITheiaRewards.sol";

import {C3SwapIDKeeper} from "lib/protocol/C3SwapIDKeeper.sol";
import {C3Caller} from "lib/protocol/C3Caller.sol";
import {IC3CallerProxy} from "lib/protocol/IC3Caller.sol";
import {C3CallerProxy} from "lib/protocol/C3CallerProxy.sol";



interface IC3CallerUpgradable is IC3CallerProxy {
    function upgradeToAndCall(address newImplementation, bytes memory data) external;
}

interface IVotingEscrowUpgradable is IVotingEscrow {
    function upgradeToAndCall(address newImplementation, bytes memory data) external;
}

interface ITheiaERC20Extended {
    function underlyingIsMinted() external view returns(bool);
}

contract SetUp is Test {
    using Strings for *;

    address admin;
    address gov;
    address user1;
    address treasury;
    address swapRouter;

    USDC usdc;
    DAI dai;
    WETH weth;
    VotingEscrow veImplV1;
    VeTHEIAProxy veTheiaProxy;
    IVotingEscrowUpgradable ve;

    address ADDRESS_ZERO = address(0);
    
    uint256 chainID;
    uint256 dappId = 1;

    string constant BASE_URI_V1 = "veTHEIA V1";

    TheiaCallData theiaCallData;
    FeeManager feeManager;
    TheiaUUIDKeeper theiaUUIDKeeper;
    TheiaRouterConfig theiaRouterConfig;
    TheiaRouter theiaRouter;
    PoolDeployer pool;
    StagingVault stagingVault;
    TheiaRewards theiaRewards;

    C3SwapIDKeeper c3SwapIDKeeper;
    C3Caller c3Caller;
    C3CallerProxy c3CallerProxy;
    IC3CallerUpgradable c3;

    THEIA theia;
    TheiaERC20 theiaETH;
    TheiaERC20 theiaUSDC;
    TheiaERC20 theiaDAI;
    TheiaERC20 theiaToken;

    uint256 THEIA_TS = 10_000_000 ether;

    uint256 initialBalUser = THEIA_TS/10;
    
    uint256 constant ONE_YEAR = 365 * 86400;
    uint256 constant MAXTIME = ONE_YEAR/2;
    uint256 constant WEEK = 1 weeks;

    uint256 constant BASE_EMISSION_RATE = 1 ether / 2000;

    uint256 usdcBal;
    uint256 daiBal;

    


    function setUp() public virtual {
        string memory mnemonic = "test test test test test test test test test test test junk";
        uint256 privKey0 = vm.deriveKey(mnemonic, 0);
        uint256 privKey1 = vm.deriveKey(mnemonic, 1);
        uint256 privKey2 = vm.deriveKey(mnemonic, 2);
        uint256 privKey3 = vm.deriveKey(mnemonic, 3);
        admin = vm.addr(privKey0);
        gov = vm.addr(privKey1);
        user1 = vm.addr(privKey2);
        treasury = vm.addr(privKey3);

        vm.startPrank(admin);

        usdc = new USDC();
        dai = new DAI();
        weth = new WETH();
        theiaCallData = new TheiaCallData();
        deployC3Caller();
        theiaUUIDKeeper = new TheiaUUIDKeeper(
            gov,
            address(c3),
            admin,
            dappId
        );

        feeManager = new FeeManager(
            gov,
            address(c3),
            admin,
            dappId
        );

        theiaRouterConfig = new TheiaRouterConfig(
            gov,
            address(c3),
            admin,
            dappId
        );

        theiaRouter = new TheiaRouter(
            address(weth),
            address(theiaUUIDKeeper),
            address(theiaRouterConfig),
            address(feeManager),
            gov,
            address(c3),
            admin,
            dappId
        );

        vm.stopPrank();
        

        vm.startPrank(gov);
        theiaRouter.setDelay(0);
        feeManager.addFeeToken(address(usdc));
        feeManager.addFeeToken(address(dai));
        address[] memory feeList = new address[](2);
        feeList[0] = address(usdc);
        feeList[1] = address(dai);
        uint256[] memory baseFees = new uint256[](2);
        baseFees[0] = 1e8;
        baseFees[1] = 1e8;
        feeManager.setFeeConfig(cID(), cID(), 2, feeList, baseFees);
        theiaUUIDKeeper.addSupportedCaller(address(theiaRouter));
        vm.stopPrank();


        vm.startPrank(admin);

        theia = new THEIA(
            admin,
            gov,
            address(c3)
        );

        theiaETH = new TheiaERC20("theiaETHOD", "theiaETH", 18, address(weth), address(theiaRouter));
        theiaUSDC = new TheiaERC20("theiaUSDC", "theiaUSDC", 6, address(usdc), address(theiaRouter));  // token with underlying
        theiaDAI = new TheiaERC20("theiaDAI", "theiaDAI", 6, address(dai), address(theiaRouter)); // token with underlying
        theiaToken = new TheiaERC20("theiaToken", "theiaToken", 18, address(0), admin);  // mint/burn token
        theiaToken.setMinter(address(theiaRouter));
        skip(1 days);
        theiaToken.applyMinter();
        chainID = theiaRouter.cID();
        vm.stopPrank();

        vm.startPrank(address(theiaRouter));
        theiaUSDC.setMinter(address(theiaRouter));
        theiaDAI.setMinter(address(theiaRouter));
        theiaETH.setMinter(address(theiaRouter));
        skip(1 days);
        theiaUSDC.applyMinter();
        theiaDAI.applyMinter();
        theiaETH.applyMinter();
        vm.stopPrank();


        vm.startPrank(admin);
        veImplV1 = new VotingEscrow();

        bytes memory initializerData = abi.encodeWithSignature(
            "initialize(address,string)",
            address(theia),
            BASE_URI_V1
        );
        veTheiaProxy = new VeTHEIAProxy(address(veImplV1), initializerData);

        ve = IVotingEscrowUpgradable(address(veTheiaProxy));


        stagingVault = new StagingVault(
            admin,
            address(c3),
            dappId,
            gov,
            address(feeManager),
            address(weth),
            address(ve)
        );


        // console.log('gov = ',gov);
        // console.log('theia = ',address(theia));
        // console.log('usdc = ',address(usdc));
        // console.log('swapRouter = ',swapRouter);
        // console.log('stagingVault = ', address(stagingVault));
        // console.log('ve = ',address(ve));
        // console.log('weth = ', address(weth));
        // console.log('*************************************************************************');

        theiaRewards = new TheiaRewards(
            0,
            gov,
            address(theia),
            address(usdc),
            swapRouter,
            address(stagingVault),
            address(ve),
            BASE_EMISSION_RATE,   // baseEmission rate
            address(weth)
        );

        vm.stopPrank();

        vm.startPrank(gov);

        ve.setUp(
            gov, 
            address(stagingVault), 
            address(theiaRewards),
            treasury
        );


        stagingVault.setUp(
            address(ve),
            address(pool),
            address(theiaRewards)
        );
        vm.stopPrank();


        usdcBal = 100000*10**usdc.decimals();
        daiBal = 100000*10**dai.decimals();

        vm.startPrank(admin);
        //console.log("admin bal USDC = ", usdc.balanceOf(address(admin))/1e6);
        usdc.transfer(user1, usdcBal);
        dai.transfer(user1, daiBal);

        theia.transfer(user1, initialBalUser);
        theia.transfer(address(theiaRewards), 100_000 ether);
        vm.stopPrank();


        vm.prank(user1);
        theia.approve(address(ve), initialBalUser);

    }


    function deployC3Caller() internal {

        c3SwapIDKeeper = new C3SwapIDKeeper(admin);

        bytes memory initializerData = abi.encodeWithSignature(
            "initialize(address,address)",
            admin, 
            address(c3SwapIDKeeper)
        );

        c3Caller = new C3Caller();

        c3CallerProxy = new C3CallerProxy(
            address(c3Caller),
            initializerData
        );

        c3 = IC3CallerUpgradable(address(c3CallerProxy));

        assertEq(c3.getMPC(), admin);

        vm.startPrank(admin);
        c3SwapIDKeeper.addSupportedCaller(address(c3));
        c3.addOperator(address(c3));
        vm.stopPrank();

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

}

contract TestTheiaStaking is SetUp {
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

    
  
    function test_depositWithdrawVaultLocal() public {
        uint256 amount = 1000 ether;
        uint256 endpoint =  MAXTIME;
        vm.startPrank(user1);
        uint256 tokenId = ve.create_lock(amount, endpoint);
        vm.stopPrank();

        string memory tokenSymbol = "DAI";
        string memory tokenStr = Strings.toHexString(uint160(address(theiaDAI)), 20);
        //string memory underlyingStr = Strings.toHexString(uint160(address(dai)), 20);

        bool underlyingIsMinted = ITheiaERC20Extended(address(theiaDAI)).underlyingIsMinted();
        assertEq(underlyingIsMinted, false);

        // Check that a user cannot add liquidity yet for staking

        string memory targetStr = "";
        string memory chainIdStr = block.chainid.toString();
        //console.log('chainIdStr = ', chainIdStr);

        vm.startPrank(user1);
        vm.expectRevert("Theia StagingVault: Not owner of this veTHEIA");
        IStagingVault(address(stagingVault)).attachLiquidity(
            2, 
            targetStr, 
            tokenSymbol, 
            chainIdStr, 
            amount, 
            0
        );
        
        vm.expectRevert("Theia StagingVault: Liquidity token address does not exist on target chain");
        IStagingVault(address(stagingVault)).attachLiquidity(
            tokenId, 
            targetStr, 
            "SHITCOIN",
            chainIdStr, 
            amount, 
            0
        );

        vm.stopPrank();


        uint256 rateFactor = 1100;
        uint256 standardRewardRate = 1 ether / 50000;

        vm.startPrank(gov);
        stagingVault.addRewardToken(
            tokenSymbol,
            standardRewardRate,
            chainIdStr,
            rateFactor,
            targetStr
        );
        vm.stopPrank();

        bool isRewarded = stagingVault.isRewardedToken(tokenSymbol);
        //console.log(tokenSymbol, ' is rewarded? : ', isRewarded);
        assertEq(isRewarded, true);

        // console.log('underlying address = ', ITheiaERC20(address(theiaDAI)).underlying());
        // console.log('tokenStr = ', stringToAddress(tokenStr));
        // console.log('tokenStr = ', tokenStr);


        vm.startPrank(user1);
        vm.expectRevert("Theia StagingVault: Liquidity provider has insufficient funds in the stagingVault");
        IStagingVault(address(stagingVault)).attachLiquidity(
            tokenId, 
            targetStr, 
            tokenSymbol,
            chainIdStr, 
            amount, 
            0
        );

        uint256 user1BalBefore = dai.balanceOf(user1);
        //console.log('user1 balance of DAI beforehand = ', user1BalBefore/10**dai.decimals());

        IERC20(address(dai)).approve(address(stagingVault), type(uint256).max);

        uint256 daiBal = IStagingVault(address(stagingVault)).depositStaging(tokenStr, 1000*10**dai.decimals());
        assertEq(daiBal, 1000*10**dai.decimals());

        daiBal = IStagingVault(address(stagingVault)).depositStaging(tokenStr, 2000*10**dai.decimals());
        assertEq(daiBal, 3000*10**dai.decimals());

        daiBal = IStagingVault(address(stagingVault)).withdrawStaging(tokenStr, 3000*10**dai.decimals(), user1);
        assertEq(daiBal, 0);

        uint256 user1BalAfter = dai.balanceOf(user1);
        //console.log('user1 balance of DAI afterwards = ', user1BalAfter/10**dai.decimals());

        assertEq(user1BalBefore, user1BalAfter);

        vm.stopPrank();
    }

    function test_attachLiquidityLocal() public {
        uint256 amount = 1000 ether;
        uint256 endpoint =  MAXTIME;
        vm.startPrank(user1);
        uint256 tokenId = ve.create_lock(amount, endpoint);
        vm.stopPrank();

        string memory tokenSymbol = "DAI";
        string memory tokenStr = Strings.toHexString(uint160(address(theiaDAI)), 20);


        string memory targetStr = "";
        string memory chainIdStr = block.chainid.toString();

        uint256 rateFactor = 1100;
        uint256 standardRewardRate = 1 ether / 50000;

        vm.startPrank(gov);
        stagingVault.addRewardToken(
            tokenSymbol,
            standardRewardRate,
            chainIdStr,
            rateFactor,
            targetStr
        );
        vm.stopPrank();

        uint256 standardRate = IStagingVault(address(stagingVault)).getStandardRewardRate(tokenSymbol);
        //console.log('standardRate = ', standardRate);
        assertEq(standardRate, standardRewardRate);

        vm.startPrank(user1);

        IERC20(address(dai)).approve(address(stagingVault), type(uint256).max);

        daiBal = IStagingVault(address(stagingVault)).depositStaging(tokenStr, 2000*10**dai.decimals());

        uint256 amountToAttach = 800*10**dai.decimals();

        uint256 nonce = IStagingVault(address(stagingVault)).attachLiquidity(
            tokenId,
            "",
            tokenSymbol,
            chainIdStr,
            amountToAttach,
            0
        );

        //console.log('nonce = ', nonce);
        bool completed = IStagingVault(address(stagingVault)).getCompletedStatus(nonce);
        assertEq(completed, true);
        (uint256 daiLiquidity, uint256 decimals) = IStagingVault(address(stagingVault)).getLiquidity(address(theiaDAI));

        uint256 balTheiaDAI = IERC20(address(theiaDAI)).balanceOf(address(stagingVault));
        //uint256 decimals = ITheiaERC20(address(theiaDAI)).decimals();
        //console.log('decimals = ', decimals);
        //console.log('StagingVault has balance of theiaDAI = ', balTheiaDAI/10**decimals);
        assertEq(amountToAttach/10**dai.decimals(), balTheiaDAI/10**decimals);
        assertEq(daiLiquidity, amountToAttach);


        uint256 daiStakedByTokenId = IStagingVault(address(stagingVault)).getTokenStakedByTokenId(tokenId, tokenSymbol);
        //console.log('daiStakedByTokenId = ', daiStakedByTokenId/10**decimals);
        assertEq(daiStakedByTokenId, amountToAttach);

        uint256 daiStakedByChainId = IStagingVault(address(stagingVault)).getTokenStakedByChain(tokenSymbol, chainIdStr);
        //console.log('daiStakedByChainId = ', daiStakedByChainId/10**decimals);
        assertEq(daiStakedByChainId, amountToAttach);

        uint256 daiStakedByTokenIsAndChainId = IStagingVault(address(stagingVault)).getTokenStakedByTokenIdAndChain(
            tokenId,
            tokenSymbol,
            chainIdStr
        );
        //console.log('daiStakedByTokenIsAndChainId = ', daiStakedByTokenIsAndChainId/10**decimals);
        assertEq(daiStakedByTokenIsAndChainId, amountToAttach);

        uint256 daiStakedAllChains = IStagingVault(address(stagingVault)).getTokenStakedAllChains(tokenSymbol);
        //console.log('daiStakedAllChains = ', daiStakedAllChains/10**decimals);
        assertEq(daiStakedAllChains, amountToAttach);

        // function detachLiquidity(
        // uint256 tokenId,
        // string memory tokenSymbol,
        // string memory targetStr,
        // string memory toChainIdStr,
        // uint256 amount,
        // uint256 swapFee

        vm.expectRevert("Theia StagingVault: Not owner of this veTHEIA");
        IStagingVault(address(stagingVault)).detachLiquidity(
            2,
            tokenSymbol,
            targetStr,
            chainIdStr,
            amountToAttach,
            0
        );

        vm.expectRevert("Theia StagingVault: Cannot remove liquidity yet");
        IStagingVault(address(stagingVault)).detachLiquidity(
            tokenId,
            tokenSymbol,
            targetStr,
            chainIdStr,
            amountToAttach,
            0
        );

        skip(7 days);

        vm.expectRevert("Theia StagingVault: the amount exceeds the liquidity of this token on this chain for TokenId");
        IStagingVault(address(stagingVault)).detachLiquidity(
            tokenId,
            tokenSymbol,
            targetStr,
            chainIdStr,
            amountToAttach + 1,
            0
        );

        nonce = IStagingVault(address(stagingVault)).detachLiquidity(
            tokenId,
            tokenSymbol,
            targetStr,
            chainIdStr,
            amountToAttach,
            0
        );

        completed = IStagingVault(address(stagingVault)).getCompletedStatus(nonce);
        assertEq(completed, true);

        balTheiaDAI = IERC20(address(theiaDAI)).balanceOf(address(stagingVault));
        assertEq(balTheiaDAI, 0);

        daiStakedAllChains = IStagingVault(address(stagingVault)).getTokenStakedAllChains(tokenSymbol);
        //console.log('daiStakedAllChains = ', daiStakedAllChains/10**decimals);
        assertEq(daiStakedAllChains, 0);

        daiBal = IERC20(address(dai)).balanceOf(address(stagingVault));
        console.log('balance of DAI in stagingVault = ', daiBal);

        //vm.expectRevert("Theia StagingVault: Insufficient funds in StagingVault to withdraw");
        //IStagingVault(address(stagingVault)).withdrawStaging(tokenStr, 2000*10**dai.decimals() + 1, user1);

        daiBal = IStagingVault(address(stagingVault)).withdrawStaging(tokenStr, 2000*10**dai.decimals(), user1);
        assertEq(daiBal, 0);

        vm.stopPrank();
    }

}