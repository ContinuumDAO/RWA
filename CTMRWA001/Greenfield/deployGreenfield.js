const {ethers} = require('ethers')
const dotenv = require('dotenv')

const {
    Client,
    VisibilityType,
    RedundancyType,
    Long,
    bytesFromBase64,
} = require('@bnb-chain/greenfield-js-sdk');

const client = Client.create('https://gnfd-testnet-fullnode-tendermint-ap.bnbchain.org', '5600');

dotenv.config()
const {abi:ctmRwaMapAbi} = require('../out/CTMRWAMap.sol/CTMRWAMap.json')
const {abi:storageManagerAbi} = require('../out/CTMRWA001StorageManager.sol/CTMRWA001StorageManager.json')
const {abi:storageAbi} = require('../out/CTMRWA001Storage.sol/CTMRWA001Storage.json')

dotenv.config()
const RPC_URL = process.env.RPC_URL
const PRIVATE_KEY = process.env.PRIVATE_KEY

const rwaType = 1
const version = 1


//var ID = 99684070135934630131606551487381759499506454134815756064540932287878103004710n

// Replace this with an actual ID that you are the admin of
var ID = n

// For Arbitrum Sepolia
const ctmRwaMap = "0x53C42f0AE7BbBD3c5c1336d7E87a9408EC27b90F"
const storageManager = "0x78e9F16b42508a9BC0892bFF922c09067de08Fc5"

const BigNumber = ethers.BigNumber
const PublicRead = 1n



const connect = () => {
    const provider = new ethers.JsonRpcProvider(RPC_URL)

    const wallet = new ethers.Wallet(PRIVATE_KEY)
    const signer = wallet.connect(provider)
    return signer
}

const getSps = async () => {
    const spList = await client.sp.getStorageProviders()
    const sp = {
        operatorAddress: spList[0].operatorAddress,
        endpoint: spList[0].endpoint,
    };
    return sp
};

var createBucketTx

const deployBucket = async (name, operatorAddress) => {
    	createBucketTx = await client.bucket.createBucket({
        bucketName: name,
        creator: signer.address,
        visibility: VisibilityType.VISIBILITY_TYPE_PUBLIC_READ,
        chargedReadQuota: Long.fromString('0'),
        primarySpAddress: operatorAddress,
        paymentAddress: signer.address,
    });

    try{
        const createBucketTxSimulateInfo = await createBucketTx.simulate({
            denom: 'BNB',
        });
    } catch(err) {
        console.log(err.message)
        process.exit()
    }

    console.log('createBucketTxSimulateInfo = ', createBucketTxSimulateInfo)

    var res

    try{
            res = await createBucketTx.broadcast({
            denom: 'BNB',
            gasLimit: Number(createBucketTxSimulateInfo?.gasLimit),
            gasPrice: createBucketTxSimulateInfo?.gasPrice || '5000000000',
            payer: signer.address,
            granter: '',
            privateKey: PRIVATE_KEY
        });

        console.log('res = ', res)
        return

    } catch(err) {
        console.log(err.message)
        process.exit()
    }

    console.log('should not be here')
    return
}

const main = async () => {
    signer = connect()
    console.log('connected')

    //const name = "tmp.continuumdao.bucket.test.1"
    
    // const sm = new ethers.Contract(storageManager, abi, signer)

    const ctmMap = new ethers.Contract(ctmRwaMap, ctmRwaMapAbi, signer)
    let res = await ctmMap.getStorageContract(ID, rwaType, version)
    let storageContract = res[1]
    console.log('storageContract = ', storageContract)

    const stor = new ethers.Contract(storageContract, storageAbi, signer)
    const bucketName = await stor.greenfieldBucket();
    console.log('contractNewName = ', bucketName)

    console.log('sp')
    const sp = await getSps()
    console.log(`operator address : ${sp.operatorAddress}`)

    try{
        await deployBucket(bucketName, sp.operatorAddress)
    } catch(err) {
        console.error(err.message)
    }

}

main()
