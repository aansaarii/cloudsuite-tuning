#!/bin/bash 

# set -x

# trap 'kill ${dataset_ready} ${master_ready} ${worker_ready} ${rampup_ready} ${measurement_ready}; exit' SIGINT

source safeguard
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

start_client ${DATASET_SEL} 
detect_stage ramp-up
echo "Rampup completed"

if [[ ${MEASURE} = "worker" ]]; then  
    perf stat -e $PERF_EVENTS --cpu $WORKER_CPUS_STR -p $WORKER_PIDS sleep infinity 2>>$PERF_LOG &
elif [[ ${MEASURE} = "master" ]]; then 
    perf stat -e $PERF_EVENTS --cpu $MASTER_CPUS -p $MASTER_PID sleep infinity 2>>$PERF_LOG &
elif [[ ${MEASURE} = "combine" ]]; then 
    perf stat -e $PERF_EVENTS --cpu $SERVER_CPUS -p $MASTER_PID,$WORKER_PIDS sleep infinity 2>>$PERF_LOG &
else
    echo "invalid option $MEASURE"
fi 

detect_stage finished 
echo "Finished"
sudo pkill -fx "sleep infinity"

cp user.cfg $OUT/user.cfg 
docker logs $CLIENT_CONTAINER > $CLIENT_LOG
log_folder
