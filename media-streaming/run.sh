#!/bin/bash 
# set -x 

source ../common/safeguard
source main_func

create_dataset 
create_network 
start_server

# SERVER_PID=$(docker inspect -f '{{.State.Pid}}' ${SERVER_CONTAINER})

while read OPERATIONS; do 
    clean_containers $CLIENT_CONTAINER
    start_client &  

    detect_stage warmup
    (($DEV)) && echo "warmup ready"
    perf stat -e $PERF_EVENTS --cpu $SERVER_CPUS sleep infinity 2>>$PERF_LOG &
    detect_stage finished 
    pkill -fx "sleep infinity"
    log_client 
    cp user.cfg $OUT/user.cfg 
    log_folder
done < $OPERATIONS_FILE

