if [ "$#" -ne 2 ]; then
    echo "Illegal number of parameters"
    echo "usage: Command RECORDS OPERATIONS_FILE"
    exit 1
fi
THREADS=42
TARGET=100000
CLIENT_CPUS=0-5
SERVER_CPUS=6-7
CLIENT_CONTAINER=cassandra-client
SERVER_CONTAINER=cassandra-server
RECORDS=$1
OPERATIONS_FILE=$2

OUTPUTFOLDER=output
UTILFILE=$OUTPUTFOLDER/util.txt
OPERATIONSFILE=$OUTPUTFOLDER/operations.txt
DISPLAYFILE=$OUTPUTFOLDER/display.txt
BENCHMARKFILE=$OUTPUTFOLDER/benchmark.txt

rm $UTILFILE && touch $UTILFILE
rm $OPERATIONSFILE && touch $OPERATIONSFILE
rm $BENCHMARKFILE && touch $BENCHMARKFILE

docker rm -f $CLIENT_CONTAINER
docker rm -f $SERVER_CONTAINER
docker network rm serving_network
docker system prune -f

docker network create serving_network
docker run --rm -d --name $SERVER_CONTAINER --cpuset-cpus=$SERVER_CPUS --net serving_network server

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


docker exec -it CLIENT_CONTAINER "/ycsb/bin/ycsb load cassandra-cql -p hosts=$SERVER_CONTAINER -P /ycsb/workloads/workloada -p recordcount=$RECORDS"
mpstat -P 0-7 1 &
echo "WARMING UP"
pkill mpstat
docker exec $CLIENT_CONTAINER bash -c "/ycsb/bin/ycsb run cassandra-cql -p hosts=$SERVER_CONTAINER -P /ycsb/workloads/workloada -s -target $TARGET -threads $THREADS -p operationcount=10000"
while read OPERATIONS; do
    echo "NUM OPERATIONS = $OPERATIONS"
    echo $OPERATIONS>>$OPERATIONSFILE
    echo "@">>$UTILFILE
    mpstat -P 0-7 1 >> $UTILFILE &
    (docker exec $CLIENT_CONTAINER bash -c "/ycsb/bin/ycsb run cassandra-cql -p hosts=$SERVER_CONTAINER -P /ycsb/workloads/workloada -s -target $TARGET -threads $THREADS -p operationcount=$OPERATIONS")>>$BENCHMARKFILE
    pkill mpstat
done < $OPERATIONS_FILE
