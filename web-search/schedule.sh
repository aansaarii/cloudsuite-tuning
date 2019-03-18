#!/bin/bash 

LOGFILE=log 
LOGFOLDER=log_18g

if [[ 0 -eq 1 ]]; then 
echo "Run started" > $LOGFILE 
echo "$LOGFOLDER" >> $LOGFILE

date -u >> $LOGFILE
./benchmark_run.sh load.txt 
mv output ${LOGFOLDER}0 
echo "Run completed" >> $LOGFILE
date -u >> $LOGFILE

fi

MOD1='s/SERVER_CPUS=16-23/SERVER_CPUS=16-31/g'
MOD2='s/SERVER_CPUS=16-31/SERVER_CPUS=32-63/g;s/CLIENT_CPUS=0-15/CLIENT_CPUS=0-31/g'
MOD3='s/SERVER_MEMORY=20g/SERVER_MEMORY=40g/g;s/SOLR_MEM=19g/SOLR_MEM=30g/g'
MOD4='s/LOAD=true/LOAD=false/g'

CNT=1
MAX=4

while [[ ${CNT} -le ${MAX} ]]; do
	echo "Run ${CNT} started" >> $LOGFILE
	
	FOO="MOD"$CNT
	sed -ri ${!FOO} benchmark_run.sh
	./benchmark_run.sh load.txt
	mv output ${LOGFOLDER}${CNT}

	echo "Run completed" >> $LOGFILE
	date -u >> $LOGFILE
	
	CNT=$((CNT + 1))
done

