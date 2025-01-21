

const getRwaContracts = (chainIdStr) => {
    let rpcUrl
    let ctmRwaMap
    let storageManager
    let feeToken

    if(chainIdStr == "421614") { // ARB Sepolia
        rpcUrl = "https://sepolia-rollup.arbitrum.io/rpc"
        ctmRwaMap = "0x1113E64C90dab3d1c2Da5850e3eEE672D33CE1f3"
        storageManager = "0x769139881024cE730dE9de9c21E3ad6fb5a872f2"
        feeToken = "0xbF5356AdE7e5F775659F301b07c4Bc6961044b11"

        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    } else {
        return {ok: false, rpcUrl: null, ctmRwaMap: null, storageManager: null, feeToken: null}
    }
}

module.exports = {
    getRwaContracts
}