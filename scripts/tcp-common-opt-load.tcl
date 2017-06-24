#
# TCP pair's have
# - group_id = "src->dst"
# - pair_id = index of connection among the group
# - fid = unique flow identifier for this connection (group_id, pair_id)
#
set next_fid 0

Class TCP_pair

#Variables:
#tcps tcpr:  Sender TCP, Receiver TCP
#sn   dn  :  source/dest node which TCP sender/receiver exist
#:  (only for setup_wnode)
#delay    :  delay between sn and san (dn and dan)
#:  (only for setup_wnode)
#san  dan :  nodes to which sn/dn are attached
#aggr_ctrl:  Agent_Aggr_pair for callback
#start_cbfunc:  callback at start
#fin_cbfunc:  callback at fin
#group_id :  group id
#pair_id  :  pair id
#fid       :  flow id
#deadline_	:	deadline in us
#Public Functions:
#setup{snode dnode}       <- either of them
#setup_wnode{snode dnode} <- must be called
#setgid {gid}             <- if applicable (default 0)
#setpairid {pid}          <- if applicable (default 0)
#setfid {fid}             <- if applicable (default 0)

#Tao: deadline
#setdeadline {ddl}

#start { nr_bytes } ;# let start sending nr_bytes
#set_debug_mode { mode }    ;# change to debug_mode
#setcallback { controller } #; only Agent_Aggr_pair uses to
##; registor itself
#fin_notify {}  #; Callback .. this is called
##; by agent when it finished
#Private Function
#flow_finished {} {

TCP_pair instproc init {args} {
    $self instvar pair_id group_id id debug_mode rttimes
    $self instvar tcps tcpr;# Sender TCP,  Receiver TCP
	$self instvar deadline_
    global myAgent
    eval $self next $args

    $self set tcps [new $myAgent]  ;# Sender TCP
    $self set tcpr [new $myAgent]  ;# Receiver TCP

    $tcps set_callback $self
#$tcpr set_callback $self

    $self set pair_id  0
    $self set group_id 0
    $self set id       0
    $self set debug_mode 0
    $self set rttimes 0

	$self set deadline_ 0
}

TCP_pair instproc set_debug_mode { mode } {
    $self instvar debug_mode
    $self set debug_mode $mode
}


TCP_pair instproc setup {snode dnode} {
#Directly connect agents to snode, dnode.
#For faster simulation.
    global ns link_rate
    $self instvar tcps tcpr;# Sender TCP,  Receiver TCP
    $self instvar san dan  ;# memorize dumbell node (to attach)

    $self set san $snode
    $self set dan $dnode

    $ns attach-agent $snode $tcps;
    $ns attach-agent $dnode $tcpr;

    $tcpr listen
    $ns connect $tcps $tcpr
}

TCP_pair instproc create_agent {} {
    $self instvar tcps tcpr;# Sender TCP,  Receiver TCP
    $self set tcps [new Agent/TCP/FullTcp/Sack]  ;# Sender TCP
    $self set tcpr [new Agent/TCP/FullTcp/Sack]  ;# Receiver TCP
}

TCP_pair instproc setup_wnode {snode dnode link_dly} {

#New nodes are allocated for sender/receiver agents.
#They are connected to snode/dnode with link having delay of link_dly.
#Caution: If the number of pairs is large, simulation gets way too slow,
#and memory consumption gets very very large..
#Use "setup" if possible in such cases.

    global ns link_rate
    $self instvar sn dn    ;# Source Node, Dest Node
    $self instvar tcps tcpr;# Sender TCP,  Receiver TCP
    $self instvar san dan  ;# memorize dumbell node (to attach)
    $self instvar delay    ;# local link delay

    $self set delay link_dly

    $self set sn [$ns node]
    $self set dn [$ns node]

    $self set san $snode
    $self set dan $dnode

    $ns duplex-link $snode $sn  [set link_rate]Gb $delay  DropTail
    $ns duplex-link $dn $dnode  [set link_rate]Gb $delay  DropTail

    $ns attach-agent $sn $tcps;
    $ns attach-agent $dn $tcpr;

    $tcpr listen
    $ns connect $tcps $tcpr
}

TCP_pair instproc set_fincallback { controller func} {
    $self instvar aggr_ctrl fin_cbfunc
    $self set aggr_ctrl  $controller
    $self set fin_cbfunc  $func
}

TCP_pair instproc set_startcallback { controller func} {
    $self instvar aggr_ctrl start_cbfunc
    $self set aggr_ctrl $controller
    $self set start_cbfunc $func
}

TCP_pair instproc setgid { gid } {
    $self instvar group_id
    $self set group_id $gid
}

TCP_pair instproc setpairid { pid } {
    $self instvar pair_id
    $self set pair_id $pid
}

TCP_pair instproc setfid { fid } {
    $self instvar tcps tcpr
	#Tao: flow id
    $self instvar id
    $self set id $fid
    $tcps set fid_ $fid;
    $tcpr set fid_ $fid;
}

TCP_pair instproc setdeadline { ddl } {
	$self instvar deadline_
	$self set deadline_ $ddl
}

TCP_pair instproc settbf { tbf } {
    global ns
    $self instvar tcps tcpr
    $self instvar san
    $self instvar tbfs

    $self set tbfs $tbf
    $ns attach-tbf-agent $san $tcps $tbf
}


TCP_pair instproc set_debug_mode { mode } {
    $self instvar debug_mode
    $self set debug_mode $mode
}
TCP_pair instproc start { nr_bytes } {
    global ns sim_end flow_gen
	global ddl_flow_start nonddl_flow_start
    $self instvar tcps tcpr id group_id
    $self instvar start_time bytes
    $self instvar aggr_ctrl start_cbfunc
	# Tao: deadline
	$self instvar deadline_

    $self instvar debug_mode

    $self set start_time [$ns now] ;# memorize
    #$self set start_time $st_time ;# memorize
    $self set bytes       $nr_bytes  ;# memorize

    if {$flow_gen >= $sim_end} {
		return
    }
    if {$start_time >= 0.2} {
		set flow_gen [expr $flow_gen + 1]
		if {$deadline_ > 0} {
			set ddl_flow_start [expr $ddl_flow_start + 1]
		} else {
			set nonddl_flow_start [expr $nonddl_flow_start + 1]
		}
    }

    if { $debug_mode == 1 } {
	#puts "stats: [$ns now] start grp $group_id fid $id $nr_bytes bytes"
	puts "stats: $st_time start grp $group_id fid $id $nr_bytes bytes"
    }

    if { [info exists aggr_ctrl] } {
	$aggr_ctrl $start_cbfunc
    }

    $tcpr set flow_remaining_ [expr $nr_bytes]
    $tcps set signal_on_empty_ TRUE
# Tao: here we may add deadline
	$tcps set deadline $deadline_
	$tcpr set deadline $deadline_
# there are something to send
    $tcps advance-bytes $nr_bytes
}

TCP_pair instproc warmup { nr_pkts } {
    global ns
    $self instvar tcps id group_id

    $self instvar debug_mode

    set pktsize [$tcps set packetSize_]

    if { $debug_mode == 1 } {
	puts "warm-up: [$ns now] start grp $group_id fid $id $nr_pkts pkts ($pktsize +40)"
    }

    $tcps advanceby $nr_pkts
}


TCP_pair instproc stop {} {
    $self instvar tcps tcpr

    $tcps reset
    $tcpr reset
}

TCP_pair instproc fin_notify {} {
    global ns
    $self instvar sn dn san dan rttimes
    $self instvar tcps tcpr
    $self instvar aggr_ctrl fin_cbfunc
    $self instvar pair_id
    $self instvar bytes

    $self instvar dt
	$self instvar flct
    $self instvar bps

	#Tao: flow id
	$self instvar id

    $self flow_finished

	# Tao:
	$self instvar deadline_
    #Shuang
    set old_rttimes $rttimes
    $self set rttimes [$tcps set nrexmit_]

    #
    # Mohammad commenting these
    # for persistent connections
    #
    #$tcps reset
    #$tcpr reset

    if { [info exists aggr_ctrl] } {
	$aggr_ctrl $fin_cbfunc $pair_id $id $bytes $dt $flct $bps [expr $rttimes - $old_rttimes] $deadline_
    }
}

TCP_pair instproc flow_finished {} {
    global ns
    $self instvar start_time bytes id group_id
    $self instvar dt bps flct
    $self instvar debug_mode

    set ct [$ns now]
    #Shuang commenting these
	#duration time is calculated as completion time minus start time
    $self set dt  [expr $ct - $start_time]
	$self set flct $ct
    if { $dt == 0 } {
		puts "dt = 0"
		flush stdout
	}
    $self set bps [expr $bytes * 8.0 / $dt ]

    if { $debug_mode == 1 } {
	puts "stats: $ct fin grp $group_id fid $id fldur $dt sec $bps bps"
    }
}

Agent/TCP/FullTcp instproc set_callback {tcp_pair} {
    $self instvar ctrl
    $self set ctrl $tcp_pair
}

Agent/TCP/FullTcp instproc done_data {} {
    global ns sink
    $self instvar ctrl
#puts "[$ns now] $self fin-ack received";
    if { [info exists ctrl] } {
	$ctrl fin_notify
    }
}

Class Agent_Aggr_pair
#Note:
#Contoller and placeholder of Agent_pairs
#Let Agent_pairs to arrives according to
#random process.
#Currently, the following two processes are defined
#- PParrival:
#flow arrival is poissson and
#each flow contains pareto
#distributed number of packets.
#- PEarrival
#flow arrival is poissson and
#each flow contains pareto
#distributed number of packets.
#- PBarrival
#flow arrival is poissson and
#each flow contains bimodal
#distributed number of packets.

#Variables:#
#apair:    array of Agent_pair
#nr_pairs: the number of pairs
#rv_flow_intval: (r.v.) flow interval
#rv_nbytes: (r.v.) the number of bytes within a flow
#ddl_rv_nbytes: (r.v.) the number of bytes within a flow
#last_arrival_time: the last flow starting time
#logfile: log file (should have been opend)
#stat_nr_finflow ;# statistics nr  of finished flows
#stat_sum_fldur  ;# statistics sum of finished flow durations
#last_arrival_time ;# last flow arrival time
#actfl             ;# nr of current active flow

#cntfl
#exprate	;#flowsize/deadline
#abs_deadline	;absolute deadline

#Public functions:
#attach-logfile {logf}  <- call if want logfile
#setup {snode dnode gid nr} <- must
#set_PParrival_process {lambda mean_nbytes shape rands1 rands2}  <- call either
#set_PEarrival_process {lambda mean_nbytes rands1 rands2}        <-
#set_PBarrival_process {lambda mean_nbytes S1 S2 rands1 rands2}  <- of them
#init_schedule {}       <- must

#cal_exprate {ctime}
#cal_deadline {flsize exprate}

#fin_notify { pid bytes fldur bps } ;# Callback
#start_notify {}                   ;# Callback

#Private functions:
#init {args}
#resetvars {}


Agent_Aggr_pair instproc init {args} {
	$self instvar cntfl
    eval $self next $args

	$self set cntfl 0
}


Agent_Aggr_pair instproc attach-logfile { logf } {
#Public
    $self instvar logfile
    $self set logfile $logf
}

#Tao
Agent_Aggr_pair instproc attach-tracefile { trf } {
	$self instvar trfile
	$self set trfile $trf
	# $self set trlen [llength $trf]
}

Agent_Aggr_pair instproc setup {snode dnode gid nr init_fid agent_pair_type} {
#Public
#Note:
#Create nr pairs of Agent_pair
#and connect them to snode-dnode bottleneck.
#We may refer this pair by group_id gid.
#All Agent_pairs have the same gid,
#and each of them has its own flow id: init_fid + [0 .. nr-1]
    #global next_fid

    $self instvar apair     ;# array of Agent_pair
    $self instvar group_id  ;# group id of this group (given)
    $self instvar nr_pairs  ;# nr of pairs in this group (given)
    $self instvar s_node d_node apair_type ;

    $self set group_id $gid
    $self set nr_pairs $nr
    $self set s_node $snode
    $self set d_node $dnode
    $self set apair_type $agent_pair_type

    for {set i 0} {$i < $nr_pairs} {incr i} {
 	      $self set apair($i) [new $agent_pair_type]
          $apair($i) setup $snode $dnode
          $apair($i) setgid $group_id  ;# let each pair know our group id
          $apair($i) setpairid $i      ;# let each pair know his pair id
          # $apair($i) setfid $init_fid  ;# Mohammad: assign next fid
		  # Tao: comment this line 
          incr init_fid
    }
    $self resetvars                  ;# other initialization
}


set warmupRNG [new RNG]
$warmupRNG seed 5251

Agent_Aggr_pair instproc warmup {jitter_period npkts} {
    global ns warmupRNG
    $self instvar nr_pairs apair

    for {set i 0} {$i < $nr_pairs} {incr i} {
	$ns at [expr [$ns now] + [$warmupRNG uniform 0.0 $jitter_period]] "$apair($i) warmup $npkts"
    }
}

Agent_Aggr_pair instproc init_schedule {} {
#Public
#Note:
#Initially schedule flows for all pairs
#according to the arrival process.
    global ns flow_gen
    $self instvar nr_pairs apair
    $self instvar apair_type s_node d_node group_id

    # Mohammad: initializing last_arrival_time
    #$self instvar last_arrival_time
    #$self set last_arrival_time [$ns now]
    #$self instvar tnext rv_flow_intval
	#
	$self instvar trfile

    for {set i 0} {$i < $nr_pairs} {incr i} {
		#### Callback Setting ########################
		$apair($i) set_fincallback $self   fin_notify
		$apair($i) set_startcallback $self start_notify
		###############################################
    }

	set ind_tmp_ 0
	foreach line $trfile {
		if { $ind_tmp_ >= $nr_pairs } {
			
			$self set apair($nr_pairs) [new $apair_type]
			$apair($nr_pairs) setup $s_node $d_node
			$apair($nr_pairs) setgid $group_id ;
			$apair($nr_pairs) setpairid $nr_pairs ;

			#### Callback Setting #################
			$apair($nr_pairs) set_fincallback $self fin_notify
			$apair($nr_pairs) set_startcallback $self start_notify
			#######################################
			incr nr_pairs
		}
		if { [llength [split $line " "]] > 0 } {
			set trflid [lindex [split $line " "] 0]
			set v1 [lindex [split $line " "] 1] 	
			set v2 [lindex [split $line " "] 2] 	
			set v3 [lindex [split $line " "] 3]

			$apair($ind_tmp_) setfid $trflid
			$apair($ind_tmp_) setdeadline [expr ceil ($v3)] 
			$ns at $v1 "$apair($ind_tmp_) start [expr ceil ($v2 * 1460)]"

			# set flow_gen [expr $flow_gen + 1]
		}
		# puts "$group_id generate flows $ind_tmp_"
		incr ind_tmp_
	}
}

Agent_Aggr_pair instproc resetvars {} {
#Private
#Reset variables
#   $self instvar fid             ;# current flow id of this group
    $self instvar tnext ;# last flow arrival time
    $self instvar actfl             ;# nr of current active flow

    $self set tnext 0.0
#    $self set fid 0 ;#  flow id starts from 0
    $self set actfl 0
}



Agent_Aggr_pair instproc fin_notify { pid flid bytes fldur flct bps rttimes ddl} {
#Callback Function
#pid  : pair_id
#bytes : nr of bytes of the flow which has just finished
#fldur: duration of the flow which has just finished
#bps  : avg bits/sec of the flow which has just finished
#Note:
#If we registor $self as "setcallback" of
#$apair($id), $apair($i) will callback this
#function with argument id when the flow between the pair finishes.
#i.e.
#If we set:  "$apair(13) setcallback $self" somewhere,
#"fin_notify 13 $bytes $fldur $bps" is called when the $apair(13)'s flow is finished.
#
    global ns flow_gen flow_fin sim_end
	global ddl_flow_fin nonddl_flow_fin
    $self instvar logfile
    $self instvar group_id
    $self instvar actfl
    $self instvar apair

    #Here, we re-schedule $apair($pid).
    #according to the arrival process.

    $self set actfl [expr $actfl - 1]

    # set fin_fid [$apair($pid) set id]

    ###### OUPUT STATISTICS #################
    if { [info exists logfile] } {
        #puts $logfile "flow_stats: [$ns now] gid $group_id pid $pid fid $fin_fid bytes $bytes fldur $fldur actfl $actfl bps $bps"
        set tmp_pkts [expr $bytes / 1460]

		#puts $logfile "$tmp_pkts $fldur $rttimes"
		# Tao: we may trace down the deadline here
		# puts $logfile "$tmp_pkts $fldur $rttimes $group_id"
		puts $logfile "$flid $tmp_pkts $fldur $flct $ddl $rttimes $group_id"
		flush stdout
    }
	#if { $flct >= 2.0 } {
	#	finish
	#}
    set flow_fin [expr $flow_fin + 1]
	if {$ddl > 0} {
		set ddl_flow_fin [expr $ddl_flow_fin + 1]
	} else {
		set nonddl_flow_fin [expr $nonddl_flow_fin + 1]
	}
    if {$flow_fin >= $sim_end} {
	finish
    }
    #if {$flow_gen < $sim_end} {
    #$self schedule $pid ;# re-schedule a pair having pair_id $pid.
    #}
}

Agent_Aggr_pair instproc start_notify {} {
#Callback Function
#Note:
#If we registor $self as "setcallback" of
#$apair($id), $apair($i) will callback this
#function with argument id when the flow between the pair finishes.
#i.e.
#If we set:  "$apair(13) setcallback $self" somewhere,
#"start_notyf 13" is called when the $apair(13)'s flow is started.
    $self instvar actfl;
    incr actfl;
}
proc finish {} {
    global ns flowlog
    global sim_start
    global enableNAM namfile
	global ddl_flow_start ddl_flow_fin nonddl_flow_start nonddl_flow_fin
	global S topology_spt topology_tors topology_spines
	global log_hl log_lh log_ls log_sl

    $ns flush-trace
    close $flowlog

	for {set i 0} {$i < $S} {incr i} {
		set j [expr $i/$topology_spt]
		close $log_hl($i,$j)
		close $log_lh($j,$i)
	}
	
	for {set i 0} {$i < $topology_tors} {incr i} {
		for {set j 0} {$j < $topology_spines} {incr j} {
			close $log_ls($i,$j)
			close $log_sl($j,$i)
		}
	}

    set t [clock seconds]
    puts "Simulation Finished!"
    puts "Time [expr $t - $sim_start] sec"
	puts "$ddl_flow_fin out of $ddl_flow_start finished"
	puts "$nonddl_flow_fin out of $nonddl_flow_start finished"
    
    exit 0
}
