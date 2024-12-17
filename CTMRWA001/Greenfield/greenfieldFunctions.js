const {ethers} = require('ethers')
const dotenv = require('dotenv')
const {ReedSolomon} = require('@bnb-chain/reed-solomon')
const fs = require('fs')

const {
    Client,
    VisibilityType,
    RedundancyType,
    Long,
    bytesFromBase64,
} = require('@bnb-chain/greenfield-js-sdk')

const {
    Rwa,
    Issuer,
    Notice,
    Provenance,
    Valuation,
    Rating,
    Legal,
    Financial,
    Prospectus,
    License,
    DueDiligence,
    Dividend,
    Redemption,
    WhoCanInvest,
    Image,

} = require('./storage_classes.js')

const rs = new ReedSolomon()

const SPNUMBER = 1

dotenv.config()
const {abi:ctmRwaMapAbi} = require('../out/CTMRWAMap.sol/CTMRWAMap.json')
const {abi:storageManagerAbi} = require('../out/CTMRWA001StorageManager.sol/CTMRWA001StorageManager.json')
const {abi:storageAbi} = require('../out/CTMRWA001Storage.sol/CTMRWA001Storage.json')

const RPC_URL = process.env.RPC_URL
const GREENFIELD_RPC_URL = process.env.NEXT_PUBLIC_GREENFIELD_RPC_URL
const GREENFIELD_CHAINID = process.env.NEXT_PUBLIC_GREEN_CHAIN_ID
const PRIVATE_KEY = process.env.PRIVATE_KEY

const client = Client.create(GREENFIELD_RPC_URL, GREENFIELD_CHAINID);

const rwaType = 1
const version = 1

var publicAddress


// For Arbitrum Sepolia
const ctmRwaMap = "0x767Eb58dEa0891eb790867eDe9b2Baae04428b45"
const storageManager = "0xE38F40EFC472Aae401BA1EDF37eDD98Ba43f5266"

const BigNumber = ethers.BigNumber
const PublicRead = 1n

var createBucketTx



const connect = () => {
    const provider = new ethers.JsonRpcProvider(RPC_URL)

    const wallet = new ethers.Wallet(PRIVATE_KEY)
    const signer = wallet.connect(provider)
    return signer
}

const getSps = async (indx) => {
    const spList = await client.sp.getStorageProviders()
    const sp = {
        operatorAddress: spList[indx].operatorAddress,
        endpoint: spList[indx].endpoint,
    };
    return sp
}

const getBucketName = async (storageContract) => {
    let bucketName
    const stor = new ethers.Contract(storageContract, storageAbi, signer)
    return(bucketName = await stor.greenfieldBucket());
}

const getNextObjectName = async (uriType, slot, ID) => {

    let objectName

    let storageContract = await getStorageContract(ID)
    if(!storageContract) {
        return null
    }

    const stor = new ethers.Contract(storageContract, storageAbi, signer)
    objectName = await stor.greenfieldObject(uriType, slot)

    return(objectName)
}

const getTokenAdmin = async (storageContract) => {
    let tokenAdmin
    const stor = new ethers.Contract(storageContract, storageAbi, signer)
    return(tokenAdmin = await stor.tokenAdmin());
}

const getStorageContract = async (ID) => {

    const ctmMap = new ethers.Contract(ctmRwaMap, ctmRwaMapAbi, signer)
    
    const res = await ctmMap.getStorageContract(ID, rwaType, version)
    let ok = res[0]
    let storageContract = res[1]

    if(!ok) {
        console.log("CTMRWA001 does not exist, or does not have a storage contract")
        return null
    } else {
        return(storageContract)
    }
}

const checkBucketExists = async (bucketName) => {
    let bucketInfo
    try {
        bucketInfo = await client.bucket.getBucketMeta({
            bucketName: bucketName,
        });
        return true
    } catch(err) {
        if (err.message.includes('not found')) {
            console.log('Bucket does not exist')
            return false
        } else {
        console.err('Error checking bucket:', err.message);
        throw err
        }
    }
}



const deployBucket = async (bucketName, operatorAddress) => {
    createBucketTx = await client.bucket.createBucket({
        bucketName: bucketName,
        creator: signer.address,
        visibility: VisibilityType.VISIBILITY_TYPE_PUBLIC_READ,
        chargedReadQuota: Long.fromString('0'),
        primarySpAddress: operatorAddress,
        paymentAddress: signer.address,
    });

    var createBucketTxSimulateInfo

    try{
        createBucketTxSimulateInfo = await createBucketTx.simulate({
            denom: 'BNB',
        });
    } catch(err) {
        console.log(err.message)
        process.exit()
    }

    // console.log('createBucketTxSimulateInfo = ', createBucketTxSimulateInfo)

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

}


const deployGreenfield = async (ID) => {

    let storageContract = await getStorageContract(ID)
    if(!storageContract) {
        return null
    }

    // check that wallet is tokenAdmin
    let tokenAdmin = await getTokenAdmin(storageContract)
    if(tokenAdmin != publicAddress) {
        console.error(`Signer is not the token admin for ID ${ID}`)
        return(null)
    }


    let bucketName = await getBucketName(storageContract)
    const sp = await getSps(SPNUMBER)
    if(!sp) {
        console.error('Greenfield Storage Provider is undefined')
        return null
    }
    console.log(sp)
    
    // console.log('bucketName = ', bucketName)
    console.log(`operator address : ${sp.operatorAddress}`)

    if (await checkBucketExists(bucketName)) {
        console.log('Bucket already exists')
        return(bucketName)
    } else {
        console.log('Adding a Bucket for CTMRWA001')
        try{
            await deployBucket(bucketName, sp.operatorAddress)
            return(bucketName)
        } catch(err) {
            console.error(err.message)
            return null
        }
    }

}

const createObject = async (rwaObject, bucketName, objectName) => {

    const {...ctmObject} = rwaObject
    //const arrayBuffer = Buffer.from(ctmObject)
    serialObject = JSON.stringify(rwaObject)

    const expectCheckSums = rs.encode(Uint8Array.from(serialObject));
    const checkSum = expectCheckSums.map((x) => bytesFromBase64(x))
    //console.log(checkSum)

    let tempFile = bucketName + '.' + objectName + '.json'

    let createObjectTx
    let createObjectTxRes

    try {
        createObjectTx = await client.object.createObject({
            bucketName: bucketName,
            objectName: objectName,
            creator: signer.address,
            visibility: VisibilityType.VISIBILITY_TYPE_PUBLIC_READ,
            contentType: 'application/json',
            redundancyType: RedundancyType.REDUNDANCY_EC_TYPE,
            payloadSize: Long.fromInt(serialObject.length),
            expectChecksums: expectCheckSums.map((x) => bytesFromBase64(x)),
        });

        const createObjectTxSimulateInfo = await createObjectTx.simulate({
            denom: 'BNB',
        });

        createObjectTxRes = await createObjectTx.broadcast({
            denom: 'BNB',
            gasLimit: Number(createObjectTxSimulateInfo?.gasLimit),
            gasPrice: createObjectTxSimulateInfo?.gasPrice || '5000000000',
            payer: signer.address,
            granter: '',
            privateKey: PRIVATE_KEY,
        });

    } catch(err) {
        console.log(`error creating Greenfield Object ${err.message}`)
        return null
    }

    // console.log('create object success', createObjectTxRes);

    // Write the serialized object to a temporary local file for upload
    fs.writeFileSync(tempFile, serialObject);
    console.log(fs.readFileSync(tempFile))


    const uploadRes = await client.object.uploadObject(
        {
          bucketName: bucketName,
          objectName: objectName,
          body: fs.readFileSync(tempFile),
          txnHash: createObjectTxRes.transactionHash,
        },
        {
          type: 'ECDSA',
          privateKey: PRIVATE_KEY,
        },
    );

    // const uploadRes = await client.object.putObject({
    //     bucketName,
    //     objectName,
    //     //body: serialObject,
    //     body: fs.readFileSync(tempFile),
    //     contentType: 'application/json'
    // }, {
    //     // type: 'EDDSA', // or another authentication method
    //     // domain: window.location.origin,
    //     // seed: offChainData.seedString,
    //     // address
    //     type: 'ECDSA',
    //     privateKey: PRIVATE_KEY
    // });

    console.log('Upload Result:', uploadRes);
    // Clean up temporary file
    fs.unlinkSync(tempFile);

    return checkSum
    
}

const getObject = async (bucketName, objectName) => {
    const getObjectResult = await client.object.getObject(
        {
            bucketName: bucketName, 
            objectName: objectName,
        },
        {
            type: 'ECDSA',
            privateKey: PRIVATE_KEY,
        }

    );

    if(getObjectResult.statusCode == 404) {
        console.error(`Greenfield Object ${objectName} does not exist`)
        return null
    } else {
        const deserializedObject = JSON.parse(getObjectResult.body.toString());
        console.log('Deserialized Object:', deserializedObject);
        return(deserializedObject)
    }
}

const deleteObject = async (bucketName, objectName) => {
    const tx = await client.object.deleteObject({
        bucketName: bucketName,
        objectName: objectName,
        operator: signer.address,
      });
    
      const simulateTx = await tx.simulate({
        denom: 'BNB',
      });
    
      const createObjectTxRes = await tx.broadcast({
        denom: 'BNB',
        gasLimit: Number(simulateTx?.gasLimit),
        gasPrice: simulateTx?.gasPrice || '5000000000',
        payer: signer.address,
        granter: '',
        privateKey: PRIVATE_KEY,
      });
    
      if (createObjectTxRes.code === 0) {
        console.log('delete object success');
      }
}

const downloadFile = async(bucketName, objectName) => {
    const res = await client.object.downloadFile(
        {
            bucketName,
            objectName,
        },
        {
            type: 'ECDSA',
            privateKey: PRIVATE_KEY,
        },
    );
    return res
}


const listObjects = async (bucketName) => {
    const res = await client.object.listObjects({
        bucketName: bucketName,
    })

    return res
}

const addIssuer = () => {

    const rwaTitle = "# ISSUER DETAILS"
    const rwaType = "CONTRACT"
    const slot = ""
    const rwaCategory = "ISSUER"
    const rwaText = "## Sellers of the finest assets\n Do yourself a favour and buy some"

    const rwaIssuer = new Issuer(
        "Selqui",
        "CTM",
        "Co-Founder",
        "ContinuumDAO",
        "The World",
        "Xanadu",
        "12345678XN",
        "https:XanaduCompanyRegistrationOffice",
        "abc@continuumdao.org",
        "@ContinuumDAO",
        "https://continuumdao.org",
        "https://x.com/ContinuumDAO",
        "+555",
        "55555555",
        "https://somelawfirm.com/lawracle/continuumdao/1/"
    )

    const newRwaURI = new Rwa(
        rwaTitle,
        rwaType,
        slot,
        rwaCategory,
        rwaIssuer,
        rwaText       
    )

    console.log(newRwaURI.properties.email)

    return newRwaURI

}

const main = async () => {
    signer = connect()
    publicAddress = await signer.getAddress()
    //console.log(publicAddress)

    const ID = 100717520879586792025282533445662450073598293455206286955762820529058356160766n

    const bucketName = await deployGreenfield(ID)
    console.log(`bucketName = ${bucketName}`)

    // const newRwaURI = addIssuer()

    // const objectName = await getNextObjectName(0n, 0, ID)
    // console.log(`New Greenfield object name = ${objectName}`)

    // const checksum = await createObject(newRwaURI, bucketName, 'tmp')
    // console.log(checksum)

    const newObj = await getObject(bucketName, 'tmp')
    console.log(newObj)

    // console.log(await listObjects(bucketName))

    // console.log(await client.object.headObject(bucketName, 'tmp'))

    // const res = await downloadFile(bucketName, 'tmp')
    // console.log(res)

    // await deleteObject(bucketName, '0')
}

main()

