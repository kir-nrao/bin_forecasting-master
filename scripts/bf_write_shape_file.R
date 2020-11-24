# library(rgdal)

##### Write shape file - !!! Experimental
### ESRI has a field character limit of 10, so manually truncating here: 
print("Truncating field names for ESRI shape file.")
old_colnames<-colnames(mergeddataoutput)
old_colnames
names(mergeddataoutput) <- gsub("_", "", names(mergeddataoutput), fixed = TRUE)
names(mergeddataoutput) <- gsub("year", "yr_", names(mergeddataoutput), fixed = TRUE)
names(mergeddataoutput) <- gsub("gmt", "_gmt", names(mergeddataoutput), fixed = TRUE)

names(mergeddataoutput) <- gsub("kbps", "_kbps", names(mergeddataoutput), fixed = TRUE)
names(mergeddataoutput) <- gsub("MB", "_MB", names(mergeddataoutput), fixed = TRUE)
names(mergeddataoutput) <- gsub("current", "crnt", names(mergeddataoutput), fixed = TRUE)
names(mergeddataoutput) <- gsub("count", "cnt", names(mergeddataoutput), fixed = TRUE)
names(mergeddataoutput) <- gsub("PDCCH", "ph_", names(mergeddataoutput), fixed = TRUE)
names(mergeddataoutput) <- gsub("BusyHr", "BHr", names(mergeddataoutput), fixed = TRUE)

names(mergeddataoutput) <- gsub("LONGITUDE", "enb_lon", names(mergeddataoutput), fixed = TRUE)
names(mergeddataoutput) <- gsub("LATITUDE", "enb_lat", names(mergeddataoutput), fixed = TRUE)
names(mergeddataoutput) <- strtrim(names(mergeddataoutput),10)

print(colnames(mergeddataoutput)) ## Print new colnames

### Create layers ? 
SPDF <- SpatialPointsDataFrame( matrix(c( mergeddataoutput$loncenter , mergeddataoutput$latcenter ), ncol=2) , data=mergeddataoutput
                                ,proj4string=CRS("+proj=longlat +ellps=WGS84 +datum=WGS84")
)

SPDF_2 <- SpatialPointsDataFrame( matrix(c( mergeddataoutput$enb_lon , mergeddataoutput$enb_lat ), ncol=2) , data=mergeddataoutput
                                  ,proj4string=CRS("+proj=longlat +ellps=WGS84 +datum=WGS84")
)

SPDF_3 <- SpatialPointsDataFrame( matrix(c( mergeddataoutput$avglon , mergeddataoutput$avglat ), ncol=2) , data=mergeddataoutput
                                  ,proj4string=CRS("+proj=longlat +ellps=WGS84 +datum=WGS84")
)

print("Writting ESRI shape file.")
### Write layers to ESRI shape file 
# writeOGR(obj = SPDF, layer = "grid_id",  "/home/ejohn004/git/bin_forecasting/shape_files/mergeddataoutput",driver = "ESRI Shapefile")
# writeOGR(obj = SPDF_2, dsn="/home/ejohn004/git/bin_forecasting/shape_files/mergeddataoutput", layer = "end_enb_id",driver = "ESRI Shapefile")
# writeOGR(obj = SPDF_3, dsn="/home/ejohn004/git/bin_forecasting/shape_files/mergeddataoutput", layer = "avg_grid_point",driver = "ESRI Shapefile")


writeOGR(obj = SPDF, layer = "grid_id",  output_shape_dir,driver = "ESRI Shapefile")
writeOGR(obj = SPDF_2, dsn=output_shape_dir, layer = "end_enb_id",driver = "ESRI Shapefile")
writeOGR(obj = SPDF_3, dsn=output_shape_dir, layer = "avg_grid_point",driver = "ESRI Shapefile")




rm(SPDF,SPDF_2,SPDF_3)

##### ! Testing reading in shape file
### Shape file currently seems to be a incorrect format. May be related to layer creation method
# shapefile <- readOGR("/home/ejohn004/git/bin_forecasting/shape_files/mergeddataoutput")
# shapefile_df <- data.frame(shapefile)
# head(shapefile_df)
# rm(shapefile,shapefile_df)
