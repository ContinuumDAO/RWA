// Rwa class is the object that is written to Greenfield for ALL storage classes.
// The property item chnages depending on the CATEGORY of the storage
class Rwa {
    constructor (
        rwaTitle,
        rwaType,
        slot,
        rwaCategory,
        rwaProperty,
        rwaText
    ) {
        this.title = rwaTitle,
        this.type = rwaType,
        this.category = rwaCategory,
        this.properties = rwaProperty,
        this.text = rwaText
    }
}

// This is the first and OBLIGATORY entry that ALL RWAs must write to storage, unless NONE was selected for storage class 
// It dscribes the Issuer of the RWA
class Issuer {
    constructor(
        forename,
        lastname,
        company_position,
        company,
        address,
        country_of_registration,
        company_number,
        company_registration_link,
        email,
        telegram_group,
        website_url,
        x_account,
        telephone_country_prefix,
        telephone_number,
        lawracle_link
    ) {
            this.forename = forename,
            this.lastname = lastname,
            this.company_position = company_position,
            this.company = company,
            this.address = address,
            this.country_of_registration = country_of_registration,
            this.company_number = company_number,
            this.company_registration_link = company_registration_link,
            this.email = email,
            this.telegram_group = telegram_group,
            this.website_url = website_url,
            this.x_account = x_account,
            this.telephone_country_prefix = telephone_country_prefix,
            this.telephone_number = telephone_number,
            this.lawracle_link = lawracle_link
    }
}

// This Notice class can be used for any statement that the Issuer wishes holders to see. 
// The name, position and email is the author of the Notice. The actual Notice is written into the text section of the Rwa class
class Notice {
    constructor(
        forename,
        lastname,
        position,
        email
    ) {
        this.forename = forename
        this.lastname = lastname
        this.position - position
        this.email = email
    }
}


// This desribes how the asset behind the RWA tokens is held, together with a legal statement regarding it in the lawracle link
// The holding_entity could be an SPV, or TRUST, or COMPANY. The text associated with the Rwa class should include any legal text proving that the 
// asset is uniquely tokenized by this RWA and that the entity is solely established to issue and redeem the assets
class Provenance {
    constructor(
        holding_entity,
        entity_type,
        country_of_registration,
        company_number,
        company_registration_link,
        asset_ownership_statement,
        token_uniqueness,
        lawracle_link
    ) {
        this.holding_entity = holding_entity,
        this.entity_type = entity_type,
        this.country_of_registration = country_of_registration,
        this.company_number = company_number,
        this.company_registration_link = company_registration_link,
        this.asset_ownership_statement = asset_ownership_statement,
        this.token_uniqueness = token_uniqueness,
        this.lawracle_link = lawracle_link
    }
}

// This is a valuation statement for the asset, by some recognised valuer of assets of this description
// Details of the valuer are included so that a holder can check with them the authenticity of the valuation
class Valuation {
    constructor(
        valuer_name,
        valuer_address,
        valuer_country_of_registration,
        valuer_company_number,
        company_registration_link,
        valuer_email,
        valuer_website,
        valuer_telephone_country_code,
        valuer_telephone_number,
        valuation_per_unit,
        valuation_currency
    ) {
        this.valuer_name = valuer_name,
        this.valuer_address = valuer_address,
        this.valuer_country_of_registration = valuer_country_of_registration,
        this.valuer_company_number = valuer_company_number,
        this.company_registration_link = company_registration_link,
        this.valuer_email = valuer_email,
        this.valuer_website = valuer_website,
        this.valuer_telephone_country_code = valuer_telephone_country_code,
        this.valuer_telephone_number = valuer_telephone_number,
        this.valuation_per_unit = valuation_per_unit,
        this.valuation_currency = valuation_currency
    }
}

// This is a statement regarding the Rating of RWA token by a recognised ratings Agency
class Rating {
    constructor(
        agency_name,
        agency_address,
        agency_country_of_registration,
        agency_company_number,
        company_registration_link,
        agency_email,
        agency_website,
        agency_telephone_country_code,
        agency_telephone_number,
        credit_rating,
        expiry_date
    ) {
        this.agency_name = agency_name
        this.agency_address = agency_address,
        this.agency_country_of_registration = agency_country_of_registration,
        this.agency_company_number = agency_company_number,
        this.company_registration_link = company_registration_link,
        this.agency_email = agency_email,
        this.agency_website = agency_website,
        this.agency_telephone_country_code = agency_telephone_country_code,
        this.agency_telephone_number = agency_telephone_number,
        this.credit_rating = credit_rating,
        this.expiry_date = expiry_date
    }
}

// This is any legal statement regarding the RWA, or the Issuer, together with a Lawracle link to verify the statement
class Legal {
    constructor(
        forename,
        lastname,
        position,
        email,
        lawracle_link
    ) {
        this.forename = forename
        this.lastname = lastname
        this.position - position
        this.email = email
        this.lawracle_link = lawracle_link
    }
}

// This is any financial statement regarding the Issuer by a recognised accountancy comapny, such as Balance sheet, P&L etc.
// Details of the accountants is included
class Financial {
    constructor(
        accountancy_name,
        accountancy_address,
        accountancy_email,
        accountancy_website,
        accountancy_company_number,
        accountancy_registration_link
    ) {
        this.accountancy_name = accountancy_name
        this.accountancy_address = accountancy_address
        this.accountancy_email = accountancy_email
        this.accountancy_website = accountancy_website
        this.accountancy_company_number = accountancy_company_number
        this.accountancy_registration_link = accountancy_registration_link
    }
}

// This is ther actual License for the RWA Security, tyogether with details about the Authority and official license number
class License {
    constructor(
        licensing_authority,
        license_number,
        authority_website,
        license_link
    ) {
        this.licensing_authority = licensing_authority
        this.license_number = license_number
        this.authority_website = authority_website
        this.license_link = license_link
    }
}

// This is a statement regarding some aspect of the Issuer by some recognised managament consultancy, describing the competency
// of the Issuer to perform their duties as custodian and executor etc. It could include management capability, marketing etc.
class DueDiligence {
    constructor(
        company_name,
        company_address,
        company_email,
        company_website,
        company_number,
        company_registration_link
    ) {
        this.company_name = company_name
        this.company_address = company_address
        this.company_email = company_email
        this.company_website = company_website
        this.company_number = company_number
        this.company_registration_link = company_registration_link
    }
}

// This is a Dividend statement for net income to be distributed to holders of the RWA for a past period
class Dividend {
    constructor(
        forename,
        lastname,
        position,
        email
    ) {
        this.forename = forename
        this.lastname = lastname
        this.position = position
        this.email = email
    }
}

// This describes how an RWA token holder can swap their tokens for the underlying asset. It includes the cost of doing so and any other details
class Redemption {
    constructor(
        contact_forename,
        contact_lastname,
        contact_position,
        contact_email,
        fee_currency,
        fixed_fee,
        variable_fee_per_unit,
        redemption_time_completion,
        redemption_conditions
    ) {
        this.contact_forename = contact_forename
        this.contact_lastname = contact_lastname
        this.contact_position = contact_position
        this.contact_email = contact_email
        this.fee_currency = fee_currency
        this.fixed_fee = fixed_fee
        this.variable_fee_per_unit = variable_fee_per_unit
        this.redemption_time_completion = redemption_time_completion
        this.redemption_conditions = redemption_conditions
    }
}

// this describes who can actually legally invest in this RWA. The investor_category could be "PUBLIC", or "ACCREDITED"
// It also states who may NOT invest by country and also the maximum permittable number of investors if this condition of the license applies
class WhoCanInvest {
    constructor(
        KYC_required,
        investor_category,
        investor_country_list,
        max_number_of_investors,
        prohibited_jurisdictions
    ) {
        this.KYC_required = KYC_required
        this.investor_category = investor_category
        this.investor_country_list = investor_country_list
        this.max_number_of_investors = max_number_of_investors
        this.prohibited_jurisdictions = prohibited_jurisdictions
    }
}

// This is the data for any image associated with the asset, or any of its slots. the image data has to be in BASE64 format
class Image {
    constructor(
        image_name,
        image_data
    ) {
        this.image_name = image_name
        this.image_data = image_data
    }
}


const addIssuer = () => {

    const rwaTitle = "# ISSUER DETAILS"
    const rwaType = "CONTRACT"
    const slot = ""
    const rwaCategory = "ISSUER"
    const rwaText = "## Sellers of the finest assets\n Do yourself a favour and buy some"

    const rwaIssuer = new Issuer(
        "Selqui",
        "CTM",
        "Co-Founder",
        "ContinuumDAO",
        "The World",
        "Xanadu",
        "12345678XN",
        "https:XanaduCompanyRegistrationOffice",
        "abc@continuumdao.org",
        "@ContinuumDAO",
        "https://continuumdao.org",
        "https://x.com/ContinuumDAO",
        "+555",
        "55555555",
        "https://somelawfirm.com/lawracle/continuumdao/1/"
    )

    const newRwaURI = new Rwa(
        rwaTitle,
        rwaType,
        slot,
        rwaCategory,
        rwaIssuer,
        rwaText       
    )

    console.log(newRwaURI.properties.email)

}

const addNotice = () => {
    const rwaTitle = "# Important update for token holders of slot 4"
    const rwaType = "SLOT"
    const slot = "4"
    const rwaCategory = "NOTICE"
    const rwaText = "## No new assets will be minted for this slot class and all available assets will be sold"

    const rwaNotice = new Notice(
        "John",
        "Doe",
        "Marketing Manager",
        "john.doe@Acme.com"
    )

    const newRwaURI = new Rwa(
        rwaTitle,
        rwaType,
        slot,
        rwaCategory,
        rwaNotice,
        rwaText       
    )

    console.log(newRwaURI.properties.email)

}

const addProvenance = () => {
    const rwaTitle = "# Asset Ownership Structure"
    const rwaType = "CONTRACT"
    const slot = ""
    const rwaCategory = "PROVENANCE"
    const rwaText = "## All assets are secure"

    const rwaProvenance = new Provenance(
        "CtmAssetHoldings Gmbh",
        "Special Purpose Vehicle",
        "Germany",
        "12345DE",
        "https://www.unternehmensregister.de/ureg/?submitaction=language&language=en",
        "All assets are held by the SPV, whose function is to tokenize the assets and distribute revenue, less costs to token holders",
        true,
         "https://somelawfirm.com/lawracle/continuumdao/2/"
    )

    const newRwaURI = new Rwa(
        rwaTitle,
        rwaType,
        slot,
        rwaCategory,
        rwaProvenance,
        rwaText       
    )

    console.log(newRwaURI.properties.asset_ownership_statement)
}

const addValuation = () => {
    const rwaTitle = "# Asset Valuation"
    const rwaType = "SLOT"
    const slot = "4"
    const rwaCategory = "VALUATION"
    const rwaText = "**Assets are not guaranteed to keep this value**"

    const rwaValuation = new Valuation(
        "Dubai Luxury Apartments Ltd.",
        "Burj Calif, Floor 23, No 6.",
        "UAE",
        "12345UAE",
        "https://uaecompanies.ae/discover-companies",
        "valuations@DLARealEstate.ae",
        "https://DLARealEstate.ae",
        "+97",
        "54545454",
        "440760.00",
        "AED"
    )

    const newRwaURI = new Rwa(
        rwaTitle,
        rwaType,
        slot,
        rwaCategory,
        rwaValuation,
        rwaText       
    )

    console.log(newRwaURI.properties.valuation_currency)

}

const addRating = () => {

    const rwaTitle = "# Asset Rating"
    const rwaType = "SLOT"
    const slot = "4"
    const rwaCategory = "RATING"
    const rwaText = "### A full list of credit ratings and their interpretation can be found on our [website](https://cer.live/methodology/cryptocurrencies)"

    const rwaRating = new Rating(
        "CER",
        "",
        "",
        "",
        "",
        "contact@cer.live",
        "https://cer.live/token",
        "",
        "",
        "AAB",
        "1764782345"  // Linux time
    )

    const newRwaURI = new Rwa(
        rwaTitle,
        rwaType,
        slot,
        rwaCategory,
        rwaRating,
        rwaText       
    )
}

const addLegal = () => {
    const rwaTitle = "# Legal Statement"
    const rwaType = "CONTRACT"
    const slot = ""
    const rwaCategory = "LEGAL"
    const rwaText = "### The asset holding company is changing to XYZ Ltd. Details here :- ... "

    const rwaLegal = new Legal (
        "John",
        "Doe",
        "Marketing Manager",
        "john.doe@Acme.com",
        "https://somelawfirm.com/lawracle/continuumdao/3/"
    )

    const newRwaURI = new Rwa(
        rwaTitle,
        rwaType,
        slot,
        rwaCategory,
        rwaLegal,
        rwaText       
    )
}

const addFinancial = () => {

    const rwaTitle = "# Balance Sheet Statement"
    const rwaType = "CONTRACT"
    const slot = ""
    const rwaCategory = "FINANCIAL"
    const rwaText = "## Balance Sheet ACME Ltd. 12/12/2024\n Cash on hand   777777777, Fixed assets 3333333 etc."

    const rwaFinancial = new Financial(
        "CPA Financial Services Ltd.",
        "12, The Castle, Belmere Rd, Y89TYRE, UK",
        "info@cpafinancial.co.uk",
        "https://cpafinancial.co.uk",
        "123456UK",
        "https://ukcomapaniesoffice.gov.uk"
    )

    const newRwaURI = new Rwa(
        rwaTitle,
        rwaType,
        slot,
        rwaCategory,
        rwaFinancial,
        rwaText       
    )

}

const addLicense = () => {
    const rwaTitle = "# Security License"
    const rwaType = "CONTRACT"
    const slot = ""
    const rwaCategory = "LICENSE"
    const rwaText = "## License Granted to Acme Ltd. for Issuance of a Security"

    const rwaLicense = new License (
        "VARA",
        "1234-56DT",
        "https://vara.ae",
        "https://vara.ae/current-licenses/1234-56DT"
    )

    const newRwaURI = new Rwa(
        rwaTitle,
        rwaType,
        slot,
        rwaCategory,
        rwaLicense,
        rwaText       
    )

}

const addDueDiligence = () => {

    const rwaTitle = "# Report on the in-house Production Capacity of ACME Ltd."
    const rwaType = "CONTRACT"
    const slot = ""
    const rwaCategory = "DUEDILIGENCE"
    const rwaText = "### Production Capacity of ACME Ltd.\n The factory at xxxxx has 221 personnel dedicated to ..."

    const rwaDueDiligence = new DueDiligence(
        "TTR Management Consultancy Ltd.",
        "88 Tree drive, Northanpton, H7651TN, UK",
        "contact@ttrconsultancy.co.uk",
        "https://ttrconsultancy.co.uk",
        "1238623UK",
        "https://ukcomapaniesoffice.gov.uk"
    )
    
    const newRwaURI = new Rwa(
        rwaTitle,
        rwaType,
        slot,
        rwaCategory,
        rwaDueDiligence,
        rwaText       
    )
}

const addDividend = () => {

    const rwaTitle = "# Dividend to be distributed to SLOT 4 Asset Class for 2024"
    const rwaType = "SLOT"
    const slot = "4"
    const rwaCategory = "DIVIDEND"
    const rwaText = "### Dividend Distribution Slot 4 \n A total net profit of 1,234,567 USD was generated in 2024 to be distributed to holders of slot 4. The total supply was 9832, so 234 USD per unit etc. ..."

    const rwaDividend = new Dividend(
        "Jane",
        "Priestly",
        "Financial Manager",
        "jane.priestly@Acme.com"
    )

    const newRwaURI = new Rwa(
        rwaTitle,
        rwaType,
        slot,
        rwaCategory,
        rwaDividend,
        rwaText       
    )
}

const addRedemption = () => {

    const rwaTitle = "# How to Swap Tokens in Slot 4 for Assets"
    const rwaType = "SLOT"
    const slot = "4"
    const rwaCategory = "REDEMPTION"
    const rwaText = "### Procedure to de-tokenize slot 4 tokens in exchange for underlying land\n Please make contact with our company rep. indicating that you wish to redeem some assets etc. ..."

    const rwaRedemption = new Redemption(
        "Adam",
        "Doe",
        "Services Manager",
        "adam.doe@Acme.com",
        "GBP",
        4800.0,
        1200.50,
        "3 months",
        "Redemption is subject to direct contact by lawyers representing you to transfer land deeds"
    )

    const newRwaURI = new Rwa(
        rwaTitle,
        rwaType,
        slot,
        rwaCategory,
        rwaRedemption,
        rwaText       
    )

}

const addWhoCanInvest = () => {

    const rwaTitle = "# Statement about Who Can Invest in Slot 4 Assets"
    const rwaType = "SLOT"
    const slot = "4"
    const rwaCategory = "WHOCANINVEST"
    const rwaText = "### The conditions about who may invest are established by th terms of our License"

    const rwaWhoCanInvest = new WhoCanInvest (
        true,
        "ACCREDITED",
        ["UK", "EU"],
        "unlimited",
        "OFAC Prohibited"
    )

    const newRwaURI = new Rwa(
        rwaTitle,
        rwaType,
        slot,
        rwaCategory,
        rwaWhoCanInvest,
        rwaText       
    )

}

const addImage = () => {

    const rwaTitle = "# Image of Land in Slot 4 Assets"
    const rwaType = "SLOT"
    const slot = "4"
    const rwaCategory = "IMAGE"
    const rwaText = "### Typical plot of slot 4 Land"

    const rwaImage = new Image(
        "Plot 234 in slot 4",
        "a lot of BASE64 data"
    )

    const newRwaURI = new Rwa(
        rwaTitle,
        rwaType,
        slot,
        rwaCategory,
        rwaImage,
        rwaText       
    )
}

const addIcon = () => {

    const rwaTitle = "# "
    const rwaType = "CONTRACT"
    const slot = ""
    const rwaCategory = "ICON"
    const rwaText = "### Icon for Assets"

    const rwaImage = new Image(
        "",
        "a lot of BASE64 data"
    )

    const newRwaURI = new Rwa(
        rwaTitle,
        rwaType,
        slot,
        rwaCategory,
        rwaImage,
        rwaText       
    )
}


const main = async () => {

    addIssuer()
    addProvenance()
    addValuation()
    addNotice()
    addRating()
    addLegal()
    addFinancial()
    addLicense()
    addDueDiligence()
    addDividend()
    addRedemption()
    addWhoCanInvest()
    addImage()
    addIcon()

}

main()