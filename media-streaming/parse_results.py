import os
import plotly.express as px
import pandas as pd
import plotly.graph_objects as go
from plotly.subplots import make_subplots

rates = []

class DataPoint:
  server_cpu_usage: float = 0
  client_cpu_usage: float = 0
  rate: float = 0
  session_rate: float = 0
  bw_util: float = 0
  connected_cons: float = 0

  def parseFromFolder(self, path: str):
    client_cpu_usages = []
    server_cpu_usages = []

    with open("{}/rate.txt".format(path)) as f:
      self.rate = int(f.read())
      rates.append(self.rate)
      print("\n\n\nthe rate is {}".format(self.rate))

    with open("{}/util.txt".format(path)) as f:
      for l in f:
        if "server" in l:
          line_info = l.split()
          server_cpu_usages.append(float(line_info[1][:-1]))
          #print("the server util is {}".format(cpu_usages[-1]))
        if "client" in l:
          line_info = l.split()
          client_cpu_usages.append(float(line_info[1][:-1]))
          #print("the client util is {}".format(cpu_usages[-1]))
    self.server_cpu_usage=sum(server_cpu_usages)/len(server_cpu_usages)
    self.client_cpu_usage=sum(client_cpu_usages)/len(client_cpu_usages)
    print("server: {}, client: {}".format(self.server_cpu_usage, self.client_cpu_usage))

    factor=1
    session_rates = []
    bw_utils = []
    connected_cons = []
    while True:
      factor -= 0.05
      with open("{}/client-result.txt".format(path)) as f:
        steady_state = False

        for l in f:
          if not steady_state:
            if "session-rate" in l:
              line_info = l.split()
              sr = float(line_info[2])
              if sr > self.rate * factor:
                steady_state = True
                #print("steady state at {}".format(sr))
          else:
            if "session-rate" in l:
              line_info = l.split()
              session_rates.append(float(line_info[2]))
            if "Last Period:" in l:
              line_info = l.split()
              bw_utils.append(float(line_info[5]))
              connected_cons.append(float(line_info[11]))

        if steady_state:
          break

    print("factor: {}".format(factor))
    #print("session_rates are: " + str(session_rates))
    self.session_rate = sum(session_rates)/len(session_rates)
    print("average session_rate is: {}".format(self.session_rate))
    #print("bw_utils are: " + str(bw_utils))
    self.bw_util = sum(bw_utils)/len(bw_utils)
    print("average bw_util is: {}".format(self.bw_util))
    #print("coonected_cons are: " + str(connected_cons))
    self.connected_cons = sum(connected_cons)/len(connected_cons)
    print("average connected_cons is: {}".format(self.connected_cons))


experiments_folder="results/singlecore_local/"
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
  "server_cpu_usage": [ x[1].server_cpu_usage for x in data ],
  "client_cpu_usage": [ x[1].client_cpu_usage for x in data ],
  "session_rate":     [ x[1].session_rate     for x in data ],
  "bw_util":          [ x[1].bw_util          for x in data ],
  "connected_cons":   [ x[1].connected_cons   for x in data ]
})

df.to_csv("{}/results.csv".format(experiments_folder), index=False)

fig = make_subplots(2, 3)

fig.add_trace(
  go.Scatter(x=df["rates"], y=df["server_cpu_usage"], mode="markers", showlegend=False),  row=1, col=1
)

fig.update_xaxes(title="Load (sessions/s)", row=1, col=1)
fig.update_yaxes(title="Server CPU Usage (%)", row=1, col=1)

fig.add_trace(
  go.Scatter(x=df["rates"], y=df["client_cpu_usage"], mode="markers", showlegend=False),  row=1, col=2
)

fig.update_xaxes(title="Load (sessions/s)", row=1, col=2)
fig.update_yaxes(title="Client CPU Usage (%)", row=1, col=2)

fig.add_trace(
  go.Scatter(x=df["rates"], y=df["session_rate"], mode="markers", showlegend=False),  row=1, col=3
)

fig.update_xaxes(title="Load (sessions/s)", row=1, col=3)
fig.update_yaxes(title="Throughput (sessions/s)", row=1, col=3)

fig.add_trace(
  go.Scatter(x=df["rates"], y=df["bw_util"], mode="markers", showlegend=False),  row=2, col=1
)

fig.update_xaxes(title="Load (sessions/s)", row=2, col=1)
fig.update_yaxes(title="Bandwidth Utilization (Mbps)", row=2, col=1)

fig.add_trace(
  go.Scatter(x=df["rates"], y=df["connected_cons"], mode="markers", showlegend=False),  row=2, col=2
)

fig.update_xaxes(title="Load (sessions/s)", row=2, col=2)
fig.update_yaxes(title="Simultaneous Connections", row=2, col=2)

fig.update_layout(width=1280, height=600)

fig.write_image("{}/fig.jpeg".format(experiments_folder))







