#! /bin/bash

clear -x

# src
echo -e "\nBuilding src/core..."
forge build src/core
echo -e "\nBuilding src/crosschain..."
forge build src/crosschain
echo -e "\nBuilding src/deployment..."
forge build src/deployment
echo -e "\nBuilding src/dividend..."
forge build src/dividend
echo -e "\nBuilding src/identity..."
forge build src/identity
echo -e "\nBuilding src/managers..."
forge build src/managers
echo -e "\nBuilding src/mocks..."
forge build src/mocks
echo -e "\nBuilding src/sentry..."
forge build src/sentry
echo -e "\nBuilding src/shared..."
forge build src/shared
echo -e "\nBuilding src/storage..."
forge build src/storage
echo -e "\nBuilding src/utils..."
forge build src/utils

# test
echo -e "\nBuilding test/core..."
forge build test/core
echo -e "\nBuilding test/crosschain..."
forge build test/crosschain
echo -e "\nBuilding test/deployment..."
forge build test/deployment
echo -e "\nBuilding test/dividend..."
forge build test/dividend
echo -e "\nBuilding test/identity..."
forge build test/identity
echo -e "\nBuilding test/managers..."
forge build test/managers
echo -e "\nBuilding test/sentry..."
forge build test/sentry
echo -e "\nBuilding test/shared..."
forge build test/shared
echo -e "\nBuilding test/storage..."
forge build test/storage
