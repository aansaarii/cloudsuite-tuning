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
parser.add_argument("output", help="Generated JSON file for batching run HHVM.", type=argparse.FileType("w"))

args = parser.parse_args()

# 1. checking arguments

client_numbers = range(*args.c)
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
