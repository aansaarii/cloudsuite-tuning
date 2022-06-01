#!/bin/bash 
# set -x 

source ../common/safeguard
source main_func

rm_all_containers

while read RATE; do
  start_dataset
  create_network 

  # SERVER_PID=$(docker inspect -f '{{.State.Pid}}' ${SERVER_CONTAINER})
  echo "starting rate $RATE"

  rm ${OUT}/*
  rm output/*
  echo "$RATE" > $RATE_LOG

  start_server
  sleep 10

  start_client &
  sleep 30

  detect_stage warmup 

  docker stats $(docker ps --format '{{.Names}}') > $UTIL_LOG &
  PID=$!
  #perf stat -e $PERF_EVENTS --cpu $SERVER_CPUS sleep infinity 2>> $PERF_LOG &
  sleep $STEADY_TIME
  echo "execution period finished"

  kill -9 $PID
  #pkill -fx "sleep infinity"
  sed -i "s,\x1B\[[0-9;]*[a-zA-Z],,g" $UTIL_LOG # remove escape characters

  #log_client
  cp -r output $OUT/.
  cp user.cfg $OUT/user.cfg 
  log_folder
  rm_all_containers
  sleep 60
done < $RATES_FILE
