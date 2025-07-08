// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.22;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { ICTMRWAGateway } from "../src/crosschain/ICTMRWAGateway.sol";
import { FeeType, IFeeManager } from "../src/managers/IFeeManager.sol";

struct NewChain {
    uint256 chainId;
    address gateway;
    address rwaX;
    address feeManager;
    address storageManager;
    address sentryManager;
    address deployer;
}

interface IDapp {
    function addDappAddr(uint256 dappID, string[] memory whitelist) external;
}

contract DappConfig is Script {
    using Strings for *;

    string[] wList;

    address dappContract = address(0xf77C7BdF97245EB9b12e7d7C10ab6ABc2ABA0f6a);

    NewChain[] newchains;

    // struct NewChain {
    //     uint256 chainId;
    //     address gateway;
    //     address rwaX;
    //     address feeManager;
    //     address storageManager;
    //     address sentryManager;
    //     address deployer;
    // }

    constructor() {
        newchains.push(
            NewChain( // ARB Sepolia
                421_614,
                0xFa89DD803b8872f991997778d26c74a3Aecd9639,
                0x8bd737F4Ea451911eDF0445ACB1B7efdc9565221,
                0xc28328b1f98076eD5111f1223C647E883f5d6E16,
                0x7aB4De775c88e4aA4c93d0078d8318463fABfb13,
                0xb63F83484b9bdbaD5C574B4c89Badf0359e78854,
                0x167EF5E62CF14Eb74c4A9bC599D9afcB2119c2f8
            )
        );
        newchains.push(
            NewChain( // BASE SEPOLIA  Chain 84532
                84_532,
                0x31F21C6E2605D28e6b204CD323FF58421FC8Dd00,
                0x8736d3b789A6548Cc8fb607dA34Ed860ab626322,
                0x050E942b8ebb0E174A847f343D04EfdC669dFf63,
                0x7e0858dE387f30Ebc0bC2F24A35dc4ad9231Cffd,
                0x669AB21e6CeA598ea34CD1292680937c3DEF535c,
                0xd661BbE93a05ff2720623d501B54CF5eE72B2A9b
            )
        );
        newchains.push(
            NewChain( // POLYGON AMOY  Chain 80002
                80_002,
                0x66dB3f564807fdc689eC85285981eF464daeB943,
                0x2dA1B2763cF56b9DF5CbBB5A996C7e8836d8C6D8,
                0xA332fc0BF257AFF4aB07267De75d5Eb0c67B71AF,
                0xB3D138F0613CC476faA8c5E2C1a64e90D9d506F3,
                0xf32bc63A511B3B3DeB8fB6AeB3c52eBC0541067e,
                0x709b45446a540fA2bE3B9f8C6302B8c392AA9095
            )
        );
        // newchains.push(NewChain(  // LINEA SEPOLIA Chain 59141
        //     59141,
        //     ,
        //     ,
        //     ,
        //     ,
        //     ,
        //
        // ));
        // newchains.push(NewChain(  // CONFLUX ESPACE  Chain 71
        //     71,

        // ));
        newchains.push(
            NewChain( // CORE Testnet Chain 1115
                1115,
                0xc0b8f765907ab09106010190Ee991aAae01F88Ba,
                0xC981D340AC02B717B52DC249c46B1942e20EDBAD,
                0x87a0c3e97B52A42edBB513ad9701F6641B62afe2,
                0x2809808fC225FDAF859826cE7499a56B106D8870,
                0xEa37aEfe52E5327528F71171844474CF77507770,
                0x7f75443345A631751A7f6cdE34be3a8855ccdac7
            )
        );
        newchains.push(
            NewChain( // HOLESKY Chain 17000
                17_000,
                0x1EeBC47AaE37F2EA390869efe60db5a2cF2c9d80,
                0x9372CD1287E0bB6337802D80DFF342348c85fd78,
                0x1371eC7be82175C768Adc2E9E9AE5018863D5151,
                0xe148fbc6C35B6cecC50d18Ebf69959a6A989cB7C,
                0x208Ec1Ca3B07a50151c5741bc0E05C61beddad90,
                0x00d850114aC97754eCf9611Bb0dA99BbFC21BC4C
            )
        );
        // newchains.push(NewChain(  // MORPH HOLESKY  Chain 2810
        //     2810,
        //     ,
        //     ,
        //     ,
        //     ,
        //     ,

        // ));
        newchains.push(
            NewChain( // BLAST SEPOLIA Chain 168587773
                168_587_773,
                0xEa4A06cB68ABa869e6BF98Edc4BdbC731d2D82e3,
                0x9A0F81de582Ce9194FEADC6CCefaf9eA70451616,
                0x66dc636132fb9b7f6ed858928B65864D3fd0ea67,
                0x8D4EEe23A687b304E94eee3211f3058A60744502,
                0x0156a74FD9432446030f47f7c55f4d1FbfdF5E9a,
                0x32101CD0cF6FbC0743B17B51A94224c75B7092A0
            )
        );
        newchains.push(
            NewChain( // BITLAYER TESTNET Chain 200810
                200_810,
                0xe08C7eE637336565511eb3421DAFdf45b860F9bc,
                0x78F81b1AEe019efaAfe58853D96c5E9Ac87be731,
                0xb849bF0a5ca08f1e6EA792bDC06ff2317bb2fB90,
                0x0F607AF04457E86eC349FbEbb6e23B0A6A0D067F,
                0x10A04ad4a73C8bb00Ee5A29B27d11eeE85390306,
                0xF813DdCDd690aCB06ddbFeb395Cf65D18Efe74A7
            )
        );
        newchains.push(
            NewChain( // SCROLL SEPOLIA   Chain 534351
                534_351,
                0x1944F7fdd330Af7b0e7C08349591213E35ed5948,
                0x1249d751e6a0b7b11b9e55CBF8bC7d397AC3c083,
                0x93637D7068CEebC6cCDCB230E3AE65436666fe15,
                0xb406b937C12E03d676727Fc1Bb686279EeDbc178,
                0x66dc636132fb9b7f6ed858928B65864D3fd0ea67,
                0x20ADAf244972bC6cB064353F3EA4893f73E85599
            )
        );
        newchains.push(
            NewChain( // MANTLE SEPOLIA Chain 5003
                5003,
                0x9DC772b55e95A630031EBe431706D105af01Cf03,
                0xad49cabD336f943a9c350b9ED60680c54fa2c3d1,
                0x358498985E6ac7CA73F5110b415525aE04CB8313,
                0xeDe597aA066e6d7bc84BF586c494735DEB7DDe9F,
                0xDa61b02D88D2c857dA9d2da435152b08F03E2836,
                0x0EeA0C2FB4122e8193E26B06358E384b2b909848
            )
        );
        // newchains.push(NewChain(  // LUKSO TESTNET  Chain 4201
        //     4201,
        //     ,
        //     ,
        //     ,
        //     ,
        //     ,

        // ));
        // newchains.push(NewChain(  // LUMIA TESTNET Chain 1952959480
        //     1952959480,
        //     ,
        //     ,
        //     ,
        //     ,
        //     ,

        // ));
        // newchains.push(NewChain(  // PLUME TESTNET Chain 161221135
        //     161221135,

        // ));
        // newchains.push(NewChain(  // VANGUARD Chain 78600
        //     78600,
        //     ,
        //     ,
        //     ,
        //     ,
        //     ,

        // ));
        // newchains.push(NewChain(  // U2U NEBULAS TESTNET Chain 2484
        //     2484,
        //     ,
        //     ,
        //     ,
        //     ,
        //     ,

        // ));
        newchains.push(
            NewChain( // SONEIUM MINATO Chain 1946
                1946,
                0xa7441037961E31D4b64Aca57417d7673FEdC8fEC,
                0xf299832e535b9cc50D4002909061c320964D03FC,
                0xF074c733800eC017Da580A5DC95533143CD6abE4,
                0x3f547B04f8CF9552434B7f3a51Fc23247911b797,
                0xc04058E417De221448D4140FC1622dE24121C5e3,
                0x797AA64f83e4d17c2C6C80321f22445AAB153630
            )
        );
        newchains.push(
            NewChain( // OPBNB TESTNET  Chain 5611
                5611,
                0x78F81b1AEe019efaAfe58853D96c5E9Ac87be731,
                0x7743150e59d6A27ec96dDDa07B24131D0122b611,
                0xe08C7eE637336565511eb3421DAFdf45b860F9bc,
                0x926DF1f820Af8E3cF53A58C94332eB16BA4cB4b5,
                0x3AF6a526DD51C8B08FD54dBB624E042BB3b0a77e,
                0x093eaCfA2D856516ED71aF96D7DC7C571E6CA2a6
            )
        );
        // newchains.push(NewChain(  // SONIC TESTNET  Chain 64165
        //     64165,
        //     ,
        //     ,
        //     ,
        //     ,
        //     ,

        // ));
        // newchains.push(NewChain(  // FIRE THUNDER  Chain 997
        //     997,
        //     ,
        //     ,
        //     ,
        //     ,
        //     ,

        // ));
        // newchains.push(NewChain(  // HUMANODE TESTNET ISRAFEL  Chain 14853
        //     14853,
        //     ,
        //     ,
        //     ,
        //     ,
        //     ,

        // ));
        // newchains.push(NewChain(   // CRONOS TESTNET   Chain 338
        //     338,
        //     ,
        //     ,
        //     ,
        //     ,
        //     ,

        // // ));
        newchains.push(
            NewChain( //  BSC TESTNET Chain 97
                97,
                0x7a63F6b51c503e9A3354AF8262E8C7129aBDbBEb,
                0x37C7137Dc6e3DC3c3637bFEd3F6dBFbd43386429,
                0x1736009b39009f1cD6F08791C781317c2Dce4a88,
                0x71645806ee984439ADC3352ABB5491Ec03928e63,
                0x0d7B0bb763557EA0c7c2d938B5Ae3D5ccbbf8D44,
                0xdB2dC418F97DA871f5aCA6C4D50440FBffa40313
            )
        );
        newchains.push(
            NewChain( //  SEPOLIA  Chain 11155111
                11_155_111,
                0x13797c225F8E3645299F17d83365e0f5DB1c1607,
                0x778511925d3243Cf03a2486386ECc363E9Ad6647,
                0x08D0F2f8368CE13206F4839c3ce9151Be93893Bc,
                0x6681DB630eB117050D78E0B89eB5619b35Ea12e8,
                0xF4842C8354fE42e85D6DCDe11CFAda1B80BEAa33,
                0xef7c7BB5AB5b7bf55f7Cd9a38167C1F61eD15295
            )
        );
        newchains.push(
            NewChain( //  REDBELLY  Chain 153
                153,
                0x24A74106195Acd7e3E0a8cc17fd44761CC32474a,
                0x41388451eca7344136004D29a813dCEe49577B44,
                0xa328Fd0f353afc134f8f6Bdb51082D85395d7200,
                0x74972e7Ff5561bD902E3Ec3dDD5A22653088cA6f,
                0x5930640c1572bCD396eB410f62a6975ab9b8A148,
                0x208Ec1Ca3B07a50151c5741bc0E05C61beddad90
            )
        );
        newchains.push(
            NewChain( //  OPTIMISM  Chain 11155420
                11_155_420,
                0xf74b4051a565399B114a0fd6a674eCAB864aE186,
                0xb9de1C03EEa7546D9dB1fa6fc19Dfa7443f0AEDE,
                0x6Da387268C610E7276ee20255252819e923C754e,
                0x6429D598684EfBe5a5fF70451e7B2C501c85e254,
                0xA31AC55003cde3eF9CE9c576a691d0F41586c20b,
                0x791B9F43F035993420284bbd50203F3419F5b466
            )
        );
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        console.log("Wallet of deployer");
        console.log(deployer);

        vm.startBroadcast(deployerPrivateKey);

        // addDappWhitelist(65);
        // address toAdd = 0xF53fb9bb64AB9d3D78F976735762c5af9B5fF341;
        // addOneAddress(65,toAdd);
        addSingle(65, 2);

        vm.stopBroadcast();
    }

    function addDappWhitelist(uint256 dappID) public {
        require(block.chainid == 421_614, "Should be chainId for ARBITRUM SEPOLIA");

        address thisAddress;

        uint256 len = newchains.length;

        for (uint256 i = 0; i < len; i++) {
            console.log("Processing blockchain = ");
            console.log(newchains[i].chainId);

            if (dappID == 61) {
                // FeeManager
                thisAddress = newchains[i].feeManager;
                wList = _stringToArray(newchains[i].feeManager.toHexString());
            } else if (dappID == 62) {
                // CTMRWA001X
                thisAddress = newchains[i].rwaX;
                wList = _stringToArray(newchains[i].rwaX.toHexString());
            } else if (dappID == 63) {
                // CTMRWADeployer
                thisAddress = newchains[i].deployer;
                wList = _stringToArray(newchains[i].deployer.toHexString());
            } else if (dappID == 60) {
                // CTMRWAGateway
                thisAddress = newchains[i].gateway;
                wList = _stringToArray(newchains[i].gateway.toHexString());
            } else if (dappID == 64) {
                // CTMRWA001Storage
                thisAddress = newchains[i].storageManager;
                wList = _stringToArray(newchains[i].storageManager.toHexString());
            } else if (dappID == 65) {
                // CTMRWA001Sentry
                thisAddress = newchains[i].sentryManager;
                wList = _stringToArray(newchains[i].sentryManager.toHexString());
            }

            if (1 == 1) {
                // DappID 60
                // thisAddress != 0xeFbd6990A5C4ABFA30b91409aA3d9A0e7C8Bb77b &&
                // thisAddress != 0x25903bEA74d4fbE43B7D30703D2A740841DfB7b2 &&
                // thisAddress != 0x3CB56e6E5917a2a8924BC2A5C1f0ecc90b585e74

                // DappID 61
                // thisAddress != 0x9E2F5D1228b02C2FbF3168Db1162e7461574eBB9 &&
                // thisAddress != 0xf7548cB35188aa7DaC8423fAA2ACe3855634e40C

                // DappID 62
                // thisAddress != 0x45cddE4bdAbC97b3ec02B1271432ceeBc04d4c53 &&
                // thisAddress != 0xC230C289328a86d2daC10Db25E91f516aD7D0D3f &&
                // thisAddress != 0x610D47b471Ca1BA509F752AFAD8E391664bF4deC &&
                // thisAddress != 0xCa19ddc73718512B968B2cb838b1408885D74A05 &&
                // thisAddress != 0x8393181277c8a85ec0468B3f1ee61Bbfd78E62b4

                // DappID 63
                // thisAddress != 0x3FfbC9f4C2Bb8fB74Ab712d3E01c695Ce2329b1D &&
                // thisAddress != 0x25903bEA74d4fbE43B7D30703D2A740841DfB7b2 &&
                // thisAddress != 0xeFbd6990A5C4ABFA30b91409aA3d9A0e7C8Bb77b &&
                // thisAddress != 0xD55F76833388137FB1ECFc0dE1e6982716A19640 &&
                // thisAddress != 0x1F652e2D8A9FCa346A0F45D59a67FB998999e454

                // DappID 64
                // thisAddress != 0xe5AF1a54B2b8cA3091edD229329B60A82b7A04E8 &&
                // thisAddress != 0x6F0DDf81d8145301058e37CC51A485Ae6b44BCF9 &&
                // thisAddress != 0x3dc0e90bB56DE095321c48aadF0D0c29b47b837a &&
                // thisAddress != 0xd13779b354c3C72c9B438ABe7Db3086098778A7a

                // DappID 65
                // thisAddress != 0xDbBbbbd746F539d8C82aea9d4F776e5BA0F4e1a1 &&
                // thisAddress != 0x3FfbC9f4C2Bb8fB74Ab712d3E01c695Ce2329b1D &&
                // thisAddress != 0x6F0DDf81d8145301058e37CC51A485Ae6b44BCF9 &&
                // thisAddress != 0xDFe447a7F6780dD40D3eA4CF3F132c1F3b50BfF7 &&
                // thisAddress != 0x41543A4C6423E2546FC58AC63117B5692D68c323 &&
                // thisAddress != 0x3dc0e90bB56DE095321c48aadF0D0c29b47b837a &&
                // thisAddress != 0x43B8494f3C645c8CBA2B0D13C7Bd948D9877620c &&
                // thisAddress != 0xF1a79c24efF78FfFfbd4f8Df0Ce31aDEc284b9Cf

                try IDapp(dappContract).addDappAddr(dappID, wList) { } catch { }
            }
        }

        return;
    }

    function addOneAddress(uint256 dappID, address c3Address) public {
        IDapp(dappContract).addDappAddr(dappID, _stringToArray(c3Address.toHexString()));
    }

    function addSingle(uint256 dappID, uint256 indx) public {
        if (dappID == 61) {
            // FeeManager
            wList.push(newchains[indx].feeManager.toHexString());
        } else if (dappID == 62) {
            // CTMRWA001X
            wList.push(newchains[indx].rwaX.toHexString());
        } else if (dappID == 63) {
            // CTMRWADeployer
            wList.push(newchains[indx].deployer.toHexString());
        } else if (dappID == 60) {
            // CTMRWAGateway
            wList.push(newchains[indx].gateway.toHexString());
        } else if (dappID == 64) {
            // CTMRWA001Storage
            wList.push(newchains[indx].storageManager.toHexString());
        } else if (dappID == 65) {
            // CTMRWA001Sentry
            wList.push(newchains[indx].sentryManager.toHexString());
        }

        IDapp(dappContract).addDappAddr(dappID, wList);

        return;
    }

    function _stringToArray(string memory _string) internal pure returns (string[] memory) {
        string[] memory strArray = new string[](1);
        strArray[0] = _string;
        return (strArray);
    }
}
