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

4. Run benchmark_run.sh with the load file as the argument
```
./benchmark_run.sh load.txt
```

**Note**: There are multiple parameters which can be changed in the script itself (cores to be used by server, client, ramp up time, steady state time, etc). Please adjust those values before running the script.

# Plotting
Refer to the notebook dataReadAndPlot.ipynb. 


**Note**: The script might not work if the output files are not in the correct format. This can happen if the script is run on different machines and the perf/mpstat output is in a different format. The functions readCPUUtil() and readPerf() in the notebook might require some minor adjustments in that case. 
