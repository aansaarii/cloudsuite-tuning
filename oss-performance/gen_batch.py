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
      "cpu-fraction=0.5",
      "i-am-not-benchmarking",
      "server-threads=4"
    ]
  },
  "runtimes": {
    
  },
}

import argparse

parser = argparse.ArgumentParser()

parser.add_argument("-r", nargs=3, type=int, help="Range. Using Python's range to generate number of client threads.")
parser.add_argument("-f", type=argparse.FileType("r"), help="File contains the number of client threads.")
parser.add_argument("output", help="Generated JSON file for batching run HHVM.", type=argparse.FileType("w"))

args = parser.parse_args()

# 1. checking arguments

if args.r is None and args.f is None:
  print("You should either use -r or -f to provide thread numbers.")
  exit(0)

client_numbers= []

if args.r is None:
  for l in args.f:
    client_numbers.append(int(l))
else:
  client_numbers = range(*args.r)

# generate the json
for th in client_numbers:
  base_structure["runtimes"]["{}C".format(th)] = {
    "type": "hhvm",
    "bin": "/usr/local/bin/hhvm",
    "args": [
      "--client-threads={}".format(th)
    ]
  }

json.dump(base_structure, args.output, indent=4)