#!/bin/bash

WEB_SERVER_IP=$1
LOAD_SCALE=${2:-7}
RAMPUP=$3
STEADYSTATE=$4
RAMPDOWN=$5

echo "Load scale is ${LOAD_SCALE}"

while [ "$(curl -sSI ${WEB_SERVER_IP}:8080 | grep 'HTTP/1.1' | awk '{print $2}')" != "200" ]; do
  sleep 1
done

sed -i "s@<javaHome>.*@<javaHome>$JAVA_HOME<\\/javaHome>@" /web20_benchmark/deploy/run.xml
sed -i "s/num_users=[0-9]*$/num_users=${LOAD_SCALE}/" $FABAN_HOME/usersetup.properties

$FABAN_HOME/master/bin/startup.sh
cd /web20_benchmark/build && java -jar Usergen.jar http://${WEB_SERVER_IP}:8080
sed -i "s/<fa:scale.*/<fa:scale>${LOAD_SCALE}<\\/fa:scale>/" /web20_benchmark/deploy/run.xml
sed -i "s/<fa:rampUp.*/<fa:rampUp>${RAMPUP}<\\/fa:rampUp>/" /web20_benchmark/deploy/run.xml
sed -i "s/<fa:rampDown.*/<fa:rampDown>${RAMPDOWN}<\\/fa:rampDown>/" /web20_benchmark/deploy/run.xml
sed -i "s/<fa:steadyState.*/<fa:steadyState>${STEADYSTATE}<\\/fa:steadyState>/" /web20_benchmark/deploy/run.xml
sed -i "s/<host.*/<host>${WEB_SERVER_IP}<\\/host>/" /web20_benchmark/deploy/run.xml
sed -i "s/<port.*/<port>8080<\\/port>/" /web20_benchmark/deploy/run.xml
sed -i "s@<outputDir.*@<outputDir>${FABAN_HOME}\/output<\\/outputDir>@" /web20_benchmark/deploy/run.xml
cd /web20_benchmark && ant run
cat $FABAN_HOME/output/*/summary.xml
