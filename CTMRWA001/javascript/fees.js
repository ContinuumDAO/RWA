//

const {ethers} = require('ethers')
const dotenv = require('dotenv')


// const {abi:storageManagerAbi} = require('../out/CTMRWA001StorageManager.sol/CTMRWA001StorageManager.json')
// 

let signer
let feeManagerAddr
let feeManager
let decimals
let mapAddr
let chainIdStr
let baseOrder

dotenv.config({ path: '../.env' })
const PRIVATE_KEY = process.env.PRIVATE_KEY

const {abi:feeManagerAbi} = require('../out/FeeManager.sol/FeeManager.json')
const {abi:ctmRwaMapAbi} = require('../out/CTMRWAMap.sol/CTMRWAMap.json')
const {abi:storageAbi} = require('../out/CTMRWA001Storage.sol/CTMRWA001Storage.json')
const {abi:ERC20Abi} = require('../out/ERC20.sol/ERC20.json')

const deployFee = async(feeTokenStr, toChainIdsStr, includeLocal) => {

    feeType = 1 // FeeType.DEPLOY

    const fee = await feeManager.getXChainFee(toChainIdsStr, includeLocal, feeType, feeTokenStr)
    const feeWei = fee*10n**(decimals - baseOrder)

    return feeWei
}

const adminFee = async(feeTokenStr, toChainIdsStr) => {

    feeType = 0 // FeeType.ADMIN
    const includeLocal = true

    const fee = await feeManager.getXChainFee(toChainIdsStr, includeLocal, feeType, feeTokenStr)
    const feeWei = fee*10n**(decimals - baseOrder)

    return feeWei
}

const txFee = async(feeTokenStr, toChainIdsStr) => {
    if(toChainIdsStr[0] == chainIdStr) {
        return 0n
    } else {
        feeType = 2 // FeeType.TX
        const includeLocal = false

        const fee = await feeManager.getXChainFee(toChainIdsStr, includeLocal, feeType, feeTokenStr)
        const feeWei = fee*10n**(decimals - baseOrder)

        return feeWei
    }
}


const mintFee = async(feeTokenStr, toChainIdsStr) => {
    feeType = 3 // FeeType.MINT
    const includeLocal = false

    const fee = await feeManager.getXChainFee(toChainIdsStr, includeLocal, feeType, feeTokenStr)
    const feeWei = fee*10n**(decimals - baseOrder)

    return feeWei
}


const individualURIFee = async(uriCategory, feeTokenStr, toChainIdsStr) => {

    let feeType = uriCategory + 5 // First 5 are ADMIN, DEPLOY, TX, MINT, DEPLOY

    let includeLocal = false
    const fee = await feeManager.getXChainFee(toChainIdsStr, includeLocal, feeType, feeTokenStr)
    const feeWei = fee*10n**(decimals - baseOrder)

    return feeWei
}


const transferURIFee = async(ID, feeTokenStr, toChainIdsStr) => {

    const categories = await getCategories(ID)

    let feeWei = 0n

    for(let i=0; i<categories.length; i++) {
        feeWei += await individualURIFee(Number(categories[i]), feeTokenStr, toChainIdsStr)
    }

    return feeWei
}


const setSentryOptionsFee = async(feeTokenStr, toChainIdsStr) => {
    feeType = 0 // FeeType.ADMIN
    const includeLocal = false

    const fee = await feeManager.getXChainFee(toChainIdsStr, includeLocal, feeType, feeTokenStr)
    const feeWei = fee*10n**(decimals - baseOrder)

    return feeWei
}


const addWhitelistFee = async(nWallets, feeTokenStr, toChainIdsStr) => {
    feeType = 21 // FeeType.WHITELIST
    const includeLocal = false

    const fee = await feeManager.getXChainFee(toChainIdsStr, includeLocal, feeType, feeTokenStr)
    const feeWei = fee*10n**(decimals - baseOrder) * nWallets

    return feeWei
}


const addCountrylistFee = async(nCountries, feeTokenStr, toChainIdsStr) => {
    feeType = 22 // FeeType.COUNTRY
    const includeLocal = false

    const fee = await feeManager.getXChainFee(toChainIdsStr, includeLocal, feeType, feeTokenStr)
    const feeWei = fee*10n**(decimals - baseOrder) * nCountries

    return feeWei
}

const verifyPersonFee = async(feeTokenStr, toChainIdsStr) => {
    feeType = 23 // FeeType.KYC
    const includeLocal = false

    const fee = await feeManager.getXChainFee(toChainIdsStr, includeLocal, feeType, feeTokenStr)
    const feeWei = fee*10n**(decimals - baseOrder)

    return feeWei
}



//////////////////////////////////////////////////////////////////////////////////////////////////

const connect = async (rpcUrl) => {
    const provider = new ethers.JsonRpcProvider(rpcUrl)

    const signer = new ethers.Wallet(PRIVATE_KEY, provider)
    const { chainId } = await provider.getNetwork()

    return {signer: signer, chainId: chainId}
}

const getRwaContracts = (chainIdStr) => {

    let rpcUrl
    let feeTokenStr
    let feeManagerAddr
    let storageManagerAddr

    if(chainIdStr == "421614") {
        rpcUrl = "https://sepolia-rollup.arbitrum.io/rpc"
        feeTokenStr = "0xbF5356AdE7e5F775659F301b07c4Bc6961044b11"
        feeManagerAddr = "0x8e1fc60c90Aff208023735c9eE54Ff6315D13182"
        mapAddr = "0x47D91341Ba367BCe483d0Ee2fE02DD1420b883EC"
    } else if (chainIdStr == "97") {
        rpcUrl = "https://data-seed-prebsc-1-s1.binance.org:8545/"
        feeTokenStr = "0xDd43fc986a13392dDbC7aeA150b41EfE27b2d0eD"
        feeManagerAddr = "0x20D5CdE9700144ED0Da22754D89f3379916c99Fa"
        mapAddr = "0xC886FFa78114cf7e701Fd33505b270505B3FeAE3"
    } else {
        return {rpcUrl: null, feeTokenStr: null, feeManagerAddr: null, mapAddr: mapAddr}
    }

    return {rpcUrl: rpcUrl, feeTokenStr: feeTokenStr, feeManagerAddr: feeManagerAddr, mapAddr: mapAddr}
}

const getFeeManager = async() => {
    const feeManager = new ethers.Contract(feeManagerAddr, feeManagerAbi, signer)
    return feeManager
}

const feeDecimals = async(feeTokenAddr) => {
    const feeToken = new ethers.Contract(feeTokenAddr, ERC20Abi, signer)
    return await feeToken.decimals()
}

const getCategories = async(ID) => {
    const map = new ethers.Contract(mapAddr, ctmRwaMapAbi, signer)
    const stor = await map.getStorageContract(ID, 1, 1)
    const ok = stor[0]

    if(ok) {
        let storageContractAddr = stor[1]
        const storageContract = new ethers.Contract(storageContractAddr, storageAbi, signer)
        const res = await storageContract.getAllURIData()
        let categories = res[0]
        return categories
    } else {
        return null
    }
}



const main = async () => {
    console.log('hello')


    // Setup for Arbitrum
    chainIdStr = "421614"

    baseOrder = 2n

    let toChainIdsStr
    let feeWei

    let rwaContracts = getRwaContracts(chainIdStr)
    let feeTokenStr = rwaContracts.feeTokenStr

    let rpcUrl = rwaContracts.rpcUrl

    const connectRes = await connect(rpcUrl)
    signer = connectRes.signer

    let publicAddress = await signer.getAddress()
    console.log(publicAddress)

    feeManagerAddr = rwaContracts.feeManagerAddr
    feeManager = await getFeeManager()

    decimals = await feeDecimals(feeTokenStr)

    mapAddr = rwaContracts.mapAddr



    // Some example values

    //////////////  Functions in CTMRWA001X  //////////////////////////////

    // deployAllCTMRWA001X
    toChainIdsStr = ["97", "11155111"] // not including local chain
    let includeLocal = true

    feeWei = await deployFee(feeTokenStr, toChainIdsStr, includeLocal)
    console.log('Deployment fee = ', feeWei);

    // changeTokenAdmin
    toChainIdsStr = ["421614", "97", "11155111"] // including local chain this time
    feeWei = await adminFee(feeTokenStr, toChainIdsStr)
    console.log('ChangeTokenAdmin fee = ', feeWei);

    // createNewSlot
    toChainIdsStr = ["421614", "97", "11155111"] // including local chain this time
    feeWei = await adminFee(feeTokenStr, toChainIdsStr)
    console.log('CreateNewSlot fee = ', feeWei);

    // transferPartialTokenX and transferWholeTokenX
    toChainIdsStr = ["97"] // Destination chain - only one value allowed. If local chain, feeWei == 0n
    feeWei = await txFee(feeTokenStr, toChainIdsStr)
    console.log('Transfer token fee = ', feeWei);

    // mintNewTokenValueLocal
    toChainIdsStr = [chainIdStr] // THIS chainId - only one value allowed.
    feeWei = await mintFee(feeTokenStr, toChainIdsStr)
    console.log('Mint token fee = ', feeWei);

    ////////////////  Functions in CTMRWA001StorageManager ///////////////////////

    // addURI
    toChainIdsStr = ["421614", "97", "11155111"] // including local chain this time
    uriCategory = 13  // Example here is for URICategory.IMAGE
    feeWei = await individualURIFee(uriCategory, feeTokenStr, toChainIdsStr)
    console.log('addURI fee = ', feeWei);

    // transferURI
    toChainIdsStr = ["97", "11155111"] // not including local chain
    const ID = 67670652457707734262283528307800251615759764170770069878035074418343211732425n
    toChainIdsStr = ["421614", "97", "11155111"] // including local chain this time
    feeWei = await transferURIFee(ID, feeTokenStr, toChainIdsStr)
    console.log('transferURI fee = ', feeWei)
    

    ////////////////  Functions in CTMRWA001SentryManager  //////////////////////

    // setSentryOptions AND goPublic
    toChainIdsStr = ["421614", "97", "11155111"] // including local chain this time
    feeWei = await setSentryOptionsFee(feeTokenStr, toChainIdsStr)
    console.log('setSentryOptions fee = ', feeWei)

    // addWhitelist
    toChainIdsStr = ["421614", "97", "11155111"] // including local chain this time
    let nWallets = 15n  // The number of wallets being added to the whitelist
    feeWei = await addWhitelistFee(nWallets, feeTokenStr, toChainIdsStr)
    console.log('addWhitelist fee = ', feeWei)

    // addCountrylist
    toChainIdsStr = ["421614", "97", "11155111"] // including local chain this time
    let nCountries = 15n  // The number of wallets being added to the whitelist
    feeWei = await addCountrylistFee(nCountries, feeTokenStr, toChainIdsStr)
    console.log('addCountrylist fee = ', feeWei)


    //////////////// Functions in CTMRWA001PolygonId  ////////////////////////////

    // verifyPerson
    toChainIdsStr = ["421614", "97", "11155111"] // including local chain this time
    feeWei = await verifyPersonFee(feeTokenStr, toChainIdsStr)
    console.log('verifyPerson fee = ', feeWei)

}

main()