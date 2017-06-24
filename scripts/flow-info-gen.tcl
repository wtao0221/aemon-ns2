Class Flow_genner

Flow_genner instproc init {args} {
	$self instvar group_id pair_id id
}

Flow_genner instproc setgid {gid} {
	$self instvar group_id
	$self set group_id $gid
}

Flow_genner instproc setpairid {pid} {
	$self instvar pair_id
	$self set pair_id $pid
}

Flow_genner instproc setfid {fid} {
	$self instvar id
	$self set id $fid
}


Class Flow_info

Flow_info instproc init {args} {
	$self instvar cntfl abs_deadline deadline nbytes st_time desrate
	eval $self next $args

	$self set cntfl 0
}

Flow_info instproc attach-logfile {logf} {
	$self instvar sumfile
	$self set sumfile $logf
}

Flow_info instproc init_schedule {} {
	global ns
	$self instvar nr_pairs

	$self instvar tnext rv_flow_intval
	set dt [$rv_flow_intval value]
	$self set tnext [expr [$ns now] + $dt]

	for {set i 0} {$i < $nr_pairs} {incr i} {
		$self schedule $i
	}
}

#Flow_info instproc setup {sd rv nr init_fid} {
Flow_info instproc setup {sd rv nr} {
	$self instvar snd rec
	$self instvar nr_pairs
	$self instvar fid

	$self set snd $sd
	$self set rec $rv
	$self set nr_pairs $nr
	#$self set fid $init_fid

	#for {set i 0} {$i < $nr_pairs} {incr i} {
	#	$self set apair($i) [new $class_type]
	#	$apair($i) setgid $group_id
	#	$apair($i) setpairid $i
	#	$apair($i) setfid $init_fid
	#	incr init_fid
	#}
}

Flow_info instproc schedule {pid} {
	global ns flow_gen nFlows gen_type endtime
	$self instvar tnext
	$self instvar rv_flow_intval rv_nbytes
	$self instvar group_id cntfl st_time nbytes 
	$self instvar desrate abs_deadline deadline

	set t [$ns now]

	if { $t > $tnext } {
		puts "Error, Not enough flows!"
		flush stdout
		exit
	}

	set tmp_ [expr ceil ([$rv_nbytes value])]
	set tmp_ [expr $tmp_ * 1460]

	set st_time($cntfl) $tnext
	set nbytes($cntfl) $tmp_
	set abs_deadline($cntfl) 0
	set deadline($cntfl) 0
	set desrate($cntfl) 0
	incr cntfl

	set flow_gen [expr $flow_gen+1]

	if { $gen_type == 0} {
		if { $flow_gen >= $nFlows } {
			finish
			return
		}
	}

	set dt [$rv_flow_intval value]
	$self set tnext [expr $tnext + $dt]
	$ns at [expr $tnext - 0.0000001] "$self check_if_behind"
}

Flow_info instproc check_if_behind {} {
	global ns
	global flow_gen nFlows gen_type endtime

	$self instvar nr_pairs
	$self instvar tnext

	set t [$ns now]
	set tmp_flag_ 0
	if { $tnext < [expr $t + 0.0000002]} {
		if { $gen_type == 0} {
			if { $flow_gen < $nFlows} {
				set tmp_flag 1
			}
		} elseif {$gen_type == 1} {
			set tmp_flag 1
		}
		if { $tmp_flag == 1} {
			puts "[$ns now]: creating new connection gen_type 1"
			flush stdout

			$self schedule $nr_pairs
			incr nr_pairs
		}
	}
}

Flow_info instproc set_ddl_Distribution {lambda rands} {
	$self instvar rv_flow_ddl

	set rng [new RNG]
	$rng seed $rands

	$self set rv_flow_ddl [new RandomVariable/Exponential]
	$rv_flow_ddl use-rng $rng
	# [NOTICE] $lambda is the avg
	$rv_flow_ddl set avg_ [expr $lambda]
}

Flow_info instproc set_Distribution {lambda cdffile rands1 rands2} {
	$self instvar rv_flow_intval rv_nbytes

	set rng1 [new RNG]
	$rng1 seed $rands1

	$self set rv_flow_intval [new RandomVariable/Exponential]
	$rv_flow_intval use-rng $rng1
	$rv_flow_intval set avg_ [expr 1.0/$lambda]

	set rng2 [new RNG]
	$rng2 seed $rands2

	$self set rv_nbytes [new RandomVariable/Empirical]
	$rv_nbytes use-rng $rng2
	$rv_nbytes set interpolation_ 2
	$rv_nbytes loadCDF $cdffile
}

Flow_info instproc cal_deadline_pf { ind } {
	global link_rate Ucap
	global initcwnd e2e_delay
	global maxcwndcnt tot_byte tot_nrtt
	$self instvar nbytes rv_flow_ddl

	if {$nbytes($ind) > 200*1000} {
		return 0
	}

	# ddl from calculation
	if {$nbytes($ind) <= $tot_byte} {
		set tmp1 [expr $nbytes($ind)/($initcwnd*1460) + 1]
		set tmp2 [expr log ($tmp1)]
		set tmp3 [expr log (2)]

		set tmp_nrtt [expr ceil ([expr $tmp2/$tmp3])]

	} else {
		set tmp_addnrtt [expr ($nbytes($ind)-$tot_byte)/($initcwnd*1460)]
		set tmp_nrtt_plus [expr ceil ($tmp_addnrtt)]
		set tmp_nrtt [expr $tot_nrtt+$tmp_nrtt_plus]
	}

	set tmp_rtt [expr $nbytes($ind)*8/($link_rate*1000) + $nbytes($ind)*8/($Ucap*1000)]
	set tmp_rtt [expr $tmp_rtt + $e2e_delay]
	set tmp_rtt [expr 2 * $tmp_rtt]
	set ddl_tmp_cal [expr $tmp_nrtt * $tmp_rtt]

	# ddl from distribution
	set ddl_tmp_dis [$rv_flow_ddl value]
	# we do not use nrtt*rtt this time
	# set ddl_tmp_cal [expr $nbytes($ind)*8/($link_rate*1000) + $tmp_rtt]

	#puts "ddl_tmp_dis: $ddl_tmp_dis, ddl_tmp_cal: [expr 1.25*$ddl_tmp_cal]"

	if {$ddl_tmp_dis < [expr 1.25*$ddl_tmp_cal]} {
		return [expr ceil ([expr 1.25*$ddl_tmp_cal])]
	} else {
		return [expr ceil ($ddl_tmp_dis)]
	}

}

Flow_info instproc cal_deadline { ind } {
	global ddl_load link_rate
	global S
	$self instvar cntfl st_time nbytes abs_deadline desrate

	# rate in MBps, divided by ($S-1) hosts
	set allrate [expr $ddl_load * $link_rate * 1000 / (8* ($S-1))]
	# set allrate [expr $ddl_load * $link_rate * 1000 / 8]
	set sumrate 0
	for {set i 0} {$i < $cntfl} {incr i} {
		if {$abs_deadline($i) < $st_time($ind)} {
			continue;
		} else {
			set sumrate [expr $sumrate + $desrate($i)]
		}
	}

	set exprate [expr $allrate - $sumrate]

	#if {[expr $nbytes($ind)] >= 200*1000} {
	#	set desrate($ind) 0
	#	return 0
	#}

	#puts "nbytes of $ind: [expr $nbytes($ind)]"


	if {$exprate <= 0} {
		set desrate($ind) 0
		return 0
	} else {
		set desrate($ind) $exprate
		set tmp_ [expr $nbytes($ind) / $exprate]
		if {$tmp_ <= 5000} {
			# rate in MBps
			set desrate($ind) [expr 1.0*$nbytes($ind) / 5000]
			return 5000
		} else {
			return [expr ceil ($tmp_)]
		}
	}
}

Flow_info instproc logdown {} {
	global flow_fin nFlows prefix pf_gen
	$self instvar cntfl st_time nbytes group_id abs_deadline deadline
	$self instvar snd rec desrate

	set fpname [concat $prefix/$snd-$rec]
	set logfile [open $fpname w]

	for {set i 0} {$i < $cntfl} {incr i} {
		if {$pf_gen == 0} {
			set dtmp_ [$self cal_deadline $i]
		} elseif {$pf_gen == 1} {
			set dtmp_ [$self cal_deadline_pf $i]
		}
		set deadline($i) $dtmp_
		set abs_deadline($i) [expr 1.0 * $deadline($i)/1e6 + $st_time($i)]

		if { [info exists logfile] } {
			# puts $logfile "$group_id $st_time($i) [expr $nbytes($i) / 1460] $deadline($i) $abs_deadline($i) $desrate($i)"
			#Tao: we can treate this $flow_fin as fid
			puts $logfile "$flow_fin $st_time($i) [expr $nbytes($i) / 1460] $deadline($i)"
			flush stdout
		}


		set flow_fin [expr $flow_fin+1]

	}

	close $logfile
}

proc finish_update_ddl {snd} {
	global prefix
	global S
	global ddl_load link_rate
	global sumlog


	set x [list]
	set cntfl 0
	for {set rec 0} {$rec < $S} {incr rec} {
		if {$snd != $rec} {
			set fpname [concat $prefix/$snd-$rec]
			set rp [open $fpname r]
			set rdata [read $rp]

			set rdata [split $rdata "\n"]
			foreach line $rdata {
				set ltmp [split $line " "]
				if {[llength $ltmp] > 0} {
					set t_fid [lindex $ltmp 0]
					set t_st [lindex $ltmp 1]
					set t_bytes [lindex $ltmp 2]
					set t_ddl [lindex $ltmp 3]

					set t_list [list $snd $rec $t_fid $t_st $t_bytes $t_ddl]
					lappend x $t_list

					set des_rate($cntfl) 0
					set abs_ddl($cntfl) 0
					set ddl($cntfl) 0
					incr cntfl
				}
			}

			close $rp
		}
	}

	#sort
	set x [lsort -real -index 3 $x]
	#calculate deadline
	set allrate [expr $ddl_load * $link_rate * 1000 / 8]

	for {set i 0} {$i < $cntfl} {incr i} {
		set sumrate 0
		set i_list [lindex $x $i]
		set i_st [lindex $i_list 3]
		set i_bytes [lindex $i_list 4]
		set i_bytes [expr $i_bytes * 1460]
		for {set j 0} {$j < $i} {incr j} {
			if {$abs_ddl($j) > $i_st} {
				set sumrate [expr $sumrate + $des_rate($j)]
			}
		}

		set avail_rate [expr $allrate - $sumrate]

		if {$avail_rate <= 0} {
			set des_rate($i) 0
			set t_ddl 0
		} else {
			set t_ddl [expr $i_bytes / $avail_rate]
			if {$t_ddl < 5000} {
				set t_ddl 5000
				set des_rate($i) [expr $i_bytes / 5000]
			} else {
				set des_rate($i) $avail_rate
			}
		}
	
		set t_ddl [expr ceil ($t_ddl)]
		set ddl($i) $t_ddl
		set abs_ddl($i) [expr 1.0*$t_ddl/1e6 + $i_st]

		lset x $i 5 $t_ddl	
	}
	#logdown
	for {set i 0} {$i < $cntfl} {incr i} {
		set i_list [lindex $x $i]
		set t_snd [lindex $i_list 0]
		set t_rec [lindex $i_list 1]
		set t_fid [lindex $i_list 2]
		set t_st [lindex $i_list 3]
		set t_bytes [lindex $i_list 4]
		set t_ddl [lindex $i_list 5]
		set path "new"
		set fpname [concat $prefix/$path-$t_snd-$t_rec]
		set fp [open $fpname a+]
		puts $fp "$t_fid $t_st $t_bytes $t_ddl"
		close $fp
		
		if { [info exists sumlog] } {
			#Tao: we can treate this $flow_fin as fid
			puts $sumlog "$t_fid $t_snd $t_rec $t_st $t_bytes $t_ddl"
			flush stdout
			flush stdout
		}
	}
}


proc finish {} {
	global ns
	global sim_start
	global trlog
	global S flinfo flow_gen flow_fin
	global sumlog

	$ns flush-trace
	
	for {set i 0} {$i < $S} {incr i} {
		for {set j 0} {$j < $S} {incr j} {
			if {$i != $j} {
				$flinfo($i,$j) logdown
			}
		}
	}

	#for {set i 0} {$i < $S} {incr i} {
	#	for {set j 0} {$j < $S} {incr j} {
	#		if {$i != $j} {
	#			close $trlog($i,$j)
	#		}
	#	}
	#}

	#Tao: now, we may add something here
	for {set i 0} {$i < $S} {incr i} {
		finish_update_ddl $i
	}

	

	close $sumlog
	set t [clock seconds]
	puts "Simulation Finished!"
	puts "flow_gen: $flow_gen###flow_fin: $flow_fin"
	puts "Time [expr $t - $sim_start] secs"
	exit
}
