// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "./CTM3525XSlotEnumerableUpgradeable.sol";
import "./extensions/ICTM3525XSlotApprovableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract CTM3525XSlotApprovableUpgradeable is Initializable, ContextUpgradeable, CTM3525XSlotEnumerableUpgradeable, ICTM3525XSlotApprovableUpgradeable {

    // @dev owner => slot => operator => approved
    mapping(address => mapping(uint256 => mapping(address => bool))) private _slotApprovals;

    function __CTM3525XSlotApprovable_init(string memory name_, string memory symbol_, uint8 decimals_) internal onlyInitializing {
        __CTM3525X_init_unchained(name_, symbol_, decimals_);
        __CTM3525XSlotEnumerable_init_unchained(name_, symbol_, decimals_);
    }

    function __CTM3525XSlotApprovable_init_unchained(string memory, string memory, uint8) internal onlyInitializing {
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, CTM3525XSlotEnumerableUpgradeable) returns (bool) {
        return
            interfaceId == type(ICTM3525XSlotApprovableUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function setApprovalForSlot(
        address owner_,
        uint256 slot_,
        address operator_,
        bool approved_
    ) public payable virtual override {
        require(_msgSender() == owner_ || isApprovedForAll(owner_, _msgSender()), "CTM3525XSlotApprovable: caller is not owner nor approved for all");
        _setApprovalForSlot(owner_, slot_, operator_, approved_);
    }

    function isApprovedForSlot(
        address owner_,
        uint256 slot_,
        address operator_
    ) public view virtual override returns (bool) {
        return _slotApprovals[owner_][slot_][operator_];
    }

    function approve(address to_, uint256 tokenId_) public payable virtual override(IERC721Upgradeable, CTM3525XUpgradeable) {
        address owner = CTM3525XUpgradeable.ownerOf(tokenId_);
        uint256 slot = CTM3525XUpgradeable.slotOf(tokenId_);
        require(to_ != owner, "CTM3525X: approval to current owner");

        require(
            _msgSender() == owner || 
            CTM3525XUpgradeable.isApprovedForAll(owner, _msgSender()) ||
            CTM3525XSlotApprovableUpgradeable.isApprovedForSlot(owner, slot, _msgSender()),
            "CTM3525X: approve caller is not owner nor approved for all/slot"
        );

        _approve(to_, tokenId_);
    }

    function _setApprovalForSlot(
        address owner_,
        uint256 slot_,
        address operator_,
        bool approved_
    ) internal virtual {
        require(owner_ != operator_, "CTM3525XSlotApprovable: approve to owner");
        _slotApprovals[owner_][slot_][operator_] = approved_;
        emit ApprovalForSlot(owner_, slot_, operator_, approved_);
    }

    function _isApprovedOrOwner(address operator_, uint256 tokenId_) internal view virtual override returns (bool) {
        _requireMinted(tokenId_);
        address owner = CTM3525XUpgradeable.ownerOf(tokenId_);
        uint256 slot = CTM3525XUpgradeable.slotOf(tokenId_);
        return (
            operator_ == owner ||
            getApproved(tokenId_) == operator_ ||
            CTM3525XUpgradeable.isApprovedForAll(owner, operator_) ||
            CTM3525XSlotApprovableUpgradeable.isApprovedForSlot(owner, slot, operator_)
        );
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}