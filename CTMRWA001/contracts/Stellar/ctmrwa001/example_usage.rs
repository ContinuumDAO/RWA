// Deploy and initialize
let env = Env::default();
let contract_id = env.register_contract(None, CTMRWA001);
let client = CTMRWA001Client::new(&env, &contract_id);

let admin = Address::random(&env);
let rwa_id = 123u128;
client.initialize(
    &admin,
    &String::from_str(&env, "CTMRWA Token"),
    &String::from_str(&env, "RWA"),
    &18u32,
    &String::from_str(&env, "IPFS"),
    &rwa_id
);

// Create a slot
client.create_slot(
    &admin,
    &1u128,
    &String::from_str(&env, "Gold Slot")
);

// Mint a token
let recipient = Address::random(&env);
let token_id = client.mint(
    &admin,
    &recipient,
    &1u128,
    &String::from_str(&env, "Gold Slot"),
    &1000u128
);

// Transfer value
let to_token_id = client.mint(
    &admin,
    &Address::random(&env),
    &1u128,
    &String::from_str(&env, "Gold Slot"),
    &0u128
);
client.approve(&recipient, &token_id, &admin, &500u128);
client.transfer_from(&admin, &token_id, &to_token_id, &500u128);
