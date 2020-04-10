# merchantid: your Merchant ID
# apikey: your API-Key
# downloadconfirmed: FALSE will download created orders, TRUE will download already confirmed
# confirm: TRUE orders will be confirmed, FALSE orders will stay created
# baseurl: points to the shöpping API endpoints (either staging or productive)
# edit this file and save it under settings.R

merchantid <- "xxx-xxx"
apikey <- "xxx-xxx-xxx-xxx"

baseurl <- "https://portal.staging.shoepping.at"
#baseurl <- "https://portal.shoepping.at"


#for the warehouse downloader
warehouse-downloadconfirmed <- FALSE
warehouse-confirm <- TRUE

#for the PLC downloader
PLC-downloadconfirmed <- FALSE
PLC-confirm <- TRUE
postproduktcode <- "10"

