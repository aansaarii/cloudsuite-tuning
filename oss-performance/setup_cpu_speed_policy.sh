#!/bin/bash

# The default value in the scaling_governor for this machine is "schedutil"

for file in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    echo performance > $file
done
