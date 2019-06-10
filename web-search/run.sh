#!/bin/bash 
#set -x 
trap 'kill ${CLIENT_PID}; exit' SIGINT

source ../common/safeguard
source main_func

# if [ 0 -eq 1 ]; then
(($GENERATE_INDEX)) && generate_index
(($START_SERVER)) && start_server 

# SERVER_PID=$(docker inspect -f '{{.State.Pid}}' ${SERVER_CONTAINER})
SERVER_PID=`docker container top $SERVER_CONTAINER  | grep solr | tr ' ' '\n' | grep '[^[:blank:]]' | sed -n "2 p"`
detect_stage index-node-ready

while read OPERATIONS; do

    clean_containers $CLIENT_CONTAINER
    start_client &
    CLIENT_PID=$!

    detect_stage rampup

    sudo perf stat -e $PERF_EVENTS --cpu $SERVER_CPUS -p $SERVER_PID sleep infinity 2>>$PERF_LOG &
    detect_stage steady-state
    sudo pkill -fx "sleep infinity"
    
    detect_stage detail
    wait $CLIENT_PID
    docker logs $CLIENT_CONTAINER 2>/dev/null >> $CLIENT_LOG

done < $OPERATIONS_FILE

cp user.cfg $OUT/user.cfg
log_folder

