#!/bin/bash 
# Author: Zilu Tian 

if [[ $# -eq 0 ]]; then 
  echo "Please enter the folder name that contains log file"
  exit 
fi 

if [[ $# -gt 2 ]]; then 
  echo "This script takes at most two args, log folder name and clean (optional)"
  exit 
fi 

LOG=$1
metrics=(metric avg p90th p99th totalOps)

if [ ! -d ${LOG} ]; then 
  echo "Specified log folder doesn't exist"
  exit 
fi 


# Metric vals are specified in xml format 
# Sample output: <avg>0.023</avg>

for metric in ${metrics[@]}; do 
  grep ${metric} ${LOG}/benchmark.txt | grep -o '>.*<' | grep -o [0-9.]* > ${LOG}/ben_${metric}.txt
done

# Throughput vals are repeated twice in ben_metric.txt   
awk 'NR % 2 ==0' ${LOG}/ben_metric.txt > ${LOG}/ben_throughput.txt

grep CPUS ${LOG}/env.txt | grep -o [0-9,-]* > ${LOG}/env_cpus.txt

if [[ $2 = 'clean' ]]; then 
  rm $LOG/ben_*.txt
fi 
