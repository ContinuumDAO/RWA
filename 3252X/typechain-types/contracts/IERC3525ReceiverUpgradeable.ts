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

export interface IERC3525ReceiverUpgradeableInterface extends utils.Interface {
  functions: {
    "onERC3525Received(address,uint256,uint256,uint256,bytes)": FunctionFragment;
  };

  getFunction(nameOrSignatureOrTopic: "onERC3525Received"): FunctionFragment;

  encodeFunctionData(
    functionFragment: "onERC3525Received",
    values: [
      PromiseOrValue<string>,
      PromiseOrValue<BigNumberish>,
      PromiseOrValue<BigNumberish>,
      PromiseOrValue<BigNumberish>,
      PromiseOrValue<BytesLike>
    ]
  ): string;

  decodeFunctionResult(
    functionFragment: "onERC3525Received",
    data: BytesLike
  ): Result;

  events: {};
}

export interface IERC3525ReceiverUpgradeable extends BaseContract {
  connect(signerOrProvider: Signer | Provider | string): this;
  attach(addressOrName: string): this;
  deployed(): Promise<this>;

  interface: IERC3525ReceiverUpgradeableInterface;

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
    onERC3525Received(
      _operator: PromiseOrValue<string>,
      _fromTokenId: PromiseOrValue<BigNumberish>,
      _toTokenId: PromiseOrValue<BigNumberish>,
      _value: PromiseOrValue<BigNumberish>,
      _data: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;
  };

  onERC3525Received(
    _operator: PromiseOrValue<string>,
    _fromTokenId: PromiseOrValue<BigNumberish>,
    _toTokenId: PromiseOrValue<BigNumberish>,
    _value: PromiseOrValue<BigNumberish>,
    _data: PromiseOrValue<BytesLike>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  callStatic: {
    onERC3525Received(
      _operator: PromiseOrValue<string>,
      _fromTokenId: PromiseOrValue<BigNumberish>,
      _toTokenId: PromiseOrValue<BigNumberish>,
      _value: PromiseOrValue<BigNumberish>,
      _data: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<string>;
  };

  filters: {};

  estimateGas: {
    onERC3525Received(
      _operator: PromiseOrValue<string>,
      _fromTokenId: PromiseOrValue<BigNumberish>,
      _toTokenId: PromiseOrValue<BigNumberish>,
      _value: PromiseOrValue<BigNumberish>,
      _data: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;
  };

  populateTransaction: {
    onERC3525Received(
      _operator: PromiseOrValue<string>,
      _fromTokenId: PromiseOrValue<BigNumberish>,
      _toTokenId: PromiseOrValue<BigNumberish>,
      _value: PromiseOrValue<BigNumberish>,
      _data: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;
  };
}
