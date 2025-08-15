# Deployment Guide for AssetX

## Introduction

Dependencies: foundry, node, npm, dotenv

Run `npm i dotenv` to install the only dependency required.

Verification: An Etherscan API V2 key, see [here](https://docs.etherscan.io/etherscan-v2/v2-quickstart).

For security in deployment, this guide assumes that you are using an account saved in a keystore, and that you have a password file saved locally.

Use a fresh wallet and ensure you have plenty of gas for deployment and configuration.

See [Foundry keystores](https://getfoundry.sh/cast/reference/wallet).

## .env file

Modify .env for the following structure. To get DApp IDs, go to the [DApp Registry](https://c3caller.continuumdao.org).

```
# Addresses (gov should be your deployer address, MPC is the address that can call onlyCaller functions)
GOV=<DEPLOYER>
MPC=0xEef3d3678E1E739C6522EEC209Bede0197791339

# RWA Type & Version (current type and version are 1)
RWA_TYPE=1
VERSION=1

# DApp IDs
DAPP_ID_GATEWAY=
DAPP_ID_FEE_MANAGER=
DAPP_ID_RWA1X=
DAPP_ID_DEPLOYER=
DAPP_ID_STORAGE_MANAGER=
DAPP_ID_SENTRY_MANAGER=
DAPP_ID_MAP=

# C3Caller Endpoints (pre-audit current instances)
C3CALLER_421614=0x9e0625366F7d85A174a59b1a5D2e44F1492a9cBB      # Arbitrum Sepolia
C3CALLER_11155111=0x9e0625366F7d85A174a59b1a5D2e44F1492a9cBB    # Ethereum Sepolia
C3CALLER_97=0x9e0625366F7d85A174a59b1a5D2e44F1492a9cBB          # BSC Testnet
C3CALLER_5611=0x9e0625366F7d85A174a59b1a5D2e44F1492a9cBB        # OPBNB Testnet
C3CALLER_43113=0x9e0625366F7d85A174a59b1a5D2e44F1492a9cBB       # Avalanche Fuji
C3CALLER_84532=0x9e0625366F7d85A174a59b1a5D2e44F1492a9cBB       # Base Sepolia
C3CALLER_17000=0x9e0625366F7d85A174a59b1a5D2e44F1492a9cBB       # Scroll Sepolia
C3CALLER_534351=0x9e0625366F7d85A174a59b1a5D2e44F1492a9cBB      # Holesky Testnet
C3CALLER_1946=0x9e0625366F7d85A174a59b1a5D2e44F1492a9cBB        # Soneium Minato

# Fee Tokens: use any ERC20. These are testnet USDT tokens - available from our faucet at https://theianet.com on Arbitrum Sepolia, from where tokens can be sent to other chains (use the faucet button).
FEE_TOKEN_421614=0xbF5356AdE7e5F775659F301b07c4Bc6961044b11      # Arbitrum Sepolia
FEE_TOKEN_11155111=0xa4C104db0937F1E886d5C9c9789D6f0e5bfBA75c    # Ethereum Sepolia
FEE_TOKEN_97=0xDd43fc986a13392dDbC7aeA150b41EfE27b2d0eD          # BSC Testnet
FEE_TOKEN_5611=0x108642B1b2390AC3f54E3B45369B7c660aeFffAD        # OPBNB Testnet
FEE_TOKEN_43113=0x15A1ED0815ECeD97E46967179846c72BA21DABAd       # Avalanche Fuji
FEE_TOKEN_84532=0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae       # Base Sepolia
FEE_TOKEN_534351=0xe536Bf33585aa6bb528627Ed7Dc4D49009dafC58      # Scroll Sepolia
FEE_TOKEN_17000=0x108642B1b2390AC3f54E3B45369B7c660aeFffAD       # Holesky Testnet
FEE_TOKEN_1946=0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae        # Soneium Minato

# Fee Multipliers: the multiplier is provided in USD for current configuration of baseFee
FEE_MULTIPLIER_0=2      # Admin
FEE_MULTIPLIER_1=10     # Deploy
FEE_MULTIPLIER_2=1      # TX
FEE_MULTIPLIER_3=4      # Mint
FEE_MULTIPLIER_4=4      # Burn
FEE_MULTIPLIER_5=4      # Issuer
FEE_MULTIPLIER_6=8      # Provenance
FEE_MULTIPLIER_7=4      # Valuations
FEE_MULTIPLIER_8=10     # Prospectus
FEE_MULTIPLIER_9=8      # Rating
FEE_MULTIPLIER_10=8     # Legal
FEE_MULTIPLIER_11=8     # Financial
FEE_MULTIPLIER_12=20    # License
FEE_MULTIPLIER_13=8     # Due Diligence
FEE_MULTIPLIER_14=4     # Notice
FEE_MULTIPLIER_15=4     # Dividend
FEE_MULTIPLIER_16=4     # Redemption
FEE_MULTIPLIER_17=4     # Who can invest
FEE_MULTIPLIER_18=2     # Image
FEE_MULTIPLIER_19=20    # Video
FEE_MULTIPLIER_20=2     # Icon
FEE_MULTIPLIER_21=1     # Whitelist
FEE_MULTIPLIER_22=1     # Country
FEE_MULTIPLIER_23=5     # KYC
FEE_MULTIPLIER_24=5     # ERC20
FEE_MULTIPLIER_25=5     # Deploy Invest
FEE_MULTIPLIER_26=5     # Offering
FEE_MULTIPLIER_27=5     # Invest

# VERIFIER for ZKME
VERIFIER_534351=0xf8E1973814E66BF03002862C325305A5EeF98cc1  # Scroll Sepolia

# RPC Endpoints
ARBITRUM_SEPOLIA_RPC_URL=https://sepolia-rollup.arbitrum.io/rpc
SEPOLIA_RPC_URL=https://ethereum-sepolia-rpc.publicnode.com
BASE_SEPOLIA_RPC_URL=https://base-sepolia-rpc.publicnode.com
BSC_TESTNET_RPC_URL=https://data-seed-prebsc-1-s1.binance.org:8545/
AVALANCHE_FUJI_RPC_URL=https://api.avax-test.network/ext/bc/C/rpc
OPBNB_TESTNET_RPC_URL=https://opbnb-testnet-rpc.publicnode.com
HOLESKY_TESTNET_RPC_URL=https://holesky.gateway.tenderly.co
SCROLL_SEPOLIA_RPC_URL=https://sepolia-rpc.scroll.io
SONEIUM_MINATO_RPC_URL=https://rpc.minato.soneium.org/
```

## Make Scripts Executable

```bash
chmod +x helpers/[0-9]*
chmod +x helpers/deploy/*
chmod +x helpers/configure/*
```

## Flatten the source directory

This is required for single-file verification on chains that do not support Etherscan and to facilitate remedial manual verification.

```bash
./helpers/0-flatten.sh
```

## Compilation

Use the compilation script to compile the flattened source code and scripts.

```bash
./helpers/1-clean.sh
./helpers/2-build-flattened.sh
./helpers/5-build-script.sh
```

## Deploy Contracts

### Core Contracts (every network)

Run each of the following scripts to deploy. This will first execute a simulation, then allow you elect to deploy all contracts to the given network (broadcast) and verify the contracts on Etherscan if possible.

```bash
./helpers/deploy/arbitrum-sepolia.sh <DEPLOYER> <PATH_TO_PASSWORD_FILE>
./helpers/deploy/avalanche-fuji.sh <DEPLOYER> <PATH_TO_PASSWORD_FILE>
./helpers/deploy/base-sepolia.sh <DEPLOYER> <PATH_TO_PASSWORD_FILE>
./helpers/deploy/bsc-testnet.sh <DEPLOYER> <PATH_TO_PASSWORD_FILE>
./helpers/deploy/holesky.sh <DEPLOYER> <PATH_TO_PASSWORD_FILE>
./helpers/deploy/opbnb-testnet.sh <DEPLOYER> <PATH_TO_PASSWORD_FILE>
./helpers/deploy/scroll-sepolia.sh <DEPLOYER> <PATH_TO_PASSWORD_FILE>
./helpers/deploy/sepolia.sh <DEPLOYER> <PATH_TO_PASSWORD_FILE>
./helpers/deploy/soneium-minato-testnet.sh <DEPLOYER> <PATH_TO_PASSWORD_FILE>
```

All contracts are now deployed and initialized; their addresses are accessible in `broadcast/DeployAssetX.s.sol/<chain-id>/run-latest.json`.

The following contracts are proxies:

- FeeManager
- CTMRWAGateway
- CTMRWA1X
- CTMRWAMap
- CTMRWADeployer
- CTMRWA1StorageManager
- CTMRWA1SentryManager

Note: For the proxies, go to Etherscan and select "Contract > More Options > Is this a proxy?" to link its implementation contract.

### Identity Contract (Scroll Sepolia only)

To deploy the Identity contract, which is used for ZK-proof verification of identity, run the following script:

```bash
./helpers/7-deploy-identity.sh <DEPLOYER> <PATH_TO_PASSWORD_FILE>
```

This will deploy, initialize (in SentryManager) and verify the identity contract on Scroll Sepolia. The deployment information is accessible in `broadcast/DeployIdentity.s.sol/534351/run-latest.json`.

## Write Deployed Contracts to Environment File

Run the JS helpers found in `js-helpers/` to generate (i) a .env.deployed file from the saved logs, (ii) a JSON file with all deployed instances across all networks, and (iii) the addition of the saved identity contract address(es), if applicable.

```bash
node js-helpers/0-generate-environment.js
node js-helpers/1-save-contract-addresses.js
node js-helpers/2-save-identity-addresses.js
```

## Source the Deployed Contract Environment File

This will expose the generated contract addresses to the execution environment.

```bash
source helpers/6-export-env.sh
```

## Configure Contracts

*Note: only execute this script when contracts are deployed to all target chains.*

Run each of the following scripts to configure initial values on all networks. This will first execute a simulation, then allow you elect to configure all contracts to the given network (broadcast), to link all other deployed contracts.

```bash
./helpers/configure/arbitrum-sepolia.sh <DEPLOYER> <PATH_TO_PASSWORD_FILE>
./helpers/configure/avalanche-fuji.sh <DEPLOYER> <PATH_TO_PASSWORD_FILE>
./helpers/configure/base-sepolia.sh <DEPLOYER> <PATH_TO_PASSWORD_FILE>
./helpers/configure/bsc-testnet.sh <DEPLOYER> <PATH_TO_PASSWORD_FILE>
./helpers/configure/holesky.sh <DEPLOYER> <PATH_TO_PASSWORD_FILE>
./helpers/configure/opbnb-testnet.sh <DEPLOYER> <PATH_TO_PASSWORD_FILE>
./helpers/configure/scroll-sepolia.sh <DEPLOYER> <PATH_TO_PASSWORD_FILE>
./helpers/configure/sepolia.sh <DEPLOYER> <PATH_TO_PASSWORD_FILE>
./helpers/configure/soneium-minato-testnet.sh <DEPLOYER> <PATH_TO_PASSWORD_FILE>
```

## Complete

The contracts are now deployed, verified and configured on all test networks.

# Appendices

## Appendix I: Network names available in Forge

These are the chain names that can be used with the `--chain` flag in Foundry.

### Current Deployed Testnets
- **sepolia** (Ethereum Sepolia)
- **holesky** (Ethereum Holesky)
- **arbitrum-sepolia**
- **base-sepolia**
- **bsc-testnet**
- **avalanche-fuji**
- **scroll-sepolia**
- **opbnb-testnet**
- **soneium-minato-testnet**

### Mainnet Networks
- mainnet
- ethereum

### Testnet Networks
- goerli

### Layer 2 Networks
- arbitrum
- arbitrum-goerli
- base
- base-goerli
- optimism
- optimism-sepolia
- optimism-goerli
- polygon
- polygon-mumbai
- polygon-zkevm
- polygon-zkevm-testnet

### Other Major Networks
- bsc
- avalanche
- fantom
- fantom-testnet
- cronos
- cronos-testnet
- gnosis
- gnosis-chiado

### Rollups and Specialized Networks
- scroll
- linea
- linea-sepolia
- mantle
- mantle-sepolia
- zksync
- zksync-sepolia
- starknet
- starknet-sepolia

## Appendix II: Gas costs for deployment and configuration

| Network | Chain ID | DeployAssetX Gas Units | ConfigureAssetX Gas Units | DeployAssetX Total Gas Cost | ConfigureAssetX Total Gas Cost | Gas Price (gwei, approx.)| Gas Token |
|---|---|---|---|---|---|---|---|
| Arbitrum Sepolia | 421614 | 56386008 | 7556244 | 0.011277202 | 0.0007556244 | 0.2 | ETH |
| BSC Testnet | 97 | 43369218 | 7579192 | 0.0043369218 | 0.0007579192 | 0.1 | BNB |
| Sepolia | 11155111 | 43373858 | 7561477 | 0.009064373298100646 | 0.000008222437583216 | 0.209817865 | ETH |
| Avalanche Fuji | 43113 | 43371322 | 7666774 | 0.000000000086742644 | 0.000000019174601774 | 0.000000002 | AVAX |
| Scroll Sepolia | 534351 | 43372218 | 7562133 | 0.000680081062439544 | 0.000118575062150364 | 0.015680108 | ETH |
| Base Sepolia | 84532 | 43371322 | 7568804 | 0.000043374268956092 | 0.000007569205146612 | 0.001000067 | ETH |
| Holesky Testnet | 17000 | 43371322 | 7564806 | 0.000043371625599254 | 0.000007564920655827 | 0.001000007 | ETH |
| OP BNB Testnet | 5611 | 43370858 | 7567061 | 0.000000000043370858 | 0.000000000007567061 | 0.000000001 | BNB |
| Soneium Minato Testnet | 1946 | 43370858 | 7571059 | 0.000043381787456216 | 0.000000001915477927 | 0.001000252 | ETH |
