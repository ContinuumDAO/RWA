#!/bin/bash

echo -e "\n🔨 Compiling build/core..."
forge build build/core/
echo -e "🔨 Compiling build/crosschain..."
forge build build/crosschain/
echo -e "🔨 Compiling build/deployment..."
forge build build/deployment/
echo -e "🔨 Compiling build/dividend..."
forge build build/dividend/
echo -e "🔨 Compiling build/identity..."
forge build build/identity/
echo -e "🔨 Compiling build/managers..."
forge build build/managers/
echo -e "🔨 Compiling build/sentry..."
forge build build/sentry/
echo -e "🔨 Compiling build/shared..."
forge build build/shared/
echo -e "🔨 Compiling build/storage..."
forge build build/storage/
