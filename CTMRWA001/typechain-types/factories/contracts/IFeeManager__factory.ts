/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import { Contract, Signer, utils } from "ethers";
import type { Provider } from "@ethersproject/providers";
import type {
  IFeeManager,
  IFeeManagerInterface,
} from "../../contracts/IFeeManager";

const _abi = [
  {
    inputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    name: "getFeeTokenIndexMap",
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
    inputs: [],
    name: "getFeeTokenList",
    outputs: [
      {
        internalType: "address[]",
        name: "",
        type: "address[]",
      },
    ],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "string",
        name: "fromChainIDStr",
        type: "string",
      },
      {
        internalType: "string",
        name: "toChainIDStr",
        type: "string",
      },
      {
        internalType: "address",
        name: "feeToken",
        type: "address",
      },
    ],
    name: "getXChainFee",
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
] as const;

export class IFeeManager__factory {
  static readonly abi = _abi;
  static createInterface(): IFeeManagerInterface {
    return new utils.Interface(_abi) as IFeeManagerInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): IFeeManager {
    return new Contract(address, _abi, signerOrProvider) as IFeeManager;
  }
}
