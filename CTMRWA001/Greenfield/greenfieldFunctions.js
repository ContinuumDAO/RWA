const {ethers} = require('ethers')
const dotenv = require('dotenv')
const express = require("express")
const cors = require("cors")
const helmet = require("helmet")
const rateLimit = require("express-rate-limit")
const timeout = require('connect-timeout')
var bodyParser = require('body-parser')
const {ReedSolomon} = require('@bnb-chain/reed-solomon')

const fs = require('fs')

const {getRwaContracts} = require('./rwaContracts.js')
const {checkRwaObject, categorySizeLimit} = require('./checkRwaObject.js')

const {
    Client,
    VisibilityType,
    RedundancyType,
    Long,
    bytesFromBase64,
} = require('@bnb-chain/greenfield-js-sdk')

const {
    client,
    connect,
    selectSp,
    generateString,
    getTokenAdmin,
    getStorageContract,
    checkBucketExists,
    getExistingObjectName,
    getBucketName,
    getBucketNameFromID,
    getNextObjectName,
    getObjectList,
    getSingleObject,
    getChecksum,
    checksumFromBase64,
    uriTypeToInt,
    uriCategoryToInt,
    deployBucket,
    addObject,
    deleteObject,
    createFile,
    createStorageObject,
    getObject
} = require('./greenfieldLib.js')

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

//const ASSETXFRONT = "::ffff:127.0.0.1"
const ASSETXFRONTEND = "00.00.00.00"  // ipv4 for nginx/Express reverse proxy

dotenv.config()
const {abi:ctmRwaMapAbi} = require('../out/CTMRWAMap.sol/CTMRWAMap.json')
const {abi:storageManagerAbi} = require('../out/CTMRWA001StorageManager.sol/CTMRWA001StorageManager.json')
const {abi:storageAbi} = require('../out/CTMRWA001Storage.sol/CTMRWA001Storage.json')

const PRIVATE_KEY = process.env.PRIVATE_KEY

const limiter = rateLimit({
	windowMs: 10 * 60 * 1000, // 10 minutes
	limit: 10, // Limit each IP to 10 requests per `window` (here, per 10 minutes).
})

const app = express()
app.use(limiter)
app.use(bodyParser.json({limit: '50mb'}))
app.use(helmet({crossOriginResourcePolicy: false}))
app.use(cors())
app.use(express.json())
app.use(timeout('10s'))

const PORT = 3000

const rwaType = 1
const version = 1


const deployGreenfield = async (ID, chainIdStr, signer) => {

    let res

    let storageContractRes = await getStorageContract(ID, chainIdStr, signer)
    let storageContract = storageContractRes.storageContract
    if(!storageContract) {
        console.error('No Storage Contract exists for this ID')
        return {ok: false, msg: "No Storage contract", bucketName: null}
    }

    let tokenAdmin = await getTokenAdmin(storageContract, signer)

    let bucketNameRes = await getBucketName(ID, chainIdStr, signer)
    let bucketName = bucketNameRes.bucketName

    if (await checkBucketExists(bucketName)) {
        console.log("Bucket already exists")
        return {ok: true, msg: "Bucket already exists", bucketName: bucketName}
    } else {
        try {
            console.log('Adding a Bucket for CTMRWA001')
            res = await deployBucket(bucketName, tokenAdmin, signer)
            if(!res) {
                return({ok: false, msg: "Did not create a bucket", bucketName: null})
            } else {
                return {ok: true, msg: "Bucket successfully created", bucketName: bucketName}
            }
        } catch(err) {
            console.error(err.message)
            return {ok: false, msg: err.message, bucketName: null}
        }
    }

}

const createObjectPolicy = async (bucketName, objectName, creator) => {
    console.log(PermissionTypes.ActionType)

    const statement = {
      effect: PermissionTypes.Effect.EFFECT_ALLOW,
      actions: [PermissionTypes.ActionType.ACTION_GET_OBJECT, PermissionTypes.ActionType.ACTION_LIST_OBJECT],
      resources: [],
    };
    const tx = await client.object.putObjectPolicy(bucketName, objectName, {
      operator: creator,
      statements: [statement],
      principal: {
        type: PermissionTypes.PrincipalType.PRINCIPAL_TYPE_GNFD_ACCOUNT,
        value: '0x0000000000000000000000000000000000000001',
      },
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
}


const listObjects = async (bucketName) => {

    try {
        const sp = await getSps(SPNUMBER);

        const res = await client.object.listObjects({
            bucketName: bucketName,
            endpoint: sp.endpoint,
        })
        console.log(`res.code = ${res.code}`)

        if(res.code != 0) {
            return res.code
        } else {

            const gfldObjects = res.body.GfSpListObjectsByBucketNameResponse.Objects
            console.log(`OBJS = ${gfldObjects}`)
            const numObjects = gfldObjects.length
            console.log(`number of objects = ${numObjects}`)

            let objInfoRoot
            let objInfo = []

            for(let i=0; i<numObjects; i++) {
                objInfoRoot = gfldObjects[i].ObjectInfo
                console.log(objInfoRoot)
                objInfo.push({
                    name: objInfoRoot.ObjectName,
                    owner: objInfoRoot.Owner,
                    creator: objInfoRoot.Creator,
                    size: objInfoRoot.PayloadSize,
                    visibility: objInfoRoot.Visibility,
                    creationTime: objInfoRoot.CreateAt,
                    checksums: objInfoRoot.Checksums,
                })
            }

            return objInfo
        }
    } catch(err) {
        return err
    }

}



////  POST and GET methods /////////////////////////////////////////////////////////////////////////////

app.get("/", async (req, res) => {
    res.send(`Welcome to the ContinuumDAO CTMRWA001 Greenfield API.\n\n
        Try one of the following routes:\n\t
        /add-bucket (POST)\n\t
        /add-object (POST)\n\t
        /list-one_object (POST)\n\t
        /list-objects (POST)\n\t
        /delete-object (POST)\n\t
        /get-object (POST)\n\t
        /get-objectList (GET)\n\t
        /get-checksum (POST)\n\t`
    )
})

app.post("/get-checksum", async (req, res) => {

    const ipAddress = req.headers["x-real-ip"] || req.socket.remoteAddress
    console.log(`get-checksum request from IP Address: ${ipAddress}`)

    if(ipAddress != ASSETXFRONT) {
        res.send(`Request from an illegal address ${ipAddress}`)
    }

    try {
        const { body } = req
        if (!body) res.send(`No serialObject passed with POST request.`)
        const serialObject = JSON.stringify(body)

        const checksumRes = await getChecksum(serialObject)

        res.send(JSON.stringify({
            ok: checksumRes.ok, 
            msg: checksumRes.msg, 
            expectCheckSums: checksumRes.expectCheckSums, 
            checksum: checksumRes.checksum,
            hash: checksumRes.hash
        }))
    } catch(err) {
        res.send(JSON.stringify({ok: false, msg:err.message, checksum: null}))
    }
})

app.post("/list-one_object", async (req, res) => {
    const ipAddress = req.headers["x-real-ip"] || req.socket.remoteAddress
    console.log(`get-checksum request from IP Address: ${ipAddress}`)

    let msg

    if(ipAddress != ASSETXFRONT) {
        msg = `Request from an illegal address ${ipAddress}`
        res.send(JSON.stringify({ok: false, msg: msg, objectList: null}))
    }

    let IDn
    let objectName
    let rpcUrl
    let signer
    let chainIdStr
    let objectListRes

    try {
        const { body } = req
        if (!body) res.send(`No bucketName passed with POST request.`)

        IDn = BigInt(body.ID)
        console.log('ID = ', IDn)
        objectName = body.objectName
        chainIdStr = body.chainIdStr
        console.log('from chainId ', chainIdStr)

        const contractRes = getRwaContracts(chainIdStr)
        rpcUrl = contractRes.rpcUrl

        const signerRes = await connect(rpcUrl)
        signer = signerRes.signer

        objectListRes = await getSingleObject(IDn, objectName, chainIdStr, signer)

        if(objectListRes.ok) {
            res.send(JSON.stringify(objectListRes))
        } else {
            throw new Error(objectListRes.msg)
        }
    } catch(err) {
        return {ok: false, msg: objectListRes.msg, objectList: null}
    }
})

app.post("/list-objects", async (req, res) => {
    const ipAddress = req.headers["x-real-ip"] || req.socket.remoteAddress
    console.log(`get-checksum request from IP Address: ${ipAddress}`)

    let msg

    if(ipAddress != ASSETXFRONT) {
        msg = `Request from an illegal address ${ipAddress}`
        res.send(JSON.stringify({ok: false, msg: msg, objectList: null}))
    }

    let IDn
    let rpcUrl
    let signer
    let chainIdStr
    let objectList

    try {
        const { body } = req
        if (!body) res.send(`No bucketName passed with POST request.`)

        IDn = BigInt(body.ID)
        console.log('ID = ', IDn)
        chainIdStr = body.chainIdStr
        console.log('from chainId ', chainIdStr)

        const contractRes = getRwaContracts(chainIdStr)
        rpcUrl = contractRes.rpcUrl

        const signerRes = await connect(rpcUrl)
        signer = signerRes.signer

        objectList = await getObjectList(IDn, chainIdStr, signer)

        if(!objectList.ok) {
            res.send(JSON.stringify({ok: false, msg: "Could not generate object list", objectList: null}))
        } else {
            res.send(JSON.stringify({ok: true, msg: "Object list generated OK", objectList: objectList}))
        }

    } catch(err) {
        res.send(JSON.stringify({ok: false, msg:err.message, objectList: null}))
    }
})

app.post("/add-object", async (req, res) => {
    const ipAddress = req.headers["x-real-ip"] || req.socket.remoteAddress
    console.log(`Request to add an object from IP Address: ${ipAddress}`)

    let signer
    let chainIdStr

    let ID
    let rpcUrl
    let rwaObject
    let fileBuffer
    let bucketName
    let objectName = null
    let createRes
    let expectChecksums
    let transactionHash
    let signerRes
    let owner
    let msg

    if(ipAddress != ASSETXFRONT) {
        msg = `Request from an illegal address ${ipAddress}`
        res.send(JSON.stringify({ok: false, msg: msg, objectName: objectName, transactionHash: null}))
    }


    try {
        const { body } = req
        if (!body) {
            msg = `No add object data passed with POST request`
            console.log(body)
            res.send(JSON.stringify({ok: false, msg: msg, objectName: objectName, transactionHash: null}))
        }

        ID = BigInt(body.ID)
        console.log('ID = ', ID)
        owner = body.owner
        chainIdStr = body.chainIdStr
        rwaObject = body.rwaObject
        fileBuffer = Buffer.from(JSON.stringify(rwaObject))
        bucketName = body.bucketName
        objectName = body.objectName
        expectChecksums = body.expectChecksums

        const contractRes = getRwaContracts(chainIdStr)
        rpcUrl = contractRes.rpcUrl

        signerRes = await connect(rpcUrl)
        signer = signerRes.signer

        createRes = await addObject(fileBuffer, bucketName, objectName, expectChecksums, owner, signer)

        res.send(JSON.stringify(createRes))
       
    } catch(err) {
        res.send(JSON.stringify({ok: false, msg: err.message, objectName: objectName, transactionHash: transactionHash}))
    }


})

app.post("/add-bucket", async (req, res) => {

    const ipAddress = req.headers["x-real-ip"] || req.socket.remoteAddress
    console.log(`Request to add bucket from IP Address: ${ipAddress}`)

    let deployRes
    let ID
    let IDn
    let chainIdStr
    let rpcUrl
    let signerRes

    if(ipAddress != ASSETXFRONT) {
        res.send(`Request from an illegal address ${ipAddress}`)
    }

    

    try {
        const { body } = req
        if (!body) res.send(`No ID passed with POST request.`)
        
        ID = body.ID
        IDn = BigInt(ID)
        console.log(IDn)
        chainIdStr = body.chainIdStr
        const contractRes = getRwaContracts(chainIdStr)
        console.log(contractRes)
        rpcUrl = contractRes.rpcUrl

        signerRes = await connect(rpcUrl)
        signer = signerRes.signer
    
        deployRes = await deployGreenfield(IDn, chainIdStr, signer)
        let ok = deployRes.ok
        const retMessage = deployRes.msg
        let bucketName = deployRes.bucketName
        res.send(JSON.stringify(deployRes))
    } catch(err) {
        res.send(JSON.stringify({ok: false, msg:err.message, bucketName: null}))
    }
})

app.listen(PORT, () => {
    console.log(`CONTINUUM-DAO Greenfield CTMRWA001 Storage service, listening on port ${PORT}...`)
})
