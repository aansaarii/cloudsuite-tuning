#!/bin/bash 
# set -x 

source ../common/safeguard
source main_func

create_dataset 
create_network 
start_master
clean_containers $WORKER_CONTAINER
start_worker
docker exec $MASTER_CONTAINER benchmark >>$CLIENT_LOG2 2>$CLIENT_LOG 
# docker exec $MASTER_CONTAINER benchmark & 
# WORKER_CGROUP_ID=`docker ps --no-trunc -aqf "name=slave-0"`
# sudo perf stat -e $INST,$CYCLES,$UOPS_RETIRED_U --cpu $WORKER_CPUS sleep infinity 2>>$PERF_LOG

#SERVER_PID=$(docker inspect -f '{{.State.Pid}}' ${SERVER_CONTAINER})

client_summary 
cp user.cfg $OUT/user.cfg
log_folder
