#!/bin/bash

# set -x
LOGFILE=log

rm -rf /tmp/da_scheduler.lock

function change_servers() {
    MOD=( 's/WORKER_CPUS=.*$/WORKER_CPUS=0-27/g' \
    's/WORKER_CPUS=.*$/WORKER_CPUS=0-20/g' \
    's/WORKER_CPUS=.*$/WORKER_CPUS=0-13/g' \
    's/WORKER_CPUS=.*$/WORKER_CPUS=0-11/g' \
    's/WORKER_CPUS=.*$/WORKER_CPUS=0-7/g' \
    's/WORKER_CPUS=.*$/WORKER_CPUS=0-3/g' \
    's/WORKER_CPUS=.*$/WORKER_CPUS=0/g'
    )

    CNT=0
    MAX=${#MOD[@]}
    lockdir=/tmp/da_scheduler.lock

    while [[ ${CNT} -lt ${MAX} ]]; do
        if mkdir $lockdir
        then
            docker volume ls -qf dangling=true | xargs -r docker volume rm
            echo "Run ${CNT} started" >> $LOGFILE
            date -u >> $LOGFILE
            FOO=MOD[${CNT}]

            sed -ri ${!FOO} user.cfg
            bash run.sh
            echo "Run completed" >> $LOGFILE
            date -u >> $LOGFILE

            CNT=$((CNT + 1))
            rm -rf $lockdir
        fi
        sleep 20
    done
}

change_servers

