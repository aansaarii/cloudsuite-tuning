if [ "$#" -ne 1 ]; then
    echo "Illegal number of parameters"
    echo "usage: Command OPERATIONS_FILE"
    exit 1
fi
CLIENT_CPUS=0-3 #CPU cores to run the client on
SERVER_CPUS=4-7 #CPU cores to run the server on
SERVER_MEMORY=20g #Memory available to the server docker container
SOLR_MEM=14g #Memory available to SOLR
RAMPTIME=60
STEADYTIME=30
STOPTIME=30
CLIENT_CONTAINER=web_search_client
SERVER_CONTAINER=web_search_server
CLIENT_IMAGE=web_search_client #Name of web-server client image
SERVER_IMAGE=web_search_server #Name of web-search server image
NETWORK=web_search_network 
INDEX_CONTAINER=index #Name of the web_search_index container which containes the index
OPERATIONS_FILE=$1
LOAD=true
OUTPUTFOLDER=output
UTILFILE=$OUTPUTFOLDER/util.txt
OPERATIONSFILE=$OUTPUTFOLDER/operations.txt
DISPLAYFILE=$OUTPUTFOLDER/display.txt
BENCHMARKFILE=$OUTPUTFOLDER/benchmark.txt
ENVIRONMENTFILE=$OUTPUTFOLDER/env.txt
PERFFILE=$OUTPUTFOLDER/perf.txt
rm $PERFFILE
rm $UTILFILE && touch $UTILFILE
rm $OPERATIONSFILE && touch $OPERATIONSFILE
rm $BENCHMARKFILE && touch $BENCHMARKFILE
set > $ENVIRONMENTFILE
docker rm -f $CLIENT_CONTAINER
if [ "$LOAD" = true ]
then    
    docker rm -f $SERVER_CONTAINER
fi

docker network rm $NETWORK


docker network create $NETWORK
if [ "$LOAD" = true ]
then
    docker run -d --name $SERVER_CONTAINER --volumes-from=index --cpuset-cpus=$SERVER_CPUS --net $NETWORK --memory=$SERVER_MEMORY $SERVER_IMAGE $SOLR_MEM 1
fi



while true; do
    if docker logs $SERVER_CONTAINER | grep -q 'Index Node IP Address: 172'; then
	SERVER_IP=`docker logs $SERVER_CONTAINER | grep 'Index Node IP Address: 172' | sed 's/.*\:\s//'`
	echo "Index is ready. Server IP is $SERVER_IP "
	break;
    fi
    echo "Index is not ready ... "
    sleep 5
done


while read OPERATIONS; do
    THREADS=$OPERATIONS
   
    echo "NUM OPERATIONS = $OPERATIONS"
   
    echo $OPERATIONS>>$OPERATIONSFILE
    echo "@">>$UTILFILE

    docker rm -f $CLIENT_CONTAINER
   
    echo "docker run --net=$NETWORK --name=$CLIENT_CONTAINER --cpuset-cpus=$CLIENT_CPUS $CLIENT_IMAGE $SERVER_IP $THREADS $RAMPTIME $STEADYTIME $STOPTIME"
    docker run --net=$NETWORK --name=$CLIENT_CONTAINER --cpuset-cpus=$CLIENT_CPUS $CLIENT_IMAGE $SERVER_IP $THREADS $RAMPTIME $STEADYTIME $STOPTIME >> $BENCHMARKFILE &
    pid1=$!
    echo "Done Running"
    while true; do
	if docker logs $CLIENT_CONTAINER 2>&1 >/dev/null | grep -q 'Ramp up completed'; then
	    mpstat -P ALL 1 >> $UTILFILE &
	    perf stat -e instructions:u,instructions:k,cycles --cpu $SERVER_CPUS sleep infinity 2>>$PERFFILE & 
	    echo "Ramp up completed. Logging CPU Util"
	    break;
	fi
	echo "Ramp up not finished ... "
	sleep 1
    done

    while true; do
	if docker logs $CLIENT_CONTAINER 2>&1 >/dev/null | grep -q 'Steady state completed'; then
	    pkill mpstat
	    pkill -fx "sleep infinity"
	    echo "Steady State completed. Stopped Logging CPU Util"
	    break;
	fi
	echo "Steady state not finished ... "
	sleep 1
    done

    while true; do
	if docker logs $CLIENT_CONTAINER 2>&1 >/dev/null | grep -q 'Detail finished'; then
	    echo "Benchmark completed completed."
	    break;
	fi
	echo "Benchmark not finished ... "
	sleep 1
    done
    wait $pid1
   

    
done < $OPERATIONS_FILE
