#!/bin/bash

echo -e "\nBuilding test/core..."
forge build test/core/
echo -e "\nBuilding test/crosschain..."
forge build test/crosschain/
echo -e "\nBuilding test/deployment..."
forge build test/deployment/
echo -e "\nBuilding test/dividend..."
forge build test/dividend/
echo -e "\nBuilding test/identity..."
forge build test/identity/
echo -e "\nBuilding test/managers..."
forge build test/managers/
echo -e "\nBuilding test/sentry..."
forge build test/sentry/
echo -e "\nBuilding test/shared..."
forge build test/shared/
echo -e "\nBuilding test/storage..."
forge build test/storage/
