#!/bin/bash 
#set -x

source ../common/safeguard
source main_func

rm_all_containers
start_server 

while read TARGET_RPS; do 
    clean_containers $CLIENT_CONTAINER
    start_client &   
    detect_stage warmup

    (($DEV)) && echo "warmup ready" 
    sleep 10
    docker stats $(docker ps --format '{{.Names}}') > $UTIL_LOG &
    #perf stat -e $PERF_EVENTS --cpu $SERVER_CPUS sleep $MEASURE_TIME 2>>$PERF_LOG 
    sleep $MEASURE_TIME
    docker stop $CLIENT_CONTAINER
    pkill -f "docker-current"
    sed -i "s,\x1B\[[0-9;]*[a-zA-Z],,g" $UTIL_LOG # remove escape characters

    log_client     
    latency_summary 
    rps_summary 
    cp user.cfg $OUT/user.cfg

    log_folder

done < $RPS_FILE
 
