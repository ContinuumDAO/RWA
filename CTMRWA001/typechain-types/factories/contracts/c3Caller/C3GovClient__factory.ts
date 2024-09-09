/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import { Signer, utils, Contract, ContractFactory, Overrides } from "ethers";
import type { Provider, TransactionRequest } from "@ethersproject/providers";
import type { PromiseOrValue } from "../../../common";
import type {
  C3GovClient,
  C3GovClientInterface,
} from "../../../contracts/c3Caller/C3GovClient";

const _abi = [
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "oldGov",
        type: "address",
      },
      {
        indexed: true,
        internalType: "address",
        name: "newGov",
        type: "address",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "timestamp",
        type: "uint256",
      },
    ],
    name: "ApplyGov",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "oldGov",
        type: "address",
      },
      {
        indexed: true,
        internalType: "address",
        name: "newGov",
        type: "address",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "timestamp",
        type: "uint256",
      },
    ],
    name: "ChangeGov",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "uint8",
        name: "version",
        type: "uint8",
      },
    ],
    name: "Initialized",
    type: "event",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "_op",
        type: "address",
      },
    ],
    name: "addOperator",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [],
    name: "applyGov",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "_gov",
        type: "address",
      },
    ],
    name: "changeGov",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [],
    name: "getAllOperators",
    outputs: [
      {
        internalType: "address[]",
        name: "",
        type: "address[]",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "gov",
    outputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    name: "isOperator",
    outputs: [
      {
        internalType: "bool",
        name: "",
        type: "bool",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    name: "operators",
    outputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "pendingGov",
    outputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "_op",
        type: "address",
      },
    ],
    name: "revokeOperator",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
] as const;

const _bytecode =
  "0x608080604052346100165761073d908161001c8239f35b600080fdfe60806040908082526004908136101561001757600080fd5b600092833560e01c91826312d43a51146105065750816325240810146104dd578163459c7695146104075781636d70f7ae146103c75781639870d7fe14610284578163a962ef1e14610207578163d911c63214610116578163e28d4906146100d1575063fad8b32a1461008957600080fd5b346100cd5760203660031901126100cd576001600160a01b03903581811681036100c9576100c16100c692845460101c16331461057a565b6105b8565b80f35b8280fd5b5080fd5b919050346100c95760203660031901126100c957359160035483101561011357506100fd60209261052d565b60018060a01b0391549060031b1c169051908152f35b80fd5b90508234610113578060031936011261011357815180916003549384835260208093018095600384527fc2575a0e9e593c00f959f8c92f12db2869c3395a3b0502d05e2516446f71f85b90845b868282106101ea5750505050849003601f01601f191684019567ffffffffffffffff8711858810176101d7575085815282865292518583018190528594938501939290915b8281106101b757505050500390f35b83516001600160a01b0316855286955093810193928101926001016101a8565b634e487b7160e01b835260419052602482fd5b83546001600160a01b031685529093019260019283019201610163565b919050346100c95760203660031901126100c957356001600160a01b0381811692918390036102805760207fd098c548c6851f1e61d4e1364996748b40477bb1abe90254bd71352396b2b7be91855460101c169261026684331461057a565b600180546001600160a01b0319168617905551428152a380f35b8380fd5b839150346100cd57602090816003193601126100c9578335916001600160a01b03808416908185036103c3576102c190865460101c16331461057a565b8015610382578085526002825260ff8386205416610335578452600290528220805460ff1916600117905560035492680100000000000000008410156101d757506103168360016100c694950160035561052d565b90919082549060031b9160018060a01b03809116831b921b1916179055565b825162461bcd60e51b8152808701839052602160248201527f433343616c6c65723a204f70657261746f7220616c72656164792065786973746044820152607360f81b6064820152608490fd5b606486838086519262461bcd60e51b845283015260248201527f433343616c6c65723a204f70657261746f7220697320616464726573732830296044820152fd5b8580fd5b919050346100c95760203660031901126100c957356001600160a01b038116908190036100c957818360ff92602095526002855220541690519015158152f35b8383346100cd57816003193601126100cd57600154906001600160a01b03908183161561049a5750825462010000600160b01b031916601083811b62010000600160b01b0316919091178085556001600160a01b031990931660015593514281529293849392901c16907fff88f8815b3f9faf85529ba09d2f7ff0d9c726c11cc863fd245156986014259090602090a380f35b606490602086519162461bcd60e51b8352820152601760248201527f4333476f763a20656d7074792070656e64696e67476f760000000000000000006044820152fd5b8390346100cd57816003193601126100cd5760015490516001600160a01b039091168152602090f35b8490346100cd57816003193601126100cd57905460101c6001600160a01b03168152602090f35b6003548110156105645760036000527fc2575a0e9e593c00f959f8c92f12db2869c3395a3b0502d05e2516446f71f85b0190600090565b634e487b7160e01b600052603260045260246000fd5b1561058157565b60405162461bcd60e51b815260206004820152600f60248201526e2199a3b7bb1d1037b7363c9023b7bb60891b6044820152606490fd5b6001600160a01b039081166000818152600260205260408120549192909160ff16156106c257828252600260205260408220805460ff1916905560038054835b81811061060757505050505050565b85846106128361052d565b905490861b1c161461064357600019811461062f576001016105f8565b634e487b7160e01b85526011600452602485fd5b92945090926000199290918381019081116106ae5790610316866106696106769461052d565b905490881b1c169161052d565b825490811561069a5750019161068b8361052d565b9091825491841b1b1916905555565b634e487b7160e01b81526031600452602490fd5b634e487b7160e01b83526011600452602483fd5b60405162461bcd60e51b815260206004820152601c60248201527f433343616c6c65723a204f70657261746f72206e6f7420666f756e64000000006044820152606490fdfea2646970667358221220b941cbd22edfa2e51b00dd2a904208ac48a7e2c4c9af049f488fc9b2b1e8197e64736f6c63430008140033";

type C3GovClientConstructorParams =
  | [signer?: Signer]
  | ConstructorParameters<typeof ContractFactory>;

const isSuperArgs = (
  xs: C3GovClientConstructorParams
): xs is ConstructorParameters<typeof ContractFactory> => xs.length > 1;

export class C3GovClient__factory extends ContractFactory {
  constructor(...args: C3GovClientConstructorParams) {
    if (isSuperArgs(args)) {
      super(...args);
    } else {
      super(_abi, _bytecode, args[0]);
    }
  }

  override deploy(
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<C3GovClient> {
    return super.deploy(overrides || {}) as Promise<C3GovClient>;
  }
  override getDeployTransaction(
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): TransactionRequest {
    return super.getDeployTransaction(overrides || {});
  }
  override attach(address: string): C3GovClient {
    return super.attach(address) as C3GovClient;
  }
  override connect(signer: Signer): C3GovClient__factory {
    return super.connect(signer) as C3GovClient__factory;
  }

  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): C3GovClientInterface {
    return new utils.Interface(_abi) as C3GovClientInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): C3GovClient {
    return new Contract(address, _abi, signerOrProvider) as C3GovClient;
  }
}