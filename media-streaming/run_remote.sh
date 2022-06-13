#!/bin/bash 
# set -x 

source ../common/safeguard
source main_func

rm_all_containers

while read RATE; do
  rm ${OUT}/*
  rm output/*

  echo "starting rate $RATE"
  echo "$RATE" > $RATE_LOG


  #start_dataset
  #create_network 

  # SERVER_PID=$(docker inspect -f '{{.State.Pid}}' ${SERVER_CONTAINER})

  #start_server
  echo "docker stop $SERVER_CONTAINER; docker rm $SERVER_CONTAINER;" | ssh n135 /bin/bash
  echo "docker run -d --name $SERVER_CONTAINER --cpuset-cpus=$SERVER_CPUS --volumes-from $DATASET_CONTAINER --net $NET $SERVER_IMAGE $NUM_WORKERS" | ssh n135 /bin/bash
  sleep 10

  start_client &
  sleep 30

  detect_stage warmup 

  docker stats $(docker ps --format '{{.Names}}') > $OUT/client_util.txt &
  PID=$!
  echo "A"
  echo "docker stats media_streaming_server > /home/aansari/cloudsuite-tuning/media-streaming/$UTIL_LOG &" | ssh n135 /bin/bash
  echo "B"
  #perf stat -e $PERF_EVENTS --cpu $SERVER_CPUS sleep infinity 2>> $PERF_LOG &
  echo "C"
  sleep $STEADY_TIME
  echo "execution period finished"

  kill -9 $PID
  echo "pkill -f docker-current" | ssh n135 /bin/bash
  #pkill -fx "sleep infinity"
  sed -i "s,\x1B\[[0-9;]*[a-zA-Z],,g" $UTIL_LOG # remove escape characters
  sed -i "s,\x1B\[[0-9;]*[a-zA-Z],,g" $OUT/client_util.txt # remove escape characters


  #log_client
  cp -r output $OUT/.
  cp user.cfg $OUT/user.cfg 
  #echo "docker cp $SERVER_CONTAINER:/var/log/nginx/ /home/aansari/cloudsuite-tuning/media-streaming/$OUT/." | ssh n135 /bin/bash
  log_folder
  rm_all_containers
  echo "docker stop $SERVER_CONTAINER; docker rm $SERVER_CONTAINER;" | ssh n135 /bin/bash
  sleep 120
done < $RATES_FILE
