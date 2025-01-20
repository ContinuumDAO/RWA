const {ethers} = require('ethers')
const dotenv = require('dotenv')
const {getRwaContracts} = require('./rwaContracts.js')
const fs = require('fs')
const axios = require('axios')
const keccak256 = require('keccak256')
const {ReedSolomon} = require('@bnb-chain/reed-solomon')
const { NodeAdapterReedSolomon } = require('@bnb-chain/reed-solomon/node.adapter')
const {
    client,
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
    VisibilityType,
    RedundancyType,
    Long,
    bytesFromBase64,
    base64FromBytes
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

const REMOTE = false

const greenfieldServer = "http://127.0.0.1:3000"

dotenv.config()

const {abi:ctmRwaMapAbi} = require('../out/CTMRWAMap.sol/CTMRWAMap.json')
const {abi:storageManagerAbi} = require('../out/CTMRWA001StorageManager.sol/CTMRWA001StorageManager.json')
const {abi:storageAbi} = require('../out/CTMRWA001Storage.sol/CTMRWA001Storage.json')


const rwaType = 1
const version = 1

const RPC_URL = process.env.RPC_URL
const PRIVATE_KEY = process.env.PRIVATE_KEY

var signer
let chainId
let ctmRwaMap
let storageManager
let feeToken

const connect = async () => {
    const provider = new ethers.JsonRpcProvider(RPC_URL)

    const signer = new ethers.Wallet(PRIVATE_KEY, provider)
    const { chainId } = await provider.getNetwork()

    return {signer: signer, chainId: chainId}
}


const deleteBucket = async(bucketName, admin, signer) => {

    let ok = checkBucketExists(bucketName, signer)
    if(!ok) {
        return false
    }

    const tx = await client.bucket.deleteBucket({
        bucketName: bucketName,
        operator: admin,
    })

    const deleteBucketTxSimulateInfo = await tx.simulate({
        denom: 'BNB',
    })

    const deleteBucketTxRes = await tx.broadcast({
        denom: 'BNB',
        gasLimit: Number(deleteBucketTxSimulateInfo?.gasLimit),
        gasPrice: deleteBucketTxSimulateInfo?.gasPrice || '5000000000',
        payer: signer.address,
        granter: '',
        privateKey: PRIVATE_KEY,
    })

    if (deleteBucketTxRes.code === 0) {
        console.log('delete bucket success');
        return true
    } else {
        console.log('delete bucket failed')
        return false
    }
}


const createObject = async (ID, rwaObject, chainIdsStr, feeToken, feeApproval, override) => {

    let bucketRes
    let storageContract
    let bucketName
    const storRes = await getStorageContract(ID)
    if(!storRes.ok) {
        return({ok: storRes.ok, msg: storRes.msg, objectName: null, bucketName: bucketName})
    } else {
        storageContract = storRes.storageContract
    }
    let tokenAdmin = await getTokenAdmin(storageContract)
    bucketRes = await getBucketName(storageContract, signer)
    if(!bucketRes.ok) {
        return {ok: false, msg: bucketRes.msg, objectName: null, bucketName: null}
    } else {
        bucketName = bucketRes.bucketName
    }

    let ok = await checkBucketExists(bucketName, signer)
    console.log(`bucketExists = ${ok}`)
    let msg
    if(!ok) {
        console.log('adding a bucket for ID ', ID)
        if(REMOTE) {
            let addBucketRes = await axios.post(greenfieldServer + '/add-bucket', {ID: ID.toString()})
            let bucketData = addBucketRes.data
            if(!bucketData.ok) {
                return {ok: false, msg: bucketData.msg, objectName: null, bucketName: bucketData.bucketName}
            }
        } else {
            let deployBucketRes = await deployBucket(bucketName, tokenAdmin)
            if(!deployBucketRes.ok) {
                return {ok: false, msg: deployBucketRes.msg, objectName: null, bucketName: bucketName}
            }
        }
    }

    const resChecksum = await getChecksumObj(rwaObject)
    ok = resChecksum.ok
    if(!ok) {
        return {ok: false, msg: resChecksum.msg, objectName: null, bucketName: bucketName}
    }

    let expectCheckSums = resChecksum.expectCheckSums
    let hash = resChecksum.hash

    let objectRes
    let objectName

    if(override) {
        const getObjRes = await getExistingObjectName(ID, hash)
        if(!getObjRes.ok) {
            return {ok: false, msg:getObjRes.msg, objectName: objectName, transactionHash: null}
        } else {
            objectName = getObjRes.objectName
            console.log('existing objectName = ', objectName)
        }
    } else {
        objectRes = await getNextObjectName(rwaObject.type, rwaObject.slot, ID, signer)
        if(!objectRes.ok) {
            return {ok: false, msg: objectRes.msg, objectName: null, transactionHash: null}
        } else {
            objectName = objectRes.objectName
        }

        let res = await createStorageObject(ID, rwaObject, hash, chainIdsStr, feeToken, feeApproval)
        if(!res.ok) {
            return {ok: false, msg: res.msg, objectName: objectName, transactionHash: null}
        }
    }

    
    fileBuffer = resChecksum.fileBuffer
    console.log('fileBuffer length = ', Long.fromInt(fileBuffer.byteLength))


    let createObjectTx
    let createObjectTxRes
    let uploadRes
    let addObjectRes
    let transactionHash

    try {
        if(REMOTE) {
            addObjectRes = await axios.post(greenfieldServer + '/add-object', {
                ID: ID.toString(),
                fileBuffer: fileBuffer,
                bucketName: bucketName,
                objectName: objectName,
            })

            ok = addObjectRes.data.ok
            msg = addObjectRes.data.msg
            transactionHash = addObjectRes.data.transactionHash

        } else {
            createObjectTx = await client.object.createObject({
                bucketName: bucketName,
                objectName: objectName,
                creator: signer.address,
                visibility: VisibilityType.VISIBILITY_TYPE_PUBLIC_READ,
                contentType: 'text/plain',
                redundancyType: RedundancyType.REDUNDANCY_EC_TYPE,
                payloadSize: Long.fromInt(fileBuffer.byteLength),
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

            transactionHash = createObjectTxRes.transactionHash

            uploadRes = await client.object.uploadObject(
                {
                    bucketName: bucketName,
                    objectName: objectName,
                    body: fileBuffer,
                    txnHash: transactionHash,
                },
                {
                    type: 'ECDSA',
                    privateKey: PRIVATE_KEY,
                },
            )

            if(uploadRes.code == 0 || uploadRes.code == '110004') {
                ok = true
                msg = "Object successfully created"
                // console.log('Upload Result:', uploadRes)
            } else {
                ok = false
                console.log(uploadRes)
                msg = "Object not successfully created"
            }
            
        }

        return {ok: ok, msg: msg, objectName: objectName, transactionHash: transactionHash}
    } catch(err) {
        if (err.message.includes('Object already exists')) {
            msg = `Object already exists ${objectName}`
        } else {
            msg = err.message
        }
        // console.log(`error creating Greenfield object signed transaction ${err.message}`)
        return {ok: false, msg: msg, objectName: objectName, transactionHash: null}
    }
    
}


const getChecksumObj = async(rwaObject) => {

    let checksumRes
    let expectCheckSums
    let serialObject
    let fileBuffer

    if(REMOTE) {
        checksumRes = await axios.post(greenfieldServer + '/get-checksum', rwaObject)

        let ok = checksumRes.data.ok

        if(!ok) {
            return {ok: false, msg: checksumRes.data.msg, expectCheckSums: null, checksum: null, hash: null}
        }

        expectCheckSums = checksumRes.data.expectCheckSums
        fileBuffer = checksumRes.data.fileBuffer
    } else {
        checksumRes = await getChecksum(JSON.stringify(rwaObject))
        expectCheckSums = checksumRes.expectCheckSums
        fileBuffer = checksumRes.fileBuffer
    }

    checksumRes = checksumFromBase64(expectCheckSums)

    return {ok: true, msg: "Checksum returned successfully", fileBuffer: fileBuffer, expectCheckSums: expectCheckSums, checksum: checksumRes.checksum, hash: checksumRes.hash}
}


const getPropertyList = async(ID, signer) => {
    try {

        let bucketName
        const storRes = await getStorageContract(ID, signer)

        let bucketRes = await getBucketNameFromID(ID, signer)
        if(!bucketRes.ok) {
            return {ok: false, msg: bucketRes.msg, objectList: null}
        } else {
            bucketName = bucketRes.bucketName
        }

        let res

        if(REMOTE) {
            res = await axios.post(greenfieldServer + '/list-objects', {bucketName: bucketName})
            console.log(res.data.objectList)
            return {ok: true, msg: "listObjects successful", objectList: res.data.objectList}
        } else {
            res = await getObjectList(ID, signer)
            return res
        }
    } catch(err) {
        return {ok: false, msg: err, objectList: null}
    }

}




const addIssuer = () => {

    const rwaTitle = "# ISSUER DETAILS"
    const rwaType = "CONTRACT"
    const slot = 0
    const rwaCategory = "ISSUER"
    const rwaText = "## Sellers of the finest assets\n Do yourself a favour and buy some now"

    const rwaIssuer = new Issuer(
        "Selqui",
        "CTM",
        "Co-Founder",
        "Continuum DAO",
        "All the World is mine to take !!",
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

    // console.log(newRwaURI.properties.email)

    return newRwaURI

}


const main = async () => {

    const connectRes = await connect()
    signer = connectRes.signer
    chainId = connectRes.chainId

    publicAddress = await signer.getAddress()
    console.log(publicAddress)

    const contractRes = getRwaContracts(chainId)
    ctmRwaMap = contractRes.ctmRwaMap
    storageManager = contractRes.storageManager
    feeToken = contractRes.feeToken


    // This is just an example using one ID and on the connected chain

    const ID =  52132802886920618599792052678530329303821379622883015540104134213040705464055n
    const rwaObject = addIssuer()  // sample rwaObject

    let storageRes = await getStorageContract(ID, signer)
    let storageContract = storageRes.storageContract
   
    let tokenAdmin = await getTokenAdmin(storageContract, signer)

    // const chainIdsStr = ["421614", "84532", "97"]
    const chainIdsStr = ["421614"]

    try {

        // let bucketRes = await getBucketName(storageContract, signer)
        // let bucketName = bucketRes.bucketName

        // let singleRes = await getSingleObject(ID, '5', signer)
        // console.log(singleRes)
        // return

        // let objectRes = await getNextObjectName(rwaObject.type,rwaObject.slot,ID, signer)
        // let objectName = objectRes.objectName
        // console.log(`Next objectName = ${objectName}`)
        // return

        // let ok = await checkBucketExists(bucketName, signer)
        // console.log('bucketExists = ', bucketName)
        // return

                                            
        // let res = await getPropertyList(ID, signer)
        // console.log(res)
        // return

        // await deleteObject(bucketName, 'pxxfmedtun', tokenAdmin)
        // await deleteBucket(bucketName, tokenAdmin, signer)
        // return

        // const resChecksum = await getChecksumObj(rwaObject)
        // let expectCheckSums = resChecksum.expectCheckSums
        // return


        // const res = await createObject(ID, rwaObject, chainIdsStr, feeToken, 100, false)
        // console.log(res)

        const getObjRes = await getObject(ID, '6', signer)
        console.log(getObjRes)

    } catch(err) {
        if (
            err.message.includes("ENOTFOUND")
            || err.message.includes("disconnected before secure TLS connection was established")
            || err.message.includes("certificate has expired")
            || err.message.includes("request timed out")
            || err.message.includes("socket disconnected")
        ) {
            console.log("Check internet connection and RE-RUN the command")
        }
        console.log(err.message)
    }
    
}

main()