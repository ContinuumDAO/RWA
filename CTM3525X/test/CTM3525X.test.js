const { shouldBehaveLikeERC721, shouldBehaveLikeERC721Enumerable, shouldBehaveLikeERC721Metadata } = require('./ERC721.behavior');
const { shouldBehaveLikeCTM3525X, shouldBehaveLikeCTM3525XMetadata } = require('./CTM3525X.behavior');

async function deployCTM3525X(name, symbol, decimals) {
  const CTM3525XFactory = await ethers.getContractFactory('CTM3525XBaseMock');
  const CTM3525X = await CTM3525XFactory.deploy(name, symbol, decimals);
  await CTM3525X.deployed();
  return CTM3525X;
}

describe('CTM3525X', () => {

  const name = 'Semi Fungible Token';
  const symbol = 'SFT';
  const decimals = 18;

  beforeEach(async function () {
    this.token = await deployCTM3525X(name, symbol, decimals);
  })

  shouldBehaveLikeERC721('ERC721');
  shouldBehaveLikeERC721Enumerable('ERC721Enumerable');
  shouldBehaveLikeERC721Metadata('ERC721Metadata', name, symbol);
  shouldBehaveLikeCTM3525X('CTM3525X');
  shouldBehaveLikeCTM3525XMetadata('CTM3525XMetadata');
  
})