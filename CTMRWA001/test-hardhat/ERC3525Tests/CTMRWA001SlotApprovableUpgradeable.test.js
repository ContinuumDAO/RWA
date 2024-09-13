const { shouldBehaveLikeCTMRWA001SlotApprovable } = require('./CTMRWA001.behavior');

async function deployCTMRWA001(
  admin,
  tokenName, 
  symbol, 
  decimals,
  ctmRwa001XChain
) {
  const CTMRWA001Factory = await ethers.getContractFactory('CTMRWA001AllRoundMockUpgradeableWithInit');
  const CTMRWA001 = await CTMRWA001Factory.deploy(
    admin,
    tokenName, 
    symbol, 
    decimals,
    ctmRwa001XChain
  );
  await CTMRWA001.deployed();
  return CTMRWA001;
}

describe('CTMRWA001SlotApprovableUpgradeable', () => {

  const tokenName = 'Semi Fungible Token';
  const symbol = 'SFT';
  const decimals = 18;
  const dappID = 1;

  beforeEach(async function () {

    [ firstOwner, secondOwner, approved, valueApproved, anotherApproved, operator, slotOperator, admin, ctmRwa001XChain, other ] = await ethers.getSigners();

      this.token = await deployCTMRWA001(
          admin.address,
          tokenName, 
          symbol, 
          decimals,
          ctmRwa001XChain.address
      );

  })

  shouldBehaveLikeCTMRWA001SlotApprovable('CTMRWA001SlotApprovableUpgradeable');

})