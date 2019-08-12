#!/bin/bash 
# set -x 

source ../common/safeguard
source main_func

create_network 
start_db
start_caching_layer

start_server

while read USER_NUM; do 
    clean_containers $CLIENT_CONTAINER
    start_client &

    detect_stage warmup
    echo "Warmup ready" >> $UTIL_LOG 
    docker stats >> $UTIL_LOG & 
    sudo perf stat -e $PERF_EVENTS --cpu $SERVER_CPUS sleep infinity 2>>$PERF_LOG &
    detect_stage rampdown && echo "benchmark finished"

    sudo pkill -fx "sleep infinity"
    sudo pkill -f "docker stats"
    docker cp $CLIENT_CONTAINER:/usr/src/faban/output/1/ $OUT/client-results
    cp user.cfg $OUT/user.cfg
    client_summary 
    log_folder
done < $INPUT_FILE

