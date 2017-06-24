# aemon-ns2
This repository releases the NS2 simulation code (not finely polished) of [Aemon](https://wtao0221.github.io/publication.html), along with the implementation of [Karuna](http://www.cse.ust.hk/~kaichen/papers/karuna-sigcomm16.pdf), [pFabric-EDF](https://people.csail.mit.edu/alizadeh/papers/pfabric-sigcomm13.pdf) and etc.

### Software Requirements

* [NS2 simulator](http://sourceforge.net/projects/nsnam/files/allinone/ns-allinone-2.34/ns-allinone-2.34.tar.gz/download)

### Patch Aemon on NS2

We have tested the released codes on 64-bit Ubuntu 14.04-LTS.

To correctly build NS2 on Ubuntu, you have to install some dependencies and patch the [`aemon.patch`](https://github.com/wtao0221/aemon-ns2/blob/master/aemon.patch), which includes some modifications that make NS2 compilable on Ubuntu.

* To install the necessary dependencies on Ubuntu, run

```
$ sudo apt-get install -y libxmu-dev build-essential build-essential autoconf automake
```

* To patch [`aemon.patch`](https://github.com/wtao0221/aemon-ns2/blob/master/aemon.patch), run

```
$ mkdir workspace
$ cd worksapce
$ tar -xzvf ns-allinone-2.34.tar.gz
$ patch -p1 < aemon.patch
$ cd ./ns-allinone-2.34
$ ./configure
$ ./install
```

Before you run some simulations, please ensure that the `Makefile` in folder `./ns-allinone-2.34/ns-2.34` contains the newly-added `.o` files (i.e. `queue/prioqueue.o` and `queue/edf-queue.o`). If not contained, please add it to the `Makefile` and then remake the NS2.

```
$ make clean
$ make
```

### Reproduce!

The folder `./scripts` contains the trace generator and simulation scripts. 

**NOTE**: before executing any scripts, please remember to change the path of your built `ns` and carefully examine the configuration parameters of each running script. Also, please refer to [Aemon](https://wtao0221.github.io/publication.html) for the details of trace we used.

#### Trace generator

The file `CDF_*.tcl` is the CDF of size distribution of data ming and web search traces. 

To generate traces, run

```
$ chmod +x flow_gen_drive.sh
$ ./flow_gen_drive.sh
```

#### Simulation scripts
To conduct the simulations, just run

```
$ chmod +x drive_all.sh
$ ./drive_all.sh
```

**NOTE**: `run_daed_*.sh`, `run_karuna_*.sh`, `run_pias_*.sh`, `run_pfabric_*.sh` and `run_pfabric_edf_*.sh` stand for Aemon, Karuna, PIAS, pFabric, pFabric-EDF, respectively.

#### Result analysis
After executing simulation successfully, the related folder `[datamining/webserch]_[scheme]_[#queue]_[load]_[ddl load]` is generated.

Inside this foler, the `flow.tr` contains the infos of flow size in nubmer of 1460B-packet, flow duration, deadline in us, number of timeouts and groupid. The `log.tr` contains some running output log. Other `queue_*.tr` files contain the infos for debugging.

For analyzing the result, run

```
$ python result_ana_new.py -i flow.tr -a
```


### Acknowledgements

We thank [Matthew P. Grosvenor](http://www.cl.cam.ac.uk/~mpg39/) for their release of [QJUMP](http://www.cl.cam.ac.uk/research/srg/netos/qjump/), [Wei Bai](http://baiwei0427.github.io/) for [PIAS NS2 implementation](https://github.com/HKUST-SING/PIAS-NS2) and [Li Chen](http://www.cse.ust.hk/~lchenad/) for private conversation about Karuna.

### Contact
If you have any question about Aemon, please feel free to contact [Tao Wang](https://wtao0221.github.io/).

### Citation of this work
Aemon: Information-agnostic Mix-flow Scheduling in Data Center Networks, APNet'17. 