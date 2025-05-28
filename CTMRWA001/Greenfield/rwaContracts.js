
const getRwaContracts = (chainIdStr) => {
    let rpcUrl
    let ctmRwaMap
    let storageManager
    let feeToken

    if(chainIdStr == "421614") { // ARB Sepolia
        rpcUrl = "https://sepolia-rollup.arbitrum.io/rpc"
        ctmRwaMap = "0x4f390Eaa4Ddb82fc37053b8E8dbc3367594577E4"
        storageManager = "0x7aB4De775c88e4aA4c93d0078d8318463fABfb13"
        feeToken = "0xbF5356AdE7e5F775659F301b07c4Bc6961044b11"

        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    } else if (chainIdStr == "84532") { // BASE SEPOLIA Chain 84532

        rpcUrl = "https://base-sepolia-rpc.publicnode.com"
        ctmRwaMap = "0x416D3bE80a79E4F082C92f7fB17b1C13fD91B055"
        storageManager = "0x7e0858dE387f30Ebc0bC2F24A35dc4ad9231Cffd"
        feeToken = "0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae"
        
        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    } else if (chainIdStr == "80002") {  // POLYGON AMOY Chain 80002

        rpcUrl = "https://rpc-amoy.polygon.technology"
        ctmRwaMap = "0x9A48630090429E3039A5E1CDb4cf0433D54a1AEe"
        storageManager = "0xB3D138F0613CC476faA8c5E2C1a64e90D9d506F3"
        feeToken = "0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae"
        
        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    } else if (chainIdStr == "11155111") {  // ETHEREUM SEPOLIA  Chain 11155111

        rpcUrl = "https://ethereum-sepolia-rpc.publicnode.com"
        ctmRwaMap = "0x4f102432739a2DE082B7977316796A05C99147fb"
        storageManager = "0x6681DB630eB117050D78E0B89eB5619b35Ea12e8"
        feeToken = "0xa4C104db0937F1E886d5C9c9789D6f0e5bfBA75c"
        
        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    } else if (chainIdStr == "97") {  // BSC TESTNET  Chain 97

        rpcUrl = "https://data-seed-prebsc-1-s1.binance.org:8545/"
        ctmRwaMap = "0x15702A75071c424BbdC6F69aFeB6F919593B389E"
        storageManager = "0x71645806ee984439ADC3352ABB5491Ec03928e63"
        feeToken = "0xDd43fc986a13392dDbC7aeA150b41EfE27b2d0eD"
        
        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    // } else if (chainIdStr == "200810") {  // BITLAYER TESTNET Chain 200810

    //     rpcUrl = "https://testnet-rpc.bitlayer.org"
    //     ctmRwaMap = ""
    //     storageManager = ""
    //     feeToken = "0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae"
        
    //     return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    } else if (chainIdStr == "1952959480") {  // LUMIA TESTNET Chain 1952959480

        rpcUrl = "https://testnet-rpc.lumia.org"
        ctmRwaMap = "0x698509EBaefBFA03C2c32162155CEcdDFC7C728C"
        storageManager = "0xE3A405Aa844DA4b6E83eAe852bA471219163CBe0"
        feeToken = "0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae"
        
        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    } else if (chainIdStr == "5611") { // OPBNB TESTNET  Chain 5611

        rpcUrl = "https://opbnb-testnet-rpc.publicnode.com"
        ctmRwaMap = "0xF813DdCDd690aCB06ddbFeb395Cf65D18Efe74A7"
        storageManager = "0x926DF1f820Af8E3cF53A58C94332eB16BA4cB4b5"
        feeToken = "0x108642B1b2390AC3f54E3B45369B7c660aeFffAD"
        
        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    // } else if (chainIdStr == "1115") {  // CORE Testnet Chain 1115

    //     rpcUrl = "https://rpc.test.btcs.network/"
    //     ctmRwaMap = ""
    //     storageManager = ""
    //     feeToken = "0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae"
        
    //     return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    } else if (chainIdStr == "1946") {  // SONEIUM MINATO Chain 1946

        rpcUrl = "https://rpc.minato.soneium.org/"
        ctmRwaMap = "0x1249d751e6a0b7b11b9e55CBF8bC7d397AC3c083"
        storageManager = "0x3f547B04f8CF9552434B7f3a51Fc23247911b797"
        feeToken = "0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae"
        
        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    // } else if (chainIdStr == "2810") {  // MORPH HOLESKY  Chain 2810

    //     rpcUrl = "https://rpc-holesky.morphl2.io"
    //     ctmRwaMap = ""
    //     storageManager = ""
    //     feeToken = "0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae"
        
    //     return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    } else if (chainIdStr == "534351") {  // SCROLL SEPOLIA   Chain 534351

        rpcUrl = "https://sepolia-rpc.scroll.io"
        ctmRwaMap = "0x21640b51400Da2B679916b8619c38b3Cc03692fe"
        storageManager = "0xb406b937C12E03d676727Fc1Bb686279EeDbc178"
        feeToken = "0xe536Bf33585aa6bb528627Ed7Dc4D49009dafC58"
        
        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    } else if (chainIdStr == "17000") {  // HOLESKY Chain 17000

        rpcUrl = "https://ethereum-holesky-rpc.publicnode.com"
        ctmRwaMap = "0x0156a74FD9432446030f47f7c55f4d1FbfdF5E9a"
        storageManager = "0xe148fbc6C35B6cecC50d18Ebf69959a6A989cB7C"
        feeToken = "0x108642B1b2390AC3f54E3B45369B7c660aeFffAD"
        
        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    } else if (chainIdStr == "5003") {  // MANTLE SEPOLIA Chain 5003

        rpcUrl = "https://rpc.sepolia.mantle.xyz"
        ctmRwaMap = "0x2a592B15dd480F7E861198002ed68F8E5927ee80"
        storageManager = "0xf3F62dAF8f096e5e1e8626cF2F35d816d454bC93"
        feeToken = "0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae"
        
        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    // } else if (chainIdStr == "4201") {  // LUKSO TESTNET  Chain 4201

    //     rpcUrl = "https://rpc.testnet.lukso.network/"
    //     ctmRwaMap = ""
    //     storageManager = ""
    //     feeToken = "0xC92291fbBe0711b6B34928cB1b09aba1f737DEfd"
        
    //     return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    }  else if (chainIdStr == "168587773") {  // BLAST SEPOLIA Chain 168587773

        rpcUrl = "https://rpc.ankr.com/blast_testnet_sepolia"
        ctmRwaMap = "0xcFF54249Dae66746377e15C07D95c42188D5d3A8"
        storageManager = "0x8D4EEe23A687b304E94eee3211f3058A60744502"
        feeToken = "0x5d5408e949594E535d0c3d533761Cb044E11b664"
        
        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    }  else if (chainIdStr == "153") {  // REDBELLY TESTNET Chain 153

        rpcUrl = "https://governors.testnet.redbelly.network"
        ctmRwaMap = "0xAd8E9e0Cc6FB6680E3e4fE2b6c3E8E84911e9637"
        storageManager = "0x35f5B7A7469c7B3e3Bb159335eC92Ce74f7F11CD"
        feeToken = "0xe536Bf33585aa6bb528627Ed7Dc4D49009dafC58"
        
        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    }  else if (chainIdStr == "11155420") {  // OPTIMISM SEPOLIA Chain 11155420

        rpcUrl = "https://rpc.ankr.com/optimism_sepolia"
        ctmRwaMap = "0xe73c59e27Ea9e702FAdfC804c33EFEFB3D5D6C26"
        storageManager = "0x6429D598684EfBe5a5fF70451e7B2C501c85e254"
        feeToken = "0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae"
        
        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    // } else if (chainIdStr == "59141") {  // LINEA SEPOLIA Chain 59141

    //     rpcUrl = "https://linea-sepolia-rpc.publicnode.com"
    //     ctmRwaMap = ""
    //     storageManager = ""
    //     feeToken = "0x6654D956A4487A26dF1186b01B689c26939544fC"
        
    //     return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    // } else if (chainIdStr == "78600") {  // VANGUARD Chain 78600

    //     rpcUrl = "https://rpc-vanguard.vanarchain.com"
    //     ctmRwaMap = ""
    //     storageManager = ""
    //     feeToken = "0x6654D956A4487A26dF1186b01B689c26939544fC"
        
    //     return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    // }  else if (chainIdStr == "2484") {  // U2U NEBULAS TESTNET Chain 2484

    //     rpcUrl = "https://rpc-nebulas-testnet.uniultra.xyz"
    //     ctmRwaMap = ""
    //     storageManager = ""
    //     feeToken = "0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae"
        
    //     return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    } else if (chainIdStr == "43113") {  // AVALANCHE FUJI Chain 431130

        rpcUrl = "https://api.avax-test.network/ext/bc/C/rpc"
        ctmRwaMap = "0xD2cd1c42e56Ca30588de604E724C0031b2139053"
        storageManager = "0xAE66C08b9d76EeCaA74314c60f3305D43707ACc9"
        feeToken = "0x15A1ED0815ECeD97E46967179846c72BA21DABAd"
        
        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    // } else if (chainIdStr == "3441006") {  // MANTA PACIFIC Chain 3441006

    //     rpcUrl = "https://pacific-rpc.sepolia-testnet.manta.network/http"
    //     ctmRwaMap = ""
    //     storageManager = ""
    //     feeToken = "0x20cEfCf72622156987f82E1B54E94Dbc0848De9C"
        
    //     return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    }else {
        return {ok: false, rpcUrl: null, ctmRwaMap: null, storageManager: null, feeToken: null}
    }
}

module.exports = {
    getRwaContracts
}