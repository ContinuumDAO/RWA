#!/bin/bash

forge clean

# flattened
echo -e "\nBuilding flattened/core..."
forge build flattened/core
echo -e "\nBuilding flattened/crosschain..."
forge build flattened/crosschain
echo -e "\nBuilding flattened/deployment..."
forge build flattened/deployment
echo -e "\nBuilding flattened/dividend..."
forge build flattened/dividend
echo -e "\nBuilding flattened/identity..."
forge build flattened/identity
echo -e "\nBuilding flattened/managers..."
forge build flattened/managers
echo -e "\nBuilding flattened/sentry..."
forge build flattened/sentry
echo -e "\nBuilding flattened/shared..."
forge build flattened/shared
echo -e "\nBuilding flattened/storage..."
forge build flattened/storage

