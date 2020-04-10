# Simple Order Downloader #

This script will allow to download Shöpping Orders and stores it to CSV files

## Installation ##

Download and Install R from https://www.r-project.org/
Please make sure that the R-Binary directory is included in PATH so that R and Rscript can be found and executed
Run `R -f install-dependencies.R` (on the commandline/terminal/eingabeaufforderung) to install necessary packages

## Configuration ##

Edit stdsettings.R and save it to settings.R
Configure
* it to use your merchant-id and APIkey
* Specify if prod/staging server is connected to
* Please also configure created or confirmed orders are downloaded (this can be separately configured for warehouse/PLC usage)
* For the PLC downloader You need also to set the right Post Product Code to transmit

## Usage ##

Run `Rscript export-warehouse.R` (on the commandline/terminal/eingabeaufforderung), it will connect to Shöpping, download orders and stores it to a CSV file with a timestamp in the name. The format can be used to import in your warehouse software. `export-warehouse-format2.R` offers a different format. First one separates Orders and Order-Positions into different lines. Second one gives you everything in one line and additionaly generates unique decimal order numbers and unique non-existing e-mail addresses.


Run `Rscript export-PLC.R` (on the commandline/terminal/eingabeaufforderung), it will connect to Shöpping, download orders and stores it to a CSV file with a timestamp in the name. The format can be used to import into Post PLC application

