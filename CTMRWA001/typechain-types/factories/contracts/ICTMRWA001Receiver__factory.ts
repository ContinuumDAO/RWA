/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import { Contract, Signer, utils } from "ethers";
import type { Provider } from "@ethersproject/providers";
import type {
  ICTMRWA001Receiver,
  ICTMRWA001ReceiverInterface,
} from "../../contracts/ICTMRWA001Receiver";

const _abi = [
  {
    inputs: [
      {
        internalType: "address",
        name: "_operator",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "_fromTokenId",
        type: "uint256",
      },
      {
        internalType: "uint256",
        name: "_toTokenId",
        type: "uint256",
      },
      {
        internalType: "uint256",
        name: "_value",
        type: "uint256",
      },
      {
        internalType: "bytes",
        name: "_data",
        type: "bytes",
      },
    ],
    name: "onCTMRWA001Received",
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
] as const;

export class ICTMRWA001Receiver__factory {
  static readonly abi = _abi;
  static createInterface(): ICTMRWA001ReceiverInterface {
    return new utils.Interface(_abi) as ICTMRWA001ReceiverInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): ICTMRWA001Receiver {
    return new Contract(address, _abi, signerOrProvider) as ICTMRWA001Receiver;
  }
}
