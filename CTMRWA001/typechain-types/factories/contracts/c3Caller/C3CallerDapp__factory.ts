/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import { Contract, Signer, utils } from "ethers";
import type { Provider } from "@ethersproject/providers";
import type {
  C3CallerDapp,
  C3CallerDappInterface,
} from "../../../contracts/c3Caller/C3CallerDapp";

const _abi = [
  {
    inputs: [],
    name: "c3CallerProxy",
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
        internalType: "uint256",
        name: "_dappID",
        type: "uint256",
      },
      {
        internalType: "bytes",
        name: "_data",
        type: "bytes",
      },
      {
        internalType: "bytes",
        name: "_reason",
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
    stateMutability: "view",
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

export class C3CallerDapp__factory {
  static readonly abi = _abi;
  static createInterface(): C3CallerDappInterface {
    return new utils.Interface(_abi) as C3CallerDappInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): C3CallerDapp {
    return new Contract(address, _abi, signerOrProvider) as C3CallerDapp;
  }
}
