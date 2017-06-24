source "tcp-common-opt-load.tcl"

set ns [new Simulator]
puts "Date: [clock format [clock seconds]]"
set sim_start [clock seconds]

if {$argc != 47} {
    puts "wrong number of arguments $argc"
    exit 0
}

set sim_end [lindex $argv 0]
set link_rate [lindex $argv 1]
set mean_link_delay [lindex $argv 2]
set host_delay [lindex $argv 3]
set queueSize [lindex $argv 4]
set load [lindex $argv 5]
set ddl_load [lindex $argv 6]
set connections_per_pair [lindex $argv 7]
set meanFlowSize [lindex $argv 8]
set paretoShape [lindex $argv 9]
set flow_cdf [lindex $argv 10]

#### Multipath
set enableMultiPath [lindex $argv 11]
set perflowMP [lindex $argv 12]

#### Transport settings options
set sourceAlg [lindex $argv 13] ; # Sack or DCTCP-Sack
set initWindow [lindex $argv 14]
set ackRatio [lindex $argv 15]
set slowstartrestart [lindex $argv 16]
set DCTCP_g [lindex $argv 17] ; # DCTCP alpha estimation gain
set min_rto [lindex $argv 18]
set prob_cap_ [lindex $argv 19] ; # Threshold of consecutive timeouts to trigger probe mode

#### Switch side options
set switchAlg [lindex $argv 20] ; # DropTail (pFabric), RED (DCTCP) or PriorityQueue (DA)
set DCTCP_K [lindex $argv 21]
set drop_prio_ [lindex $argv 22]
set prio_scheme_ [lindex $argv 23]
set deque_prio_ [lindex $argv 24]
set keep_order_ [lindex $argv 25]
set num_queue_ [lindex $argv 26]
set ECN_scheme_ [lindex $argv 27]
set da_thresh_0 [lindex $argv 28]
set da_thresh_1 [lindex $argv 29]
set da_thresh_2 [lindex $argv 30]
set da_thresh_3 [lindex $argv 31]
set da_thresh_4 [lindex $argv 32]
set da_thresh_5 [lindex $argv 33]
set da_thresh_6 [lindex $argv 34]

#### topology
set topology_spt [lindex $argv 35]
set topology_tors [lindex $argv 36]
set topology_spines [lindex $argv 37]
set topology_x [lindex $argv 38]

### result file
set flowlog [open [lindex $argv 39] w]

### Tao: newly added feature
set pf_ddl_en [lindex $argv 40]
set early_detect_ [lindex $argv 41]
set pias_enable_ [lindex $argv 42]
set karuna_enable_ [lindex $argv 43]
set prefix [lindex $argv 44]
set dir_name [lindex $argv 45]
set pf_enable [lindex $argv 46]

#### Packet size is in bytes.
set pktSize 1460
#### trace frequency
set queueSamplingInterval 0.0001
#set queueSamplingInterval 1

puts "Simulation input:"
puts "Dynamic Flow - Pareto"
puts "topology: spines server per rack = $topology_spt, x = $topology_x"
puts "sim_end $sim_end"
puts "link_rate $link_rate Gbps"
puts "link_delay $mean_link_delay sec"
puts "host_delay $host_delay sec"
puts "queue size $queueSize pkts"
puts "load $load"
puts "ddl_load $ddl_load"
puts "connections_per_pair $connections_per_pair"
puts "enableMultiPath=$enableMultiPath, perflowMP=$perflowMP"
puts "source algorithm: $sourceAlg"
puts "TCP initial window: $initWindow"
puts "ackRatio $ackRatio"
puts "DCTCP_g $DCTCP_g"
puts "slow-start Restart $slowstartrestart"
puts "switch algorithm $switchAlg"
puts "DCTCP_K_ $DCTCP_K"
puts "pktSize(payload) $pktSize Bytes"
puts "pktSize(include header) [expr $pktSize + 40] Bytes"

puts " "

################# Transport Options ####################
Agent/TCP set ecn_ 1
Agent/TCP set old_ecn_ 1
Agent/TCP set packetSize_ $pktSize
Agent/TCP/FullTcp set segsize_ $pktSize
Agent/TCP/FullTcp set spa_thresh_ 0
Agent/TCP set window_ 64
Agent/TCP set windowInit_ 2
Agent/TCP set slow_start_restart_ $slowstartrestart
Agent/TCP set windowOption_ 0
Agent/TCP set minrto_ $min_rto
Agent/TCP set tcpTick_ 0.000001
Agent/TCP set maxrto_ 2
Agent/TCP set l2dct_w_min_ 0.125
Agent/TCP set l2dct_w_max_ 2.5
Agent/TCP set l2dct_size_min_ 204800
Agent/TCP set l2dct_size_max_ 1048576

# Agent/TCP/FullTcp set karuna_timeout_thresh_ 2
Agent/TCP/FullTcp set nodelay_ true; # disable Nagle
Agent/TCP/FullTcp set segsperack_ $ackRatio;
Agent/TCP/FullTcp set interval_ 0.000006

if {$ackRatio > 2} {
    Agent/TCP/FullTcp set spa_thresh_ [expr ($ackRatio - 1) * $pktSize]
}

if {[string compare $sourceAlg "DCTCP-Sack"] == 0} {
    Agent/TCP set ecnhat_ true
    Agent/TCPSink set ecnhat_ true
    Agent/TCP set ecnhat_g_ $DCTCP_g
    Agent/TCP set l2dct_enable_ 0

} elseif {[string compare $sourceAlg "L2DCT-Sack"] == 0} {
    Agent/TCP set ecnhat_ true
    Agent/TCPSink set ecnhat_ true
    Agent/TCP set ecnhat_g_ $DCTCP_g;
    Agent/TCP set l2dct_enable_ 1
}

#Shuang
Agent/TCP/FullTcp set prio_scheme_ $prio_scheme_;
Agent/TCP/FullTcp set dynamic_dupack_ 1000000; #disable dupack
Agent/TCP set window_ 1000000
Agent/TCP set windowInit_ $initWindow
Agent/TCP set rtxcur_init_ $min_rto;
Agent/TCP/FullTcp/Sack set clear_on_timeout_ false;
Agent/TCP/FullTcp/Sack set sack_rtx_threshmode_ 2;
Agent/TCP/FullTcp set prob_cap_ $prob_cap_;
#newly added
Agent/TCP/FullTcp set pf_ddl_enable_ $pf_ddl_en;


#Tao
Agent/TCP set prio_enable_ 0
Agent/TCP set pias_enable_ 0
Agent/TCP set karuna_enable_ 0
Agent/TCP set kar_seg_size_ $pktSize
Agent/TCP set early_detect_ $early_detect_
Agent/TCP set num_queue_ 0
Agent/TCP set queue_thresh0 0
Agent/TCP set queue_thresh1 0
Agent/TCP set queue_thresh2 0
Agent/TCP set queue_thresh3 0
Agent/TCP set queue_thresh4 0
Agent/TCP set queue_thresh5 0
Agent/TCP set queue_thresh6 0
# for karuna
Agent/TCP set host_link_rate_ $link_rate
Agent/TCP set k_thresh_ $DCTCP_K

#whether we enable da
if {[string compare $switchAlg "PriorityQueue"] == 0 } {
	if {$pias_enable_ == 0 && $karuna_enable_ == 0} {
		puts "da enabled"
		Agent/TCP set prio_enable_ 1
		Agent/TCP set early_detect_ $early_detect_
	}
	if {$pias_enable_ == 1} {
		puts "pias enabled"
		Agent/TCP set pias_enable_ 1
	}
	if {$karuna_enable_ == 1} {
		puts "karuna enabled"
		Agent/TCP set karuna_enable_ 1
		Agent/TCP set srtt_init_ 85
	}
	Agent/TCP set num_queue_ $num_queue_
	Agent/TCP set queue_thresh0 $da_thresh_0
	Agent/TCP set queue_thresh1 $da_thresh_1
	Agent/TCP set queue_thresh2 $da_thresh_2
	Agent/TCP set queue_thresh3 $da_thresh_3 
	Agent/TCP set queue_thresh4 $da_thresh_4 
	Agent/TCP set queue_thresh5 $da_thresh_5 
	Agent/TCP set queue_thresh6 $da_thresh_6 
}

if {$queueSize > $initWindow } {
    Agent/TCP set maxcwnd_ [expr $queueSize - 1];
} else {
    Agent/TCP set maxcwnd_ $initWindow
}

if {$pf_enable == 1} {
	set myAgent "Agent/TCP/FullTcp/Sack/MinTCP";
} else {
	set myAgent "Agent/TCP/FullTcp/Sack";
}

################# Switch Options ######################
Queue set limit_ $queueSize

Queue/DropTail set queue_in_bytes_ true
Queue/DropTail set mean_pktsize_ [expr $pktSize+40]
Queue/DropTail set drop_prio_ $drop_prio_
Queue/DropTail set deque_prio_ $deque_prio_
Queue/DropTail set keep_order_ $keep_order_

Queue/EDFQueue set queue_in_bytes_ true
Queue/EDFQueue set mean_pktsize_ [expr $pktSize+40]
Queue/EDFQueue set drop_prio_ $drop_prio_
Queue/EDFQueue set deque_prio_ $deque_prio_
Queue/EDFQueue set keep_order_ $keep_order_
Queue/EDFQueue set drop_smart_ false
Queue/EDFQueue set drop_front_ false
Queue/EDFQueue set sq_limit_ 0
Queue/EDFQueue set summarystats_ false

Queue/RED set bytes_ false
Queue/RED set queue_in_bytes_ true
Queue/RED set mean_pktsize_ [expr $pktSize+40]
Queue/RED set setbit_ true
Queue/RED set gentle_ false
Queue/RED set q_weight_ 1.0
Queue/RED set mark_p_ 1.0
Queue/RED set thresh_ $DCTCP_K
Queue/RED set maxthresh_ $DCTCP_K
Queue/RED set drop_prio_ $drop_prio_
Queue/RED set deque_prio_ $deque_prio_

Queue/PriorityQueue set num_queue_ $num_queue_
# the ecn_thresh_ may be different at the uplinks?
Queue/PriorityQueue set ecn_thresh_ $DCTCP_K
Queue/PriorityQueue set mean_pktsize_ [expr $pktSize+40]
Queue/PriorityQueue set ecn_scheme_ $ECN_scheme_
#Queue/PriorityQueue set que_perc_0 0
#Queue/PriorityQueue set que_perc_1 0
#Queue/PriorityQueue set que_perc_2 0
#Queue/PriorityQueue set que_perc_3 0
#Queue/PriorityQueue set que_perc_4 0
#Queue/PriorityQueue set que_perc_5 0
#Queue/PriorityQueue set que_perc_6 0
#Queue/PriorityQueue set que_perc_7 0

############## Multipathing ###########################
if {$enableMultiPath == 1} {
    $ns rtproto DV
    Agent/rtProto/DV set advertInterval	[expr 2*$sim_end]
    Node set multiPath_ 1
    if {$perflowMP != 0} {
        Classifier/MultiPath set perflow_ 1
        Agent/TCP/FullTcp set dynamic_dupack_ 0; # enable duplicate ACK
    }
}

############# Topoplgy #########################
set S [expr $topology_spt * $topology_tors] ; #number of servers
set UCap [expr $link_rate * $topology_spt / $topology_spines / $topology_x] ; #uplink rate

puts "UCap: $UCap"

for {set i 0} {$i < $S} {incr i} {
    set s($i) [$ns node]
}

for {set i 0} {$i < $topology_tors} {incr i} {
    set n($i) [$ns node]
}

for {set i 0} {$i < $topology_spines} {incr i} {
    set a($i) [$ns node]
}

############ Edge links ##############
for {set i 0} {$i < $S} {incr i} {
    set j [expr $i/$topology_spt]
    $ns duplex-link $s($i) $n($j) [set link_rate]Gb [expr $host_delay + $mean_link_delay] $switchAlg 
	set hl($i,$j) [[$ns link $s($i) $n($j)] queue]
	set log_hl($i,$j) [open $dir_name\/queue_h$i\_l$j.tr w]
	set lh($j,$i) [[$ns link $n($j) $s($i)] queue]
	set log_lh($j,$i) [open $dir_name\/queue_l$j\_h$i.tr w]
	#$sn($i,$j) trace que_perc_0
	$hl($i,$j) attach $log_hl($i,$j)
	$lh($j,$i) attach $log_lh($j,$i)
}

### update switch option ###
Queue set limit_ [expr $queueSize * $topology_spt / $topology_spines / $topology_x]

Queue/RED set thresh_ [expr $DCTCP_K * $topology_spt / $topology_spines / $topology_x]
Queue/RED set maxthresh_ [expr $DCTCP_K * $topology_spt / $topology_spines / $topology_x]

Queue/PriorityQueue set ecn_thresh_ [expr $DCTCP_K * $topology_spt / $topology_spines / $topology_x]

############ Core links ##############
for {set i 0} {$i < $topology_tors} {incr i} {
    for {set j 0} {$j < $topology_spines} {incr j} {
        $ns duplex-link $n($i) $a($j) [set UCap]Gb $mean_link_delay $switchAlg
		set ls($i,$j) [[$ns link $n($i) $a($j)] queue]
		set log_ls($i,$j) [open $dir_name\/queue_l$i\_s$j.tr w]
		set sl($j,$i) [[$ns link $a($j) $n($i)] queue]
		set log_sl($j,$i) [open $dir_name\/queue_s$j\_l$i.tr w]
		#$sn($i,$j) trace que_perc_0
		$ls($i,$j) attach $log_ls($i,$j)
		$sl($j,$i) attach $log_sl($j,$i)
    }
}

#############  Agents ################
set lambda [expr ($link_rate*$load*1000000000)/($meanFlowSize*8.0/1460*1500)]
#set lambda [expr ($link_rate*$load*1000000000)/($mean_npkts*($pktSize+40)*8.0)]
#Poisson distribution with inter-arrival exponential distribution with lambda = 1/$lambda
puts "Arrival: Poisson with inter-arrival [expr 1/$lambda * 1000] ms"
puts "FlowSize: Pareto with mean = $meanFlowSize, shape = $paretoShape"

puts "Setting up connections ..."; flush stdout

set flow_gen 0
set flow_fin 0
set ddl_flow_start 0
set ddl_flow_fin 0
set nonddl_flow_start 0
set nonddl_flow_fin 0

set init_fid 0
for {set j 0} {$j < $S } {incr j} {
    for {set i 0} {$i < $S } {incr i} {
        if {$i != $j} {
			set fpname [concat $prefix/new-$i-$j]
			puts "load trace file name: $fpname"
			set trlog($i,$j) [open $fpname r]
			set tr_data($i,$j) [split [read $trlog($i,$j)] "\n"]
			close $trlog($i,$j)

            set agtagr($i,$j) [new Agent_Aggr_pair]
            $agtagr($i,$j) setup $s($i) $s($j) "$i $j" $connections_per_pair $init_fid "TCP_pair"
            $agtagr($i,$j) attach-logfile $flowlog
			$agtagr($i,$j) attach-tracefile $tr_data($i,$j)
			# Tao we read trace file here
			$agtagr($i,$j) init_schedule

            puts -nonewline "($i,$j) "
            #For Poisson/Pareto

            $ns at 0.1 "$agtagr($i,$j) warmup 0.5 5"
			#$ns at 1 "$agtagr($i,$j) init_schedule"

            set init_fid [expr $init_fid + $connections_per_pair];
        }
    }
}

$ns at 1 "prstats"

puts "Initial agent creation done";flush stdout
puts "Simulation started!"

proc prstats {} {
	global ns
	global S topology_spt topology_tors topology_spines
	global hl lh ls sl

	set now [$ns now]
	for {set i 0} {$i < $S} {incr i} {
		set j [expr $i/$topology_spt]
		$hl($i,$j) printStats
		$lh($j,$i) printStats
	}
	
	for {set i 0} {$i < $topology_tors} {incr i} {
		for {set j 0} {$j < $topology_spines} {incr j} {
			$ls($i,$j) printStats
			$sl($j,$i) printStats
		}
	}
	$ns at [expr $now+0.05] "prstats"
}


$ns run
