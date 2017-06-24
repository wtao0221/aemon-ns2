#########################################################################
# File Name: drive_all.sh
# Author: wtao
# mail: tao.wang0221@gmail.com
#########################################################################
#!/bin/bash

sim_end=100000
mean_link_delay=0.0000002
host_delay=0.000020
queueSize=140
init_wnd=70
min_rto=0.000250
DCTCP_K=65
queue_thresh_ind=0

for CDF in "vl2"; do
	for scheme in "pfabric_edf"; do

		if [ "$scheme" == "pfabric_edf" ]; then con_per_pair=1; fi

		for load_arr in "0.9"; do
			for ddl_load_arr in "0.9" "0.85" "0.8" "0.75"; do
				for num_queue in "1"; do
					for prio_scheme in "2"; do
						if [ "$scheme" == "pfabric" ];
						then
							if [ $num_queue -ne 1 ]; then continue; fi
						fi

						cmd="python ./run_${scheme}_${CDF}.py $sim_end $mean_link_delay $host_delay $queueSize $load_arr $ddl_load_arr $con_per_pair $init_wnd $min_rto $DCTCP_K $num_queue $queue_thresh_ind $prio_scheme &"
						echo $cmd
						eval $cmd
						pids="$pids $!"
					done
				done
			done
		done
	done
done

#for pid in pids; do
#	echo "Waiting for $pid"
#	wait $pid
#done

