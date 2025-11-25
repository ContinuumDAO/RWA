#!/bin/bash

echo -e "\n🔨 Building src/core..."
forge build src/core/
echo -e "🔨 Building src/crosschain..."
forge build src/crosschain/
echo -e "🔨 Building src/deployment..."
forge build src/deployment/
echo -e "🔨 Building src/dividend..."
forge build src/dividend/
echo -e "🔨 Building src/identity..."
forge build src/identity/
echo -e "🔨 Building src/managers..."
forge build src/managers/
echo -e "🔨 Building src/mocks..."
forge build src/mocks/
echo -e "🔨 Building src/sentry..."
forge build src/sentry/
echo -e "🔨 Building src/shared..."
forge build src/shared/
echo -e "🔨 Building src/storage..."
forge build src/storage/
echo -e "🔨 Building src/utils..."
forge build src/utils/
