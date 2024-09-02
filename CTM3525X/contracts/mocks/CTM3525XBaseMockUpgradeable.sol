// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "../CTM3525XUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract CTM3525XBaseMockUpgradeable is Initializable, ContextUpgradeable, CTM3525XUpgradeable {
    function __CTM3525XBaseMock_init(string memory name_, string memory symbol_, uint8 decimals_) internal onlyInitializing {
        __CTM3525X_init_unchained(name_, symbol_, decimals_);
    }

    function __CTM3525XBaseMock_init_unchained(string memory, string memory, uint8) internal onlyInitializing {
    }

    function mint(
        address mintTo_,
        uint256 tokenId_,
        uint256 slot_,
        uint256 value_
    ) public virtual {
        CTM3525XUpgradeable._mint(mintTo_, tokenId_, slot_, value_);
    }

    function mintValue(
        uint256 tokenId_,
        uint256 value_
    ) public virtual {
        CTM3525XUpgradeable._mintValue(tokenId_, value_);
    }

    function burn(uint256 tokenId_) public virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId_), "CTM3525X: caller is not token owner nor approved");
        CTM3525XUpgradeable._burn(tokenId_);
    }

    function burnValue(uint256 tokenId_, uint256 burnValue_) public virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId_), "CTM3525X: caller is not token owner nor approved");
        CTM3525XUpgradeable._burnValue(tokenId_, burnValue_);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}