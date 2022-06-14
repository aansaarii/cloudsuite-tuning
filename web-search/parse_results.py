import os
import plotly.express as px
import pandas as pd
import plotly.graph_objects as go
from plotly.subplots import make_subplots

rates = []
steady_state = 300

class DataPoint:
  server_cpu_usage: float = 0
  client_cpu_usage: float = 0
  clientss: float = 0
  load: float = 0
  totalOps: float = 0
  avgs: float = 0
  p90th: float = 0
  p99th: float = 0

  def getVal(self, line: str):
    idx_start = line.find(">")+1
    idx_end = line.find("</")
    return line[idx_start:idx_end].strip()

  def parseFromFolder(self, path: str):
    print("\n\n\n")
    with open("{}/client-result.txt".format(path)) as f:
      for l in f:
        if "users" in l:
          self.clients = float(self.getVal(l))
          print("number of clients: {}".format(self.clients))
          rates.append(self.clients / 2.0)
          print("expected load: {} rps".format(rates[-1]))
        if "totalOps" in l:
          self.totalOps = float(self.getVal(l))
          print("number of totalOps: {}".format(self.totalOps))
        if "avg" in l:
          self.avgs = float(self.getVal(l))
          print("Average response time: {}".format(self.avgs))
        if "p90th" in l:
          self.p90th = self.getVal(l)
          if "gt" in self.p90th:
            self.p90th = 2.475
          else:
            self.p90th = float(self.p90th)
          print("90th percentile: {}".format(self.p90th))
        if "p99th" in l:
          self.p99th = self.getVal(l)
          if "gt" in self.p99th:
            self.p99th = 2.475
          else:
            self.p99th = float(self.p99th)
          print("99th percentile: {}".format(self.p99th))

    client_cpu_usages = []
    server_cpu_usages = []
    with open("{}/util.txt".format(path)) as f:
      for l in f:
        if "server" in l:
          line_info = l.split()
          server_cpu_usages.append(float(line_info[2][:-1]))
          #print("the server util is {}".format(server_cpu_usages[-1]))
        if "client" in l:
          line_info = l.split()
          client_cpu_usages.append(float(line_info[2][:-1]))
          #print("the client util is {}".format(client_cpu_usages[-1]))

    print("The client usages: " + str(client_cpu_usages))
    print("The server usages: " + str(server_cpu_usages))
    self.server_cpu_usage=sum(server_cpu_usages)/len(server_cpu_usages)
    self.client_cpu_usage=sum(client_cpu_usages)/len(client_cpu_usages)
    print("server: {}, client: {}".format(self.server_cpu_usage, self.client_cpu_usage))

    return

experiments_folder="results/singlecore_local_qflex"
experiments=[ name for name in os.listdir(experiments_folder) if os.path.isdir(os.path.join(experiments_folder, name)) ]

print(str(experiments))

data: list[(int, DataPoint)] = []

for experiment in experiments:
  data_point = DataPoint()
  data_point.parseFromFolder("{}/{}".format(experiments_folder, experiment))
  data.append([int(experiment), data_point])

print("rates: " + str(rates))

data.sort(key=lambda x: x[0])
df = pd.DataFrame({
  "rates": rates,
  "clients": [ x[1].clients for x in data ],
  "server_cpu_usage": [ x[1].server_cpu_usage for x in data ],
  "client_cpu_usage": [ x[1].client_cpu_usage for x in data ],
  "throughput":       [ x[1].totalOps / steady_state for x in data ],
  "avgs":             [ x[1].avgs             for x in data ],
  "p90th":            [ x[1].p90th            for x in data ],
  "p99th":            [ x[1].p99th            for x in data ]
})

df.to_csv("{}/results.csv".format(experiments_folder), index=False)

fig = make_subplots(2, 3)

fig.add_trace(
  go.Scatter(x=df["clients"], y=df["server_cpu_usage"], mode="markers", showlegend=False),  row=1, col=1
)

fig.update_xaxes(title="Load (clients)", row=1, col=1)
fig.update_yaxes(title="Server CPU Usage (%)", rangemode="tozero", row=1, col=1)

fig.add_trace(
  go.Scatter(x=df["clients"], y=df["client_cpu_usage"], mode="markers", showlegend=False),  row=1, col=2
)

fig.update_xaxes(title="Load (clients)", row=1, col=2)
fig.update_yaxes(title="Client CPU Usage (%)", rangemode="tozero", row=1, col=2)

fig.add_trace(
  go.Scatter(x=df["clients"], y=df["throughput"], mode="markers", showlegend=False),  row=1, col=3
)

fig.update_xaxes(title="Load (clients)", row=1, col=3)
fig.update_yaxes(title="Throughput (rps)", rangemode="tozero", row=1, col=3)

fig.add_trace(
  go.Scatter(x=df["clients"], y=df["avgs"], mode="markers", showlegend=False),  row=2, col=1
)

fig.update_xaxes(title="Load (clients)", row=2, col=1)
fig.update_yaxes(title="Average Latency (s)", rangemode="tozero", row=2, col=1)

fig.add_trace(
  go.Scatter(x=df["clients"], y=df["p90th"], mode="markers", showlegend=False, name="p90th"),  row=2, col=2
)

fig.update_xaxes(title="Load (clients)", row=2, col=2)
fig.update_yaxes(title="90th Percentile (s)", rangemode="tozero", row=2, col=2)

fig.add_trace(
  go.Scatter(x=df["clients"], y=df["p99th"], mode="markers", showlegend=False, name="p99th"),  row=2, col=3
)

fig.update_xaxes(title="Load (clients)", row=2, col=3)
fig.update_yaxes(title="99th Percentile (s)", rangemode="tozero", row=2, col=3)



fig.update_layout(width=1280, height=600)

fig.write_image("{}/fig.jpeg".format(experiments_folder))
