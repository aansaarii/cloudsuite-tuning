#!/bin/bash 
#set -x 
source ../common/safeguard
source main_func


create_network 
(($GENERATE_INDEX)) && generate_index
(($START_SERVER)) && start_server 

detect_stage index-node-ready

while read OPERATIONS; do

    clean_containers $CLIENT_CONTAINER
    start_client &
    CLIENT_PID=$!

    detect_stage rampup-completed
    echo "rampup completed" >> $UTIL_LOG 
    docker stats >> $UTIL_LOG &
    SERVER_PID=`docker container top $SERVER_CONTAINER  | grep solr | tr ' ' '\n' | grep '[^[:blank:]]' | sed -n "2 p"`
    sudo perf stat -e $PERF_EVENTS --cpu $SERVER_CPUS -p $SERVER_PID sleep infinity 2>>$PERF_LOG &
    detect_stage steady-state-completed
    sudo pkill -fx "sleep infinity"
    sudo pkill -f "docker stats"
    detect_stage detail-completed
    wait $CLIENT_PID
    log_client 

done < $OPERATIONS_FILE

cp user.cfg $OUT/user.cfg
log_folder
