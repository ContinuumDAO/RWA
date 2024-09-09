/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import {
  Signer,
  utils,
  Contract,
  ContractFactory,
  BigNumberish,
  Overrides,
} from "ethers";
import type { Provider, TransactionRequest } from "@ethersproject/providers";
import type { PromiseOrValue } from "../../common";
import type { CTM3525X, CTM3525XInterface } from "../../contracts/CTM3525X";

const _abi = [
  {
    inputs: [
      {
        internalType: "string",
        name: "name_",
        type: "string",
      },
      {
        internalType: "string",
        name: "symbol_",
        type: "string",
      },
      {
        internalType: "uint8",
        name: "decimals_",
        type: "uint8",
      },
    ],
    stateMutability: "nonpayable",
    type: "constructor",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "_owner",
        type: "address",
      },
      {
        indexed: true,
        internalType: "address",
        name: "_approved",
        type: "address",
      },
      {
        indexed: true,
        internalType: "uint256",
        name: "_tokenId",
        type: "uint256",
      },
    ],
    name: "Approval",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "_owner",
        type: "address",
      },
      {
        indexed: true,
        internalType: "address",
        name: "_operator",
        type: "address",
      },
      {
        indexed: false,
        internalType: "bool",
        name: "_approved",
        type: "bool",
      },
    ],
    name: "ApprovalForAll",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "uint256",
        name: "_tokenId",
        type: "uint256",
      },
      {
        indexed: true,
        internalType: "address",
        name: "_operator",
        type: "address",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "_value",
        type: "uint256",
      },
    ],
    name: "ApprovalValue",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "metadataDescriptor",
        type: "address",
      },
    ],
    name: "SetMetadataDescriptor",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "uint256",
        name: "_tokenId",
        type: "uint256",
      },
      {
        indexed: true,
        internalType: "uint256",
        name: "_oldSlot",
        type: "uint256",
      },
      {
        indexed: true,
        internalType: "uint256",
        name: "_newSlot",
        type: "uint256",
      },
    ],
    name: "SlotChanged",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "_from",
        type: "address",
      },
      {
        indexed: true,
        internalType: "address",
        name: "_to",
        type: "address",
      },
      {
        indexed: true,
        internalType: "uint256",
        name: "_tokenId",
        type: "uint256",
      },
    ],
    name: "Transfer",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "uint256",
        name: "_fromTokenId",
        type: "uint256",
      },
      {
        indexed: true,
        internalType: "uint256",
        name: "_toTokenId",
        type: "uint256",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "_value",
        type: "uint256",
      },
    ],
    name: "TransferValue",
    type: "event",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "tokenId_",
        type: "uint256",
      },
      {
        internalType: "address",
        name: "operator_",
        type: "address",
      },
    ],
    name: "allowance",
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
        name: "to_",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "tokenId_",
        type: "uint256",
      },
    ],
    name: "approve",
    outputs: [],
    stateMutability: "payable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "tokenId_",
        type: "uint256",
      },
      {
        internalType: "address",
        name: "to_",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "value_",
        type: "uint256",
      },
    ],
    name: "approve",
    outputs: [],
    stateMutability: "payable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "owner_",
        type: "address",
      },
    ],
    name: "balanceOf",
    outputs: [
      {
        internalType: "uint256",
        name: "balance",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "tokenId_",
        type: "uint256",
      },
    ],
    name: "balanceOf",
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
    name: "contractURI",
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
        name: "tokenId_",
        type: "uint256",
      },
    ],
    name: "getApproved",
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
        internalType: "address",
        name: "owner_",
        type: "address",
      },
      {
        internalType: "address",
        name: "operator_",
        type: "address",
      },
    ],
    name: "isApprovedForAll",
    outputs: [
      {
        internalType: "bool",
        name: "",
        type: "bool",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "metadataDescriptor",
    outputs: [
      {
        internalType: "contract ICTM3525XMetadataDescriptor",
        name: "",
        type: "address",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "name",
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
        name: "tokenId_",
        type: "uint256",
      },
    ],
    name: "ownerOf",
    outputs: [
      {
        internalType: "address",
        name: "owner_",
        type: "address",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "from_",
        type: "address",
      },
      {
        internalType: "address",
        name: "to_",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "tokenId_",
        type: "uint256",
      },
    ],
    name: "safeTransferFrom",
    outputs: [],
    stateMutability: "payable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "from_",
        type: "address",
      },
      {
        internalType: "address",
        name: "to_",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "tokenId_",
        type: "uint256",
      },
      {
        internalType: "bytes",
        name: "data_",
        type: "bytes",
      },
    ],
    name: "safeTransferFrom",
    outputs: [],
    stateMutability: "payable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "operator_",
        type: "address",
      },
      {
        internalType: "bool",
        name: "approved_",
        type: "bool",
      },
    ],
    name: "setApprovalForAll",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "tokenId_",
        type: "uint256",
      },
    ],
    name: "slotOf",
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
        internalType: "uint256",
        name: "slot_",
        type: "uint256",
      },
    ],
    name: "slotURI",
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
        internalType: "bytes4",
        name: "interfaceId",
        type: "bytes4",
      },
    ],
    name: "supportsInterface",
    outputs: [
      {
        internalType: "bool",
        name: "",
        type: "bool",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "symbol",
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
        name: "index_",
        type: "uint256",
      },
    ],
    name: "tokenByIndex",
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
        name: "owner_",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "index_",
        type: "uint256",
      },
    ],
    name: "tokenOfOwnerByIndex",
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
        internalType: "uint256",
        name: "tokenId_",
        type: "uint256",
      },
    ],
    name: "tokenURI",
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
    inputs: [],
    name: "totalSupply",
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
        internalType: "uint256",
        name: "fromTokenId_",
        type: "uint256",
      },
      {
        internalType: "address",
        name: "to_",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "value_",
        type: "uint256",
      },
    ],
    name: "transferFrom",
    outputs: [
      {
        internalType: "uint256",
        name: "newTokenId",
        type: "uint256",
      },
    ],
    stateMutability: "payable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "from_",
        type: "address",
      },
      {
        internalType: "address",
        name: "to_",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "tokenId_",
        type: "uint256",
      },
    ],
    name: "transferFrom",
    outputs: [],
    stateMutability: "payable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "fromTokenId_",
        type: "uint256",
      },
      {
        internalType: "uint256",
        name: "toTokenId_",
        type: "uint256",
      },
      {
        internalType: "uint256",
        name: "value_",
        type: "uint256",
      },
    ],
    name: "transferFrom",
    outputs: [],
    stateMutability: "payable",
    type: "function",
  },
  {
    inputs: [],
    name: "valueDecimals",
    outputs: [
      {
        internalType: "uint8",
        name: "",
        type: "uint8",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
] as const;

const _bytecode =
  "0x60806040523480156200001157600080fd5b5060405162002f2c38038062002f2c833981016040819052620000349162000139565b600160035560006200004784826200024d565b5060016200005683826200024d565b506002805460ff191660ff9290921691909117905550620003199050565b634e487b7160e01b600052604160045260246000fd5b600082601f8301126200009c57600080fd5b81516001600160401b0380821115620000b957620000b962000074565b604051601f8301601f19908116603f01168101908282118183101715620000e457620000e462000074565b816040528381526020925086838588010111156200010157600080fd5b600091505b8382101562000125578582018301518183018401529082019062000106565b600093810190920192909252949350505050565b6000806000606084860312156200014f57600080fd5b83516001600160401b03808211156200016757600080fd5b62000175878388016200008a565b945060208601519150808211156200018c57600080fd5b506200019b868287016200008a565b925050604084015160ff81168114620001b357600080fd5b809150509250925092565b600181811c90821680620001d357607f821691505b602082108103620001f457634e487b7160e01b600052602260045260246000fd5b50919050565b601f8211156200024857600081815260208120601f850160051c81016020861015620002235750805b601f850160051c820191505b8181101562000244578281556001016200022f565b5050505b505050565b81516001600160401b0381111562000269576200026962000074565b62000281816200027a8454620001be565b84620001fa565b602080601f831160018114620002b95760008415620002a05750858301515b600019600386901b1c1916600185901b17855562000244565b600085815260208120601f198616915b82811015620002ea57888601518255948401946001909101908401620002c9565b5085821015620003095787850151600019600388901b60f8161c191681555b5050505050600190811b01905550565b612c0380620003296000396000f3fe6080604052600436106101815760003560e01c80634f6ccce7116100d15780639cc7f7081161008a578063c87b56dd11610064578063c87b56dd14610416578063e345e0bc14610436578063e8a3d48514610456578063e985e9c51461046b57600080fd5b80639cc7f708146103c3578063a22cb465146103e3578063b88d4fde1461040357600080fd5b80634f6ccce71461031b5780636352211e1461033b57806370a082311461035b578063840f71131461037b5780638cb0a5111461039b57806395d89b41146103ae57600080fd5b806318160ddd1161013e5780632f745c59116101185780632f745c59146102b3578063310ed7f0146102d35780633e7e8669146102e657806342842e0e1461030857600080fd5b806318160ddd1461026b57806323b872dd14610280578063263f3e7e1461029357600080fd5b806301ffc9a71461018657806306fdde03146101bb578063081812fc146101dd578063095ea7b31461021557806309c3dd871461022a5780630f485c021461024a575b600080fd5b34801561019257600080fd5b506101a66101a1366004612538565b6104b8565b60405190151581526020015b60405180910390f35b3480156101c757600080fd5b506101d061055b565b6040516101b291906125a5565b3480156101e957600080fd5b506101fd6101f83660046125b8565b6105ed565b6040516001600160a01b0390911681526020016101b2565b6102286102233660046125e8565b61063f565b005b34801561023657600080fd5b506101d06102453660046125b8565b610723565b61025d610258366004612612565b610815565b6040519081526020016101b2565b34801561027757600080fd5b5060055461025d565b61022861028e366004612647565b61084d565b34801561029f57600080fd5b5061025d6102ae3660046125b8565b61087e565b3480156102bf57600080fd5b5061025d6102ce3660046125e8565b6108c6565b6102286102e1366004612673565b610968565b3480156102f257600080fd5b5060025460405160ff90911681526020016101b2565b610228610316366004612647565b61097e565b34801561032757600080fd5b5061025d6103363660046125b8565b610999565b34801561034757600080fd5b506101fd6103563660046125b8565b610a2a565b34801561036757600080fd5b5061025d61037636600461269f565b610aca565b34801561038757600080fd5b506008546101fd906001600160a01b031681565b6102286103a9366004612612565b610b53565b3480156103ba57600080fd5b506101d0610c13565b3480156103cf57600080fd5b5061025d6103de3660046125b8565b610c22565b3480156103ef57600080fd5b506102286103fe3660046126c8565b610c6a565b61022861041136600461276e565b610c79565b34801561042257600080fd5b506101d06104313660046125b8565b610cab565b34801561044257600080fd5b5061025d610451366004612819565b610d4a565b34801561046257600080fd5b506101d0610d7e565b34801561047757600080fd5b506101a6610486366004612845565b6001600160a01b0391821660009081526007602090815260408083209390941682526002909201909152205460ff1690565b60006001600160e01b031982166301ffc9a760e01b14806104e957506001600160e01b03198216630354d60560e61b145b8061050457506001600160e01b031982166380ac58cd60e01b145b8061051f57506001600160e01b031982166370b0048160e11b145b8061053a57506001600160e01b0319821663780e9d6360e01b145b8061055557506001600160e01b03198216635b5e139f60e01b145b92915050565b60606000805461056a9061286f565b80601f01602080910402602001604051908101604052809291908181526020018280546105969061286f565b80156105e35780601f106105b8576101008083540402835291602001916105e3565b820191906000526020600020905b8154815290600101906020018083116105c657829003601f168201915b5050505050905090565b60006105f882610e78565b60008281526006602052604090205460058054909190811061061c5761061c6128a9565b60009182526020909120600460069092020101546001600160a01b031692915050565b600061064a82610a2a565b9050806001600160a01b0316836001600160a01b0316036106865760405162461bcd60e51b815260040161067d906128bf565b60405180910390fd5b336001600160a01b03821614806106a257506106a28133610486565b6107145760405162461bcd60e51b815260206004820152603a60248201527f43544d33353235583a20617070726f76652063616c6c6572206973206e6f742060448201527f6f776e6572206e6f7220617070726f76656420666f7220616c6c000000000000606482015260840161067d565b61071e8383610ed0565b505050565b6060600061073c60408051602081019091526000815290565b6008549091506001600160a01b031661079c57600081511161076d576040518060200160405280600081525061080e565b8061077784610f67565b604051602001610788929190612902565b60405160208183030381529060405261080e565b600854604051633601bfc560e11b8152600481018590526001600160a01b0390911690636c037f8a906024015b600060405180830381865afa1580156107e6573d6000803e3d6000fd5b505050506040513d6000823e601f3d908101601f1916820160405261080e9190810190612942565b9392505050565b6000610822338584610ffa565b61082b8461108a565b9050610842838261083b8761087e565b6000611094565b61080e8482846111c0565b61085733826114be565b6108735760405162461bcd60e51b815260040161067d906129b9565b61071e838383611541565b600061088982610e78565b6000828152600660205260409020546005805490919081106108ad576108ad6128a9565b9060005260206000209060060201600101549050919050565b60006108d183610aca565b821061092b5760405162461bcd60e51b815260206004820152602360248201527f43544d33353235583a206f776e657220696e646578206f7574206f6620626f756044820152626e647360e81b606482015260840161067d565b6001600160a01b0383166000908152600760205260409020805483908110610955576109556128a9565b9060005260206000200154905092915050565b610973338483610ffa565b61071e8383836111c0565b61071e83838360405180602001604052806000815250610c79565b60006109a460055490565b82106109fe5760405162461bcd60e51b8152602060048201526024808201527f43544d33353235583a20676c6f62616c20696e646578206f7574206f6620626f604482015263756e647360e01b606482015260840161067d565b60058281548110610a1157610a116128a9565b9060005260206000209060060201600001549050919050565b6000610a3582610e78565b600082815260066020526040902054600580549091908110610a5957610a596128a9565b60009182526020909120600360069092020101546001600160a01b0316905080610ac55760405162461bcd60e51b815260206004820152601a60248201527f43544d33353235583a20696e76616c696420746f6b656e204944000000000000604482015260640161067d565b919050565b60006001600160a01b038216610b375760405162461bcd60e51b815260206004820152602c60248201527f43544d33353235583a2062616c616e636520717565727920666f72207468652060448201526b7a65726f206164647265737360a01b606482015260840161067d565b506001600160a01b031660009081526007602052604090205490565b6000610b5e84610a2a565b9050806001600160a01b0316836001600160a01b031603610b915760405162461bcd60e51b815260040161067d906128bf565b610b9b33856114be565b610c025760405162461bcd60e51b815260206004820152603260248201527f43544d33353235583a20617070726f76652063616c6c6572206973206e6f74206044820152711bdddb995c881b9bdc88185c1c1c9bdd995960721b606482015260840161067d565b610c0d8484846116a5565b50505050565b60606001805461056a9061286f565b6000610c2d82610e78565b600082815260066020526040902054600580549091908110610c5157610c516128a9565b9060005260206000209060060201600201549050919050565b610c753383836117de565b5050565b610c8333836114be565b610c9f5760405162461bcd60e51b815260040161067d906129b9565b610c0d848484846118a8565b6060610cb682610e78565b6000610ccd60408051602081019091526000815290565b6008549091506001600160a01b0316610d19576000815111610cfe576040518060200160405280600081525061080e565b80610d0884610f67565b604051602001610788929190612a0c565b6008546040516344a5a61760e11b8152600481018590526001600160a01b039091169063894b4c2e906024016107c9565b6000610d5583610e78565b5060009182526004602090815260408084206001600160a01b0393909316845291905290205490565b60606000610d9760408051602081019091526000815290565b6008549091506001600160a01b0316610df7576000815111610dc85760405180602001604052806000815250610e72565b80610dd23061191c565b604051602001610de3929190612a3b565b604051602081830303815290604052610e72565b600860009054906101000a90046001600160a01b03166001600160a01b031663725fa09c6040518163ffffffff1660e01b8152600401600060405180830381865afa158015610e4a573d6000803e3d6000fd5b505050506040513d6000823e601f3d908101601f19168201604052610e729190810190612942565b91505090565b610e8181611932565b610ecd5760405162461bcd60e51b815260206004820152601a60248201527f43544d33353235583a20696e76616c696420746f6b656e204944000000000000604482015260640161067d565b50565b600081815260066020526040902054600580548492908110610ef457610ef46128a9565b6000918252602090912060069091020160040180546001600160a01b0319166001600160a01b0392831617905581908316610f2e82610a2a565b6001600160a01b03167f8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b92560405160405180910390a45050565b60606000610f748361197e565b600101905060008167ffffffffffffffff811115610f9457610f946126ff565b6040519080825280601f01601f191660200182016040528015610fbe576020820181803683370190505b5090508181016020015b600019016f181899199a1a9b1b9c1cb0b131b232b360811b600a86061a8153600a8504945084610fc857509392505050565b60006110068385610d4a565b905061101284846114be565b15801561102157506000198114155b15610c0d57818110156110765760405162461bcd60e51b815260206004820181905260248201527f43544d33353235583a20696e73756666696369656e7420616c6c6f77616e6365604482015260640161067d565b610c0d83856110858585612a95565b6116a5565b6000610555611a56565b6001600160a01b0384166110f55760405162461bcd60e51b815260206004820152602260248201527f43544d33353235583a206d696e7420746f20746865207a65726f206164647265604482015261737360f01b606482015260840161067d565b826000036111505760405162461bcd60e51b815260206004820152602260248201527f43544d33353235583a2063616e6e6f74206d696e74207a65726f20746f6b656e604482015261125960f21b606482015260840161067d565b61115983611932565b156111a65760405162461bcd60e51b815260206004820152601e60248201527f43544d33353235583a20746f6b656e20616c7265616479206d696e7465640000604482015260640161067d565b6111b1848484611a70565b6111bb8382611b36565b610c0d565b6111c983611932565b6112265760405162461bcd60e51b815260206004820152602860248201527f43544d33353235583a207472616e736665722066726f6d20696e76616c6964206044820152671d1bdad95b88125160c21b606482015260840161067d565b61122f82611932565b61128a5760405162461bcd60e51b815260206004820152602660248201527f43544d33353235583a207472616e7366657220746f20696e76616c696420746f6044820152651ad95b88125160d21b606482015260840161067d565b6000838152600660205260408120546005805490919081106112ae576112ae6128a9565b90600052602060002090600602019050600060056006600086815260200190815260200160002054815481106112e6576112e66128a9565b90600052602060002090600602019050828260020154101561135e5760405162461bcd60e51b815260206004820152602b60248201527f43544d33353235583a20696e73756666696369656e742062616c616e6365206660448201526a37b9103a3930b739b332b960a91b606482015260840161067d565b80600101548260010154146113cd5760405162461bcd60e51b815260206004820152602f60248201527f43544d33353235583a207472616e7366657220746f20746f6b656e207769746860448201526e08191a5999995c995b9d081cdb1bdd608a1b606482015260840161067d565b828260020160008282546113e19190612a95565b92505081905550828160020160008282546113fc9190612aa8565b9091555050604051838152849086907f0b2aac84f3ec956911fd78eae5311062972ff949f38412e8da39069d9f068cc69060200160405180910390a361145385858560405180602001604052806000815250611bbb565b6114b75760405162461bcd60e51b815260206004820152602f60248201527f43544d33353235583a207472616e736665722072656a6563746564206279204360448201526e2a26999a991aac2932b1b2b4bb32b960891b606482015260840161067d565b5050505050565b6000806114ca83610a2a565b9050806001600160a01b0316846001600160a01b0316148061151557506001600160a01b038082166000908152600760209081526040808320938816835260029093019052205460ff165b806115395750836001600160a01b031661152e846105ed565b6001600160a01b0316145b949350505050565b826001600160a01b031661155482610a2a565b6001600160a01b0316146115b85760405162461bcd60e51b815260206004820152602560248201527f43544d33353235583a207472616e736665722066726f6d20696e76616c69642060448201526437bbb732b960d91b606482015260840161067d565b6001600160a01b03821661161d5760405162461bcd60e51b815260206004820152602660248201527f43544d33353235583a207472616e7366657220746f20746865207a65726f206160448201526564647265737360d01b606482015260840161067d565b60006116288261087e565b9050600061163583610c22565b9050611642600084610ed0565b61164b83611d31565b6116558584611ddc565b61165f8484611efd565b82846001600160a01b0316866001600160a01b03167fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef60405160405180910390a46114b7565b6001600160a01b03821661170f5760405162461bcd60e51b815260206004820152602b60248201527f43544d33353235583a20617070726f76652076616c756520746f20746865207a60448201526a65726f206164647265737360a81b606482015260840161067d565b6117198284611f86565b61177f57600083815260066020526040902054600580549091908110611741576117416128a9565b60009182526020808320600692909202909101600501805460018101825590835291200180546001600160a01b0319166001600160a01b0384161790555b60008381526004602090815260408083206001600160a01b038616808552908352928190208490555183815285917f621b050de0ad08b51d19b48b3e6df75348c4de6bdd93e81b252ca62e28265b1b91015b60405180910390a3505050565b816001600160a01b0316836001600160a01b03160361183f5760405162461bcd60e51b815260206004820152601b60248201527f43544d33353235583a20617070726f766520746f2063616c6c65720000000000604482015260640161067d565b6001600160a01b0383811660008181526007602090815260408083209487168084526002909501825291829020805460ff191686151590811790915591519182527f17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c3191016117d1565b6118b3848484611541565b6118bf84848484612059565b610c0d5760405162461bcd60e51b815260206004820152602860248201527f43544d33353235583a207472616e7366657220746f206e6f6e204552433732316044820152672932b1b2b4bb32b960c11b606482015260840161067d565b60606105556001600160a01b038316601461219f565b600554600090158015906105555750600082815260066020526040902054600580548492908110611965576119656128a9565b9060005260206000209060060201600001541492915050565b60008072184f03e93ff9f4daa797ed6e38ed64bf6a1f0160401b83106119bd5772184f03e93ff9f4daa797ed6e38ed64bf6a1f0160401b830492506040015b6d04ee2d6d415b85acef810000000083106119e9576d04ee2d6d415b85acef8100000000830492506020015b662386f26fc100008310611a0757662386f26fc10000830492506010015b6305f5e1008310611a1f576305f5e100830492506008015b6127108310611a3357612710830492506004015b60648310611a45576064830492506002015b600a83106105555760010192915050565b6003805460009182611a6783612abb565b91905055905090565b6040805160c081018252838152602080820184905260008284018190526001600160a01b038716606084015260808301819052835181815291820190935260a08201529050611abe8161233b565b611ac88484611efd565b60405183906001600160a01b038616906000907fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef908290a4816000847fe4f48c240d3b994948aa54f3e2f5fca59263dfe1d52b6e4cf39a5d249b5ccb6560405160405180910390a450505050565b600082815260066020526040902054600580548392908110611b5a57611b5a6128a9565b90600052602060002090600602016002016000828254611b7a9190612aa8565b909155505060405181815282906000907f0b2aac84f3ec956911fd78eae5311062972ff949f38412e8da39069d9f068cc69060200160405180910390a35050565b600080611bc785610a2a565b9050803b63ffffffff1615611d25576040516301ffc9a760e01b81526301e9d27f60e31b60048201526001600160a01b038216906301ffc9a790602401602060405180830381865afa925050508015611c3d575060408051601f3d908101601f19168201909252611c3a91810190612ad4565b60015b611c7c573d808015611c6b576040519150601f19603f3d011682016040523d82523d6000602084013e611c70565b606091505b50600192505050611539565b8015611d1a576040516301e9d27f60e31b81526000906001600160a01b03841690630f4e93f890611cb99033908c908c908c908c90600401612af1565b6020604051808303816000875af1158015611cd8573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190611cfc9190612b2f565b6001600160e01b0319166301e9d27f60e31b14935061153992505050565b600192505050611539565b50600195945050505050565b600081815260066020526040812054600580549091908110611d5557611d556128a9565b600091825260208220600560069092020190810154909250905b81811015611dcd576000836005018281548110611d8e57611d8e6128a9565b60009182526020808320909101548783526004825260408084206001600160a01b03909216845291528120555080611dc581612abb565b915050611d6f565b5061071e60058301600061248a565b600081815260066020526040812054600580549091908110611e0057611e006128a9565b6000918252602080832060069290920290910160030180546001600160a01b0319166001600160a01b0394851617905591841681526007909152604081208054909190611e4f90600190612a95565b90506000826000018281548110611e6857611e686128a9565b90600052602060002001549050600083600101600086815260200190815260200160002054905081846000018281548110611ea557611ea56128a9565b60009182526020808320909101929092558381526001860190915260408082208390558682528120558354849080611edf57611edf612b4c565b60019003818190600052602060002001600090559055505050505050565b600081815260066020526040902054600580548492908110611f2157611f216128a9565b6000918252602080832060069290920290910160030180546001600160a01b0319166001600160a01b03948516179055939091168152600780845260408083208054858552600182810188529285208190559286529082018155825292902090910155565b600081815260066020526040812054600580548392908110611faa57611faa6128a9565b6000918252602082206005600690920201015491505b8181101561204e57600084815260066020526040902054600580546001600160a01b03881692908110611ff557611ff56128a9565b90600052602060002090600602016005018281548110612017576120176128a9565b6000918252602090912001546001600160a01b03160361203c57600192505050610555565b8061204681612abb565b915050611fc0565b506000949350505050565b6000833b63ffffffff161561219757604051630a85bd0160e11b81526001600160a01b0385169063150b7a029061209a903390899088908890600401612b62565b6020604051808303816000875af19250505080156120d5575060408051601f3d908101601f191682019092526120d291810190612b2f565b60015b61217d573d808015612103576040519150601f19603f3d011682016040523d82523d6000602084013e612108565b606091505b5080516000036121755760405162461bcd60e51b815260206004820152603260248201527f4552433732313a207472616e7366657220746f206e6f6e20455243373231526560448201527131b2b4bb32b91034b6b83632b6b2b73a32b960711b606482015260840161067d565b805181602001fd5b6001600160e01b031916630a85bd0160e11b149050611539565b506001611539565b606060006121ae836002612b9f565b6121b9906002612aa8565b67ffffffffffffffff8111156121d1576121d16126ff565b6040519080825280601f01601f1916602001820160405280156121fb576020820181803683370190505b509050600360fc1b81600081518110612216576122166128a9565b60200101906001600160f81b031916908160001a905350600f60fb1b81600181518110612245576122456128a9565b60200101906001600160f81b031916908160001a9053506000612269846002612b9f565b612274906001612aa8565b90505b60018111156122ec576f181899199a1a9b1b9c1cb0b131b232b360811b85600f16601081106122a8576122a86128a9565b1a60f81b8282815181106122be576122be6128a9565b60200101906001600160f81b031916908160001a90535060049490941c936122e581612bb6565b9050612277565b50831561080e5760405162461bcd60e51b815260206004820181905260248201527f537472696e67733a20686578206c656e67746820696e73756666696369656e74604482015260640161067d565b600580548251600090815260066020818152604080842085905560018501865594909252845192027f036b6384b5eca791c62761152d0c79bb0604c104a5fb6f4eb0703f3154bb3db08101928355818501517f036b6384b5eca791c62761152d0c79bb0604c104a5fb6f4eb0703f3154bb3db1820155928401517f036b6384b5eca791c62761152d0c79bb0604c104a5fb6f4eb0703f3154bb3db284015560608401517f036b6384b5eca791c62761152d0c79bb0604c104a5fb6f4eb0703f3154bb3db3840180546001600160a01b039283166001600160a01b03199182161790915560808601517f036b6384b5eca791c62761152d0c79bb0604c104a5fb6f4eb0703f3154bb3db48601805491909316911617905560a084015180518594610c0d937f036b6384b5eca791c62761152d0c79bb0604c104a5fb6f4eb0703f3154bb3db59091019201906124a8565b5080546000825590600052602060002090810190610ecd919061250d565b8280548282559060005260206000209081019282156124fd579160200282015b828111156124fd57825182546001600160a01b0319166001600160a01b039091161782556020909201916001909101906124c8565b5061250992915061250d565b5090565b5b80821115612509576000815560010161250e565b6001600160e01b031981168114610ecd57600080fd5b60006020828403121561254a57600080fd5b813561080e81612522565b60005b83811015612570578181015183820152602001612558565b50506000910152565b60008151808452612591816020860160208601612555565b601f01601f19169290920160200192915050565b60208152600061080e6020830184612579565b6000602082840312156125ca57600080fd5b5035919050565b80356001600160a01b0381168114610ac557600080fd5b600080604083850312156125fb57600080fd5b612604836125d1565b946020939093013593505050565b60008060006060848603121561262757600080fd5b83359250612637602085016125d1565b9150604084013590509250925092565b60008060006060848603121561265c57600080fd5b612665846125d1565b9250612637602085016125d1565b60008060006060848603121561268857600080fd5b505081359360208301359350604090920135919050565b6000602082840312156126b157600080fd5b61080e826125d1565b8015158114610ecd57600080fd5b600080604083850312156126db57600080fd5b6126e4836125d1565b915060208301356126f4816126ba565b809150509250929050565b634e487b7160e01b600052604160045260246000fd5b604051601f8201601f1916810167ffffffffffffffff8111828210171561273e5761273e6126ff565b604052919050565b600067ffffffffffffffff821115612760576127606126ff565b50601f01601f191660200190565b6000806000806080858703121561278457600080fd5b61278d856125d1565b935061279b602086016125d1565b925060408501359150606085013567ffffffffffffffff8111156127be57600080fd5b8501601f810187136127cf57600080fd5b80356127e26127dd82612746565b612715565b8181528860208385010111156127f757600080fd5b8160208401602083013760006020838301015280935050505092959194509250565b6000806040838503121561282c57600080fd5b8235915061283c602084016125d1565b90509250929050565b6000806040838503121561285857600080fd5b612861836125d1565b915061283c602084016125d1565b600181811c9082168061288357607f821691505b6020821081036128a357634e487b7160e01b600052602260045260246000fd5b50919050565b634e487b7160e01b600052603260045260246000fd5b60208082526023908201527f43544d33353235583a20617070726f76616c20746f2063757272656e74206f776040820152623732b960e91b606082015260800190565b60008351612914818460208801612555565b64736c6f742f60d81b9083019081528351612936816005840160208801612555565b01600501949350505050565b60006020828403121561295457600080fd5b815167ffffffffffffffff81111561296b57600080fd5b8201601f8101841361297c57600080fd5b805161298a6127dd82612746565b81815285602083850101111561299f57600080fd5b6129b0826020830160208601612555565b95945050505050565b60208082526033908201527f43544d33353235583a207472616e736665722063616c6c6572206973206e6f74604082015272081bdddb995c881b9bdc88185c1c1c9bdd9959606a1b606082015260800190565b60008351612a1e818460208801612555565b835190830190612a32818360208801612555565b01949350505050565b60008351612a4d818460208801612555565b68636f6e74726163742f60b81b9083019081528351612a73816009840160208801612555565b01600901949350505050565b634e487b7160e01b600052601160045260246000fd5b8181038181111561055557610555612a7f565b8082018082111561055557610555612a7f565b600060018201612acd57612acd612a7f565b5060010190565b600060208284031215612ae657600080fd5b815161080e816126ba565b60018060a01b038616815284602082015283604082015282606082015260a060808201526000612b2460a0830184612579565b979650505050505050565b600060208284031215612b4157600080fd5b815161080e81612522565b634e487b7160e01b600052603160045260246000fd5b6001600160a01b0385811682528416602082015260408101839052608060608201819052600090612b9590830184612579565b9695505050505050565b808202811582820484141761055557610555612a7f565b600081612bc557612bc5612a7f565b50600019019056fea26469706673582212203ed0754eea5b7f049d7268b4cc73359e00931f3de6aafbd2810e2847ff22017a64736f6c63430008140033";

type CTM3525XConstructorParams =
  | [signer?: Signer]
  | ConstructorParameters<typeof ContractFactory>;

const isSuperArgs = (
  xs: CTM3525XConstructorParams
): xs is ConstructorParameters<typeof ContractFactory> => xs.length > 1;

export class CTM3525X__factory extends ContractFactory {
  constructor(...args: CTM3525XConstructorParams) {
    if (isSuperArgs(args)) {
      super(...args);
    } else {
      super(_abi, _bytecode, args[0]);
    }
  }

  override deploy(
    name_: PromiseOrValue<string>,
    symbol_: PromiseOrValue<string>,
    decimals_: PromiseOrValue<BigNumberish>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<CTM3525X> {
    return super.deploy(
      name_,
      symbol_,
      decimals_,
      overrides || {}
    ) as Promise<CTM3525X>;
  }
  override getDeployTransaction(
    name_: PromiseOrValue<string>,
    symbol_: PromiseOrValue<string>,
    decimals_: PromiseOrValue<BigNumberish>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): TransactionRequest {
    return super.getDeployTransaction(
      name_,
      symbol_,
      decimals_,
      overrides || {}
    );
  }
  override attach(address: string): CTM3525X {
    return super.attach(address) as CTM3525X;
  }
  override connect(signer: Signer): CTM3525X__factory {
    return super.connect(signer) as CTM3525X__factory;
  }

  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): CTM3525XInterface {
    return new utils.Interface(_abi) as CTM3525XInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): CTM3525X {
    return new Contract(address, _abi, signerOrProvider) as CTM3525X;
  }
}