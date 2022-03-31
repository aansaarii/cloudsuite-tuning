# You are required to install Docker API Python handler to manipulate the server.

from time import sleep
import docker

# The template for the configuration. Will be loaded from a JSON file.
conf = [
  {
    "RecordCount": 100,
    "ServerCPUs": "1,3,5,7",
    "ClientCPUs": "2,4,6,8",
    # It's all about the client request
    "ClientConf": [
      {
        "Thread": 1,
        "TargetLoad": 1000,
      },
      {
        "Thread": 1,
        "TargetLoad": 1000,
      }
    ]
  }
]


# 1. Start up the server.
d = docker.from_env()

server = d.containers.run(
  "cloudsuite/data-serving:server",
  name = "cassandra-server",
  auto_remove= True,
  cpuset_cpus=conf[0]["ServerCPUs"],
  detach=True,
  privileged=True,
  remove=True,
  stdin_open=True,
  network_mode="host"
)


print("Wait for the server to start up...")
# Wait for the server to fully startup
sleep(15)


# 2. extract the IP from the log. It's always in the second line. 
l = server.logs().decode()
IP = l.split("\n")[1]

# start the client
ycsb = d.containers.run(
  "cloudsuite/data-serving:client",
  "bash",
  name = "cassandra-client",
  auto_remove= True,
  cpuset_cpus=conf[0]["ClientCPUs"],
  detach=True,
  privileged=True,
  remove=True,
  tty=True,
  stdin_open=True,
  network_mode="host"
)


# Run command in the client.
## 1. Load the table
print("Warm up the server")

(ok, out_log) = ycsb.exec_run([
  "cqlsh",
  "-f",
  "/setup_tables.txt",
  IP
])

print(out_log.decode())

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
  "recordcount={}".format(conf[0]["RecordCount"])
])

print(out_log.decode())

## 3. Run the test
(exit_code, out_log) = ycsb.exec_run([
  "/ycsb/bin/ycsb",
  "run",
  "cassandra-cql",
  "-p",
  "hosts={}".format(IP),
  "-P",
  "/ycsb/workloads/workloada",
  "-p",
  "recordcount={}".format(conf[0]["RecordCount"]),
  "-p",
  "operationcount={}".format(conf[0]["RecordCount"] * 100),
  "-threads",
  "10",
  "-target",
  "100000"
])

print(out_log.decode())

server.kill()
ycsb.kill()