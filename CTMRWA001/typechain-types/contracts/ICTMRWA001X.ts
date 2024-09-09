/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import type {
  BaseContract,
  BigNumber,
  BigNumberish,
  BytesLike,
  CallOverrides,
  ContractTransaction,
  Overrides,
  PopulatedTransaction,
  Signer,
  utils,
} from "ethers";
import type { FunctionFragment, Result } from "@ethersproject/abi";
import type { Listener, Provider } from "@ethersproject/providers";
import type {
  TypedEventFilter,
  TypedEvent,
  TypedListener,
  OnEvent,
  PromiseOrValue,
} from "../common";

export interface ICTMRWA001XInterface extends utils.Interface {
  functions: {
    "addXTokenInfo(address,string[],string[])": FunctionFragment;
    "admin()": FunctionFragment;
    "approveFromX(address,uint256)": FunctionFragment;
    "burnValueX(uint256,uint256)": FunctionFragment;
    "changeAdminX(address)": FunctionFragment;
    "checkTokenCompatibility(string,string)": FunctionFragment;
    "clearApprovedValues(uint256)": FunctionFragment;
    "getTokenContract(string)": FunctionFragment;
    "getTokenInfo(uint256)": FunctionFragment;
    "isApprovedOrOwner(address,uint256)": FunctionFragment;
    "mintFromX(address,uint256,uint256,uint256)": FunctionFragment;
    "mintFromX(address,uint256,uint256)": FunctionFragment;
    "mintValueX(uint256,uint256,uint256)": FunctionFragment;
    "removeTokenFromOwnerEnumeration(address,uint256)": FunctionFragment;
    "spendAllowance(address,uint256,uint256)": FunctionFragment;
  };

  getFunction(
    nameOrSignatureOrTopic:
      | "addXTokenInfo"
      | "admin"
      | "approveFromX"
      | "burnValueX"
      | "changeAdminX"
      | "checkTokenCompatibility"
      | "clearApprovedValues"
      | "getTokenContract"
      | "getTokenInfo"
      | "isApprovedOrOwner"
      | "mintFromX(address,uint256,uint256,uint256)"
      | "mintFromX(address,uint256,uint256)"
      | "mintValueX"
      | "removeTokenFromOwnerEnumeration"
      | "spendAllowance"
  ): FunctionFragment;

  encodeFunctionData(
    functionFragment: "addXTokenInfo",
    values: [
      PromiseOrValue<string>,
      PromiseOrValue<string>[],
      PromiseOrValue<string>[]
    ]
  ): string;
  encodeFunctionData(functionFragment: "admin", values?: undefined): string;
  encodeFunctionData(
    functionFragment: "approveFromX",
    values: [PromiseOrValue<string>, PromiseOrValue<BigNumberish>]
  ): string;
  encodeFunctionData(
    functionFragment: "burnValueX",
    values: [PromiseOrValue<BigNumberish>, PromiseOrValue<BigNumberish>]
  ): string;
  encodeFunctionData(
    functionFragment: "changeAdminX",
    values: [PromiseOrValue<string>]
  ): string;
  encodeFunctionData(
    functionFragment: "checkTokenCompatibility",
    values: [PromiseOrValue<string>, PromiseOrValue<string>]
  ): string;
  encodeFunctionData(
    functionFragment: "clearApprovedValues",
    values: [PromiseOrValue<BigNumberish>]
  ): string;
  encodeFunctionData(
    functionFragment: "getTokenContract",
    values: [PromiseOrValue<string>]
  ): string;
  encodeFunctionData(
    functionFragment: "getTokenInfo",
    values: [PromiseOrValue<BigNumberish>]
  ): string;
  encodeFunctionData(
    functionFragment: "isApprovedOrOwner",
    values: [PromiseOrValue<string>, PromiseOrValue<BigNumberish>]
  ): string;
  encodeFunctionData(
    functionFragment: "mintFromX(address,uint256,uint256,uint256)",
    values: [
      PromiseOrValue<string>,
      PromiseOrValue<BigNumberish>,
      PromiseOrValue<BigNumberish>,
      PromiseOrValue<BigNumberish>
    ]
  ): string;
  encodeFunctionData(
    functionFragment: "mintFromX(address,uint256,uint256)",
    values: [
      PromiseOrValue<string>,
      PromiseOrValue<BigNumberish>,
      PromiseOrValue<BigNumberish>
    ]
  ): string;
  encodeFunctionData(
    functionFragment: "mintValueX",
    values: [
      PromiseOrValue<BigNumberish>,
      PromiseOrValue<BigNumberish>,
      PromiseOrValue<BigNumberish>
    ]
  ): string;
  encodeFunctionData(
    functionFragment: "removeTokenFromOwnerEnumeration",
    values: [PromiseOrValue<string>, PromiseOrValue<BigNumberish>]
  ): string;
  encodeFunctionData(
    functionFragment: "spendAllowance",
    values: [
      PromiseOrValue<string>,
      PromiseOrValue<BigNumberish>,
      PromiseOrValue<BigNumberish>
    ]
  ): string;

  decodeFunctionResult(
    functionFragment: "addXTokenInfo",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "admin", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "approveFromX",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "burnValueX", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "changeAdminX",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "checkTokenCompatibility",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "clearApprovedValues",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "getTokenContract",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "getTokenInfo",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "isApprovedOrOwner",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "mintFromX(address,uint256,uint256,uint256)",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "mintFromX(address,uint256,uint256)",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "mintValueX", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "removeTokenFromOwnerEnumeration",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "spendAllowance",
    data: BytesLike
  ): Result;

  events: {};
}

export interface ICTMRWA001X extends BaseContract {
  connect(signerOrProvider: Signer | Provider | string): this;
  attach(addressOrName: string): this;
  deployed(): Promise<this>;

  interface: ICTMRWA001XInterface;

  queryFilter<TEvent extends TypedEvent>(
    event: TypedEventFilter<TEvent>,
    fromBlockOrBlockhash?: string | number | undefined,
    toBlock?: string | number | undefined
  ): Promise<Array<TEvent>>;

  listeners<TEvent extends TypedEvent>(
    eventFilter?: TypedEventFilter<TEvent>
  ): Array<TypedListener<TEvent>>;
  listeners(eventName?: string): Array<Listener>;
  removeAllListeners<TEvent extends TypedEvent>(
    eventFilter: TypedEventFilter<TEvent>
  ): this;
  removeAllListeners(eventName?: string): this;
  off: OnEvent<this>;
  on: OnEvent<this>;
  once: OnEvent<this>;
  removeListener: OnEvent<this>;

  functions: {
    addXTokenInfo(
      _admin: PromiseOrValue<string>,
      _chainIdsStr: PromiseOrValue<string>[],
      _contractAddrsStr: PromiseOrValue<string>[],
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    admin(
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    approveFromX(
      to_: PromiseOrValue<string>,
      tokenId_: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    burnValueX(
      fromTokenId_: PromiseOrValue<BigNumberish>,
      value_: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    changeAdminX(
      _admin: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    checkTokenCompatibility(
      _otherChainIdStr: PromiseOrValue<string>,
      _otherContractStr: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<[boolean]>;

    clearApprovedValues(
      tokenId_: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    getTokenContract(
      _chainIdStr: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<[string]>;

    getTokenInfo(
      tokenId_: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<
      [BigNumber, BigNumber, string, BigNumber] & {
        id: BigNumber;
        bal: BigNumber;
        owner: string;
        slot: BigNumber;
      }
    >;

    isApprovedOrOwner(
      operator_: PromiseOrValue<string>,
      tokenId_: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<[boolean]>;

    "mintFromX(address,uint256,uint256,uint256)"(
      to_: PromiseOrValue<string>,
      tokenId_: PromiseOrValue<BigNumberish>,
      slot_: PromiseOrValue<BigNumberish>,
      value_: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    "mintFromX(address,uint256,uint256)"(
      to_: PromiseOrValue<string>,
      slot_: PromiseOrValue<BigNumberish>,
      value_: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    mintValueX(
      toTokenId_: PromiseOrValue<BigNumberish>,
      slot_: PromiseOrValue<BigNumberish>,
      value_: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    removeTokenFromOwnerEnumeration(
      from_: PromiseOrValue<string>,
      tokenId_: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    spendAllowance(
      operator_: PromiseOrValue<string>,
      tokenId_: PromiseOrValue<BigNumberish>,
      value_: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;
  };

  addXTokenInfo(
    _admin: PromiseOrValue<string>,
    _chainIdsStr: PromiseOrValue<string>[],
    _contractAddrsStr: PromiseOrValue<string>[],
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  admin(
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  approveFromX(
    to_: PromiseOrValue<string>,
    tokenId_: PromiseOrValue<BigNumberish>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  burnValueX(
    fromTokenId_: PromiseOrValue<BigNumberish>,
    value_: PromiseOrValue<BigNumberish>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  changeAdminX(
    _admin: PromiseOrValue<string>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  checkTokenCompatibility(
    _otherChainIdStr: PromiseOrValue<string>,
    _otherContractStr: PromiseOrValue<string>,
    overrides?: CallOverrides
  ): Promise<boolean>;

  clearApprovedValues(
    tokenId_: PromiseOrValue<BigNumberish>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  getTokenContract(
    _chainIdStr: PromiseOrValue<string>,
    overrides?: CallOverrides
  ): Promise<string>;

  getTokenInfo(
    tokenId_: PromiseOrValue<BigNumberish>,
    overrides?: CallOverrides
  ): Promise<
    [BigNumber, BigNumber, string, BigNumber] & {
      id: BigNumber;
      bal: BigNumber;
      owner: string;
      slot: BigNumber;
    }
  >;

  isApprovedOrOwner(
    operator_: PromiseOrValue<string>,
    tokenId_: PromiseOrValue<BigNumberish>,
    overrides?: CallOverrides
  ): Promise<boolean>;

  "mintFromX(address,uint256,uint256,uint256)"(
    to_: PromiseOrValue<string>,
    tokenId_: PromiseOrValue<BigNumberish>,
    slot_: PromiseOrValue<BigNumberish>,
    value_: PromiseOrValue<BigNumberish>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  "mintFromX(address,uint256,uint256)"(
    to_: PromiseOrValue<string>,
    slot_: PromiseOrValue<BigNumberish>,
    value_: PromiseOrValue<BigNumberish>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  mintValueX(
    toTokenId_: PromiseOrValue<BigNumberish>,
    slot_: PromiseOrValue<BigNumberish>,
    value_: PromiseOrValue<BigNumberish>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  removeTokenFromOwnerEnumeration(
    from_: PromiseOrValue<string>,
    tokenId_: PromiseOrValue<BigNumberish>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  spendAllowance(
    operator_: PromiseOrValue<string>,
    tokenId_: PromiseOrValue<BigNumberish>,
    value_: PromiseOrValue<BigNumberish>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  callStatic: {
    addXTokenInfo(
      _admin: PromiseOrValue<string>,
      _chainIdsStr: PromiseOrValue<string>[],
      _contractAddrsStr: PromiseOrValue<string>[],
      overrides?: CallOverrides
    ): Promise<boolean>;

    admin(overrides?: CallOverrides): Promise<string>;

    approveFromX(
      to_: PromiseOrValue<string>,
      tokenId_: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<void>;

    burnValueX(
      fromTokenId_: PromiseOrValue<BigNumberish>,
      value_: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<boolean>;

    changeAdminX(
      _admin: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<boolean>;

    checkTokenCompatibility(
      _otherChainIdStr: PromiseOrValue<string>,
      _otherContractStr: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<boolean>;

    clearApprovedValues(
      tokenId_: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<void>;

    getTokenContract(
      _chainIdStr: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<string>;

    getTokenInfo(
      tokenId_: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<
      [BigNumber, BigNumber, string, BigNumber] & {
        id: BigNumber;
        bal: BigNumber;
        owner: string;
        slot: BigNumber;
      }
    >;

    isApprovedOrOwner(
      operator_: PromiseOrValue<string>,
      tokenId_: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<boolean>;

    "mintFromX(address,uint256,uint256,uint256)"(
      to_: PromiseOrValue<string>,
      tokenId_: PromiseOrValue<BigNumberish>,
      slot_: PromiseOrValue<BigNumberish>,
      value_: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<void>;

    "mintFromX(address,uint256,uint256)"(
      to_: PromiseOrValue<string>,
      slot_: PromiseOrValue<BigNumberish>,
      value_: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    mintValueX(
      toTokenId_: PromiseOrValue<BigNumberish>,
      slot_: PromiseOrValue<BigNumberish>,
      value_: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<boolean>;

    removeTokenFromOwnerEnumeration(
      from_: PromiseOrValue<string>,
      tokenId_: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<void>;

    spendAllowance(
      operator_: PromiseOrValue<string>,
      tokenId_: PromiseOrValue<BigNumberish>,
      value_: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<void>;
  };

  filters: {};

  estimateGas: {
    addXTokenInfo(
      _admin: PromiseOrValue<string>,
      _chainIdsStr: PromiseOrValue<string>[],
      _contractAddrsStr: PromiseOrValue<string>[],
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    admin(
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    approveFromX(
      to_: PromiseOrValue<string>,
      tokenId_: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    burnValueX(
      fromTokenId_: PromiseOrValue<BigNumberish>,
      value_: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    changeAdminX(
      _admin: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    checkTokenCompatibility(
      _otherChainIdStr: PromiseOrValue<string>,
      _otherContractStr: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    clearApprovedValues(
      tokenId_: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    getTokenContract(
      _chainIdStr: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    getTokenInfo(
      tokenId_: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    isApprovedOrOwner(
      operator_: PromiseOrValue<string>,
      tokenId_: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    "mintFromX(address,uint256,uint256,uint256)"(
      to_: PromiseOrValue<string>,
      tokenId_: PromiseOrValue<BigNumberish>,
      slot_: PromiseOrValue<BigNumberish>,
      value_: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    "mintFromX(address,uint256,uint256)"(
      to_: PromiseOrValue<string>,
      slot_: PromiseOrValue<BigNumberish>,
      value_: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    mintValueX(
      toTokenId_: PromiseOrValue<BigNumberish>,
      slot_: PromiseOrValue<BigNumberish>,
      value_: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    removeTokenFromOwnerEnumeration(
      from_: PromiseOrValue<string>,
      tokenId_: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    spendAllowance(
      operator_: PromiseOrValue<string>,
      tokenId_: PromiseOrValue<BigNumberish>,
      value_: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;
  };

  populateTransaction: {
    addXTokenInfo(
      _admin: PromiseOrValue<string>,
      _chainIdsStr: PromiseOrValue<string>[],
      _contractAddrsStr: PromiseOrValue<string>[],
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    admin(
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    approveFromX(
      to_: PromiseOrValue<string>,
      tokenId_: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    burnValueX(
      fromTokenId_: PromiseOrValue<BigNumberish>,
      value_: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    changeAdminX(
      _admin: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    checkTokenCompatibility(
      _otherChainIdStr: PromiseOrValue<string>,
      _otherContractStr: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    clearApprovedValues(
      tokenId_: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    getTokenContract(
      _chainIdStr: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    getTokenInfo(
      tokenId_: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    isApprovedOrOwner(
      operator_: PromiseOrValue<string>,
      tokenId_: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    "mintFromX(address,uint256,uint256,uint256)"(
      to_: PromiseOrValue<string>,
      tokenId_: PromiseOrValue<BigNumberish>,
      slot_: PromiseOrValue<BigNumberish>,
      value_: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    "mintFromX(address,uint256,uint256)"(
      to_: PromiseOrValue<string>,
      slot_: PromiseOrValue<BigNumberish>,
      value_: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    mintValueX(
      toTokenId_: PromiseOrValue<BigNumberish>,
      slot_: PromiseOrValue<BigNumberish>,
      value_: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    removeTokenFromOwnerEnumeration(
      from_: PromiseOrValue<string>,
      tokenId_: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    spendAllowance(
      operator_: PromiseOrValue<string>,
      tokenId_: PromiseOrValue<BigNumberish>,
      value_: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;
  };
}