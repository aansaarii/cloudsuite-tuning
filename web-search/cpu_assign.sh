#!/bin/bash 
#
#Author: Zilu Tian 
#Date: April 4, 2019  
# 
#Check the CPU assignment is valid

CLIENT_CPUS=0-15
SERVER_CPUS=16-23

function valid_core_spec () {
  # pattern: On-line CPU(s) list:   0-23
  max_avail_cores=`lscpu | grep -oP "CPU\((s\)) list: \K.*" | tr "-" "\n" | sed -n 2p`
  max_client_cores=`echo $CLIENT_CPUS | tr "-" "\n" | sed -n 2p`
  max_server_cores=`echo $SERVER_CPUS | tr "-" "\n" | sed -n 2p`

  if [ $max_client_cores -gt $max_server_cores ]; then 
    max_req_cores=$max_client_cores
  else
    max_req_cores=$max_server_cores
  fi
  
  echo "$max_avail_cores cores available. Max ID of requested core is $max_req_cores"

  if [ $max_req_cores -gt $max_avail_cores ]; then 
    echo "Requested more cores than available"
    exit 1
  fi 
}

valid_core_spec
