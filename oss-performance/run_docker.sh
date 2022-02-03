#!/bin/bash

# 0. figure out the ip address

# 1. kill existing docker
docker kill siege
docker kill db_server

# 2. run the db_server docker.
docker run -dt --rm --name=db_server --net=host cloudsuite/mysql:mariadb-10.3

# 3. run the siege client
docker run --name=siege --rm -dt --net=host cloudsuite/siege:4.0.3rc3 $LOCAL_IP $LOCAL_IP

sleep 5

# 4. Run the hhvm container

# 4.1 clear the output
echo "" > result.json

# 4.2 setup docker
docker run --net=host --name=fb --rm \
  -v $(pwd)/cmd.batch.sh:/oss-performance/cmd.sh \
  -v $(pwd)/batch.conf.json:/oss-performance/batch.conf.json \
  -v $(pwd)/result.json:/oss-performance/result.json \
  cloudsuite/fb-oss-performance:4.0

