const {ethers} = require('ethers')
const {ReedSolomon} = require('@bnb-chain/reed-solomon')
const { NodeAdapterReedSolomon } = require('@bnb-chain/reed-solomon/node.adapter')
const keccak256 = require('keccak256')
const fs = require('fs')

const dotenv = require('dotenv')
dotenv.config()
const PRIVATE_KEY = process.env.PRIVATE_KEY

const {abi:ctmRwaMapAbi} = require('../out/CTMRWAMap.sol/CTMRWAMap.json')
const {abi:storageManagerAbi} = require('../out/CTMRWA001StorageManager.sol/CTMRWA001StorageManager.json')
const {abi:storageAbi} = require('../out/CTMRWA001Storage.sol/CTMRWA001Storage.json')


const rwaType = 1
const version = 1

const {getRwaContracts} = require('./rwaContracts.js')


const {
    Client,
    VisibilityType,
    RedundancyType,
    Long,
    bytesFromBase64,
    base64FromBytes
} = require('@bnb-chain/greenfield-js-sdk')

// const rs = new ReedSolomon()
const rs = new NodeAdapterReedSolomon()

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

const getChainId = async () => {
    const provider = new ethers.JsonRpcProvider(RPC_URL)
    const { chainId } = await provider.getNetwork()
    return chainId
}

const connect = async (rpcUrl) => {
    const provider = new ethers.JsonRpcProvider(rpcUrl)

    const signer = new ethers.Wallet(PRIVATE_KEY, provider)
    const { chainId } = await provider.getNetwork()

    return {signer: signer, chainId: chainId}
}


const client = Client.create(
    process.env.NEXT_PUBLIC_GREENFIELD_RPC_URL,
    process.env.NEXT_PUBLIC_GREEN_CHAIN_ID,
    )

    const getSps = async () => {
    const sps = await client.sp.getStorageProviders()
    const finalSps = (sps ?? []).filter((v) => v.endpoint.includes('nodereal'))

    return finalSps
}

const getAllSps = async () => {
    const sps = await getSps()

    return sps.map((sp) => {
        return {
        address: sp.operatorAddress,
        endpoint: sp.endpoint,
        name: sp.description?.moniker,
        }
    })
}

const selectSp = async () => {
    const finalSps = await getSps()

    const selectIndex = Math.floor(Math.random() * finalSps.length)

    const secondarySpAddresses = [
        ...finalSps.slice(0, selectIndex),
        ...finalSps.slice(selectIndex + 1),
    ].map((item) => item.operatorAddress)
    const selectSpInfo = {
        id: finalSps[selectIndex].id,
        endpoint: finalSps[selectIndex].endpoint,
        primarySpAddress: finalSps[selectIndex]?.operatorAddress,
        sealAddress: finalSps[selectIndex].sealAddress,
        secondarySpAddresses,
    }

    return selectSpInfo
}

const generateString = (length) => {
    const characters = 'abcdefghijklmnopqrstuvwxyz'

    let result = ''
    const charactersLength = characters.length
    for (let i = 0; i < length; i++) {
        result += characters.charAt(Math.floor(Math.random() * charactersLength))
    }

    return result
}


const getBucketName = async (ID, chainIdStr, signer) => {

    let storageContract
    const storRes = await getStorageContract(ID, chainIdStr, signer)

    if(!storRes.ok) {
        return({ok: storRes.ok, msg: storRes.msg, bucketName: null})
    } else {
        storageContract = storRes.storageContract
    }

    let bucketName

    try {
        const stor = new ethers.Contract(storageContract, storageAbi, signer)
        bucketName = await stor.greenfieldBucket()
    return {ok: true, msg: "Successfully got bucketName", bucketName: bucketName.replace('.', '-')}
    } catch(err) {
        return {ok: false, msg: err.message, bucketName: null}
    }
}

const getBucketNameFromID = async (ID, chainIdStr, signer) => {

    let bucketName
    let bucketRes = await getBucketName(ID, chainIdStr, signer)
    if(!bucketRes.ok) {
        return {ok: false, msg: bucketRes.msg, bucketName: null}
    } else {
        bucketName = bucketRes.bucketName.replaceAll('.', '-')
        return {ok: true, msg: "Successfully got bucketName", bucketName: bucketName}
    }
}

const getNextObjectName = async (uriType, slot, ID, chainIdStr, signer) => {

    let objectName
    let storageContract

    let storRes = await getStorageContract(ID, chainIdStr, signer)
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
    if(uriType == "CONTRACT") return "0"
    else if(uriType == "SLOT") return 1
    else return -1
}

const uriSlotToInt = (slot) => {
    if(slot == "") return 0
    else return Number(slot)
}

const uriCategoryToInt = (uriCategory) => {
    if(uriCategory == "ISSUER") return "0"
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


const getTokenAdmin = async (storageContract, signer) => {
    let tokenAdmin
    const stor = new ethers.Contract(storageContract, storageAbi, signer)
    return(tokenAdmin = await stor.tokenAdmin())
}

const getStorageContract = async (ID, chainIdStr, signer) => {

    const {ctmRwaMap, storageManager} = getRwaContracts(chainIdStr)
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
        })
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

const getExistingObjectName = async (ID, hash, chainIdStr, signer) => {
    let uriDataRes

    try {
        uriDataRes = await getURIStorageData(ID, hash, chainIdStr, signer)

        if(!uriDataRes.ok) {
            return {ok: false, msg: uriDataRes.msg, objectName: null}
        } else {
            return {ok: true, msg: "Successfully got existing object name", objectName: uriDataRes.uriData[4]}
        }

    } catch(err) {
        return {ok: false, msg: err.message, objectName: null}
    }
}

const deployBucket = async (bucketName, creator, signer) => {

    let spRes
    let sp

    try {
        sp = await selectSp()

        createBucketTx = await client.bucket.createBucket({
            bucketName: bucketName,
            creator: creator,
            visibility: VisibilityType.VISIBILITY_TYPE_PUBLIC_READ,
            chargedReadQuota: Long.fromString('0'),
            primarySpAddress: sp.operatorAddress,
            paymentAddress: signer.address,
        })

        var createBucketTxSimulateInfo

        createBucketTxSimulateInfo = await createBucketTx.simulate({
            denom: 'BNB',
        })
    
        var res

        res = await createBucketTx.broadcast({
            denom: 'BNB',
            gasLimit: Number(createBucketTxSimulateInfo?.gasLimit),
            gasPrice: createBucketTxSimulateInfo?.gasPrice || '5000000000',
            payer: signer.address,
            granter: '',
            privateKey: PRIVATE_KEY
        })

        // console.log('res = ', res)
        return {ok: true, msg: "Successfully created a bucket", bucketName: bucketName}

    } catch(err) {
        return {ok: false, msg: err.message, bucketName: null}
    }

}

const getChecksum = async(serialObject) => {

    let expectCheckSums
    let fileBuffer = Buffer.from(serialObject)

    expectCheckSums = rs.encode(Uint8Array.from(fileBuffer))
    fileBuffer = Buffer.from(serialObject)

    let checksumRes = checksumFromBase64(expectCheckSums)

    return {ok: true, msg: "Checksum returned successfully", fileBuffer: fileBuffer, expectCheckSums: expectCheckSums, checksum: checksumRes.checksum, hash: checksumRes.hash}
}


const checksumFromBase64 = (expectCheckSums) => {
    // console.log(expectCheckSums)
    const checksum = expectCheckSums.map((x) => bytesFromBase64(x))

    // console.log('checksum = ', checksum)

    const abi = new ethers.AbiCoder()

    const abiData = abi.encode(expectCheckSums.map((x) => 'string'), expectCheckSums)

    const hash = keccak256(abiData)
    // console.log('hash = ', hash)

    return {checksum: checksum, hash: hash}
}

const getURIStorageData = async (ID, hash, chainIdStr, signer) => {

    let uriDataRes

    try {
        const storRes = await getStorageContract(ID, chainIdStr, signer)
        let storageAddr

        if(!storRes.ok) {
            return {ok: false, msg: storRes.msg, uriData: null}
        } else {
            storageAddr = storRes.storageContract
        }

        const stor = new ethers.Contract(storageAddr, storageAbi, signer)

        uriDataRes = await stor.getURIHash(hash)

        // console.log(uriDataRes)
        // console.log("**********************************")

        return {ok: true, msg: "Successfully got URI data from contract", uriData: uriDataRes}

    } catch(err) {
        return {ok: false, msg: err.message, uriData: null}
    }
}

const createStorageObject = async(
    ID, 
    rwaObject, 
    hash, 
    chainIdsStr, 
    feeToken, 
    feeApproval, 
    chainIdStr, 
    signer
) => {

    try{

        const {ctmRwaMap, storageManager} = getRwaContracts(chainIdStr)
        const ctmMap = new ethers.Contract(ctmRwaMap, ctmRwaMapAbi, signer)
        const storRes = await getStorageContract(ID, chainIdStr, signer)
        let storageAddr

        if(!storRes.ok) {
            return(storRes)
        } else {
            storageAddr = storRes.storageContract
        }

        const stor = new ethers.Contract(storageAddr, storageAbi, signer)

        let erc20Abi = [
            "function approve(address _spender, uint256 _value) public returns (bool success)",
            "function decimals() public view returns (uint8)"
        ]
        let erc20Contract = new ethers.Contract(feeToken, erc20Abi, signer)

        const decimals = await erc20Contract.decimals()

        const approveTx = await erc20Contract.approve(storageManager, ethers.parseUnits(feeApproval.toString(), decimals))
        await approveTx.wait()
       
        const hashBytes32 = ethers.hexlify(hash)
        console.log(`hashBytes32 = ${hashBytes32}`)


        const numURI = await stor.getURIHashCount(uriCategoryToInt(rwaObject.category), uriTypeToInt(rwaObject.type))
        console.log(`Number of this URI Category/Type already created = ${numURI}`)

        const hashExists = await stor.existURIHash(hashBytes32)
        if(hashExists) {
            return({ok: false, msg: "The hash for this object already exists in the CTMRWA001 Storage Contract"})
        }

        const ctmStorageManager = new ethers.Contract(storageManager, storageManagerAbi, signer)

        console.log('Calling addURI now')
        console.log(`uriType = ${uriTypeToInt(rwaObject.type)}`)
        console.log(`uriCategory = ${uriCategoryToInt(rwaObject.category)}`)
        console.log(`slot = ${uriSlotToInt(rwaObject.slot)}`)
        console.log(`title = ${rwaObject.title}`)
        console.log(`hash length = ${hash.length}`)
        console.log(`chainIdsStr = ${chainIdsStr}`)
        console.log(`feeToken = ${feeToken}`)
        const tx = await ctmStorageManager.addURI(
            ID,
            uriCategoryToInt(rwaObject.category),
            uriTypeToInt(rwaObject.type),
            rwaObject.title,
            uriSlotToInt(rwaObject.slot),
            hashBytes32,
            chainIdsStr,
            feeToken
        )

        await tx.wait()
        console.log('Done')

        return {ok: true, msg: "Successful call of addURI"}
    } catch(err) {
        const errorMsg = err.message
        return {ok: false, msg: errorMsg}
    }
}

const getSingleObject = async(ID, objectName, chainIdStr, signer) => {

    let bucketName

    let headList
    let objInfoRoot
    let uriDataRes
    let objInfo
    let objectHash
    let checksumRes
    let storageHash
    let uriCategory
    let uriType
    let uriObjectName
    let uriTitle
    let slot
    let uriTimestamp
    let msg

    try {
        let bucketRes = await getBucketNameFromID(ID, chainIdStr, signer)
        if(!bucketRes.ok) {
            return {ok: false, msg: bucketRes.msg, objectList: null}
        } else {
            bucketName = bucketRes.bucketName
        }
        
        // console.log(`bucketName = ${bucketName}, objectName = ${objectName}`)
        headList = await client.object.headObject(bucketName, objectName)
        // console.log(headList.objectInfo)
        objInfoRoot = headList.objectInfo

        checksumRes = checksumFromBase64(objInfoRoot.checksums.map((x) => base64FromBytes(x)))

        uriDataRes = await getURIStorageData(ID, checksumRes.hash, chainIdStr, signer)

        storageHash = uriDataRes.uriData[5]
        objectHash = '0x' + checksumRes.hash.toString('hex')

        if (!uriDataRes.ok) {
            return {ok: false, msg: uriDataRes.msg, objectList: null}
        } else if (storageHash != objectHash) {
            // console.log('stor hash')
            // console.log(storageHash)
            // console.log('Obj hash')
            // console.log(objectHash)

            return {ok: false, msg: `Storage hash ${storageHash} does not match Object hash ${objectHash}`, objectList: null}
        }

        uriCategory = Number(uriDataRes.uriData[0])
        uriType = Number(uriDataRes.uriData[1])
        uriObjectName = uriDataRes.uriData[4]
        uriTitle = uriDataRes.uriData[2]
        slot = uriType == 0? slot = -1: slot = Number(uriDataRes.uriData[3])
        uriTimestamp = Number(uriDataRes.uriData[6])

        objInfo = {
            name: objInfoRoot.objectName,
            uriCategory: uriCategory,
            uriType: uriType,
            slot: slot,
            uriTitle: uriTitle,
            owner: objInfoRoot.owner,
            creator: objInfoRoot.creator,
            size: objInfoRoot.payloadSize.low,
            visibility: objInfoRoot.visibility,
            creationTime: objInfoRoot.createAt,
            uriTimestamp: uriTimestamp,
            checksums: objInfoRoot.checksums
        }

        if (uriObjectName.replaceAll('.', '-') == objectName) {
            return {ok: true, msg: "listObject successful", objectList: objInfo}
        } else {
            return {ok: false, msg: `Object name in contract ${uriObjectName} does not match objectName in Greenfield ${objectName}`, objectList: objInfo}
        }

    } catch(err) {
        if (err.message.includes("No such object")) {
            msg = `No such object ${objectName}`
        } else {
            msg = err.message
        }
        return {ok: false, msg: msg, objectList: null}
    }
}


const addObject = async (fileBuffer, bucketName, objectName, expectCheckSums, owner, signer) => {

    let createObjectTx

    try {
        createObjectTx = await client.object.createObject({
            bucketName: bucketName,
            objectName: objectName,
            creator: owner,
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
            msg = "Object not successfully created"
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


const getObject = async (ID, objectName, chainIdStr, signer) => {

    let fname
    let bucketRes
    let bucketName
   

    try {
        bucketRes = await getBucketNameFromID(ID, chainIdStr, signer)
        if(!bucketRes.ok) {
            return {ok: false, msg: bucketRes.msg, filename: null}
        } else {
            bucketName = bucketRes.bucketName
        }

        fname = bucketName + '-' + objectName + '.json'


        const getObjectResult = await client.object.getObject(
            {
                bucketName: bucketName,
                objectName: objectName,
            },
            {
                type: 'ECDSA',
                privateKey: PRIVATE_KEY,
            }
        )

        // console.log('getObjectResult', getObjectResult)
        if(getObjectResult.code != 0) {
            throw new Error(`${getObjectResult.message}, statusCode: ${getObjectResult.statusCode}`)
        }

        const blob = getObjectResult.body
        const buffer = Buffer.from(await blob.arrayBuffer())

        // fs.writeFileSync(fname, buffer)

        let rwaObject = JSON.parse(buffer.toString())

        return {ok: true, msg: "Object successfully retrieved", filename: fname, rwaObject: rwaObject}
    } catch(err) {
        return {ok: false, msg: err.message, filename: null, rwaObject: null}
    }

}

const getObjectList = async(ID, chainIdStr, signer) => {
    
    try {

        let bucketName
        let bucketRes = await getBucketNameFromID(ID, chainIdStr, signer)
        if(!bucketRes.ok) {
            return {ok: false, msg: bucketRes.msg, objectList: null}
        } else {
            bucketName = bucketRes.bucketName
        }

        let res
        let spRes
        let sp

       
        sp = await selectSp()

        res = await client.object.listObjects({
            bucketName: bucketName,
            endpoint: sp.endpoint,
        })

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

                uriDataRes = await getURIStorageData(ID, checksumRes.hash, chainIdStr, signer)

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
    } catch(err) {
        return {ok: false, msg: err, objectList: null}
    }
}

const deleteObject = async (bucketName, objectName, signer) => {
    const tx = await client.object.deleteObject({
        bucketName: bucketName,
        objectName: objectName,
        operator: signer.address,
      })
    
      const simulateTx = await tx.simulate({
        denom: 'BNB',
      })
    
      const createObjectTxRes = await tx.broadcast({
        denom: 'BNB',
        gasLimit: Number(simulateTx?.gasLimit),
        gasPrice: simulateTx?.gasPrice || '5000000000',
        payer: signer.address,
        granter: '',
        privateKey: PRIVATE_KEY,
      })
    
      if (createObjectTxRes.code === 0) {
        console.log('delete object success')
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


module.exports = {
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
    downloadFile,
    createStorageObject,
    getObject,

}