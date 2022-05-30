#!/bin/bash 
# set -x 

source ../common/safeguard
source main_func
start_dataset 
create_network 
start_server

# SERVER_PID=$(docker inspect -f '{{.State.Pid}}' ${SERVER_CONTAINER})

start_client &

detect_stage warmup
(($DEV)) && echo "warmup ready"
docker stats $(docker ps --format '{{.Names}}') > $UTIL_LOG &
perf stat -e $PERF_EVENTS --cpu $SERVER_CPUS sleep infinity 2>> $PERF_LOG &
sleep $EXEC_TIME
echo "execution period finished"
#detect_stage finished 
pkill -f "docker-current"
pkill -fx "sleep infinity"
sed -i "s,\x1B\[[0-9;]*[a-zA-Z],,g" $UTIL_LOG # remove escape characters
#log_client 
cp user.cfg $OUT/user.cfg 
log_folder
sleep 5
rm_all_containers
