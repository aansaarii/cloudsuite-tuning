#!/bin/bash 
# set -x 

source ../common/safeguard
source main_func

#create_network 

start_memcached 
start_cassandra
start_graphite
start_uwsgi
start_siege & 
detect_stage started
docker stats $(docker ps --format '{{.Names}}') > $UTIL_LOG &
perf stat -e $PERF_EVENTS --cpu $SERVER_CPUS sleep infinity 2>> $PERF_LOG &
detect_stage finished
pkill -f "docker-current"
pkill -fx "sleep infinity"
sed -i "s,\x1B\[[0-9;]*[a-zA-Z],,g" $UTIL_LOG
cp user.cfg $OUT/user.cfg
log_containers
log_folder
rm_all_containers

