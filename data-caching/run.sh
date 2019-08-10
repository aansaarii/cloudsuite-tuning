#!/bin/bash 
#set -x

source ../common/safeguard
source main_func

rm_all_containers
create_network 
start_server 

while read TARGET_RPS; do 
    clean_containers $CLIENT_CONTAINER
    start_client &   
    detect_stage warmup

    (($DEV)) && echo "warmup ready" 
    sleep 10
    docker stats >> $UTIL_LOG & 
    sudo perf stat -e $PERF_EVENTS --cpu $SERVER_CPUS sleep $MEASURE_TIME 2>>$PERF_LOG 
    docker stop $CLIENT_CONTAINER
    sudo pkill -f "docker stats"
    log_client 
    
    latency_summary 
    rps_summary 
    cp user.cfg $OUT/user.cfg

    log_folder

done < $RPS_FILE
 
