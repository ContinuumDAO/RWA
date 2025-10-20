#!/bin/bash

echo -e "\nCompiling build/core..."
forge build build/core/
echo -e "\nCompiling build/crosschain..."
forge build build/crosschain/
echo -e "\nCompiling build/deployment..."
forge build build/deployment/
echo -e "\nCompiling build/dividend..."
forge build build/dividend/
echo -e "\nCompiling build/identity..."
forge build build/identity/
echo -e "\nCompiling build/managers..."
forge build build/managers/
echo -e "\nCompiling build/sentry..."
forge build build/sentry/
echo -e "\nCompiling build/shared..."
forge build build/shared/
echo -e "\nCompiling build/storage..."
forge build build/storage/

