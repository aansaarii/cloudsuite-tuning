#!/bin/bash 

#set -x 
#trap read debug 

GENERATE_INDEX=false
START_SERVER=true

if [ "$#" -ne 1 ]; then
    echo "Illegal number of parameters"
    echo "usage: Command OPERATIONS_FILE"
    exit 1
fi

source cpu_assign.sh 
source config.sh 

if [ "$GENERATE_INDEX" = true ]
then
    docker rm -f $SERVER_CONTAINER
    docker network rm $NETWORK
    docker network create $NETWORK
    docker run -d --name $SERVER_CONTAINER -v $LOCAL_INDEX_VOL:/home/solr -p 8983:8983 --cpuset-cpus=$SERVER_CPUS --net $NETWORK --memory=$SERVER_MEMORY $SERVER_IMAGE $SOLR_MEM 1 generate
fi 

if [ "$START_SERVER" = true ] 
then  
    docker rm -f $SERVER_CONTAINER
    docker network rm $NETWORK
    docker network create $NETWORK
    docker run -d --name $SERVER_CONTAINER -v $LOCAL_INDEX_VOL:/home/solr -p 8983:8983 --cpuset-cpus=$SERVER_CPUS --net $NETWORK --memory=$SERVER_MEMORY $SERVER_IMAGE $SOLR_MEM 1 
fi

#SERVER_CPUS=1,3,5,7,9,11,13,15 #CPU cores to run the server on

# check the logs to determine the stage
function detect_stage () {
    case "$2" in
    index) MATCH="Index Node IP Address:"
        ;;
    ramp-up) MATCH="Ramp up completed"
        ;;
    steady-state) MATCH="Steady state completed"
        ;;
    detail) MATCH="Detail finished"
        ;;
    esac

    case "$1" in
    server)
        while true; do
        # hard-code since it is the only one for server
            
	    if docker logs $SERVER_CONTAINER | grep "$MATCH"; then
                SERVER_IP=`docker logs $SERVER_CONTAINER | grep "$MATCH" | sed 's/.*\:\s//'`
                echo "Index node IP $SERVER_IP"
                return
            fi
            echo "Server Index is not ready "
            sleep 5
        done
        ;;
    client)
        while true; do
            if docker logs $CLIENT_CONTAINER 2>&1 > /dev/null | grep -q "$MATCH"; then
                echo "$MATCH"
                echo "Current time: $(date +"%T")"
                return
            fi
            echo "$2 stage not completed"
            sleep 1
        done
        ;;
    esac
}

# Check if the index node is ready and get the IP
detect_stage server index

USR=polkitd
# USR=systemd

# server_proc=`ps aux | grep solr-7.7.1 | grep $USR |tr ' ' '\n' | grep '[^[:blank:]]' | sed -n "2 p"`
server_proc=$(docker inspect -f '{{.State.Pid}}' $SERVER_CONTAINER)

if [ -z "$server_proc" ]; then 
  echo "Server process not found!"
  docker stop $SERVER_CONTAINER
  exit 2 
fi

# Read in thread counts from the operations file
while read OPERATIONS; do
    THREADS=$OPERATIONS

    echo "NUM OPERATIONS = $OPERATIONS"
    echo $OPERATIONS>>$OPERATIONSFILE

    docker rm -f $CLIENT_CONTAINER

    docker run --net=$NETWORK -e JAVA_HOME=$JAVA_HOME --name=$CLIENT_CONTAINER --cpuset-cpus=$CLIENT_CPUS $CLIENT_IMAGE $SERVER_IP $THREADS $OPERATIONS $STOPTIME $OPERATIONS >> $BENCHMARKFILE &
    client_proc=$!

    detect_stage client ramp-up &
    wait $!

    # echo "Measurement starts $(date +"%T")"
    # mpstat -P ALL 1 >> $UTILFILE &
    # perf record -F 99 -e instructions:u,instructions:k,cycles --call-graph dwarf -p $server_proc sleep $STEADYTIME
    perf stat -e instructions:u,instructions:k,cycles,idle-cycles-frontend,idle-cycles-backend,cache-misses,branch-misses,cache-references --cpu $SERVER_CPUS -p $server_proc sleep infinity 2>>$PERFFILE &
    # sudo perf stat -e instructions:u,instructions:k,cycles --cpu $SERVER_CPUS sleep infinity 2>>$PERFFILE &

    detect_stage client steady-state &
    wait $!

    # pkill mpstat
    sudo pkill -fx "sleep infinity"

    detect_stage client detail

    wait $client_proc

done < $OPERATIONS_FILE
