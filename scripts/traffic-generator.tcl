source "flow-info-gen.tcl"

set ns [new Simulator]
puts "Date: [clock format [clock seconds]]"
set sim_start [clock seconds]

if {$argc != 20} {
	puts "wrong number of arguments $argc"
	exit -1
}

# num_flows mean_flow_size flow_cdf link_rate tot_load ddl_load topo_spt topo_tors
# link_rate in Gbps
#
set nFlows [lindex $argv 0]
set meanFlowSize [lindex $argv 1]
set flow_cdf [lindex $argv 2]
set link_rate [lindex $argv 3]
set load [lindex $argv 4]
set ddl_load [lindex $argv 5]
set topo_spt [lindex $argv 6]
set topo_tors [lindex $argv 7]
set prefix [lindex $argv 8]
set con_per_pair [lindex $argv 9]
set sumlog [open [lindex $argv 10] w]
set endtime [lindex $argv 11]
set gen_type [lindex $argv 12]
set topo_spines [lindex $argv 13]
set pf_gen [lindex $argv 14]
set mean_ddl [lindex $argv 15]

set S [expr $topo_spt * $topo_tors]
set Ucap [expr $link_rate * $topo_spt / $topo_spines]

set initcwnd [lindex $argv 16]
set maxcwnd [lindex $argv 17]
set mean_link_delay [lindex $argv 18]
set host_delay [lindex $argv 19]

set maxcwndcnt [expr $maxcwnd/$initcwnd]
set tmp_log1 [expr log ($maxcwndcnt)]
set tmp_log2 [expr log (2)]
set tmp_log3 [expr floor ([expr $tmp_log1/$tmp_log2])]
set tot_byte 0
set base 1
for {set i 0} {$i <= $tmp_log3} {incr i} {
	set tot_byte [expr $tot_byte+$base]
	set base [expr 2*$base]
}
puts "tot_byte $tot_byte"

set tot_byte [expr $tot_byte*1460*$initcwnd]
set tot_nrtt [expr $tmp_log3+1]
set e2e_delay [expr 1000000*($host_delay+4*$mean_link_delay)]
puts "maxcwndcnt $maxcwndcnt with $tot_byte and $tot_nrtt"



# total flow stats
set flow_gen 0
set flow_fin 0
# set init_fid 0
# generate flow info
set lambda [expr ($link_rate*$load*1000000000)/($meanFlowSize*8.0/1460*1500)]

for {set i 0} {$i < $S} {incr i} {
	for {set j 0} {$j < $S} {incr j} {
		if {$i != $j} {
			#set fpname [concat $prefix/$i-$j]
			# puts "trace file name: $fpname"
			#set trlog($i,$j) [open $fpname w]

			set flinfo($i,$j) [new Flow_info]
			#$flinfo($i,$j) setup $i $j $con_per_pair $init_fid
			$flinfo($i,$j) setup $i $j $con_per_pair

			#$flinfo($i,$j) attach-logfile $sumlog

			$flinfo($i,$j) set_Distribution [expr $lambda/($S - 1)] $flow_cdf [expr 17*$i+1244*$j] [expr 33*$i+4369*$j]

			$flinfo($i,$j) set_ddl_Distribution $mean_ddl [expr 17*$i+1244*$j]

			$ns at 1 "$flinfo($i,$j) init_schedule"
			#$flinfo($i,$j) init_schedule

			#set init_fid [expr $init_fid + $con_per_pair]
		}
	}
}

puts "Initialization Done"; flush stdout

if {$gen_type == 1} {
	$ns at $endtime "finish"
	puts "the end time is $endtime"
}

puts "Simulation start!"

$ns run
