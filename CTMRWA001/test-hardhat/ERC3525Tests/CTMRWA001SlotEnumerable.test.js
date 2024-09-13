const { shouldBehaveLikeCTMRWA001SlotEnumerable } = require('./CTMRWA001.behavior');

async function deployCTMRWA001(
  admin,
  tokenName, 
  symbol, 
  decimals,
  ctmRwa001XChain
) {
  const CTMRWA001Factory = await ethers.getContractFactory('CTMRWA001AllRoundMock');
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

describe('CTMRWA001SlotEnumerable', () => {

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

  shouldBehaveLikeCTMRWA001SlotEnumerable('CTMRWA001SlotEnumerable');

})