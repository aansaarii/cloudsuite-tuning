#!/bin/bash 

docker rm -f hello-world 2>dum

permission=`grep "permission denied" dum | wc -m`

if [ $permission -gt 0 ]; then 
	echo "Found keyword!"
else
	echo "Keyword unfound!"
fi 
