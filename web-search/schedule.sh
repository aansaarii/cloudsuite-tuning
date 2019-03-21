#!/bin/bash 

LOGFILE=log 
LOGFOLDER=log_18g

echo "Run started" > $LOGFILE 
echo "$LOGFOLDER" >> $LOGFILE

date -u >> $LOGFILE
./benchmark_run.sh load.txt 
mv output ${LOGFOLDER}0 
echo "Run completed" >> $LOGFILE
date -u >> $LOGFILE

MOD=( 's/SERVER_MEMORY=25g/SERVER_MEMORY=40g/g;s/SOLR_MEM=19g/SOLR_MEM=30g/g'\
	's/LOAD=true/LOAD=false/g'\
	's/RAMPTIME=20/RAMPTIME=15/g'\
	's/RAMPTIME=15/RAMPTIME=20/g;s/STEADYTIME=20/STEADYTIME=15/g'\
	's/STEADYTIME=15/STEADYTIME=20/g;s/STOPTIME=10/STOPTIME=5/g' )
CNT=0
MAX=${#MOD[@]}

while [[ ${CNT} -le ${MAX} ]]; do
	echo "Run ${CNT} started" >> $LOGFILE
	
	FOO=MOD[${CNT}]
	sed -ri ${!FOO} benchmark_run.sh
	./benchmark_run.sh load.txt

	echo "Run completed" >> $LOGFILE
	date -u >> $LOGFILE
	
	CNT=$((CNT + 1))
	
	mv output ${LOGFOLDER}${CNT}
done

