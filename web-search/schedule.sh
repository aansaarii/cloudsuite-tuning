#!/bin/bash 

LOGFILE=log 
LOGFOLDER=cavium/multithreads

echo "Run started" > $LOGFILE 
date -u >> $LOGFILE
./benchmark_run.sh load.txt 
mv output ${LOGFOLDER}/single-thread

echo "Run completed" >> $LOGFILE
date -u >> $LOGFILE

MOD=( 's/CLIENT_CPUS=0/CLIENT_CPUS=0,1/g;s/SERVER_CPUS=28/SERVER_CPUS=28,29/g'\
's/CLIENT_CPUS=0,1/CLIENT_CPUS=0,1,2/g;s/SERVER_CPUS=28,29/SERVER_CPUS=28,29,30/g'\
's/CLIENT_CPUS=0,1,2/CLIENT_CPUS=0,1,2,3/g;s/SERVER_CPUS=28,29,30/SERVER_CPUS=28,29,30,31/g'
)

CNT=0
MAX=${#MOD[@]}

while [[ ${CNT} -le ${MAX} ]]; do
	echo "Run ${CNT} started" >> $LOGFILE
	
	FOO=MOD[${CNT}]
	sed -ri ${!FOO} cpu_assign.sh
	./benchmark_run.sh load.txt

	echo "Run completed" >> $LOGFILE
	date -u >> $LOGFILE
	
	CNT=$((CNT + 1))
    OUTCNT=$((CNT+1))	
	mv output ${LOGFOLDER}/${OUTCNT}-thread
done

