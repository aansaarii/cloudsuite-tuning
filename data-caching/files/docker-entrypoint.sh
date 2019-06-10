#!/bin/bash 

# dataset scale: $1
# worker number: $1 

# echo "args are $1 $2 $3"
# $1: dataset scale factor, $2: number of workers, $3: target rps 
 
/usr/src/memcached/memcached_client/loader \
    -a /usr/src/memcached/twitter_dataset/twitter_dataset_unscaled \
    -o /usr/src/memcached/twitter_dataset/twitter_dataset_{$1}x \
    -s /usr/src/memcached/memcached_client/servers.txt \
    -w $2 -S $2 -D 2048 -j

/usr/src/memcached/memcached_client/loader \
    -a /usr/src/memcached/twitter_dataset/twitter_dataset_{$1}x \
    -s /usr/src/memcached/memcached_client/servers.txt \
    -g 0.8 -c 200 -w $2 -e -r $3 -T 1

