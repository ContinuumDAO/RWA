

const {
    Rwa,
    Issuer,
    Notice,
    Provenance,
    Valuation,
    Rating,
    Legal,
    Financial,
    Prospectus,
    License,
    DueDiligence,
    Dividend,
    Redemption,
    WhoCanInvest,
    Image,
    
} = require('./storage_classes.js')

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

const addProspectus = () => {
    const rwaTitle = "# Prospectus for Company Acme Diamonds"
    const rwaType = "CONTRACT"
    const slot = ""
    const rwaCategory = "PROSPECTUS"
    const rwaText = ""

    const rwaProspectus = new Prospectus("1.0")

    const newRwaURI = new Rwa(
        rwaTitle,
        rwaType,
        slot,
        rwaCategory,
        rwaProspectus,
        rwaText       
    )

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
        "PNG",
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
    addProspectus()
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