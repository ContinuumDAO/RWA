use soroban_sdk::{contract, contractimpl, contracttype, symbol_short, Env, Address, BytesN, String, Vec};
use ctm_rwa001::CtmRwa001Client; // Import ctm_rwa001 client

#[contracttype]
#[derive(Clone)]
pub enum DataKey {
    DeployedContracts(BytesN<32>), // Maps rwa_id to deployed contract Address
}

#[contract]
pub struct CtmRwa001Factory;

#[contractimpl]
impl CtmRwa001Factory {
    pub fn deploy(
        env: Env,
        caller: Address,
        wasm_hash: BytesN<32>,
        rwa_id: BytesN<32>,
        rwa_type: u32,
        version: u32,
        token_admin: Address,
        token_name: String,
        symbol: String,
        decimals: u32,
        base_uri: String
    ) -> Address {
        caller.require_auth();

        let storage = env.storage().persistent();

        // Check if rwa_id is already used
        if storage.has(&DataKey::DeployedContracts(rwa_id.clone())) {
            panic!("Contract for rwa_id already deployed");
        }

        // Deploy the contract using rwa_id as salt
        let contract_address = env
            .deployer()
            .with_current_contract(rwa_id.clone())
            .deploy(wasm_hash);

        // Initialize the deployed contract
        let client = CtmRwa001Client::new(&env, &contract_address);
        client.initialize(
            &rwa_type,
            &version,
            &token_admin,
            &token_name,
            &symbol,
            &decimals,
            &base_uri,
            &rwa_id
        );

        // Store the deployed contract address
        storage.set(&DataKey::DeployedContracts(rwa_id.clone()), &contract_address);

        // Emit deployment event
        env.events().publish(
            (symbol_short!("deploy"),),
            (rwa_id.clone(), contract_address.clone())
        );

        contract_address
    }

    pub fn get_contract(env: Env, rwa_id: BytesN<32>) -> Option<Address> {
        env.storage().persistent().get(&DataKey::DeployedContracts(rwa_id))
    }
}