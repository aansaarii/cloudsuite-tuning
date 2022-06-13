#!/bin/bash 
#set -x 
source ../common/safeguard
source main_func


create_network 
#(($GENERATE_INDEX)) && generate_index
#(($MOUNT_DATASET)) && start_dataset


ARY=""
while read LOAD; do
  ARY+=($LOAD)
done < $LOADS_FILE

for LOAD in ${ARY[@]}; do
  SCALE=$LOAD
  echo "SCALE is $SCALE"
#  continue 

  (($START_SERVER)) && start_server 

  detect_stage index-node-ready

  clean_containers $CLIENT_CONTAINER
  start_client &
  CLIENT_PID=$!

  detect_stage rampup-completed
  echo "rampup completed" >> $UTIL_LOG 
  docker stats $(docker ps --format '{{.Names}}') > $UTIL_LOG &
  PID=$!
  #SERVER_PID=`docker container top $SERVER_CONTAINER  | grep solr | tr ' ' '\n' | grep '[^[:blank:]]' | sed -n "2 p"`
  #sudo perf stat -e $PERF_EVENTS --cpu $SERVER_CPUS -p $SERVER_PID sleep infinity 2>>$PERF_LOG &
  detect_stage steady-state-completed
  pkill -fx "sleep infinity"
  kill -9 $PID
  sed -i "s,\x1B\[[0-9;]*[a-zA-Z],,g" $UTIL_LOG # remove escape characters
  detect_stage results-written
  wait $CLIENT_PID
  sleep 10
  log_client 

  client_summary
  cp user.cfg $OUT/user.cfg
  log_folder
done

echo "reached exit"

