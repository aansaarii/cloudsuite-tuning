# Plotting Performance Graphs

*  Create some configuration script like `x86_1_core_2MB.cfg` namely `my_config.cfg`,
*  Make sure server machine is available to run commands using `ssh [server address] [command]`,
*  Make sure the server has `sysstat` installed. Our script uses `mpstat` to log the CPU utilization,
*  Run `./data_caching.sh my_config.cfg` and wait for it to finish the experiment,
*  With a `python` version 3 and having `matplotlib` and `numpy` installed run `python plotter.py data_caching output [address to output files named as $EXPERIMENT_ID.txt]`,
*  Or run `python plotter.py data_caching_datailed output.png [address to two output files]`,
*  Find the graph in `output.png` and the data used in `output.csv`.

We have used these tools to plot performance graphs. You can view our graphs in the wiki.

# Adding Other Parsers
To add another parser you can follow the manner used for the parser functions in `parsers.py` file. Actually the synopsis for the plotter is like this:

 ```
 python plotter.py [name of the parser function without the parser_ prefix] [output name] [data file names]
 ```
So you can use your customized or newly written parser to plot graphs. The only thing to consider is to keep the structure of the parser output like the current parsers.

You can change the `qemu_aarch64_1_core_4GB.cfg` file which is downloaded from master to the Qemu base image to change the plotting configurations. 

You can always take a snapshot sending `savevm-ext [snapshot-name]` to mrun process standard input. You can do it by something like this:
```
sudo bash -c 'echo savevm-ext [snapshot-name] > /proc/[mrun pid]/fd/0'
```
