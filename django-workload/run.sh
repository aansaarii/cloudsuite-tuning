docker stop $(docker ps -aq)
docker rm $(docker ps -aq)

IP=192.168.9.136

docker run -tid --name memcached_container --network host cloudsuite/django-workload:memcached
sleep 10
docker run -tid --name cassandra_container -e SYSTEM_MEMORY=8 -e ENDPOINT="192.168.9.136" --network host cloudsuite/django-workload:cassandra
sleep 10
docker run -tid --name graphite_container --network host cloudsuite/django-workload:graphite
sleep 10
. ./uwsgi.cfg
#docker run -tid --name uwsgi_container --network host -e GRAPHITE_ENDPOINT=$GRAPHITE_ENDPOINT -e CASSANDRA_ENDPOINT=$CASSANDRA_ENDPOINT -e MEMCACHED_ENDPOINT="$MEMCACHED_ENDPOINT" -e SIEGE_ENDPOINT=$SIEGE_ENDPOINT -e UWSGI_ENDPOINT=$UWSGI_ENDPOINT cloudsuite/django-workload:uwsgi
docker run -tid --name uwsgi_container --network host -e GRAPHITE_ENDPOINT=$IP -e CASSANDRA_ENDPOINT=$IP -e MEMCACHED_ENDPOINT="${IP}:11211" -e SIEGE_ENDPOINT=$IP -e UWSGI_ENDPOINT=$IP cloudsuite/django-workload:uwsgi

sleep 10
. ./siege.cfg
docker run -ti --name siege_container --volume=/tmp:/tmp --network host -e TARGET_ENDPOINT=$IP -e SIEGE_WORKERS=$SIEGE_WORKERS cloudsuite/django-workload:siege
sleep 10

