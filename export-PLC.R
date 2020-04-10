# Simple Script that pulls Orders from Shöpping Order API and saves it as CSV
# May be used for free by Shöpping merchants
#

# Configuration is now loaded from settings.R copy stdsettings.R to settings.R and edit settings.R to make it work

source("settings.R")



library(httr)
library(jsonlite)
library(xml2)

getconfirmed <- "/ws/v1/orders?status=confirmed"
getcreated <- "/ws/v1/orders?status=created"
putconfirmed <- "/ws/v1/orders"

if (!PLC_downloadconfirmed) {
  call <- paste0(baseurl,getcreated)
} else {
  call <- paste0(baseurl,getconfirmed)
}


auth_header <- sub("\n","",paste("Basic",base64_enc(paste0(merchantid,":",apikey))))

filename <- paste0("shoepping-plc-data-",format(Sys.time(), "%Y%m%d-%H%M%S"),".csv")
fc<-file(filename, open = "w+")
print(paste("Using filename",filename))

#Header-Lines can be commented out if not needed
writeLines("Sendungsnummer;PaketRef;EmpfTitel;EmpfName1;EmpfName2;EmpfName3;EmpfTel;EmpfMail;EmpfAdresszeile1;EmpfHausnummer;EmpfPLZ;EmpfOrt;EmpfLand;Gewicht;Produkt;Zusatzleistungen;Retour;ProvinzIsoCode;Rücksendeweg;Rücksendeoption;Rücksendedauer;Zollbeschreibung;Begleitdokumente;Artikelliste",con=fc,sep = "\n")

moredatathere <- TRUE
toconfirm <- vector()


#if we get a paginated result we need to fetch data more often
while( moredatathere )
{

  print("Fetching data from Shöpping")
  rsp <- GET(call,add_headers(Authorization = auth_header))
  result <- read_xml(content(rsp,"text"))
  orders <- xml_find_all(xml_find_first(result,"ns1:orders"),"ns1:order")

  if ( length(orders) )
  {
    print(paste("Saving data into file"))
    for (i in 1:length(orders) ) {

      # somewhen we will want to react on the AddressType and send Pickup Stations properly
      # ,xml_text(xml_find_first(xml_find_first(orders[i],"ns1:deliveryAddress"),"ns1:deliveryAddressType")),";",
      ordernumber <- xml_text(xml_find_first(orders[i],"ns1:code") )
      addresstype <- xml_text(xml_find_first(xml_find_first(orders[i],"ns1:deliveryAddress"),"ns1:deliveryAddressType")) 
      if (  addresstype == "address" )
      {
        toconfirm[ length( toconfirm ) + 1 ] <-  ordernumber
      }
      else
      {
        print(  paste("Warning Order ",ordernumber, "Addresstype",addresstype,"is not properly supported")  )      
      }


      #prepare doornumber as its not always there and needs special care
      ddoornumber <- xml_text(xml_find_first(xml_find_first(orders[i],"ns1:deliveryAddress"),"ns1:doornumber"))
      if (is.na(ddoornumber)) { ddoornumber<-"" } else {ddoornumber<-paste0("/",ddoornumber)}

      #copy all fields into one csv line
      line <- paste(
      ordernumber ,";",
      ordernumber ,";",
      ";",
      xml_text(xml_find_first(xml_find_first(orders[i],"ns1:deliveryAddress"),"ns1:firstName"))," ",
      xml_text(xml_find_first(xml_find_first(orders[i],"ns1:deliveryAddress"),"ns1:lastName")),";",
      xml_text(xml_find_first(xml_find_first(orders[i],"ns1:deliveryAddress"),"ns1:additionalInfo")),";",
      ";;;",
      xml_text(xml_find_first(xml_find_first(orders[i],"ns1:deliveryAddress"),"ns1:streetname")),";",
      xml_text(xml_find_first(xml_find_first(orders[i],"ns1:deliveryAddress"),"ns1:streetnumber")),ddoornumber,";",
      xml_text(xml_find_first(xml_find_first(orders[i],"ns1:deliveryAddress"),"ns1:postalCode")),";",
      xml_text(xml_find_first(xml_find_first(orders[i],"ns1:deliveryAddress"),"ns1:town")),";",
      "AT;",
      ";",
      postproduktcode,";",
      ";;;;;;;;",
      sep="" )
      line <- gsub(";NA;", ";;", line)
      writeLines(line,con=fc,sep = "\n")
      
    }
  }

  #Look if we can find pagination and build a new url if yes otherwise we are done
  nextpage <- xml_find_first(xml_find_all(result,"ns1:pagination"),"ns1:next")
  if ( length( nextpage ) )
  {
    call <- paste0(baseurl,xml_text(nextpage))
    print("Next call")
    print(call)
  } else
  {
    moredatathere <- FALSE
  }
}

if( PLC_confirm & !PLC_downloadconfirmed &  length( toconfirm ) > 0 ) {
  print( paste( "Confirming", length(toconfirm), "orders")  )
  for (i in 1:length(toconfirm) ) {
    body <- paste(
      "<order xmlns='https://portal.shoepping.at/marketplaceportal/resources/merchant/orderStatusInterface.xsd'> ",
      "<orderConfirmed> ",
      "<orderNumber>",
      toconfirm[i],
      "</orderNumber> ",
      "</orderConfirmed> ",
      "</order>", sep="")
    call <- paste0(baseurl,putconfirmed)
    rsp <- POST( url=call, body=body, add_headers( .headers = c( 'Authorization' = auth_header, 'Content-Type' = "application/xml"  ) )  )
    if( !grepl("Order updated successfully",content(rsp, "text") ) ) { print(paste("Warning",toconfirm[i],"not sucessfully confirmed")) }
  }
}

close(fc)
