// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "./CTMRWA001SlotEnumerableUpgradeable.sol";
import "./extensions/ICTMRWA001SlotApprovableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract CTMRWA001SlotApprovableUpgradeable is Initializable, ContextUpgradeable, CTMRWA001SlotEnumerableUpgradeable, ICTMRWA001SlotApprovableUpgradeable {

    // @dev owner => slot => operator => approved
    mapping(address => mapping(uint256 => mapping(address => bool))) private _slotApprovals;

    function __CTMRWA001SlotApprovable_init(
        string memory name_, 
        string memory symbol_, 
        uint8 decimals_,
        address _ctmRwa001XChain
        ) internal onlyInitializing {
        __CTMRWA001_init_unchained(
            name_, 
            symbol_, 
            decimals_,
            _ctmRwa001XChain
        );
        __CTMRWA001SlotEnumerable_init_unchained(
            name_,
            symbol_,
            decimals_,
            _ctmRwa001XChain
        );
    }

    function __CTMRWA001SlotApprovable_init_unchained(
        string memory, 
        string memory, 
        uint8,
        address
    ) internal onlyInitializing {
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, CTMRWA001SlotEnumerableUpgradeable) returns (bool) {
        return
            interfaceId == type(ICTMRWA001SlotApprovableUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function setApprovalForSlot(
        address owner_,
        uint256 slot_,
        address operator_,
        bool approved_
    ) public payable virtual override {
        require(_msgSender() == owner_ || isApprovedForAll(owner_, _msgSender()), "CTMRWA001SlotApprovable: caller is not owner nor approved for all");
        _setApprovalForSlot(owner_, slot_, operator_, approved_);
    }

    function isApprovedForSlot(
        address owner_,
        uint256 slot_,
        address operator_
    ) public view virtual override returns (bool) {
        return _slotApprovals[owner_][slot_][operator_];
    }

    function approve(address to_, uint256 tokenId_) public payable virtual override(IERC721Upgradeable, CTMRWA001Upgradeable) {
        address owner = CTMRWA001Upgradeable.ownerOf(tokenId_);
        uint256 slot = CTMRWA001Upgradeable.slotOf(tokenId_);
        require(to_ != owner, "CTMRWA001: approval to current owner");

        require(
            _msgSender() == owner || 
            CTMRWA001Upgradeable.isApprovedForAll(owner, _msgSender()) ||
            CTMRWA001SlotApprovableUpgradeable.isApprovedForSlot(owner, slot, _msgSender()),
            "CTMRWA001: approve caller is not owner nor approved for all/slot"
        );

        _approve(to_, tokenId_);
    }

    function _setApprovalForSlot(
        address owner_,
        uint256 slot_,
        address operator_,
        bool approved_
    ) internal virtual {
        require(owner_ != operator_, "CTMRWA001SlotApprovable: approve to owner");
        _slotApprovals[owner_][slot_][operator_] = approved_;
        emit ApprovalForSlot(owner_, slot_, operator_, approved_);
    }

    function _isApprovedOrOwner(address operator_, uint256 tokenId_) internal view virtual override returns (bool) {
        _requireMinted(tokenId_);
        address owner = CTMRWA001Upgradeable.ownerOf(tokenId_);
        uint256 slot = CTMRWA001Upgradeable.slotOf(tokenId_);
        return (
            operator_ == owner ||
            getApproved(tokenId_) == operator_ ||
            CTMRWA001Upgradeable.isApprovedForAll(owner, operator_) ||
            CTMRWA001SlotApprovableUpgradeable.isApprovedForSlot(owner, slot, operator_)
        );
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}