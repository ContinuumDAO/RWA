use soroban_sdk::{
    contract, contractimpl, contracttype, contractclient, symbol_short, vec, Address, Env, U256, String, Vec, Map,
    log, BytesN, Bytes
};
use soroban_sdk::xdr::ToXdr;

use ethabi::{ParamType, Token, encode};

// storage keys for persistent data

#[contracttype]
#[derive(Clone)]
pub enum DataKey {
    Gov,
    Gateway,
    FeeManager,
    CtmRwaMap,
    CtmRwaDeployer
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


#[contract]
pub struct CTMRwa001X;

#[contractimpl]
impl CTMRwa001X {

    pub fn initialize(
        env: Env,
        gov: Address,
        gateway: Address,
        fee_manager: Address
    ) {
        let storage = env.storage().persistent();
        if storage.has(&DataKey::Gov) {
            panic!("CTMRwa001X: Contract has already been initialized");
        }

        storage.set(&DataKey::Gov, &gov);
        storage.set(&DataKey::Gateway, &gateway);
        storage.set(&DataKey::FeeManager, &fee_manager);
    }

    pub fn set_governor(env: Env, gov: Address, new_gov: Address) {
        gov.require_auth();
        Self::check_gov(&env, &gov);
        let storage = env.storage().persistent();
        storage.set(&DataKey::Gov, &new_gov);
        env.events().publish((symbol_short!("set_gov"),), (new_gov,));
    }

    fn check_gov(env: &Env, caller: &Address) {
        let gov: Address = env
            .storage()
            .persistent()
            .get(&DataKey::Gov)
            .unwrap_or_else(|| panic!("CTMRwaDeployer: Gov not set"));
        if caller != &gov {
            panic!("CTMRwaDeployer: Caller is not gov");
        }
    }

    pub fn set_ctm_gateway(env: Env, gov: Address, new_gateway: Address) {
        gov.require_auth();
        Self::check_gov(&env, &gov);
        let storage = env.storage().persistent();
        storage.set(&DataKey::Gateway, &new_gateway);
        env.events().publish((symbol_short!("set_gate"),), (new_gateway,));
    }

    pub fn set_ctm_map(env: Env, gov: Address, new_map: Address) {
        gov.require_auth();
        Self::check_gov(&env, &gov);
        let storage = env.storage().persistent();
        storage.set(&DataKey::CtmRwaMap, &new_map);
        env.events().publish((symbol_short!("set_map"),), (new_map,));
    }

    pub fn set_fee_manager(env: Env, gov: Address, new_fee_manager: Address) {
        gov.require_auth();
        Self::check_gov(&env, &gov);
        let storage = env.storage().persistent();
        storage.set(&DataKey::FeeManager, &new_fee_manager);
        env.events().publish((symbol_short!("set_fee"),), (new_fee_manager,));
    }

    pub fn set_ctm_deployer(env: Env, gov: Address, new_deployer: Address) {
        gov.require_auth();
        Self::check_gov(&env, &gov);
        let storage = env.storage().persistent();
        storage.set(&DataKey::CtmRwaDeployer, &new_deployer);
        env.events().publish((symbol_short!("set_dep"),), (new_deployer,));
    }


    pub fn deploy_all_ctm_rwa001_x (
        env: Env,
        caller: Address,
        include_local: bool,
        existing_rwa_id: BytesN<32>,
        rwa_type: u32,
        version: u32,
        token_details: TokenDetails,
        to_chain_ids: Vec<String>,
        fee_token: String
    ) {
        let TokenDetails {
            mut token_name, 
            mut token_symbol, 
            mut token_decimals, 
            mut base_uri
        } = token_details;

        // Caller has two options: Extend an existing rwa_id to other chains, or create a new one
        if !include_local && Self::is_zero_bytes32(&env, &existing_rwa_id) 
            || include_local && !Self::is_zero_bytes32(&env, &existing_rwa_id) {
                panic!("CTMRwa001X: Incorrect call logic");
        }

        let name_len = token_name.len();
        if name_len<10 || name_len>512 {
            panic!("CTMRwa001X: Token name length is < 10 or > 512 characters");
        }

        let n_chains = to_chain_ids.len();
        let rwa_id: BytesN<32>;

        if include_local { // Generate a new CTMRWA001
            rwa_id = Self::generate_random_bytes32(&env, caller.clone());

            let token_admin = caller;

            let slot_details:SlotDetails = SlotDetails{
                slot_numbers: Vec::new(&env.clone()), 
                slot_names: Vec::new(&env.clone())
            };
        }

        

    }

    fn deploy_local_ctm_rwa001(
        env: &Env,
        rwa_id: BytesN<32>,
        token_details: TokenDetails,
        slot_details: SlotDetails,
        token_admin: Address
    ) -> Address {

        let TokenDetails {
            token_name, 
            token_symbol, 
            token_decimals, 
            base_uri
        } = token_details;

        let SlotDetails {
            slot_numbers,
            slot_names
        } = slot_details;

        // let eth_tokens = vec![
        //     Token::FixedBytes(rwa_id.to_vec()),
        //     Token::String(token_admin.to_string()),
        //     Token::String(token_name),
        //     Token::String(token_symbol),
        //     Token::Uint(token_decimals),
        //     Token::String(base_uri),
        //     // Token::Array(slot_numbers),
        //     // Token::Array(slot_names),
        // ];

        // let eth_bytesn_encoded = encode(&eth_tokens);

        let token_decimals: U256 = U256::from_u32(&env, 18u32);

        let eth_tokens = vec![ &env,
            Token::String(String::from_str("dummy token name")),
            Token::Uint(token_decimals)
        ];

        let eth_bytesn_encoded = encode(&eth_tokens);



        token_admin
    }


    fn get_token_contract(
        env: Env,
        rwa_id: BytesN<32>,
        rwa_type: u32, 
        version: u32
    ) -> Option<Address> {

        let map_address: Address = env
            .storage()
            .persistent()
            .get(&DataKey::CtmRwaMap)
            .unwrap_or_else(|| panic!("CTMRwa001X: Could not get the CTMRWAMap address"));

        let ctm_rwa_map_client = CTMRWAMapClient::new(&env, &map_address);

        ctm_rwa_map_client.get_token_contract(&rwa_id, &rwa_type, &version)

    }

    // Function to check if a BytesN<32> is all zeros
    fn is_zero_bytes32(env: &Env, bytes: &BytesN<32>) -> bool {
        let zero_bytes = BytesN::from_array(env, &[0u8; 32]);
        bytes == &zero_bytes
    }

    fn generate_random_bytes32(env: &Env, caller: Address) -> BytesN<32> {
        // Collect inputs for hashing
        let mut input = Bytes::new(env);
        
        // Add ledger sequence (u32)
        let ledger_seq = env.ledger().sequence();
        input.extend_from_slice(&ledger_seq.to_le_bytes());
        
        // Add ledger timestamp (u64)
        let ledger_time = env.ledger().timestamp();
        input.extend_from_slice(&ledger_time.to_le_bytes());
        
        // Add the current contract address
        let contract_address: Address = env.current_contract_address();
        let contract_address_xdr = contract_address.to_xdr(env); // Returns Bytes
        let contract_address_array = {
            let mut array = [0u8; 32];
            let len = contract_address_xdr.len().min(32); // Ensure we don't exceed array bounds
            for i in 0..len {
                array[i as usize] = contract_address_xdr.get_unchecked(i);
            }
            array
        };
        input.extend_from_slice(&contract_address_array[..contract_address_xdr.len() as usize]);

        
        // Add caller address
        let caller_address_xdr = caller.to_xdr(env); // Returns Bytes
        let caller_address_array = {
            let mut array = [0u8; 32];
            let len = caller_address_xdr.len().min(32); // Ensure we don't exceed array bounds
            for i in 0..len {
                array[i as usize] = caller_address_xdr.get_unchecked(i);
            }
            array
        };
        input.extend_from_slice(&caller_address_array[..caller_address_xdr.len() as usize]);
        
        // Compute SHA-256 hash
        let hash: BytesN<32> = env.crypto().sha256(&input).into();
        
        hash
    }

}

#[contractclient(name = "CTMRWAGatewayClient")]
pub trait CTMRWA001Gateway {
    fn get_attached_rwa_x(
        env: Env, 
        rwa_type: u32, 
        version: u32, 
        chain_id_str: String
    ) -> Option<String>;

}

#[contractclient(name = "CTMRWA001DeployerClient")]
pub trait CTMRWA001Deployer {
    fn deploy(
        env: Env,
        rwa_id: BytesN<32>,
        rwa_type: u32,
        version: u32,
        deploy_args: Bytes
    ) -> Address;
}

#[contractclient(name = "CTMRWA001Client")]
pub trait CTMRWA001 {
    fn get_token_admin(env: &Env) -> Address;
    fn get_rwa_type(env: Env) -> u32;
    fn get_version(env: Env) -> u32;
}

#[contractclient(name = "CTMRWAMapClient")]
pub trait CTMRWAMap {
    fn get_token_contract(
        env: Env, 
        id: BytesN<32>, 
        rwa_type: u32, 
        version: u32
    ) -> Option<Address>;
}