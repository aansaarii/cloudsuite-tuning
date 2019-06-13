#!/bin/bash 
# set -x 

source ../common/safeguard
source main_func

(($DEV)) && echo "server cpus $SERVER_CPUS"

create_dataset 
create_network 
start_server

# SERVER_PID=$(docker inspect -f '{{.State.Pid}}' ${SERVER_CONTAINER})
SERVER_CGROUP_ID=`docker ps --no-trunc -aqf "name=$SERVER_CONTAINER"`
(($DEV)) && echo "server pid $SERVER_PID"

# if [ 1 -eq 0 ]; then
while read OPERATIONS; do 
    clean_containers $CLIENT_CONTAINER
    start_client &  

    detect_stage warmup
    (($DEV)) && echo "warmup ready"
    perf stat -e $INST,$CYCLES,$UOPS_RETIRED_U --cpu $SERVER_CPUS -G docker/$SERVER_CGROUP_ID,docker/$SERVER_CGROUP_ID,docker/$SERVER_CGROUP_ID sleep infinity 2>>$PERF_LOG 
    detect_stage finished 
    pkill -fx "sleep infinity"
    # docker stop $CLIENT_CONTAINER
    log_client 
    # _summary 
    cp user.cfg $OUT/user.cfg 
    log_folder
done < $OPERATIONS_FILE
# fi

