#!/bin/bash 
# set -x 

source ../common/safeguard
source main_func

# create_dataset 
create_network 
start_master

#SERVER_PID=$(docker inspect -f '{{.State.Pid}}' ${SERVER_CONTAINER})

while read OPERATIONS; do 
    clean_containers $SLAVE_CONTAINER
    start_slave   
    docker exec $MASTER_CONTAINER benchmark 
if [ 0 -eq 1 ]; then 
    detect_stage warmup
    (($DEV)) && echo "warmup ready"
    sudo perf stat -e $PERF_EVENTS --cpu $SERVER_CPUS -p $SERVER_PID sleep $MEASURE_TIME 2>$PERF_LOG

    docker stop $CLIENT_CONTAINER
    log_client 
fi 

done < $OPERATIONS_FILE

#client_summary 
#cp user.cfg $OUT/user.cfg
#log_folder
