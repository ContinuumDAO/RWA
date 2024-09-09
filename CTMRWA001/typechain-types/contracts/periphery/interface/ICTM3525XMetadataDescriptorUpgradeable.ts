/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import type {
  BaseContract,
  BigNumber,
  BigNumberish,
  BytesLike,
  CallOverrides,
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
} from "../../../common";

export interface ICTM3525XMetadataDescriptorUpgradeableInterface
  extends utils.Interface {
  functions: {
    "constructContractURI()": FunctionFragment;
    "constructSlotURI(uint256)": FunctionFragment;
    "constructTokenURI(uint256)": FunctionFragment;
  };

  getFunction(
    nameOrSignatureOrTopic:
      | "constructContractURI"
      | "constructSlotURI"
      | "constructTokenURI"
  ): FunctionFragment;

  encodeFunctionData(
    functionFragment: "constructContractURI",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "constructSlotURI",
    values: [PromiseOrValue<BigNumberish>]
  ): string;
  encodeFunctionData(
    functionFragment: "constructTokenURI",
    values: [PromiseOrValue<BigNumberish>]
  ): string;

  decodeFunctionResult(
    functionFragment: "constructContractURI",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "constructSlotURI",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "constructTokenURI",
    data: BytesLike
  ): Result;

  events: {};
}

export interface ICTM3525XMetadataDescriptorUpgradeable extends BaseContract {
  connect(signerOrProvider: Signer | Provider | string): this;
  attach(addressOrName: string): this;
  deployed(): Promise<this>;

  interface: ICTM3525XMetadataDescriptorUpgradeableInterface;

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
    constructContractURI(overrides?: CallOverrides): Promise<[string]>;

    constructSlotURI(
      slot: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<[string]>;

    constructTokenURI(
      tokenId: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<[string]>;
  };

  constructContractURI(overrides?: CallOverrides): Promise<string>;

  constructSlotURI(
    slot: PromiseOrValue<BigNumberish>,
    overrides?: CallOverrides
  ): Promise<string>;

  constructTokenURI(
    tokenId: PromiseOrValue<BigNumberish>,
    overrides?: CallOverrides
  ): Promise<string>;

  callStatic: {
    constructContractURI(overrides?: CallOverrides): Promise<string>;

    constructSlotURI(
      slot: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<string>;

    constructTokenURI(
      tokenId: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<string>;
  };

  filters: {};

  estimateGas: {
    constructContractURI(overrides?: CallOverrides): Promise<BigNumber>;

    constructSlotURI(
      slot: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    constructTokenURI(
      tokenId: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;
  };

  populateTransaction: {
    constructContractURI(
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    constructSlotURI(
      slot: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    constructTokenURI(
      tokenId: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;
  };
}