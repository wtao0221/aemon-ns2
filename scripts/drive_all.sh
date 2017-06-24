#########################################################################
# File Name: drive_all.sh
# Author: wtao
# mail: tao.wang0221@gmail.com
#########################################################################
#!/bin/bash

sim_end=100000
mean_link_delay=0.0000002
host_delay=0.000020
queueSize=240
init_wnd=70
min_rto=0.002
DCTCP_K=65

for CDF in "vl2"; do
	for scheme in "karuna" "pias" "da" "daed" "dctcp"; do

		if [ "$scheme" == "tcp" ]; then con_per_pair=8; fi
		if [ "$scheme" == "dctcp" ]; then con_per_pair=8; fi
		if [ "$scheme" == "karuna" ]; then con_per_pair=8; fi
		if [ "$scheme" == "pias" ]; then con_per_pair=8; fi
		if [ "$scheme" == "lldct" ]; then con_per_pair=1; fi
		if [ "$scheme" == "da" ]; then con_per_pair=8; fi
		if [ "$scheme" == "daed" ]; then con_per_pair=8; fi

		for load_arr in "0.9"; do
			queue_thresh_ind=0
			for ddl_load_arr in "0.85"; do
				for num_queue in "1" "8"; do
					if [ "$scheme" == "lldct" ] || [ "$scheme" == "tcp" ] || [ "$scheme" == "dctcp" ];
					then
						if [ $num_queue -ne 1 ]; then continue; fi
					fi
					if [ "$scheme" == "karuna" ] || [ "$scheme" == "pias" ] || [ "$scheme" == "da" ] || [ "$scheme" == "daed" ];
					then
						if [ $num_queue -eq 1 ]; then continue; fi
					fi

					cmd="python ./run_${scheme}_${CDF}.py $sim_end $mean_link_delay $host_delay $queueSize $load_arr $ddl_load_arr $con_per_pair $init_wnd $min_rto $DCTCP_K $num_queue $queue_thresh_ind &"
					echo $cmd
					eval $cmd
					pids="$pids $!"
					
				done
			done
			queue_thresh_ind=$(($queue_thresh_ind+1))
		done
	done
done

#for pid in pids; do
#	echo "Waiting for $pid"
#	wait $pid
#done

