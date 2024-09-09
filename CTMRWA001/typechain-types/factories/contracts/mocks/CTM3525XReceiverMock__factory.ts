/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import {
  Signer,
  utils,
  Contract,
  ContractFactory,
  BytesLike,
  BigNumberish,
  Overrides,
} from "ethers";
import type { Provider, TransactionRequest } from "@ethersproject/providers";
import type { PromiseOrValue } from "../../../common";
import type {
  CTM3525XReceiverMock,
  CTM3525XReceiverMockInterface,
} from "../../../contracts/mocks/CTM3525XReceiverMock";

const _abi = [
  {
    inputs: [
      {
        internalType: "bytes4",
        name: "retval",
        type: "bytes4",
      },
      {
        internalType: "enum CTM3525XReceiverMock.Error",
        name: "error",
        type: "uint8",
      },
    ],
    stateMutability: "nonpayable",
    type: "constructor",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "address",
        name: "operator",
        type: "address",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "fromTokenId",
        type: "uint256",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "toTokenId",
        type: "uint256",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "value",
        type: "uint256",
      },
      {
        indexed: false,
        internalType: "bytes",
        name: "data",
        type: "bytes",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "gas",
        type: "uint256",
      },
    ],
    name: "Received",
    type: "event",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "operator",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "fromTokenId",
        type: "uint256",
      },
      {
        internalType: "uint256",
        name: "toTokenId",
        type: "uint256",
      },
      {
        internalType: "uint256",
        name: "value",
        type: "uint256",
      },
      {
        internalType: "bytes",
        name: "data",
        type: "bytes",
      },
    ],
    name: "onCTM3525XReceived",
    outputs: [
      {
        internalType: "bytes4",
        name: "",
        type: "bytes4",
      },
    ],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "bytes4",
        name: "interfaceId",
        type: "bytes4",
      },
    ],
    name: "supportsInterface",
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
] as const;

const _bytecode =
  "0x60c060405234801561001057600080fd5b506040516104ec3803806104ec83398101604081905261002f9161006e565b6001600160e01b0319821660805280600381111561004f5761004f6100b9565b60a0816003811115610063576100636100b9565b8152505050506100cf565b6000806040838503121561008157600080fd5b82516001600160e01b03198116811461009957600080fd5b6020840151909250600481106100ae57600080fd5b809150509250929050565b634e487b7160e01b600052602160045260246000fd5b60805160a0516103eb6101016000396000818160cc01528181610151015261018f0152600061021901526103eb6000f3fe608060405234801561001057600080fd5b50600436106100365760003560e01c806301ffc9a71461003b5780630f4e93f814610063575b600080fd5b61004e610049366004610242565b61008f565b60405190151581526020015b60405180910390f35b610076610071366004610273565b6100c6565b6040516001600160e01b0319909116815260200161005a565b60006001600160e01b031982166301ffc9a760e01b14806100c057506001600160e01b031982166301e9d27f60e31b145b92915050565b600060017f000000000000000000000000000000000000000000000000000000000000000060038111156100fc576100fc610320565b0361014d5760405162461bcd60e51b815260206004820152601f60248201527f43544d333532355852656365697665724d6f636b3a20726576657274696e6700604482015260640160405180910390fd5b60027f0000000000000000000000000000000000000000000000000000000000000000600381111561018157610181610320565b0361018b57600080fd5b60037f000000000000000000000000000000000000000000000000000000000000000060038111156101bf576101bf610320565b036101d35760006101d08180610336565b50505b7f7693f14379c435d2f83242a3efbdcca5efc90c59cbcf91f258ed512e511b19518787878787875a60405161020e9796959493929190610358565b60405180910390a1507f00000000000000000000000000000000000000000000000000000000000000009695505050505050565b60006020828403121561025457600080fd5b81356001600160e01b03198116811461026c57600080fd5b9392505050565b60008060008060008060a0878903121561028c57600080fd5b86356001600160a01b03811681146102a357600080fd5b9550602087013594506040870135935060608701359250608087013567ffffffffffffffff808211156102d557600080fd5b818901915089601f8301126102e957600080fd5b8135818111156102f857600080fd5b8a602082850101111561030a57600080fd5b6020830194508093505050509295509295509295565b634e487b7160e01b600052602160045260246000fd5b60008261035357634e487b7160e01b600052601260045260246000fd5b500490565b60018060a01b038816815286602082015285604082015284606082015260c060808201528260c0820152828460e0830137600060e08483010152600060e0601f19601f86011683010190508260a08301529897505050505050505056fea26469706673582212209c1c25a165138febf6edadd17f9227a84fb5b996ac59fcc5d8cd6c8b2391601264736f6c63430008140033";

type CTM3525XReceiverMockConstructorParams =
  | [signer?: Signer]
  | ConstructorParameters<typeof ContractFactory>;

const isSuperArgs = (
  xs: CTM3525XReceiverMockConstructorParams
): xs is ConstructorParameters<typeof ContractFactory> => xs.length > 1;

export class CTM3525XReceiverMock__factory extends ContractFactory {
  constructor(...args: CTM3525XReceiverMockConstructorParams) {
    if (isSuperArgs(args)) {
      super(...args);
    } else {
      super(_abi, _bytecode, args[0]);
    }
  }

  override deploy(
    retval: PromiseOrValue<BytesLike>,
    error: PromiseOrValue<BigNumberish>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<CTM3525XReceiverMock> {
    return super.deploy(
      retval,
      error,
      overrides || {}
    ) as Promise<CTM3525XReceiverMock>;
  }
  override getDeployTransaction(
    retval: PromiseOrValue<BytesLike>,
    error: PromiseOrValue<BigNumberish>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): TransactionRequest {
    return super.getDeployTransaction(retval, error, overrides || {});
  }
  override attach(address: string): CTM3525XReceiverMock {
    return super.attach(address) as CTM3525XReceiverMock;
  }
  override connect(signer: Signer): CTM3525XReceiverMock__factory {
    return super.connect(signer) as CTM3525XReceiverMock__factory;
  }

  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): CTM3525XReceiverMockInterface {
    return new utils.Interface(_abi) as CTM3525XReceiverMockInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): CTM3525XReceiverMock {
    return new Contract(
      address,
      _abi,
      signerOrProvider
    ) as CTM3525XReceiverMock;
  }
}