#!/bin/bash 

source ../common/safeguard 
source main_func 

(($LOAD)) && start_server
(($LOAD)) && detect_stage server-ready 
start_client 
(($LOAD)) && load_server 
warmup_server

SERVER_PID=$(docker inspect -f '{{.State.Pid}}' ${SERVER_CONTAINER})
while read OPERATIONS; do
    TARGET="$((OPERATIONS * MULTIPLIER))"
    sudo perf stat -e $PERF_EVENTS --cpu $SERVER_CPUS -p ${SERVER_PID} sleep infinity 2>>$PERF_LOG &  
    (docker exec $CLIENT_CONTAINER bash -c "/ycsb/bin/ycsb run cassandra-cql -p hosts=$SERVER_CONTAINER -P /ycsb/workloads/workloadb -s -threads $THREADS -p operationcount=$TARGET -p recordcount=$RECORDS")>>$CLIENT_LOG &
    CLIENT_PID=$!
    wait $CLIENT_PID 
    sudo pkill -fx "sleep infinity"
done < $OPERATIONS_FILE
