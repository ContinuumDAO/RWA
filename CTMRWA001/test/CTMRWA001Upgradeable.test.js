const { shouldBehaveLikeERC721, shouldBehaveLikeERC721Enumerable, shouldBehaveLikeERC721Metadata } = require('./ERC721.behavior');
const { shouldBehaveLikeCTMRWA001, shouldBehaveLikeCTMRWA001Metadata } = require('./CTMRWA001.behavior');

async function deployCTMRWA001( 
  tokenName, 
  symbol, 
  decimals,
  feeManager,
  gov,
  c3callerProxy,
  txSender,
  dappID
) {
  const CTMRWA001Factory = await ethers.getContractFactory('CTMRWA001BaseMockUpgradeableWithInit');
  const CTMRWA001 = await CTMRWA001Factory.deploy(
    tokenName, 
    symbol, 
    decimals,
    feeManager,
    gov,
    c3callerProxy,
    txSender,
    dappID
  );
  await CTMRWA001.deployed();
  return CTMRWA001;
}

describe('CTMRWA001Upgradeable', () => {

  const tokenName = 'Semi Fungible Token';
  const symbol = 'SFT';
  const decimals = 18;
  const dappID = 1;

  beforeEach(async function () {

    [ firstOwner, secondOwner, approved, valueApproved, anotherApproved, operator, slotOperator, feeManager, gov, c3callerProxy, txSender, other ] = await ethers.getSigners();

      this.token = await deployCTMRWA001(
          tokenName, 
          symbol, 
          decimals,
          feeManager.address,
          gov.address,
          c3callerProxy.address,
          txSender.address,
          dappID
      );

  })

  shouldBehaveLikeERC721('ERC721');
  shouldBehaveLikeERC721Enumerable('ERC721Enumerable');
  shouldBehaveLikeERC721Metadata('ERC721Metadata', tokenName, symbol);
  shouldBehaveLikeCTMRWA001('CTMRWA001Upgradeable');
  shouldBehaveLikeCTMRWA001Metadata('CTMRWA001MetadataUpgradeable');

})