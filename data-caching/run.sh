#!/bin/bash 
# set -x

source ../common/safeguard
source main_func

(($DEV)) && echo $NUM_SERVERS

create_network 
start_server 

clean_containers $CLIENT_CONTAINER
start_client &  

detect_stage warmup

(($DEV)) && echo "warmup ready" 
sudo perf stat -e $PERF_EVENTS --cpu $SERVER_CPUS -p $SERVER_PIDS sleep $MEASURE_TIME 2>>$PERF_LOG
docker stop $CLIENT_CONTAINER
docker logs $CLIENT_CONTAINER 2>/dev/null | sed -n -e '/warm/,$p' > $CLIENT_LOG 

