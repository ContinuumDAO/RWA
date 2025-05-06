use soroban_sdk::{
    contract, contractimpl, contracttype, symbol_short, vec, Address, Env, String, Vec, Map,
    log, BytesN, Bytes
};

// Storage keys for persistent data
#[contracttype]
#[derive(Clone)]
pub enum DataKey {
    RwaType,                // u32: RWA Type
    Version,                // u32: verrsion
    TokenAdmin,             // Address: Contract admin
    Id,                     // BytesN<32>: Unique RWA ID
    TokenIdGenerator,       // u128: Next token ID
    Name,                   // String: Token name
    Symbol,                 // String: Token symbol
    Decimals,               // u32: Value decimals
    BaseUri,                // String: Base URI (e.g., "IPFS")
    Tokens(u128),           // TokenData: Token info by token ID
    TokenIndex(u128),       // u128: Index in all_tokens
    AllTokens,              // Vec<TokenData>: All tokens
    OwnedTokens(Address),   // Vec<u128>: Tokens owned by address
    ApprovedValues(u128, Address), // u128: Approved value for (token_id, operator)
    Slots(u128),            // SlotData: Slot info by slot ID
    SlotIndex(u128),        // u128: Index in all_slots
    AllSlots,               // Vec<SlotData>: All slots
    SlotTokens(u128),       // Vec<u128>: Token IDs in slot
    SlotTokensIndex(u128, u128), // u128: Index of token in slot's token list
}

// Token data structure
#[contracttype]
#[derive(Clone)]
pub struct TokenData {
    id: u128,               // Unique token ID
    slot: u128,             // Slot ID
    balance: u128,          // Fungible balance
    owner: Address,         // Owner address
    approved: Option<Address>, // Approved operator
    value_approvals: Vec<Address>, // Addresses approved to spend value
}

// Slot data structure
#[contracttype]
#[derive(Clone)]
pub struct SlotData {
    slot: u128,             // Slot ID
    slot_name: String,      // Slot name
    dividend_rate: u128,    // Dividend rate (for future extension)
    slot_tokens: Vec<u128>, // Token IDs in this slot
}

#[contract]
pub struct ctm_rwa001;

#[contractimpl]
impl ctm_rwa001 {
    // Initialize the contract
    pub fn initialize(
        env: Env,
        rwa_type: u32,
        version: u32,
        token_admin: Address,
        token_name: String,
        symbol: String,
        decimals: u32,
        base_uri: String,
        rwa_id: BytesN<32>
    ) {
        let storage = env.storage().persistent();

        // Ensure not already initialized
        if storage.has(&DataKey::TokenAdmin) {
            panic!("Contract already initialized");
        }

        // Set contract metadata
        storage.set(&DataKey::RwaType, &rwa_type);
        storage.set(&DataKey::Version, &version);
        storage.set(&DataKey::TokenAdmin, &token_admin);
        storage.set(&DataKey::Id, &rwa_id);
        storage.set(&DataKey::TokenIdGenerator, &1u128);
        storage.set(&DataKey::Name, &token_name);
        storage.set(&DataKey::Symbol, &symbol);
        storage.set(&DataKey::Decimals, &decimals);
        storage.set(&DataKey::BaseUri, &base_uri);
        storage.set(&DataKey::AllTokens, &Vec::<TokenData>::new(&env));
        storage.set(&DataKey::AllSlots, &Vec::<SlotData>::new(&env));

        // Emit initialization event (optional)
        env.events().publish(
            (symbol_short!("init"),),
            (token_admin, token_name, symbol, rwa_id)
        );
    }

    // Modifier-like check for token admin
    fn require_token_admin(env: &Env, caller: &Address) {
        let token_admin: Address = env.storage().persistent().get(&DataKey::TokenAdmin).unwrap();
        if caller != &token_admin {
            panic!("Caller is not token admin");
        }
    }

    // Modifier-like check for minter (simplified to admin-only for now)
    fn require_minter(env: &Env, caller: &Address) {
        Self::require_token_admin(env, caller);
    }

    // Get contract name
    pub fn name(env: Env) -> String {
        env.storage().persistent().get(&DataKey::Name).unwrap()
    }

    // Get contract symbol
    pub fn symbol(env: Env) -> String {
        env.storage().persistent().get(&DataKey::Symbol).unwrap()
    }

    // Get value decimals
    pub fn value_decimals(env: Env) -> u32 {
        env.storage().persistent().get(&DataKey::Decimals).unwrap()
    }

    // Create a new slot
    pub fn create_slot(env: Env, caller: Address, slot: u128, slot_name: String) {
        Self::require_token_admin(&env, &caller); // Simplified: only admin can create slots

        let storage = env.storage().persistent();
        if storage.has(&DataKey::Slots(slot)) {
            panic!("Slot already exists");
        }

        let slot_data = SlotData {
            slot,
            slot_name: slot_name.clone(),
            dividend_rate: 0,
            slot_tokens: vec![&env],
        };

        // Add to all slots
        let mut all_slots: Vec<SlotData> = storage.get(&DataKey::AllSlots).unwrap_or(vec![&env]);
        storage.set(&DataKey::SlotIndex(slot), &(all_slots.len() as u128));
        all_slots.push_back(slot_data.clone());
        storage.set(&DataKey::AllSlots, &all_slots);
        storage.set(&DataKey::Slots(slot), &slot_data);

        // Emit slot creation event
        env.events().publish(
            (symbol_short!("new_slot"),),
            (slot, slot_name)
        );
    }

    // Mint a new token
    pub fn mint(env: Env, caller: Address, to: Address, slot: u128, slot_name: String, value: u128) -> u128 {
        Self::require_minter(&env, &caller);
        to.require_auth(); // Ensure recipient authorizes the transaction
    
        let storage = env.storage().persistent();
    
        // Verify slot exists
        if !storage.has(&DataKey::Slots(slot)) {
            panic!("Slot does not exist");
        }
    
        // Generate new token_id
        let token_id: u128 = storage.get(&DataKey::TokenIdGenerator).unwrap_or(1);
        storage.set(&DataKey::TokenIdGenerator, &(token_id + 1));
    
        // Create token data
        let token_data = TokenData {
            id: token_id,
            slot,
            balance: value,
            owner: to.clone(),
            approved: None,
            value_approvals: Vec::<Address>::new(&env),
        };
    
        // Store token data
        storage.set(&DataKey::Tokens(token_id), &token_data);
        storage.set(&DataKey::TokenIndex(token_id), &(token_id - 1));
    
        // Add to all tokens
        let mut all_tokens: Vec<TokenData> = storage.get(&DataKey::AllTokens).unwrap_or(Vec::<TokenData>::new(&env));
        all_tokens.push_back(token_data.clone());
        storage.set(&DataKey::AllTokens, &all_tokens);
    
        // Add to owner's token list
        let mut owned_tokens: Vec<u128> = storage.get(&DataKey::OwnedTokens(to.clone())).unwrap_or(Vec::<u128>::new(&env));
        owned_tokens.push_back(token_id);
        storage.set(&DataKey::OwnedTokens(to.clone()), &owned_tokens);
    
        // Add to slot's token list
        let mut slot_data: SlotData = storage.get(&DataKey::Slots(slot)).unwrap();
        storage.set(&DataKey::SlotTokensIndex(slot, token_id), &(slot_data.slot_tokens.len() as u128));
        slot_data.slot_tokens.push_back(token_id);
        storage.set(&DataKey::Slots(slot), &slot_data);
    
        // Emit events
        env.events().publish(
            (symbol_short!("transfer"),),
            (None::<Address>, to.clone(), token_id)
        );
        env.events().publish(
            (symbol_short!("trans_val"),),
            (0u128, token_id, value)
        );
        env.events().publish(
            (symbol_short!("slot_mod"),),
            (token_id, 0u128, slot)
        );
    
        token_id
    }

    // Approve an operator to spend value from a token
    pub fn approve(env: Env, caller: Address, token_id: u128, to: Address, value: u128) {
        let storage = env.storage().persistent();
        let token_data: TokenData = storage.get(&DataKey::Tokens(token_id)).unwrap_or_else(|| panic!("Token does not exist"));

        // Check if caller is owner
        if caller != token_data.owner {
            panic!("Caller is not token owner");
        }

        // Prevent self-approval
        if to == token_data.owner {
            panic!("Cannot approve to current owner");
        }

        // Update value approvals
        let mut token_data = token_data.clone();
        if !token_data.value_approvals.contains(&to) {
            token_data.value_approvals.push_back(to.clone());
        }
        storage.set(&DataKey::Tokens(token_id), &token_data);
        storage.set(&DataKey::ApprovedValues(token_id, to.clone()), &value);

        // Emit approval event
        env.events().publish(
            (symbol_short!("app_val"),),
            (token_id, to, value)
        );
    }

    // Transfer value from one token to another
    pub fn transfer_from(env: Env, caller: Address, from_token_id: u128, to_token_id: u128, value: u128) -> Address {
        let storage = env.storage().persistent();

        // Load token data
        let mut from_token: TokenData = storage.get(&DataKey::Tokens(from_token_id)).unwrap_or_else(|| panic!("From token does not exist"));
        let mut to_token: TokenData = storage.get(&DataKey::Tokens(to_token_id)).unwrap_or_else(|| panic!("To token does not exist"));

        // Check permissions
        let allowance: u128 = storage.get(&DataKey::ApprovedValues(from_token_id, caller.clone())).unwrap_or(0);
        if caller != from_token.owner && allowance < value {
            panic!("Insufficient allowance or not owner");
        }

        // Verify same slot
        if from_token.slot != to_token.slot {
            panic!("Tokens must be in the same slot");
        }

        // Check balance
        if from_token.balance < value {
            panic!("Insufficient balance");
        }

        // Update balances
        from_token.balance -= value;
        to_token.balance += value;

        // Update storage
        storage.set(&DataKey::Tokens(from_token_id), &from_token);
        storage.set(&DataKey::Tokens(to_token_id), &to_token);

        // Update allowance if applicable
        if caller != from_token.owner {
            storage.set(&DataKey::ApprovedValues(from_token_id, caller.clone()), &(allowance - value));
        }

        // Emit transfer event
        env.events().publish(
            (symbol_short!("trans_val"),),
            (from_token_id, to_token_id, value)
        );

        to_token.owner
    }

    // Transfer a token to another address
    pub fn transfer_token(env: Env, caller: Address, from: Address, to: Address, token_id: u128) {
        let storage = env.storage().persistent();
        let mut token_data: TokenData = storage.get(&DataKey::Tokens(token_id)).unwrap_or_else(|| panic!("Token does not exist"));
    
        // Check permissions
        if caller != from || from != token_data.owner {
            panic!("Caller is not owner");
        }
    
        // Ensure recipient authorizes
        to.require_auth();
    
        // Update owner
        token_data.owner = to.clone();
        storage.set(&DataKey::Tokens(token_id), &token_data);
    
        // Update owned tokens
        let mut from_tokens: Vec<u128> = storage.get(&DataKey::OwnedTokens(from.clone())).unwrap_or(vec![&env]);
        let index = from_tokens.iter().position(|x| x == token_id).unwrap();
        from_tokens.remove(index as u32);
        storage.set(&DataKey::OwnedTokens(from.clone()), &from_tokens);
    
        let mut to_tokens: Vec<u128> = storage.get(&DataKey::OwnedTokens(to.clone())).unwrap_or(vec![&env]);
        to_tokens.push_back(token_id);
        storage.set(&DataKey::OwnedTokens(to.clone()), &to_tokens);
    
        // Clear approvals
        token_data.approved = None;
        token_data.value_approvals = Vec::<Address>::new(&env);
        storage.set(&DataKey::Tokens(token_id), &token_data);
    
        // Emit transfer event
        env.events().publish(
            (symbol_short!("transfer"),),
            (Some(from), to, token_id)
        );
    }

    // Get token balance
    pub fn balance_of(env: Env, token_id: u128) -> u128 {
        let storage = env.storage().persistent();
        let token_data: TokenData = storage.get(&DataKey::Tokens(token_id)).unwrap_or_else(|| panic!("Token does not exist"));
        token_data.balance
    }

    // Get number of tokens owned by an address
    pub fn balance_of_address(env: Env, owner: Address) -> u128 {
        let storage = env.storage().persistent();
        let owned_tokens: Vec<u128> = storage.get(&DataKey::OwnedTokens(owner)).unwrap_or(vec![&env]);
        owned_tokens.len() as u128
    }

    // Get owner of a token
    pub fn owner_of(env: Env, token_id: u128) -> Address {
        let storage = env.storage().persistent();
        let token_data: TokenData = storage.get(&DataKey::Tokens(token_id)).unwrap_or_else(|| panic!("Token does not exist"));
        token_data.owner
    }

    // Get slot of a token
    pub fn slot_of(env: Env, token_id: u128) -> u128 {
        let storage = env.storage().persistent();
        let token_data: TokenData = storage.get(&DataKey::Tokens(token_id)).unwrap_or_else(|| panic!("Token does not exist"));
        token_data.slot
    }

    // Get slot name
    pub fn slot_name(env: Env, slot: u128) -> String {
        let storage = env.storage().persistent();
        let slot_data: SlotData = storage.get(&DataKey::Slots(slot)).unwrap_or_else(|| panic!("Slot does not exist"));
        slot_data.slot_name
    }

    // Check if token exists
    pub fn require_minted(env: Env, token_id: u128) -> bool {
        env.storage().persistent().has(&DataKey::Tokens(token_id))
    }

    // Check if slot exists
    pub fn slot_exists(env: Env, slot: u128) -> bool {
        env.storage().persistent().has(&DataKey::Slots(slot))
    }
}

#[cfg(test)]
mod test {
    use super::*;
    use soroban_sdk::{testutils::{Address as _, Events}, vec, Env};

    #[test]
    fn test_initialize_and_mint() {
        let env = Env::default();
        env.mock_all_auths(); // Mock all authorizations for the test
        let contract_id = env.register_contract(None, CTMRWA001);
        let client = CTMRWA001Client::new(&env, &contract_id);

        let rwa_type: u32 = 1;
        let version: u32 = 1;
        let admin = Address::generate(&env);
        let id = BytesN::from_array(&env, &[6; 32]);
        let recipient = Address::generate(&env);

        // Initialize
        client.initialize(
            &rwa_type,
            &version,
            &admin,
            &String::from_str(&env, "CTMRWA Token"),
            &String::from_str(&env, "RWA"),
            &18u32,
            &String::from_str(&env, "IPFS"),
            &id
        );

        // Create slot
        client.create_slot(&admin, &1u128, &String::from_str(&env, "Gold Slot"));

        // Mint token
        let token_id = client.mint(
            &admin,
            &recipient,
            &1u128,
            &String::from_str(&env, "Gold Slot"),
            &1000u128
        );

        // Verify state
        assert_eq!(client.balance_of(&token_id), 1000u128);
        assert_eq!(client.owner_of(&token_id), recipient);
        assert_eq!(client.slot_of(&token_id), 1u128);

        // Verify events
        let events = env.events().all();
        // assert!(events.iter().any(|e| e.0.contains(&symbol_short!("init"))));
        // assert!(events.iter().any(|e| e.0.contains(&symbol_short!("transfer"))));
    }
}