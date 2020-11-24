
forecast_df <- read.csv("/home/ejohn004/r_projects/bin_forecasting/data/forecast.csv")

colnames(LSR_In)
colnames(forecast_df)

####### Notes on join keys used throughout scripts: 
##### X0Key = eNB_ID + "-" + SECTOR_ID + "." + end_earfcn_dl ? 
### necom.output$Key <- paste0(necom.output$eNB_ID,".",necom.output$PCI,".",necom.output$DL_EARFCN)
### necom.output$EUTRANCELLFDD <- paste0(necom.output$eNB_ID,"-",necom.output$SECTOR_ID)
### OptimaPCI$Key <- paste0(OptimaPCI$PCI,".",OptimaPCI$DL_EARFCN,".",OptimaPCI$eNB_ID)
### finalLSR  Key = paste0(finaldf$EUTRANCELLFDD,".",finaldf$EARFCN)



### Calculate Weights
print("Calculating Weights for each End-eNodeB, EARFCN and End-Cell-ID")
temp_df <- temp_df %>% group_by( end_enb_id, end_earfcn_dl, end_cell_id ) %>% mutate(Weight=record_count/ sum(record_count))

### Create join key 
temp_df <- temp_df %>% mutate(SECTOR_ID = as.numeric(end_cell_id)-as.numeric(end_enb_id)*256
                              ,EUTRANCELLFDD = paste0(end_enb_id,"-",SECTOR_ID)
                              ,key_f = paste0(EUTRANCELLFDD,".",end_earfcn_dl)
                              )
### Merge data with forecast dataset
temp_df_final <- merge(temp_df,forecast_df,by.x="key_f",by.y="X0Key")


### Apply weights across all forecast years (MB)
print("Applying weights.")
temp_df_final<-temp_df_final %>% mutate_at(vars(starts_with("year_")),funs(.*Weight))

### Create kbps version of weighted forecast 
temp_df_final_kbps<-temp_df_final[grepl("year_" , colnames(temp_df_final))==T] %>% mutate_at(vars(starts_with("year_")),funs(.*2.27555555555556))

### Suffix MB and kbps fields
require(fastmatch) # Using this package to identify the position of each year field to use within the colmanes(data.frame)[colnums] sytax
colnames(temp_df_final)[fmatch(names(temp_df_final[grepl("year_" , colnames(temp_df_final))==T]) ,names(temp_df_final))] <- c(paste0(names(temp_df_final[grepl("year_" , colnames(temp_df_final))==T]),"_MB"))
colnames(temp_df_final_kbps) <- paste0(colnames(temp_df_final_kbps),"_kbps")

### Merge MB and kbps to create final output
mergeddataoutput <- cbind(temp_df_final,temp_df_final_kbps)

mergeddataoutput$grid_id <- paste0(mergeddataoutput$EUTRANCELLFDD,".",mergeddataoutput$lat_grid_index,".", mergeddataoutput$lon_grid_index)
length(unique(mergeddataoutput$grid_id))

print(colnames(mergeddataoutput))

print("Saving final merged output file.")
# write.csv(mergeddataoutput,"/home/ejohn004/git/bin_forecasting/data/mergeddataoutput.csv")
write.csv(mergeddataoutput,output_csv_dir)

rm(temp_df_final,temp_df_final_kbps)




