// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

interface IDapp {
    function addDappAddr(uint256 dappID, string[] memory whitelist) external;
    function delWhitelists(uint256 dappID, string[] memory) external;
}

contract DeleteDappConfig is Script {

    using Strings for *;

    uint256 dappID = 44;

    address dappContract = address(0xf77C7BdF97245EB9b12e7d7C10ab6ABc2ABA0f6a);

    string[] dappID44AddrStr = [
        // '0x00cb1299d29a1d389879c1af2316a4b2c78da610',
        // '0x02ac04fba3ee9723ae60697b95128b6a5d5bda33',
        // '0x0872133516d5fe7b9b8a618aa0463ae0d776a865',
        // '0x0897e91383ab942bc502549ed75aa8ea7538b5fe',
        // '0x0bcb87c43e2ad859412d90892ff73d64c6dbb962',
        // '0x0c4aedfd2aef21b742c29f061ca80cc79d64a106',
        // '0x0d8723a971ab42d0c52bf241ddb313b20f84e837',
        // '0x0e95227823f64f54d6611ae6f4fb70a4d76d4378',
        // '0x1211a2dd0d01848dc4042a7a354cb8a4c51df594',
        // '0x176cD7aBF4919068d7FeC79935c303b32B7DabE7',
        '0x1944f7fdd330af7b0e7c08349591213e35ed5948',
        '0x1b902cf02724ac790da51e8004b82c7d0de6f957',
        '0x1ba78c17f0b190fa84bef5fb0de2234404acbea3',
        '0x1e608fd1546e1bc1382abc4e676cefb7e314fb30',
        '0x1eb65ef07b5a3b8f89fd851e078194e5d9e85f4b',
        '0x1F652e2D8A9FCa346A0F45D59a67FB998999e454',
        '0x1f8548eb8ec40294d7ed5e85dbf0f3bce228c3bc',
        '0x20adaf244972bc6cb064353f3ea4893f73e85599',
        '0x272d46ca49c87ab9e4cbd919cf35a32527d544db',
        '0x2a07e30ceb718f199268b5cd1cd473500af53c52',
        '0x2ba0f2383bee65838c07f89823414f7ee5124847',
        '0x2d2112de9801eaf71b6d1cbf40a99e57afc235a7',
        '0x33348aa4a1d62757eb6077c86554672dd22902ae',
        '0x3af6a526dd51c8b08fd54dbb624e042bb3b0a77e',
        '0x3Bd5Ae65396B96901F65CF01D40a6fB724c31bFd',
        '0x3dd9bb1ff0e52390c1bc16f1ab77608a2c7631c4',
        '0x41543a4c6423e2546fc58ac63117b5692d68c323',
        '0x4a82933a6d097a1f4c99880e4a3b4c7b7d291765',
        '0x4cda22b59a1fe957d09273e533ccb7d44bdef90c',
        '0x4f5b13a48d4fc78e154dda6c49e39c6d59277213',
        '0x54caa31d029e68a605d839d7258f37e946db71e9',
        '0x5930640c1572bcd396eb410f62a6975ab9b8a148',
        '0x5b4d2c1b2e918ff1b0de85803f5a737e5f816ecb',
        '0x605ab9626e57c5d1f3f0508d5400ab0449b5a015',
        '0x63135c26ad4a67d9d5dcfbccdc94f11de83eb2ca',
        '0x66dc636132fb9b7f6ed858928b65864d3fd0ea67',
        '0x67510816512511818b5047a4cce6e8f2ebb15d20',
        '0x7226289b8df9ffe5b98ad54d0225e8c83ecc7191',
        '0x7743150e59d6a27ec96ddda07b24131d0122b611',
        '0x779f7ffdd1157935e1cd6344a6d7a9047736ebc1',
        '0x7ad438d2b3ac77d55c85275fd09d51cec9bb2987',
        '0x7cd54fcbd1e2fdad5ec77557f76cc35972977a5a',
        '0x7e61a5AF95Fc6efaC03F7d92320F42B2c2fe96f0',
        '0x8b97e011a2f64f705c0a65706fb7bb968cb13d52',
        '0x9068f274555af3cd0a934dbcf1c56e7b83ad450a',
        '0x91677ec1879987aBC3978fD2A71204640A9e9f4A',
        '0x926df1f820af8e3cf53a58c94332eb16ba4cb4b5',
        '0x92bb6defef73fa2ee42fec2273d98693571bd7f3',
        '0x94c3fd7a91ee706b89214b9c2e9a505508109a3c',
        '0x957ebeecca9e712e335f99de34d0f46317283696',
        '0x9bfab09e477e0e931f292c8132f2579883c6921a',
        '0x9e2f5d1228b02c2fbf3168db1162e7461574ebb9',
        '0xa31ac55003cde3ef9ce9c576a691d0f41586c20b',
        '0xa3bae05aa45bcc739258b124face332043d3b1da',
        '0xa6e0fa5cceef6e87d89b4dc51053e1ff1a557b53',
        '0xa74af157716e604042cf835bd3a3f3a85c1c0959',
        '0xa9522e00101ee85f3b8e6a4f0723f5ea4a2f0a50',
        '0xa9888fd40bc181958bd2c2b2d06dd1559d0c8e55',
        '0xad2e580c931861360c998db3f0b090a5391da58e',
        '0xb413850c2d470643f5cb4ba9678c4e7d822c326e',
        '0xb76428ebe853f2f6a5d74c4361b72999f55ee637',
        '0xb9676266295363bc85a31305b479baddf4516033',
        '0xb9f462138e33dd8dba73394ddff141b3ef2f6bb1',
        '0xbce6b1ab3790bce90e2299cc9c46f6d2bcb56324',
        '0xc04058e417de221448d4140fc1622de24121c5e3',
        '0xc4edb1cbb639143a6faa63b7caf194ce53d88d29',
        '0xc74d2556d610f886b55653faffddf4bd0c1605b6',
        '0xCA89ae89EFa4D49150237038D63562247d17Ca1C',
        '0xcbf4e5fda887e602e5132fa800d74154dfb5b237',
        '0xcc2461b294f68e860b046038df8ad3a2a8c2fc51',
        '0xd1f0743c665d80d6bdaf1b4b8c9e82bfd1ae1994',
        '0xd8fb50721bc30bf3e4d591c078747b4e7ce46e7a',
        '0xdc44569f688a91ba3517c292de75e30ea284eea0',
        '0xea911684c200ac1fd3ca8a3ffd21afe9ef0e35da',
        '0xeb28c8e7cc2d8a8d361cb41ec0937ac11c0c0a1f',
        '0xec0DBF0fF0e4a73aBB940457B62b6979E4087A23',
        '0xecd4b2ab820215acc3cd579b8e65530d44a83643',
        '0xee53a0ad7f17715774acc3963693b37040900019',
        '0xeeccd5e6b0c4dca7d06bef132e3be04009eeef65',
        '0xef01a0adff5a96820a7c267d6a92ba041fa0c781',
        '0xF1a79c24efF78FfFfbd4f8Df0Ce31aDEc284b9Cf',
        '0xf204b97dbbba1bed029bd13bef456d1a17da9bf9',
        '0xf663c3de2d18920ffd7392242459275d0dd249e4',
        '0xf84a465ce158aad1848b737a6ecabe6d253d12c2',
        '0xfdD1a5B3AEEa2DF15a6F6B502784B61BdCbF66BC'
    ];

    string[] dappID45AddrStr = [
        // '0x01176DdbD5C70c0462cFE5ec1293227f323917c8',
        '0x176cd7abf4919068d7fec79935c303b32b7dabe7',
        '0x1a72d73b379a2454160b395ce7326755cbc76bce',
        '0x1b87108b35abb5751bfc64647e9d5cd1cb77e236',
        '0x1ee4ba474da815f728df08f0147defac07f0bab3',
        '0x21ea338975678968da85dea76f298e7f11a09334',
        '0x22D305a430b57a12D569f1e578B9F2f7613f92F8',
        '0x232c61b3d1a03cc57e976cccd0f9c9cd33a98fe0',
        '0x24da0f2114b682d01234bc9e103ff7eebf86ae6a',
        '0x266442249f62a8dd4e29348a52af8c806c7cb0da',
        '0x282eccb80074e9ab23ea5d28bd795c0bba3726a6',
        '0x2bBA6E0eDBe1aC6794B12B960A37156d9d07f009',
        '0x2be0c4ac75784737d4d0e75c4026d4bc671b938e',
        '0x30a63cf179996ae6332c0ac3898cdfd48b105118',
        '0x386ed9c1a214cc8700af43f4a39df8c722176e01',
        '0x3abb2780b0bbf630490d155c4861f4e82c623246',
        '0x410871e12756f751974379d56319ae5d34bb3eb5',
        '0x4328bf65bc8c69067a03d0fbde94ca1e24ed966c',
        '0x45cdde4bdabc97b3ec02b1271432ceebc04d4c53',
        '0x4da174a7024b242fb979d120ee63f1bf6aba3e07',
        '0x5fd3ef94668d7f5b6a439a9e2c662960115658c7',
        '0x63135C26Ad4a67D9D5dCfbCCDc94F11de83eB2Ca',
        '0x636d43798340603707c936c1a93597dc44effbee',
        '0x6681DB630eB117050D78E0B89eB5619b35Ea12e8',
        '0x66b719c489193594c617801e67119959cd15b63a',
        '0x67193a5129e506db83f434461a839938d98b2628',
        '0x69d461e1314af5e3bcab39f0eba3872c5de2c1e5',
        '0x6f2f79720c81631d3a0fe8e19c96f3cebd56519a',
        '0x730e8b2d89ba0d3403bb3d8c9929a9f0da61e051',
        '0x73943ec95aafbb4dd073b11f5c9701e5bc3708a6',
        '0x74da08abcb64a66370e9c1609771e68aafede27b',
        '0x7658e59cdba5e7e08263a216e89c8438c9f02048',
        '0x797aa64f83e4d17c2c6c80321f22445aab153630',
        '0x7dabce18c66b5c857355a815b6c1e926c701c23f',
        '0x8230abab39f9c618282ddd0af1dfa278de7df98f',
        '0x842391b3c9103a0cfcae764a201150a08774e810',
        '0x87E16C219daF604C8D33aea61f26b61152cf7c1d',
        '0x88a23d9ec1a9f1100d807d0e8c7a39927d4a7897',
        '0x8bde23e16f4f9b19b3e11edcb65168e7f2720006',
        '0x8Ea9B4616e5653CF21B87e60c8D72d8384685ec6',
        '0x9a0f81de582ce9194feadc6ccefaf9ea70451616',
        '0x9b0bc1e8267252b2e99fda8c302b0713ba3a8202',
        '0x9dc772b55e95a630031ebe431706d105af01cf03',
        '0xa09e913fa1aa5383a90ad6d8b94bc3dabee90332',
        '0xa4482df3a723654a599ba66d1b5091fd9c42ad05',
        '0xA450Ae39bf325c23a45B126eD2735F02d36b9A2d',
        '0xa6f306def6a39d08b0996e053458c632f9f55993',
        // '0xA85c68e9e09b2e84DF95e2ea7325Fb27019eDF30',
        '0xa8f94374facdf9413407fd10af8954e20e299c5d',
        '0xafc30031d05cab08f6e7ea5db3e3dba7e83de000',
        '0xb008b6cc593fc290ed03d5011e90f4e9d19f9a87',
        '0xb37c81d6f90a16bbd778886af49abebfd1ad02c7',
        '0xb3aefea9f49de70c41ce22afa321e64393932d21',
        '0xb41c8b53ea014188ba6777233e04efddbf4877b1',
        '0xb4317dba65486889643585a8d96c8d1990971cad',
        // '0xb5638019cbfc1b523d5167a269e755b05bf24fd9',
        // '0xb5638019cbfc1b523d5167a269e755b05bf24fd9',
        // '0xb5638019cbfc1b523d5167a269e755b05bf24fd9',
        // '0xb5638019cbfc1b523d5167a269e755b05bf24fd9',
        '0xb5d1f61f6b9f0ca2b89eb9d693e8cd737076846a',
        '0xb84577bf16b7ae120bca7bb9dbdb42e0a1ae67ec',
        '0xbab5Ec2802257958d3f3a34dcE2F7Aa65Eac922d',
        '0xbe87477fd18fbebd8cccdd003f6f66ffc4d49cd1',
        '0xc5070659d0290f2eb2b1ed886f3f7574fde5c4be',
        '0xcacf2003d4bc2e19c865e65ebb9d57c440217f0f',
        '0xcd1f6cb9977db3187ec00bcfaa99d5f808537be8',
        '0xcff54249dae66746377e15c07d95c42188d5d3a8',
        '0xd06cda2c8f2258ceec5efb8c6371f54d7853480e',
        '0xd455bb0f664ac8241b505729c3116f1acc441be4',
        '0xd586ea1fce09384f71b69e80f643135fc0641def',
        '0xd5870cb8400e75f2097f3af9fd37af0c758707e0',
        '0xd6f9cc85f5a3031d6e32a03ddb8a7aedbebd953e',
        '0xd7155b99ca57aa4c0711a87b982f517de5a036de',
        '0xdb3caae3a1fd4846bc2a7ddbcb2b7b4dbd3484b8',
        '0xdf495f3724a6c705fed4adfa7588cd326162a39c',
        '0xdfcf0181d2c2608d6e055997d2c215811acc2d49',
        '0xe08c7ee637336565511eb3421dafdf45b860f9bc',
        '0xe0f1cd117107457bc14c2f1b82e218157c2a620c',
        '0xe4370824a15854eed6d132cb2c7ee7a4953e7aca',
        '0xe63d71fc4c86003aea77325c896345d9311690aa',
        '0xf3cC0945B766f296A7ff7b5b52820376A2322f39',
        '0xfc2b6634dc49ba4b353540f344050724c932359a'
    ];

    string[] dappID46AddrStr = [
        '0x08a424008babad51161ed85761c1421c26116dfe',
        '0x0a91de653d4c09e7bc757ed794a03e4b40a1d057',
        '0x11D5B22218A54981D27E0B6a6439Fd61589bf02a',
        '0x127d5ada49071c33d10aa8de441e218a71475119',
        '0x13b17e90f430760eb038b83C5EBFd8082c027e00',
        '0x1B87108B35Abb5751Bfc64647E9D5cD1Cb77E236',
        // '0x298F37599789926A4ab495F72d3Bb5CC7838ff73',
        '0x37415b746b2ef7f37608006ddaa404d377fdf633',
        '0x40BE43817F87dEB5A355E3796CF89CACB590DaEc',
        '0x5020f191fd0ce7f9340659b2d03ea0ba5921b44a',
        // '0x511A4e9af646E933c145A8892837547900078A97',
        '0x5a7be43d528d75ed78aaa16a9e3bf6a20a23b8a3',
        '0x618a42e871ea7a9ee5f8477a1631da8c433eb9bc',
        '0x6f013ad0b507590dcb26e674199ba99d613e9dfd',
        '0x70af28a024463d3efb5772adb8869470015bf076',
        // '0x74Da08aBCb64A66370E9C1609771e68aAfEDE27B',
        '0x77aa59ba778c00946122e43702509c87b81604f5',
        '0x7AEECCcafb96e53460B5b633Fc668adf14ed8419',
        '0x9af1e5b3e863d88a4e220fb07ffb8c2e5a96ddbd',
        '0xa3325b2fa099c81a06d9b7532317d4a4da7f2ab7',
        '0xa7441037961E31D4b64Aca57417d7673FEdC8fEC',
        '0xa7ec64d41f32ffe662a46b62e59d1ebfead52522',
        '0xac71dcf325724594525cc05552bee7d6550a80fd',
        '0xc3dc6a3edc40460baa684f45e9e377b7e42009b1',
        '0xcfc2d5fa55534019b3406257723506a3ab5e2eed',
        '0xd09a46f3a221a5595f4a71a24296787235bbb895',
        '0xd1F0743C665d80D6BDaf1b4B8C9E82bfd1aE1994',
        '0xD523b4f68c015B472724c24e127FF1f51EeE0fbf',
        '0xDB3caaE3A1fD4846bC2a7dDBcb2B7b4dbd3484b8',
        '0xdbbbbbd746f539d8c82aea9d4f776e5ba0f4e1a1',
        '0xeA4B6Aed334Bc39342486C85126838C9D4e293a9',
        '0xf0c7a83f1bb9ca54e7c60b4cdbc8c469ce776a6d',
        '0xf813ddcdd690acb06ddbfeb395cf65d18efe74a7',
        '0xfc2175a02c2e1e673f1ba374a321d274bb29bd68'
    ];

    string[] dappID47AddrStr = [
        '0x052e276c0a9d2d2adf1a2aeb6d7ecaec38ec9de6',
        '0x06edc167555ceb6038e2c6b3bed7a47c628f2eed',
        '0x0a47eff3560ee2c0a2773f3927b6869f193f6858',
        '0x114ace1c918409889464c2a714f8442a97934ccf',
        '0x1249d751e6a0b7b11b9e55cbf8bc7d397ac3c083',
        '0x1392fc45312550197adf2039de80e8da58fc72a3',
        '0x16b049e17b49c5dc1d8598b53593d4497c858c9a',
        '0x1e46d7f21299ac06aad49017a1f733cd5e6134f3',
        '0x20a9f9d7282c6fde913522a42c3951f5b18f62d5',
        '0x21c90e25142a8cef8ca3fbefd6417617bcafa303',
        '0x22c254662850f21bfb09714f6a5638d929439f8d',
        '0x25903bea74d4fbe43b7d30703d2a740841dfb7b2',
        '0x291e038ef58dcfdf020e0bbea0c9a36713db7966',
        '0x2927d422cbea7f315ee3e0660af2ed9b35302004',
        '0x2cd9f1d9000d8752cc7653e10f259f7d9a94a5e7',
        '0x2d1967ef42ecf9a42785d08398aadba806aa090b',
        '0x3561aa249d1262a912764770bb8c387a7bbb56b6',
        '0x358498985e6ac7ca73f5110b415525ae04cb8313',
        '0x37415B746B2eF7f37608006dDaA404d377fdF633',
        '0x3cb56e6e5917a2a8924bc2a5c1f0ecc90b585e74',
        '0x3ffbc9f4c2bb8fb74ab712d3e01c695ce2329b1d',
        '0x409774624e037e950b7c6f099357ffde3e7f8e1b',
        '0x443731488c75cdb209fbab813b574953ba973597',
        '0x497d31415cc6d20113d2f96c90c706b98701c1c9',
        '0x63e754dabf952456427b9958682d58aa07f85982',
        '0x64c5734e22cf8126c6367c0230b66788fbe4ab90',
        '0x6640ec42f86abcf799c21a070f7baf6db38a2ab9',
        '0x67fd0c58bd8b925a3d3546ecc505653514b64013',
        '0x699de1ff83fad8c40aea628975e1b3ee71dcfb56',
        '0x6aff0df7a17477f76f2cc927a50571a23a4a3b1f',
        '0x7240fcdb0dd116293044ed50db499680aa532eeb',
        '0x73a3ecd2fad26975d16b31e482eaf0f5152d420e',
        '0x7478600f35ccb2421e9dadc84954290adeca1196',
        '0x74972e7ff5561bd902e3ec3ddd5a22653088ca6f',
        '0x7635a9b23275892ac46479b7ead9831a80171ace',
        '0x787a3afdebabb386b31d56cf7cc3cd6637340799',
        '0x82c7cf3ad2a7c6ea732c131e552ad171d190421e',
        '0x89330be16c672d4378b6731a8347d23b0c611de3',
        '0x8b8de69a9cbca6b7cb85406dde46116dd520d5b0',
        '0x9266e8bf4943f2b366f2be89688a8622084db8b9',
        '0x95574b1a28865A81D2df36683d027A9D7603aFC7',
        '0x969035b34b913c507b87fd805fff608fb1fe13f0',
        // '0x99d26Ed0E4bb6659b56eE36DD9EE1814345aE9B9',
        '0x9b191600588b59e314d2927204c8edc57603d672',
        '0x9b81c6a2a62eea2a814afdbb5d69ce0592e1c751',
        '0xa42864da3ee7b05489ef1d99704089b734cb73a2',
        '0xae66c08b9d76eecaa74314c60f3305d43707acc9',
        '0xb1bc63301670f8ec9ee98bd501c89783d65ddc8a',
        '0xb64a86e7f8d84b2cd88535bdaac6d19c87754024',
        '0xb75a2833405907508bd5f8dea3a24fa537d9c85c',
        '0xb81d017b3606a7e6eba0049de9f0ea0e4a1d90dd',
        '0xb849bf0a5ca08f1e6ea792bdc06ff2317bb2fb90',
        '0xba08c3b81ed1a13e7a3457b6ab5dddba2df34df4',
        '0xbab5ec2802257958d3f3a34dce2f7aa65eac922d',
        '0xbf56d054a81583e18c3d186abaca3302be399f3c',
        '0xc0dd542bcac26095a2c83ffb10826ccef806c07b',
        '0xc70baa204cfdcda282bc16980a5bab15d152df5c',
        '0xD362AFB113D7a2226aFf228F4FB161BEFd3b6BD4',
        '0xd52966352e5a15dcb05cdfb4d8f54f565d487210',
        '0xD586Ea1FcE09384F71B69e80F643135FC0641def',
        '0xd990ef52a6a375b19375b07cfc2aad2b592e66be',
        '0xdbd55d95d447e363251592a8ff573bbf16c2cb68',
        '0xdc432bc497a9e38f3ae319842777c9829aac47c4',
        '0xdc635161b63ca5281f96f2d70c3f7c0060d151d3',
        '0xe1c4c5a0e6a99bb61b842bb78e5c66ea1256d292',
        '0xe305d37adbe6f7c987108f537dc247f8df5c1f24',
        '0xea4a06cb68aba869e6bf98edc4bdbc731d2d82e3',
        '0xea4b6aed334bc39342486c85126838c9d4e293a9',
        '0xeadb6779c7284a7ef6f611f4535e60c3d59b321b',
        '0xeb4b038c0f1f086bb7ab5b4192611015aff95390',
        '0xf065f9bbd5f59afa0d24be34bdf8ad483485ed1c',
        '0xf1a79c24eff78ffffbd4f8df0ce31adec284b9cf',
        '0xf3a991cb19949cb6abd9e416f0408c648b6c36fa',
        '0xf4e7a775c8abc8e0b7ed11d660b0a6b2e1b7a132',
        '0xf8fe7804ae6dbc7306ab5a97ae2302706170530c',
        '0xf97c2b87a7193b7800f50fc402e8f999bf1bf3e4',
        // '0xf9EDcE2638da660F51Ee08220a1a5A32fAB61d61',
        '0xfdd1a5b3aeea2df15a6f6b502784b61bdcbf66bc'
    ];

    string[] dappID48AddrStr = [
        '0x0156a74fd9432446030f47f7c55f4d1fbfdf5e9a',
        '0x0174abcc86b7b8a54cfff7ad08f982bc894b914d',
        '0x02E77B34A4d16D9b00c7B4e787776327adB1344C',
        '0x048a5cefcdf0faeb734bc4a941e0de44d8c49f55',
        '0x05a804374bb77345854022fd0cd2a602e00bf2e7',
        '0x093eacfa2d856516ed71af96d7dc7c571e6ca2a6',
        '0x094bd93df885d063e89b61702aad4463de313ebe',
        '0x0f21cb137b097dc120abbb0ec6fb89c605e5f476',
        '0x0f92c2f73498bf195c6129b2528c64f3d0bed434',
        '0x10a04ad4a73c8bb00ee5a29b27d11eee85390306',
        '0x140991ff31a86d700510c1d391a0acd48cb7abb7',
        '0x1a934da311376333e784b1f7afa84287f6122c0d',
        '0x1f652e2d8a9fca346a0f45d59a67fb998999e454',
        '0x20b88eba092c4ceb11e88f92abe1c01bc7fe7234',
        '0x267d28e9cb14938b00f0dc216c84d15b37738884',
        '0x298c11661856dc1194c578ecd2c230eb4fa433a0',
        '0x2c4be93acd346ca06363b37a06beb9d693d02dac',
        '0x316b7f54d7a1140cfbe5d4d39f07cc396dd71e01',
        '0x3188f25255c22ba3cb0339a259cdca9cb963f135',
        '0x3418a45e442210ec9579b074ae9acb13b2a67554',
        '0x37c7137dc6e3dc3c3637bfed3f6dbfbd43386429',
        '0x3912670e1a1b6183c89a2079aaa3299ce585296a',
        '0x3b44962bf264b8cebac13da24722faa27fc693a1',
        '0x3c63f6f855b761793366336a0941cb9d8b21f79a',
        '0x3d9ad7fb378bceb18c47e01af6e60679b6caa8a9',
        '0x41543A4C6423E2546FC58AC63117B5692D68c323',
        '0x44bd5b80fed6d6574d21f9b748d0b9a1d5566312',
        '0x48f214fda66380a454dadad9f84ef9d11d1f1d39',
        '0x4b17e8ee1cc1814636dde9ac12a42472799ccb64',
        '0x4ddcab55e1eae426a98e85f43896592ad1db0f84',
        '0x4f6af153614d50051bad6f3e76110f959817738f',
        '0x4fb3a28c53c88731d783610d0ff275b02bbf19e0',
        '0x533a9ceccba37453337e28dcb3ec4705d5d22260',
        '0x5438b4f84152061e3717350721f00ee9c6151baf',
        '0x56249f01cf2b50a7f211bb9de08b1480835f574a',
        '0x563c5c85cc7ba923c50b66479588e5b3b2c93470',
        '0x5fffba2e10d66e9368c6270cfd07e31802fff751',
        '0x60a5b05db6c8eb0b47f8227ea3b04bd751b79dbc',
        '0x610d47b471ca1ba509f752afad8e391664bf4dec',
        '0x6187ee058bb5b7db140cfd470a27ebe1f16d92b1',
        '0x6429d598684efbe5a5ff70451e7b2c501c85e254',
        '0x66db3f564807fdc689ec85285981ef464daeb943',
        '0x6dd5666ef6b2e83d504c1ee586fb3c630abc7fd2',
        '0x6f0ddf81d8145301058e37cc51a485ae6b44bcf9',
        '0x769139881024ce730de9de9c21e3ad6fb5a872f2',
        '0x78e9f16b42508a9bc0892bff922c09067de08fc5',
        '0x7ed4d0234e6c0f6704463e9a62a33ab7b7846a09',
        '0x8159be9135ecc4893826e40cf19047a79c523008',
        '0x815ac25ea81d9a0b38d81698cdd661e93a833117',
        '0x8393181277c8a85ec0468b3f1ee61bbfd78e62b4',
        '0x854bcf67c4b4bbf44623f8f0c86d954f02be6d67',
        '0x855c06f9f7b01838dc540ec6fcff17fd86a378d8',
        '0x8641613849038f495fa8dd313f13a3f7f2d73815',
        '0x87724b9402bd58Fb13963F5884845db8Ec860552',
        '0x8d494f8b762005cca5bdebb770af3bf51e730305',
        '0x8e36c2b1ac03d98fac0074c9e8e27023a3ce2206',
        '0x8ee0aee8a42f55ed43f5e7db765fa591c4714c41',
        '0x9372cd1287e0bb6337802d80dff342348c85fd78',
        '0x93def24108852be52b2c34084d584338e46ab8f4',
        '0x952c91e42cD9eCdc5F9cD98d8F24EAa769fDCd02',
        '0x95574b1a28865a81d2df36683d027a9d7603afc7',
        '0x95ae66ad780e73ef2d2a80611458883c950a1356',
        '0x95fdf4044a76a886b80481c360d2f64cdb337918',
        '0x98269063d2bd9dda4b9438f4240463b8b475c7f6',
        '0xa240b0714712e2927ec055ceaa8e031ac671a55f',
        '0xa33cfd901896c775c5a6d62e94081b4fdd1b09bc',
        '0xa3d476bb425ad923483c5f699fab17dbeb4473be',
        '0xa7c57315395def05f906310d590f4ea15308fe30',
        '0xa840a5ec6557df201a6a1561dbdc8ad6f3b3faf4',
        '0xaa0558dd75995a3916e79b354ec4cb40fe9f122d',
        '0xad49cabd336f943a9c350b9ed60680c54fa2c3d1',
        '0xad77409a722056b0d41b5ce2f03a6b7a2b18e3ed',
        '0xaf685f104e7428311f25526180cbd416fa8668cd',
        '0xb07c3788549cd48ad1d4cb9b7336f7c9dd53d67f',
        '0xb128ee08fb55a9ae0b18d753a093bf40ebc1d804',
        '0xb406b937c12e03d676727fc1bb686279eedbc178',
        '0xb523f0e72a7bdf94a5a3d84ba9e8dc42e69229ea',
        '0xb8b99101c1dbfad6aa418220592773be082db804',
        '0xc047401f28f43ec8af8c5aaac26bf7d007e2474a',
        '0xc230c289328a86d2dac10db25e91f516ad7d0d3f',
        '0xc33b3317912d173806d782bfade797f262d9a4bd',
        '0xc653cd79f70165005319ef97ad1229ac7f88a25d',
        '0xCBf4E5FDA887e602E5132FA800d74154DFb5B237',
        '0xd4bd9bba2fb97c36bbd619303cab636f476f8904',
        '0xd83c21b20935aa3135864965c6181b811b31fb7c',
        '0xde3e5713b4873c466dac96009bda93d2ac7242b8',
        '0xde3fdb278b0ec3254e8701c38e58cfd1168f13a5',
        '0xdf64bce319cef28abc017d166a5f6563d58c493d',
        '0xe38f40efc472aae401ba1edf37edd98ba43f5266',
        '0xe43d06a75cfee05bd698f32c36c611d5328718ee',
        '0xe517ce19a5e7f6a81f2ca573110e963db65c27ce',
        '0xe569c146b0d4c1c941607b5c6a648b5877ae29ef',
        '0xe60cc236b36ba33b07832ec9bfeaf875a409a1d3',
        '0xE6d89DBE4113BDDc79c4D8256C3604d9Db291fEa',
        '0xe91abb1f959c96a91674b0923478860eacd653d2',
        '0xf3065b38973c66a425fe7f7ed911962cef3a7dc1',
        '0xf4e9dc949ca6eb2bbafa1e887017e91e523c1bc8',
        '0xf55fB33d9BD6Bb47461d68890bc8F951480211FC',
        '0xf5f405ccf62c2e9f636f9f0de9878dd26550b63d',
        '0xf60acdea049b537865441d7befd492c5cb56496d',
        '0xf9229aceba228fdbb757a637eeebadb46fdb617e',
        '0xfa1e6c9b7464668a0001309c0969b0f6fa893e8f',
        '0xfc63dc90296800c67cbb96330238fc17fbd674a2',
        '0xfefe834c4b32bf5da89f7f0c059590719fe3e3ee'
    ];

    string[] dappID58AddrStr = [
        '0x0000000000000000000000000000000000000000',
        '0x03571126595d2afe0039a174bdd00565ef923940',
        '0x0dB39536F72E19edFfd45e318b1Da9A3684679a2',
        '0x0f607af04457e86ec349fbebb6e23b0a6a0d067f',
        '0x100eb51c34cc7507c201139a2d9421479ca86ad0',
        '0x26e5dbf59b2f8081a9b9a0728160203c4c1ac64c',
        '0x2ad99b7d982b119848a647676c02663018a1928a',
        '0x2da1b2763cf56b9df5cbbb5a996c7e8836d8c6d8',
        '0x2fdbb139fb38520c2ad6cd30cf45b3c8e5633c65',
        '0x4218c42503fbb0cc65cbdf507b7ce64f0c52bc32',
        '0x4596f5bfba6cb5ebdb23a0d118434b43ad9be3b7',
        '0x555081698e43f7f7b04f9ba7ea36ceb0f2be4749',
        '0x5b1e22e2b53f673485a38a57457b00accd24dc07',
        '0x5d1ac9be7112f10568cf9e795b85c278d99264eb',
        '0x604643f60b3bf7ee767a998e35fe0b9c6356223a',
        '0x6105e8bb3727d7c990305f0741dc6ad1c027a4a8',
        '0x652003e2253e9200d7779d4bc8b962cd1f8d604b',
        '0x77abd89181775355f39a2dfb74fb233499fc4500',
        '0x7aeecccafb96e53460b5b633fc668adf14ed8419',
        '0x813f3770a82cf5a368ef50bfff3b619c446ef938',
        '0x9282fa6c2639305b7e462233ebae328381fe40bd',
        '0x93ae0e18578828631489c6cb8f8045ebe8d4599f',
        '0x97161c4c66b11629f2d3211c8bd8131705d64092',
        '0x998f9E69CF313d06b1D4BA22FeCE9c23D0D0Ca31',
        '0xae57e6d1cfbce6872f7d2bebda2e09cde089d0bc',
        '0xb22b822a7d945d6b77184cf5753e8458577dcf3a',
        '0xb9297f9d00e0712bdc0734419d5bcc92a61fec57',
        '0xba59f04dbdcb1b74d601fbbf3e7e1ca82081c536',
        '0xc7a339588569da96def78a96732ee20c3446bf11',
        '0xc98984dae5ef66e702fe16d1b69b043bc163435c',
        '0xca19ddc73718512b968b2cb838b1408885d74a05',
        '0xcb3cdbbb8966faaf90de6f4b6b6935b38c703225',
        '0xcfce683f3cf5aeb17c5d6cc15ab82930588f877a',
        '0xd4fb54dc259fd95846d5569e94b91fda08d08262',
        '0xd523b4f68c015b472724c24e127ff1f51eee0fbf',
        '0xdc910f7bcc6f163dfa4804eaca10891eb5b9e867',
        '0xe0f2017bc8206ffc8d563a6c0c9fb52c0189a5a6',
        '0xe73fb620e57f764746ead61319865f71f6a5cd60',
        '0xe831d6dcaf9f45089eb82dcdda8014355273f1dc',
        '0xec66ee6116cf91ffc2a7afc0dfb1cb882caab4d0',
        '0xefbd6990a5c4abfa30b91409aa3d9a0e7c8bb77b',
        '0xf6c7d0228d98a7ecb9c2a472182063ed84eb6ba0',
        '0xf7548cb35188aa7dac8423faa2ace3855634e40c'
    ];

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        console.log("Wallet of deployer");
        console.log(deployer);

        vm.startBroadcast(deployerPrivateKey);

        // deleteDappAddr(dappID);

        string memory delAddrStr = "0x94C3fD7a91ee706B89214B9C2E9a505508109a3c";
        // 0x91677ec1879987abc3978fd2a71204640a9e9f4a
        // 0x94c3fd7a91ee706b89214b9c2e9a505508109a3c
        // 0x63135c26ad4a67d9d5dcfbccdc94f11de83eb2ca
        deleteSingleDappAddr(44, delAddrStr);

        vm.stopBroadcast();

    }

    function deleteSingleDappAddr(uint256 _dappID, string memory _delAddrStr) public {
        IDapp(dappContract).delWhitelists(_dappID, _stringToArray(_delAddrStr));
    }

    function deleteDappAddr(uint256 _dappID) public {

        string[] memory delListStr;

        if(_dappID == 44) {
            delListStr = dappID44AddrStr;
        } else if(_dappID == 45) {
            delListStr = dappID45AddrStr;
        } else if(_dappID == 46) {
            delListStr = dappID46AddrStr; 
        } else if(_dappID == 47) {
            delListStr = dappID47AddrStr;
        } else if(dappID == 48) {
            delListStr = dappID48AddrStr;
        } else if(_dappID == 58) {
            delListStr = dappID58AddrStr;
        }

        for(uint256 i=0; i<delListStr.length; i++) {
            try IDapp(dappContract).delWhitelists(_dappID, _stringToArray(delListStr[i])) {

            } catch {

            }
        }

    }

    function _stringToArray(string memory _string) internal pure returns(string[] memory) {
        string[] memory strArray = new string[](1);
        strArray[0] = _string;
        return(strArray);
    }
    

}
