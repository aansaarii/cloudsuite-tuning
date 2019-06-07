#!/bin/bash 

RED='\033[0;31m'
NC='\033[0m'

if [ "$#" -ne 2 ]; then
    echo "Illegal number of parameters"
    echo "usage: Command RECORDS OPERATIONS_FILE"
    exit 1
fi
THREADS=64
THREADS_LOAD=10
CLIENT_CPUS=0
SERVER_CPUS=1
SERVER_MEMORY=20g
CLIENT_CONTAINER=cassandra-client
SERVER_CONTAINER=cassandra-server
CLIENT_IMAGE=zilutian/data-serving-client-v2
SERVER_IMAGE=zilutian/data-serving:server-amd64

RECORDS=$1
OPERATIONS_FILE=$2
LOAD=true 
OUTPUTFOLDER=output
UTILFILE=$OUTPUTFOLDER/util.txt
OPERATIONSFILE=$OUTPUTFOLDER/operations.txt
DISPLAYFILE=$OUTPUTFOLDER/display.txt
BENCHMARKFILE=$OUTPUTFOLDER/benchmark.txt
PERFFILE=$OUTPUTFOLDER/perf.txt
ENVIRONMENTFILE=$OUTPUTFOLDER/env.txt
MULTIPLIER=100

mkdir $OUTPUTFOLDER
rm -f $UTILFILE && touch $UTILFILE
rm -f $OPERATIONSFILE && touch $OPERATIONSFILE
rm -f $BENCHMARKFILE && touch $BENCHMARKFILE
rm -f $PERFFILE && touch $PERFFILE
rm -f $ENVRONMENTFILE && touch $ENVRONMENTFILE
set > $ENVIRONMENTFILE

docker rm -f $CLIENT_CONTAINER

if [ "$LOAD" = true ]
then    
    docker rm -f $SERVER_CONTAINER
fi

docker network rm serving_network


docker network create serving_network
if [ "$LOAD" = true ]
then
    docker run -d --name $SERVER_CONTAINER --cpuset-cpus=$SERVER_CPUS --net serving_network --memory=$SERVER_MEMORY $SERVER_IMAGE
fi

SERVER_PROC=$(docker inspect -f '{{.State.Pid}}' $SERVER_CONTAINER)

while [ 1 ]; do
    docker logs $SERVER_CONTAINER | grep 'Created default superuser role' &> /dev/null
    if [ $? == 0 ]; then
	echo -e "${RED}Done creating server ${NC}"
	break;
    fi
    docker logs $SERVER_CONTAINER
    echo "Sleeping"
    sleep 5
done

docker run -it -d --cpuset-cpus=$CLIENT_CPUS --name $CLIENT_CONTAINER --net serving_network $CLIENT_IMAGE "cassandra-server" 


while [ 1 ]; do
    docker logs $CLIENT_CONTAINER | grep 'Keyspace usertable was created' &> /dev/null
    if [ $? == 0 ]; then
	echo -e "${RED}Done inserting the keyspace usertable${NC}"
	break;
    fi
    docker logs $CLIENT_CONTAINER
    echo "Sleeping"
    sleep 5
done
echo $RECORDS
echo $SERVER_CONTAINER

#read -p "BEFORE LOAD"

echo -e "${RED}Total record count $RECORDS ${NC}"

#read -p "BEFORE LOAD"
if [ "$LOAD" = true ]
then
    docker exec -it $CLIENT_CONTAINER bash -c "/ycsb/bin/ycsb load cassandra-cql -p hosts=$SERVER_CONTAINER -P /ycsb/workloads/workloadb -s -threads $THREADS_LOAD -p recordcount=$RECORDS"
fi

#read -p "AFTER LOAD"
# mpstat -P ALL 1 &
echo -e "${RED}WARMING UP ${NC}"

docker exec $CLIENT_CONTAINER bash -c "/ycsb/bin/ycsb run cassandra-cql -p hosts=$SERVER_CONTAINER -P /ycsb/workloads/workloadb -s -threads $THREADS -p operationcount=10000 -p recordcount=$RECORDS"
# pkill mpstat

while read OPERATIONS; do
    TARGET="$((OPERATIONS * MULTIPLIER))"
    echo "NUM OPERATIONS = $OPERATIONS"
    echo "TARGET = $TARGET"
    echo $OPERATIONS>>$OPERATIONSFILE
    echo "@">>$UTILFILE
   # docker rm -f $CLIENT_CONTAINER
   # docker run --rm -it -d --cpuset-cpus=$CLIENT_CPUS --name $CLIENT_CONTAINER --net serving_network client "cassandra-server"
    # while [ 1 ]; do
    # 	docker logs $CLIENT_CONTAINER | grep 'Keyspace usertable was created' &> /dev/null
    # 	if [ $? == 0 ]; then
    # 	    echo "Done"
    # 	    break;
    # 	fi
    # 	docker logs $CLIENT_CONTAINER
    # 	echo "Sleeping"
    # 	sleep 5
    # done
    #docker exec $CLIENT_CONTAINER bash -c "/ycsb/bin/ycsb run cassandra-cql -p hosts=$SERVER_CONTAINER -P /ycsb/workloads/workloada -s -target 1000 -threads $THREADS -p operationcount=$TARGET"
    # mpstat -P ALL 1 >> $UTILFILE &
    sudo perf stat -e instructions:u,cycles:u,cpu/event=0xc2,umask=0x01,name=uops_retired/,cpu/event=0xc2,umask=0x01,name=uops_retired:u/u,cpu/event=0xc2,umask=0x01,inv=1,cmask=1,name=uops_stalled/ --cpu $SERVER_CPUS -p ${SERVER_PROC} sleep infinity 2>>$PERFFILE &  
    (docker exec $CLIENT_CONTAINER bash -c "/ycsb/bin/ycsb run cassandra-cql -p hosts=$SERVER_CONTAINER -P /ycsb/workloads/workloadb -s -threads $THREADS -p operationcount=$TARGET -p recordcount=$RECORDS")>>$BENCHMARKFILE &
    pid1=$!
#    (docker exec $CLIENT_CONTAINER bash -c "/ycsb/bin/ycsb run cassandra-cql -p hosts=$SERVER_CONTAINER -P /ycsb/workloads/workloada -s -target $TARGET -threads $THREADS -p operationcount=$OPERATIONS")>>$BENCHMARKFILE2 &
 #   pid2=$!
    wait $pid1 
    sudo pkill -fx "sleep infinity"
    # pkill mpstat
done < $OPERATIONS_FILE 
