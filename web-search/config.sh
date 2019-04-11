#!/bin/bash 
#
# Author: Zilu Tian 
# April 4, 2019 
#
# Parameters spec for web search benchmark 

SERVER_MEMORY=25g
SOLR_MEM=20g

RAMPTIME=30
STEADYTIME=20
STOPTIME=20

CLIENT_CONTAINER=web_search_client
SERVER_CONTAINER=web_search_server

CLIENT_IMAGE=zilutian/web-search-client:amd64 
SERVER_IMAGE=zilutian/web-search-server:amd64 
NETWORK=search_network
LOCAL_INDEX_VOL=/mnt/scrap/users/ztian/web-search/server/wiki_dump

JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64

OPERATIONS_FILE=$1
LOAD=true
OUTPUTFOLDER=output
UTILFILE=$OUTPUTFOLDER/util.txt
OPERATIONSFILE=$OUTPUTFOLDER/operations.txt
BENCHMARKFILE=$OUTPUTFOLDER/benchmark.txt
ENVIRONMENTFILE=$OUTPUTFOLDER/env.txt
PERFFILE=$OUTPUTFOLDER/perf.txt
SYSTEMFILE=$OUTPUTFOLDER/os-info.txt 

rm -rf $OUTPUTFOLDER
mkdir $OUTPUTFOLDER

# Make sure has the permission to create log directory 
if [ $? -ne 0 ]; then
  echo "Unable to create log directory!"
  exit 1
fi

touch $UTILFILE
touch $OPERATIONSFILE
touch $BENCHMARKFILE
touch $PERFFILE
set > $ENVIRONMENTFILE
cat /etc/os-release > $SYSTEMFILE
lscpu >> $SYSTEMFILE

# Permission check 
docker rm -f $CLIENT_CONTAINER 2>docker_permission_tmp
permission=`grep "permission denied" docker_permission_tmp | wc -m`

if [ $permission -gt 0 ]; then
  echo "Docker doesn't have root permission"
  echo "Consider link: https://docs.docker.com/install/linux/linux-postinstall/"
  exit 1
else
  rm docker_permission_tmp
fi

function image_exists () {
  if [ -z "$(docker images -q $1 2>/dev/null)" ]; then
    echo "Image $1 not found locally!"
    exit 1 
  fi
}

image_exists $CLIENT_IMAGE 
image_exists $SERVER_IMAGE 

if [ ! -f "$LOCAL_INDEX_VOL/wiki_dump.xml" ]; then 
  echo "File wiki_dump.xml not found at the directory $LOCAL_INDEX_VOL"
  exit 1 
fi

