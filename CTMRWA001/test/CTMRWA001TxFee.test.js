const { shouldBehaveLikeCTMRWA001TxFee } = require('./CTMRWA001.behavior');

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
  const CTMRWA001Factory = await ethers.getContractFactory('CTMRWA001TxFee');
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

describe('CTMRWA001SlotApprovable', () => {

  const tokenName = 'Semi Fungible Token';
  const symbol = 'SFT';
  const decimals = 18;
  const dappID = 1;

  beforeEach(async function () {

    [ firstOwner, secondOwner, approved, valueApproved, anotherApproved, operator, slotOperator, other ] = await ethers.getSigners();

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

  shouldBehaveLikeCTMRWA001TxFee('CTMRWA001SlotApprovable');

})