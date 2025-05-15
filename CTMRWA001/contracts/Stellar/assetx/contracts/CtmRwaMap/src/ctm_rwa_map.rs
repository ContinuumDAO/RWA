use soroban_sdk::{
    contract, contractimpl, contracttype, symbol_short, Env, Address, String, BytesN
};

// Constants
const RWA_TYPE: u32 = 1;
const VERSION: u32 = 1;

// Data keys for persistent storage
#[contracttype]
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum DataKey {
    Gateway,                    // Address of CTMRWAGateway
    CtmRwaDeployer,             // Address of CTMRWADeployer
    CtmRwa001X,                 // Address of CTMRWA001X
    ChainIdStr,                 // String representation of chain ID
    IdToContract(BytesN<32>),   // ID => CTMRWA001 contract address (Address)
    ContractToId(Address),      // CTMRWA001 contract address (Address) => ID
    IdToDividend(BytesN<32>),   // ID => CTMRWA001Dividend contract address (Address)
    DividendToId(Address),      // CTMRWA001Dividend contract address (Address) => ID
    IdToStorage(BytesN<32>),    // ID => CTMRWA001Storage contract address (Address)
    StorageToId(Address),       // CTMRWA001Storage contract address (Address) => ID
    IdToSentry(BytesN<32>),     // ID => CTMRWA001Sentry contract address (Address)
    SentryToId(Address),        // CTMRWA001Sentry contract address (Address) => ID
}

// Client for ICTMRWAAttachment interface
// #[contractclient(name = "CTMRWAAttachmentClient")]
// pub trait CTMRWAAttachment {
//     fn token_admin() -> Address;
    // fn attach_dividend(&self, dividend_addr: Address) -> bool;
    // fn attach_storage(&self, storage_addr: Address) -> bool;
    // fn attach_sentry(&self, sentry_addr: Address) -> bool;
    // fn dividend_addr(&self) -> Address;
    // fn storage_addr(&self) -> Address;
    // fn sentry_addr(&self) -> Address;
// }


#[contract]
pub struct CTMRWAMap;

#[contractimpl]
impl CTMRWAMap {
    // Initialize the contract
    pub fn initialize(
        env: Env, 
        gateway: Address, 
        ctm_rwa001x: Address, 
        chain_id_str: String
    ) {
        let storage = env.storage().persistent();

        // Ensure not already initialized
        if storage.has(&DataKey::Gateway) {
            panic!("CTMRWAMap: Contract already initialized");
        }

        // Store initial values
        storage.set(&DataKey::Gateway, &gateway);
        storage.set(&DataKey::CtmRwa001X, &ctm_rwa001x);
        storage.set(&DataKey::ChainIdStr, &chain_id_str);

        // Emit initialization event
        env.events().publish(
            (symbol_short!("init"),),
            (gateway, ctm_rwa001x, chain_id_str)
        );
    }

    // Modifier: onlyDeployer
    fn require_deployer(env: &Env, caller: &Address) {
        let deployer: Address = env.storage().persistent().get(&DataKey::CtmRwaDeployer)
            .unwrap_or_else(|| panic!("CTMRWAMap: Deployer not set"));
        if caller != &deployer {
            panic!("CTMRWAMap: Caller is not CTMRWADeployer");
        }
    }

    // Modifier: onlyRwa001X
    fn require_rwa001x(env: &Env, caller: &Address) {
        let rwa001x: Address = env.storage().persistent().get(&DataKey::CtmRwa001X)
            .unwrap_or_else(|| panic!("CTMRWAMap: CTMRWA001X not set"));
        if caller != &rwa001x {
            panic!("CTMRWAMap: Caller is not CTMRWA001X");
        }
    }

    // Set CTMRWADeployer, Gateway, and CTMRWA001X (onlyRwa001X)
    pub fn set_ctm_rwa_deployer(env: Env, caller: Address, deployer: Address, gateway: Address, rwa001x: Address) {
        caller.require_auth();
        Self::require_rwa001x(&env, &caller);

        let storage = env.storage().persistent();
        storage.set(&DataKey::CtmRwaDeployer, &deployer);
        storage.set(&DataKey::Gateway, &gateway);
        storage.set(&DataKey::CtmRwa001X, &rwa001x);

        env.events().publish(
            (symbol_short!("set_depl"),),
            (deployer, gateway, rwa001x)
        );
    }

    // Get ID from CTMRWA001 contract address
    pub fn get_token_id(env: Env, token_addr: Address, rwa_type: u32, version: u32) -> Option<BytesN<32>> {
        if rwa_type != RWA_TYPE || version != VERSION {
            panic!("CTMRWAMap: incorrect RWA type or version");
        }

        env.storage().persistent().get(&DataKey::ContractToId(token_addr))
    }

    // Get CTMRWA001 contract address from ID
    pub fn get_token_contract(env: Env, id: BytesN<32>, rwa_type: u32, version: u32) -> Option<Address> {
        if rwa_type != RWA_TYPE || version != VERSION {
            panic!("CTMRWAMap: incorrect RWA type or version");
        }

        env.storage().persistent().get(&DataKey::IdToContract(id))
    }

    // Get CTMRWA001Dividend contract address from ID
    pub fn get_dividend_contract(env: Env, id: BytesN<32>, rwa_type: u32, version: u32) -> Option<Address> {
        if rwa_type != RWA_TYPE || version != VERSION {
            panic!("CTMRWAMap: incorrect RWA type or version");
        }

        env.storage().persistent().get(&DataKey::IdToDividend(id))
    }

    // Get CTMRWA001Storage contract address from ID
    pub fn get_storage_contract(env: Env, id: BytesN<32>, rwa_type: u32, version: u32) -> Option<Address> {
        if rwa_type != RWA_TYPE || version != VERSION {
            panic!("CTMRWAMap: incorrect RWA type or version");
        }

        env.storage().persistent().get(&DataKey::IdToStorage(id))
    }

    // Get CTMRWA001Sentry contract address from ID
    pub fn get_sentry_contract(env: Env, id: BytesN<32>, rwa_type: u32, version: u32) -> Option<Address> {
        if rwa_type != RWA_TYPE || version != VERSION {
            panic!("CTMRWAMap: incorrect RWA type or version");
        }

        env.storage().persistent().get(&DataKey::IdToSentry(id))
    }

    // Attach contracts for an ID (onlyDeployer)
    pub fn attach_contracts(
        env: Env,
        caller: Address,
        id: BytesN<32>,
        rwa_type: u32,
        version: u32,
        token_addr: Address,
        // dividend_addr: Address,
        // storage_addr: Address,
        // sentry_addr: Address
    ) {
        caller.require_auth();
        Self::require_deployer(&env, &caller);

        if rwa_type != RWA_TYPE || version != VERSION {
            panic!("CTMRWAMap: incorrect RWA type or version");
        }

        // Attach CTMRWA ID and related contracts
        let ok = Self::attach_ctmrwa_id(&env, 
            id.clone(), 
            &token_addr, 
            // &dividend_addr, 
            // &storage_addr, 
            // &sentry_addr
        );
        if !ok {
            panic!("CTMRWAMap: Failed to set token ID");
        }

        // Call attach methods on CTMRWA001 contract
        // let client = CTMRWAAttachmentClient::new(&env, &token_addr);
        // if !client.attach_dividend(&dividend_addr) {
        //     panic!("CTMRWAMap: Failed to set the dividend contract address");
        // }
        // if !client.attach_storage(&storage_addr) {
        //     panic!("CTMRWAMap: Failed to set the storage contract address");
        // }
        // if !client.attach_sentry(&sentry_addr) {
        //     panic!("CTMRWAMap: Failed to set the sentry contract address");
        // }

        // env.events().publish(
        //     (symbol_short!("attach"),),
        //     (id, token_addr, dividend_addr, storage_addr, sentry_addr)
        // );
    }

    // Internal: Attach CTMRWA ID and related contracts
    fn attach_ctmrwa_id(
        env: &Env,
        id: BytesN<32>,
        ctm_rwa_addr: &Address,
        // dividend_addr: &Address,
        // storage_addr: &Address,
        // sentry_addr: &Address
    ) -> bool {
        let storage = env.storage().persistent();

        // Check if ID or contract address is already used
        if storage.has(&DataKey::IdToContract(id.clone())) || storage.has(&DataKey::ContractToId(ctm_rwa_addr.clone())) {
            return false;
        }

        // Store mappings
        storage.set(&DataKey::IdToContract(id.clone()), ctm_rwa_addr);
        storage.set(&DataKey::ContractToId(ctm_rwa_addr.clone()), &id);

        // storage.set(&DataKey::IdToDividend(id.clone()), dividend_addr);
        // storage.set(&DataKey::DividendToId(dividend_addr.clone()), &id);

        // storage.set(&DataKey::IdToStorage(id.clone()), storage_addr);
        // storage.set(&DataKey::StorageToId(storage_addr.clone()), &id);

        // storage.set(&DataKey::IdToSentry(id.clone()), sentry_addr);
        // storage.set(&DataKey::SentryToId(sentry_addr.clone()), &id);

        true
    }
}