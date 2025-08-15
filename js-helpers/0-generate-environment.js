const fs = require("fs")
const path = require("path")
const dotenv = require("dotenv")

// Check for command line argument
const includeAnvil = process.argv.length > 2 && process.argv[2] === "--anvil"

// Load environment variables from .env file
const result = dotenv.config()
if (result.error) {
    console.error("Error loading .env file:", result.error)
    process.exit(1)
}

// Get the broadcast directory path
const broadcastDir = path.join(__dirname, "../broadcast/DeployAssetX.s.sol")

if (!fs.existsSync(broadcastDir)) {
    console.error("Error: Broadcast directory not found")
    console.error(`Expected directory: ${broadcastDir}`)
    process.exit(1)
}

// Get all chain ID directories
const chainDirs = fs.readdirSync(broadcastDir, { withFileTypes: true })
    .filter(dirent => dirent.isDirectory())
    .map(dirent => dirent.name)

if (chainDirs.length === 0) {
    console.error("Error: No chain directories found in broadcast/DeployAssetX.s.sol/")
    process.exit(1)
}

// Filter chain directories based on argument
const filteredChainDirs = includeAnvil 
    ? chainDirs 
    : chainDirs.filter(chainId => chainId !== "31337")

if (filteredChainDirs.length === 0) {
    console.error("Error: No chain directories to process after filtering")
    process.exit(1)
}

console.log(`Found chain directories: ${chainDirs.join(", ")}`)
if (!includeAnvil) {
    console.log("Excluding chain ID 31337 (anvil) - use 'node generate-environment.js anvil' to include it")
}
console.log(`Processing chain directories: ${filteredChainDirs.join(", ")}`)

let environment = ""
let allChainIds = []

// Process each chain directory
filteredChainDirs.forEach((chainId, chainIdIndex) => {
    const runFilePath = path.join(broadcastDir, chainId, "run-latest.json")
    
    if (!fs.existsSync(runFilePath)) {
        console.warn(`Warning: run-latest.json not found for chain ID ${chainId}`)
        return
    }
    
    console.log(`Processing chain ID: ${chainId}`)

    const chainIdStr = `CHAIN_ID_${chainIdIndex}`
    environment += `${chainIdStr}=${chainId}\n`

    try {
        // Load the deployment data
        const deploymentData = require(runFilePath)
        
        // Process transactions to extract contract addresses
        deploymentData.transactions.forEach((tx, index) => {
            if (tx.transactionType === "CREATE" && tx.contractAddress && !tx.contractName.includes("Proxy")) {
                const contractName = tx.contractName
                const contractAddress = tx.contractAddress
                
                // Map contract names to the expected keys
                switch (contractName) {
                    case "FeeManager":
                        const feeManagerProxyTx = deploymentData.transactions[index + 1]
                        if (feeManagerProxyTx.contractName.includes("Proxy")) {
                            environment += `FEE_MANAGER_${chainId}=${feeManagerProxyTx.contractAddress}\n`
                        } else {
                            console.log(`Fee Manager was not followed by a Proxy, saving implementation address instead.`)
                            environment += `FEE_MANAGER_${chainId}=${contractAddress}\n`
                        }
                        break
                    case "CTMRWAGateway":
                        const gatewayProxyTx = deploymentData.transactions[index + 1]
                        if (gatewayProxyTx.contractName.includes("Proxy")) {
                            environment += `GATEWAY_${chainId}=${gatewayProxyTx.contractAddress}\n`
                        } else {
                            console.log(`Gateway was not followed by a Proxy, saving implementation address instead.`)
                            environment += `GATEWAY_${chainId}=${contractAddress}\n`
                        }
                        break
                    case "CTMRWA1X":
                        const rwa1XProxyTx = deploymentData.transactions[index + 1]
                        if (rwa1XProxyTx.contractName.includes("Proxy")) {
                            environment += `RWA1X_${chainId}=${rwa1XProxyTx.contractAddress}\n`
                        } else {
                            console.log(`RWA1X was not followed by a Proxy, saving implementation address instead.`)
                            environment += `RWA1X_${chainId}=${contractAddress}\n`
                        }
                        break
                    case "CTMRWA1XFallback":
                        environment += `RWA1X_FALLBACK_${chainId}=${contractAddress}\n`
                        break
                    case "CTMRWAMap":
                        const mapProxyTx = deploymentData.transactions[index + 1]
                        if (mapProxyTx.contractName.includes("Proxy")) {
                            environment += `MAP_${chainId}=${mapProxyTx.contractAddress}\n`
                        } else {
                            console.log(`Map was not followed by a Proxy, saving implementation address instead.`)
                            environment += `MAP_${chainId}=${contractAddress}\n`
                        }
                        break
                    case "CTMRWADeployer":
                        const deployerProxyTx = deploymentData.transactions[index + 1]
                        if (deployerProxyTx.contractName.includes("Proxy")) {
                            environment += `DEPLOYER_${chainId}=${deployerProxyTx.contractAddress}\n`
                        } else {
                            console.log(`Deployer was not followed by a Proxy, saving implementation address instead.`)
                            environment += `DEPLOYER_${chainId}=${contractAddress}\n`
                        }
                        break
                    case "CTMRWADeployInvest":
                        environment += `DEPLOY_INVEST_${chainId}=${contractAddress}\n`
                        break
                    case "CTMRWAERC20Deployer":
                        environment += `ERC20_DEPLOYER_${chainId}=${contractAddress}\n`
                        break
                    case "CTMRWA1TokenFactory":
                        environment += `TOKEN_FACTORY_${chainId}=${contractAddress}\n`
                        break
                    case "CTMRWA1DividendFactory":
                        environment += `DIVIDEND_FACTORY_${chainId}=${contractAddress}\n`
                        break
                    case "CTMRWA1StorageManager":
                        const storageManagerProxyTx = deploymentData.transactions[index + 1]
                        if (storageManagerProxyTx.contractName.includes("Proxy")) {
                            environment += `STORAGE_MANAGER_${chainId}=${storageManagerProxyTx.contractAddress}\n`
                        } else {
                            console.log(`Storage Manager was not followed by a Proxy, saving implementation address instead.`)
                            environment += `STORAGE_MANAGER_${chainId}=${contractAddress}\n`
                        }
                        break
                    case "CTMRWA1StorageUtils":
                        environment += `STORAGE_UTILS_${chainId}=${contractAddress}\n`
                        break
                    case "CTMRWA1SentryManager":
                        const sentryManagerProxyTx = deploymentData.transactions[index + 1]
                        if (sentryManagerProxyTx.contractName.includes("Proxy")) {
                            environment += `SENTRY_MANAGER_${chainId}=${sentryManagerProxyTx.contractAddress}\n`
                        } else {
                            console.log(`Sentry Manager was not followed by a Proxy, saving implementation address instead.`)
                            environment += `SENTRY_MANAGER_${chainId}=${contractAddress}\n`
                        }
                        break
                    case "CTMRWA1SentryUtils":
                        environment += `SENTRY_UTILS_${chainId}=${contractAddress}\n`
                        break
                }
            }
        })

        const feeTokenKey = `FEE_TOKEN_${chainId}`
        const feeTokenValue = process.env[feeTokenKey]
        environment += `${feeTokenKey}=${feeTokenValue || "0x0000000000000000000000000000000000000000"}\n\n`

        allChainIds.push(chainId)
        
    } catch (error) {
        console.error(`Error processing chain ID ${chainId}:`, error.message)
    }
})

// Add N_CHAINS count
const nChainsStr = `N_CHAINS=${allChainIds.length}\n\n`

// Write the environment file to the root directory
const outputPath = path.join(__dirname, "../.env.deployed")
fs.writeFileSync(outputPath, nChainsStr + environment)

console.log(`Environment file generated successfully for chain IDs: ${allChainIds.join(", ")}`)
console.log(`Output file: ${outputPath}`)
console.log(`Total chain IDs processed: ${allChainIds.length}`)