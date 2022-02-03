#!/bin/bash

set -eu

LOCAL_IP=$(ip route get 1.0.0.0 | grep src | cut -d' ' -f7)

echo "The IP address is $LOCAL_IP"

# mysql server ip
MYSQL_IP=$LOCAL_IP
SIEGE_IP=$LOCAL_IP

# Max connections >1000 required for mediawiki workload. If mysql already has max_connections > 1000 comment the below line.
mysql --host=$MYSQL_IP --user=root --password=root -e "SET GLOBAL max_connections = 1001;"

sleep 2

# run hhvm
hhvm perf.php --i-am-not-benchmarking --mediawiki --db-host=$MYSQL_IP --db-username=root --db-password=root --hhvm=$HHVM_BIN --remote-siege=root@$SIEGE_IP --client-threads=10

# run php_cgi7
# hhvm perf.php --i-am-not-benchmarking --mediawiki --db-host=$MYSQL_IP --db-username=root --db-password=root --php5=$PHP_CGI7_BIN --remote-siege=root@$SIEGE_IP

# run php_fpm7
# hhvm perf.php --i-am-not-benchmarking --mediawiki --db-host=$MYSQL_IP --db-username=root --db-password=root --php=$PHP_FPM7_BIN --remote-siege=root@$SIEGE_IP
