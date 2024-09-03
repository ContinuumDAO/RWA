// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "../CTMRWA001SlotApprovableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract CTMRWA001AllRoundMockUpgradeable is Initializable, ContextUpgradeable, CTMRWA001SlotApprovableUpgradeable {

    function __CTMRWA001AllRoundMock_init(
            string memory name_, 
            string memory symbol_, 
            uint8 decimals_,
            address _feeManager,
            address _gov,
            address _c3CallerProxy,
            address _txSender,
            uint256 _dappID
        ) internal onlyInitializing {
        __CTMRWA001_init_unchained(
            name_,
            symbol_,
            decimals_,
            _feeManager,
            _gov,
            _c3CallerProxy,
            _txSender,
            _dappID);
        __CTMRWA001SlotEnumerable_init_unchained(
            name_,
            symbol_,
            decimals_,
            _feeManager,
            _gov,
            _c3CallerProxy,
            _txSender,
            _dappID
        );
        __CTMRWA001SlotApprovable_init_unchained(
            name_,
            symbol_,
            decimals_,
            _feeManager,
            _gov,
            _c3CallerProxy,
            _txSender,
            _dappID
        );
    }

    function __CTMRWA001AllRoundMock_init_unchained(string memory, string memory, uint8) internal onlyInitializing {
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