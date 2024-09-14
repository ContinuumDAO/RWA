// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7 <0.9;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

contract ContextUpgradeableWithInit is ContextUpgradeable {
    constructor() payable initializer {
        __Context_init();
    }
}
import "../CTMRWA001Upgradeable.sol";

contract CTMRWA001UpgradeableWithInit is CTMRWA001Upgradeable {
    constructor(
            address _admin,
            string memory name_, 
            string memory symbol_, 
            uint8 decimals_,
            string memory baseURI_,
            address _ctmRwa001XChain
        ) payable initializer {
        __CTMRWA001_init(
            _admin,
            name_,
            symbol_,
            decimals_,
            baseURI_,
            _ctmRwa001XChain
        );
    }
}
import "../CTMRWA001BurnableUpgradeable.sol";

contract CTMRWA001BurnableUpgradeableWithInit is CTMRWA001BurnableUpgradeable {
    constructor(
        address _admin,
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        string memory baseURI_,
        address _ctmRwa001XChain
    ) payable initializer {
        __CTMRWA001Burnable_init(
            _admin,
            name_,
            symbol_,
            decimals_,
            baseURI_,
            _ctmRwa001XChain
        );
    }
}
import "../CTMRWA001MintableUpgradeable.sol";

contract CTMRWA001MintableUpgradeableWithInit is CTMRWA001MintableUpgradeable {
    constructor(
        address _admin,
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        string memory baseURI_,
        address _ctmRwa001XChain
    ) payable initializer {
        __CTMRWA001Mintable_init(
            _admin,
            name_,
            symbol_,
            decimals_,
            baseURI_,
            _ctmRwa001XChain
        );
    }
}
import "../CTMRWA001SlotApprovableUpgradeable.sol";

contract CTMRWA001SlotApprovableUpgradeableWithInit is CTMRWA001SlotApprovableUpgradeable {
    constructor(
        address _admin,
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        string memory baseURI_,
        address _ctmRwa001XChain
    )
     payable initializer {
        __CTMRWA001SlotApprovable_init(
            _admin,
            name_,
            symbol_,
            decimals_,
            baseURI_,
           _ctmRwa001XChain
        );
    }
}
import "../CTMRWA001SlotEnumerableUpgradeable.sol";

contract CTMRWA001SlotEnumerableUpgradeableWithInit is CTMRWA001SlotEnumerableUpgradeable {
    constructor(
        address _admin,
        string memory name_, 
        string memory symbol_, 
        uint8 decimals_,
        string memory baseURI_,
        address _ctmRwa001XChain
    ) payable initializer {
        __CTMRWA001SlotEnumerable_init(
            _admin,
            name_,
            symbol_,
            decimals_,
            baseURI_,
            _ctmRwa001XChain
        );
    }
}
import "./CTMRWA001AllRoundMockUpgradeable.sol";

contract CTMRWA001AllRoundMockUpgradeableWithInit is CTMRWA001AllRoundMockUpgradeable {
    constructor(
        address _admin,
        string memory name_, 
        string memory symbol_, 
        uint8 decimals_,
        string memory baseURI_,
        address _ctmRwa001XChain
    ) payable initializer {
        __CTMRWA001AllRoundMock_init(
            _admin,
            name_,
            symbol_,
            decimals_,
            baseURI_,
            _ctmRwa001XChain
        );
    }
}
import "./CTMRWA001BaseMockUpgradeable.sol";

contract CTMRWA001BaseMockUpgradeableWithInit is CTMRWA001BaseMockUpgradeable {
    constructor(
        address _admin,
        string memory name_, 
        string memory symbol_, 
        uint8 decimals_,
        string memory baseURI_,
        address _ctmRwa001XChain
    ) payable initializer {
        __CTMRWA001BaseMock_init(
            _admin,
            name_,
            symbol_,
            decimals_,
            baseURI_,
            _ctmRwa001XChain
        );
    }
}
import "./NonReceiverMockUpgradeable.sol";

contract NonReceiverMockUpgradeableWithInit is NonReceiverMockUpgradeable {
    constructor() payable initializer {
        __NonReceiverMock_init();
    }
}
import "../periphery/CTMRWA001MetadataDescriptorUpgradeable.sol";

contract CTMRWA001MetadataDescriptorUpgradeableWithInit is CTMRWA001MetadataDescriptorUpgradeable {
    constructor() payable initializer {
        __CTMRWA001MetadataDescriptor_init();
    }
}
