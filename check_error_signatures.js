const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

// Target signature we're looking for
const TARGET_SIGNATURE = '0x8c755a25';

// Function to calculate keccak256 hash
function keccak256(data) {
    return crypto.createHash('sha3-256').update(data).digest('hex');
}

// Function to get first 4 bytes (8 hex characters) of hash
function getSignature(hash) {
    return '0x' + hash.substring(0, 8);
}

// Custom errors found in interface files
const customErrors = [
    // Core errors
    "CTMRWA1_Unauthorized(CTMRWAErrorParam,CTMRWAErrorParam)",
    "CTMRWA1_OnlyAuthorized(CTMRWAErrorParam,CTMRWAErrorParam)",
    "CTMRWA1_IsZeroAddress(CTMRWAErrorParam)",
    "CTMRWA1_NotZeroAddress(CTMRWAErrorParam)",
    "CTMRWA1_IsZeroUint(CTMRWAErrorParam)",
    "CTMRWA1_NonZeroUint(CTMRWAErrorParam)",
    "CTMRWA1_LengthMismatch(CTMRWAErrorParam)",
    "CTMRWA1_ValueOverflow(uint256,uint256)",
    "CTMRWA1_InsufficientBalance()",
    "CTMRWA1_InsufficientAllowance()",
    "CTMRWA1_OutOfBounds()",
    "CTMRWA1_NameTooLong()",
    "CTMRWA1_IDNonExistent(uint256)",
    "CTMRWA1_IDExists(uint256)",
    "CTMRWA1_InvalidSlot(uint256)",
    "CTMRWA1_ReceiverRejected()",
    "CTMRWA1_WhiteListRejected(address)",
    
    // Identity errors
    "CTMRWA1Identity_OnlyAuthorized(CTMRWAErrorParam,CTMRWAErrorParam)",
    "CTMRWA1Identity_IsZeroAddress(CTMRWAErrorParam)",
    "CTMRWA1Identity_InvalidContract(CTMRWAErrorParam)",
    "CTMRWA1Identity_KYCDisabled()",
    "CTMRWA1Identity_AlreadyWhitelisted(address)",
    "CTMRWA1Identity_InvalidKYC(address)",
    
    // Storage errors
    "CTMRWA1StorageManager_OnlyAuthorized(CTMRWAErrorParam,CTMRWAErrorParam)",
    "CTMRWA1StorageManager_InvalidContract(CTMRWAErrorParam)",
    "CTMRWA1StorageManager_NoStorage()",
    "CTMRWA1StorageManager_ObjectAlreadyExists()",
    "CTMRWA1StorageManager_InvalidLength(CTMRWAErrorParam)",
    "CTMRWA1StorageManager_SameChain()",
    "CTMRWA1StorageManager_StartNonce()",
    
    "CTMRWA1Storage_OnlyAuthorized(CTMRWAErrorParam,CTMRWAErrorParam)",
    "CTMRWA1Storage_InvalidID(uint256,uint256)",
    "CTMRWA1Storage_HashExists(bytes32)",
    "CTMRWA1Storage_InvalidSlot(uint256)",
    "CTMRWA1Storage_OutOfBounds()",
    "CTMRWA1Storage_IncreasingNonceOnly()",
    "CTMRWA1Storage_InvalidContract(CTMRWAErrorParam)",
    "CTMRWA1Storage_ForceTransferNotSetup()",
    "CTMRWA1Storage_NoSecurityDescription()",
    "CTMRWA1Storage_IssuerNotFirst()",
    
    "CTMRWA1StorageUtils_OnlyAuthorized(CTMRWAErrorParam,CTMRWAErrorParam)",
    "CTMRWA1StorageUtils_InvalidContract(CTMRWAErrorParam)",
    
    // Map errors
    "CTMRWAMap_OnlyAuthorized(CTMRWAErrorParam,CTMRWAErrorParam)",
    "CTMRWAMap_AlreadyAttached(uint256,address)",
    "CTMRWAMap_FailedAttachment(CTMRWAErrorParam)",
    "CTMRWAMap_IncompatibleRWA(CTMRWAErrorParam)",
    
    // Dividend errors
    "CTMRWA1DividendFactory_OnlyAuthorized(CTMRWAErrorParam,CTMRWAErrorParam)",
    "CTMRWA1Dividend_OnlyAuthorized(CTMRWAErrorParam,CTMRWAErrorParam)",
    "CTMRWA1Dividend_InvalidDividend(CTMRWAErrorParam)",
    "CTMRWA1Dividend_FailedTransaction()",
    "CTMRWA1Dividend_FundingTimeLow()",
    "CTMRWA1Dividend_FundingTimeFuture()",
    "CTMRWA1Dividend_FundingTooFrequent()",
    "CTMRWA1Dividend_FundTokenNotSet()",
    "CTMRWA1Dividend_InvalidSlot(uint256)",
    "CTMRWA1Dividend_EnforcedPause()",
    
    // Crosschain errors
    "CTMRWA1XUtils_OnlyAuthorized(CTMRWAErrorParam,CTMRWAErrorParam)",
    "CTMRWAGateway_LengthMismatch(CTMRWAErrorParam)",
    "CTMRWAGateway_InvalidLength(CTMRWAErrorParam)",
    
    // Sentry errors
    "CTMRWA1SentryManager_OnlyAuthorized(CTMRWAErrorParam,CTMRWAErrorParam)",
    "CTMRWA1SentryManager_IsZeroAddress(CTMRWAErrorParam)",
    "CTMRWA1SentryManager_InvalidContract(CTMRWAErrorParam)",
    "CTMRWA1SentryManager_OptionsAlreadySet()",
    "CTMRWA1SentryManager_NoKYC()",
    "CTMRWA1SentryManager_KYCDisabled()",
    "CTMRWA1SentryManager_AccreditationDisabled()",
    "CTMRWA1SentryManager_LengthMismatch(CTMRWAErrorParam)",
    "CTMRWA1SentryManager_SameChain()",
    "CTMRWA1SentryManager_InvalidLength(CTMRWAErrorParam)",
    "CTMRWA1SentryManager_InvalidList(CTMRWAErrorParam)",
    
    "CTMRWA1SentryUtils_OnlyAuthorized(CTMRWAErrorParam,CTMRWAErrorParam)",
    "CTMRWA1SentryUtils_InvalidContract(CTMRWAErrorParam)",
    
    // Deployment errors
    "CTMRWAERC20Deployer_IsZeroAddress(CTMRWAErrorParam)",
    "CTMRWAERC20Deployer_InvalidContract(CTMRWAErrorParam)",
    "CTMRWAERC20Deployer_OnlyAuthorized(CTMRWAErrorParam,CTMRWAErrorParam)",
    
    "CTMRWAERC20_InvalidContract(CTMRWAErrorParam)",
    "CTMRWAERC20_NonExistentSlot(uint256)",
    "CTMRWAERC20_IsZeroAddress(CTMRWAErrorParam)",
    "CTMRWAERC20_MaxTokens()",
    
    "CTMRWADeployer_OnlyAuthorized(CTMRWAErrorParam,CTMRWAErrorParam)",
    "CTMRWADeployer_InvalidContract(CTMRWAErrorParam)",
    "CTMRWADeployer_IncompatibleRWA(CTMRWAErrorParam)",
    "CTMRWADeployer_IsZeroAddress(CTMRWAErrorParam)",
    
    "CTMRWA1TokenFactory_OnlyAuthorized(CTMRWAErrorParam,CTMRWAErrorParam)",
    
    "CTMRWADeployInvest_OnlyAuthorized(CTMRWAErrorParam,CTMRWAErrorParam)",
    
    "CTMRWA1InvestWithTimeLock_OnlyAuthorized(CTMRWAErrorParam,CTMRWAErrorParam)",
    "CTMRWA1InvestWithTimeLock_InvalidContract(CTMRWAErrorParam)",
    "CTMRWA1InvestWithTimeLock_OutOfBounds()",
    "CTMRWA1InvestWithTimeLock_NonExistentToken(uint256)",
    "CTMRWA1InvestWithTimeLock_MaxOfferings()",
    "CTMRWA1InvestWithTimeLock_InvalidLength(CTMRWAErrorParam)",
    "CTMRWA1InvestWithTimeLock_Paused()",
    "CTMRWA1InvestWithTimeLock_InvalidTimestamp(CTMRWAErrorParam)",
    "CTMRWA1InvestWithTimeLock_InvalidAmount(CTMRWAErrorParam)",
    "CTMRWA1InvestWithTimeLock_NotWhiteListed(address)",
    "CTMRWA1InvestWithTimeLock_AlreadyWithdrawn(uint256)",
    "CTMRWA1InvestWithTimeLock_InvalidOfferingIndex()",
    
    // Fee Manager errors
    "FeeManager_InvalidLength(CTMRWAErrorParam)",
    "FeeManager_NonExistentToken(address)",
    "FeeManager_FailedTransfer()"
];

console.log(`Looking for signature: ${TARGET_SIGNATURE}`);
console.log(`Checking ${customErrors.length} custom errors...\n`);

let found = false;

for (const error of customErrors) {
    const hash = keccak256(error);
    const signature = getSignature(hash);
    
    if (signature === TARGET_SIGNATURE) {
        console.log(`🎯 FOUND MATCH!`);
        console.log(`Error: ${error}`);
        console.log(`Signature: ${signature}`);
        console.log(`Full hash: 0x${hash}\n`);
        found = true;
        break;
    }
}

if (!found) {
    console.log(`❌ No matching signature found for ${TARGET_SIGNATURE}`);
    console.log(`\nAll calculated signatures:`);
    
    for (const error of customErrors) {
        const hash = keccak256(error);
        const signature = getSignature(hash);
        console.log(`${signature} -> ${error}`);
    }
}
