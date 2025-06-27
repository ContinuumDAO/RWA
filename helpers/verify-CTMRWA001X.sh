#/bin/bash!

forge verify-contract \
    --rpc-url https://sepolia-rollup.arbitrum.io/rpc \
    --chain-id  421614 \
    --num-of-optimizations 1000000 \
    --watch \
    --constructor-args $(cast abi-encode "constructor(address,address,address,address,address,uint256)" 0xb27abB5B0C183AFA71d228e634a0112606AAeC9F 0x56249F01CF2B50A7F211Bb9de08B1480835F574a 0xe62Ab4D111f968660C6B2188046F9B9bA53C4Bae 0xeC1f296fC2Dd0FFf803c30DBD315b5457aFaA8B3 0xe62Ab4D111f968660C6B2188046F9B9bA53C4Bae 45) \
    --etherscan-api-key arbSepoliaKey \
    --compiler-version v0.8.20+commit.a1b79de6 \
    --show-standard-json-input > etherscan.json \
    0x92A2f66274fB9E5db9017A300ae9AD5469dF7Fe5 \
    flattened/CTMRWA001X.sol:CTMRWA001X

