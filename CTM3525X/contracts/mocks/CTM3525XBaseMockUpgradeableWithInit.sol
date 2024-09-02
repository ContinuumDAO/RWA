// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7 <0.9;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

contract ContextUpgradeableWithInit is ContextUpgradeable {
    constructor() payable initializer {
        __Context_init();
    }
}
import "../CTM3525XUpgradeable.sol";

contract CTM3525XUpgradeableWithInit is CTM3525XUpgradeable {
    constructor(string memory name_, string memory symbol_, uint8 decimals_) payable initializer {
        __CTM3525X_init(name_, symbol_, decimals_);
    }
}
import "../CTM3525XBurnableUpgradeable.sol";

contract CTM3525XBurnableUpgradeableWithInit is CTM3525XBurnableUpgradeable {
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) payable initializer {
        __CTM3525XBurnable_init(name_, symbol_, decimals_);
    }
}
import "../CTM3525XMintableUpgradeable.sol";

contract CTM3525XMintableUpgradeableWithInit is CTM3525XMintableUpgradeable {
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) payable initializer {
        __CTM3525XMintable_init(name_, symbol_, decimals_);
    }
}
import "../CTM3525XSlotApprovableUpgradeable.sol";

contract CTM3525XSlotApprovableUpgradeableWithInit is CTM3525XSlotApprovableUpgradeable {
    constructor(string memory name_, string memory symbol_, uint8 decimals_) payable initializer {
        __CTM3525XSlotApprovable_init(name_, symbol_, decimals_);
    }
}
import "../CTM3525XSlotEnumerableUpgradeable.sol";

contract CTM3525XSlotEnumerableUpgradeableWithInit is CTM3525XSlotEnumerableUpgradeable {
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) payable initializer {
        __CTM3525XSlotEnumerable_init(name_, symbol_, decimals_);
    }
}
import "./CTM3525XAllRoundMockUpgradeable.sol";

contract CTM3525XAllRoundMockUpgradeableWithInit is CTM3525XAllRoundMockUpgradeable {
    constructor(string memory name_, string memory symbol_, uint8 decimals_) payable initializer {
        __CTM3525XAllRoundMock_init(name_, symbol_, decimals_);
    }
}
import "./CTM3525XBaseMockUpgradeable.sol";

contract CTM3525XBaseMockUpgradeableWithInit is CTM3525XBaseMockUpgradeable {
    constructor(string memory name_, string memory symbol_, uint8 decimals_) payable initializer {
        __CTM3525XBaseMock_init(name_, symbol_, decimals_);
    }
}
import "./NonReceiverMockUpgradeable.sol";

contract NonReceiverMockUpgradeableWithInit is NonReceiverMockUpgradeable {
    constructor() payable initializer {
        __NonReceiverMock_init();
    }
}
import "../periphery/CTM3525XMetadataDescriptorUpgradeable.sol";

contract CTM3525XMetadataDescriptorUpgradeableWithInit is CTM3525XMetadataDescriptorUpgradeable {
    constructor() payable initializer {
        __CTM3525XMetadataDescriptor_init();
    }
}
