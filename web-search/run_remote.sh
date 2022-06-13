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

#  (($START_SERVER)) && start_server 

  echo "docker stop $SERVER_CONTAINER; docker rm $SERVER_CONTAINER;" | ssh n135 /bin/bash 
  echo "docker run -d --name $SERVER_CONTAINER --cpuset-cpus=$SERVER_CPUS --volumes-from ${DATASET_CONTAINER} --net $NET $SERVER_IMAGE 12g 1" | ssh n135 /bin/bash

  #detect_stage index-node-ready
  sleep 30 # TODO: read the server ip from the container on a remote machine

  clean_containers $CLIENT_CONTAINER
  start_client &
  CLIENT_PID=$!

  detect_stage rampup-completed
  echo "rampup completed" >> $UTIL_LOG 
  echo "docker stats web_search_server > /home/aansari/cloudsuite-tuning/web-search/$UTIL_LOG &" | ssh n135 /bin/bash
  docker stats $(docker ps --format '{{.Names}}') > $OUT/client_util.txt &
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

  cp user.cfg $OUT/user.cfg
  log_folder
done
