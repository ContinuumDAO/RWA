const { ethers, upgrades } = require("hardhat");

// let owner
// let otherAccount
// let c3Caller
// let c3SwapIDKeeper
// let c3CallerProxy


async function deployC3Caller() {
    // Contracts are deployed using the first signer/account by default
    //const [_owner, _otherAccount] = await ethers.getSigners();

    const C3SwapIDKeeper = await ethers.getContractFactory('C3UUIDKeeper');
    const c3SwapIDKeeper = await C3SwapIDKeeper.deploy();
    await await c3SwapIDKeeper.deployed()

    const C3Caller = await ethers.getContractFactory('C3Caller');
    let c3Caller = await C3Caller.deploy(c3SwapIDKeeper.address);
    await c3Caller.deployed()

    const C3CallerProxy = await ethers.getContractFactory('C3CallerProxy');
    //const c3CallerProxy = await C3CallerProxy.deploy();
    console.log(upgrades)
    const c3CallerProxy = await upgrades.deployProxy(C3CallerProxy, [c3Caller.getAddress()], { initializer: 'initialize', kind: 'uups' });

    // await c3SwapIDKeeper.addOperator(c3Caller.target)

    // await c3Caller.addOperator(c3CallerProxy.target)

    // owner = _owner
    // otherAccount = _otherAccount

    // return(c3CallerProxy)
}

module.exports = {
    deployC3Caller
};