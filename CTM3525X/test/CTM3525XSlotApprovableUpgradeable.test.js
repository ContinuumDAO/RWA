const { shouldBehaveLikeCTM3525XSlotApprovable } = require('./CTM3525X.behavior');

async function deployCTM3525X(name, symbol, decimals) {
  const CTM3525XFactory = await ethers.getContractFactory('CTM3525XAllRoundMockUpgradeableWithInit');
  const CTM3525X = await CTM3525XFactory.deploy(name, symbol, decimals);
  await CTM3525X.deployed();
  return CTM3525X;
}

describe('CTM3525XSlotApprovableUpgradeable', () => {

  const name = 'Semi Fungible Token';
  const symbol = 'SFT';
  const decimals = 18;

  beforeEach(async function () {
    this.token = await deployCTM3525X(name, symbol, decimals);
  })

  shouldBehaveLikeCTM3525XSlotApprovable('CTM3525XSlotApprovableUpgradeable');

})