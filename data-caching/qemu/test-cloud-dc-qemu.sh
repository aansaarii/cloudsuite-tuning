#!/bin/bash

set -e

QFLEX_DIR=$1
PREPARE=$2

INITIAL_DIRECTORY=`pwd`

if $PREPARE; then
	cd $QFLEX_DIR/images/ubuntu-16.04-blank/
	rm -f ubuntu-16.04-lts-blank.qcow2
	echo 'Extracting original ubuntu image ...'
	bzip2 -dk ubuntu-16.04-lts-blank.qcow2.bz2
	cd $INITIAL_DIRECTORY

	cd $QFLEX_DIR/scripts
	expect prepare.expect
	cd $INITIAL_DIRECTORY
fi

cd $QFLEX_DIR/scripts/mrun
echo 'Running mrun ...'
sudo ip link delete tap-inet-ns || true
sudo ip link delete tap-0 || true
sudo ip link delete tap-1 || true
sudo ip link delete tap-0-ns || true
sudo ip link delete tap-1-ns || true
sudo bash -c "echo 0 > /proc/sys/net/bridge/bridge-nf-call-iptables"
while true; do echo ''; sleep 1; done | sudo ./mrun -r qemu-setup-sample-file.xml -qmp -ns /home/aasgari/Documents/qflex/3rdparty/ns3 &
MRUN_PID=$!
sleep 20
cd $INITIAL_DIRECTORY

expect server.expect
expect client.expect

sudo bash -c "echo 'kill' >> /proc/$MRUN_PID/fd/0"
while sudo ps | grep -q "$MRUN_PID"; do echo Waiting for mrun to stop ...; sleep 5; done
