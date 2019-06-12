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

WORKER_CGROUP_IDS=""
CNT=0

LOCKDIR2=/tmp/ima-repeat.lock

while [[ $CNT -lt $REPEAT ]]; do 
    if mkdir $LOCKDIR2; then
	start_client ${DATASET_SEL} 
	detect_stage executor-ready  
	(($DEV)) && echo "executors ready"

if [ 0 -eq 1 ]; then 
    WORKER_CNT=0
    PERF_CNT=0
    while [[ ${WORKER_CNT} -lt ${NUM_WORKERS} ]]; do
        if mkdir $LOCKDIR; then 
            WORKER_CGROUP_ID=`docker ps --no-trunc -aqf "name=ima-spark-worker-${WORKER_CNT}"`
            if [ -z "WORKER_CGROUP_IDS" ]; then 
                echo "HIT!!!"
                PERF_CNT=1
                WORKER_CGROUP_IDS="docker/${WORKER_CGROUP_ID}"
                while [[ ${PERF_CNT} -lt ${PERF_EVENT_CNT} ]]; do 
                    WORKER_CGROUP_IDS="$WORKER_CGROUP_IDS,$WORKER_CGROUP_IDS"
                    PERF_CNT=$((PERF_CNT+1))
                done
            else 
                while [[ ${PERF_CNT} -lt ${PERF_EVENT_CNT} ]]; do
                    WORKER_CGROUP_IDS="$WORKER_CGROUP_IDS,docker/$WORKER_CGROUP_ID"
                    PERF_CNT=$((PERF_CNT+1))
                done
            fi 
            PERF_CNT=0
            WORKER_CNT=$((WORKER_CNT+1))
            rm -rf $LOCKDIR
        fi 
    done
    echo "worker cgroup ids are ${WORKER_CGROUP_IDS}"
fi 
    EXEC_ID=`docker container top ${WORKER_CONTAINER}-0  | grep executor | tr ' ' '\n' | grep '[^[:blank:]]' | sed -n "2 p"`
    # docker stats ${WORKER_CONTAINER}-0 ${MASTER_CONTAINER} ${CLIENT_CONTAINER} > $UTIL_LOG &
	sudo perf stat -e $PERF_EVENTS --cpu $WORKER_CPUS -p ${EXEC_ID},${WORKER_PIDS} sleep infinity 2>>$PERF_LOG &

    detect_stage executor-killed
    pkill -fx "sleep infinity"
    (($DEV)) && echo "executor killed" 
	detect_stage finished 
	(($DEV)) && echo "Finished"
    # pkill -fx "sleep infinity"
    # pkill -fx "docker stats "
	log_client 

	CNT=$(( CNT+1 ))
	rm -rf $LOCKDIR2
    fi 
done 

client_summary 
cp user.cfg $OUT/user.cfg 
log_folder
