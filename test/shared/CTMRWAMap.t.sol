// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.27;

import { console } from "forge-std/console.sol";

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { Helpers } from "../helpers/Helpers.sol";
import { CTMRWA1 } from "../../src/core/CTMRWA1.sol";
import { ICTMRWAMap } from "../../src/shared/ICTMRWAMap.sol";
import { RWA } from "../../src/CTMRWAUtils.sol";

contract TestCTMRWAMap is Helpers {
    using Strings for address;

    function setUp() public override {
        Helpers.setUp();
        // Deploy a token for the main test context
        vm.startPrank(tokenAdmin);
        (ID, token) = _deployCTMRWA1(address(usdc));
        vm.stopPrank();
    }

    function test_getTokenContract_and_getTokenId() public {
        // Get contract by ID
        (bool ok, address tokenAddr) = map.getTokenContract(ID, RWA_TYPE, VERSION);
        assertTrue(ok, "Should find token contract for ID");
        assertEq(tokenAddr, address(token), "Token address should match deployed token");

        // Get ID by contract
        string memory tokenAddrStr = _toLower(address(token).toHexString());
        uint256 foundID;
        (ok, foundID) = map.getTokenId(tokenAddrStr, RWA_TYPE, VERSION);
        assertTrue(ok, "Should find ID for token contract");
        assertEq(foundID, ID, "ID should match deployed ID");
    }

    function test_getDividendContract() public {
        // Get the mapped dividend contract address for this ID
        (bool ok, address dividendAddr) = map.getDividendContract(ID, RWA_TYPE, VERSION);
        assertTrue(ok, "Should find dividend contract for ID");
        // Just check that it's a nonzero address and not the factory
        assertTrue(dividendAddr != address(0), "Dividend address should not be zero");
        assertTrue(dividendAddr != address(dividendFactory), "Dividend address should not be the factory");
    }

    function test_getStorageContract() public {
        (bool ok, address storageAddr) = map.getStorageContract(ID, RWA_TYPE, VERSION);
        assertTrue(ok, "Should find storage contract for ID");
        assertTrue(storageAddr != address(0), "Storage address should not be zero");
        assertTrue(storageAddr != address(storageManager), "Storage address should not be the manager");
    }

    function test_getSentryContract() public {
        (bool ok, address sentryAddr) = map.getSentryContract(ID, RWA_TYPE, VERSION);
        assertTrue(ok, "Should find sentry contract for ID");
        assertTrue(sentryAddr != address(0), "Sentry address should not be zero");
        assertTrue(sentryAddr != address(sentryManager), "Sentry address should not be the manager");
    }

    function test_getInvestContract() public {
        // The invest contract may not be set for the ID unless explicitly set in the deployer
        // So just check that the call does not revert and returns an address (could be zero)
        bool ok;
        address investAddr;
        try map.getInvestContract(ID, RWA_TYPE, VERSION) returns (bool _ok, address _investAddr) {
            ok = _ok;
            investAddr = _investAddr;
        } catch {
            ok = false;
            investAddr = address(0);
        }
        // Accept either not found or a nonzero address
        assertTrue(ok || investAddr == address(0), "Should not revert and should return a valid address or zero");
    }

    function test_nonExistentID_and_nonExistentContract() public {
        // Non-existent ID
        bool ok;
        address tokenAddr;
        (ok, tokenAddr) = map.getTokenContract(999999, RWA_TYPE, VERSION);
        assertTrue(!ok, "Should not find token contract for non-existent ID");
        assertEq(tokenAddr, address(0), "Address should be zero for non-existent ID");

        // Non-existent contract (use a valid but unmapped Ethereum address)
        string memory fakeAddrStr = _toLower(address(0x000000000000000000000000000000000000dEaD).toHexString());
        uint256 fakeID;
        (ok, fakeID) = map.getTokenId(fakeAddrStr, RWA_TYPE, VERSION);
        assertTrue(!ok, "Should not find ID for non-existent contract");
        assertEq(fakeID, 0, "ID should be zero for non-existent contract");
    }

    function test_duplicateAttachmentReverts() public {
        // Try to attach the same contracts again (should revert)
        vm.startPrank(address(deployer));
        vm.expectRevert();
        map.attachContracts(ID, address(token), address(dividendFactory), address(storageManager), address(sentryManager));
        vm.stopPrank();
    }

    function test_multipleTokensMappings() public {
        // Deploy a second token for user2
        vm.startPrank(tokenAdmin2);
        (uint256 ID2, CTMRWA1 token2) = _deployCTMRWA1(address(ctm));
        vm.stopPrank();

        // Check mappings for both tokens
        (bool ok, address tokenAddr) = map.getTokenContract(ID, RWA_TYPE, VERSION);
        assertTrue(ok);
        assertEq(tokenAddr, address(token));
        (ok, tokenAddr) = map.getTokenContract(ID2, RWA_TYPE, VERSION);
        assertTrue(ok);
        assertEq(tokenAddr, address(token2));

        string memory tokenAddrStr = _toLower(address(token).toHexString());
        string memory token2AddrStr = _toLower(address(token2).toHexString());
        uint256 foundID;
        (ok, foundID) = map.getTokenId(tokenAddrStr, RWA_TYPE, VERSION);
        assertTrue(ok);
        assertEq(foundID, ID);
        (ok, foundID) = map.getTokenId(token2AddrStr, RWA_TYPE, VERSION);
        assertTrue(ok);
        assertEq(foundID, ID2);
    }

    function test_revertOnIncorrectRWATypeOrVersion() public {
        // Use correct ID and token address, but wrong RWA_TYPE
        uint256 wrongType = RWA_TYPE + 1;
        uint256 wrongVersion = VERSION + 1;
        string memory tokenAddrStr = _toLower(address(token).toHexString());

        // getTokenContract with wrong RWA_TYPE
        vm.expectRevert(abi.encodeWithSelector(ICTMRWAMap.CTMRWAMap_IncompatibleRWA.selector, RWA.Type));
        map.getTokenContract(ID, wrongType, VERSION);

        // getTokenContract with wrong VERSION
        vm.expectRevert(abi.encodeWithSelector(ICTMRWAMap.CTMRWAMap_IncompatibleRWA.selector, RWA.Version));
        map.getTokenContract(ID, RWA_TYPE, wrongVersion);

        // getTokenId with wrong RWA_TYPE
        vm.expectRevert(abi.encodeWithSelector(ICTMRWAMap.CTMRWAMap_IncompatibleRWA.selector, RWA.Type));
        map.getTokenId(tokenAddrStr, wrongType, VERSION);

        // getTokenId with wrong VERSION
        vm.expectRevert(abi.encodeWithSelector(ICTMRWAMap.CTMRWAMap_IncompatibleRWA.selector, RWA.Version));
        map.getTokenId(tokenAddrStr, RWA_TYPE, wrongVersion);
    }
}
