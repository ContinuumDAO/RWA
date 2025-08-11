const fs = require("fs")
const path = require("path")
const dotenv = require("dotenv")

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

// Load environment variables from .env file
const result = dotenv.config()
if (result.error) {
    console.error("Error loading .env file:", result.error)
    process.exit(1)
}


let list = {}

// Process each chain directory
chainDirs.forEach(chainId => {
    const runFilePath = path.join(broadcastDir, chainId, "run-latest.json")

    list[chainId] = {}

    if (!fs.existsSync(runFilePath)) {
        console.warn(`Warning: run-latest.json not found for chain ID ${chainId}`)
        return
    }
    
    console.log(`Processing chain ID: ${chainId}`)
    
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
                        list[chainId].feeManagerProxy = feeManagerProxyTx.contractAddress
                        list[chainId].feeManagerImpl = contractAddress
                        break
                    case "CTMRWAGateway":
                        const gatewayProxyTx = deploymentData.transactions[index + 1]
                        list[chainId].gatewayProxy = gatewayProxyTx.contractAddress
                        list[chainId].gatewayImpl = contractAddress
                        break
                    case "CTMRWA1X":
                        const rwa1XProxyTx = deploymentData.transactions[index + 1]
                        list[chainId].rwa1XProxy = rwa1XProxyTx.contractAddress
                        list[chainId].rwa1XImpl = contractAddress
                        break
                    case "CTMRWA1XFallback":
                        list[chainId].rwa1XFallback = contractAddress
                        break
                    case "CTMRWAMap":
                        const mapProxyTx = deploymentData.transactions[index + 1]
                        list[chainId].mapProxy = mapProxyTx.contractAddress
                        list[chainId].mapImpl = contractAddress
                        break
                    case "CTMRWADeployer":
                        const deployerProxyTx = deploymentData.transactions[index + 1]
                        list[chainId].deployerProxy = deployerProxyTx.contractAddress
                        list[chainId].deployerImpl = contractAddress
                        break
                    case "CTMRWADeployInvest":
                        list[chainId].deployInvest = contractAddress
                        break
                    case "CTMRWAERC20Deployer":
                        list[chainId].erc20Deployer = contractAddress
                        break
                    case "CTMRWA1TokenFactory":
                        list[chainId].tokenFactory = contractAddress
                        break
                    case "CTMRWA1DividendFactory":
                        list[chainId].dividendFactory = contractAddress
                        break
                    case "CTMRWA1StorageManager":
                        const storageManagerProxyTx = deploymentData.transactions[index + 1]
                        list[chainId].storageManagerProxy = storageManagerProxyTx.contractAddress
                        list[chainId].storageManagerImpl = contractAddress
                        break
                    case "CTMRWA1StorageUtils":
                        list[chainId].storageUtils = contractAddress
                        break
                    case "CTMRWA1SentryManager":
                        const sentryManagerProxyTx = deploymentData.transactions[index + 1]
                        list[chainId].sentryManagerProxy = sentryManagerProxyTx.contractAddress
                        list[chainId].sentryManagerImpl = contractAddress
                        break
                    case "CTMRWA1SentryUtils":
                        list[chainId].sentryUtils = contractAddress
                        break
                }
            }
        })

        list[chainId].feeToken = process.env[`FEE_TOKEN_${chainId}`] || "0x0000000000000000000000000000000000000000"
    } catch (error) {
        console.error(`Error processing chain ID ${chainId}:`, error.message)
    }
})

// Write the contract addresses file to the root directory
const outputPath = path.join(__dirname, "../contract-addresses.json")
fs.writeFileSync(outputPath, JSON.stringify(list, null, 2))

console.log(`Contract addresses file generated successfully for chain IDs: ${Object.keys(list).join(", ")}`)
console.log(`Output file: ${outputPath}`)
console.log(`Total chain IDs processed: ${Object.keys(list).length}`)
