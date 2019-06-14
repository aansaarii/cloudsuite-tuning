#!/bin/bash 
# set -x 

source ../common/safeguard
source main_func

# create_dataset 
create_network 
start_master
clean_containers $WORKER_CONTAINER
start_worker
docker exec $MASTER_CONTAINER benchmark & 
sleep 60
WORKER_CGROUP_ID=`docker ps --no-trunc -aqf "name=slave-0"`
sudo perf stat -e $INST,$CYCLES,$UOPS_RETIRED_U --cpu $WORKER_CPUS -G docker/$WORKER_CGROUP_ID,docker/$WORKER_CGROUP_ID,docker/$WORKER_CGROUP_ID sleep $MEASURE_TIME 2>>$PERF_LOG

#SERVER_PID=$(docker inspect -f '{{.State.Pid}}' ${SERVER_CONTAINER})

#client_summary 
#cp user.cfg $OUT/user.cfg
#log_folder
