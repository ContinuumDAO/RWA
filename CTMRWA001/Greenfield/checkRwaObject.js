

const checkRwaObject = (rwaObject, size) => {
    let rwaCategory = rwaObject.category
    let rwaType = rwaObject.type
    let sizeLimit

    try {

        console.log('size = ', size)
        sizeLimit = categorySizeLimit(rwaCategory)

        if (rwaCategory == "ISSUER") {
            if (size > categorySizeLimit(rwaCategory)) {
                throw new Error(`Size for RWA Category ${rwaCategory}, ${sizeLimit} bytes exceeded`)
            }
        } else if (rwaCategory == "NOTICE") {

        } else if (rwaCategory == "PROVENANCE") {
            
        } else if (rwaCategory == "VALUATION") {
            
        } else if (rwaCategory == "RATING") {
            
        } else if (rwaCategory == "LEGAL") {
            
        } else if (rwaCategory == "FINANCIAL") {
            
        } else if (rwaCategory == "PROSPECTUS") {
            
        } else if (rwaCategory == "LICENSE") {
            
        } else if (rwaCategory == "DUEDILIGENCE") {
            
        } else if (rwaCategory == "DIVIDEND") {
            
        } else if (rwaCategory == "REDEMPTION") {
            
        } else if (rwaCategory == "WHOCANINVEST") {
            
        } else if (rwaCategory == "IMAGE") {
            if (size > categorySizeLimit(rwaCategory)) {
                throw new Error(`Size for RWA Category ${rwaCategory}, ${sizeLimit} bytes exceeded`)
            }

            imageType = rwaObject.properties.image_type

            if (!imageType.includes("image/")) {
                throw new Error(`RWA image type ${imageType} is not compatible with an RWA IMAGE Category`)
            }
        } else if (rwaCategory == "VIDEO") {
            if (size > categorySizeLimit(rwaCategory)) {
                throw new Error(`Size for RWA Category ${rwaCategory}, ${sizeLimit} bytes exceeded`)
            }

            videoType = rwaObject.properties.image_type

            if (!imageType.includes("video/")) {
                throw new Error(`RWA image type ${videoType} is not compatible with an RWA VIDEO Category`)
            }
        } else {
            throw new Error("RWA Category was not found in this object")
        }

        return {ok: true, msg: "Successfully passed checkRwaObject"}

    } catch(err) {
        return {ok: false, msg: err.message}
    }
}

const categorySizeLimit = (rwaCategory) => {
    if (rwaCategory == "ISSUER") {
        return 100_000
    } else if (rwaCategory == "NOTICE") {
        return 500_000
    } else if (rwaCategory == "PROVENANCE") {
        return 500_000
    } else if (rwaCategory == "VALUATION") {
        return 500_000
    } else if (rwaCategory == "RATING") {
        return 200_000
    } else if (rwaCategory == "LEGAL") {
        return 500_000
    } else if (rwaCategory == "FINANCIAL") {
        return 500_000
    } else if (rwaCategory == "PROSPECTUS") {
        return 1_000_000
    } else if (rwaCategory == "LICENSE") {
        return 500_000
    } else if (rwaCategory == "DUEDILIGENCE") {
        return 500_000
    } else if (rwaCategory == "DIVIDEND") {
        return 200_000
    } else if (rwaCategory == "REDEMPTION") {
        return 200_000
    } else if (rwaCategory == "WHOCANINVEST") {
        return 200_000
    } else if (rwaCategory == "IMAGE") {
        return 2_000_000
    } else if (rwaCategory == "VIDEO") {
        return 50_000_000_000
    } else {
        throw new Error("RWA Category was not found in this object")
    }
}

module.exports = {
    checkRwaObject,
    categorySizeLimit
}