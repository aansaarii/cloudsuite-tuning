if [ "$#" -ne 2 ]; then
    echo "Illegal number of parameters"
    echo "usage: Command RECORDS OPERATIONS_FILE"
    exit 1
fi
THREADS=64
THREADS_LOAD=10
TARGET=100000
CLIENT_CPUS=32-47
SERVER_CPUS=16-19
SERVER_MEMORY=10g
CLIENT_CONTAINER=cassandra-client
SERVER_CONTAINER=cassandra-server
RECORDS=$1
OPERATIONS_FILE=$2
LOAD=true
OUTPUTFOLDER=output
UTILFILE=$OUTPUTFOLDER/util.txt
OPERATIONSFILE=$OUTPUTFOLDER/operations.txt
DISPLAYFILE=$OUTPUTFOLDER/display.txt
BENCHMARKFILE=$OUTPUTFOLDER/benchmark.txt
BENCHMARKFILE2=$OUTPUTFOLDER/benchmark2.txt
ENVIRONMENTFILE=$OUTPUTFOLDER/env.txt
MULTIPLIER=10
rm $UTILFILE && touch $UTILFILE
rm $OPERATIONSFILE && touch $OPERATIONSFILE
rm $BENCHMARKFILE && touch $BENCHMARKFILE
rm $BENCHMARKFILE2 && touch $BENCHMARKFILE2
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
    docker run -d --name $SERVER_CONTAINER --cpuset-cpus=$SERVER_CPUS --net serving_network --memory=$SERVER_MEMORY server
fi


while [ 1 ]; do
    docker logs $SERVER_CONTAINER | grep 'Created default superuser role' &> /dev/null
    if [ $? == 0 ]; then
	echo "Done"
	break;
    fi
    docker logs $SERVER_CONTAINER
    echo "Sleeping"
    sleep 5
done

docker run --rm -it -d --cpuset-cpus=$CLIENT_CPUS --name $CLIENT_CONTAINER --net serving_network client "cassandra-server"



while [ 1 ]; do
    docker logs $CLIENT_CONTAINER | grep 'Keyspace usertable was created' &> /dev/null
    if [ $? == 0 ]; then
	echo "Done"
	break;
    fi
    docker logs $CLIENT_CONTAINER
    echo "Sleeping"
    sleep 5
done
echo $RECORDS
echo $SERVER_CONTAINER

#read -p "BEFORE LOAD"


while [ 1 ]; do
    docker logs $SERVER_CONTAINER | grep 'Created default superuser role' &> /dev/null
    if [ $? == 0 ]; then
	echo "Done"
	break;
    fi
    docker logs $SERVER_CONTAINER
    echo "Sleeping"
    sleep 5
done

docker run --rm -it -d --cpuset-cpus=$CLIENT_CPUS --name $CLIENT_CONTAINER --net serving_network client "cassandra-server"



while [ 1 ]; do
    docker logs $CLIENT_CONTAINER | grep 'Keyspace usertable was created' &> /dev/null
    if [ $? == 0 ]; then
	echo "Done"
	break;
    fi
    docker logs $CLIENT_CONTAINER
    echo "Sleeping"
    sleep 5
done
echo $RECORDS
echo $SERVER_CONTAINER

#read -p "BEFORE LOAD"
if [ "$LOAD" = true ]
then
    docker exec -it $CLIENT_CONTAINER bash -c "/ycsb/bin/ycsb load cassandra-cql -p hosts=$SERVER_CONTAINER -P /ycsb/workloads/workloada -s -target $TARGET -threads $THREADS_LOAD -p recordcount=$RECORDS"
fi

#read -p "AFTER LOAD"
mpstat -P ALL 1 &
echo "WARMING UP"

docker exec $CLIENT_CONTAINER bash -c "/ycsb/bin/ycsb run cassandra-cql -p hosts=$SERVER_CONTAINER -P /ycsb/workloads/workloada -s -target $TARGET -threads $THREADS -p operationcount=10000"
pkill mpstat

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
    mpstat -P ALL 1 >> $UTILFILE &
    (docker exec $CLIENT_CONTAINER bash -c "/ycsb/bin/ycsb run cassandra-cql -p hosts=$SERVER_CONTAINER -P /ycsb/workloads/workloada -s -target $OPERATIONS -threads $THREADS -p operationcount=$TARGET")>>$BENCHMARKFILE &
    pid1=$!
#    (docker exec $CLIENT_CONTAINER bash -c "/ycsb/bin/ycsb run cassandra-cql -p hosts=$SERVER_CONTAINER -P /ycsb/workloads/workloada -s -target $TARGET -threads $THREADS -p operationcount=$OPERATIONS")>>$BENCHMARKFILE2 &
 #   pid2=$!
    wait $pid1 $pid2
    pkill mpstat
done < $OPERATIONS_FILE
