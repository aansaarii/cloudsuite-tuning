#!/bin/bash 

if [ "$#" -ne 1 ]; then
    echo "Illegal number of parameters"
    echo "usage: Command OPERATIONS_FILE"
    exit 1
fi

CLIENT_CPUS=0-31
SERVER_CPUS=32-63

# CLIENT_CPUS=0,2,4,6,8,10,12,14,16,18,20,22 #CPU cores to run the client on
# SERVER_CPUS=1,3,5,7,9,11,13,15 #CPU cores to run the server on

SERVER_MEMORY=20g #Memory available to the server docker container
SOLR_MEM=19g #Memory available to SOLR
RAMPTIME=25
STEADYTIME=25
STOPTIME=15
CLIENT_CONTAINER=web_search_client
SERVER_CONTAINER=web_search_server
CLIENT_IMAGE=web-search-client #Name of web-server client image
SERVER_IMAGE=web-search-server-test #Name of web-search server image
NETWORK=search_network 
INDEX_CONTAINER=index #Name of the web_search_index container which containes the index
OPERATIONS_FILE=$1

LOAD=true
OUTPUTFOLDER=output
UTILFILE=$OUTPUTFOLDER/util.txt
OPERATIONSFILE=$OUTPUTFOLDER/operations.txt
BENCHMARKFILE=$OUTPUTFOLDER/benchmark.txt
ENVIRONMENTFILE=$OUTPUTFOLDER/env.txt
PERFFILE=$OUTPUTFOLDER/perf.txt

rm -rf $OUTPUTFOLDER
mkdir $OUTPUTFOLDER

touch $UTILFILE
touch $OPERATIONSFILE
touch $BENCHMARKFILE
touch $PERFFILE 

set > $ENVIRONMENTFILE

docker rm -f $CLIENT_CONTAINER
if [[ "$LOAD" = true ]]; then 
	docker rm -f $SERVER_CONTAINER
	docker network rm $NETWORK
	docker network create $NETWORK
    docker run -d --name $SERVER_CONTAINER -v:/home/wiki_vol:/home/solr/wiki_dump --cpuset-cpus=$SERVER_CPUS --net $NETWORK --memory=$SERVER_MEMORY $SERVER_IMAGE $SOLR_MEM 1 generate 
fi

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
                return 
            fi
			echo "$2 stage not completed"
			sleep 5 
        done
        ;; 
	esac 
}

# Check if the index node is ready and get the IP
detect_stage server index  

server_proc=`ps aux | grep solr-7.7.1 |tr ' ' '\n' | sed -n "3 p"`
echo "docker prepares client container: ramp-up $RAMPTIME stop $STOPTIME steady state $STEADYTIME"

# Read in thread counts from the operations file 
while read OPERATIONS; do
    THREADS=$OPERATIONS
   
    echo "NUM OPERATIONS = $OPERATIONS"
    echo $OPERATIONS>>$OPERATIONSFILE
    echo "@">>$UTILFILE

    docker rm -f $CLIENT_CONTAINER
    
    echo "docker starts client container $THREADS threads"
    docker run --net=$NETWORK -e JAVA_HOME=/usr/lib/jvm/java-8-openjdk-arm64 --name=$CLIENT_CONTAINER --cpuset-cpus=$CLIENT_CPUS $CLIENT_IMAGE $SERVER_IP $THREADS $RAMPTIME $STOPTIME $STEADYTIME >> $BENCHMARKFILE &
    
	client_proc=$!
  
	detect_stage client ramp-up  
	mpstat -P ALL 1 >> $UTILFILE & 
	perf stat -e instructions:u,instructions:k,cycles --cpu $SERVER_CPUS -p $server_proc sleep infinity 2>>$PERFFILE &
	# perf stat -e instructions:u,instructions:k,cycles --cpu $SERVER_CPUS sleep infinity 2>>$PERFFILE &	
	detect_stage client steady-state 
	pkill mpstat
    pkill -fx "sleep infinity"
	detect_stage client detail 

    wait $client_proc
   
done < $OPERATIONS_FILE
