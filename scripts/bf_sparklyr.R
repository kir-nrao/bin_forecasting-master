

##########
##### Set up port for sparklyR
### Set up port for sparklyR -- May need to add something at the end of the script to release the port assignment
oracledrv <- dbDriver("Oracle")
connect.string <- "(DESCRIPTION =    
(ADDRESS = (PROTOCOL = TCP)(HOST = shcracp-scan)(PORT = 1521))    
(CONNECT_DATA =      
(SERVER = DEDICATED)      
(SERVICE_NAME = dpc)))"
ch <-dbConnect(oracledrv,username="dpc_reporter_dpcstats",password = "dpc_reporter_dpcstats",dbname = connect.string)
port<-dbGetQuery(ch,"
                 SELECT MIN(SPARKPORT) as V_SPARKPORT
                 FROM SPARK_PORT_ASSIGNMENTS
                 WHERE PERMANENTRESERVATION<>'Y'
                 AND SYSDATE-LASTASSIGNEDTIME>4/24
                 GROUP BY PERMANENTRESERVATION")

port <- as.integer(port[1,1])
dbExecute(ch,paste0("update SPARK_PORT_ASSIGNMENTS
                    SET LASTASSIGNEDTIME = SYSDATE
                    WHERE SPARKPORT = ",port))
dbDisconnect(ch)
rm(ch);rm(connect.string);rm(oracledrv)		

### Spark Configs 
Sys.setenv(JAVA_HOME='/usr/java/latest')
Sys.setenv(SPARK_HOME="/opt/cloudera/parcels/SPARK2-2.1.0.cloudera2-1.cdh5.7.0.p0.171658/lib/spark2")
Sys.setenv(SPARK_MEM = "30g")
config <- spark_config()
config$spark.yarn.keytab <- "/home/ejohn004/ejohn004.keytab"
config$spark.yarn.principal <- "ejohn004@INT.USC.LOCAL"
config$spark.home <- "/opt/cloudera/parcels/SPARK2-2.1.0.cloudera2-1.cdh5.7.0.p0.171658/lib/spark2"
config$spark.executor.cores <- 4
config$spark.dynamicAllocation.minExecutors <- 0
config$spark.dynamicAllocation.maxExecutors <- 100
config$spark.sql.autoBroadcastJoinThreshold <- "204857600"
shuffle <- as.character(config$spark.executor.cores * config$spark.dynamicAllocation.maxExecutors)
config$spark.driver.maxResultSize <- "4g"
config$spark.executor.memory <- "10g"
config$spark.driver.memory <- "30g"
config$spark.kryoserializer.buffer.max <- "1524m"
config$spark.sql.shuffle.partitions <- shuffle
config$spark.yarn.driver.memoryOverhead <- "8g"
config$spark.yarn.executors.memoryOverhead <- "10g"
config$spark.executor.heartbeatInterval <- "20s"
config$`sparklyr.shell.driver-memory` <- '30G'
config$sparklyr.gateway.port = port

### Connect
spark_disconnect_all()
sc <- spark_connect(master = "yarn-client", version = "2.1.0", config = config)


