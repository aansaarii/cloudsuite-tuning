#!/bin/bash 

# 95th latency 
docker logs dc-client 2>/dev/null | sed -n -e '/warm/,' | grep -A1 95th | grep -v 95th | awk '{print $10}'
