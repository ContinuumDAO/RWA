/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import { Contract, Signer, utils } from "ethers";
import type { Provider } from "@ethersproject/providers";
import type {
  IERC3525MetadataDescriptorUpgradeable,
  IERC3525MetadataDescriptorUpgradeableInterface,
} from "../../../../contracts/periphery/interface/IERC3525MetadataDescriptorUpgradeable";

const _abi = [
  {
    inputs: [],
    name: "constructContractURI",
    outputs: [
      {
        internalType: "string",
        name: "",
        type: "string",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "slot",
        type: "uint256",
      },
    ],
    name: "constructSlotURI",
    outputs: [
      {
        internalType: "string",
        name: "",
        type: "string",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "tokenId",
        type: "uint256",
      },
    ],
    name: "constructTokenURI",
    outputs: [
      {
        internalType: "string",
        name: "",
        type: "string",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
] as const;

export class IERC3525MetadataDescriptorUpgradeable__factory {
  static readonly abi = _abi;
  static createInterface(): IERC3525MetadataDescriptorUpgradeableInterface {
    return new utils.Interface(
      _abi
    ) as IERC3525MetadataDescriptorUpgradeableInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): IERC3525MetadataDescriptorUpgradeable {
    return new Contract(
      address,
      _abi,
      signerOrProvider
    ) as IERC3525MetadataDescriptorUpgradeable;
  }
}
