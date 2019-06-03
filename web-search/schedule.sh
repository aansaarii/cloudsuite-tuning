#!/bin/bash 

# set -x 
LOGFILE=log 
LOGFOLDER=cavium/single-core-client/
rm -rf /tmp/ws_scheduler.lock
rm -rf server-finished
rm -rf ${LOGFOLDER}/*

cp benchmark_run.sh $LOGFOLDER/benchmark_cp 

echo "Initial run started" > $LOGFILE 
date -u >> $LOGFILE

./benchmark_run.sh load.txt
#echo "hello" > output 
mv output ${LOGFOLDER}/0

echo "Run completed" >> $LOGFILE
date -u >> $LOGFILE

function change_servers() {
    MOD=( 's/SERVER_CPUS=.*$/SERVER_CPUS=112-117/g' \
    's/SERVER_CPUS=.*$/SERVER_CPUS=112,140/g' \
    's/SERVER_CPUS=.*$/SERVER_CPUS=112,140,168,196/g' \
    's/SERVER_CPUS=.*$/SERVER_CPUS=112-117,140-145/g' \
    's/SERVER_CPUS=.*$/SERVER_CPUS=112-117,140-145,168-173,196-201/g' \
    's/SERVER_CPUS=.*$/SERVER_CPUS=112-167/g' \
    's/SERVER_CPUS=.*$/SERVER_CPUS=112-223/g' 
    )

    CNT=0
    MAX=${#MOD[@]}
    lockdir=/tmp/ws_scheduler.lock 

    while [[ ${CNT} -lt ${MAX} ]]; do
	    if mkdir $lockdir
	    then 
	    echo "Run ${CNT} started" >> $LOGFILE
	    FOO=MOD[${CNT}]
	    
	    sed -ri ${!FOO} cpu_assign.sh
 	    ./benchmark_run.sh load.txt
	    # echo "${!FOO}" > output 
	    echo "Run completed" >> $LOGFILE
	    date -u >> $LOGFILE
	    
	    CNT=$((CNT + 1))
	    mv output ${LOGFOLDER}/${CNT}
	    rm -rf $lockdir
	fi 
    done
    
    if [ ${CNT} -eq ${MAX} ]; then 
	mkdir server-finished	
    fi 
}

change_servers &
wait $! 

if [ -d server-finished ]; then  
    rm -rf server-finished
    sed -ri 's/CLIENT_CPUS=.*$/CLIENT_CPUS=0-5/g' cpu_assign.sh 
    sed -ri 's/SERVER_CPUS=.*$/SERVER_CPUS=112/g' cpu_assign.sh
    LOGFOLDER=cavium/single-chip-client/
    rm -rf /tmp/ws_scheduler.lock
    rm -rf ${LOGFOLDER}/*

    date -u >> $LOGFILE
    ./benchmark_run.sh load.txt 
    # echo "Hello again" > output 
    mv output ${LOGFOLDER}/0

    echo "Run initial completed" >> $LOGFILE
    date -u >> $LOGFILE

    change_servers & 
    wait $! 
fi 
