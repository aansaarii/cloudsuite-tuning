#!/bin/bash 

source ../common/safeguard 
source main_func 

rm_all_containers
create_network
(($LOAD)) && start_server
(($LOAD)) && detect_stage server-ready 
start_client 
(($LOAD)) && load_server 
warmup_server

while read OPERATIONS; do
    TARGET="$((OPERATIONS * MULTIPLIER))"
    docker stats $(docker ps --format '{{.Names}}') > $UTIL_LOG &
    sudo perf stat -e $PERF_EVENTS --cpu $SERVER_CPUS -p ${SERVER_PID} sleep infinity 2>>$PERF_LOG &  
    (docker exec $CLIENT_CONTAINER bash -c "/ycsb/bin/ycsb run cassandra-cql -p hosts=$SERVER_CONTAINER -P /ycsb/workloads/workloadb -s -threads $THREADS -p operationcount=$TARGET -p recordcount=$RECORDS")>>$CLIENT_LOG &
    CLIENT_PID=$!
    wait $CLIENT_PID 
    sudo pkill -f "docker-current" 
    sudo pkill -fx "sleep infinity"
    sed -i "s,\x1B\[[0-9;]*[a-zA-Z],,g" $UTIL_LOG # remove escape characters

    echo "operations: $OPERATIONS" > $OUT/operations.txt
    cp user.cfg $OUT/user.cfg
    log_folder
done < $OPERATIONS_FILE
