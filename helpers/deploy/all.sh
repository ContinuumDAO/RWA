#!/bin/bash

# Check if required arguments are provided
if [ $# -lt 2 ]; then
    echo "Error: Missing required arguments."
    echo "Usage: $0 <ACCOUNT> <PASSWORD_FILE>"
    echo "Example: $0 0x1234... /path/to/password.txt"
    exit 1
fi

./helpers/deploy/arbitrum-sepolia.sh $1 $2
./helpers/deploy/arbitrum-sepolia.sh $1 $2
./helpers/deploy/arbitrum-sepolia.sh $1 $2
./helpers/deploy/bsc-testnet.sh $1 $2
./helpers/deploy/holesky.sh $1 $2
./helpers/deploy/opbnb-testnet.sh $1 $2
./helpers/deploy/scroll-sepolia.sh $1 $2
./helpers/deploy/sepolia.sh $1 $2
./helpers/deploy/soneium-minato-testnet.sh $1 $2
