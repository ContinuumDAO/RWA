#!/bin/bash

# Check if required arguments are provided
if [ $# -lt 2 ]; then
    echo "Error: Missing required arguments."
    echo "Usage: $0 <ACCOUNT> <PASSWORD_FILE>"
    echo "Example: $0 0x1234... /path/to/password.txt"
    exit 1
fi

./helpers/configure/arbitrum-sepolia.sh $1 $2
./helpers/configure/arbitrum-sepolia.sh $1 $2
./helpers/configure/arbitrum-sepolia.sh $1 $2
./helpers/configure/bsc-testnet.sh $1 $2
./helpers/configure/holesky.sh $1 $2
./helpers/configure/opbnb-testnet.sh $1 $2
./helpers/configure/scroll-sepolia.sh $1 $2
./helpers/configure/sepolia.sh $1 $2
./helpers/configure/soneium-minato-testnet.sh $1 $2
