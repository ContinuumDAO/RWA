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

export declare namespace C3CallerStructLib {
  export type C3EvmMessageStruct = {
    uuid: PromiseOrValue<BytesLike>;
    to: PromiseOrValue<string>;
    fromChainID: PromiseOrValue<string>;
    sourceTx: PromiseOrValue<string>;
    fallbackTo: PromiseOrValue<string>;
    data: PromiseOrValue<BytesLike>;
  };

  export type C3EvmMessageStructOutput = [
    string,
    string,
    string,
    string,
    string,
    string
  ] & {
    uuid: string;
    to: string;
    fromChainID: string;
    sourceTx: string;
    fallbackTo: string;
    data: string;
  };
}

export interface C3CallerInterface extends utils.Interface {
  functions: {
    "addOperator(address)": FunctionFragment;
    "applyGov()": FunctionFragment;
    "c3Fallback(uint256,address,(bytes32,address,string,string,string,bytes))": FunctionFragment;
    "c3broadcast(uint256,address,string[],string[],bytes)": FunctionFragment;
    "c3call(uint256,address,string,string,bytes,bytes)": FunctionFragment;
    "changeGov(address)": FunctionFragment;
    "context()": FunctionFragment;
    "execute(uint256,address,(bytes32,address,string,string,string,bytes))": FunctionFragment;
    "getAllOperators()": FunctionFragment;
    "gov()": FunctionFragment;
    "isOperator(address)": FunctionFragment;
    "operators(uint256)": FunctionFragment;
    "pause()": FunctionFragment;
    "paused()": FunctionFragment;
    "pendingGov()": FunctionFragment;
    "revokeOperator(address)": FunctionFragment;
    "unpause()": FunctionFragment;
    "uuidKeeper()": FunctionFragment;
  };

  getFunction(
    nameOrSignatureOrTopic:
      | "addOperator"
      | "applyGov"
      | "c3Fallback"
      | "c3broadcast"
      | "c3call"
      | "changeGov"
      | "context"
      | "execute"
      | "getAllOperators"
      | "gov"
      | "isOperator"
      | "operators"
      | "pause"
      | "paused"
      | "pendingGov"
      | "revokeOperator"
      | "unpause"
      | "uuidKeeper"
  ): FunctionFragment;

  encodeFunctionData(
    functionFragment: "addOperator",
    values: [PromiseOrValue<string>]
  ): string;
  encodeFunctionData(functionFragment: "applyGov", values?: undefined): string;
  encodeFunctionData(
    functionFragment: "c3Fallback",
    values: [
      PromiseOrValue<BigNumberish>,
      PromiseOrValue<string>,
      C3CallerStructLib.C3EvmMessageStruct
    ]
  ): string;
  encodeFunctionData(
    functionFragment: "c3broadcast",
    values: [
      PromiseOrValue<BigNumberish>,
      PromiseOrValue<string>,
      PromiseOrValue<string>[],
      PromiseOrValue<string>[],
      PromiseOrValue<BytesLike>
    ]
  ): string;
  encodeFunctionData(
    functionFragment: "c3call",
    values: [
      PromiseOrValue<BigNumberish>,
      PromiseOrValue<string>,
      PromiseOrValue<string>,
      PromiseOrValue<string>,
      PromiseOrValue<BytesLike>,
      PromiseOrValue<BytesLike>
    ]
  ): string;
  encodeFunctionData(
    functionFragment: "changeGov",
    values: [PromiseOrValue<string>]
  ): string;
  encodeFunctionData(functionFragment: "context", values?: undefined): string;
  encodeFunctionData(
    functionFragment: "execute",
    values: [
      PromiseOrValue<BigNumberish>,
      PromiseOrValue<string>,
      C3CallerStructLib.C3EvmMessageStruct
    ]
  ): string;
  encodeFunctionData(
    functionFragment: "getAllOperators",
    values?: undefined
  ): string;
  encodeFunctionData(functionFragment: "gov", values?: undefined): string;
  encodeFunctionData(
    functionFragment: "isOperator",
    values: [PromiseOrValue<string>]
  ): string;
  encodeFunctionData(
    functionFragment: "operators",
    values: [PromiseOrValue<BigNumberish>]
  ): string;
  encodeFunctionData(functionFragment: "pause", values?: undefined): string;
  encodeFunctionData(functionFragment: "paused", values?: undefined): string;
  encodeFunctionData(
    functionFragment: "pendingGov",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "revokeOperator",
    values: [PromiseOrValue<string>]
  ): string;
  encodeFunctionData(functionFragment: "unpause", values?: undefined): string;
  encodeFunctionData(
    functionFragment: "uuidKeeper",
    values?: undefined
  ): string;

  decodeFunctionResult(
    functionFragment: "addOperator",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "applyGov", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "c3Fallback", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "c3broadcast",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "c3call", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "changeGov", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "context", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "execute", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "getAllOperators",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "gov", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "isOperator", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "operators", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "pause", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "paused", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "pendingGov", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "revokeOperator",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "unpause", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "uuidKeeper", data: BytesLike): Result;

  events: {
    "ApplyGov(address,address,uint256)": EventFragment;
    "ChangeGov(address,address,uint256)": EventFragment;
    "Initialized(uint8)": EventFragment;
    "LogC3Call(uint256,bytes32,address,string,string,bytes,bytes)": EventFragment;
    "LogExecCall(uint256,address,bytes32,string,string,bytes,bool,bytes)": EventFragment;
    "LogExecFallback(uint256,address,bytes32,string,string,bytes,bytes)": EventFragment;
    "LogFallbackCall(uint256,bytes32,string,bytes,bytes)": EventFragment;
    "Paused(address)": EventFragment;
    "Unpaused(address)": EventFragment;
  };

  getEvent(nameOrSignatureOrTopic: "ApplyGov"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "ChangeGov"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "Initialized"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "LogC3Call"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "LogExecCall"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "LogExecFallback"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "LogFallbackCall"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "Paused"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "Unpaused"): EventFragment;
}

export interface ApplyGovEventObject {
  oldGov: string;
  newGov: string;
  timestamp: BigNumber;
}
export type ApplyGovEvent = TypedEvent<
  [string, string, BigNumber],
  ApplyGovEventObject
>;

export type ApplyGovEventFilter = TypedEventFilter<ApplyGovEvent>;

export interface ChangeGovEventObject {
  oldGov: string;
  newGov: string;
  timestamp: BigNumber;
}
export type ChangeGovEvent = TypedEvent<
  [string, string, BigNumber],
  ChangeGovEventObject
>;

export type ChangeGovEventFilter = TypedEventFilter<ChangeGovEvent>;

export interface InitializedEventObject {
  version: number;
}
export type InitializedEvent = TypedEvent<[number], InitializedEventObject>;

export type InitializedEventFilter = TypedEventFilter<InitializedEvent>;

export interface LogC3CallEventObject {
  dappID: BigNumber;
  uuid: string;
  caller: string;
  toChainID: string;
  to: string;
  data: string;
  extra: string;
}
export type LogC3CallEvent = TypedEvent<
  [BigNumber, string, string, string, string, string, string],
  LogC3CallEventObject
>;

export type LogC3CallEventFilter = TypedEventFilter<LogC3CallEvent>;

export interface LogExecCallEventObject {
  dappID: BigNumber;
  to: string;
  uuid: string;
  fromChainID: string;
  sourceTx: string;
  data: string;
  success: boolean;
  reason: string;
}
export type LogExecCallEvent = TypedEvent<
  [BigNumber, string, string, string, string, string, boolean, string],
  LogExecCallEventObject
>;

export type LogExecCallEventFilter = TypedEventFilter<LogExecCallEvent>;

export interface LogExecFallbackEventObject {
  dappID: BigNumber;
  to: string;
  uuid: string;
  fromChainID: string;
  sourceTx: string;
  data: string;
  reason: string;
}
export type LogExecFallbackEvent = TypedEvent<
  [BigNumber, string, string, string, string, string, string],
  LogExecFallbackEventObject
>;

export type LogExecFallbackEventFilter = TypedEventFilter<LogExecFallbackEvent>;

export interface LogFallbackCallEventObject {
  dappID: BigNumber;
  uuid: string;
  to: string;
  data: string;
  reasons: string;
}
export type LogFallbackCallEvent = TypedEvent<
  [BigNumber, string, string, string, string],
  LogFallbackCallEventObject
>;

export type LogFallbackCallEventFilter = TypedEventFilter<LogFallbackCallEvent>;

export interface PausedEventObject {
  account: string;
}
export type PausedEvent = TypedEvent<[string], PausedEventObject>;

export type PausedEventFilter = TypedEventFilter<PausedEvent>;

export interface UnpausedEventObject {
  account: string;
}
export type UnpausedEvent = TypedEvent<[string], UnpausedEventObject>;

export type UnpausedEventFilter = TypedEventFilter<UnpausedEvent>;

export interface C3Caller extends BaseContract {
  connect(signerOrProvider: Signer | Provider | string): this;
  attach(addressOrName: string): this;
  deployed(): Promise<this>;

  interface: C3CallerInterface;

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
    addOperator(
      _op: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    applyGov(
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    c3Fallback(
      _dappID: PromiseOrValue<BigNumberish>,
      _txSender: PromiseOrValue<string>,
      _message: C3CallerStructLib.C3EvmMessageStruct,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    c3broadcast(
      _dappID: PromiseOrValue<BigNumberish>,
      _caller: PromiseOrValue<string>,
      _to: PromiseOrValue<string>[],
      _toChainIDs: PromiseOrValue<string>[],
      _data: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    c3call(
      _dappID: PromiseOrValue<BigNumberish>,
      _caller: PromiseOrValue<string>,
      _to: PromiseOrValue<string>,
      _toChainID: PromiseOrValue<string>,
      _data: PromiseOrValue<BytesLike>,
      _extra: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    changeGov(
      _gov: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    context(
      overrides?: CallOverrides
    ): Promise<
      [string, string, string] & {
        swapID: string;
        fromChainID: string;
        sourceTx: string;
      }
    >;

    execute(
      _dappID: PromiseOrValue<BigNumberish>,
      _txSender: PromiseOrValue<string>,
      _message: C3CallerStructLib.C3EvmMessageStruct,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    getAllOperators(overrides?: CallOverrides): Promise<[string[]]>;

    gov(overrides?: CallOverrides): Promise<[string]>;

    isOperator(
      arg0: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<[boolean]>;

    operators(
      arg0: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<[string]>;

    pause(
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    paused(overrides?: CallOverrides): Promise<[boolean]>;

    pendingGov(overrides?: CallOverrides): Promise<[string]>;

    revokeOperator(
      _op: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    unpause(
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    uuidKeeper(overrides?: CallOverrides): Promise<[string]>;
  };

  addOperator(
    _op: PromiseOrValue<string>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  applyGov(
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  c3Fallback(
    _dappID: PromiseOrValue<BigNumberish>,
    _txSender: PromiseOrValue<string>,
    _message: C3CallerStructLib.C3EvmMessageStruct,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  c3broadcast(
    _dappID: PromiseOrValue<BigNumberish>,
    _caller: PromiseOrValue<string>,
    _to: PromiseOrValue<string>[],
    _toChainIDs: PromiseOrValue<string>[],
    _data: PromiseOrValue<BytesLike>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  c3call(
    _dappID: PromiseOrValue<BigNumberish>,
    _caller: PromiseOrValue<string>,
    _to: PromiseOrValue<string>,
    _toChainID: PromiseOrValue<string>,
    _data: PromiseOrValue<BytesLike>,
    _extra: PromiseOrValue<BytesLike>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  changeGov(
    _gov: PromiseOrValue<string>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  context(
    overrides?: CallOverrides
  ): Promise<
    [string, string, string] & {
      swapID: string;
      fromChainID: string;
      sourceTx: string;
    }
  >;

  execute(
    _dappID: PromiseOrValue<BigNumberish>,
    _txSender: PromiseOrValue<string>,
    _message: C3CallerStructLib.C3EvmMessageStruct,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  getAllOperators(overrides?: CallOverrides): Promise<string[]>;

  gov(overrides?: CallOverrides): Promise<string>;

  isOperator(
    arg0: PromiseOrValue<string>,
    overrides?: CallOverrides
  ): Promise<boolean>;

  operators(
    arg0: PromiseOrValue<BigNumberish>,
    overrides?: CallOverrides
  ): Promise<string>;

  pause(
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  paused(overrides?: CallOverrides): Promise<boolean>;

  pendingGov(overrides?: CallOverrides): Promise<string>;

  revokeOperator(
    _op: PromiseOrValue<string>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  unpause(
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  uuidKeeper(overrides?: CallOverrides): Promise<string>;

  callStatic: {
    addOperator(
      _op: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<void>;

    applyGov(overrides?: CallOverrides): Promise<void>;

    c3Fallback(
      _dappID: PromiseOrValue<BigNumberish>,
      _txSender: PromiseOrValue<string>,
      _message: C3CallerStructLib.C3EvmMessageStruct,
      overrides?: CallOverrides
    ): Promise<void>;

    c3broadcast(
      _dappID: PromiseOrValue<BigNumberish>,
      _caller: PromiseOrValue<string>,
      _to: PromiseOrValue<string>[],
      _toChainIDs: PromiseOrValue<string>[],
      _data: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<void>;

    c3call(
      _dappID: PromiseOrValue<BigNumberish>,
      _caller: PromiseOrValue<string>,
      _to: PromiseOrValue<string>,
      _toChainID: PromiseOrValue<string>,
      _data: PromiseOrValue<BytesLike>,
      _extra: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<void>;

    changeGov(
      _gov: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<void>;

    context(
      overrides?: CallOverrides
    ): Promise<
      [string, string, string] & {
        swapID: string;
        fromChainID: string;
        sourceTx: string;
      }
    >;

    execute(
      _dappID: PromiseOrValue<BigNumberish>,
      _txSender: PromiseOrValue<string>,
      _message: C3CallerStructLib.C3EvmMessageStruct,
      overrides?: CallOverrides
    ): Promise<void>;

    getAllOperators(overrides?: CallOverrides): Promise<string[]>;

    gov(overrides?: CallOverrides): Promise<string>;

    isOperator(
      arg0: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<boolean>;

    operators(
      arg0: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<string>;

    pause(overrides?: CallOverrides): Promise<void>;

    paused(overrides?: CallOverrides): Promise<boolean>;

    pendingGov(overrides?: CallOverrides): Promise<string>;

    revokeOperator(
      _op: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<void>;

    unpause(overrides?: CallOverrides): Promise<void>;

    uuidKeeper(overrides?: CallOverrides): Promise<string>;
  };

  filters: {
    "ApplyGov(address,address,uint256)"(
      oldGov?: PromiseOrValue<string> | null,
      newGov?: PromiseOrValue<string> | null,
      timestamp?: null
    ): ApplyGovEventFilter;
    ApplyGov(
      oldGov?: PromiseOrValue<string> | null,
      newGov?: PromiseOrValue<string> | null,
      timestamp?: null
    ): ApplyGovEventFilter;

    "ChangeGov(address,address,uint256)"(
      oldGov?: PromiseOrValue<string> | null,
      newGov?: PromiseOrValue<string> | null,
      timestamp?: null
    ): ChangeGovEventFilter;
    ChangeGov(
      oldGov?: PromiseOrValue<string> | null,
      newGov?: PromiseOrValue<string> | null,
      timestamp?: null
    ): ChangeGovEventFilter;

    "Initialized(uint8)"(version?: null): InitializedEventFilter;
    Initialized(version?: null): InitializedEventFilter;

    "LogC3Call(uint256,bytes32,address,string,string,bytes,bytes)"(
      dappID?: PromiseOrValue<BigNumberish> | null,
      uuid?: PromiseOrValue<BytesLike> | null,
      caller?: null,
      toChainID?: null,
      to?: null,
      data?: null,
      extra?: null
    ): LogC3CallEventFilter;
    LogC3Call(
      dappID?: PromiseOrValue<BigNumberish> | null,
      uuid?: PromiseOrValue<BytesLike> | null,
      caller?: null,
      toChainID?: null,
      to?: null,
      data?: null,
      extra?: null
    ): LogC3CallEventFilter;

    "LogExecCall(uint256,address,bytes32,string,string,bytes,bool,bytes)"(
      dappID?: PromiseOrValue<BigNumberish> | null,
      to?: PromiseOrValue<string> | null,
      uuid?: PromiseOrValue<BytesLike> | null,
      fromChainID?: null,
      sourceTx?: null,
      data?: null,
      success?: null,
      reason?: null
    ): LogExecCallEventFilter;
    LogExecCall(
      dappID?: PromiseOrValue<BigNumberish> | null,
      to?: PromiseOrValue<string> | null,
      uuid?: PromiseOrValue<BytesLike> | null,
      fromChainID?: null,
      sourceTx?: null,
      data?: null,
      success?: null,
      reason?: null
    ): LogExecCallEventFilter;

    "LogExecFallback(uint256,address,bytes32,string,string,bytes,bytes)"(
      dappID?: PromiseOrValue<BigNumberish> | null,
      to?: PromiseOrValue<string> | null,
      uuid?: PromiseOrValue<BytesLike> | null,
      fromChainID?: null,
      sourceTx?: null,
      data?: null,
      reason?: null
    ): LogExecFallbackEventFilter;
    LogExecFallback(
      dappID?: PromiseOrValue<BigNumberish> | null,
      to?: PromiseOrValue<string> | null,
      uuid?: PromiseOrValue<BytesLike> | null,
      fromChainID?: null,
      sourceTx?: null,
      data?: null,
      reason?: null
    ): LogExecFallbackEventFilter;

    "LogFallbackCall(uint256,bytes32,string,bytes,bytes)"(
      dappID?: PromiseOrValue<BigNumberish> | null,
      uuid?: PromiseOrValue<BytesLike> | null,
      to?: null,
      data?: null,
      reasons?: null
    ): LogFallbackCallEventFilter;
    LogFallbackCall(
      dappID?: PromiseOrValue<BigNumberish> | null,
      uuid?: PromiseOrValue<BytesLike> | null,
      to?: null,
      data?: null,
      reasons?: null
    ): LogFallbackCallEventFilter;

    "Paused(address)"(account?: null): PausedEventFilter;
    Paused(account?: null): PausedEventFilter;

    "Unpaused(address)"(account?: null): UnpausedEventFilter;
    Unpaused(account?: null): UnpausedEventFilter;
  };

  estimateGas: {
    addOperator(
      _op: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    applyGov(
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    c3Fallback(
      _dappID: PromiseOrValue<BigNumberish>,
      _txSender: PromiseOrValue<string>,
      _message: C3CallerStructLib.C3EvmMessageStruct,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    c3broadcast(
      _dappID: PromiseOrValue<BigNumberish>,
      _caller: PromiseOrValue<string>,
      _to: PromiseOrValue<string>[],
      _toChainIDs: PromiseOrValue<string>[],
      _data: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    c3call(
      _dappID: PromiseOrValue<BigNumberish>,
      _caller: PromiseOrValue<string>,
      _to: PromiseOrValue<string>,
      _toChainID: PromiseOrValue<string>,
      _data: PromiseOrValue<BytesLike>,
      _extra: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    changeGov(
      _gov: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    context(overrides?: CallOverrides): Promise<BigNumber>;

    execute(
      _dappID: PromiseOrValue<BigNumberish>,
      _txSender: PromiseOrValue<string>,
      _message: C3CallerStructLib.C3EvmMessageStruct,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    getAllOperators(overrides?: CallOverrides): Promise<BigNumber>;

    gov(overrides?: CallOverrides): Promise<BigNumber>;

    isOperator(
      arg0: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    operators(
      arg0: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    pause(
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    paused(overrides?: CallOverrides): Promise<BigNumber>;

    pendingGov(overrides?: CallOverrides): Promise<BigNumber>;

    revokeOperator(
      _op: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    unpause(
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    uuidKeeper(overrides?: CallOverrides): Promise<BigNumber>;
  };

  populateTransaction: {
    addOperator(
      _op: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    applyGov(
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    c3Fallback(
      _dappID: PromiseOrValue<BigNumberish>,
      _txSender: PromiseOrValue<string>,
      _message: C3CallerStructLib.C3EvmMessageStruct,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    c3broadcast(
      _dappID: PromiseOrValue<BigNumberish>,
      _caller: PromiseOrValue<string>,
      _to: PromiseOrValue<string>[],
      _toChainIDs: PromiseOrValue<string>[],
      _data: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    c3call(
      _dappID: PromiseOrValue<BigNumberish>,
      _caller: PromiseOrValue<string>,
      _to: PromiseOrValue<string>,
      _toChainID: PromiseOrValue<string>,
      _data: PromiseOrValue<BytesLike>,
      _extra: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    changeGov(
      _gov: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    context(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    execute(
      _dappID: PromiseOrValue<BigNumberish>,
      _txSender: PromiseOrValue<string>,
      _message: C3CallerStructLib.C3EvmMessageStruct,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    getAllOperators(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    gov(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    isOperator(
      arg0: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    operators(
      arg0: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    pause(
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    paused(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    pendingGov(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    revokeOperator(
      _op: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    unpause(
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    uuidKeeper(overrides?: CallOverrides): Promise<PopulatedTransaction>;
  };
}