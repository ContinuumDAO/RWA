const { shouldBehaveLikeCTMRWA001SlotEnumerable } = require('./CTMRWA001.behavior');

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
  const CTMRWA001Factory = await ethers.getContractFactory('CTMRWA001AllRoundMock');
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

describe('CTMRWA001SlotEnumerable', () => {

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

  shouldBehaveLikeCTMRWA001SlotEnumerable('CTMRWA001SlotEnumerable');

})