const {ethers} = require('ethers')
const dotenv = require('dotenv')
const express = require("express")
const cors = require("cors")
const helmet = require("helmet")
const rateLimit = require("express-rate-limit")
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

const SPNUMBER = 3
const ASSETXFRONT = "::ffff:127.0.0.1"

dotenv.config()
const {abi:ctmRwaMapAbi} = require('../out/CTMRWAMap.sol/CTMRWAMap.json')
const {abi:storageManagerAbi} = require('../out/CTMRWA001StorageManager.sol/CTMRWA001StorageManager.json')
const {abi:storageAbi} = require('../out/CTMRWA001Storage.sol/CTMRWA001Storage.json')

const RPC_URL = process.env.RPC_URL
const GREENFIELD_RPC_URL = process.env.NEXT_PUBLIC_GREENFIELD_RPC_URL
const GREENFIELD_CHAINID = process.env.NEXT_PUBLIC_GREEN_CHAIN_ID
const PRIVATE_KEY = process.env.PRIVATE_KEY

const client = Client.create(GREENFIELD_RPC_URL, GREENFIELD_CHAINID);

const limiter = rateLimit({
	windowMs: 10 * 60 * 1000, // 10 minutes
	limit: 10, // Limit each IP to 10 requests per `window` (here, per 10 minutes).
})

const app = express()
app.use(limiter)
app.use(helmet({crossOriginResourcePolicy: false}))
app.use(cors())
app.use(express.json())

const PORT = 3000

const rwaType = 1
const version = 1

var publicAddress


// For Arbitrum Sepolia
const ctmRwaMap = "0x1113E64C90dab3d1c2Da5850e3eEE672D33CE1f3"
const storageManager = "0x769139881024cE730dE9de9c21E3ad6fb5a872f2"

var createBucketTx

var signer



const connect = () => {
    const provider = new ethers.JsonRpcProvider(RPC_URL)

    const wallet = new ethers.Wallet(PRIVATE_KEY)
    signer = wallet.connect(provider)
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

    try {
        const stor = new ethers.Contract(storageContract, storageAbi, signer)
        bucketName = await stor.greenfieldBucket()
    return {ok: true, msg: "Successfully got bucketName", bucketName: bucketName.replace('.', '-')}
    } catch(err) {
        return {ok: false, msg: err.message, bucketName: null}
    }
}

const getNextObjectName = async (uriType, slot, ID) => {

    let objectName
    let storageContract

    let storRes = await getStorageContract(ID)
    if(!storRes.ok) {
        return {ok: false, msg: storRes.msg, objectName: null}
    } else {
        storageContract = storRes.storageContract
    }

    const stor = new ethers.Contract(storageContract, storageAbi, signer)
    objectName = await stor.greenfieldObject(uriTypeToInt(uriType), uriSlotToInt(slot))
   
    return{ok: true, msg: "Successfully got objectName", objectName: objectName.replaceAll('.', '-')}
}

const uriTypeToInt = (uriType) => {
    if(uriType == "CONTRACT") return 0
    else if(uriType == "SLOT") return 1
    else return -1
}

const uriSlotToInt = (slot) => {
    if(slot == "") return 0
    else return Number(slot)
}

const uriCategoryToInt = (uriCategory) => {
    if(uriCategory == "ISSUER") return 0
    else if(uriCategory == "PROVENANCE") return 1
    else if(uriCategory == "VALUATION") return 2
    else if(uriCategory == "PROSPECTUS") return 3
    else if(uriCategory == "RATING") return 4
    else if(uriCategory == "LEGAL") return 5
    else if(uriCategory == "FINANCIAL") return 6
    else if(uriCategory == "LICENSE") return 7
    else if(uriCategory == "DUEDILIGENCE") return 8
    else if(uriCategory == "NOTICE") return 9
    else if(uriCategory == "DIVIDEND") return 10
    else if(uriCategory == "REDEMPTION") return 11
    else if(uriCategory == "WHOCANINVEST") return 12
    else if(uriCategory == "IMAGE") return 13
    else if(uriCategory == "VIDEO") return 14
    else if(uriCategory == "ICON") return 15
    else return -1
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
    let msg

    if(!ok) {
        msg = "CTMRWA001 does not exist, or does not have a storage contract"
        console.log("CTMRWA001 does not exist, or does not have a storage contract")
        return {ok: false, msg: msg, storageContract: null}
    } else {
        return {ok: true, msg: "Successfully got storageContract", storageContract: res[1]}
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
        if (err.message.includes('No such bucket')) {
            console.log('Bucket does not exist')
            return false
        } else {
            throw new Error(`Error checking bucket: ${err.message}`)
        }
    }
}



const deployBucket = async (bucketName, creator, operatorAddress) => {

    try {
        createBucketTx = await client.bucket.createBucket({
            bucketName: bucketName,
            creator: creator,
            visibility: VisibilityType.VISIBILITY_TYPE_PUBLIC_READ,
            chargedReadQuota: Long.fromString('0'),
            primarySpAddress: operatorAddress,
            paymentAddress: signer.address,
        });

        var createBucketTxSimulateInfo

        createBucketTxSimulateInfo = await createBucketTx.simulate({
            denom: 'BNB',
        });
    } catch(err) {
        console.log(err.message)
        return false
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
        return true

    } catch(err) {
        console.log(err.message)
        return false
    }

}


const deployGreenfield = async (ID) => {

    let res

    let storageContract = await getStorageContract(ID)
    if(!storageContract) {
        console.error('No Storage Contract exists for this ID')
        return {ok: false, msg: "No Storage contract", bucketName: null}
    }

    let tokenAdmin = await getTokenAdmin(storageContract)
    // if(tokenAdmin != publicAddress) {
    //     console.error(`Signer is not the token admin for ID ${ID}`)
    //     return {ok: false, msg: "Signer is not tokenAdmin", bucketName: null}
    // }


    let bucketName = await getBucketName(storageContract)
    const sp = await getSps(SPNUMBER)
    if(!sp) {
        console.error('Greenfield Storage Provider is undefined')
        return {ok: false, msg: "Greenfield Storage Provider is undefined", bucketName: null}
    }
    // console.log(sp)
    
    // console.log('bucketName = ', bucketName)
    console.log(`operator address : ${sp.operatorAddress}`)

    if (await checkBucketExists(bucketName)) {
        console.log("Bucket already exists")
        return {ok: true, msg: "Bucket already exists", bucketName: bucketName}
    } else {
        try {
            console.log('Adding a Bucket for CTMRWA001')
            res = await deployBucket(bucketName, tokenAdmin, sp.operatorAddress)
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


const createObject = async (ID, rwaObject, bucketName, objectName) => {

    let tempFile = bucketName + '.' + objectName + '.json'

    let serialObject = JSON.stringify(rwaObject)

    let storageContract = await getStorageContract(ID)
    let admin = await getTokenAdmin(storageContract)
    console.log("admin = ", admin)

    const expectCheckSums = rs.encode(Uint8Array.from(serialObject))

    let ok
    let msg
    let createObjectTx
    let createObjectTxRes
    let transactionHash = null
    let uploadRes


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
        })

        createObjectTxRes = await createObjectTx.broadcast({
            denom: 'BNB',
            gasLimit: Number(createObjectTxSimulateInfo?.gasLimit),
            gasPrice: createObjectTxSimulateInfo?.gasPrice || '5000000000',
            payer: signer.address,
            granter: '',
            privateKey: PRIVATE_KEY,
        })

        // Write the serialized object to a temporary local file for upload
        fs.writeFileSync(tempFile, serialObject)
        // console.log(fs.readFileSync(tempFile))

        transactionHash = createObjectTxRes.transactionHash

        uploadRes = await client.object.uploadObject(
            {
                bucketName: bucketName,
                objectName: objectName,
                body: createFile(tempFile),
                txnHash: transactionHash,
            },
            {
                type: 'ECDSA',
                privateKey: PRIVATE_KEY,
            },
        )

        console.log('Upload Result:', uploadRes)


        // Clean up temporary file
        fs.unlinkSync(tempFile)

        if(uploadRes.code == 0 || uploadRes.code == '110004') {
            ok = true
            msg = "Object successfully created"
            console.log('Upload Result:', uploadRes)
        } else {
            ok = false
            msg = "Object not successfully created"
        }
        
        return {ok: ok, msg: msg, objectName: objectName, transactionHash: transactionHash}

    } catch(err) {
        console.log('ERROR')
        ok = false
        msg = `error creating Greenfield Object ${err.message}`
        console.log(msg)
        return {ok: ok, msg: msg, objectName: objectName, transactionHash: transactionHash}
    }
}

function createFile(path) {
    const stats = fs.statSync(path)
    const fileSize = stats.size
  
    return {
      name: path,
      type: '',
      size: fileSize,
      content: fs.readFileSync(path),
    }
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

const getObjectList = async(ID) => {
    try {

        let bucketName
        const storRes = await getStorageContract(ID)

        let bucketRes = await getBucketNameFromID(ID)
        if(!bucketRes.ok) {
            return {ok: false, msg: bucketRes.msg, objectList: null}
        } else {
            bucketName = bucketRes.bucketName
        }

        let spRes
        let sp

        if(REMOTE) {
            let res = await axios.post(greenfieldServer + '/list-objects', {bucketName: bucketName})
            console.log(res.data.objectList)
            return {ok: true, msg: "listObjects successful", objectList: res.data.objectList}
        } else {
            sp = await selectSp()

            const res = await client.object.listObjects({
                bucketName: bucketName,
                endpoint: sp.endpoint,
            })
            // console.log(`res.code = ${res.code}`)
            // console.log(res.message)

            if(res.code != 0) {
                return {ok: false, msg: res.message, objectList: null}
            } else {

                const gfldObjects = res.body.GfSpListObjectsByBucketNameResponse.Objects
                // console.log(`OBJS = ${gfldObjects}`)
                const numObjects = gfldObjects.length
                console.log(`number of candidate objects = ${numObjects}`)

                let objInfoRoot
                let objInfo = []

                let uriCategory
                let uriType
                let uriObjectName
                let uriTitle
                let slot
                let uriTimestamp

                for(let i=0; i<numObjects; i++) {
                    objInfoRoot = gfldObjects[i].ObjectInfo

                    checksumRes = checksumFromBase64(objInfoRoot.Checksums)

                    uriDataRes = await getURIStorageData(ID, checksumRes.hash)

                    uriCategory = Number(uriDataRes.uriData[0])
                    uriType = Number(uriDataRes.uriData[1])
                    uriObjectName = uriDataRes.uriData[4].replaceAll('.', '-')
                    uriTitle = uriDataRes.uriData[2]
                    slot = uriType == 0? slot = -1: slot = Number(uriDataRes.uriData[3])
                    uriTimestamp = Number(uriDataRes.uriData[6])

                    console.log(`objectName ${uriObjectName}`)

                    storageHash = uriDataRes.uriData[5]
                    objectHash = '0x' + checksumRes.hash.toString('hex')

                    if (!uriDataRes.ok) {
                        return {ok: false, msg: uriDataRes.msg, objectList: null}
                    } else if (uriObjectName != objInfoRoot.ObjectName) {
                        console.log(`Object name in contract ${uriObjectName} does not match objectName in Greenfield ${objInfoRoot.ObjectName}`)
                    } else if (storageHash == objectHash) {
                        // console.log('stor hash')
                        // console.log(storageHash)
                        // console.log('Obj hash')
                        // console.log(objectHash)
            

                        objInfo.push({
                            name: objInfoRoot.ObjectName,
                            uriCategory: uriCategory,
                            uriType: uriType,
                            slot: slot,
                            uriTitle: uriTitle,
                            owner: objInfoRoot.Owner,
                            creator: objInfoRoot.Creator,
                            size: objInfoRoot.PayloadSize,
                            visibility: objInfoRoot.Visibility,
                            creationTime: objInfoRoot.CreateAt,
                            uriTimestamp: uriTimestamp,
                            checksums: objInfoRoot.Checksums,
                        })
                    } else if (storageHash != objectHash) {
                        console.log(`Storage hash ${storageHash} does not match Object hash ${objectHash}`)
                    }
                }

                return {ok: true, msg: "listObjects successful", objectList: objInfo}
            }
        }
    } catch(err) {
        return {ok: false, msg: err, objectList: null}
    }

}

const getChecksum = async(serialObject) => {

    let expectCheckSums
    let fileBuffer
   
    try {
        fileBuffer = Buffer.from(serialObject)

        expectCheckSums = rs.encode(Uint8Array.from(fileBuffer))

        let checksumRes = checksumFromBase64(expectCheckSums)

        return {ok: true, msg: "Checksum returned successfully", fileBuffer: fileBuffer, expectCheckSums: expectCheckSums, checksum: checksumRes.checksum, hash: checksumRes.hash}
    } catch (err) {
        return {ok: false, msg: err.message, fileBuffer: null, expectCheckSums: null, checksum: null, hash: null}
    }
}

////  POST and GET methods /////////////////////////////////////////////////////////////////////////////

app.get("/", async (req, res) => {
    res.send(`Welcome to the ContinuumDAO CTMRWA001 Greenfield API.\n\n
        Try one of the following routes:\n\t
        /add-bucket (POST)\n\t
        /add-object (POST)\n\t
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
    //console.log(req.body)

    try {
        const { body } = req
        // console.log(body)
        if (!body) res.send(`No serialObject passed with POST request.`)
        const serialObject = JSON.stringify(body)
        // console.log(serialObject)

        const checksumRes = getChecksum(serialObject)

        res.send(JSON.stringify(checksumRes))
    } catch(err) {
        res.send(JSON.stringify({ok: false, msg:err.message, checksum: null}))
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

    let objectList
    try {
        const { body } = req
        if (!body) res.send(`No bucketName passed with POST request.`)

        console.log(`bucketName = ${body.bucketName}`)
        objectList = await listObjects(body.bucketName)

        if(objectList < 0) {
            res.send(JSON.stringify({ok: false, msg: "Could not generate object list", objectList: null}))
        }

        res.send(JSON.stringify({ok: true, msg: "Object list generated OK", objectList: objectList}))
        
    } catch(err) {
        res.send(JSON.stringify({ok: false, msg:err.message, objectList: null}))
    }
})

app.post("/add-object", async (req, res) => {
    const ipAddress = req.headers["x-real-ip"] || req.socket.remoteAddress
    console.log(`Request to add an object from IP Address: ${ipAddress}`)

    let ID
    let rwaObject
    let bucketName
    let objectName = null
    let createRes
    let transactionHash
    let owner
    let msg

    if(ipAddress != ASSETXFRONT) {
        msg = `Request from an illegal address ${ipAddress}`
        res.send(JSON.stringify({ok: false, msg: msg, objectName: objectName, transactionHash: null}))
    }

    signer = connect()

    try {
        const { body } = req
        if (!body) {
            msg = `No add object data passed with POST request`
            console.log(body)
            res.send(JSON.stringify({ok: false, msg: msg, objectName: objectName, transactionHash: null}))
        }

        ID = BigInt(body.ID)
        console.log('ID = ', ID)
        fileBuffer = body.fileBuffer
        bucketName = body.bucketName
        objectName = body.objectName

        createRes = await createObject(ID, rwaObject, bucketName, objectName)

        
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

    if(ipAddress != ASSETXFRONT) {
        res.send(`Request from an illegal address ${ipAddress}`)
    }

    signer = connect()

    try {
        const { body } = req
        if (!body) res.send(`No ID passed with POST request.`)
        
        ID = body.ID
        IDn = BigInt(ID)
        console.log(IDn)
    
        deployRes = await deployGreenfield(IDn)
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

//debug()

