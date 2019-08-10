#!/bin/bash 
# set -x 

source ../common/safeguard
source main_func

create_network 
start_master
clean_containers $WORKER_CONTAINER
start_worker
docker exec $MASTER_CONTAINER benchmark >>$CLIENT_LOG2 2>$CLIENT_LOG &
detect_stage warmup
docker stats > $UTIL_LOG &
sudo perf stat -e instructions,cycles --cpu $WORKER_CPUS sleep infinity 2>>$PERF_LOG & 
detect_stage finished
pkill -f "docker stats"
pkill -fx "sleep infinity"
client_summary 
cp user.cfg $OUT/user.cfg
log_folder
