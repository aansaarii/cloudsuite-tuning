#!/bin/bash 
#set -x
# trap 'kill ${dataset_ready} ${master_ready} ${worker_ready} ${rampup_ready} ${measurement_ready}; exit' SIGINT

source ../common/safeguard
source main_func

(($DEV)) && echo $NUM_WORKERS
(($DEV)) && echo "Server cpus are $SERVER_CPUS"

create_dataset  
create_network 

start_master
(($DEV)) && echo $MASTER_PID

start_workers
detect_stage master-ready 
detect_stage workers-ready  

CNT=0
rm -rf $LOCKDIR
while [[ $CNT -lt $REPEAT ]]; do 
    if mkdir $LOCKDIR; then
	start_client ${DATASET_SEL} 
	detect_stage executor-ready  
	(($DEV)) && echo "executors ready" >> $UTIL_LOG

    EXEC_ID=`docker container top ${WORKER_CONTAINER}  | grep executor | tr ' ' '\n' | grep '[^[:blank:]]' | sed -n "2 p"`
    docker stats >> $UTIL_LOG &
	sudo perf stat -e $PERF_EVENTS --cpu $WORKER_CPUS -p ${EXEC_ID},${WORKER_PIDS} sleep infinity 2>>$PERF_LOG &

    detect_stage executor-killed
    (($DEV)) && echo "executor killed"
    sudo pkill -fx "sleep infinity"
    sudo pkill -f "docker stats"
    detect_stage finished 
    log_client 

	CNT=$(( CNT+1 ))
	rm -rf $LOCKDIR
    fi 
done 

client_summary 
cp user.cfg $OUT/user.cfg 
log_folder
