// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "./interface/ICTMRWA001MetadataDescriptorUpgradeable.sol";
import "../extensions/ICTMRWA001MetadataUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract CTMRWA001MetadataDescriptorUpgradeable is Initializable, ICTMRWA001MetadataDescriptorUpgradeable {

    using Strings for uint256;

    function __CTMRWA001MetadataDescriptor_init() internal onlyInitializing {
    }

    function __CTMRWA001MetadataDescriptor_init_unchained() internal onlyInitializing {
    }
    function constructContractURI() external view override returns (string memory) {
        ICTMRWA001MetadataUpgradeable CTMRWA001 = ICTMRWA001MetadataUpgradeable(msg.sender);
        return 
            string(
                abi.encodePacked(
                    /* solhint-disable */
                    'data:application/json;base64,',
                    Base64.encode(
                        abi.encodePacked(
                            '{"name":"', 
                            CTMRWA001.name(),
                            '","description":"',
                            _contractDescription(),
                            '","image":"',
                            _contractImage(),
                            '","valueDecimals":"', 
                            uint256(CTMRWA001.valueDecimals()).toString(),
                            '"}'
                        )
                    )
                    /* solhint-enable */
                )
            );
    }

    function constructSlotURI(uint256 slot_) external view override returns (string memory) {
        return
            string(
                abi.encodePacked(
                    /* solhint-disable */
                    'data:application/json;base64,',
                    Base64.encode(
                        abi.encodePacked(
                            '{"name":"', 
                            _slotName(slot_),
                            '","description":"',
                            _slotDescription(slot_),
                            '","image":"',
                            _slotImage(slot_),
                            '","properties":',
                            _slotProperties(slot_),
                            '}'
                        )
                    )
                    /* solhint-enable */
                )
            );
    }

    function constructTokenURI(uint256 tokenId_) external view override returns (string memory) {
        ICTMRWA001MetadataUpgradeable CTMRWA001 = ICTMRWA001MetadataUpgradeable(msg.sender);
        return 
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            /* solhint-disable */
                            '{"name":"',
                            _tokenName(tokenId_),
                            '","description":"',
                            _tokenDescription(tokenId_),
                            '","image":"',
                            _tokenImage(tokenId_),
                            '","balance":"',
                            CTMRWA001.balanceOf(tokenId_).toString(),
                            '","slot":"',
                            CTMRWA001.slotOf(tokenId_).toString(),
                            '","properties":',
                            _tokenProperties(tokenId_),
                            "}"
                            /* solhint-enable */
                        )
                    )
                )
            );
    }

    function _contractDescription() internal view virtual returns (string memory) {
        return "";
    }

    function _contractImage() internal view virtual returns (bytes memory) {
        return "";
    }

    function _slotName(uint256 slot_) internal view virtual returns (string memory) {
        slot_;
        return "";
    }

    function _slotDescription(uint256 slot_) internal view virtual returns (string memory) {
        slot_;
        return "";
    }

    function _slotImage(uint256 slot_) internal view virtual returns (bytes memory) {
        slot_;
        return "";
    }

    function _slotProperties(uint256 slot_) internal view virtual returns (string memory) {
        slot_;
        return "[]";
    }

    function _tokenName(uint256 tokenId_) internal view virtual returns (string memory) {
        // solhint-disable-next-line
        return 
            string(
                abi.encodePacked(
                    ICTMRWA001MetadataUpgradeable(msg.sender).name(), 
                    " #", tokenId_.toString()
                )
            );
    }

    function _tokenDescription(uint256 tokenId_) internal view virtual returns (string memory) {
        tokenId_;
        return "";
    }


    function _tokenImage(uint256 tokenId_) internal view virtual returns (bytes memory) {
        tokenId_;
        return "";
    }

    function _tokenProperties(uint256 tokenId_) internal view virtual returns (string memory) {
        tokenId_;
        return "{}";
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}