#!/usr/bin/env python3

import json

base_structure = {
  "targets": [
    "wordpress" 
  ],
  "runtime-overrides": {
  },
  "settings": {
    "username": "root",
    "password": "root",
    "options": [
      "i-am-not-benchmarking",
    ]
  },
  "runtimes": {
    
  },
}

import argparse

parser = argparse.ArgumentParser()

parser.add_argument("-c", nargs=3, type=int, help="Using Python's range to generate number of concurrent clients.")
parser.add_argument("-s", nargs=3, type=int, help="Using Python's range to generate number of server threads.")
parser.add_argument("-se", type=bool, help="Apply 2^N to the range of server threads. With this option, 1,2,3,4 -> 2,4,8,16.")
parser.add_argument("output", help="Generated JSON file for batching run HHVM.", type=argparse.FileType("w"))

args = parser.parse_args()

# 1. checking arguments

client_numbers = list(range(*args.c))
if client_numbers[0] > 1:
    # push 1 client to measure the tail latency
    client_numbers.insert(0, 1)
if args.se:
    server_threads = map(lambda x: 2 ** x, range(*args.s))
else:
    server_threads = range(*args.s)

# generate the json
for sth in server_threads:
    for th in client_numbers:
        base_structure["runtimes"]["{}S{}C".format(sth,th)] = {
            "type": "hhvm",
            "bin": "/usr/local/bin/hhvm",
            "args": [
                "--client-threads={}".format(th),
                "--server-threads={}".format(sth)
            ]
        }

json.dump(base_structure, args.output, indent=4)
