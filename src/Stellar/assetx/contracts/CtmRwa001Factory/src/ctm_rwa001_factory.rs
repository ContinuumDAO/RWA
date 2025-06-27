use soroban_sdk::{
    contract, contractimpl, contracttype, symbol_short, Env, Address, BytesN, Bytes, String, Vec, U256
};
use soroban_sdk::vec;
use ctm_rwa001::CtmRwa001Client; // Import ctm_rwa001 client

use ethabi::{ParamType, Token, decode};

#[contracttype]
#[derive(Clone)]
pub struct ArgData {
    rwa_id: BytesN<32>,
    rwa_type: u32,
    version: u32,
    token_admin_from: String,
    token_name: String,
    symbol: String,
    decimals: u32,
    base_uri: String,
}

#[contracttype]
#[derive(Clone)]
pub struct TokenDetails {
    token_name: String,
    token_symbol: String,
    token_decimals: u32,
    base_uri: String
}

#[contracttype]
#[derive(Clone)]
pub struct SlotDetails {
    slot_numbers: Vec<u32>,
    slot_names: Vec<String>
}


#[contracttype]
#[derive(Clone)]
pub enum DataKey {
    RwaType,                        // The type of RWA
    Version,                        // The version of this type of RWA
    CtmRwaDeployer,                 // The address of the CtmRwaDeployer contract
    DeployedContracts(BytesN<32>),  // Maps rwa_id to deployed contract Address
}

#[contract]
pub struct CtmRwa001Factory;

#[contractimpl]
impl CtmRwa001Factory {

    pub fn initialize(
        env: Env,
        rwa_type: u32,
        version: u32,
        ctm_rwa_deployer: Address
    ) {
        let storage = env.storage().persistent();

        // Ensure not already initialized
        if storage.has(&DataKey::RwaType) {
            panic!("CTMRWA001TokenFactory: Contract already initialized");
        }

        storage.set(&DataKey::RwaType, &rwa_type);
        storage.set(&DataKey::Version, &version);
        storage.set(&DataKey::CtmRwaDeployer, &ctm_rwa_deployer);

        // Emit initialization event
        env.events().publish(
            (symbol_short!("init"),),
            (rwa_type, version, ctm_rwa_deployer)
        );
    }

    pub fn deploy(
        env: Env,
        caller: Address,
        wasm_hash: BytesN<32>,
        // token_details: TokenDetails,
        // slot_details: SlotDetails
        deploy_args: Bytes
    ) -> Address {

        Self::require_deployer(&env, &caller);

        let storage = env.storage().persistent();

        // Use EVM compatible abi.decode for the payload, to create the correct arguments for
        let dec_args:ArgData = Self::decode_ctm_arg(&env, deploy_args.clone());

        

        // Check if rwa_id is already used
        if storage.has(&DataKey::DeployedContracts(dec_args.rwa_id.clone())) {
        panic!("Contract for rwa_id already deployed");
        }
        
        // Deploy the contract using rwa_id as salt
        let contract_address = env
            .deployer()
            .with_current_contract(dec_args.rwa_id.clone())
            .deploy(wasm_hash);


        // Initialize the deployed contract
        let client = CtmRwa001Client::new(&env, &contract_address);
        client.initialize(
            &dec_args.rwa_type,
            &dec_args.version,
            &dec_args.token_admin_from,
            &dec_args.token_name,
            &dec_args.symbol,
            &dec_args.decimals,
            &dec_args.base_uri,
            &dec_args.rwa_id
        );

        // Store the deployed contract address
        storage.set(&DataKey::DeployedContracts(dec_args.rwa_id.clone()), &contract_address);

        // Emit deployment event
        env.events().publish(
            (symbol_short!("deploy"),),
            (dec_args.rwa_id.clone(), contract_address.clone())
        );

        contract_address
    }

    // Check for token admin
    fn require_deployer(env: &Env, caller: &Address) {
        let ctm_rwa_deployer: Address = env.storage().persistent().get(&DataKey::CtmRwaDeployer).unwrap();
        if caller != &ctm_rwa_deployer {
            panic!("CTMRWA001TokenFactory: Caller is not CTMRWADeployer");
        }
    }

    pub fn get_contract(env: Env, rwa_id: BytesN<32>) -> Option<Address> {
        env.storage().persistent().get(&DataKey::DeployedContracts(rwa_id))
    }

    fn decode_ctm_arg(env: &Env, arg_data: Bytes) -> ArgData
    {
        // Define expected parameter types
        let param_types = [
            ParamType::Uint(256),      // rwa_id: BytesN<32> (decoded as U256)
            ParamType::Uint(256),      // rwa_type: u32 (decoded as U256)
            ParamType::Uint(256),      // version: u32 (decoded as U256)
            ParamType::String,         // token_admin_evm: String (EVM address as hex string)
            ParamType::String,         // token_name: String
            ParamType::String,         // symbol: String
            ParamType::Uint(256),      // decimals: u32 (as uint8 in EVM)
            ParamType::String,         // base_uri: String
        ];

        // Decode the ABI-encoded data
        let tokens = decode(&param_types, &arg_data.to_alloc_vec())
            .expect("CTMRWA001TokenFactory: Failed to decode ABI data");

        // Ensure we have exactly 8 tokens
        if tokens.len() != 8 {
            panic!("CTMRWA001TokenFactory: Incorrect number of decoded tokens");
        }

        // rwa_id: Convert U256 to BytesN<32>
        let rwa_id = match &tokens[0] {
            Token::Uint(uint) => {
                let mut bytes = [0u8; 32];
                uint.to_big_endian(&mut bytes);
                BytesN::from_array(env, &bytes)
            }
            _ => panic!("CTMRWA001TokenFactory: Expected uint256 for rwa_id"),
        };

        let rwa_type = match &tokens[1] {
            Token::Uint(uint) => uint.as_u32(),
            _ => panic!("CTMRWA001TokenFactory: Expected uint for rwa_type"),
        };

        let version = match &tokens[2] {
            Token::Uint(uint) => uint.as_u32(),
            _ => panic!("CTMRWA001TokenFactory: Expected uint for version"),
        };

        let token_admin_from: String = match &tokens[3] {
            Token::String(s) => {
                if s.len() != 42 {
                    panic!("CTMRWA001TokenFactory: Invalid token_admin_from length")
                }
                String::from_str(env, s)
            }
            _ => panic!("CTMRWA001TokenFactory: Expected string for token_admin_from"),
        };

        let token_name = match &tokens[4] {
            Token::String(s) => String::from_str(env, s),
            _ => panic!("CTMRWA001TokenFactory: Expected string for token_name"),
        };

        let symbol = match &tokens[5] {
            Token::String(s) => String::from_str(env, s),
            _ => panic!("CTMRWA001TokenFactory: Expected string for symbol"),
        };

        // decimals: Convert FixedBytes(1) to u32
        let decimals = match &tokens[6] {
            Token::FixedBytes(bytes) => {
                if bytes.len() != 1 {
                    panic!("CTMRWA001TokenFactory: Invalid decimals length");
                }
                bytes[0] as u32
            }
            _ => panic!("CTMRWA001TokenFactory: Expected fixed bytes for decimals"),
        };

        let base_uri = match &tokens[7] {
            Token::String(s) => String::from_str(env, s),
            _ => panic!("CTMRWA001TokenFactory: Expected string for base_uri"),
        };

        ArgData {
            rwa_id,
            rwa_type,
            version,
            token_admin_from,
            token_name,
            symbol,
            decimals,
            base_uri,
        }

        // let arg_struct = ArgData {
        //     rwa_id: BytesN::from_array(env, &[6; 32]),
        //     rwa_type: 1u32,
        //     version: 1u32,
        //     token_admin: env.current_contract_address(),  // TEST TEST
        //     token_name: String::from_str(&env, "CTMRWA Token"),
        //     symbol: String::from_str(&env, "RWA"),
        //     decimals: 18u32,
        //     base_uri: String::from_str(&env, "GFLD")
        // };

        // arg_struct
    }

    // pub fn convert_to_u32(env: Env, value: U256) -> u32 {
    //     // Check if the U256 value fits within u32 range
    //     let max_u32 = U256::from_u32(&env, u32::MAX);
    //     if value > max_u32 {
    //         panic!("Value exceeds u32 maximum");
    //     }

    //     // Convert U256 to u64 first, then to u32
    //     let value_u64 = value.to_u64();
    //     if value_u64 > u32::MAX as u64 {
    //         panic!("Value exceeds u32 maximum");
    //     }

    //     value_u64 as u32
    // }
}