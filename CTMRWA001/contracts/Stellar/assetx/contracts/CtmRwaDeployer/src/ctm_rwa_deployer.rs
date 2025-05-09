use soroban_sdk::{
    contract, contractimpl, contracttype, contractclient, symbol_short, vec, Address, Env, String, Vec, Map,
    log, BytesN, Bytes
};

// storage keys for persistent data

#[contracttype]
#[derive(Clone)]
pub enum DataKey {
    TokenAdmin,
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
        token_admin: Address,
        gov: Address,
        gateway: Address,
        fee_manager: Address,
        rwa_x: Address,
        ctm_rwa_map: Address
    ) {
        let storage = env.storage().persistent();
        if storage.has(&DataKey::TokenAdmin) {
            panic!("CTMRwaDeployer: Contract has already been initialized");
        }

        storage.set(&DataKey::TokenAdmin, &token_admin);
        storage.set(&DataKey::Gov, &gov);
        storage.set(&DataKey::Gateway, &gateway);
        storage.set(&DataKey::FeeManager, &fee_manager);
        storage.set(&DataKey::RwaX, &rwa_x);
        storage.set(&DataKey::CtmRwaMap, &ctm_rwa_map);

        env.events().publish((symbol_short!("init"),), (token_admin,));
    }

    pub fn set_token_admin(env: Env, token_admin: Address, new_admin: Address) {
        token_admin.require_auth();
        Self::check_admin(&env, &token_admin);
        let storage = env.storage().persistent();
        storage.set(&DataKey::TokenAdmin, &new_admin);
        env.events().publish((symbol_short!("set_admin"),), (new_admin,));
    }

    fn check_admin(env: &Env, caller: &Address) {
        let token_admin: Address = env
            .storage()
            .persistent()
            .get(&DataKey::TokenAdmin)
            .unwrap_or_else(|| panic!("CTMRwaDeployer: TokenAdmin not set"));
        if caller != &token_admin {
            panic!("CTMRwaDeployer: Caller is not tokenAdmin");
        }
    }

    pub fn set_token_hash(
        env: Env, 
        token_admin: Address, 
        rwa_type: u32, 
        version: u32, 
        token_hash: BytesN<32>
    ) {
        token_admin.require_auth();
        Self::check_admin(&env, &token_admin);
        let storage = env.storage().persistent();
        storage.set(&DataKey::TokenHash(rwa_type.clone(), version.clone()), &token_hash);
        env.events().publish((symbol_short!("tok_hash"),), (rwa_type, version, token_hash));
    }


    pub fn set_factory(env: Env, token_admin: Address, rwa_type: u32, version: u32, factory: Address) {
        token_admin.require_auth();
        Self::check_admin(&env, &token_admin);
        let storage = env.storage().persistent();
        storage.set(&DataKey::TokenFactory(rwa_type.clone(), version.clone()), &factory);
        env.events().publish((symbol_short!("set_fact"),), (rwa_type, version, factory));
    }

    pub fn deploy(
        env: Env,
        rwa_id: BytesN<32>,
        rwa_type: u32,
        version: u32,
        token_admin: Address,
        token_name: String,
        symbol: String,
        decimals: u32,
        base_uri: String
    ) -> Address {

        let rwa_x: Address = env
            .storage()
            .persistent()
            .get(&DataKey::RwaX)
            .unwrap_or_else(|| panic!(CTMRwaDeployer: Could not get RwaX address));

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

        let token_address = client.deploy(
            &caller,
            &token_hash,
            &rwa_id,
            &rwa_type,
            &version,
            &token_admin,
            &token_name,
            &symbol,
            &decimals,
            &base_uri
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
        rwa_id: BytesN<32>,
        rwa_type: u32,
        version: u32,
        token_admin: Address,
        token_name: String,
        symbol: String,
        decimals: u32,
        base_uri: String
    ) -> Address;
}