#!/usr/bin/env python3

import json

base_structure = {
  "runtimes": {
    "Name": {
      "type": "hhvm",
      "bin": "/usr/local/bin/hhvm",
      "args": [
        "--client-threads=20"
      ]
    },
  },
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
      "i-am-not-benchmarking"
    ]
  }
}

import argparse

parser = argparse.ArgumentParser()

parser.add_argument()