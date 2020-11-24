

##########
##### Query HELIX for Necom site information
necom.query <- function (vendor){
  query <- paste0("
                  SELECT
                  SEC_VENDOR_NAME as \"Vendor\",
                  ENODEB_ID as \"eNB_ID\",
                  SEC_ID AS \"SECTOR_ID\",
                  SEC_EARFCN_DNLINK AS \"DL_EARFCN\",
                  SEC_PHYS_LYR_SUBCELL_ID AS \"PSS\",
                  SEC_PHYS_LYR_CELL_ID_GRP AS \"SSS\",
                  --ENB_LATITUDE,
                  --ENB_LONGITUDE,
                  LATITUDE,
                  LONGITUDE                  
                  
                  FROM
                  NECOM.USCC_MASTER_LTE_ENBSECTOR_V@NECOM_CAPACITY
                  WHERE
                  SEC_VENDOR_NAME like '",vendor,"'
                  ")
  return(query)
}


query <- necom.query(vendor)
print ("Starting necom query")
# helix <- odbcConnect("HELIXPRDSCH", uid = "RANCAPACITY_READ", pwd = "password", believeNRows = FALSE)
helix <- dbConnect(drv = dbDriver("Oracle"), dbname = "HELIX-OPTIMA", username = "RANCAPACITY_READ", password = "password",believeNRows = FALSE)

necom.output <- dbSendQuery(helix, query)
necom.output <- fetch(necom.output)

# odbcClose(helix)
print("Completed necom query")

if(vendor == "NSN"){
  necom.output$SSS <- 0
}

### Calculating PCI
necom.output$PCI <- as.integer(as.character(necom.output$SSS)) * 3 + as.integer(necom.output$PSS)
necom.output$Key <- paste0(necom.output$eNB_ID,".",necom.output$PCI,".",necom.output$DL_EARFCN)
necom.output$EUTRANCELLFDD <- paste0(necom.output$eNB_ID,"-",necom.output$SECTOR_ID)


##########
##### Read in Busy Hour data
busyhr <- read.csv("/home/krao002/LSR/LSR\ Data\ Pull/Busyhour.csv")
# saveRDS(busyhr, "/home/ejohn004/r_projects/bin_forecasting/data/busyhr.rds")
busyhr<- readRDS("/home/ejohn004/r_projects/bin_forecasting/data/busyhr.rds")

busyhr$Vol_Busy_date <- strptime(busyhr$Vol_Busy_date, format = "%m/%d/%Y")
busyhr$Vol_Busy_date <- as.character(busyhr$Vol_Busy_date)

##### Merge tables 
print("Merging with Busy Hour data")
LSR_Input <- merge(busyhr,necom.output,"EUTRANCELLFDD")

print("Merging with HELIX data")
LSR_In <- merge(UniqueCarriers,LSR_Input,"Key")

### Clean Date & Time Fields 
LSR_In$PDCCH_BusyHr <- as.POSIXct(LSR_In$PDCCH_BusyHr,format='%m/%d/%Y %H:%M',tz="CST")
LSR_In$PDCCH_Busy_date <- as.character(format(LSR_In$PDCCH_BusyHr,"%Y%m%d"))
LSR_In$busy_hour <- hour(LSR_In$PDCCH_BusyHr)

### Convery date and time to GMT format
LSR_In$PDCCH_BusyHr_gmt <- as.POSIXct(LSR_In$PDCCH_BusyHr,format='%m/%d/%Y %H:%M',tz="CST")+5*60*60
LSR_In$PDCCH_Busy_date_gmt <- as.character(format(LSR_In$PDCCH_BusyHr_gmt,"%Y%m%d"))
LSR_In$busy_hour_gmt <- hour(LSR_In$PDCCH_BusyHr_gmt)



##### This has been done one the busyhour dataset instead of LSR side... Leaving in notes for now:
### Notes from Brent for doing GMT conversion in spark if needed later: 
## ! need to calculate the GMT Date/Time for the pdcch_busy_date/hour to get the join to work right
## ! combine date/time to a timestamp, force to GMT, then break back to date_key/Hour using yyyyMMdd for date format and hh for hour_key
# LSR_In$PDCCH_Busy_date <- as.character(format(strptime(LSR_In$PDCCH_Busy_date,"%Y-%m-%d"),"%Y%m%d"))

# select 
# pdcch_busyhr
# ,unix_timestamp(pdcch_busyhr,'M/d/yyyy HH:mm') unixts 
# ,unix_timestamp(pdcch_busyhr,'M/d/yyyy HH:mm')+5*60*60 gmtunixts
# ,from_unixtime(unix_timestamp(pdcch_busyhr,'M/d/yyyy HH:mm'),'yyyy-MM-dd HH:mm:ss') tsstring
# ,from_unixtime(unix_timestamp(pdcch_busyhr,'M/d/yyyy HH:mm')+5*60*60,'yyyy-MM-dd HH:mm:ss') gmttsstring
# from ba_lsr_in  order by unixts; 
