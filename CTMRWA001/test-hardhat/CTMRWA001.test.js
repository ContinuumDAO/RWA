const { shouldBehaveLikeCTMRWA001, shouldBehaveLikeCTMRWA001Metadata } = require('./CTMRWA001.behavior');

async function deployCTMRWA001(
  tokenName, 
  symbol, 
  decimals,
  ctmRwa001XChain
) {
  const CTMRWA001Factory = await ethers.getContractFactory('CTMRWA001BaseMock');
  const CTMRWA001 = await CTMRWA001Factory.deploy(
    tokenName, 
    symbol, 
    decimals,
    ctmRwa001XChain
  );
  await CTMRWA001.deployed();
  return CTMRWA001;
}

describe('CTMRWA001', () => {

  const tokenName = 'Semi Fungible Token';
  const symbol = 'SFT';
  const decimals = 18;
  const dappID = 1;

  beforeEach(async function () {

      [ firstOwner, secondOwner, approved, valueApproved, anotherApproved, operator, slotOperator, ctmRwa001XChain, other ] = await ethers.getSigners();
      this.token = await deployCTMRWA001(
          tokenName, 
          symbol, 
          decimals,
          ctmRwa001XChain.address
      );
  })

  shouldBehaveLikeCTMRWA001('CTMRWA001');
  //shouldBehaveLikeCTMRWA001Metadata('CTMRWA001Metadata');
  
})