#!/bin/bash 
# set -x 

source ../common/safeguard
source main_func

(($DEV)) && echo "server cpus $SERVER_CPUS"

create_network 
start_db
start_caching_layer
start_server

clean_containers $CLIENT_CONTAINER
start_client &

detect_stage warmup
SERVER_CGROUP_ID=`docker ps --no-trunc -aqf "name=$SERVER_CONTAINER"`
perf stat -e $INST,$CYCLES,$UOPS_RETIRED_U --cpu $SERVER_CPUS -G docker/$SERVER_CGROUP_ID,docker/$SERVER_CGROUP_ID,docker/$SERVER_CGROUP_ID sleep infinity 2>>$PERF_LOG & 
detect_stage rampdown && echo "benchmark finished"

pkill -fx "sleep infinity"
# log_client
docker cp $CLIENT_CONTAINER:/usr/src/faban/output/1/ $OUT/client-results
cp user.cfg $OUT/user.cfg 
log_folder

#SERVER_PID=$(docker inspect -f '{{.State.Pid}}' ${SERVER_CONTAINER})
if [ 0 -eq 1 ] ; then 
while read OPERATIONS; do 
    clean_containers $CLIENT_CONTAINER
    start_client &  

    detect_stage warmup
    (($DEV)) && echo "warmup ready"
    sudo perf stat -e $PERF_EVENTS --cpu $SERVER_CPUS -p $SERVER_PID sleep $MEASURE_TIME 2>$PERF_LOG

    docker stop $CLIENT_CONTAINER
    log_client 
    cp user.cfg $OUT/user.cfg 
    log_folder
done < $OPERATIONS_FILE
fi 

