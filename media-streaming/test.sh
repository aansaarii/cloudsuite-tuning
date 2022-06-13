#!/bin/bash

while true; do
  ss -s
  sysctl fs.file-nr
  sleep 5
done
