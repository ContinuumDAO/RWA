// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "./CTMRWA001MintableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract CTMRWA001BurnableUpgradeable is Initializable, ContextUpgradeable, CTMRWA001MintableUpgradeable {

    function __CTMRWA001Burnable_init(
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
        __CTMRWA001Mintable_init_unchained(
            name_, 
            symbol_, 
            decimals_,
            _ctmRwa001XChain
        );
    }

    function __CTMRWA001Burnable_init_unchained(
        string memory,
        string memory,
        uint8
    ) internal onlyInitializing {
    }

    function burn(uint256 tokenId_) public virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId_), "CTMRWA001: caller is not token owner nor approved");
        CTMRWA001Upgradeable._burn(tokenId_);
    }

    function burnValue(uint256 tokenId_, uint256 burnValue_) public virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId_), "CTMRWA001: caller is not token owner nor approved");
        CTMRWA001Upgradeable._burnValue(tokenId_, burnValue_);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}
