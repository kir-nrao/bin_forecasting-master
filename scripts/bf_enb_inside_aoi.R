

##########
##### Find all eNodeB's that had data connections inside AOI

### ERICSSON QUERY FROM LSR
eric.query <- function(x1,x2,y1,y2,start.date,end.date){
  query <- 
    paste0(
      "
      select
      aa.end_enb_id,
      aa.end_pci,
      aa.end_earfcn,
      COUNT(aa.end_enb_id)
      FROM lsr.elte_raw_transformed aa 
      WHERE
      aa.date_key BETWEEN '",start.date,"' and '",end.date,"'
      AND aa.LAT > '",x1,"' AND aa.LAT < '",x2,"'
      AND aa.LON > '",y1,"' AND aa.LON < '",y2,"'
      GROUP BY
      aa.end_enb_id,
      aa.end_pci,
      aa.end_earfcn
      ")
  return(query)
}


####################### !!!
### Using this query to manually insert eNodeB's that show up in the current forecast file - This query will be deleted once all enb's are in the forecast.csv file
eric.query <- function(x1,x2,y1,y2,start.date,end.date){
  query <- 
    paste0(
      "
      select
      aa.end_enb_id,
      aa.end_pci,
      aa.end_earfcn,
      COUNT(aa.end_enb_id)
      FROM lsr.elte_raw_transformed aa 
      WHERE
      aa.date_key BETWEEN '",start.date,"' and '",end.date,"'
      AND ((aa.LAT > '",x1,"' AND aa.LAT < '",x2,"'
      AND aa.LON > '",y1,"' AND aa.LON < '",y2,"') or ( aa.end_enb_id in ('190001','	
      190181','550913') ))
      GROUP BY
      aa.end_enb_id,
      aa.end_pci,
      aa.end_earfcn
      ")
  return(query)
}
####################### !!!



### NSN QUERY FROM LSR
nsn.query <- function(x1,x2,y1,y2,start.date,end.date){
  query <- 
    paste0(
      "
      select
      aa.end_enb_id,
      aa.end_pci,
      aa.end_earfcn_dl,
      COUNT(aa.end_enb_id)
      FROM lsr.nlte_raw_transformed aa
      WHERE
      aa.date_key BETWEEN '",start.date,"' and '",end.date,"'
      AND aa.LAT > '",x1,"' AND aa.LAT < '",x2,"'
      AND aa.LON > '",y1,"' AND aa.LON < '",y2,"'
      GROUP BY
      aa.end_enb_id,
      aa.end_pci,
      aa.end_earfcn_dl
      ")
  return(query)
}



##### Identify the query to be executed based on the vendor
if (vendor == "Ericsson"){
  print("Running Ericsson Query")
  query <- eric.query(x1,x2,y1,y2,start.date,end.date)
} else if (vendor == "NSN"){
  print("Running Nokia Query")
  query <- nsn.query(x1,x2,y1,y2,start.date,end.date) 
}


### Execute query on LSR
start_time <- Sys.time()
print(start_time)
print("Starting query on LSR")
UniqueCarriers_spark <- tbl(sc,sql(query))

UniqueCarriers <- data.frame(UniqueCarriers_spark)

print(nrow(UniqueCarriers))
print("Completed query on LSR")
print(Sys.time()) 
print(Sys.time() - start_time)


####################
# library(RODBC)
# 
# ericellcap5 <- odbcConnect("LSRPRD Hive 64-bit")   #open ODBC to LSR
# UniqueCarriers <- sqlQuery(ericellcap5,query)
# 
# saveRDS(UniqueCarriers, "/home/ejohn004/r_projects/bin_forecasting/data/UniqueCarriers.rds")
# UniqueCarriers<-readRDS("/home/ejohn004/r_projects/bin_forecasting/data/UniqueCarriers.rds")

####################



### Generate Unique key
colnames(UniqueCarriers) <- c("end_enb_id","end_pci","end_earfcn_dl","Count")
UniqueCarriers$Key <- paste0(UniqueCarriers$end_enb_id,".",UniqueCarriers$end_pci,".",UniqueCarriers$end_earfcn_dl)


### Clean data
UniqueCarriers <- na.omit(UniqueCarriers)

##### Calcualte % of records within each end eNodeB ID
### Create backup incase we want to query for all connected traffic
UniqueCarriers_total_records <- sum(UniqueCarriers$Count)
UniqueCarriers_backup <- UniqueCarriers %>% group_by(end_enb_id) %>% mutate(end_enb_record_count = sum(Count)
                                                                            ,end_enb_record_percent = round(end_enb_record_count / UniqueCarriers_total_records,4)
                                                                            ) 

### Filter for eNodeB's having more than 5% of total connected records
UniqueCarriers <- subset(UniqueCarriers_backup,end_enb_record_percent>.05)
length(unique(UniqueCarriers_backup$end_enb_id)) - length(unique(UniqueCarriers$end_enb_id)) # 26 eNodeB's removed

rm(eric.query,nsn.query,query,start_time)



