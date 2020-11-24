library(ROracle)
library(sparklyr)
library(dplyr)
library(tidyverse)
library(lubridate)
library(leaflet)
library(sp)
library(rgdal)


##### Manual Input
#######################################################################################################################################################
cluster = "Sam_Ericsson_2"
vendor = "Ericsson"   # Ericsson for Ericsson and NSN for Nokia

x1 =  43.02593213# Coordinates for AOI, please make sure x1<x2 and y1<y2
x2 =  43.05880775
y1 = -89.93828812
y2 = -89.89301581
start.date = '20180701'  #yyyymmdd format
end.date = '20180730'
#######################################################################################################################################################


##### Input locations to save output files:
######################################################################################
output_csv_dir <- "/home/ejohn004/git/bin_forecasting/data/mergeddataoutput.csv"
output_shape_dir <- "/home/ejohn004/git/bin_forecasting/shape_files/mergeddataoutput"
######################################################################################


########## Run Scripts
##### Set-up Sparklyr configs and connection
source("/home/ejohn004/git/bin_forecasting/scripts/bf_sparklyr.R")

##### Query to find all eNodeB's with connecting records accounting for more than 5% of the total records inside AOI
source("/home/ejohn004/git/bin_forecasting/scripts/bf_enb_inside_aoi.R")

##### Pull eNodeB details from HELIX, read Busy Hour data, and merge all tables
source("/home/ejohn004/git/bin_forecasting/scripts/bf_input_enbs.R")

##### Query LSR for grid aggregations
source("/home/ejohn004/git/bin_forecasting/scripts/bf_grid_data.R")

##### Plot results with leaflet
source("/home/ejohn004/git/bin_forecasting/scripts/bf_grid_plot.R")

##### Calculate bin weights, join and apply to forecast
source("/home/ejohn004/git/bin_forecasting/scripts/bf_forecast.R")

##### Write ESRI shape file 
source("/home/ejohn004/git/bin_forecasting/scripts/bf_write_shape_file.R")


#####
rm(cluster,vendor,x1,x2,y1,y2,start.date,end.date,output_csv_dir,output_shape_dir)