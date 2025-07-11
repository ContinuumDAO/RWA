// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.22;

import { console } from "forge-std/console.sol";

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { Helpers } from "../helpers/Helpers.sol";

import { ICTMRWAERC20 } from "../../src/deployment/ICTMRWAERC20.sol";
import { ICTMRWAERC20Deployer } from "../../src/deployment/ICTMRWAERC20Deployer.sol";

contract TestERC20Deployer is Helpers {
    using Strings for *;

    function test_deployErc20() public {
        vm.startPrank(tokenAdmin);
        // (ID, token) = CTMRWA1Deploy();

        (ID, token) = _deployCTMRWA1(address(usdc));
        _createSomeSlots(ID, address(usdc), address(rwa1X));

        uint256 slot = 1;
        string memory name = "Basic Stuff";

        string memory feeTokenStr = _toLower((address(usdc).toHexString()));

        token.deployErc20(slot, name, address(usdc));

        address newErc20 = token.getErc20(slot);

        // console.log(newErc20);
        string memory newName = ICTMRWAERC20(newErc20).name();
        string memory newSymbol = ICTMRWAERC20(newErc20).symbol();
        uint8 newDecimals = ICTMRWAERC20(newErc20).decimals();
        uint256 ts = ICTMRWAERC20(newErc20).totalSupply();

        assertEq(stringsEqual(newName, "slot 1| Basic Stuff"), true);
        // console.log(newName);
        assertEq(stringsEqual(newSymbol, "SFTX"), true);
        assertEq(newDecimals, 18);
        assertEq(ts, 0);

        vm.expectRevert("RWA: ERC20 slot already exists");
        token.deployErc20(slot, name, address(usdc));

        vm.expectRevert("RWA: Slot does not exist");
        token.deployErc20(99, name, address(usdc));

        uint256 tokenId1User1 = rwa1X.mintNewTokenValueLocal(user1, 0, slot, 2000, ID, feeTokenStr);

        uint256 balUser1 = ICTMRWAERC20(newErc20).balanceOf(user1);
        assertEq(balUser1, 2000);

        ts = ICTMRWAERC20(newErc20).totalSupply();
        assertEq(ts, 2000);

        rwa1X.mintNewTokenValueLocal(
            user2,
            0,
            slot,
            3000,
            ID,
            feeTokenStr
        );

        ts = ICTMRWAERC20(newErc20).totalSupply();
        assertEq(ts, 5000);

        rwa1X.mintNewTokenValueLocal(
            user2,
            0,
            slot,
            4000,
            ID,
            feeTokenStr
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
        assertEq(balUser1After, balUser1 - 1000);
        assertEq(balUser2After, balUser2 + 1000);
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
            feeTokenStr
        );
        vm.stopPrank();

        vm.startPrank(user1);
        uint256 balTokenId2 = token.balanceOf(tokenId2User1);
        assertEq(balTokenId2, 3000);
        ICTMRWAERC20(newErc20).transfer(user2, 2000);
        assertEq(token.balanceOf(tokenId1User1), 0); // 1000 - 1000
        assertEq(token.balanceOf(tokenId2User1), 2000); // 3000 - 1000
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
}
