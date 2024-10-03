// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "@openzeppelin/contracts/utils/Strings.sol";

import {C3UUIDKeeper} from "../contracts/c3Caller/C3UUIDKeeper.sol";
import {IUUIDKeeper} from "../contracts/c3Caller/IUUIDKeeper.sol";
import {C3CallerDapp} from "../contracts/c3Caller/C3CallerDapp.sol";
import {C3Caller} from "../contracts/c3Caller/C3Caller.sol";
import {IC3Caller, IC3CallerProxy, IC3GovClient} from "../contracts/c3Caller/IC3Caller.sol";
import {C3CallerProxy} from "../contracts/c3Caller/C3CallerProxy.sol";
import {C3CallerProxyERC1967} from "../contracts/c3Caller/C3CallerProxyERC1967.sol";
import {C3GovClient} from "../contracts/c3Caller/C3GovClient.sol";

import {TestERC20} from "../contracts/mocks/TestERC20.sol";

import {FeeManager} from "../contracts/FeeManager.sol";
import {FeeType, IFeeManager} from "../contracts/interfaces/IFeeManager.sol";

import {CTMRWADeployer} from "../contracts/CTMRWADeployer.sol";
import {CTMRWA001TokenFactory} from "../contracts/CTMRWA001TokenFactory.sol";
import {CTMRWA001XFallback} from "../contracts/CTMRWA001XFallback.sol";
import {CTMRWA001DividendFactory} from "../contracts/CTMRWA001DividendFactory.sol";

import {CTMRWAGateway} from "../contracts/CTMRWAGateway.sol";
import {CTMRWA001X} from "../contracts/CTMRWA001X.sol";

import {ICTMRWA001} from "../contracts/interfaces/ICTMRWA001.sol";
import {ICTMRWAGateway} from "../contracts/interfaces/ICTMRWAGateway.sol";
import {ICTMRWA001X} from "../contracts/interfaces/ICTMRWA001X.sol";
import {ICTMRWA001SlotEnumerable} from "../contracts/extensions/ICTMRWA001SlotEnumerable.sol";
import {ICTMRWA001Token} from "../contracts/interfaces/ICTMRWA001Token.sol";
import {ICTMRWA001XFallback} from "../contracts/interfaces/ICTMRWA001XFallback.sol";
import {ICTMRWA001Dividend} from "../contracts/interfaces/ICTMRWA001Dividend.sol";



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
    CTMRWADeployer deployer;
    CTMRWA001TokenFactory tokenFactory;
    CTMRWAGateway gateway;
    CTMRWA001X rwa001X;
    CTMRWA001XFallback rwa001XFallback;
    CTMRWA001DividendFactory dividendFactory;


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

        vm.startPrank(admin);  // gov is admin for these tests

        ctm = new TestERC20("Continuum", "CTM", 18);
        usdc = new TestERC20("Circle USD", "USDC", 6);

        uint256 usdcBal = 100000*10**usdc.decimals();
        usdc.mint(admin, usdcBal);

        /// @dev adding CTM balance to user1 so they can pay the fee
        uint256 ctmBal = 100000 ether;
        ctm.mint(user1, ctmBal);

        //console.log("admin bal USDC = ", usdc.balanceOf(address(admin))/1e6);
        usdc.transfer(user1, usdcBal/2);
        
        deployC3Caller();
        deployFeeManager();

        deployGateway();

        deployCTMRWA001X();
        vm.stopPrank();

        vm.startPrank(address(c3Gov));

        deployRwa001XFallback(address(rwa001X));

        bool ok = gateway.attachRWAX(
            "RWA001",
            "1",
            address(rwa001X).toHexString()
        );
        assertEq(ok, true);

        deployCTMRWA001Deployer(
            rwaType,
            version,
            address(c3Gov),
            address(rwa001X),
            address(c3),
            admin,
            3
        );

        vm.stopPrank();

        vm.startPrank(user1);
        uint256 initialUserBal = usdc.balanceOf(address(user1));
        usdc.approve(address(feeManager), initialUserBal);
        vm.stopPrank();

        vm.prank(user1);
        ctm.approve(address(rwa001X), ctmBal);

        string[] memory cIdList = new string[](1);
        cIdList[0] = cID().toHexString();
        string[] memory gatewayLocal = new string[](1);
        gatewayLocal[0] = address(rwa001X).toHexString();
        vm.prank(gov);

        gateway.addChainContract("1", "ethereumGateway");
    }

    function deployGateway() internal {
        gateway = new CTMRWAGateway(
            address(c3Gov),
            address(c3),
            admin,
            4
        );
    }

    function deployCTMRWA001X() internal {
        rwa001X = new CTMRWA001X(
            address(gateway),
            address(feeManager),
            address(c3Gov),
            address(c3),
            admin,
            2
        );
    }

    function deployRwa001XFallback(address _rwa001X) internal {
        rwa001XFallback = new CTMRWA001XFallback(_rwa001X);
        rwa001X.setFallback(address(rwa001XFallback));
    }


    function deployCTMRWA001Deployer(
        uint256 _rwaType,
        uint256 _version,
        address _gov,
        address _gateway,
        address _c3callerProxy,
        address _txSender,
        uint256 _dappID
    ) internal {
        deployer = new CTMRWADeployer(
            _gov,
            _gateway,
            _c3callerProxy,
            _txSender,
            _dappID
        );

        rwa001X.setCtmRwaDeployer(address(deployer));

        tokenFactory = new CTMRWA001TokenFactory(address(deployer));
        deployer.setTokenFactory(_rwaType, _version, address(tokenFactory));
        dividendFactory = new CTMRWA001DividendFactory(address(deployer));
        ctmDividend = address(dividendFactory);
        deployer.setDividendFactory(_rwaType, _version, address(dividendFactory));

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
        c3UUIDKeeper.addOperator(address(c3CallerLogic));

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

    function CTMRWA001Deploy() public returns(uint256, address) {
        string memory tokenStr = _toLower((address(usdc).toHexString()));
        string[] memory chainIdsStr;

        uint256 ID = rwa001X.deployAllCTMRWA001X(
            true,  // include local mint
            0,
            rwaType,
            version,
            "Semi Fungible Token XChain",
            "SFTX",
            18,
            "continuumdao/",
            chainIdsStr,  // empty array - no cross-chain minting
            tokenStr
        );
        (bool ok, address tokenAddress) =  rwa001X.getAttachedTokenAddress(ID);
        assertEq(ok, true);

        return(ID, tokenAddress);
    }

    function deployAFewTokensLocal(address _ctmRwaAddr) public returns(uint256,uint256,uint256) {
        (bool ok, uint256 ID) = rwa001X.getAttachedID(_ctmRwaAddr);
        assertEq(ok, true);

        uint256 tokenId1 = rwa001X.mintNewTokenValueLocal(
            user1,
            0,
            5,
            2000,
            ID
        );

        uint256 tokenId2 = rwa001X.mintNewTokenValueLocal(
            user1,
            0,
            3,
            4000,
            ID
        );

        uint256 tokenId3 = rwa001X.mintNewTokenValueLocal(
            user1,
            0,
            1,
            6000,
            ID
        );

        return(tokenId1, tokenId2, tokenId3);
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

    // function getXChainFee(
    //     string[] memory _toChainIDsStr,
    //     bool _includeLocal,
    //     FeeType _feeType,
    //     string memory _feeTokenStr
    // ) public view returns (uint256) {

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
        feeManager.delFeeToken(tokenStr);
        feeTokenList = feeManager.getFeeTokenList();
        assertEq(feeTokenList.length, 1);
        assertEq(feeTokenList[0], address(ctm));
        vm.stopPrank();
    }

    function test_CTMRWA001XBasic() public view {
        string memory gatewayStr = gateway.getChainContract(cID().toString());
        //console.log(gatewayStr);
        address gway = stringToAddress(gatewayStr);
        //console.log(gway);
        assertEq(gway, address(gateway));
    }

    function test_CTMRWA001Deploy() public {
        string memory tokenStr = _toLower((address(usdc).toHexString()));
        string[] memory chainIdsStr;

        uint256 rwaType = 1;
        uint256 version = 1;

        uint256 ID = rwa001X.deployAllCTMRWA001X(
            true,  // include local mint
            0,
            rwaType,
            version,
            "Semi Fungible Token XChain",
            "SFTX",
            18,
            "continuumdao/",
            chainIdsStr,  // empty array - no cross-chain minting
            tokenStr
        );
        // console.log("ID");
        // console.log(ID);
        (bool ok, address ctmRwaAddr) = rwa001X.getAttachedTokenAddress(ID);
        // console.log("ctmRwaAddr");
        // console.log(ctmRwaAddr);
        assertEq(ok, true);

        uint256 tokenType = ICTMRWA001Token(ctmRwaAddr).getRWAType();
        assertEq(tokenType, rwaType);

        uint256 deployedVersion = ICTMRWA001Token(ctmRwaAddr).getVersion();
        assertEq(deployedVersion, version);
    }

    function test_CTMRWA001Mint() public {
        (uint256 ID, address ctmRwaAddr) = CTMRWA001Deploy();

        // function mintNewTokenValueLocal(
        // address toAddress_,
        // uint256 toTokenId_,  // Set to 0 to create a newTokenId
        // uint256 slot_,
        // uint256 value_,
        // address _ctmRwa001Addr
        // ) public payable virtual returns(uint256) {

        uint256 tokenId = rwa001X.mintNewTokenValueLocal(
            user1,
            0,
            5,
            2000,
            ID
        );

        assertEq(tokenId, 1);
        (uint256 id, uint256 bal, address owner, uint256 slot) = ICTMRWA001(ctmRwaAddr).getTokenInfo(tokenId);
        //console.log(id, bal, owner, slot);
        assertEq(id,1);
        assertEq(bal, 2000);
        assertEq(owner, user1);
        assertEq(slot, 5);
    }

    function test_getTokenList() public {
        vm.startPrank(admin);
        (, address ctmRwaAddr) = CTMRWA001Deploy();
        deployAFewTokensLocal(ctmRwaAddr);
        vm.stopPrank();

        address[] memory adminTokens = rwa001X.getAllTokensByAdminAddress(admin);
        assertEq(adminTokens.length, 1);  // only one CTMRWA001 token deployed
        assertEq(ctmRwaAddr, adminTokens[0]);

        address[] memory nRWA001 = rwa001X.getAllTokensByOwnerAddress(user1);  // List of CTMRWA001 tokens that user1 has or still has tokens in
        assertEq(nRWA001.length, 3);

        uint256 tokenId;
        uint256 id;
        uint256 bal;
        address owner;
        uint256 slot;

        for(uint256 i=0; i<nRWA001.length; i++) {
            tokenId = ICTMRWA001(nRWA001[i]).tokenOfOwnerByIndex(user1, i);
            (id, bal, owner, slot) = ICTMRWA001(nRWA001[i]).getTokenInfo(tokenId);
            // console.log(tokenId);
            // console.log(id);
            // console.log(bal);
            // console.log(owner);
            // console.log(slot);
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
        vm.startPrank(admin);  // this CTMRWA001 has an admin of admin
        (, address ctmRwaAddr) = CTMRWA001Deploy();
        (, uint256 tokenId2,) = deployAFewTokensLocal(ctmRwaAddr);

        address ctmDividend = ICTMRWA001(ctmRwaAddr).dividendAddr();

        ICTMRWA001Dividend(ctmDividend).setDividendToken(address(usdc));
        address token = ICTMRWA001Dividend(ctmDividend).dividendToken();
        assertEq(token, address(usdc));

        uint256 divRate = ICTMRWA001Dividend(ctmDividend).getDividendRateBySlot(3);
        assertEq(divRate, 0);

        uint256 divRate3 = 2500;
        ICTMRWA001Dividend(ctmDividend).changeDividendRate(3, divRate3);
        divRate = ICTMRWA001Dividend(ctmDividend).getDividendRateBySlot(3);
        assertEq(divRate, divRate3);

        uint256 bal2 = ICTMRWA001(ctmRwaAddr).balanceOf(tokenId2);
        uint256 dividend = ICTMRWA001Dividend(ctmDividend).getDividendByToken(tokenId2);
        assertEq(dividend, bal2*divRate3);

        uint256 divRate1 = 8000;
        ICTMRWA001Dividend(ctmDividend).changeDividendRate(1, divRate1);

        uint256 balSlot1 = ICTMRWA001(ctmRwaAddr).totalSupplyInSlot(1);
        
        dividend = ICTMRWA001Dividend(ctmDividend).getTotalDividendBySlot(1);
        assertEq(dividend, balSlot1*divRate1);

        uint256 balSlot3 = ICTMRWA001(ctmRwaAddr).totalSupplyInSlot(3);
         
        uint256 balSlot5 = ICTMRWA001(ctmRwaAddr).totalSupplyInSlot(5);
        
        uint256 divRate5 = ICTMRWA001Dividend(ctmDividend).getDividendRateBySlot(5);

        uint256 dividendTotal = ICTMRWA001Dividend(ctmDividend).getTotalDividend();
        assertEq(dividendTotal, balSlot1*divRate1 + balSlot3*divRate3 + balSlot5*divRate5);

        usdc.approve(ctmDividend, dividend);
        uint256 unclaimed = ICTMRWA001Dividend(ctmDividend).fundDividend(dividend);
        vm.stopPrank();
        assertEq(unclaimed, dividendTotal);

        uint256 tokenId = ICTMRWA001SlotEnumerable(ctmRwaAddr).tokenOfOwnerByIndex(user1, 0);
        uint256 toClaim = ICTMRWA001(ctmRwaAddr).dividendUnclaimedOf(tokenId);
        uint256 balBefore = usdc.balanceOf(user1);

        vm.stopPrank();  // end of prank admin

        vm.startPrank(user1);
        bool ok = ICTMRWA001Dividend(ctmDividend).claimDividend(1);
        vm.stopPrank();
        assertEq(ok, true);
        uint balAfter = usdc.balanceOf(user1);
        assertEq(balBefore, balAfter-toClaim);
    }

    function test_remoteDeploy() public {

        vm.startPrank(user1);
        (, address ctmRwaAddr) = CTMRWA001Deploy();
        vm.stopPrank();
        (bool ok, uint256 localID) = rwa001X.getAttachedID(ctmRwaAddr);
        assertEq(ok, true);

        // admin of the CTMRWA001 token
        string memory currentAdminStr = _toLower(user1.toHexString());

        address tokenAdmin = ICTMRWA001(ctmRwaAddr).tokenAdmin();
        assertEq(tokenAdmin, user1);

        address[] memory feeTokenList = feeManager.getFeeTokenList();
        string memory ctmRwaAddrStr = ctmRwaAddr.toHexString();
        string memory feeTokenStr = feeTokenList[0].toHexString(); // CTM
        toChainIdsStr.push("1");

        string memory targetStr = gateway.getChainContract("1");
        (,uint256 ID) = rwa001X.getAttachedID(ctmRwaAddr);
        uint256 currentNonce = c3UUIDKeeper.currentNonce();

        uint256 rwaType = ICTMRWA001Token(ctmRwaAddr).getRWAType();
        uint256 version = ICTMRWA001Token(ctmRwaAddr).getVersion();

        string memory sig = "deployCTMRWA001(string,uint256,uint256,uint256,string,string,uint8,string,string)";

        string memory tokenName = "Semi Fungible Token XChain";
        string memory symbol = "SFTX";
        uint8 decimals = 18;

        // string memory funcCall = "deployCTMRWA001(string,uint256,uint256,uint256,string,string,uint8,string,string)";
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
        //     _ctmRwa001AddrStr
        // );

        bytes memory callData = abi.encodeWithSignature(
            sig,
            currentAdminStr,
            ID,
            rwaType,
            version,
            tokenName,
            symbol,
            decimals,
            "continuumdao/",
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
        emit LogC3Call(2, testUUID, address(rwa001X), toChainIdsStr[0], targetStr, callData, bytes(""));

        // function deployAllCTMRWA001X(
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
        rwa001X.deployAllCTMRWA001X(false, localID, rwaType, version, tokenName, symbol, decimals, "", toChainIdsStr, feeTokenStr);

    }

    function test_transferToken() public {
        vm.startPrank(admin);
        (uint256 ID, address ctmRwaAddr) = CTMRWA001Deploy();
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
        string memory sig = "mintX(uint256,string,string,uint256,uint256,uint256,string,string)";

 
        (bool ok, string memory toRwaXStr) = gateway.getAttachedRWAX("RWA001", toChainIdStr);
        string memory toTokenStr = ICTMRWA001(ctmRwaAddr).getTokenContract(toChainIdStr);
        (,uint256 value,,uint256 slot) = ICTMRWA001(ctmRwaAddr).getTokenInfo(tokenId1);
        uint256 currentNonce = c3UUIDKeeper.currentNonce();

        // string memory funcCall = "mintX(uint256,string,string,uint256,uint256,uint256,string,string)";
        // bytes memory callData = abi.encodeWithSignature(
        //     funcCall,
        //     _ID,
        //     fromAddressStr,
        //     _toAddressStr,
        //     _fromTokenId,
        //     slot,
        //     value,
        //     ctmRwa001AddrStr,
        //     toTokenStr
        // );

        bytes memory callData = abi.encodeWithSignature(
            sig,
            ID,
            user1Str,
            user1Str,
            tokenId1,
            slot,
            value,
            ctmRwaAddrStr,
            toTokenStr
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

        // emit LogC3Call(_dappID, _uuid, _caller, _toChainID, _to, _data, _extra);
        vm.expectEmit(true, true, false, true);
        emit LogC3Call(2, testUUID, address(rwa001X), toChainIdStr, toRwaXStr, callData, bytes(""));

        // function transferFromX( // transfer from/to same tokenid without value
        //     string memory toAddressStr_,
        //     string memory toChainIdStr_,
        //     uint256 fromTokenId_,
        //     string memory _ctmRwa001AddrStr,
        //     string memory feeTokenStr
        // ) external;

        vm.prank(user1);
        rwa001X.transferFromX(user1Str, toChainIdStr, tokenId1, ID, feeTokenStr);
    }


    function test_valueTransferExistingTokens() public {

        vm.startPrank(admin);
        (uint256 ID, address ctmRwaAddr) = CTMRWA001Deploy();
        (uint256 tokenId1,,) = deployAFewTokensLocal(ctmRwaAddr);
        vm.stopPrank();

        string memory user1Str = user1.toHexString();
        address[] memory feeTokenList = feeManager.getFeeTokenList();
        string memory ctmRwaAddrStr = ctmRwaAddr.toHexString();
        string memory feeTokenStr = feeTokenList[0].toHexString(); // CTM
        string memory toChainIdStr = "1";

        (bool ok, string memory toRwaXStr) = gateway.getAttachedRWAX("RWA001", toChainIdStr);
        string memory toTokenStr = ICTMRWA001(ctmRwaAddr).getTokenContract(toChainIdStr);
        (,uint256 value,,uint256 slot) = ICTMRWA001(ctmRwaAddr).getTokenInfo(tokenId1);
        uint256 currentNonce = c3UUIDKeeper.currentNonce();

        string memory sig = "mintX(uint256,string,string,uint256,uint256,uint256,uint256,string,string)";

        uint256 xChainTokenId = 99;  // dummy value

        //  bytes memory callData = abi.encodeWithSignature(
        //     funcCall,
        //     ID,
        //     fromAddressStr,
        //     toAddressStr_,
        //     fromTokenId_,
        //     toTokenId_,
        //     slot,
        //     value_,
        //     _ctmRwa001AddrStr,
        //     _toTokenStr
        // );

        bytes memory callData = abi.encodeWithSignature(
            sig,
            ID,
            user1Str,
            user1Str,
            tokenId1,
            xChainTokenId,
            slot,
            value/2,  // send half the value to other chain
            ctmRwaAddrStr,
            toTokenStr
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
        emit LogC3Call(2, testUUID, address(rwa001X), toChainIdStr, toRwaXStr, callData, bytes(""));

        //  function transferFromX(
        //     uint256 fromTokenId_,
        //     string memory toAddressStr_,
        //     uint256 toTokenId_,
        //     string memory toChainIdStr_,
        //     uint256 value_,
        //     string memory _ctmRwa001AddrStr,
        //     string memory feeTokenStr
        // ) public payable virtual {

        vm.prank(user1);
        rwa001X.transferFromX(tokenId1, user1Str, xChainTokenId, toChainIdStr, value/2, ID, feeTokenStr);

    }


    function test_valueTransferNewTokenCreation() public {

        vm.startPrank(admin);
        (uint256 ID, address ctmRwaAddr) = CTMRWA001Deploy();
        (uint256 tokenId1,,) = deployAFewTokensLocal(ctmRwaAddr);
        vm.stopPrank();

        string memory user1Str = user1.toHexString();
        address[] memory feeTokenList = feeManager.getFeeTokenList();
        string memory ctmRwaAddrStr = ctmRwaAddr.toHexString();
        string memory feeTokenStr = feeTokenList[0].toHexString(); // CTM
        string memory toChainIdStr = "1";

        (bool ok, string memory toRwaXStr) = gateway.getAttachedRWAX("RWA001", toChainIdStr);
        require(ok, "CTMRWA001X: Target contract address not found");
        string memory toTokenStr = ICTMRWA001(ctmRwaAddr).getTokenContract(toChainIdStr);
        (,uint256 value,,uint256 slot) = ICTMRWA001(ctmRwaAddr).getTokenInfo(tokenId1);
        uint256 currentNonce = c3UUIDKeeper.currentNonce();

        string memory sig = "mintX(uint256,string,string,uint256,uint256,uint256,string,string)";

        // string memory funcCall = "mintX(uint256,string,string,uint256,uint256,uint256,string,string)";
        // bytes memory callData = abi.encodeWithSignature(
        //     funcCall,
        //     _ID,
        //     fromAddressStr,
        //     _toAddressStr,
        //     _fromTokenId,
        //     slot,
        //     _value,
        //     ctmRwa001Addr,
        //     toTokenStr
        // );

        bytes memory callData = abi.encodeWithSignature(
            sig,
            ID,
            user1Str,
            user1Str,
            tokenId1,
            slot,
            value/2,  // send half the value to other chain
            ctmRwaAddrStr,
            toTokenStr
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
        emit LogC3Call(2, testUUID, address(rwa001X), toChainIdStr, toRwaXStr, callData, bytes(""));

        // function transferFromX(
        //     uint256 _fromTokenId,
        //     string memory _toAddressStr,
        //     string memory _toChainIdStr,
        //     uint256 _value,
        //     uint256 _ID,
        //     string memory _feeTokenStr
        // ) public {

        vm.prank(user1);
        rwa001X.transferFromX(tokenId1, user1Str, toChainIdStr, value/2, ID, feeTokenStr);

    }

}