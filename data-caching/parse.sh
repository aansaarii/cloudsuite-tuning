#!/bin/bash 

# 95th latency 
cat out/client-result.txt | grep -A1 95th | grep -v 95th | awk '{print $10}'| sed '/^$/d'

# std 
cat out/client-result.txt | grep -A1 95th | grep -v 95th | awk '{print $12}'| sed '/^$/d'
