#!/bin/bash

set -e

source $1

SERVER_THREADS=`echo $SERVER_CPU_SET | tr -cd , | wc -c`
CLIENT_THREADS=`echo $CLIENT_CPU_SET | tr -cd , | wc -c`

echo cpu_set: $SERVER_CPU_SET > $OUTPUT_FILE
echo memory_size: $SERVER_MEMORY >> $OUTPUT_FILE

ssh $SERVER_ADDRESS docker stop dc-server || true
ssh $SERVER_ADDRESS docker rm dc-server || true
ssh $SERVER_ADDRESS docker run --cpuset-cpus $SERVER_CPU_SET  --name dc-server -p 11211:11211 -d $SERVER_IMAGE -t $SERVER_THREADS -m $SERVER_MEMORY -n $KEY_LENGTH

docker stop dc-client || true
docker rm dc-client || true
docker run --cpuset-cpus $CLIENT_CPU_SET -d --network=host --name dc-client $CLIENT_IMAGE bash -c 'cd /usr/src/memcached/memcached_client/; \
    echo '$SERVER_ADDRESS', 11211 > docker_servers.txt; \
    ./loader -a ../twitter_dataset/twitter_dataset_unscaled -o ../twitter_dataset/twitter_dataset_30x -s docker_servers.txt -w '$CLIENT_THREADS' -S '$SCALE_FACTOR' -D '$SERVER_MEMORY' -j -T 1; \
    while true; do sleep 100; done;'

while ! docker logs dc-client 2>&1 | grep -q 'warmed up' &>/dev/null; do sleep 5; echo Waiting to be warmed up!; done;

for i in `seq $START_LOAD $LOAD_STEP $END_LOAD | shuf`; do
	echo rps: $i >> $OUTPUT_FILE;
	docker exec -i dc-client bash -c "cd /usr/src/memcached/memcached_client/; \
		./loader -a ../twitter_dataset/twitter_dataset_30x -s docker_servers.txt -g 0.8 -T 1 -c 200 -w $CLIENT_THREADS -e -r $i" &>> $OUTPUT_FILE &
	sleep 200;
    ssh $SERVER_ADDRESS mpstat -P ALL 5 2 >> $OUTPUT_FILE
	docker exec -i dc-client bash -c "cd /usr/src/memcached/memcached_client/; \
		pkill loader;"
done;
