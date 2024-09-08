// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "./CTMRWA001Upgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract CTMRWA001MintableUpgradeable is Initializable, ContextUpgradeable, CTMRWA001Upgradeable {

    function __CTMRWA001Mintable_init(
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
    }

    function __CTMRWA001Mintable_init_unchained(
        string memory,
        string memory,
        uint8,
        address
    ) internal onlyInitializing {
    }

    function mint(
        address mintTo_,
        uint256 tokenId_,
        uint256 slot_,
        uint256 value_
    ) public virtual {
        CTMRWA001Upgradeable._mint(mintTo_, tokenId_, slot_, value_);
    }

    function mintValue(
        uint256 tokenId_,
        uint256 value_
    ) public virtual {
        CTMRWA001Upgradeable._mintValue(tokenId_, value_);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}
