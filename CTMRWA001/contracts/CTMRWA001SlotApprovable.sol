// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/Context.sol";
import "./CTMRWA001SlotEnumerable.sol";
import {ICTMRWA001SlotApprovable} from "./extensions/ICTMRWA001SlotApprovable.sol";

contract CTMRWA001SlotApprovable is Context, CTMRWA001SlotEnumerable, ICTMRWA001SlotApprovable {

    // @dev owner => slot => operator => approved
    mapping(address => mapping(uint256 => mapping(address => bool))) private _slotApprovals;

    constructor(
        address _admin,
        string memory name_, 
        string memory symbol_, 
        uint8 decimals_,
        string memory baseURI_,
        address _ctmRwa001XChain
    ) CTMRWA001SlotEnumerable(
        _admin,
        name_,
        symbol_,
        decimals_,
        baseURI_,
        _ctmRwa001XChain
    ) {}

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, CTMRWA001SlotEnumerable) returns (bool) {
        return
            interfaceId == type(ICTMRWA001SlotApprovable).interfaceId ||
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

    function approve(address to_, uint256 tokenId_) public payable virtual override(IERC721, CTMRWA001) {
        address owner = CTMRWA001.ownerOf(tokenId_);
        uint256 slot = CTMRWA001.slotOf(tokenId_);
        require(to_ != owner, "CTMRWA001: approval to current owner");

        require(
            _msgSender() == owner || 
            CTMRWA001.isApprovedForAll(owner, _msgSender()) ||
            CTMRWA001SlotApprovable.isApprovedForSlot(owner, slot, _msgSender()),
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
        address owner = CTMRWA001.ownerOf(tokenId_);
        uint256 slot = CTMRWA001.slotOf(tokenId_);
        return (
            operator_ == owner ||
            getApproved(tokenId_) == operator_ ||
            CTMRWA001.isApprovedForAll(owner, operator_) ||
            CTMRWA001SlotApprovable.isApprovedForSlot(owner, slot, operator_)
        );
    }
}