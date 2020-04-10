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

if (!warehouse_downloadconfirmed) {
  call <- paste0(baseurl,getcreated)
} else {
  call <- paste0(baseurl,getconfirmed)
}


auth_header <- sub("\n","",paste("Basic",base64_enc(paste0(merchantid,":",apikey))))

filename <- paste0("shoepping-orders-",format(Sys.time(), "%Y%m%d-%H%M%S"),".csv")
fc<-file(filename, open = "w+")
print(paste("Using filename",filename))

#Header-Lines can be commented out if not needed
writeLines("ORDER;code;orderdate;shipmentdate;dlv-fname;dlv-lname;dlv-additionalinfo;dlv-street;dlv-housenum;dlv-city;dlv-postalcode;dlv-gender;dlv-addresstype;inv-fname;inv-additionalinfo;inv-lname;inv-street;inv-housenum;inv-city;inv-postalcode;inv-gender;totalbaseprice;merchantdiscount;merchantsubtotal;marketplacediscount;subtotal;deliverycost;totalprice;paymentmode;deliverymode;additionaldeliveryoption;deliveryconfiguration",con=fc,sep = "\n")
writeLines("POS;order;sku;name;quantity;baseprice;totalprice;taxclass;warehouse",con=fc,sep = "\n")


moredatathere <- TRUE
toconfirm <- vector()

#if we get a paginated result we need to fetch data more often
while( moredatathere )
{

  print("Fetching data from Shöpping")
  rsp <- GET(call,add_headers(Authorization = auth_header))
  result <- read_xml(content(rsp,"text"))
  orders <- xml_find_all(xml_find_first(result,"ns1:orders"),"ns1:order")

  print(paste("Saving data into file"))
  for (i in 1:length(orders) ) {
    #print(paste("processing ",xml_text(xml_find_first(orders[i],"ns1:code"))))
    if ( !length( xml_find_all(orders[i],".//ns1:serviceProductGroup") ) ) {

      #prepare doornumber as its not always there and needs special care
      ddoornumber <- xml_text(xml_find_first(xml_find_first(orders[i],"ns1:deliveryAddress"),"ns1:doornumber"))
      if (is.na(ddoornumber)) { ddoornumber<-"" } else {ddoornumber<-paste0("/",ddoornumber)}
      idoornumber <- xml_text(xml_find_first(xml_find_first(orders[i],"ns1:paymentAddress"),"ns1:doornumber"))
      if (is.na(idoornumber)) { idoornumber<-"" } else {idoornumber<-paste0("/",idoornumber)}

      #copy all fields into one csv line
      line <- paste(
      "ORDER",";",
      "\"",xml_text(xml_find_first(orders[i],"ns1:code") ) ,"\";",
      xml_text(xml_find_first(orders[i],"ns1:date") ) ,";",
      xml_text(xml_find_first(orders[i],"ns1:shipmentDate") ) ,";",
      "\"",xml_text(xml_find_first(xml_find_first(orders[i],"ns1:deliveryAddress"),"ns1:firstName")),"\";",
      "\"",xml_text(xml_find_first(xml_find_first(orders[i],"ns1:deliveryAddress"),"ns1:lastName")),"\";",
      "\"",xml_text(xml_find_first(xml_find_first(orders[i],"ns1:deliveryAddress"),"ns1:additionalInfo")),"\";",
      "\"",xml_text(xml_find_first(xml_find_first(orders[i],"ns1:deliveryAddress"),"ns1:streetname")),"\";",
      "\"",xml_text(xml_find_first(xml_find_first(orders[i],"ns1:deliveryAddress"),"ns1:streetnumber")),ddoornumber,"\";",
      "\"",xml_text(xml_find_first(xml_find_first(orders[i],"ns1:deliveryAddress"),"ns1:town")),"\";",
      "\"",xml_text(xml_find_first(xml_find_first(orders[i],"ns1:deliveryAddress"),"ns1:postalCode")),"\";",
      "\"",xml_text(xml_find_first(xml_find_first(orders[i],"ns1:deliveryAddress"),"ns1:gender")),"\";",
      "\"",xml_text(xml_find_first(xml_find_first(orders[i],"ns1:deliveryAddress"),"ns1:deliveryAddressType")),"\";",
      "\"",xml_text(xml_find_first(xml_find_first(orders[i],"ns1:paymentAddress"),"ns1:firstName")),"\";",
      "\"",xml_text(xml_find_first(xml_find_first(orders[i],"ns1:paymentAddress"),"ns1:lastName")),"\";",
      "\"",xml_text(xml_find_first(xml_find_first(orders[i],"ns1:paymentAddress"),"ns1:additionalInfo")),"\";",
      "\"",xml_text(xml_find_first(xml_find_first(orders[i],"ns1:paymentAddress"),"ns1:streetname")),"\";",
      "\"",xml_text(xml_find_first(xml_find_first(orders[i],"ns1:paymentAddress"),"ns1:streetnumber")),idoornumber,"\";",
      "\"",xml_text(xml_find_first(xml_find_first(orders[i],"ns1:paymentAddress"),"ns1:town")),"\";",
      "\"",xml_text(xml_find_first(xml_find_first(orders[i],"ns1:paymentAddress"),"ns1:postalCode")),"\";",
      "\"",xml_text(xml_find_first(xml_find_first(orders[i],"ns1:paymentAddress"),"ns1:gender")),"\";",
      xml_text(xml_find_first(orders[i],"ns1:totalBasePrice") ) ,";",
      xml_text(xml_find_first(orders[i],"ns1:merchantDiscountTotal") ) ,";",
      xml_text(xml_find_first(orders[i],"ns1:merchantSubTotal") ) ,";",
      xml_text(xml_find_first(orders[i],"ns1:marketplaceDiscountTotal") ) ,";",
      xml_text(xml_find_first(orders[i],"ns1:subtotal") ) ,";",
      xml_text(xml_find_first(orders[i],"ns1:deliveryCost") ) ,";",
      xml_text(xml_find_first(orders[i],"ns1:totalPrice") ) ,";",
      "\"",xml_text(xml_find_first(orders[i],"ns1:paymentMode") ) ,"\";",
      "\"",xml_text(xml_find_first(orders[i],"ns1:deliveryMode") ) ,"\";",
      "\"",xml_text(xml_find_first(orders[i],"ns1:additionalDeliveryOption") ) ,"\";",
      "\"",xml_text(xml_find_first(orders[i],"ns1:deliveryConfiguration") ) ,"\"",
      sep="" )
      line <- gsub("\"NA\"", "", line)
      writeLines(line,con=fc,sep = "\n")
      toconfirm[ length( toconfirm ) + 1 ] <-  xml_text(xml_find_first(orders[i],"ns1:code" ) )

      #process products of an order
      products <-  xml_children(xml_find_first(orders[i],"ns1:entries"))
      for (j in 1:length(products)) {
       pp <- paste(
          "POS",";",
          "\"",xml_text(xml_find_first(orders[i],"ns1:code") ) ,"\";",
          "\"",xml_text(xml_find_first(products[j],"ns1:sku") ),"\";",
          "\"",xml_text(xml_find_first(products[j],"ns1:name") ),"\";",
          xml_text(xml_find_first(products[j],"ns1:quantity") ),";",
          xml_text(xml_find_first(products[j],"ns1:basePrice") ),";",
          xml_text(xml_find_first(products[j],"ns1:totalPrice") ),";",
          "\"",xml_text(xml_find_first(products[j],"ns1:taxClass") ),"\";",
          "\"",xml_text(xml_find_first(products[j],"ns1:warehouse") ),"\"",
          sep="" )
      writeLines(pp,con=fc,sep = "\n")
      }
      rm(products)
    }
    else
    {
      print(paste("WARNING: omited order",xml_text(xml_find_first(orders[i],"ns1:code")),"Service products are not supported, please handle it in merchant portal" ))
    }
  }

  #Look if we can find pagination and build a new url if yes otherwise we are done
  nextpage <- xml_find_first(xml_find_all(result,"ns1:pagination"),"ns1:next")
  if ( length( nextpage ) )
  {
     call <- paste0(baseurl,xml_text(nextpage))
  } else
  {
    moredatathere <- FALSE
  }
}


if( warehouse_confirm & !warehouse_downloadconfirmed &  length( toconfirm ) > 0 ) {
  print( paste( "Confirming", length(toconfirm), "orders")  )
  for (i in 1:length(toconfirm) ) {
    body <- paste(
      "<order xmlns=\"https://portal.shoepping.at/marketplaceportal/resources/merchant/orderStatusInterface.xsd\">",
      "<orderConfirmed>",
      "<orderNumber>",
      toconfirm[i],
      "</orderNumber>",
      "</orderConfirmed>",
      "</order>", sep="")
    call <- paste0(baseurl,putconfirmed)
    rsp <- POST( url=call, body=body, add_headers( .headers = c( 'Authorization' = auth_header, 'Content-Type' = "application/xml"  ) )  )
    if( !grepl("Order updated successfully",content(rsp, "text") ) ) { print(paste("Warning",toconfirm[i],"not sucessfully confirmed")) }
  }
}

close(fc)
