# Running and collecting data

1.  Build and run the index image as described in the docs [here](https://github.com/parsa-epfl/cloudsuite/blob/web-search-update/docs/benchmarks/web-search.md)
2.  Build the web-search server and client images. By default the script assumes the following names:
  * Server Image = web_search_server
  * Client Image = web_search_client
  * Index Container = index
3. Create a text file which contains the list of loads (threads). For eg, if you want to generate load from 10 to 1000 at a step of 10, use
``` 
seq 10 10 1000 > load.txt
```
The same number can be repeated multiple times in the text file. At the plotting phase these can be used to calculate the mean and the variance to get more stable results. 
4. Run benchmark_run.sh with the load file as the argument
```
./benchmark_run.sh load.txt
```


## Some import notes
1. There are multiple parameters which can be changed in the script itself (cores to be used by server, client, ramp up time, steady state time, etc). Please adjust those values before running the script. These include 
- CLIENT_CPUS 
- SERVER_CPUS
- SERVER_MEMORY
- SOLR_MEM
- RAMPTIME
- STEADYTIME
- STOPTIME
- CLIENT_CONTAINER
- SERVER_CONTAINER
- CLIENT_IMAGE
- SERVER_IMAGE
- NETWORK
- INDEX_CONTAINER
- OUTPUTFOLDER

2. For getting the output from perf and mpstat, we run the commands when the steady state starts and stop them when the steady state ends (which is checked every 1 second). 
The following lines start the monitoring:
```
mpstat -P ALL 1 >> $UTILFILE &	    
sudo perf stat -e instructions:u,instructions:k,cycles --cpu $SERVER_CPUS sleep infinity 2>>$PERFFILE &
```
 and the following lines end it. :
```
pkill mpstat
sudo perf stat pkill -fx "sleep infinity"
```

These command might need to be changed depending on the permissions available to the user. (They may or may not require sudo). In case sudo is used, the command "sleep infinity" is also run as root and killing it requires root excess. Be careful!

# Plotting
Refer to the notebook dataReadAndPlot.ipynb. 


**Note**: The script might not work if the output files are not in the correct format. This can happen if the script is run on different machines and the perf/mpstat output is in a different format. The functions readCPUUtil() and readPerf() in the notebook might require some minor adjustments in that case. 
