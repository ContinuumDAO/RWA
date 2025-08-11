#!/bin/bash

# Export the .env.deployed environment variables
if [ -f .env.deployed ]; then
    export $(cat .env.deployed | xargs)
fi

# Export the .env environment variables (excluding comments and empty lines)
if [ -f .env ]; then
    # Use set -a to automatically export variables and source a filtered version
    set -a
    source <(cat .env | grep -v '^#' | grep -v '^[[:space:]]*$' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    set +a
fi