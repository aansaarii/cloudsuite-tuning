#!/usr/bin/env python3
import os
import re

class DataPoint:
  throughput: float = 0
  latency_95th: float = 0
  latency_99th: float = 0
  cpu_usage: float = 0
  def parseFromFoler(self, path: str):
    # 1. parse the client-result.txt file
    rps = []
    t95 = []
    t99 = []
    is_data = False
    with open("{}/client-result.txt".format(path)) as f:
      for l in f:
        if l.strip().startswith("timeDiff"):
          is_data = True
          continue
        if is_data:
          is_data = False
          line_info = re.split(r',\s+', l.strip())
          if len(line_info) < 11:
            continue
          #print(line_info)
          if float(line_info[0]) > 10: # non stable point, ignored.
            continue
          rps.append(float(line_info[1]))
          t95.append(float(line_info[9]))
          t99.append(float(line_info[10]))
    
    self.throughput = sum(rps) / len(rps)
    self.latency_95th = sum(t95) / len(t95)
    self.latency_99th = sum(t99) / len(t99)

    # 2. parse util.txt to get CPU usage.
    cpu_usages = []
    with open("{}/util.txt".format(path)) as f:
      for l in f:
        if "dc-server" in l:
          line_info = l.split()
          cpu_usages.append(float(line_info[2][:-2]))

    self.cpu_usage = sum(cpu_usages) / len(cpu_usages)


# go over the folder
files = os.listdir("experiments")

data: list[(int, DataPoint)] = []
for folder in files:
  data_point = DataPoint()
  data_point.parseFromFoler("experiments/{}".format(folder))
  data.append([int(folder), data_point])



load = []
with open("rps.txt") as f:
  load = list(map(int, f.read().split()))


import pandas as pd

data.sort(key=lambda x: x[0])
df = pd.DataFrame({
  "load": [load[x[0] - 1] for x in data],
  "throughput": [x[1].throughput for x in data],
  "latency": [x[1].latency_99th for x in data],
  "cpu_usage": [x[1].cpu_usage for x in data]
})
df.to_csv("data.csv", index=False)


