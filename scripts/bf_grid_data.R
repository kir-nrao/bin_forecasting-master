

##########
##### Query LSR for Grid Data

### Clean data
LSR_In<-data.frame(LSR_In)
LSR_In %>% mutate_if(is.factor  , as.character) -> LSR_In
LSR_In %>% mutate_if(is.POSIXct  , as.character) -> LSR_In
LSR_In %>% mutate_if(is.POSIXlt  , as.character) -> LSR_In

# saveRDS(LSR_In, "/home/ejohn004/r_projects/bin_forecasting/data/LSR_In.rds")
# LSR_In<-readRDS("/home/ejohn004/r_projects/bin_forecasting/data/LSR_In.rds")

### Determine which vendor table to query
lsr_table <- if(vendor == "Ericsson"){
  # "lsr.elte_raw_transformed"
  "lsr.v_elte_raw_corrected"
} else if (vendor == "NSN"){
  # "lsr.nlte_raw_transformed"
  "lsr.v_nlte_raw_corrected"
}

### Query LSR for grid data
### I think we maybe be able to fork the lsr.lte_eri_grid_hh transform and add in end_enb_id + end_earfcn along with measures of lat&lon dispersion
temp <- tbl(sc, lsr_table ) %>%
  filter(date_key >= start.date & lon<0 & lat>0) %>%
  inner_join(LSR_In ,by=c('end_enb_id','end_earfcn_dl','end_pci','date_key'='PDCCH_Busy_date_gmt','hour_key'='busy_hour_gmt'),copy=T) %>%
  select(tstamp, date_key, hour_key, PDCCH_BusyHr_gmt
         ,end_enb_id, end_cell_id, end_pci, end_earfcn_dl, LATITUDE, LONGITUDE
         ,imsi, number_of_records, lat, lon, lat_center, lon_center, lat_grid_index, lon_grid_index, duration_ms, rsrp, rsrq) %>%
  group_by(date_key, end_enb_id, LATITUDE, LONGITUDE, end_cell_id, end_earfcn_dl, hour_key, PDCCH_BusyHr_gmt, lat_center ,lon_center, lat_grid_index, lon_grid_index) %>%
  summarize( record_count = sum(number_of_records,na.rm=T)
             ,imsi_count = n_distinct(imsi)
             ,avg_duration_ms = mean(duration_ms,na.rm=T)
             ,avg_rsrp = mean(rsrp,na.rm=T)
             ,avg_rsrq = mean(rsrq,na.rm=T)
             ,sd_rsrp = sd(rsrp)
             ,sd_rsrq = sd(rsrq)
             ,avg_lat = mean(lat,na.rm=T)
             ,avg_lon = mean(lon,na.rm=T)
             ,sd_lat = sd(lat)
             ,sd_lon = sd(lon)
            )
# show_query(temp)


temp_df <- data.frame(temp)
# saveRDS(temp_df, "/home/ejohn004/r_projects/bin_forecasting/data/temp_df.rds")
# temp_df <- readRDS("/home/ejohn004/r_projects/bin_forecasting/data/temp_df.rds")
# spark_disconnect(sc)


unique(UniqueCarriers$end_enb_id)

