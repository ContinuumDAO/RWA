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
  PayableOverrides,
  PopulatedTransaction,
  Signer,
  utils,
} from "ethers";
import type {
  FunctionFragment,
  Result,
  EventFragment,
} from "@ethersproject/abi";
import type { Listener, Provider } from "@ethersproject/providers";
import type {
  TypedEventFilter,
  TypedEvent,
  TypedListener,
  OnEvent,
  PromiseOrValue,
} from "../../common";

export interface IERC3525SlotEnumerableUpgradeableInterface
  extends utils.Interface {
  functions: {
    "allowance(uint256,address)": FunctionFragment;
    "approve(address,uint256)": FunctionFragment;
    "approve(uint256,address,uint256)": FunctionFragment;
    "balanceOf(address)": FunctionFragment;
    "balanceOf(uint256)": FunctionFragment;
    "getApproved(uint256)": FunctionFragment;
    "isApprovedForAll(address,address)": FunctionFragment;
    "ownerOf(uint256)": FunctionFragment;
    "safeTransferFrom(address,address,uint256)": FunctionFragment;
    "safeTransferFrom(address,address,uint256,bytes)": FunctionFragment;
    "setApprovalForAll(address,bool)": FunctionFragment;
    "slotByIndex(uint256)": FunctionFragment;
    "slotCount()": FunctionFragment;
    "slotOf(uint256)": FunctionFragment;
    "supportsInterface(bytes4)": FunctionFragment;
    "tokenByIndex(uint256)": FunctionFragment;
    "tokenInSlotByIndex(uint256,uint256)": FunctionFragment;
    "tokenOfOwnerByIndex(address,uint256)": FunctionFragment;
    "tokenSupplyInSlot(uint256)": FunctionFragment;
    "totalSupply()": FunctionFragment;
    "transferFrom(uint256,address,uint256)": FunctionFragment;
    "transferFrom(address,address,uint256)": FunctionFragment;
    "transferFrom(uint256,uint256,uint256)": FunctionFragment;
    "valueDecimals()": FunctionFragment;
  };

  getFunction(
    nameOrSignatureOrTopic:
      | "allowance"
      | "approve(address,uint256)"
      | "approve(uint256,address,uint256)"
      | "balanceOf(address)"
      | "balanceOf(uint256)"
      | "getApproved"
      | "isApprovedForAll"
      | "ownerOf"
      | "safeTransferFrom(address,address,uint256)"
      | "safeTransferFrom(address,address,uint256,bytes)"
      | "setApprovalForAll"
      | "slotByIndex"
      | "slotCount"
      | "slotOf"
      | "supportsInterface"
      | "tokenByIndex"
      | "tokenInSlotByIndex"
      | "tokenOfOwnerByIndex"
      | "tokenSupplyInSlot"
      | "totalSupply"
      | "transferFrom(uint256,address,uint256)"
      | "transferFrom(address,address,uint256)"
      | "transferFrom(uint256,uint256,uint256)"
      | "valueDecimals"
  ): FunctionFragment;

  encodeFunctionData(
    functionFragment: "allowance",
    values: [PromiseOrValue<BigNumberish>, PromiseOrValue<string>]
  ): string;
  encodeFunctionData(
    functionFragment: "approve(address,uint256)",
    values: [PromiseOrValue<string>, PromiseOrValue<BigNumberish>]
  ): string;
  encodeFunctionData(
    functionFragment: "approve(uint256,address,uint256)",
    values: [
      PromiseOrValue<BigNumberish>,
      PromiseOrValue<string>,
      PromiseOrValue<BigNumberish>
    ]
  ): string;
  encodeFunctionData(
    functionFragment: "balanceOf(address)",
    values: [PromiseOrValue<string>]
  ): string;
  encodeFunctionData(
    functionFragment: "balanceOf(uint256)",
    values: [PromiseOrValue<BigNumberish>]
  ): string;
  encodeFunctionData(
    functionFragment: "getApproved",
    values: [PromiseOrValue<BigNumberish>]
  ): string;
  encodeFunctionData(
    functionFragment: "isApprovedForAll",
    values: [PromiseOrValue<string>, PromiseOrValue<string>]
  ): string;
  encodeFunctionData(
    functionFragment: "ownerOf",
    values: [PromiseOrValue<BigNumberish>]
  ): string;
  encodeFunctionData(
    functionFragment: "safeTransferFrom(address,address,uint256)",
    values: [
      PromiseOrValue<string>,
      PromiseOrValue<string>,
      PromiseOrValue<BigNumberish>
    ]
  ): string;
  encodeFunctionData(
    functionFragment: "safeTransferFrom(address,address,uint256,bytes)",
    values: [
      PromiseOrValue<string>,
      PromiseOrValue<string>,
      PromiseOrValue<BigNumberish>,
      PromiseOrValue<BytesLike>
    ]
  ): string;
  encodeFunctionData(
    functionFragment: "setApprovalForAll",
    values: [PromiseOrValue<string>, PromiseOrValue<boolean>]
  ): string;
  encodeFunctionData(
    functionFragment: "slotByIndex",
    values: [PromiseOrValue<BigNumberish>]
  ): string;
  encodeFunctionData(functionFragment: "slotCount", values?: undefined): string;
  encodeFunctionData(
    functionFragment: "slotOf",
    values: [PromiseOrValue<BigNumberish>]
  ): string;
  encodeFunctionData(
    functionFragment: "supportsInterface",
    values: [PromiseOrValue<BytesLike>]
  ): string;
  encodeFunctionData(
    functionFragment: "tokenByIndex",
    values: [PromiseOrValue<BigNumberish>]
  ): string;
  encodeFunctionData(
    functionFragment: "tokenInSlotByIndex",
    values: [PromiseOrValue<BigNumberish>, PromiseOrValue<BigNumberish>]
  ): string;
  encodeFunctionData(
    functionFragment: "tokenOfOwnerByIndex",
    values: [PromiseOrValue<string>, PromiseOrValue<BigNumberish>]
  ): string;
  encodeFunctionData(
    functionFragment: "tokenSupplyInSlot",
    values: [PromiseOrValue<BigNumberish>]
  ): string;
  encodeFunctionData(
    functionFragment: "totalSupply",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "transferFrom(uint256,address,uint256)",
    values: [
      PromiseOrValue<BigNumberish>,
      PromiseOrValue<string>,
      PromiseOrValue<BigNumberish>
    ]
  ): string;
  encodeFunctionData(
    functionFragment: "transferFrom(address,address,uint256)",
    values: [
      PromiseOrValue<string>,
      PromiseOrValue<string>,
      PromiseOrValue<BigNumberish>
    ]
  ): string;
  encodeFunctionData(
    functionFragment: "transferFrom(uint256,uint256,uint256)",
    values: [
      PromiseOrValue<BigNumberish>,
      PromiseOrValue<BigNumberish>,
      PromiseOrValue<BigNumberish>
    ]
  ): string;
  encodeFunctionData(
    functionFragment: "valueDecimals",
    values?: undefined
  ): string;

  decodeFunctionResult(functionFragment: "allowance", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "approve(address,uint256)",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "approve(uint256,address,uint256)",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "balanceOf(address)",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "balanceOf(uint256)",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "getApproved",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "isApprovedForAll",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "ownerOf", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "safeTransferFrom(address,address,uint256)",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "safeTransferFrom(address,address,uint256,bytes)",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "setApprovalForAll",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "slotByIndex",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "slotCount", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "slotOf", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "supportsInterface",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "tokenByIndex",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "tokenInSlotByIndex",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "tokenOfOwnerByIndex",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "tokenSupplyInSlot",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "totalSupply",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "transferFrom(uint256,address,uint256)",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "transferFrom(address,address,uint256)",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "transferFrom(uint256,uint256,uint256)",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "valueDecimals",
    data: BytesLike
  ): Result;

  events: {
    "Approval(address,address,uint256)": EventFragment;
    "ApprovalForAll(address,address,bool)": EventFragment;
    "ApprovalValue(uint256,address,uint256)": EventFragment;
    "SlotChanged(uint256,uint256,uint256)": EventFragment;
    "Transfer(address,address,uint256)": EventFragment;
    "TransferValue(uint256,uint256,uint256)": EventFragment;
  };

  getEvent(nameOrSignatureOrTopic: "Approval"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "ApprovalForAll"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "ApprovalValue"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "SlotChanged"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "Transfer"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "TransferValue"): EventFragment;
}

export interface ApprovalEventObject {
  _owner: string;
  _approved: string;
  _tokenId: BigNumber;
}
export type ApprovalEvent = TypedEvent<
  [string, string, BigNumber],
  ApprovalEventObject
>;

export type ApprovalEventFilter = TypedEventFilter<ApprovalEvent>;

export interface ApprovalForAllEventObject {
  _owner: string;
  _operator: string;
  _approved: boolean;
}
export type ApprovalForAllEvent = TypedEvent<
  [string, string, boolean],
  ApprovalForAllEventObject
>;

export type ApprovalForAllEventFilter = TypedEventFilter<ApprovalForAllEvent>;

export interface ApprovalValueEventObject {
  _tokenId: BigNumber;
  _operator: string;
  _value: BigNumber;
}
export type ApprovalValueEvent = TypedEvent<
  [BigNumber, string, BigNumber],
  ApprovalValueEventObject
>;

export type ApprovalValueEventFilter = TypedEventFilter<ApprovalValueEvent>;

export interface SlotChangedEventObject {
  _tokenId: BigNumber;
  _oldSlot: BigNumber;
  _newSlot: BigNumber;
}
export type SlotChangedEvent = TypedEvent<
  [BigNumber, BigNumber, BigNumber],
  SlotChangedEventObject
>;

export type SlotChangedEventFilter = TypedEventFilter<SlotChangedEvent>;

export interface TransferEventObject {
  _from: string;
  _to: string;
  _tokenId: BigNumber;
}
export type TransferEvent = TypedEvent<
  [string, string, BigNumber],
  TransferEventObject
>;

export type TransferEventFilter = TypedEventFilter<TransferEvent>;

export interface TransferValueEventObject {
  _fromTokenId: BigNumber;
  _toTokenId: BigNumber;
  _value: BigNumber;
}
export type TransferValueEvent = TypedEvent<
  [BigNumber, BigNumber, BigNumber],
  TransferValueEventObject
>;

export type TransferValueEventFilter = TypedEventFilter<TransferValueEvent>;

export interface IERC3525SlotEnumerableUpgradeable extends BaseContract {
  connect(signerOrProvider: Signer | Provider | string): this;
  attach(addressOrName: string): this;
  deployed(): Promise<this>;

  interface: IERC3525SlotEnumerableUpgradeableInterface;

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
    allowance(
      _tokenId: PromiseOrValue<BigNumberish>,
      _operator: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<[BigNumber]>;

    "approve(address,uint256)"(
      _approved: PromiseOrValue<string>,
      _tokenId: PromiseOrValue<BigNumberish>,
      overrides?: PayableOverrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    "approve(uint256,address,uint256)"(
      _tokenId: PromiseOrValue<BigNumberish>,
      _operator: PromiseOrValue<string>,
      _value: PromiseOrValue<BigNumberish>,
      overrides?: PayableOverrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    "balanceOf(address)"(
      _owner: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<[BigNumber]>;

    "balanceOf(uint256)"(
      _tokenId: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<[BigNumber]>;

    getApproved(
      _tokenId: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<[string]>;

    isApprovedForAll(
      _owner: PromiseOrValue<string>,
      _operator: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<[boolean]>;

    ownerOf(
      _tokenId: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<[string]>;

    "safeTransferFrom(address,address,uint256)"(
      _from: PromiseOrValue<string>,
      _to: PromiseOrValue<string>,
      _tokenId: PromiseOrValue<BigNumberish>,
      overrides?: PayableOverrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    "safeTransferFrom(address,address,uint256,bytes)"(
      _from: PromiseOrValue<string>,
      _to: PromiseOrValue<string>,
      _tokenId: PromiseOrValue<BigNumberish>,
      data: PromiseOrValue<BytesLike>,
      overrides?: PayableOverrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    setApprovalForAll(
      _operator: PromiseOrValue<string>,
      _approved: PromiseOrValue<boolean>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    slotByIndex(
      _index: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<[BigNumber]>;

    slotCount(overrides?: CallOverrides): Promise<[BigNumber]>;

    slotOf(
      _tokenId: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<[BigNumber]>;

    supportsInterface(
      interfaceId: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<[boolean]>;

    tokenByIndex(
      _index: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<[BigNumber]>;

    tokenInSlotByIndex(
      _slot: PromiseOrValue<BigNumberish>,
      _index: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<[BigNumber]>;

    tokenOfOwnerByIndex(
      _owner: PromiseOrValue<string>,
      _index: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<[BigNumber]>;

    tokenSupplyInSlot(
      _slot: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<[BigNumber]>;

    totalSupply(overrides?: CallOverrides): Promise<[BigNumber]>;

    "transferFrom(uint256,address,uint256)"(
      _fromTokenId: PromiseOrValue<BigNumberish>,
      _to: PromiseOrValue<string>,
      _value: PromiseOrValue<BigNumberish>,
      overrides?: PayableOverrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    "transferFrom(address,address,uint256)"(
      _from: PromiseOrValue<string>,
      _to: PromiseOrValue<string>,
      _tokenId: PromiseOrValue<BigNumberish>,
      overrides?: PayableOverrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    "transferFrom(uint256,uint256,uint256)"(
      _fromTokenId: PromiseOrValue<BigNumberish>,
      _toTokenId: PromiseOrValue<BigNumberish>,
      _value: PromiseOrValue<BigNumberish>,
      overrides?: PayableOverrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    valueDecimals(overrides?: CallOverrides): Promise<[number]>;
  };

  allowance(
    _tokenId: PromiseOrValue<BigNumberish>,
    _operator: PromiseOrValue<string>,
    overrides?: CallOverrides
  ): Promise<BigNumber>;

  "approve(address,uint256)"(
    _approved: PromiseOrValue<string>,
    _tokenId: PromiseOrValue<BigNumberish>,
    overrides?: PayableOverrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  "approve(uint256,address,uint256)"(
    _tokenId: PromiseOrValue<BigNumberish>,
    _operator: PromiseOrValue<string>,
    _value: PromiseOrValue<BigNumberish>,
    overrides?: PayableOverrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  "balanceOf(address)"(
    _owner: PromiseOrValue<string>,
    overrides?: CallOverrides
  ): Promise<BigNumber>;

  "balanceOf(uint256)"(
    _tokenId: PromiseOrValue<BigNumberish>,
    overrides?: CallOverrides
  ): Promise<BigNumber>;

  getApproved(
    _tokenId: PromiseOrValue<BigNumberish>,
    overrides?: CallOverrides
  ): Promise<string>;

  isApprovedForAll(
    _owner: PromiseOrValue<string>,
    _operator: PromiseOrValue<string>,
    overrides?: CallOverrides
  ): Promise<boolean>;

  ownerOf(
    _tokenId: PromiseOrValue<BigNumberish>,
    overrides?: CallOverrides
  ): Promise<string>;

  "safeTransferFrom(address,address,uint256)"(
    _from: PromiseOrValue<string>,
    _to: PromiseOrValue<string>,
    _tokenId: PromiseOrValue<BigNumberish>,
    overrides?: PayableOverrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  "safeTransferFrom(address,address,uint256,bytes)"(
    _from: PromiseOrValue<string>,
    _to: PromiseOrValue<string>,
    _tokenId: PromiseOrValue<BigNumberish>,
    data: PromiseOrValue<BytesLike>,
    overrides?: PayableOverrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  setApprovalForAll(
    _operator: PromiseOrValue<string>,
    _approved: PromiseOrValue<boolean>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  slotByIndex(
    _index: PromiseOrValue<BigNumberish>,
    overrides?: CallOverrides
  ): Promise<BigNumber>;

  slotCount(overrides?: CallOverrides): Promise<BigNumber>;

  slotOf(
    _tokenId: PromiseOrValue<BigNumberish>,
    overrides?: CallOverrides
  ): Promise<BigNumber>;

  supportsInterface(
    interfaceId: PromiseOrValue<BytesLike>,
    overrides?: CallOverrides
  ): Promise<boolean>;

  tokenByIndex(
    _index: PromiseOrValue<BigNumberish>,
    overrides?: CallOverrides
  ): Promise<BigNumber>;

  tokenInSlotByIndex(
    _slot: PromiseOrValue<BigNumberish>,
    _index: PromiseOrValue<BigNumberish>,
    overrides?: CallOverrides
  ): Promise<BigNumber>;

  tokenOfOwnerByIndex(
    _owner: PromiseOrValue<string>,
    _index: PromiseOrValue<BigNumberish>,
    overrides?: CallOverrides
  ): Promise<BigNumber>;

  tokenSupplyInSlot(
    _slot: PromiseOrValue<BigNumberish>,
    overrides?: CallOverrides
  ): Promise<BigNumber>;

  totalSupply(overrides?: CallOverrides): Promise<BigNumber>;

  "transferFrom(uint256,address,uint256)"(
    _fromTokenId: PromiseOrValue<BigNumberish>,
    _to: PromiseOrValue<string>,
    _value: PromiseOrValue<BigNumberish>,
    overrides?: PayableOverrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  "transferFrom(address,address,uint256)"(
    _from: PromiseOrValue<string>,
    _to: PromiseOrValue<string>,
    _tokenId: PromiseOrValue<BigNumberish>,
    overrides?: PayableOverrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  "transferFrom(uint256,uint256,uint256)"(
    _fromTokenId: PromiseOrValue<BigNumberish>,
    _toTokenId: PromiseOrValue<BigNumberish>,
    _value: PromiseOrValue<BigNumberish>,
    overrides?: PayableOverrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  valueDecimals(overrides?: CallOverrides): Promise<number>;

  callStatic: {
    allowance(
      _tokenId: PromiseOrValue<BigNumberish>,
      _operator: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    "approve(address,uint256)"(
      _approved: PromiseOrValue<string>,
      _tokenId: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<void>;

    "approve(uint256,address,uint256)"(
      _tokenId: PromiseOrValue<BigNumberish>,
      _operator: PromiseOrValue<string>,
      _value: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<void>;

    "balanceOf(address)"(
      _owner: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    "balanceOf(uint256)"(
      _tokenId: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    getApproved(
      _tokenId: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<string>;

    isApprovedForAll(
      _owner: PromiseOrValue<string>,
      _operator: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<boolean>;

    ownerOf(
      _tokenId: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<string>;

    "safeTransferFrom(address,address,uint256)"(
      _from: PromiseOrValue<string>,
      _to: PromiseOrValue<string>,
      _tokenId: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<void>;

    "safeTransferFrom(address,address,uint256,bytes)"(
      _from: PromiseOrValue<string>,
      _to: PromiseOrValue<string>,
      _tokenId: PromiseOrValue<BigNumberish>,
      data: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<void>;

    setApprovalForAll(
      _operator: PromiseOrValue<string>,
      _approved: PromiseOrValue<boolean>,
      overrides?: CallOverrides
    ): Promise<void>;

    slotByIndex(
      _index: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    slotCount(overrides?: CallOverrides): Promise<BigNumber>;

    slotOf(
      _tokenId: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    supportsInterface(
      interfaceId: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<boolean>;

    tokenByIndex(
      _index: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    tokenInSlotByIndex(
      _slot: PromiseOrValue<BigNumberish>,
      _index: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    tokenOfOwnerByIndex(
      _owner: PromiseOrValue<string>,
      _index: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    tokenSupplyInSlot(
      _slot: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    totalSupply(overrides?: CallOverrides): Promise<BigNumber>;

    "transferFrom(uint256,address,uint256)"(
      _fromTokenId: PromiseOrValue<BigNumberish>,
      _to: PromiseOrValue<string>,
      _value: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    "transferFrom(address,address,uint256)"(
      _from: PromiseOrValue<string>,
      _to: PromiseOrValue<string>,
      _tokenId: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<void>;

    "transferFrom(uint256,uint256,uint256)"(
      _fromTokenId: PromiseOrValue<BigNumberish>,
      _toTokenId: PromiseOrValue<BigNumberish>,
      _value: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<void>;

    valueDecimals(overrides?: CallOverrides): Promise<number>;
  };

  filters: {
    "Approval(address,address,uint256)"(
      _owner?: PromiseOrValue<string> | null,
      _approved?: PromiseOrValue<string> | null,
      _tokenId?: PromiseOrValue<BigNumberish> | null
    ): ApprovalEventFilter;
    Approval(
      _owner?: PromiseOrValue<string> | null,
      _approved?: PromiseOrValue<string> | null,
      _tokenId?: PromiseOrValue<BigNumberish> | null
    ): ApprovalEventFilter;

    "ApprovalForAll(address,address,bool)"(
      _owner?: PromiseOrValue<string> | null,
      _operator?: PromiseOrValue<string> | null,
      _approved?: null
    ): ApprovalForAllEventFilter;
    ApprovalForAll(
      _owner?: PromiseOrValue<string> | null,
      _operator?: PromiseOrValue<string> | null,
      _approved?: null
    ): ApprovalForAllEventFilter;

    "ApprovalValue(uint256,address,uint256)"(
      _tokenId?: PromiseOrValue<BigNumberish> | null,
      _operator?: PromiseOrValue<string> | null,
      _value?: null
    ): ApprovalValueEventFilter;
    ApprovalValue(
      _tokenId?: PromiseOrValue<BigNumberish> | null,
      _operator?: PromiseOrValue<string> | null,
      _value?: null
    ): ApprovalValueEventFilter;

    "SlotChanged(uint256,uint256,uint256)"(
      _tokenId?: PromiseOrValue<BigNumberish> | null,
      _oldSlot?: PromiseOrValue<BigNumberish> | null,
      _newSlot?: PromiseOrValue<BigNumberish> | null
    ): SlotChangedEventFilter;
    SlotChanged(
      _tokenId?: PromiseOrValue<BigNumberish> | null,
      _oldSlot?: PromiseOrValue<BigNumberish> | null,
      _newSlot?: PromiseOrValue<BigNumberish> | null
    ): SlotChangedEventFilter;

    "Transfer(address,address,uint256)"(
      _from?: PromiseOrValue<string> | null,
      _to?: PromiseOrValue<string> | null,
      _tokenId?: PromiseOrValue<BigNumberish> | null
    ): TransferEventFilter;
    Transfer(
      _from?: PromiseOrValue<string> | null,
      _to?: PromiseOrValue<string> | null,
      _tokenId?: PromiseOrValue<BigNumberish> | null
    ): TransferEventFilter;

    "TransferValue(uint256,uint256,uint256)"(
      _fromTokenId?: PromiseOrValue<BigNumberish> | null,
      _toTokenId?: PromiseOrValue<BigNumberish> | null,
      _value?: null
    ): TransferValueEventFilter;
    TransferValue(
      _fromTokenId?: PromiseOrValue<BigNumberish> | null,
      _toTokenId?: PromiseOrValue<BigNumberish> | null,
      _value?: null
    ): TransferValueEventFilter;
  };

  estimateGas: {
    allowance(
      _tokenId: PromiseOrValue<BigNumberish>,
      _operator: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    "approve(address,uint256)"(
      _approved: PromiseOrValue<string>,
      _tokenId: PromiseOrValue<BigNumberish>,
      overrides?: PayableOverrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    "approve(uint256,address,uint256)"(
      _tokenId: PromiseOrValue<BigNumberish>,
      _operator: PromiseOrValue<string>,
      _value: PromiseOrValue<BigNumberish>,
      overrides?: PayableOverrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    "balanceOf(address)"(
      _owner: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    "balanceOf(uint256)"(
      _tokenId: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    getApproved(
      _tokenId: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    isApprovedForAll(
      _owner: PromiseOrValue<string>,
      _operator: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    ownerOf(
      _tokenId: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    "safeTransferFrom(address,address,uint256)"(
      _from: PromiseOrValue<string>,
      _to: PromiseOrValue<string>,
      _tokenId: PromiseOrValue<BigNumberish>,
      overrides?: PayableOverrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    "safeTransferFrom(address,address,uint256,bytes)"(
      _from: PromiseOrValue<string>,
      _to: PromiseOrValue<string>,
      _tokenId: PromiseOrValue<BigNumberish>,
      data: PromiseOrValue<BytesLike>,
      overrides?: PayableOverrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    setApprovalForAll(
      _operator: PromiseOrValue<string>,
      _approved: PromiseOrValue<boolean>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    slotByIndex(
      _index: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    slotCount(overrides?: CallOverrides): Promise<BigNumber>;

    slotOf(
      _tokenId: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    supportsInterface(
      interfaceId: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    tokenByIndex(
      _index: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    tokenInSlotByIndex(
      _slot: PromiseOrValue<BigNumberish>,
      _index: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    tokenOfOwnerByIndex(
      _owner: PromiseOrValue<string>,
      _index: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    tokenSupplyInSlot(
      _slot: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    totalSupply(overrides?: CallOverrides): Promise<BigNumber>;

    "transferFrom(uint256,address,uint256)"(
      _fromTokenId: PromiseOrValue<BigNumberish>,
      _to: PromiseOrValue<string>,
      _value: PromiseOrValue<BigNumberish>,
      overrides?: PayableOverrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    "transferFrom(address,address,uint256)"(
      _from: PromiseOrValue<string>,
      _to: PromiseOrValue<string>,
      _tokenId: PromiseOrValue<BigNumberish>,
      overrides?: PayableOverrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    "transferFrom(uint256,uint256,uint256)"(
      _fromTokenId: PromiseOrValue<BigNumberish>,
      _toTokenId: PromiseOrValue<BigNumberish>,
      _value: PromiseOrValue<BigNumberish>,
      overrides?: PayableOverrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    valueDecimals(overrides?: CallOverrides): Promise<BigNumber>;
  };

  populateTransaction: {
    allowance(
      _tokenId: PromiseOrValue<BigNumberish>,
      _operator: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    "approve(address,uint256)"(
      _approved: PromiseOrValue<string>,
      _tokenId: PromiseOrValue<BigNumberish>,
      overrides?: PayableOverrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    "approve(uint256,address,uint256)"(
      _tokenId: PromiseOrValue<BigNumberish>,
      _operator: PromiseOrValue<string>,
      _value: PromiseOrValue<BigNumberish>,
      overrides?: PayableOverrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    "balanceOf(address)"(
      _owner: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    "balanceOf(uint256)"(
      _tokenId: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    getApproved(
      _tokenId: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    isApprovedForAll(
      _owner: PromiseOrValue<string>,
      _operator: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    ownerOf(
      _tokenId: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    "safeTransferFrom(address,address,uint256)"(
      _from: PromiseOrValue<string>,
      _to: PromiseOrValue<string>,
      _tokenId: PromiseOrValue<BigNumberish>,
      overrides?: PayableOverrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    "safeTransferFrom(address,address,uint256,bytes)"(
      _from: PromiseOrValue<string>,
      _to: PromiseOrValue<string>,
      _tokenId: PromiseOrValue<BigNumberish>,
      data: PromiseOrValue<BytesLike>,
      overrides?: PayableOverrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    setApprovalForAll(
      _operator: PromiseOrValue<string>,
      _approved: PromiseOrValue<boolean>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    slotByIndex(
      _index: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    slotCount(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    slotOf(
      _tokenId: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    supportsInterface(
      interfaceId: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    tokenByIndex(
      _index: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    tokenInSlotByIndex(
      _slot: PromiseOrValue<BigNumberish>,
      _index: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    tokenOfOwnerByIndex(
      _owner: PromiseOrValue<string>,
      _index: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    tokenSupplyInSlot(
      _slot: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    totalSupply(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    "transferFrom(uint256,address,uint256)"(
      _fromTokenId: PromiseOrValue<BigNumberish>,
      _to: PromiseOrValue<string>,
      _value: PromiseOrValue<BigNumberish>,
      overrides?: PayableOverrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    "transferFrom(address,address,uint256)"(
      _from: PromiseOrValue<string>,
      _to: PromiseOrValue<string>,
      _tokenId: PromiseOrValue<BigNumberish>,
      overrides?: PayableOverrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    "transferFrom(uint256,uint256,uint256)"(
      _fromTokenId: PromiseOrValue<BigNumberish>,
      _toTokenId: PromiseOrValue<BigNumberish>,
      _value: PromiseOrValue<BigNumberish>,
      overrides?: PayableOverrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    valueDecimals(overrides?: CallOverrides): Promise<PopulatedTransaction>;
  };
}
