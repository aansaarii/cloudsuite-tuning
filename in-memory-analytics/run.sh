#!/bin/bash 

# set -x

# trap 'kill ${dataset_ready} ${master_ready} ${worker_ready} ${rampup_ready} ${measurement_ready}; exit' SIGINT

source safeguard
source main_func

[[ "$DEV" ]] && echo $NUM_WORKERS

rm -rf $LOCKDIR

create_dataset  
create_network 

start_master
start_workers
detect_stage master-ready 
detect_stage workers-ready  

start_client ${DATASET_SEL} 
detect_stage ramp-up
echo "Rampup completed"
perf stat -e $PERF_EVENTS --cpu $WORKER_CPUS_STR -p $WORKER_PIDS sleep infinity 2>>$PERF_LOG &
detect_stage finished 
echo "Finished"
sudo pkill -fx "sleep infinity"
docker logs $CLIENT_CONTAINER > $CLIENT_LOG
