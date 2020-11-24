


##########
##### Plot Results

### Create lines within AOI between all average end earfcn lat/lon points and represented eNodeB 
temp_df$line_key <- paste0(temp_df$end_enb_id,"-",temp_df$end_earfcn_dl,"-",temp_df$lat_grid_index,"-",temp_df$lon_grid_index)
temp_df_lines <- subset(temp_df, avg_lat > x1 & avg_lat < x2 & avg_lon > y1 & avg_lon < y2) 
temp_df_lines_1 <- temp_df_lines[c('line_key','avg_lat','avg_lon')]
colnames(temp_df_lines_1)<- c("line_key","lat","lon")
temp_df_lines_2 <-temp_df_lines[c('line_key','LATITUDE','LONGITUDE')]
colnames(temp_df_lines_2)<- c("line_key","lat","lon")
temp_df_lines <- rbind(temp_df_lines_1 , temp_df_lines_2)

split_data = lapply(unique(temp_df_lines$line_key), function(x) {
  df = as.matrix(temp_df_lines[temp_df_lines$line_key == x, c("lon", "lat")])
  lns = Lines(Line(df), ID = x)
  return(lns)
})

data_lines = SpatialLines(split_data)
data_lines$ID <- sapply(slot(data_lines, "lines"), function(x) slot(x, "ID"))
data_lines$end_earfcn_dl <- substr(data_lines$ID,8,11)

### Color by total records within each grid
temp_df <- temp_df %>% group_by(lat_grid_index,lon_grid_index) %>%
  mutate(
    grid_record_count = sum(record_count)
    ,avg_grid_record_lat =  record_count*avg_lat /grid_record_count
    ,avg_grid_record_lon =  record_count*avg_lon /grid_record_count
  )

# conpal <- colorNumeric("GnBu", temp_df$record_count , na.color = "black", alpha = F,reverse = F)
conpal <- colorNumeric(colorRamp(c("#878787","#b52d2d","#910d0d" ,"#630000"), interpolate = "spline"), as.numeric(temp_df$grid_record_count) , na.color = "black", alpha = F,reverse = F)

### Leaflet map
leaflet(temp_df) %>%
  addProviderTiles("OpenStreetMap.BlackAndWhite",group="Black and White") %>%
  addTiles(group="Open Street Map") %>%
  addProviderTiles("Esri.WorldImagery",group="Satellite") %>%
  addProviderTiles("CartoDB.DarkMatter",group="Dark") %>%
  
  addPolylines(data= data_lines,group=~ paste0("End EARCN: ",data_lines$end_earfcn_dl), color = "#89009b", weight = 2 ,opacity = .5)%>%
  
  addCircles(lng=as.numeric(temp_df$lon_center), lat=as.numeric(temp_df$lat_center)
             ,color=~conpal(temp_df$grid_record_count)
             ,radius = 500
             ,group = "Grids"
             ,popup = paste0(temp_df$end_enb_id," - ",temp_df$end_earfcn_dl)) %>%
  
  addCircles(lng=as.numeric(temp_df$avg_lon), lat=as.numeric(temp_df$avg_lat)
             ,radius=60 ,color = 'gold'
             ,opacity = .7
             ,fill = T,fillOpacity = 1
             ,popup= paste0("End eNodeB: ",temp_df$end_enb_id," End EARCN: ",temp_df$end_earfcn_dl)
             ,group=~ paste0("End EARCN: ",temp_df$end_earfcn_dl)) %>%
  
  addCircles(lng=as.numeric(temp_df$LONGITUDE), lat=as.numeric(temp_df$LATITUDE),group = "USCC LTE Towers"
             ,radius=300 ,color = '#690177'
             ,opacity = .8
             ,fill = T,fillOpacity = 1
             ,popup = paste0("eNodeB ID: ",temp_df$end_enb_id)) %>%
  
  # addCircles(lng=as.numeric(temp_df$avg_grid_record_lon), lat=as.numeric(temp_df$avg_grid_record_lat),group = "USCC LTE Towers"
  #            ,radius=300 ,color = 'Navy'
  #            ,opacity = .8
  #            ,fill = T,fillOpacity = 1) %>%
  
  addRectangles( lng1=y1, lng2=y2, lat1=x1, lat2=x2 )%>%
  
  addLayersControl(
    baseGroups = c("Black and White","Open Street Map","Satellite","Dark")
    # ,overlayGroups = c("USCC LTE Towers","Grid Centers")
    ,overlayGroups = c("USCC LTE Towers","Grids",unique(paste0("End EARCN: ",temp_df$end_earfcn_dl)))
    ,options = layersControlOptions(collapsed = FALSE)) %>%
  hideGroup(unique(paste0("End EARCN: ",temp_df$end_earfcn_dl))) %>%
  addScaleBar(position = "bottomleft", options = scaleBarOptions())



rm(temp_df_lines,temp_df_lines_1,temp_df_lines_2,split_data,data_lines)