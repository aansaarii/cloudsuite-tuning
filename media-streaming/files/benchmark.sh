#!/bin/bash

num_clients_per_machine=15
min_num_sessions=1000
max_num_sessions=5000

streaming_client_dir=..
#server_ip=$(tail -n 1 hostlist.server)
server_ip=$1

peak_hunter/launch_hunt_bin.sh                     \
    $server_ip                                 \
    hostlist.client                            \
    $streaming_client_dir                      \
    $num_clients_per_machine                   \
    $min_num_sessions                          \
    $max_num_sessions

./process_logs.sh

