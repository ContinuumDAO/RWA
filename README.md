# Contract Structure for CTMRWA1

## Core Contracts

### CTMRWA1.sol

This is the basic Semi Fungible Token contract, which used ERC3525 as its
starting point, but has been modified to work in a cross-chain environment and
has other substantial modifications.

It maintains the original idea of allowing the creation of 'slots' and minting
value in each of these. Value is fungible and transferable between wallets, only
if they are in the same slot, including cross-chain.

Fungible value is held in individual tokenId tokens, which each belong to one
slot, have an owner, a balance and a list of approved spenders. They can be
split, or joined together.

A CTMRWA1 contract can be deployed by any wallet and this address becomes the
tokenAdmin (Issuer) of the RWA token.

Any number of CTMRWA1 contracts can be deployed. Each has a unique uint256 ID,
the same on each chain.

### CTMRWA1X.sol

This contract has a ContinuumDAO DappID and it can call and be called using
ContinuumDAO's C3Caller. It is also GovernDapp, so it can be administered using
an OpenZeppelin Governor contract on the same chain, or cross-chain.

The contract contains the most basic cross-chain functionality of AssetX.

There is only one CTMRWA1X contract on each chain and it enables all CTMRWA1
token contracts.

It includes these functionalities :-

(1) Deployment of CTMRWA1 on the source chain and any number of other supported
chains. Value in any slot can be exchanged between chains to which this CTMRWA1
has been deployed to. The number of chains in the RWA token can be increased, so
long as Whitelisting/Blacklisting, or KYC has NOT yet been enabled (more below).

(2) Creation of slots, which are replicated in all CTMRWA1 contracts on every
chain that it is deployed

(3) Minting of value on each chain in each slot by the tokenAdmin

(4) Transfer of value between CTMRWA1 contracts with the same ID and cross-chain
with C3Caller.

(5) Changing of the tokenAdmin address, or setting the address to 0, so that it
is 'locked' and not further value can be minted, or any other onlyTokenAdmin functions.

### CTMRWAGateway.sol

This contract exists once on each chain. It records the addresses and allows
cross-chain linking of all other CTMRWAGateway contracts on other chains. It
also stores the addresses of the other CTMRWA1X, CTMRWA1StorageManager,
CTMRWA1SentryManager contracts on all supported chains.

### CTMRWAMap.sol

This contract exists once on every supported chain.

Each deployed RWA token consists of one CTMRWA1, CTMRWA1Storage, CTMRWA1Sentry,
CTMRWADividend and CTMRWASentry contract for each individual stored ID. Optional
extra consistuents for the RWA token are CTMRWA1InvestWithTimeLock and
CTMRWAERC20 contracts.

CTMRWAMap stores the contract addresses of the ID and vice-versa. The contract
allows the multiple contracts in an RWA token to act a single whole.

### CTMRWADeployer.sol

This contract exists once on every supported chain. It is a C3GovernDapp, with
its own dappID, so it can be administred by an Open Zeppelin Governor contract
on the same or other chains.

The contract enables the creation of one unique CTMRWA1, CTMRWA1Storage,
CTMRWA1Sentry, CTMRWADividend and CTMRWASentry contracts for an individual ID on
the local chain, or on other chains via C3Caller. It is called by the Deploy
functionality of CTMRWA1X.

It also allows deployment of the CTMRWADeployInvest contract.

### CTMRWA1TokenFactory.sol

This contract exists once on every supported chain. The contract calls CREATE2
to deploy a CTMRWA1 token contract. It is called by CTMRWADeployer.

### CTMRWAStorageManager.sol

This contract exists once on every supported chain. It is a C3GovernDapp, with
its own dappID, so it can be administered by an Open Zeppelin Governor contract
on the same or other chains.

The contract (and its helper contract CTMRWA1StorageUtils.sol) call CREATE2 to
deploy an individual CTMRWA1Storage contract with the same ID as the
corresponding CTMRWA1.

The main function of CTMRWA1StorageManager is to allow cross-chain updating
between every individual CTMRWA1Storage contract of attached stored
decentralized data on BNB Greenfield (or other decentralized storage).

When a new chain is added to the RWA token, it also copies all decentralized
data object references to the new chain.

### CTMRWA1Storage.sol

There is one CTMRWA1Storage contract per CTMRWA1. It stores the state references
for all attached decentralized storage objects. This includes the Bucket of the
decentralized storage and all Objects. The Object state most importantly
includes the checksum of the object, so that any discrepency between the stored
checksum and the checksum calculated from the actual stored Object data can be
flagged. Othe information includes the Object title, size and time of creation.

The types of storage Object are categorised into some 30 URICategory,
representing different types of data appropriate to the RWA token. The stored
Objects can be either 'global' to the whole CTMRWA1 (URIType == CONTRACT), or
specific to one slot in the CTMRWA1 (URIType == SLOT).

The URICategory/URIType act as middleware to store all the different types of
data in the RWA token.

CTMRWA1Storage functions are called from CTMRWA1StorageManager.

### CTMRWA1DividendFactory.sol

This contract exists once on every supported chain.

It deploys individual CTMRWA1Dividend contracts for every CTMRWA1 token, using CREATE2.

It is called from CTMRWADeployer.

### CTMRWA1Dividend.sol

There is one CTMRWA1Dividend contract per CTMRWA1. It defines what dividends are
payable per value, per slot in the RWA token. It allows the tokenAdmin to
disburse dividends to holders and for holders to claim their dividends.

### CTMRWA1SentryManager.sol

This contract exists once on every supported chain. It is a C3GovernDapp, with
its own dappID, so it can be administered by an Open Zeppelin Governor contract
on the same or other chains.

The purpose of CTMRWA1SentryManager (together with its helper contract
CTMRWA1SentryUtils) is to deploy individual CTMRWA1Sentry contracts for each
CTMRWA1. The deployment can occur on the local chain, or cross-chain using C3Caller.

The main purpose of the contract is to define access to the CTMRWA1. This could
be via tokenAdmin defined Whitelists/Blacklists, or to enable KYC/KYB, with
zkProofs for over18, Accredited Investor status, and geo-fencing.

### CTMRWA1Sentry.sol

There is one CTMRWA1Sentry contract per CTMRWA1. It stores the state which
defines who may interact with the CTMRWA1. The state includes the actual
Whitelist, or Blacklist of the CTMRWA1 as well as the other options chosen for
what access is permissible via zkProofs.

The actual zkProof interaction is controlled by CTMRWA1Identity

### CTMRWA1Identity

This contract is deployed on some chains, where it can interact with zkVerifier
contracts from other providers. Currently AssetX supports zkMe and is in testing
for using PrivadoID.

The CTMRWA1Identity contract on a chain manages the Whitelist/Blacklist on that
chain and via CTMRWA1SentryManager, on every other chain that the RWA token is
deployed to.

### FeeManager.sol

This contract exists once on every supported chain. It is a C3GovernDapp, with
its own dappID, so it can be administred by an Open Zeppelin Governor contract
on the same or other chains.

Most of the other contracts in AssetX use FeeManager to administer the fees
payable for AssetX functions. The fees are settable using the GovernDapp
architecture of C3Caller.

The FeeManager contract stores the fees collected from AssetX operations.

### CTMRWADeployInvest.sol

This is a token contract that the tokenAdmin can deploy using a simple click
from within AssetX.

The contract allows the tokenAdmin to make the value in one or more tokenIds
avalaible for sale to investors with multiple Offerings. The investors may be
subject to an escrow period as defined by the tokenAdmin. During this time, they
can still claim their dividends.

The rules about who can invest are determined by the CTMRWA1SentryManager and
CTMRWA1Sentry contracts.

### CTMRWAERC20Deployer

This contract allows the tokenAdmin to deploy ONE ERC20 contract per chain and
per slot of a CTMRWA1. The resulting CTMRWAERC20 contracts are interfaces to the
underlying value in the CTMRWA1 token contracts. They are subject to the
restrictions determined by the CTMRWA1SentryManager and CTMRWA1Sentry contracts.

The purpose of the CTMRWAERC20 contracts is to allow 'normal' interaction with
other protocols, such as DEXes and Lending platforms.

## Modular Contracts Hierarchy

### Sentry

#### CTMRWA1Sentry & ICTMRWA1Sentry

#### CTMRWA1SentryManager & ICTMRWA1SentryManager

#### CTMRWASentryUtils & ICTMRWASentryUtils

### Core

#### CTMRWA1 & ICTMRWA1

#### CTMRWA1Dividend & ICTMRWA1Dividend

#### CTMRWADividendFactory

#### CTMRWAERC20Deployer & ICTMRWAERC20Deployer

#### ICTMRWAReceiver

#### ICTMRWAERC20

### Cross-chain

#### CTMRWA1X & ICTMRWA1X

#### CTMRWA1XFallback & ICTMRWA1XFallback

#### CTMRWAGateway & ICTMRWAGateway

### Deployment

#### CTMRWA1TokenFactory

#### CTMRWADeployInvest & ICTMRWADeployInvest

#### CTMRWADeployer & ICTMRWADeployer

#### ICTMRWAFactory

### Identity

#### CTMRWA1Identity & ICTMRWA1Identity

### Managers

#### FeeManager & IFeeManager

### Mocks

#### CTMRWA1ReceiverMock

#### NonReceiverMock

#### TestERC20

### RouterV2

#### GovernDapp

#### ITheiaERC20

#### TheiaUtils

### Shared

#### CTMRWAMap & ICTMRWAMap

### Storage

#### CTMRWA1Storage & ICTMRWAStorage

#### CTMRWA1StorageManager & ICTMRWAStorageManager

#### CTMRWA1StorageUtils & ICTMRWA1StorageUtils
