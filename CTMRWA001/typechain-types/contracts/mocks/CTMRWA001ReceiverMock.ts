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

export interface CTMRWA001ReceiverMockInterface extends utils.Interface {
  functions: {
    "onCTMRWA001Received(address,uint256,uint256,uint256,bytes)": FunctionFragment;
    "supportsInterface(bytes4)": FunctionFragment;
  };

  getFunction(
    nameOrSignatureOrTopic: "onCTMRWA001Received" | "supportsInterface"
  ): FunctionFragment;

  encodeFunctionData(
    functionFragment: "onCTMRWA001Received",
    values: [
      PromiseOrValue<string>,
      PromiseOrValue<BigNumberish>,
      PromiseOrValue<BigNumberish>,
      PromiseOrValue<BigNumberish>,
      PromiseOrValue<BytesLike>
    ]
  ): string;
  encodeFunctionData(
    functionFragment: "supportsInterface",
    values: [PromiseOrValue<BytesLike>]
  ): string;

  decodeFunctionResult(
    functionFragment: "onCTMRWA001Received",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "supportsInterface",
    data: BytesLike
  ): Result;

  events: {
    "Received(address,uint256,uint256,uint256,bytes,uint256)": EventFragment;
  };

  getEvent(nameOrSignatureOrTopic: "Received"): EventFragment;
}

export interface ReceivedEventObject {
  operator: string;
  fromTokenId: BigNumber;
  toTokenId: BigNumber;
  value: BigNumber;
  data: string;
  gas: BigNumber;
}
export type ReceivedEvent = TypedEvent<
  [string, BigNumber, BigNumber, BigNumber, string, BigNumber],
  ReceivedEventObject
>;

export type ReceivedEventFilter = TypedEventFilter<ReceivedEvent>;

export interface CTMRWA001ReceiverMock extends BaseContract {
  connect(signerOrProvider: Signer | Provider | string): this;
  attach(addressOrName: string): this;
  deployed(): Promise<this>;

  interface: CTMRWA001ReceiverMockInterface;

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
    onCTMRWA001Received(
      operator: PromiseOrValue<string>,
      fromTokenId: PromiseOrValue<BigNumberish>,
      toTokenId: PromiseOrValue<BigNumberish>,
      value: PromiseOrValue<BigNumberish>,
      data: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    supportsInterface(
      interfaceId: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<[boolean]>;
  };

  onCTMRWA001Received(
    operator: PromiseOrValue<string>,
    fromTokenId: PromiseOrValue<BigNumberish>,
    toTokenId: PromiseOrValue<BigNumberish>,
    value: PromiseOrValue<BigNumberish>,
    data: PromiseOrValue<BytesLike>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  supportsInterface(
    interfaceId: PromiseOrValue<BytesLike>,
    overrides?: CallOverrides
  ): Promise<boolean>;

  callStatic: {
    onCTMRWA001Received(
      operator: PromiseOrValue<string>,
      fromTokenId: PromiseOrValue<BigNumberish>,
      toTokenId: PromiseOrValue<BigNumberish>,
      value: PromiseOrValue<BigNumberish>,
      data: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<string>;

    supportsInterface(
      interfaceId: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<boolean>;
  };

  filters: {
    "Received(address,uint256,uint256,uint256,bytes,uint256)"(
      operator?: null,
      fromTokenId?: null,
      toTokenId?: null,
      value?: null,
      data?: null,
      gas?: null
    ): ReceivedEventFilter;
    Received(
      operator?: null,
      fromTokenId?: null,
      toTokenId?: null,
      value?: null,
      data?: null,
      gas?: null
    ): ReceivedEventFilter;
  };

  estimateGas: {
    onCTMRWA001Received(
      operator: PromiseOrValue<string>,
      fromTokenId: PromiseOrValue<BigNumberish>,
      toTokenId: PromiseOrValue<BigNumberish>,
      value: PromiseOrValue<BigNumberish>,
      data: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    supportsInterface(
      interfaceId: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;
  };

  populateTransaction: {
    onCTMRWA001Received(
      operator: PromiseOrValue<string>,
      fromTokenId: PromiseOrValue<BigNumberish>,
      toTokenId: PromiseOrValue<BigNumberish>,
      value: PromiseOrValue<BigNumberish>,
      data: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    supportsInterface(
      interfaceId: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;
  };
}
