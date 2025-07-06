// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.27;

// import "forge-std/console.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Context } from "@openzeppelin/contracts/utils/Context.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { ICTMRWA1, ITokenContract } from "../core/ICTMRWA1.sol";

import { FeeType, IERC20Extended, IFeeManager } from "../managers/IFeeManager.sol";
import { ICTMRWA1Sentry } from "../sentry/ICTMRWA1Sentry.sol";
import { ICTMRWA1SentryManager } from "../sentry/ICTMRWA1SentryManager.sol";
import { ICTMRWAMap } from "../shared/ICTMRWAMap.sol";

interface IZkMeVerify {
    function hasApproved(address cooperator, address user) external view returns (bool);
}

contract CTMRWA1Identity is Context {
    using Strings for *;
    using SafeERC20 for IERC20;

    uint256 rwaType;
    uint256 version;
    address public ctmRwa1Map;
    address public sentryManager;
    address public zkMeVerifierAddress;
    address public feeManager;

    modifier onlyIdChain() {
        require(zkMeVerifierAddress != address(0));
        _;
    }

    event LogFallback(bytes4 selector, bytes data, bytes reason);
    event UserVerified(address indexed user);

    constructor(
        uint256 _rwaType,
        uint256 _version,
        address _map,
        address _sentryManager,
        address _verifierAddress,
        address _feeManager
    ) {
        rwaType = _rwaType;
        version = _version;
        ctmRwa1Map = _map;
        sentryManager = _sentryManager;
        zkMeVerifierAddress = _verifierAddress;
        feeManager = _feeManager;
    }

    function verifyPerson(uint256 _ID, string[] memory _chainIdsStr, string memory _feeTokenStr)
        public
        onlyIdChain
        returns (bool)
    {
        require(zkMeVerifierAddress != address(0), "CTMRWA1Identity: zkMe verifier has to be set");

        (bool ok, address sentryAddr) = ICTMRWAMap(ctmRwa1Map).getSentryContract(_ID, rwaType, version);
        require(ok, "CTMRWA1Identity: Could not find _ID or its sentry address");

        require(ICTMRWA1Sentry(sentryAddr).kycSwitch(), "CTMRWA1Identity: KYC is not enabled for this CTMRWA1");

        require(
            !ICTMRWA1Sentry(sentryAddr).isAllowableTransfer(_msgSender().toHexString()),
            "CTMRWA1Identity: User is already whitelisted"
        );

        (,, address cooperator) = ICTMRWA1Sentry(sentryAddr).getZkMeParams();
        require(cooperator != address(0), "CTMRWA1Identity: zkMe cooperator address has not been set");
        bool isValid = IZkMeVerify(zkMeVerifierAddress).hasApproved(cooperator, _msgSender());

        require(!isValid, "CTMRWA1Identity: Invalid KYC");

        uint256 fee = _getFee(FeeType.KYC, 1, _chainIdsStr, _feeTokenStr);
        _payFee(fee, _feeTokenStr);

        ICTMRWA1SentryManager(sentryManager).addWhitelist(
            _ID, _stringToArray(_msgSender().toHexString()), _boolToArray(true), _chainIdsStr, _feeTokenStr
        );

        return (true);
    }

    function isKycChain() public view returns (bool) {
        return (zkMeVerifierAddress != address(0));
    }

    function isVerifiedPerson(uint256 _ID, address _wallet) public view onlyIdChain returns (bool) {
        (bool ok, address sentryAddr) = ICTMRWAMap(ctmRwa1Map).getSentryContract(_ID, rwaType, version);
        require(ok, "CTMRWA1Identity: Could not find _ID or its sentry address");
        require(ICTMRWA1Sentry(sentryAddr).kycSwitch(), "CTMRWA1Identity: KYC not set");

        (,, address cooperator) = ICTMRWA1Sentry(sentryAddr).getZkMeParams();
        require(cooperator != address(0), "CTMRWA1Identity: zkMe cooperator address not set");

        bool isValid = IZkMeVerify(zkMeVerifierAddress).hasApproved(cooperator, _wallet);

        return isValid;
    }

    function _payFee(uint256 _fee, string memory _feeTokenStr) internal returns (bool) {
        if (_fee > 0) {
            address feeToken = stringToAddress(_feeTokenStr);
            uint256 feeWei = _fee * 10 ** (IERC20Extended(feeToken).decimals() - 2);

            IERC20(feeToken).transferFrom(_msgSender(), address(this), feeWei);

            IERC20(feeToken).approve(feeManager, feeWei);
            IFeeManager(feeManager).payFee(feeWei, _feeTokenStr);
        }
        return (true);
    }

    function _getFee(FeeType _feeType, uint256 _nItems, string[] memory _toChainIdsStr, string memory _feeTokenStr)
        internal
        view
        returns (uint256)
    {
        bool includeLocal = false;

        uint256 fee = IFeeManager(feeManager).getXChainFee(_toChainIdsStr, includeLocal, _feeType, _feeTokenStr);

        return (fee * _nItems);
    }

    function stringToAddress(string memory str) internal pure returns (address) {
        bytes memory strBytes = bytes(str);
        require(strBytes.length == 42, "CTMRWA1Identity: Invalid address length");
        bytes memory addrBytes = new bytes(20);

        for (uint256 i = 0; i < 20; i++) {
            addrBytes[i] = bytes1(hexCharToByte(strBytes[2 + i * 2]) * 16 + hexCharToByte(strBytes[3 + i * 2]));
        }

        return address(uint160(bytes20(addrBytes)));
    }

    function hexCharToByte(bytes1 char) internal pure returns (uint8) {
        uint8 byteValue = uint8(char);
        if (byteValue >= uint8(bytes1("0")) && byteValue <= uint8(bytes1("9"))) {
            return byteValue - uint8(bytes1("0"));
        } else if (byteValue >= uint8(bytes1("a")) && byteValue <= uint8(bytes1("f"))) {
            return 10 + byteValue - uint8(bytes1("a"));
        } else if (byteValue >= uint8(bytes1("A")) && byteValue <= uint8(bytes1("F"))) {
            return 10 + byteValue - uint8(bytes1("A"));
        }
        revert("Invalid hex character");
    }

    function _stringToArray(string memory _string) internal pure returns (string[] memory) {
        string[] memory strArray = new string[](1);
        strArray[0] = _string;
        return (strArray);
    }

    function _boolToArray(bool _bool) internal pure returns (bool[] memory) {
        bool[] memory boolArray = new bool[](1);
        boolArray[0] = _bool;
        return (boolArray);
    }
}
