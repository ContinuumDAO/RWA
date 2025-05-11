use soroban_sdk::{
    contract, contractimpl, contracttype, contractclient, symbol_short, vec, Address, Env, String, Vec, Map,
    log, BytesN, Bytes
};

// storage keys for persistent data

#[contracttype]
#[derive(Clone)]
pub enum DataKey {
    Gov,
    Gateway,
    FeeManager,
    RwaX,
    CtmRwaMap,
    TokenFactory(u32,u32),
    TokenHash(u32,u32),
}



#[contract]
pub struct CTMRwaDeployer;

#[contractimpl]
impl CTMRwaDeployer {
    pub fn initialize(
        env: Env,
        gov: Address,
        gateway: Address,
        fee_manager: Address,
        rwa_x: Address,
        ctm_rwa_map: Address
    ) {
        let storage = env.storage().persistent();
        if storage.has(&DataKey::Gov) {
            panic!("CTMRwaDeployer: Contract has already been initialized");
        }

        storage.set(&DataKey::Gov, &gov);
        storage.set(&DataKey::Gateway, &gateway);
        storage.set(&DataKey::FeeManager, &fee_manager);
        storage.set(&DataKey::RwaX, &rwa_x);
        storage.set(&DataKey::CtmRwaMap, &ctm_rwa_map);

        env.events().publish((symbol_short!("init"),), (gov,));
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

    pub fn set_token_hash(
        env: Env, 
        gov: Address, 
        rwa_type: u32, 
        version: u32, 
        token_hash: BytesN<32>
    ) {
        gov.require_auth();
        Self::check_gov(&env, &gov);
        let storage = env.storage().persistent();
        storage.set(&DataKey::TokenHash(rwa_type.clone(), version.clone()), &token_hash);
        env.events().publish((symbol_short!("tok_hash"),), (rwa_type, version, token_hash));
    }


    pub fn set_factory(env: Env, gov: Address, rwa_type: u32, version: u32, factory: Address) {
        gov.require_auth();
        Self::check_gov(&env, &gov);
        let storage = env.storage().persistent();
        storage.set(&DataKey::TokenFactory(rwa_type.clone(), version.clone()), &factory);
        env.events().publish((symbol_short!("set_fact"),), (rwa_type, version, factory));
    }

    pub fn deploy(
        env: Env,
        rwa_id: BytesN<32>,
        rwa_type: u32,
        version: u32,
        deploy_args: Bytes
    ) -> Address {

        let rwa_x: Address = env
            .storage()
            .persistent()
            .get(&DataKey::RwaX)
            .unwrap_or_else(|| panic!("CTMRwaDeployer: Could not get RwaX address"));

        rwa_x.require_auth();

        let token_hash: BytesN<32> = env
            .storage()
            .persistent()
            .get(&DataKey::TokenHash(rwa_type.clone(), version.clone()))
            .unwrap_or_else(|| panic!("CTMRwaDeployer: TokenHash not set"));

        let token_factory: Address = env
            .storage()
            .persistent()
            .get(&DataKey::TokenFactory(rwa_type.clone(), version.clone()))
            .unwrap_or_else(|| panic!("CTMRwaDeployer: Factory address not set for rwa_type and version"));

        let client = CTMRWA001FactoryClient::new(&env, &token_factory);

        // Call Token Factory
        let token_address = client.deploy(
            &env.current_contract_address(),
            &token_hash,
            &deploy_args
        );

        env.events().publish(
            (symbol_short!("deploy"),),
            (rwa_type, version, rwa_id, token_address.clone())
        );

        token_address
    }

}

#[contractclient(name = "CTMRWA001FactoryClient")]
pub trait CTMRWA001Factory {
    fn deploy(
        env: Env,
        caller: Address,
        wasm_hash: BytesN<32>,
        deploy_args: Bytes
    ) -> Address;
}