#!/bin/bash 

# set -x

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

rm -rf $LOCKDIR_RUN
CNT=0
while [[ $CNT -lt $REPEAT ]]; do
    if mkdir $LOCKDIR_RUN; then
	start_client 
	detect_stage executor-ready
	(($DEV)) && echo "executors ready"
	
	EXEC_ID=`docker container top ${WORKER_CONTAINER}-0  | grep executor | tr ' ' '\n' | grep '[^[:blank:]]' | sed -n "2 p"`
	sudo perf stat -e $PERF_EVENTS --cpu $WORKER_CPUS -p $WORKER_PIDS,$EXEC_ID sleep infinity 2>>$PERF_LOG &

	detect_stage executor-killed 
	pkill -fx "sleep infinity"
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
