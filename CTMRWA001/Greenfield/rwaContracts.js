
const getRwaContracts = (chainIdStr) => {
    let rpcUrl
    let ctmRwaMap
    let storageManager
    let feeToken

    if(chainIdStr == "421614") { // ARB Sepolia
        rpcUrl = "https://sepolia-rollup.arbitrum.io/rpc"
        ctmRwaMap = "0xcC9AC238318d5dBe97b20957c09aC09bA73Eeb25"
        storageManager = "0x111c9778C10998716392d181B3A4cF6b489bA221"
        feeToken = "0xbF5356AdE7e5F775659F301b07c4Bc6961044b11"

        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    } else if (chainIdStr == "84532") { // BASE SEPOLIA Chain 84532

        rpcUrl = "https://base-sepolia-rpc.publicnode.com"
        ctmRwaMap = "0xCf46f23D86a672AF5614FBa6A7505031805EF5e2"
        storageManager = "0x6B8652F1Ee17172593E05c9F410EB9B03b49f092"
        feeToken = "0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae"
        
        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    } else if (chainIdStr == "80002") {  // POLYGON AMOY Chain 80002

        rpcUrl = "https://rpc.ankr.com/polygon_amoy"
        ctmRwaMap = "0x18433A774aF5d473191903A5AF156f3Eb205bBA4"
        storageManager = "0x813F3770a82Cf5a368Ef50bffF3b619c446ef938"
        feeToken = "0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae"
        
        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    } else if (chainIdStr == "11155111") {  // ETHEREUM SEPOLIA  Chain 11155111

        rpcUrl = "https://ethereum-sepolia-rpc.publicnode.com"
        ctmRwaMap = "0xd546A3a98D86d22e28d688FAf3a074D000F2612B"
        storageManager = "0x1392fC45312550197adF2039de80e8DA58fc72A3"
        feeToken = "0xa4C104db0937F1E886d5C9c9789D6f0e5bfBA75c"
        
        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    } else if (chainIdStr == "97") {  // BSC TESTNET  Chain 97

        rpcUrl = "https://data-seed-prebsc-1-s1.binance.org:8545/"
        ctmRwaMap = "0x5F0C4a82BDE669347Add86CD13587ba40d29dAd6"
        storageManager = "0xdC3AE5Dd494535abcAd60195982345DB54657021"
        feeToken = "0xDd43fc986a13392dDbC7aeA150b41EfE27b2d0eD"
        
        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    } else if (chainIdStr == "200810") {  // BITLAYER TESTNET Chain 200810

        rpcUrl = "https://testnet-rpc.bitlayer.org"
        ctmRwaMap = "0x1e608FD1546e1bC1382Abc4E676CeFB7e314Fb30"
        storageManager = "0x9E2F5D1228b02C2FbF3168Db1162e7461574eBB9"
        feeToken = "0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae"
        
        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    } else if (chainIdStr == "1952959480") {  // LUMIA TESTNET Chain 1952959480

        rpcUrl = "https://testnet-rpc.lumia.org"
        ctmRwaMap = "0xc04058E417De221448D4140FC1622dE24121C5e3"
        storageManager = "0xa3D476BB425aD923483c5f699fAB17dbEb4473Be"
        feeToken = "0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae"
        
        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    } else if (chainIdStr == "5611") { // OPBNB TESTNET  Chain 5611

        rpcUrl = "https://opbnb-testnet-rpc.publicnode.com"
        ctmRwaMap = "0xfC2175A02c2e1e673F1Ba374A321d274Bb29bD68"
        storageManager = "0x93aE0e18578828631489c6CB8f8045eBe8D4599f"
        feeToken = "0x108642B1b2390AC3f54E3B45369B7c660aeFffAD"
        
        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    } else if (chainIdStr == "1115") {  // CORE Testnet Chain 1115

        rpcUrl = "https://rpc.test.btcs.network/"
        ctmRwaMap = "0x89330bE16C672D4378B6731a8347D23B0c611de3"
        storageManager = "0xeeEF6a3EaBe62DF296d2711254ed0a0AB2920cA6"
        feeToken = "0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae"
        
        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    } else if (chainIdStr == "1946") {  // SONEIUM MINATO Chain 1946

        rpcUrl = "https://rpc.minato.soneium.org/"
        ctmRwaMap = "0xa568D1Ed42CBE94E72b0ED736588200536917E0c"
        storageManager = "0xfdD1a5B3AEEa2DF15a6F6B502784B61BdCbF66BC"
        feeToken = "0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae"
        
        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    } else if (chainIdStr == "2810") {  // MORPH HOLESKY  Chain 2810

        rpcUrl = "https://rpc-holesky.morphl2.io"
        ctmRwaMap = "0x48F214fDA66380A454DADAd9F84eF9D11d1f1D39"
        storageManager = "0xA31AC55003cde3eF9CE9c576a691d0F41586c20b"
        feeToken = "0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae"
        
        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    } else if (chainIdStr == "534351") {  // SCROLL SEPOLIA   Chain 534351

        rpcUrl = "https://sepolia-rpc.scroll.io"
        ctmRwaMap = "0x48F214fDA66380A454DADAd9F84eF9D11d1f1D39"
        storageManager = "0xA31AC55003cde3eF9CE9c576a691d0F41586c20b"
        feeToken = "0xe536Bf33585aa6bb528627Ed7Dc4D49009dafC58"
        
        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    } else if (chainIdStr == "17000") {  // HOLESKY Chain 17000

        rpcUrl = "https://ethereum-holesky-rpc.publicnode.com"
        ctmRwaMap = "0xAF685f104E7428311F25526180cbd416Fa8668CD"
        storageManager = "0xe0F2017BC8206Ffc8D563a6c0C9Fb52c0189a5a6"
        feeToken = "0x108642B1b2390AC3f54E3B45369B7c660aeFffAD"
        
        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    } else if (chainIdStr == "5003") {  // MANTLE SEPOLIA Chain 5003

        rpcUrl = "https://rpc.sepolia.mantle.xyz"
        ctmRwaMap = "0xfC2175A02c2e1e673F1Ba374A321d274Bb29bD68"
        storageManager = "0xa6f306DEf6A39D08B0996E053458c632f9F55993"
        feeToken = "0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae"
        
        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    } else if (chainIdStr == "4201") {  // LUKSO TESTNET  Chain 4201

        rpcUrl = "https://rpc.testnet.lukso.network/"
        ctmRwaMap = "0x1eE4bA474da815f728dF08F0147DeFac07F0BAb3"
        storageManager = "0x45cddE4bdAbC97b3ec02B1271432ceeBc04d4c53"
        feeToken = "0xC92291fbBe0711b6B34928cB1b09aba1f737DEfd"
        
        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    }  else if (chainIdStr == "168587773") {  // BLAST SEPOLIA Chain 168587773

        rpcUrl = "https://sepolia.blast.io"
        ctmRwaMap = "0xa3325B2fA099c81a06d9b7532317d4a4Da7F2aB7"
        storageManager = "0xA450Ae39bf325c23a45B126eD2735F02d36b9A2d"
        feeToken = "0x5d5408e949594E535d0c3d533761Cb044E11b664"
        
        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    }  else if (chainIdStr == "153") {  // REDBELLY TESTNET Chain 153

        rpcUrl = "https://governors.testnet.redbelly.network"
        ctmRwaMap = "0xf7Ed4f388e07Ab2B9138D1f7CF2F0Cf6B23820aF"
        storageManager = "0x37415B746B2eF7f37608006dDaA404d377fdF633"
        feeToken = "0xe536Bf33585aa6bb528627Ed7Dc4D49009dafC58"
        
        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    }  else if (chainIdStr == "11155420") {  // OPTIMISM SEPOLIA Chain 11155420

        rpcUrl = "https://rpc.ankr.com/optimism_sepolia"
        ctmRwaMap = "0xc8464ec2c98d3a0883E6bB64F08195AEFA807279"
        storageManager = "0xf9EDcE2638da660F51Ee08220a1a5A32fAB61d61"
        feeToken = "0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae"
        
        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    } else if (chainIdStr == "59141") {  // LINEA SEPOLIA Chain 59141

        rpcUrl = "https://linea-sepolia-rpc.publicnode.com"
        ctmRwaMap = "0xe5AF1a54B2b8cA3091edD229329B60A82b7A04E8"
        storageManager = "0x9A0F81de582Ce9194FEADC6CCefaf9eA70451616"
        feeToken = "0x6654D956A4487A26dF1186b01B689c26939544fC"
        
        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    } else if (chainIdStr == "78600") {  // VANGUARD Chain 78600

        rpcUrl = "https://rpc-vanguard.vanarchain.com"
        ctmRwaMap = "0x779f7FfdD1157935E1cD6344A6D7a9047736EBc1"
        storageManager = "0xF3065b38973C66a425FE7f7Ed911962CEF3a7dC1"
        feeToken = "0x6654D956A4487A26dF1186b01B689c26939544fC"
        
        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    }  else if (chainIdStr == "2484") {  // U2U NEBULAS TESTNET Chain 2484

        rpcUrl = "https://rpc-nebulas-testnet.uniultra.xyz"
        ctmRwaMap = "0xEd3c7279F4175F88Ab6bBcd16c8B8214387725e7"
        storageManager = "0xB44b8B43B9BD6Ae184220800703Ce7D630423e8b"
        feeToken = "0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae"
        
        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    }   else if (chainIdStr == "1952959480") {  // LUMIA TESTNET Chain 1952959480

        rpcUrl = "https://testnet-rpc.lumia.org"
        ctmRwaMap = "0xc04058E417De221448D4140FC1622dE24121C5e3"
        storageManager = "0xa3D476BB425aD923483c5f699fAB17dbEb4473Be"
        feeToken = "0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae"
        
        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    } else {
        return {ok: false, rpcUrl: null, ctmRwaMap: null, storageManager: null, feeToken: null}
    }
}

module.exports = {
    getRwaContracts
}