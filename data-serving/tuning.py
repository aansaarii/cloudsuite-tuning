# You are required to install Docker API Python handler to manipulate the server.

from time import sleep
import docker

import json

# The template for the configuration. Will be loaded from a JSON file.
conf = {
  "RecordCount": 10000000,
  "ServerCPUs": "0",
  "ClientCPUs": "1,3,5,7,9,11",
  "ClientThreadPerCore": 4,
  # It's all about the client request
  "ClientTargetLoads": [
    200, 400, 600, 800, 1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000, 9000, 10000, 12000, 14000
  ],
  # 1800 second to finish a test.
  "TestTime": 360
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

print("Warm up...")
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
  

core_count = len(conf["ClientCPUs"].split(","))
peakthroughput = -1
results = []

## 3. Run the test
for i, target in enumerate(conf["ClientTargetLoads"]):
  print("Running test {}, and the load is {}.".format(i, target))

  # Running time control.
  op_count = 0
  if peakthroughput == -1:
    op_count = target * conf["TestTime"]
  else:
    op_count = peakthroughput * conf["TestTime"]

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
    "operationcount={}".format(op_count),
    "-threads",
    "{}".format(core_count * conf["ClientThreadPerCore"]),
    "-target",
    "{}".format(target)
  ])

  if exit_code == 0:
    # parse the log and generate the data
    res = {
      "TargetLoad": target
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

    # determine the peak load. In this case, further test will not try more, and time can be saved.
    if res["Overall"]["Throughput(ops/sec)"] < target * 0.7 and res["Overall"]["Throughput(ops/sec)"] > peakthroughput:
      peakthroughput = int(res["Overall"]["Throughput(ops/sec)"])

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
