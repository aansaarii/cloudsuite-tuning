#!/usr/bin/env python3

'''
  This file will parse argv[1] and run each configuration inside.
'''

import json
import sys
import os

if len(sys.argv) != 2:
  print("Usage: {} <conf.json>".format(sys.argv[0]))
  exit(0)

if (not os.path.isfile("run.sh")) or (not os.path.isfile("main_func")):
  print("This script relies on the original batching script to finish its job.")
  print("Please make sure the run_batch.py are in the same folder with run.sh and the main_func.")
  exit(0)

with open(sys.argv[1]) as f:
  conf = json.load(f)

for name, conf_body in conf.items():
  print("Running configuration: {}".format(name))
  # 1. create a folder for that result.
  os.mkdir(name)
  # 2. generate configuration.
  with open("user.cfg", "w") as user_cfg:
    user_cfg.write("\n".join([
      "source ../common/requirements",
      "SERVER_CPUS={}".format(",".join(map(str, conf_body["server_cpus"]))),
      "CLIENT_CPUS={}".format(",".join(map(str, conf_body["client_cpus"]))),
      "MEASURE_TIME={}".format(conf_body["measure_time"]),
      "SERVER_NUM={}".format(len(conf_body["server_cpus"])),
      "SERVER_MEM={}".format(conf_body["server_memory"]),
      "WORKER_NUM={}".format(len(conf_body["client_cpus"])),
      "DATASET_SCALE={}".format(conf_body["dataset_scaling_factor"]),
      "RPS_FILE=rps.txt",
      "DEV=1",
      "PLAT=$(get_platform)",
      "if [[ $PLAT = \"x86\" ]]; then ",
      "    source ../common/events_x86",
      "elif [[ $PLAT = \"aarch64\" ]]; then",
      "    source ../common/events_aarch64",
      "else",
      "    echo \"Platform unsupported\"",
      "    exit",
      "fi",
      "PERF_EVENTS=$INST"
    ]))
  # 3. generate rps.txt
  with open("rps.txt", "w") as rps:
    rps.write("\n".join(map(lambda x: str(int(x)), range(*conf_body["load"]["range"]))))
  
  # 4. run the script
  os.system("./run.sh")

  # 5. synthesize data
  os.system("./synthesis.py")

  # 6. move the result to folder
  os.system("mv experiments out data.csv user.cfg rps.txt {}/".format(name))

