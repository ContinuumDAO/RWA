/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import { Contract, Signer, utils } from "ethers";
import type { Provider } from "@ethersproject/providers";
import type {
  IC3Dapp,
  IC3DappInterface,
} from "../../../../contracts/c3Caller/IC3Caller.sol/IC3Dapp";

const _abi = [
  {
    inputs: [
      {
        internalType: "uint256",
        name: "dappID",
        type: "uint256",
      },
      {
        internalType: "bytes",
        name: "data",
        type: "bytes",
      },
      {
        internalType: "bytes",
        name: "reason",
        type: "bytes",
      },
    ],
    name: "c3Fallback",
    outputs: [
      {
        internalType: "bool",
        name: "",
        type: "bool",
      },
    ],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [],
    name: "dappID",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "txSender",
        type: "address",
      },
    ],
    name: "isValidSender",
    outputs: [
      {
        internalType: "bool",
        name: "",
        type: "bool",
      },
    ],
    stateMutability: "nonpayable",
    type: "function",
  },
] as const;

export class IC3Dapp__factory {
  static readonly abi = _abi;
  static createInterface(): IC3DappInterface {
    return new utils.Interface(_abi) as IC3DappInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): IC3Dapp {
    return new Contract(address, _abi, signerOrProvider) as IC3Dapp;
  }
}