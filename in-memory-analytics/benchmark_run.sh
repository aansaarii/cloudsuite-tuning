#!/bin/bash 

docker create --name data cloudsuite/movielens-dataset 
docker network create spark-net 
docker run -dP --net spark-net --hostname spark-master --name spark-master --cpuset-cpus=0 zilutian/spark master
docker run -dP --net spark-net --volumes-from data --name spark-worker-01 --cpuset-cpus=1 zilutian/spark worker spark://spark-master:7077
