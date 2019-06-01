#!/bin/bash 

LOGFILE=log 
LOGFOLDER=cavium/experimental2/

echo "Run started" > $LOGFILE 
date -u >> $LOGFILE
./benchmark_run.sh load.txt 
mv output ${LOGFOLDER}/0

echo "Run completed" >> $LOGFILE
date -u >> $LOGFILE

if [ 0 -eq 1 ]; then 
MOD=( 's/CLIENT_CPUS=.*$/CLIENT_CPUS=0-1/g;s/SERVER_CPUS=.*$/SERVER_CPUS=28-29/g' \
's/CLIENT_CPUS=.*$/CLIENT_CPUS=0-2/g;s/SERVER_CPUS=.*$/SERVER_CPUS=28-30/g' \
's/CLIENT_CPUS=.*$/CLIENT_CPUS=0-3/g;s/SERVER_CPUS=.*$/SERVER_CPUS=28-31/g' \
's/CLIENT_CPUS=.*$/CLIENT_CPUS=0-4/g;s/SERVER_CPUS=.*$/SERVER_CPUS=28-32/g' \
's/CLIENT_CPUS=.*$/CLIENT_CPUS=0-13/g;s/SERVER_CPUS=.*$/SERVER_CPUS=28-41/g' \
's/CLIENT_CPUS=.*$/CLIENT_CPUS=0-27/g;s/SERVER_CPUS=.*$/SERVER_CPUS=28-55/g' 
)
fi 

sed -ri s/START_SERVER.*$/START_SERVER=false/g benchmark_run.sh

MOD=( 's/SERVER_CPUS=.*$/SERVER_CPUS=28-29/g' \
's/SERVER_CPUS=.*$/SERVER_CPUS=28-30/g' \
's/SERVER_CPUS=.*$/SERVER_CPUS=28-31/g' \
's/SERVER_CPUS=.*$/SERVER_CPUS=28-32/g' \
's/SERVER_CPUS=.*$/SERVER_CPUS=28-41/g' \
's/SERVER_CPUS=.*$/SERVER_CPUS=28-55/g'
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
	mv output ${LOGFOLDER}/${CNT}
done

