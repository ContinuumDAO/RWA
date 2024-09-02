// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/Context.sol";
import "./CTM3525XSlotEnumerable.sol";
import {ICTM3525XSlotApprovable} from "./extensions/ICTM3525XSlotApprovable.sol";

contract CTM3525XSlotApprovable is Context, CTM3525XSlotEnumerable, ICTM3525XSlotApprovable {

    // @dev owner => slot => operator => approved
    mapping(address => mapping(uint256 => mapping(address => bool))) private _slotApprovals;

    constructor(string memory name_, string memory symbol_, uint8 decimals_) CTM3525XSlotEnumerable(name_, symbol_, decimals_) {
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, CTM3525XSlotEnumerable) returns (bool) {
        return
            interfaceId == type(ICTM3525XSlotApprovable).interfaceId ||
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

    function approve(address to_, uint256 tokenId_) public payable virtual override(IERC721, CTM3525X) {
        address owner = CTM3525X.ownerOf(tokenId_);
        uint256 slot = CTM3525X.slotOf(tokenId_);
        require(to_ != owner, "CTM3525X: approval to current owner");

        require(
            _msgSender() == owner || 
            CTM3525X.isApprovedForAll(owner, _msgSender()) ||
            CTM3525XSlotApprovable.isApprovedForSlot(owner, slot, _msgSender()),
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
        address owner = CTM3525X.ownerOf(tokenId_);
        uint256 slot = CTM3525X.slotOf(tokenId_);
        return (
            operator_ == owner ||
            getApproved(tokenId_) == operator_ ||
            CTM3525X.isApprovedForAll(owner, operator_) ||
            CTM3525XSlotApprovable.isApprovedForSlot(owner, slot, operator_)
        );
    }
}