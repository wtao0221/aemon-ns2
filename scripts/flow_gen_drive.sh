#########################################################################
# File Name: flow_gen_drive.sh
# Author: wtao
# mail: tao.wang0221@gmail.com
#########################################################################
#!/bin/bash

initcwnd=70
maxcwnd=240
mean_link_delay=0.0000002
host_delay=0.000020

for type in "dm" "web"; do
	cmd="python ./flow_gen_${type}.py $initcwnd $maxcwnd $mean_link_delay $host_delay &"
	echo $cmd
	eval $cmd
	pids="$pids $!"
done
