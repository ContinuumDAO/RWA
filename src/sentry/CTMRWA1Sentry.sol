// SPDX-License-Identifier: BSL-1.1

pragma solidity 0.8.27;

import { ICTMRWA1, ITokenContract } from "../core/ICTMRWA1.sol";
import { ICTMRWAMap } from "../shared/ICTMRWAMap.sol";
import { Address, CTMRWAUtils, Uint } from "../utils/CTMRWAUtils.sol";
import { ICTMRWA1Sentry } from "./ICTMRWA1Sentry.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

contract CTMRWA1Sentry is ICTMRWA1Sentry {
    using Strings for *;
    using CTMRWAUtils for string;

    address public tokenAddr;
    uint256 public ID;
    uint256 public immutable RWA_TYPE;
    uint256 public immutable VERSION;
    address sentryManagerAddr;
    address public tokenAdmin;
    address public ctmRwa1X;
    address public ctmRwa1Map;

    string appId; // same as Merchant No
    string programNo;
    address cooperator;

    bool public sentryOptionsSet;

    // // Whitelist of wallets permitted to hold CTMRWA1
    string[] public ctmWhitelist;
    mapping(string => uint256) private whitelistIndx;

    // List of countries for KYC (white OR black listed, depending on flag)
    string[] public countryList;
    mapping(string => uint256) private countryIndx;

    // Switches to be set by tokenAdmin

    bool public whitelistSwitch;
    bool public kycSwitch;
    bool public kybSwitch;
    bool public countryWLSwitch;
    bool public countryBLSwitch;
    bool public accreditedSwitch;
    bool public age18Switch;

    modifier onlyTokenAdmin() {
        if (msg.sender != tokenAdmin && msg.sender != ctmRwa1X) {
            revert CTMRWA1Sentry_OnlyAuthorized(Address.Sender, Address.TokenAdmin);
        }
        _;
    }

    modifier onlySentryManager() {
        if (msg.sender != sentryManagerAddr) {
            revert CTMRWA1Sentry_OnlyAuthorized(Address.Sender, Address.SentryManager);
        }
        _;
    }

    constructor(
        uint256 _ID,
        address _tokenAddr,
        uint256 _rwaType,
        uint256 _version,
        address _sentryManager,
        address _map
    ) {
        ID = _ID;
        RWA_TYPE = _rwaType;
        VERSION = _version;
        ctmRwa1Map = _map;

        tokenAddr = _tokenAddr;

        tokenAdmin = ICTMRWA1(tokenAddr).tokenAdmin();
        ctmRwa1X = ICTMRWA1(tokenAddr).ctmRwa1X();

        sentryManagerAddr = _sentryManager;

        ctmWhitelist.push("0xffffffffffffffffffffffffffffffffffffffff"); // indx 0 is no go
        _setWhitelist(tokenAdmin.toHexString()._stringToArray(), CTMRWAUtils._boolToArray(true));

        countryList.push("NOGO");
    }

    /** @dev Thiss function is normally called by CTMRWA1X to set a new tokenAdmin
     * It can also be called by the current tokenAdmin, but htis should not normally be required
     * and would only happen to clean up in the event of a cross-chain failure to reset the tokenAdmin
     * @param _tokenAdmin The new tokenAdmin address
     * @return success True if the tokenAdmin was set, false otherwise.
     */
    function setTokenAdmin(address _tokenAdmin) external onlyTokenAdmin returns (bool) {
        tokenAdmin = _tokenAdmin;

        if (tokenAdmin != address(0)) {
            string memory tokenAdminStr = tokenAdmin.toHexString()._toLower();
            tokenAdminStr = _tokenAdmin.toHexString()._toLower();
            // don't leave stranded tokens by the old tokenAdmin
            _setWhitelist(tokenAdminStr._stringToArray(), CTMRWAUtils._boolToArray(true));
        }

        return (true);
    }

    /** @dev This funtion is called by SentryManager. See there for details
     * @param _appId The appId for the zkMe KYC service
     * @param _programNo The programNo for the zkMe KYC service
     * @param _cooperator The cooperator address for the zkMe KYC service
     */
    function setZkMeParams(string memory _appId, string memory _programNo, address _cooperator)
        external
        onlySentryManager
    {
        appId = _appId;
        programNo = _programNo;
        cooperator = _cooperator;
    }

    /**
     * @notice Recover the currently stored parameters for the zkMe KYC service
     * @return appId The appId for the zkMe KYC service
     * @return programNo The programNo for the zkMe KYC service
     * @return cooperator The cooperator address for the zkMe KYC service
     */
    function getZkMeParams() public view returns (string memory, string memory, address) {
        return (appId, programNo, cooperator);
    }

    /** @dev Set the sentry options on the local chain. This function is called by CTMRWA1SentryManager
     * @param _ID The ID of the RWA token
     * @param _whitelist The whitelist switch
     * @param _kyc The KYC switch
     * @param _kyb The KYB switch
     * @param _over18 The over 18 switch
     */
    function setSentryOptionsLocal(
        uint256 _ID,
        bool _whitelist,
        bool _kyc,
        bool _kyb,
        bool _over18,
        bool _accredited,
        bool _countryWL,
        bool _countryBL
    ) external onlySentryManager {
        if (_ID != ID) {
            revert CTMRWA1Sentry_InvalidID(ID, _ID);
        }

        if (_whitelist) {
            whitelistSwitch = true;
        }

        if (_kyc) {
            kycSwitch = true;
        }

        if (_kyb && _kyc) {
            kybSwitch = true;
        }

        if (_over18 && _kyc) {
            age18Switch = true;
        }

        if (_countryWL && _kyc) {
            countryWLSwitch = true;
            accreditedSwitch = _accredited;
        } else if (_countryBL && _kyc) {
            countryBLSwitch = true;
        }

        sentryOptionsSet = true;
    }

    /** @dev Set the Whitelist status on this chain. This contract holds the Whitelist state. This contract
     * is called by CTMRWA1SentryManager
     * @param _ID The ID of the RWA token
     * @param _wallets The list of wallets to set the state for
     * @param _choices The list of choices for the wallets
     */
    function setWhitelistSentry(uint256 _ID, string[] memory _wallets, bool[] memory _choices)
        external
        onlySentryManager
    {
        if (_ID != ID) {
            revert CTMRWA1Sentry_InvalidID(ID, _ID);
        }
        _setWhitelist(_wallets, _choices);
    }

    /** @dev Set the country Whitelist ot Blacklist on this chain. This contract holds the state. This contract
     * is called by CTMRWA1SentryManager
     * @param _ID The ID of the RWA token
     * @param _countryList The list of countries to set the state for
     * @param _choices The list of choices for the countries
     */
    function setCountryListLocal(uint256 _ID, string[] memory _countryList, bool[] memory _choices)
        external
        onlySentryManager
    {
        if (_ID != ID) {
            revert CTMRWA1Sentry_InvalidID(ID, _ID);
        }

        _setCountryList(_countryList, _choices);
    }

    /** @dev Internal function to manage the wallet Whitelist
     * @param _wallets The list of wallets to set the state for
     * @param _choices The list of choices for the wallets
     */
    function _setWhitelist(string[] memory _wallets, bool[] memory _choices) internal {
        uint256 len = _wallets.length;

        uint256 indx;
        string memory adminStr = tokenAdmin.toHexString()._toLower();
        string memory walletStr;
        string memory oldLastStr;

        for (uint256 i = 0; i < len; i++) {
            walletStr = _wallets[i]._toLower();
            indx = whitelistIndx[walletStr];

            if (walletStr.equal(adminStr) && !_choices[i]) {
                // revert("CTMRWA1Sentry: Cannot remove tokenAdmin from the whitelist");
                revert CTMRWA1Sentry_Unauthorized(Address.Wallet, Address.TokenAdmin);
            } else if (indx != 0 && indx == ctmWhitelist.length - 1 && !_choices[i]) {
                // last entry to be removed
                whitelistIndx[walletStr] = 0;
                ctmWhitelist.pop();
            } else if (indx != 0 && !_choices[i]) {
                // existing entry to be removed and precludes changing tokenAdmin
                oldLastStr = ctmWhitelist[ctmWhitelist.length - 1];
                ctmWhitelist[indx] = oldLastStr;
                whitelistIndx[walletStr] = 0;
                whitelistIndx[oldLastStr] = indx;
                ctmWhitelist.pop();
            } else if (indx == 0 && _choices[i]) {
                // New entry
                ctmWhitelist.push(walletStr);
                whitelistIndx[walletStr] = ctmWhitelist.length - 1;
            }
        }
    }

    /** @dev Internal function to manage the state for a stored country Whitelist or Blacklist on this chain
     * @param _countries The list of countries to set the state for
     * @param _choices The list of choices for the countries
     */
    function _setCountryList(string[] memory _countries, bool[] memory _choices) internal {
        uint256 len = _countries.length;
        uint256 indx;
        string memory oldLastStr;

        for (uint256 i = 0; i < len; i++) {
            indx = countryIndx[_countries[i]];

            if (indx != 0 && indx == countryList.length - 1 && !_choices[i]) {
                // last entry to be removed
                countryIndx[_countries[i]] = 0;
                countryList.pop();
            } else if (indx != 0 && !_choices[i]) {
                // existing entry to be removed
                oldLastStr = countryList[countryList.length - 1];
                countryList[indx] = oldLastStr;
                countryIndx[_countries[i]] = 0;
                countryIndx[oldLastStr] = indx;
                countryList.pop();
            } else if (indx == 0 && _choices[i]) {
                // New entry
                countryList.push(_countries[i]);
                countryIndx[_countries[i]] = countryList.length - 1;
            }
        }
    }

    /**
     * @notice This function checks if an address is allowed to receive value. It is called by
     * _beforeValueTransfer in CTMRWA1 before any transfers. The contracts CTMRWA1Dividend and
     * CTMRWA1Storage are allowed to pass.
     * @param _user address as a string that is being checked
     */
    function isAllowableTransfer(string memory _user) public view returns (bool) {
        bool ok;
        address dividendContract;
        (ok, dividendContract) = ICTMRWAMap(ctmRwa1Map).getDividendContract(ID, RWA_TYPE, VERSION);

        address investContract;
        (ok, investContract) = ICTMRWAMap(ctmRwa1Map).getInvestContract(ID, RWA_TYPE, VERSION);

        if (!whitelistSwitch || _user._stringToAddress() == address(0)) {
            return (true);
        } else if (_user.equal(dividendContract.toHexString()) || _user.equal(investContract.toHexString())) {
            return (true);
        } else {
            string memory walletStr = _user._toLower();
            return (_isWhitelisted(walletStr));
        }
    }

    /// @notice Get the number of Whitelisted wallet addresses (excluding the unused first one)
    function getWhitelistLength() public view returns (uint256) {
        return (ctmWhitelist.length - 1);
    }

    /**
     * @notice Get the Whitelist wallet address at an index as string
     * @param _indx The index of into the Whitelist to check
     */
    function getWhitelistAddressAtIndx(uint256 _indx) public view returns (string memory) {
        if (_indx >= ctmWhitelist.length) {
            revert CTMRWA1Sentry_OutofBounds();
        }
        return (ctmWhitelist[_indx]);
    }

    /**
     * @notice Check if a particular address (as a string) is Whitelisted
     * @param _walletStr The address (as a string) to check
     */
    function _isWhitelisted(string memory _walletStr) internal view returns (bool) {
        uint256 indx = whitelistIndx[_walletStr];

        if (indx == 0) {
            return (false);
        } else {
            return (true);
        }
    }

    function cID() internal view returns (uint256) {
        return block.chainid;
    }
}
