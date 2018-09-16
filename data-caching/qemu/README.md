# Data Caching with Qemu from Scratch
## Prerequisites
Please note that this README assumes you have read and followed [this](https://github.com/parsa-epfl/cloudsuite-tuning/wiki/Qemu) wiki page and now you have hour docker installed ubuntu image.

## Quick start
These scripts are written to automate and also document the procedure of creating Qemu images and snapshots for data caching benchmark. 

Please note that these scripts use `except` to interactively operate Qemu images via serials.

You can read `test-cloud-dc-qemu.sh` and its execpt scripts which it uses to see how to create Qemu images and how to run the workload using `mrun` with multinode and networking setup. 

To run this scripts you can use the following command:

`test-cloud-dc-qemu.sh [qflex directory] [to prepare or not: true/false]`

the prepare option tells the script to whether delete the disc image, extract it from scratch and create data caching or just use the docker installed ubuntu.
