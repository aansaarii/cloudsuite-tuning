#!/bin/bash 
# set -x 

source ../common/safeguard
source main_func

rm_all_containers

while read RATE; do
  rm ${OUT}/*
  rm output/*

  start_dataset
#  create_network 

  exit 0
  # SERVER_PID=$(docker inspect -f '{{.State.Pid}}' ${SERVER_CONTAINER})

  echo "starting rate $RATE"
  echo "$RATE" > $RATE_LOG

  echo "before experiment" > $SOCKET_LOG
  ss -s >> $SOCKET_LOG

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
  echo "after experiment" >> $SOCKET_LOG
  ss -s >> $SOCKET_LOG

  log_folder
  
  rm_all_containers

  sleep 120 # this is the time required to tcp ports in timewait state become available for the next experiment
done < $RATES_FILE
