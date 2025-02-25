
const getRwaContracts = (chainIdStr) => {
    let rpcUrl
    let ctmRwaMap
    let storageManager
    let feeToken

    if(chainIdStr == "421614") { // ARB Sepolia
        rpcUrl = "https://sepolia-rollup.arbitrum.io/rpc"
        ctmRwaMap = "0xcC9AC238318d5dBe97b20957c09aC09bA73Eeb25"
        storageManager = "0xfefE834c4b32BF5DA89f7F0C059590719Fe3e3eE"
        feeToken = "0xbF5356AdE7e5F775659F301b07c4Bc6961044b11"

        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    } else if (chainIdStr == "84532") { // BASE SEPOLIA Chain 84532

        rpcUrl = "https://base-sepolia-rpc.publicnode.com"
        ctmRwaMap = "0xCf46f23D86a672AF5614FBa6A7505031805EF5e2"
        storageManager = "0x3188f25255C22Ba3cb0339A259cDca9cB963F135"
        feeToken = "0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae"
        
        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    } else if (chainIdStr == "80002") {  // POLYGON AMOY Chain 80002

        rpcUrl = "https://rpc.ankr.com/polygon_amoy"
        ctmRwaMap = "0x18433A774aF5d473191903A5AF156f3Eb205bBA4"
        storageManager = "0xA09E913fa1aA5383a90aD6d8B94BC3DaBeE90332"
        feeToken = "0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae"
        
        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    } else if (chainIdStr == "11155111") {  // ETHEREUM SEPOLIA  Chain 11155111

        rpcUrl = "https://ethereum-sepolia-rpc.publicnode.com"
        ctmRwaMap = "0xd546A3a98D86d22e28d688FAf3a074D000F2612B"
        storageManager = "0x3C63f6f855b761793366336A0941cB9d8B21f79a"
        feeToken = "0xa4C104db0937F1E886d5C9c9789D6f0e5bfBA75c"
        
        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    } else if (chainIdStr == "97") {  // BSC TESTNET  Chain 97

        rpcUrl = "https://data-seed-prebsc-1-s1.binance.org:8545/"
        ctmRwaMap = "0x5F0C4a82BDE669347Add86CD13587ba40d29dAd6"
        storageManager = "0x66dB3f564807fdc689eC85285981eF464daeB943"
        feeToken = "0xDd43fc986a13392dDbC7aeA150b41EfE27b2d0eD"
        
        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    } else if (chainIdStr == "200810") {  // BITLAYER TESTNET Chain 200810

        rpcUrl = "https://testnet-rpc.bitlayer.org"
        ctmRwaMap = "0x1e608FD1546e1bC1382Abc4E676CeFB7e314Fb30"
        storageManager = "0x8d494f8B762005cCA5BDEBb770Af3bf51E730305"
        feeToken = "0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae"
        
        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    } else if (chainIdStr == "1952959480") {  // LUMIA TESTNET Chain 1952959480

        rpcUrl = "https://testnet-rpc.lumia.org"
        ctmRwaMap = "0xc04058E417De221448D4140FC1622dE24121C5e3"
        storageManager = "0xF84A465ce158Aad1848B737a6eCAbE6D253D12C2"
        feeToken = "0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae"
        
        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    } else if (chainIdStr == "5611") { // OPBNB TESTNET  Chain 5611

        rpcUrl = "https://opbnb-testnet-rpc.publicnode.com"
        ctmRwaMap = "0xfC2175A02c2e1e673F1Ba374A321d274Bb29bD68"
        storageManager = "0x7478600f35CCb2421E9dADC84954290adEca1196"
        feeToken = "0x108642B1b2390AC3f54E3B45369B7c660aeFffAD"
        
        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    } else if (chainIdStr == "1115") {  // CORE Testnet Chain 1115

        rpcUrl = "https://rpc.test.btcs.network/"
        ctmRwaMap = "0x89330bE16C672D4378B6731a8347D23B0c611de3"
        storageManager = "0x140991fF31A86D700510C1d391A0ACd48CB7AbB7"
        feeToken = "0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae"
        
        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    } else if (chainIdStr == "1946") {  // SONEIUM MINATO Chain 1946

        rpcUrl = "https://rpc.minato.soneium.org/"
        ctmRwaMap = "0xa568D1Ed42CBE94E72b0ED736588200536917E0c"
        storageManager = "0x48F214fDA66380A454DADAd9F84eF9D11d1f1D39"
        feeToken = "0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae"
        
        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    } else if (chainIdStr == "2810") {  // MORPH HOLESKY  Chain 2810

        rpcUrl = "https://rpc-holesky.morphl2.io"
        ctmRwaMap = "0x48F214fDA66380A454DADAd9F84eF9D11d1f1D39"
        storageManager = "0xF3065b38973C66a425FE7f7Ed911962CEF3a7dC1"
        feeToken = "0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae"
        
        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    } else if (chainIdStr == "534351") {  // SCROLL SEPOLIA   Chain 534351

        rpcUrl = "https://sepolia-rpc.scroll.io"
        ctmRwaMap = "0x48F214fDA66380A454DADAd9F84eF9D11d1f1D39"
        storageManager = "0xF3065b38973C66a425FE7f7Ed911962CEF3a7dC1"
        feeToken = "0xe536Bf33585aa6bb528627Ed7Dc4D49009dafC58"
        
        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    } else if (chainIdStr == "17000") {  // HOLESKY Chain 17000

        rpcUrl = "https://ethereum-holesky-rpc.publicnode.com"
        ctmRwaMap = "0xAF685f104E7428311F25526180cbd416Fa8668CD"
        storageManager = "0x1e46d7f21299Ac06AAd49017A1f733Cd5e6134f3"
        feeToken = "0x108642B1b2390AC3f54E3B45369B7c660aeFffAD"
        
        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    } else if (chainIdStr == "5003") {  // MANTLE SEPOLIA Chain 5003

        rpcUrl = "https://rpc.sepolia.mantle.xyz"
        ctmRwaMap = "0xfC2175A02c2e1e673F1Ba374A321d274Bb29bD68"
        storageManager = "0x7478600f35CCb2421E9dADC84954290adEca1196"
        feeToken = "0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae"
        
        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    } else if (chainIdStr == "4201") {  // LUKSO TESTNET  Chain 4201

        rpcUrl = "https://rpc.testnet.lukso.network/"
        ctmRwaMap = "0x1eE4bA474da815f728dF08F0147DeFac07F0BAb3"
        storageManager = "0x4dDcab55e1eae426a98e85f43896592Ad1dB0f84"
        feeToken = "0xC92291fbBe0711b6B34928cB1b09aba1f737DEfd"
        
        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    }  else if (chainIdStr == "80084") {  // BERA_BARTIO Chain 80084

        rpcUrl = "https://bartio.rpc.berachain.com"
        ctmRwaMap = "0x8be9dda9F320c0D9598A487E3C8F57196d53AcAe"
        storageManager = "0xFC63DC90296800c67cBb96330238fc17FbD674A2"
        feeToken = "0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae"
        
        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    }  else if (chainIdStr == "168587773") {  // BLAST SEPOLIA Chain 168587773

        rpcUrl = "https://sepolia.blast.io"
        ctmRwaMap = "0xa3325B2fA099c81a06d9b7532317d4a4Da7F2aB7"
        storageManager = "0xfC2175A02c2e1e673F1Ba374A321d274Bb29bD68"
        feeToken = "0x5d5408e949594E535d0c3d533761Cb044E11b664"
        
        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    }  else if (chainIdStr == "153") {  // REDBELLY TESTNET Chain 153

        rpcUrl = "https://governors.testnet.redbelly.network"
        ctmRwaMap = "0xf7Ed4f388e07Ab2B9138D1f7CF2F0Cf6B23820aF"
        storageManager = "0xE517cE19A5e7f6A81f2cA573110e963dB65c27cE"
        feeToken = "0xe536Bf33585aa6bb528627Ed7Dc4D49009dafC58"
        
        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    }  else if (chainIdStr == "11155420") {  // OPTIMISM SEPOLIA Chain 11155420

        rpcUrl = "https://rpc.ankr.com/optimism_sepolia"
        ctmRwaMap = "0xc8464ec2c98d3a0883E6bB64F08195AEFA807279"
        storageManager = "0x62AB67F946acA3991898ac7bB59beAc125eb5902"
        feeToken = "0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae"
        
        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    } else if (chainIdStr == "59141") {  // LINEA SEPOLIA Chain 59141

        rpcUrl = "https://linea-sepolia-rpc.publicnode.com"
        ctmRwaMap = "0xe5AF1a54B2b8cA3091edD229329B60A82b7A04E8"
        storageManager = "0x20B88eBa092c4CEb11E88F92abE1c01BC7Fe7234"
        feeToken = "0x6654D956A4487A26dF1186b01B689c26939544fC"
        
        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    } else if (chainIdStr == "78600") {  // VANGUARD Chain 78600

        rpcUrl = "https://rpc-vanguard.vanarchain.com"
        ctmRwaMap = "0x779f7FfdD1157935E1cD6344A6D7a9047736EBc1"
        storageManager = "0x8393181277c8a85ec0468B3f1ee61Bbfd78E62b4"
        feeToken = "0x6654D956A4487A26dF1186b01B689c26939544fC"
        
        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    }  else if (chainIdStr == "2484") {  // U2U NEBULAS TESTNET Chain 2484

        rpcUrl = "https://rpc-nebulas-testnet.uniultra.xyz"
        ctmRwaMap = "0xEd3c7279F4175F88Ab6bBcd16c8B8214387725e7"
        storageManager = "0xc74D2556d610F886B55653FAfFddF4bd0c1605B6"
        feeToken = "0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae"
        
        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    }   else if (chainIdStr == "1952959480") {  // LUMIA TESTNET Chain 1952959480

        rpcUrl = "https://testnet-rpc.lumia.org"
        ctmRwaMap = "0xc04058E417De221448D4140FC1622dE24121C5e3"
        storageManager = "0xF84A465ce158Aad1848B737a6eCAbE6D253D12C2"
        feeToken = "0x6a4DBC971533Ba36bdc23aD70F5A7a12E064f4ae"
        
        return {ok: true, rpcUrl: rpcUrl, ctmRwaMap: ctmRwaMap, storageManager: storageManager, feeToken: feeToken}
    } else {
        return {ok: false, rpcUrl: null, ctmRwaMap: null, storageManager: null, feeToken: null}
    }
}

module.exports = {
    getRwaContracts
}