#!/bin/bash 

set -x

source ../common/safeguard
source main_func

(($DEV)) && echo $NUM_SERVERS

create_network 
start_server 
start_client &  

detect_stage warmup

(($DEV)) && echo "warmup ready. Starts measurement" 
sudo perf stat -e $PERF_EVENTS --cpu $SERVER_CPUS -p $SERVER_PIDS sleep $MEASURE_TIME 2>>$PERF_LOG
docker stop $CLIENT_CONTAINER


