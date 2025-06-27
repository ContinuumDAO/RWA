
use soroban_sdk::{
    contract, contractimpl, contracttype, symbol_short, Env, Address, String, Vec, Bytes
};

// ChainContract struct
#[contracttype]
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct ChainContract {
    pub chain_id_str: String, // Chain ID as a string (e.g., "1" for Ethereum)
    pub contract_str: String, // Contract address as a hex string (e.g., "0x...")
}

// Data keys for persistent storage
#[contracttype]
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum DataKey {
    Governor, // Governor address (Address for local authentication)
    ChainIdStr, // Local chain ID as a string
    ChainContracts, // Vec<ChainContract> for all gateway contracts
    RwaX(u32, u32), // rwaType => version => Vec<ChainContract> (CTMRWA001X)
    RwaXChains(u32, u32), // rwaType => version => Vec<String> (chain IDs)
    StorageManager(u32, u32), // rwaType => version => Vec<ChainContract> (StorageManager)
    SentryManager(u32, u32), // rwaType => version => Vec<ChainContract> (SentryManager)
}

#[contract]
pub struct CTMRWAGateway;

#[contractimpl]
impl CTMRWAGateway {
    // Initialize the contract
    pub fn initialize(env: Env, gov: Address, chain_id_str: String, this_contract_str: String) {
        let storage = env.storage().persistent();

        // Ensure not already initialized
        if storage.has(&DataKey::Governor) {
            panic!("CTMRWAGateway: Contract already initialized");
        }

        // Validate this_contract_str length
        if this_contract_str.len() != 42 {
            panic!("CTMRWAGateway: Invalid contract address length");
        }

        // Store governor and chain ID
        storage.set(&DataKey::Governor, &gov);
        storage.set(&DataKey::ChainIdStr, &chain_id_str);

        // Initialize chainContracts with this contract’s address (as String)
        let mut chain_contracts: Vec<ChainContract> = Vec::new(&env);
        chain_contracts.push_back(ChainContract {
            chain_id_str: chain_id_str.clone(),
            contract_str: this_contract_str.clone(),
        });
        storage.set(&DataKey::ChainContracts, &chain_contracts);

        // Emit initialization event
        env.events().publish(
            (symbol_short!("init"),),
            (gov, chain_id_str, this_contract_str)
        );
    }

    // Modifier: onlyGov
    fn require_gov(env: &Env, caller: &Address) {
        let gov: Address = env.storage().persistent().get(&DataKey::Governor)
            .unwrap_or_else(|| panic!("CTMRWAGateway: Governor not set"));
        if caller != &gov {
            panic!("CTMRWAGateway: Caller is not governor");
        }
    }

    // Add addresses of CTMRWAGateway contracts on other chains (onlyGov)
    pub fn add_chain_contract(env: Env, caller: Address, new_chain_ids: Vec<String>, contract_strs: Vec<String>) -> bool {
        caller.require_auth();
        Self::require_gov(&env, &caller);

        if new_chain_ids.len() != contract_strs.len() {
            panic!("CTMRWAGateway: Argument lengths not equal");
        }

        // Validate contract string lengths
        for contract_str in contract_strs.iter() {
            if contract_str.len() != 42 {
                panic!("CTMRWAGateway: Invalid contract address length");
            }
        }

        let storage = env.storage().persistent();
        let mut chain_contracts: Vec<ChainContract> = storage.get(&DataKey::ChainContracts)
            .unwrap_or_else(|| Vec::new(&env));

        let mut updated = false;
        for (chain_id, contract_str) in new_chain_ids.iter().zip(contract_strs.iter()) {
            let mut found = false;
            for i in 0..chain_contracts.len() {
                if chain_contracts.get(i).unwrap().chain_id_str == chain_id {
                    let mut cc = chain_contracts.get(i).unwrap();
                    cc.contract_str = contract_str.clone();
                    chain_contracts.set(i, cc);
                    found = true;
                    updated = true;
                    break;
                }
            }
            if !found {
                chain_contracts.push_back(ChainContract {
                    chain_id_str: chain_id.clone(),
                    contract_str: contract_str.clone(),
                });
                updated = true;
            }
        }

        if updated {
            storage.set(&DataKey::ChainContracts, &chain_contracts);
        }

        env.events().publish(
            (symbol_short!("add_chain"),),
            (new_chain_ids, contract_strs)
        );

        true
    }

    // Get the address string for a CTMRWAGateway contract on another chain
    pub fn get_chain_contract(env: Env, chain_id_str: String) -> Option<String> {
        let storage = env.storage().persistent();
        let chain_contracts: Vec<ChainContract> = storage.get(&DataKey::ChainContracts)
            .unwrap_or_else(|| Vec::new(&env));

        for cc in chain_contracts.iter() {
            if cc.chain_id_str == chain_id_str {
                return Some(cc.contract_str.clone());
            }
        }
        None
    }

    // Get the chainId and address string of a CTMRWAGateway contract at an index
    pub fn get_chain_contract_at(env: Env, pos: u32) -> Option<(String, String)> {
        let storage = env.storage().persistent();
        let chain_contracts: Vec<ChainContract> = storage.get(&DataKey::ChainContracts)
            .unwrap_or_else(|| Vec::new(&env));

        if pos >= chain_contracts.len() {
            return None;
        }

        let cc = chain_contracts.get(pos).unwrap();
        Some((cc.chain_id_str.clone(), cc.contract_str.clone()))
    }

    // Get the number of stored chainIds and CTMRWAGateway pairs
    pub fn get_chain_count(env: Env) -> u32 {
        let storage = env.storage().persistent();
        let chain_contracts: Vec<ChainContract> = storage.get(&DataKey::ChainContracts)
            .unwrap_or_else(|| Vec::new(&env));
        chain_contracts.len()
    }

    // Get all chainIds of CTMRWA001X contracts
    pub fn get_all_rwa_x_chains(env: Env, rwa_type: u32, version: u32) -> Vec<String> {
        let storage = env.storage().persistent();
        storage.get(&DataKey::RwaXChains(rwa_type, version))
            .unwrap_or_else(|| Vec::new(&env))
    }

    // Check if a CTMRWA001X contract exists for a chainId
    pub fn exist_rwa_x_chain(env: Env, rwa_type: u32, version: u32, chain_id_str: String) -> bool {
        let storage = env.storage().persistent();
        let chains: Vec<String> = storage.get(&DataKey::RwaXChains(rwa_type, version))
            .unwrap_or_else(|| Vec::new(&env));

        for chain in chains.iter() {
            if chain == chain_id_str {
                return true;
            }
        }
        false
    }

    // Get chainId and CTMRWA001X contract address string at an index
    pub fn get_attached_rwa_x_at(env: Env, rwa_type: u32, version: u32, index: u32) -> Option<(String, String)> {
        let storage = env.storage().persistent();
        let rwa_x: Vec<ChainContract> = storage.get(&DataKey::RwaX(rwa_type, version))
            .unwrap_or_else(|| Vec::new(&env));

        if index >= rwa_x.len() {
            return None;
        }

        let cc = rwa_x.get(index).unwrap();
        Some((cc.chain_id_str.clone(), cc.contract_str.clone()))
    }

    // Get the number of stored CTMRWA001X contracts
    pub fn get_rwa_x_count(env: Env, rwa_type: u32, version: u32) -> u32 {
        let storage = env.storage().persistent();
        let rwa_x: Vec<ChainContract> = storage.get(&DataKey::RwaX(rwa_type, version))
            .unwrap_or_else(|| Vec::new(&env));
        rwa_x.len()
    }

    // Get the CTMRWA001X contract address string for a chainId
    pub fn get_attached_rwa_x(env: Env, rwa_type: u32, version: u32, chain_id_str: String) -> Option<String> {
        let storage = env.storage().persistent();
        let rwa_x: Vec<ChainContract> = storage.get(&DataKey::RwaX(rwa_type, version))
            .unwrap_or_else(|| Vec::new(&env));

        for cc in rwa_x.iter() {
            if cc.chain_id_str == chain_id_str {
                return Some(cc.contract_str.clone());
            }
        }
        None
    }

    // Get chainId and CTMRWA001StorageManager contract address string at an index
    pub fn get_attached_storage_manager_at(env: Env, rwa_type: u32, version: u32, index: u32) -> Option<(String, String)> {
        let storage = env.storage().persistent();
        let managers: Vec<ChainContract> = storage.get(&DataKey::StorageManager(rwa_type, version))
            .unwrap_or_else(|| Vec::new(&env));

        if index >= managers.len() {
            return None;
        }

        let cc = managers.get(index).unwrap();
        Some((cc.chain_id_str.clone(), cc.contract_str.clone()))
    }

    // Get the number of stored CTMRWA001StorageManager contracts
    pub fn get_storage_manager_count(env: Env, rwa_type: u32, version: u32) -> u32 {
        let storage = env.storage().persistent();
        let managers: Vec<ChainContract> = storage.get(&DataKey::StorageManager(rwa_type, version))
            .unwrap_or_else(|| Vec::new(&env));
        managers.len()
    }

    // Get the CTMRWA001StorageManager contract address string for a chainId
    pub fn get_attached_storage_manager(env: Env, rwa_type: u32, version: u32, chain_id_str: String) -> Option<String> {
        let storage = env.storage().persistent();
        let managers: Vec<ChainContract> = storage.get(&DataKey::StorageManager(rwa_type, version))
            .unwrap_or_else(|| Vec::new(&env));

        for cc in managers.iter() {
            if cc.chain_id_str == chain_id_str {
                return Some(cc.contract_str.clone());
            }
        }
        None
    }

    // Get chainId and CTMRWA001SentryManager contract address string at an index
    pub fn get_attached_sentry_manager_at(env: Env, rwa_type: u32, version: u32, index: u32) -> Option<(String, String)> {
        let storage = env.storage().persistent();
        let managers: Vec<ChainContract> = storage.get(&DataKey::SentryManager(rwa_type, version))
            .unwrap_or_else(|| Vec::new(&env));

        if index >= managers.len() {
            return None;
        }

        let cc = managers.get(index).unwrap();
        Some((cc.chain_id_str.clone(), cc.contract_str.clone()))
    }

    // Get the number of stored CTMRWA001SentryManager contracts
    pub fn get_sentry_manager_count(env: Env, rwa_type: u32, version: u32) -> u32 {
        let storage = env.storage().persistent();
        let managers: Vec<ChainContract> = storage.get(&DataKey::SentryManager(rwa_type, version))
            .unwrap_or_else(|| Vec::new(&env));
        managers.len()
    }

    // Get the CTMRWA001SentryManager contract address string for a chainId
    pub fn get_attached_sentry_manager(env: Env, rwa_type: u32, version: u32, chain_id_str: String) -> Option<String> {
        let storage = env.storage().persistent();
        let managers: Vec<ChainContract> = storage.get(&DataKey::SentryManager(rwa_type, version))
            .unwrap_or_else(|| Vec::new(&env));

        for cc in managers.iter() {
            if cc.chain_id_str == chain_id_str {
                return Some(cc.contract_str.clone());
            }
        }
        None
    }

    // Attach CTMRWA001X contracts for chainIds (onlyGov)
    pub fn attach_rwa_x(
        env: Env,
        caller: Address,
        rwa_type: u32,
        version: u32,
        chain_ids: Vec<String>,
        rwa_x_strs: Vec<String>
    ) -> bool {
        caller.require_auth();
        Self::require_gov(&env, &caller);

        if chain_ids.len() != rwa_x_strs.len() {
            panic!("CTMRWAGateway: Argument lengths not equal in attach_rwa_x");
        }

        // Validate contract string lengths
        for contract_str in rwa_x_strs.iter() {
            if contract_str.len() != 42 {
                panic!("CTMRWAGateway: Invalid contract address length");
            }
        }

        let storage = env.storage().persistent();
        let mut rwa_x: Vec<ChainContract> = storage.get(&DataKey::RwaX(rwa_type, version))
            .unwrap_or_else(|| Vec::new(&env));
        let mut rwa_x_chains: Vec<String> = storage.get(&DataKey::RwaXChains(rwa_type, version))
            .unwrap_or_else(|| Vec::new(&env));

        let mut updated = false;
        for (chain_id, contract_str) in chain_ids.iter().zip(rwa_x_strs.iter()) {
            let mut found = false;
            for i in 0..rwa_x.len() {
                if rwa_x.get(i).unwrap().chain_id_str == chain_id {
                    let mut cc = rwa_x.get(i).unwrap();
                    cc.contract_str = contract_str.clone();
                    rwa_x.set(i, cc);
                    found = true;
                    updated = true;
                    break;
                }
            }
            if !found {
                rwa_x.push_back(ChainContract {
                    chain_id_str: chain_id.clone(),
                    contract_str: contract_str.clone(),
                });
                rwa_x_chains.push_back(chain_id.clone());
                updated = true;
            }
        }

        if updated {
            storage.set(&DataKey::RwaX(rwa_type, version), &rwa_x);
            storage.set(&DataKey::RwaXChains(rwa_type, version), &rwa_x_chains);
        }

        env.events().publish(
            (symbol_short!("att_rwax"),),
            (rwa_type, version, chain_ids, rwa_x_strs)
        );

        true
    }

    // Attach CTMRWA001StorageManager contracts for chainIds (onlyGov)
    pub fn attach_storage_manager(
        env: Env,
        caller: Address,
        rwa_type: u32,
        version: u32,
        chain_ids: Vec<String>,
        storage_manager_strs: Vec<String>
    ) -> bool {
        caller.require_auth();
        Self::require_gov(&env, &caller);

        if chain_ids.len() != storage_manager_strs.len() {
            panic!("CTMRWAGateway: Argument lengths not equal in attach_storage_manager");
        }

        // Validate contract string lengths
        for contract_str in storage_manager_strs.iter() {
            if contract_str.len() != 42 {
                panic!("CTMRWAGateway: Invalid contract address length");
            }
        }

        let storage = env.storage().persistent();
        let mut managers: Vec<ChainContract> = storage.get(&DataKey::StorageManager(rwa_type, version))
            .unwrap_or_else(|| Vec::new(&env));

        let mut updated = false;
        for (chain_id, contract_str) in chain_ids.iter().zip(storage_manager_strs.iter()) {
            let mut found = false;
            for i in 0..managers.len() {
                if managers.get(i).unwrap().chain_id_str == chain_id {
                    let mut cc = managers.get(i).unwrap();
                    cc.contract_str = contract_str.clone();
                    managers.set(i, cc);
                    found = true;
                    updated = true;
                    break;
                }
            }
            if !found {
                managers.push_back(ChainContract {
                    chain_id_str: chain_id.clone(),
                    contract_str: contract_str.clone(),
                });
                updated = true;
            }
        }

        if updated {
            storage.set(&DataKey::StorageManager(rwa_type, version), &managers);
        }

        env.events().publish(
            (symbol_short!("att_stor"),),
            (rwa_type, version, chain_ids, storage_manager_strs)
        );

        true
    }


    // Attach CTMRWA001SentryManager contracts for chainIds (onlyGov)
    pub fn attach_sentry_manager(
        env: Env,
        caller: Address,
        rwa_type: u32,
        version: u32,
        chain_ids: Vec<String>,
        sentry_manager_strs: Vec<String>
    ) -> bool {
        caller.require_auth();
        Self::require_gov(&env, &caller);

        if chain_ids.len() != sentry_manager_strs.len() {
            panic!("CTMRWAGateway: Argument lengths not equal in attach_sentry_manager");
        }

        // Validate contract string lengths
        for contract_str in sentry_manager_strs.iter() {
            if contract_str.len() != 42 {
                panic!("CTMRWAGateway: Invalid contract address length");
            }
        }

        let storage = env.storage().persistent();
        let mut managers: Vec<ChainContract> = storage.get(&DataKey::SentryManager(rwa_type, version))
            .unwrap_or_else(|| Vec::new(&env));

        let mut updated = false;
        for (chain_id, contract_str) in chain_ids.iter().zip(sentry_manager_strs.iter()) {
            let mut found = false;
            for i in 0..managers.len() {
                if managers.get(i).unwrap().chain_id_str == chain_id {
                    let mut cc = managers.get(i).unwrap();
                    cc.contract_str = contract_str.clone();
                    managers.set(i, cc);
                    found = true;
                    updated = true;
                    break;
                }
            }
            if !found {
                managers.push_back(ChainContract {
                    chain_id_str: chain_id.clone(),
                    contract_str: contract_str.clone(),
                });
                updated = true;
            }
        }

        if updated {
            storage.set(&DataKey::SentryManager(rwa_type, version), &managers);
        }

        env.events().publish(
            (symbol_short!("att_sent"),),
            (rwa_type, version, chain_ids, sentry_manager_strs)
        );

        true
    }

    // Fallback function for failed c3call
    pub fn c3_fallback(env: Env, selector: Bytes, data: Bytes, reason: Bytes) -> bool {
        env.events().publish(
            (symbol_short!("fallback"),),
            (selector, data, reason)
        );
        true
    }
}