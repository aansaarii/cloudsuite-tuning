#!/bin/bash 
# set -x

source ../common/safeguard
source main_func

(($DEV)) && echo $NUM_SERVERS

create_network 
start_server 

while read TARGET_RPS; do 

    clean_containers $CLIENT_CONTAINER
    start_client &  

    detect_stage warmup

    (($DEV)) && echo "warmup ready" 
    SERVER_CGROUP_ID=`docker ps --no-trunc -aqf "name=$SERVER_CONTAINER"`
    sleep 10
    perf stat -e $INST,$CYCLES,$UOPS_RETIRED_U --cpu $SERVER_CPUS -G docker/$SERVER_CGROUP_ID,docker/$SERVER_CGROUP_ID,docker/$SERVER_CGROUP_ID sleep $MEASURE_TIME 2>>$PERF_LOG 
    docker stop $CLIENT_CONTAINER
    log_client 
    
    latency_summary 
    rps_summary 
    cp user.cfg $OUT/user.cfg

    log_folder
 
done < $RPS_FILE
 
