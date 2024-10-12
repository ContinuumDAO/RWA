#/bin/bash!


forge flatten contracts/CTMRWA001TokenFactory.sol --output flattened/CTMRWA001TokenFactory.sol
forge flatten contracts/CTMRWADeployer.sol --output flattened/CTMRWADeployer.sol
forge flatten contracts/CTMRWAGateway.sol --output flattened/CTMRWAGateway.sol
forge flatten contracts/FeeManager.sol --output flattened/FeeManager.sol
forge flatten contracts/CTMRWA001TokenFactory.sol --output flattened/CTMRWA001TokenFactory.sol
forge flatten contracts/CTMRWA001XFallback.sol --output flattened/CTMRWA001XFallback.sol
forge flatten contracts/CTMRWA001StorageManager.sol --output flattened/CTMRWA001StorageManager.sol
forge flatten contracts/CTMRWA001Storage.sol --output flattened/CTMRWA001Storage.sol
forge flatten contracts/CTMRWA001DividendFactory.sol --output flattened/CTMRWA001DividendFactory.sol
forge flatten contracts/CTMRWA001Dividend.sol --output flattened/CTMRWA001Dividend.sol
forge flatten contracts/routerV2/GovernDapp.sol --output flattened/GovernDapp.sol
forge flatten contracts/CTMRWA001X.sol --output flattened/CTMRWA001X.sol

