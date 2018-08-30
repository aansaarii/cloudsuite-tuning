# Plotting Performance Graphs

*  Create some configuration script like `x86_4_core_2MB.cfg` namely `my_config.cfg`,
*  Make sure server machine is available to run commands using `ssh [server address] [command]`,
*  Make sure the server has `sysstat` installed. Our script uses `mpstat` to log the CPU utilization,
*  Run `./data_caching.sh my_config.cfg` and wait for it to finish the experiment,
*  With a `python` version 3 and having `matplotlib` installed run `python plotter.py data_caching output.png [address to output file configured in my_config.cfg]`,
*  Find the graph in `output.png`.

We have used these tools to plot performance graphs. You can view our graphs in the wiki.
