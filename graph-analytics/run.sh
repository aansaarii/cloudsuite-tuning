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

CNT=0
while [[ $CNT -lt $REPEAT ]]; do
    if mkdir $LOCKDIR; then
	start_client 
	detect_stage warmup
	(($DEV)) && echo "Warm up completed"

	sudo perf stat -e $PERF_EVENTS --cpu $MASTER_CPUS -p $MASTER_PID sleep $MEASURE_TIME 2>>$PERF_LOG &

	detect_stage finished 
	(($DEV)) && echo "Finished"
	log_client
	CNT=$(( CNT+1 ))
	rm -rf $LOCKDIR
    fi 
done

client_summary
cp user.cfg $OUT/user.cfg 
log_folder
