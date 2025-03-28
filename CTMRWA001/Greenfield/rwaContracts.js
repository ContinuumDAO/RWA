
const getRwaContracts = (chainIdStr) => {
    let rpcUrl
    let ctmRwaMap
    let storageManager
    let feeToken

    if(chainIdStr == "421614") { // ARB Sepolia
        rpcUrl = "https://sepolia-rollup.arbitrum.io/rpc"
        ctmRwaMap = "0x47D91341Ba367BCe483d0Ee2fE02DD1420b883EC"
        storageManager = "0x3804bD72656E086166f2d64E7C78f2F9CD2735b8"
        feeToken = "0xbF5356AdE7e5F775659F301b07c4Bc6961044b11"

        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    } else if (chainIdStr == "84532") { // BASE SEPOLIA Chain 84532

        rpcUrl = "https://base-sepolia-rpc.publicnode.com"
        ctmRwaMap = "0xC5A13F8750f362AA8e8Ace59f261268295923190"
        storageManager = "0x1481875CA0EcD0ACdEb79d3d57FB76EAE726d128"
        feeToken = "0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae"
        
        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    } else if (chainIdStr == "80002") {  // POLYGON AMOY Chain 80002

        rpcUrl = "https://rpc.ankr.com/polygon_amoy"
        ctmRwaMap = "0xf9229aCEba228fdbb757A637EeeBadB46FDb617e"
        storageManager = "0xE5b921BD326efa802e3dc20Fb3502559f59fd8AA"
        feeToken = "0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae"
        
        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    } else if (chainIdStr == "11155111") {  // ETHEREUM SEPOLIA  Chain 11155111

        rpcUrl = "https://ethereum-sepolia-rpc.publicnode.com"
        ctmRwaMap = "0x8Ed2Dc74260aA279fcB5438932B5B367F221e7db"
        storageManager = "0xDC44569f688a91ba3517C292de75E30EA284eeA0"
        feeToken = "0xa4C104db0937F1E886d5C9c9789D6f0e5bfBA75c"
        
        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    } else if (chainIdStr == "97") {  // BSC TESTNET  Chain 97

        rpcUrl = "https://data-seed-prebsc-1-s1.binance.org:8545/"
        ctmRwaMap = "0xC886FFa78114cf7e701Fd33505b270505B3FeAE3"
        storageManager = "0x188af80a2ea153bc43dD448434d753C05D3C93f3"
        feeToken = "0xDd43fc986a13392dDbC7aeA150b41EfE27b2d0eD"
        
        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    } else if (chainIdStr == "200810") {  // BITLAYER TESTNET Chain 200810

        rpcUrl = "https://testnet-rpc.bitlayer.org"
        ctmRwaMap = "0x766061Cd28592Fd2503cAA3E4772C1215192cD3d"
        storageManager = "0xC5E7f5e1BABBF45e3F1e0764B48736C19A122383"
        feeToken = "0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae"
        
        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    } else if (chainIdStr == "1952959480") {  // LUMIA TESTNET Chain 1952959480

        rpcUrl = "https://testnet-rpc.lumia.org"
        ctmRwaMap = ""
        storageManager = ""
        feeToken = "0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae"
        
        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    } else if (chainIdStr == "5611") { // OPBNB TESTNET  Chain 5611

        rpcUrl = "https://opbnb-testnet-rpc.publicnode.com"
        ctmRwaMap = "0xa3bae05aA45bcC739258b124FACE332043D3B1dA"
        storageManager = "0xd13779b354c3C72c9B438ABe7Db3086098778A7a"
        feeToken = "0x108642B1b2390AC3f54E3B45369B7c660aeFffAD"
        
        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    } else if (chainIdStr == "1115") {  // CORE Testnet Chain 1115

        rpcUrl = "https://rpc.test.btcs.network/"
        ctmRwaMap = "0xa3bae05aA45bcC739258b124FACE332043D3B1dA"
        storageManager = "0xd13779b354c3C72c9B438ABe7Db3086098778A7a"
        feeToken = "0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae"
        
        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    } else if (chainIdStr == "1946") {  // SONEIUM MINATO Chain 1946

        rpcUrl = "https://rpc.minato.soneium.org/"
        ctmRwaMap = "0x0f78335bD79BDF6C8cbE6f4F565Ca715a44Aed54"
        storageManager = "0x80f1BB2DF520e3e091C79AebE81f46136A8fBCb5"
        feeToken = "0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae"
        
        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    } else if (chainIdStr == "2810") {  // MORPH HOLESKY  Chain 2810

        rpcUrl = "https://rpc-holesky.morphl2.io"
        ctmRwaMap = "0x3dc0e90bB56DE095321c48aadF0D0c29b47b837a"
        storageManager = "0x6F0DDf81d8145301058e37CC51A485Ae6b44BCF9"
        feeToken = "0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae"
        
        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    } else if (chainIdStr == "534351") {  // SCROLL SEPOLIA   Chain 534351

        rpcUrl = "https://sepolia-rpc.scroll.io"
        ctmRwaMap = "0x80f1BB2DF520e3e091C79AebE81f46136A8fBCb5"
        storageManager = "0x0A0C882706544F37377e9bb7976E0805cd29a94F"
        feeToken = "0xe536Bf33585aa6bb528627Ed7Dc4D49009dafC58"
        
        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    } else if (chainIdStr == "17000") {  // HOLESKY Chain 17000

        rpcUrl = "https://ethereum-holesky-rpc.publicnode.com"
        ctmRwaMap = "0xA33cfD901896C775c5a6d62e94081b4Fdd1B09BC"
        storageManager = "0xe5AF1a54B2b8cA3091edD229329B60A82b7A04E8"
        feeToken = "0x108642B1b2390AC3f54E3B45369B7c660aeFffAD"
        
        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    } else if (chainIdStr == "5003") {  // MANTLE SEPOLIA Chain 5003

        rpcUrl = "https://rpc.sepolia.mantle.xyz"
        ctmRwaMap = "0x41388451eca7344136004D29a813dCEe49577B44"
        storageManager = "0xA365a4Ea68929C6297ef32Da2c21BDBfd1d354f0"
        feeToken = "0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae"
        
        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    } else if (chainIdStr == "4201") {  // LUKSO TESTNET  Chain 4201

        rpcUrl = "https://rpc.testnet.lukso.network/"
        ctmRwaMap = ""
        storageManager = ""
        feeToken = "0xC92291fbBe0711b6B34928cB1b09aba1f737DEfd"
        
        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    }  else if (chainIdStr == "168587773") {  // BLAST SEPOLIA Chain 168587773

        rpcUrl = "https://sepolia.blast.io"
        ctmRwaMap = "0xD55F76833388137FB1ECFc0dE1e6982716A19640"
        storageManager = "0x3dc0e90bB56DE095321c48aadF0D0c29b47b837a"
        feeToken = "0x5d5408e949594E535d0c3d533761Cb044E11b664"
        
        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    }  else if (chainIdStr == "153") {  // REDBELLY TESTNET Chain 153

        rpcUrl = "https://governors.testnet.redbelly.network"
        ctmRwaMap = "0xdC910F7BCc6f163DFA4804eACa10891eb5B9E867"
        storageManager = "0x52661DbA4F88FeD997164ff2C453A2339216592C"
        feeToken = "0xe536Bf33585aa6bb528627Ed7Dc4D49009dafC58"
        
        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    }  else if (chainIdStr == "11155420") {  // OPTIMISM SEPOLIA Chain 11155420

        rpcUrl = "https://rpc.ankr.com/optimism_sepolia"
        ctmRwaMap = "0x64C5734e22cf8126c6367c0230B66788fBE4AB90"
        storageManager = "0xc3dC6a3EdC40460BAa684F45E9e377B7e42009b1"
        feeToken = "0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae"
        
        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    } else if (chainIdStr == "59141") {  // LINEA SEPOLIA Chain 59141

        rpcUrl = "https://linea-sepolia-rpc.publicnode.com"
        ctmRwaMap = "0x3144e9ff0C0F7b2414Ec0684665451f0487293FA"
        storageManager = "0x73B4143b7cd9617F9f29452f268479Bd513e3d23"
        feeToken = "0x6654D956A4487A26dF1186b01B689c26939544fC"
        
        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    } else if (chainIdStr == "78600") {  // VANGUARD Chain 78600

        rpcUrl = "https://rpc-vanguard.vanarchain.com"
        ctmRwaMap = "0xCBf4E5FDA887e602E5132FA800d74154DFb5B237"
        storageManager = "0x89c8CC177f04CC8209B93e42d81a780c3A685dD4"
        feeToken = "0x6654D956A4487A26dF1186b01B689c26939544fC"
        
        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    }  else if (chainIdStr == "2484") {  // U2U NEBULAS TESTNET Chain 2484

        rpcUrl = "https://rpc-nebulas-testnet.uniultra.xyz"
        ctmRwaMap = "0xEcabB66a84340E7E6D020EAD0dAb1364767f3f70"
        storageManager = "0xA33cfD901896C775c5a6d62e94081b4Fdd1B09BC"
        feeToken = "0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae"
        
        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    } else if (chainIdStr == "43113") {  // AVALANCHE FUJI Chain 431130

        rpcUrl = "https://api.avax-test.network/ext/bc/C/rpc"
        ctmRwaMap = "0x92BB6DEfEF73fa2ee42FeC2273d98693571bd7f3"
        storageManager = "0xcAcF2003d4bC2e19C865e65Ebb9D57C440217f0F"
        feeToken = "0x15A1ED0815ECeD97E46967179846c72BA21DABAd"
        
        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    } else if (chainIdStr == "3441006") {  // MANTA PACIFIC Chain 3441006

        rpcUrl = "https://pacific-rpc.sepolia-testnet.manta.network/http"
        ctmRwaMap = "0x92BB6DEfEF73fa2ee42FeC2273d98693571bd7f3"
        storageManager = "0xcAcF2003d4bC2e19C865e65Ebb9D57C440217f0F"
        feeToken = "0x20cEfCf72622156987f82E1B54E94Dbc0848De9C"
        
        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    }else {
        return {ok: false, rpcUrl: null, ctmRwaMap: null, storageManager: null, feeToken: null}
    }
}

module.exports = {
    getRwaContracts
}