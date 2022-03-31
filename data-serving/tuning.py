# You are required to install Docker API Python handler to manipulate the server.

from time import sleep
import docker

import json

# The template for the configuration. Will be loaded from a JSON file.
conf = {
  "RecordCount": 1000,
  "ServerCPUs": "0",
  "ClientCPUs": "1,3,5,7,9,11",
  # It's all about the client request
  "ClientConf": [
    {
      "ThreadNumber": 1,
      "TargetLoad": 200,
    },
    {
      "ThreadNumber": 1,
      "TargetLoad": 400,
    },
    {
      "ThreadNumber": 1,
      "TargetLoad": 600,
    },
    {
      "ThreadNumber": 1,
      "TargetLoad": 800,
    },
    {
      "ThreadNumber": 1,
      "TargetLoad": 1000,
    },
    {
      "ThreadNumber": 1,
      "TargetLoad": 2000,
    },
    {
      "ThreadNumber": 1,
      "TargetLoad": 3000,
    },
    {
      "ThreadNumber": 1,
      "TargetLoad": 4000,
    },
    {
      "ThreadNumber": 1,
      "TargetLoad": 5000,
    },
    {
      "ThreadNumber": 1,
      "TargetLoad": 6000,
    },
  ]
}

# 1. Start up the server.
d = docker.from_env()

server = d.containers.run(
  "cloudsuite/data-serving:server",
  name = "cassandra-server",
  auto_remove= True,
  cpuset_cpus=conf["ServerCPUs"],
  detach=True,
  privileged=True,
  remove=True,
  stdin_open=True,
  network_mode="host"
)

print("Wait for the server to start up...")
# Wait for the server to fully startup
import socket
def is_port_in_use(port: int) -> bool:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        return s.connect_ex(('localhost', port)) == 0

while not is_port_in_use(9042):
    sleep(1)

# 2. extract the IP from the log. It's always in the second line. 
l = server.logs().decode()
IP = l.split("\n")[1]

# start the client
ycsb = d.containers.run(
  "cloudsuite/data-serving:client",
  "bash",
  name = "cassandra-client",
  auto_remove= True,
  cpuset_cpus=conf["ClientCPUs"],
  detach=True,
  privileged=True,
  remove=True,
  tty=True,
  stdin_open=True,
  network_mode="host"
)


# Run command in the client.
## 1. Load the table
print("Generate Table in Server")

(ok, out_log) = ycsb.exec_run([
  "cqlsh",
  "-f",
  "/setup_tables.txt",
  IP
])

if ok != 0:
  print(out_log.decode())
  server.kill()
  ycsb.kill()
  print("Error!")
  exit(-1)

print("Warn up...")
## 2. Warm up
(ok, out_log) = ycsb.exec_run([
  "/ycsb/bin/ycsb",
  "load",
  "cassandra-cql",
  "-p",
  "hosts={}".format(IP),
  "-P",
  "/ycsb/workloads/workloada",
  "-p",
  "recordcount={}".format(conf["RecordCount"])
])

if ok != 0:
  print(out_log.decode())
  server.kill()
  ycsb.kill()
  print("Error!")
  exit(-1)
  

results = []

## 3. Run the test
for i, test in enumerate(conf["ClientConf"]):
  print("Running test {}".format(i))
  (exit_code, out_log) = ycsb.exec_run([
    "/ycsb/bin/ycsb",
    "run",
    "cassandra-cql",
    "-p",
    "hosts={}".format(IP),
    "-P",
    "/ycsb/workloads/workloada",
    "-p",
    "recordcount={}".format(conf["RecordCount"]),
    "-p",
    "operationcount={}".format(conf["RecordCount"] * 100),
    "-threads",
    "{}".format(test["ThreadNumber"]),
    "-target",
    "{}".format(test["TargetLoad"])
  ])

  if exit_code == 0:
    # parse the log and generate the data
    res = {
      "ThreadNumber": test["ThreadNumber"],
      "TargetLoad": test["TargetLoad"]
    }
    # it's time to parse the log
    for line in out_log.decode().split("\n"):
      if line.startswith("["):
        # 1. get the tag
        tag = ""
        if "[OVERALL]" in line:
          tag = "Overall"
        elif "[READ]" in line:
          tag = "Read"
        elif "[CLEANUP]" in line:
          tag = "Cleanup"
        elif "[UPDATE]" in line:
          tag = "Update"
        
        if len(tag) == 0:
          continue

        if not (tag in res.keys()):
          res[tag] = {}

        terms = line.split(", ")
        if len(terms) != 3:
          print("Warning: cannot parse {}.".format(line))
        if "Return" in terms[1]:
          res[tag]["Return"] = terms[1].split("=")[1]
        else:
          res[tag][terms[1]] = float(terms[2])
    results.append(res)
  else:
    print(out_log.decode())
    server.kill()
    ycsb.kill()
    print("Error!")
    exit(-1)

server.kill()
ycsb.kill()
with open("result.json", "w") as o:
  json.dump(results, o, indent=4, sort_keys=True)
