#!/bin/bash 

# set -x

source ../common/safeguard
source main_func
(($DEV)) && echo "workers: $NUM_WORKERS"

create_dataset  
create_network 

start_master
(($DEV)) && echo "master: $MASTER_PID"

start_workers
detect_stage master-ready 
detect_stage workers-ready  

rm -rf $LOCKDIR_RUN
CNT=0
while [[ $CNT -lt $REPEAT ]]; do
    if mkdir $LOCKDIR_RUN; then
	start_client 
	detect_stage executor-ready
	(($DEV)) && echo "executors ready" >> $UTIL_LOG
    docker stats container ${WORKER_CONTAINER} >> $UTIL_LOG & 
	EXEC_ID=`docker container top ${WORKER_CONTAINER}  | grep executor | tr ' ' '\n' | grep '[^[:blank:]]' | sed -n "2 p"`
	sudo perf stat -e $PERF_EVENTS --cpu $WORKER_CPUS -p $WORKER_PIDS,$EXEC_ID sleep infinity 2>>$PERF_LOG &

	detect_stage executor-killed 
	pkill -fx "sleep infinity"
    pkill -fx "docker stats"
	(($DEV)) && echo "executor killed"
	detect_stage finished 
	(($DEV)) && echo "Finished"
	log_client
	CNT=$(( CNT+1 ))
	rm -rf $LOCKDIR_RUN
    fi 
done

client_summary
cp user.cfg $OUT/user.cfg 
log_folder
