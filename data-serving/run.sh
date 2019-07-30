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

# SERVER_CGROUP_ID=`docker ps --no-trunc -aqf "name=$SERVER_CONTAINER"`

while read OPERATIONS; do
    TARGET="$((OPERATIONS * MULTIPLIER))"
    docker stats >> $UTIL_LOG & 
    sudo perf stat -e $PERF_EVENTS --cpu $SERVER_CPUS -p ${SERVER_PID} sleep infinity 2>>$PERF_LOG &  
    # perf stat -e $INST,$CYCLES,$UOPS_RETIRED_U --cpu $SERVER_CPUS -G docker/$SERVER_CGROUP_ID,docker/$SERVER_CGROUP_ID,docker/$SERVER_CGROUP_ID sleep infinity 2>>$PERF_LOG & 
    (docker exec $CLIENT_CONTAINER bash -c "/ycsb/bin/ycsb run cassandra-cql -p hosts=$SERVER_CONTAINER -P /ycsb/workloads/workloadb -s -threads $THREADS -p operationcount=$TARGET -p recordcount=$RECORDS")>>$CLIENT_LOG &
    CLIENT_PID=$!
    wait $CLIENT_PID 
    sudo pkill -f "docker stats" 
    sudo pkill -fx "sleep infinity"
done < $OPERATIONS_FILE

mv $OPERATIONS_FILE $OUT/operations.txt
cp user.cfg $OUT/user.cfg
log_folder
