const { ethers, upgrades } = require("hardhat");
const { deployC3Caller } = require('./c3Caller');
const { shouldBehaveLikeCTMRWA001BasicToken } = require('./CTMRWA001.behavior');


async function deployFeeManager(

) {

}

async function deployCTMRWA001Deployer() {

}

async function deployCTMRWA001X(

) {

}

async function deployCTMRWA001(
  tokenName, 
  symbol, 
  decimals,
  ctmRwa001XChain
) {
  
  const CTMRWA001Factory = await ethers.getContractFactory('CTMRWA001BasicToken');
  const CTMRWA001 = await CTMRWA001Factory.deploy(
    tokenName, 
    symbol, 
    decimals,
    ctmRwa001XChain
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

    [ admin, firstOwner, secondOwner, approved, valueApproved, anotherApproved, operator, slotOperator, ctmRwa001XChain, other] = await ethers.getSigners();

      await deployC3Caller()

      this.token = await deployCTMRWA001(
          tokenName, 
          symbol, 
          decimals,
          ctmRwa001XChain.address
      );

  })

  shouldBehaveLikeCTMRWA001BasicToken('CTMRWA001SlotApprovable');

})