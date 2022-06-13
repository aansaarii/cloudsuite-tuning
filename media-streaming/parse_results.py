import os
import plotly.express as px
import pandas as pd
import plotly.graph_objects as go
from plotly.subplots import make_subplots

rates = []
cpu_util_idx = 2

class DataPoint:
  server_cpu_usage: float = 0
  client_cpu_usage: float = 0
  rate: float = 0
  session_rate: float = 0
  bw_util: float = 0
  connected_cons: float = 0
  httperf_client: int = 0
  sessions_failed: int = 0
  sessions_total: int = 0
  errors_total: int = 0
  errors_client_timeout: int = 0
  errors_other: int = 0

  def parseFromFolder(self, path: str):
    with open("{}/user.cfg".format(path)) as f:
      for l in f:
        if "NUM_HTTPERF_CLIENTS=" in l:
          idx = l.find('=')
          self.httperf_clients = int(l[idx+1:].strip())
          print("\n\n\nhttperf clients: {}".format(self.httperf_clients))

    with open("{}/rate.txt".format(path)) as f:
      self.rate = float(f.read())*self.httperf_clients
      rates.append(self.rate)
      print("the rate is {}".format(self.rate))


    client_cpu_usages = []
    server_cpu_usages = []
    with open("{}/util.txt".format(path)) as f:
      for l in f:
        if "server" in l:
          line_info = l.split()
          server_cpu_usages.append(float(line_info[cpu_util_idx][:-1]))
          #print("the server util is {}".format(server_cpu_usages[-1]))
        if "client" in l:
          line_info = l.split()
          client_cpu_usages.append(float(line_info[cpu_util_idx][:-1]))
          #print("the client util is {}".format(client_cpu_usages[-1]))
    self.server_cpu_usage=sum(server_cpu_usages)/len(server_cpu_usages)
    
    if os.path.exists("{}/client_util.txt".format(path)):
      with open("{}/client_util.txt".format(path)) as f:
        for l in f:
          if "client" in l:
            line_info = l.split()
            client_cpu_usages.append(float(line_info[cpu_util_idx][:-1]))
            #print("the client util is {}".format(client_cpu_usages[-1]))
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
              if sr > (self.rate / self.httperf_clients) * factor:
                steady_state = True
                #print("steady state at {}".format(sr))
          else:
            if "session-rate" in l:
              line_info = l.split()
              session_rates.append(float(line_info[2]))
              self.sessions_failed = int(line_info[8])
              self.sessions_total = int(line_info[11])
            if "Last Period:" in l:
              line_info = l.split()
              bw_utils.append(float(line_info[5]))
              connected_cons.append(float(line_info[11]))
            if "Errors: total" in l:
              line_info = l.split()
              self.errors_total = int(line_info[2])
              self.errors_client_timeout = int(line_info[4])
            if "Errors: fd-unavail" in l:
              line_info = l.split()
              self.errors_other = int(line_info[10])

        if steady_state:
          break

    print("factor: {}".format(factor))
    print("session_rates are: " + str(session_rates))
    self.session_rate = sum(session_rates)/len(session_rates)*self.httperf_clients
    print("average session_rate is: {}".format(self.session_rate))
    #print("bw_utils are: " + str(bw_utils))
    self.bw_util = sum(bw_utils)/len(bw_utils)*self.httperf_clients
    print("average bw_util is: {}".format(self.bw_util))
    #print("coonected_cons are: " + str(connected_cons))
    self.connected_cons = sum(connected_cons)/len(connected_cons)*self.httperf_clients
    print("average connected_cons is: {}".format(self.connected_cons))
    print("sessions_failed: {}, sessions_total: {}".format(self.sessions_failed, self.sessions_total))
    print("Errors, total: {}, client_timeout: {}, other: {}".format(self.errors_total, self.errors_client_timeout, self.errors_other))

experiments_folder="results/multicore_local_smt_2cores_portFixed/"
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
  "connected_cons":   [ x[1].connected_cons   for x in data ],
  "failure_rate":     [ 100.0*x[1].sessions_failed/x[1].sessions_total for x in data ],
  "client_timeout_rate": [ 100.0*x[1].errors_client_timeout/x[1].sessions_total for x in data ],
  "other_rate":       [ 100.0*x[1].errors_other/x[1].sessions_total for x in data ]
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



fig.add_trace(
  go.Scatter(x=df["rates"], y=df["client_timeout_rate"], mode="markers", showlegend=True, name="client timeout"),  row=2, col=3
)

fig.add_trace(
  go.Scatter(x=df["rates"], y=df["other_rate"], mode="markers", showlegend=True, name="other"),  row=2, col=3
)

fig.add_trace(
  go.Scatter(x=df["rates"], y=df["failure_rate"], mode="markers", showlegend=True, name="total failure"),  row=2, col=3
)




fig.update_xaxes(title="Load (sessions/s)", row=2, col=3)
fig.update_yaxes(title="Failure rate (%)", row=2, col=3)


fig.update_layout(width=1280, height=600, legend=dict(x=1, y=0.3))

fig.write_image("{}/fig.jpeg".format(experiments_folder))
