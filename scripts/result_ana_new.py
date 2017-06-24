# the format of input trace file
# flow-size in 1460B packets, flow duration, deadline in us, number of timeouts, gourpid

import argparse
import string
import os
import sys

#Get average FCT
def avg(flows):
    sum = 0.0
    for f in flows:
        sum = sum+f

    if len(flows) > 0:
        return sum/len(flows)
    else:
        return 0

#Get median FCT
def median(flows):
    flows.sort()
    if len(flows) > 0:
        return flows[50*len(flows)/100]
    else:
        return 0

#Get 99-percentile FCT
def max(flows):
    flows.sort()
    if len(flows) > 0:
    	return flows[99*len(flows)/100]
    else:
    	return 0

def max_95(flows):
    flows.sort()
    if len(flows) > 0:
    	return flows[95*len(flows)/100]
    else:
    	return 0

def print_all_flow():
    global flows
    global flows_notimeouts
    global ddl_flows
    global ddl_flows_noto
    global no_ddl_flows
    global no_ddl_flows_noto
    print "==============================Statistics================================"
    print "There are "+str(len(flows))+" flows in total, in which "+str(len(flows_notimeouts))+" are non-timeouts flows"
    print "There are "+str(len(ddl_flows))+" deadline flows in total, in which "+str(len(ddl_flows_noto))+" are non-timeouts flows"
    print "There are "+str(len(no_ddl_flows))+" non-deadline flows in total, in which "+str(len(no_ddl_flows_noto))+" are non-timeouts flows\n"
    print "==============================All-flow Statistics================================"
    print "For all flows (time is in milliseconds)"
    print "Average FCT is "+str(avg(flows))+" Median FCT is "+str(median(flows))+" 99%-percentile FCT is "+str(max(flows))+" 95%-percentile FCT is "+str(max_95(flows))
    print "For all flows w/o timeouts"
    print "Average FCT is "+str(avg(flows_notimeouts))+" Median FCT is "+str(median(flows_notimeouts))+" 99%-percentile FCT is "+str(max(flows_notimeouts))+" 95%-percentile FCT is "+str(max_95(flows_notimeouts))
    print "For all deadline flows"
    print "Average FCT is "+str(avg(ddl_flows))+" Median FCT is "+str(median(ddl_flows))+" 99%-percentile FCT is "+str(max(ddl_flows))+" 95%-percentile FCT is "+str(max_95(ddl_flows))
    print "For all deadline flows w/o timeouts"
    print "Average FCT is "+str(avg(ddl_flows_noto))+" Median FCT is "+str(median(ddl_flows_noto))+" 99%-percentile FCT is "+str(max(ddl_flows_noto))+" 95%-percentile FCT is "+str(max_95(ddl_flows_noto))
    print "For all non-deadline flows"
    print "Average FCT is "+str(avg(no_ddl_flows))+" Median FCT is "+str(median(no_ddl_flows))+" 99%-percentile FCT is "+str(max(no_ddl_flows))+" 95%-percentile FCT is "+str(max_95(no_ddl_flows))
    print "For all non-deadline flows w/o timeouts"
    print "Average FCT is "+str(avg(no_ddl_flows_noto))+" Median FCT is "+str(median(no_ddl_flows_noto))+" 99%-percentile FCT is "+str(max(no_ddl_flows_noto))+" 95%-percentile FCT is "+str(max_95(no_ddl_flows_noto))

def print_short_flow():
    global short_flows
    global short_flows_notimeouts
    global ddl_short_flows
    global ddl_short_flows_noto
    global no_ddl_short_flows
    global no_ddl_short_flows_noto
    print "==============================Short-flow Statistics================================"
    print "For short flows"
    print "There are "+str(len(short_flows))+" flows in total, in which "+str(len(short_flows_notimeouts))+" are non-timeouts flows"
    print "There are "+str(len(ddl_short_flows))+" deadline flows in total, in which "+str(len(ddl_short_flows_noto))+" are non-timeouts flows"
    print "There are "+str(len(no_ddl_short_flows))+" non-deadline flows in total, in which "+str(len(no_ddl_short_flows_noto))+" are non-timeouts flows\n"
    print "Average FCT is "+str(avg(short_flows))+" Median FCT is "+str(median(short_flows))+" 99%-percentile FCT is "+str(max(short_flows))+" 95%-percentile FCT is "+str(max_95(short_flows))
    print "For all flows w/o timeouts"
    print "Average FCT is "+str(avg(short_flows_notimeouts))+" Median FCT is "+str(median(short_flows_notimeouts))+" 99%-percentile FCT is "+str(max(short_flows_notimeouts))+" 95%-percentile FCT is "+str(max_95(short_flows_notimeouts))
    print "For all deadline flows"
    print "Average FCT is "+str(avg(ddl_short_flows))+" Median FCT is "+str(median(ddl_short_flows))+" 99%-percentile FCT is "+str(max(ddl_short_flows))+" 95%-percentile FCT is "+str(max_95(ddl_short_flows))
    print "For all deadline flows w/o timeouts"
    print "Average FCT is "+str(avg(ddl_short_flows_noto))+" Median FCT is "+str(median(ddl_short_flows_noto))+" 99%-percentile FCT is "+str(max(ddl_short_flows_noto))+" 95%-percentile FCT is "+str(max_95(ddl_short_flows_noto))
    print "For all non-deadline flows"
    print "Average FCT is "+str(avg(no_ddl_short_flows))+" Median FCT is "+str(median(no_ddl_short_flows))+" 99%-percentile FCT is "+str(max(no_ddl_short_flows))+" 95%-percentile FCT is "+str(max_95(no_ddl_short_flows))
    print "For all non-deadline flows w/o timeouts"
    print "Average FCT is "+str(avg(no_ddl_short_flows_noto))+" Median FCT is "+str(median(no_ddl_short_flows_noto))+" 99%-percentile FCT is "+str(max(no_ddl_short_flows_noto))+" 95%-percentile FCT is "+str(max_95(no_ddl_short_flows_noto))

def print_median_flow():
    global median_flows
    global median_flows_notimeouts
    global ddl_median_flows
    global ddl_median_flows_noto
    global no_ddl_median_flows
    global no_ddl_median_flows
    print "==============================Median-flow Statistics================================"
    print "For median flows"
    print "There are "+str(len(median_flows))+" flows in total, in which "+str(len(median_flows_notimeouts))+" are non-timeouts flows"
    print "There are "+str(len(ddl_median_flows))+" deadline flows in total, in which "+str(len(ddl_median_flows_noto))+" are non-timeouts flows"
    print "There are "+str(len(no_ddl_median_flows))+" non-deadline flows in total, in which "+str(len(no_ddl_median_flows_noto))+" are non-timeouts flows\n"
    print "Average FCT is "+str(avg(median_flows))+" Median FCT is "+str(median(median_flows))+" 99%-percentile FCT is "+str(max(median_flows))+" 95%-percentile FCT is "+str(max_95(median_flows))
    print "For all flows w/o timeouts"
    print "Average FCT is "+str(avg(median_flows_notimeouts))+" Median FCT is "+str(median(median_flows_notimeouts))+" 99%-percentile FCT is "+str(max(median_flows_notimeouts))+" 95%-percentile FCT is "+str(max_95(median_flows_notimeouts))
    print "For all deadline flows"
    print "Average FCT is "+str(avg(ddl_median_flows))+" Median FCT is "+str(median(ddl_median_flows))+" 99%-percentile FCT is "+str(max(ddl_median_flows))+" 95%-percentile FCT is "+str(max_95(ddl_median_flows))
    print "For all deadline flows w/o timeouts"
    print "Average FCT is "+str(avg(ddl_median_flows_noto))+" Median FCT is "+str(median(ddl_median_flows_noto))+" 99%-percentile FCT is "+str(max(ddl_median_flows_noto))+" 95%-percentile FCT is "+str(max_95(ddl_median_flows_noto))
    print "For all non-deadline flows"
    print "Average FCT is "+str(avg(no_ddl_median_flows))+" Median FCT is "+str(median(no_ddl_median_flows))+" 99%-percentile FCT is "+str(max(no_ddl_median_flows))+" 95%-percentile FCT is "+str(max_95(no_ddl_median_flows))
    print "For all non-deadline flows w/o timeouts"
    print "Average FCT is "+str(avg(no_ddl_median_flows_noto))+" Median FCT is "+str(median(no_ddl_median_flows_noto))+" 99%-percentile FCT is "+str(max(no_ddl_median_flows_noto))+" 95%-percentile FCT is "+str(max_95(no_ddl_median_flows_noto))
	

def print_large_flow():
    global large_flows
    global large_flows_notimeouts
    global ddl_large_flows
    global ddl_large_flows_noto
    global no_ddl_large_flows
    global no_ddl_large_flows_noto
    print "==============================Long-flow Statistics================================"
    print "For large flows"
    print "There are "+str(len(large_flows))+" flows in total, in which "+str(len(large_flows_notimeouts))+" are non-timeouts flows"
    print "There are "+str(len(ddl_large_flows))+" deadline flows in total, in which "+str(len(ddl_large_flows_noto))+" are non-timeouts flows"
    print "There are "+str(len(no_ddl_large_flows))+" non-deadline flows in total, in which "+str(len(no_ddl_large_flows_noto))+" are non-timeouts flows\n"
    print "Average FCT is "+str(avg(large_flows))+" Median FCT is "+str(median(large_flows))+" 99%-percentile FCT is "+str(max(large_flows))+" 95%-percentile FCT is "+str(max_95(large_flows))
    print "For all flows w/o timeouts"
    print "Average FCT is "+str(avg(large_flows_notimeouts))+" Median FCT is "+str(median(large_flows_notimeouts))+" 99%-percentile FCT is "+str(max(large_flows_notimeouts))+" 95%-percentile FCT is "+str(max_95(large_flows_notimeouts))
    print "For all deadline flows"
    print "Average FCT is "+str(avg(ddl_large_flows))+" Median FCT is "+str(median(ddl_flows))+" 99%-percentile FCT is "+str(max(ddl_large_flows))+" 95%-percentile FCT is "+str(max_95(ddl_large_flows))
    print "For all deadline flows w/o timeouts"
    print "Average FCT is "+str(avg(ddl_large_flows_noto))+" Median FCT is "+str(median(ddl_large_flows_noto))+" 99%-percentile FCT is "+str(max(ddl_large_flows_noto))+" 95%-percentile FCT is "+str(max_95(ddl_large_flows_noto))
    print "For all non-deadline flows"
    print "Average FCT is "+str(avg(no_ddl_large_flows))+" Median FCT is "+str(median(no_ddl_large_flows))+" 99%-percentile FCT is "+str(max(no_ddl_large_flows))+" 95%-percentile FCT is "+str(max_95(no_ddl_large_flows))
    print "For all non-deadline flows w/o timeouts"
    print "Average FCT is "+str(avg(no_ddl_large_flows_noto))+" Median FCT is "+str(median(no_ddl_large_flows_noto))+" 99%-percentile FCT is "+str(max(no_ddl_large_flows_noto))+" 95%-percentile FCT is "+str(max_95(no_ddl_large_flows_noto))


def print_stats():
    global mis_ddl
    global ddl_flows
    global mis_ddl_noto
    global ddl_flows_noto
    global dt_ddl_ratio
    global dt_ddl_ratio_noto
    mis_ratio = 0.0
    mis_ratio_noto = 0.0
    if len(ddl_flows) > 0:
    	mis_ratio = 1.0*mis_ddl/len(ddl_flows)
    else:
    	mis_ratio = 0.0

    if len(ddl_flows_noto) > 0:
    	mis_ratio_noto = 1.0*mis_ddl_noto/len(ddl_flows_noto)
    else:
    	mis_ratio_noto = 0.0

    print "==============================Normal Statistics================================"
    print "The missing deadline ratio is "+str(mis_ratio)+" of "+str(len(ddl_flows))+" deadline flows"
    print "The missing deadline ratio is "+str(mis_ratio_noto)+" of "+str(len(ddl_flows_noto))+" deadline flows w/o timeouts"
    print "For all deadline flows"
    print "Average FCT is "+str(avg(dt_ddl_ratio))+" Median FCT is "+str(median(dt_ddl_ratio))+" 99%-percentile FCT is "+str(max(dt_ddl_ratio))+" 95%-percentile FCT is "+str(max_95(dt_ddl_ratio))
    print "For all deadline flows w/o timeouts"
    print "Average FCT is "+str(avg(dt_ddl_ratio_noto))+" Median FCT is "+str(median(dt_ddl_ratio_noto))+" 99%-percentile FCT is "+str(max(dt_ddl_ratio_noto))+" 95%-percentile FCT is "+str(max_95(dt_ddl_ratio_noto))


parser = argparse.ArgumentParser()
parser.add_argument("-i", "--input", help="input file name")
parser.add_argument("-a","--all",help="print all FCT information",action="store_true")
parser.add_argument("-s","--small",help="print FCT information for short flows",action="store_true")
parser.add_argument("-m","--median",help="print FCT information for median flows",action="store_true")
parser.add_argument("-l","--large",help="print FCT information for large flows",action="store_true")
parser.add_argument("-d","--deadline",help="print deadline information",action="store_true")


#All the flows
flows=[]
flows_notimeouts=[];	#Flows without timeouts
ddl_flows=[];	#Flows with deadline
ddl_flows_noto=[]
no_ddl_flows=[]
no_ddl_flows_noto=[]
#Short flows (0,100KB)
short_flows=[]
short_flows_notimeouts=[];
ddl_short_flows=[]
ddl_short_flows_noto=[];
no_ddl_short_flows=[]
no_ddl_short_flows_noto=[];
#Large flows (10MB,)
large_flows=[]
large_flows_notimeouts=[];
ddl_large_flows=[]
ddl_large_flows_noto=[];
no_ddl_large_flows=[]
no_ddl_large_flows_noto=[];
#Median flows (100KB, 10MB)
median_flows=[]
median_flows_notimeouts=[];
ddl_median_flows=[]
ddl_median_flows_noto=[];
no_ddl_median_flows=[]
no_ddl_median_flows_noto=[];
#the ration of duration_time/deadline
dt_ddl_ratio=[];
dt_ddl_ratio_noto=[];
#The number of total timeouts
timeouts=0
#The number of missing deadline flows
mis_ddl=0
mis_ddl_noto=0;

args = parser.parse_args()

if args.input:
    fp = open(args.input)
    while True:
    	line = fp.readline()
    	if not line:
    		break
    	if len(line.split(' '))<4:
            continue
    	pkt_size = int(float(line.split(' ')[1]))
    	byte_size = float(pkt_size)*1460
    	duration_time = float(line.split(' ')[2]) # in s
    	complete_time = float(line.split(' ')[3]) # in s
    	deadline_time = float(line.split(' ')[4]) # in us

	dt_in_ms = duration_time*1000
	ddl_in_ms = deadline_time/1000
		
	#TCP timeouts
	timeouts_num = int(line.split(' ')[5])
	timeouts = timeouts+timeouts_num

	flows.append(dt_in_ms);

	#Processing all flows
	if deadline_time > 0:
            ddl_flows.append(dt_in_ms)
	    ratio = dt_in_ms/ddl_in_ms
	    dt_ddl_ratio.append(ratio)
	    if ratio > 1:
		mis_ddl = mis_ddl+1
	    if byte_size < 100*1024:
	        short_flows.append(dt_in_ms)
	        ddl_short_flows.append(dt_in_ms)
	    elif byte_size > 10*1024*1024:
	        large_flows.append(dt_in_ms)
	        ddl_large_flows.append(dt_in_ms)
	    else:
	        median_flows.append(dt_in_ms)
	        ddl_median_flows.append(dt_in_ms)
	else:
	    no_ddl_flows.append(dt_in_ms)
	    if byte_size < 100*1024:
	        short_flows.append(dt_in_ms)
	        no_ddl_short_flows.append(dt_in_ms)
	    elif byte_size > 10*1024*1024:
		large_flows.append(dt_in_ms)
		no_ddl_large_flows.append(dt_in_ms)
	    else:
		median_flows.append(dt_in_ms)
		no_ddl_median_flows.append(dt_in_ms)
	#Processing flows without timeouts
	if timeouts_num == 0:
	    flows_notimeouts.append(dt_in_ms)
	    if deadline_time > 0:
		ddl_flows_noto.append(dt_in_ms)
		ratio = dt_in_ms/ddl_in_ms
		dt_ddl_ratio_noto.append(ratio)
	        if ratio > 1:
		    mis_ddl_noto = mis_ddl_noto+1
	        if byte_size < 100*1024:
		    short_flows_notimeouts.append(dt_in_ms)
		    ddl_short_flows_noto.append(dt_in_ms)
	        elif byte_size > 10*1024*1024:
		    large_flows_notimeouts.append(dt_in_ms)
		    ddl_large_flows_noto.append(dt_in_ms)
	        else:
		    median_flows_notimeouts.append(dt_in_ms)
		    ddl_median_flows_noto.append(dt_in_ms)
	    else:
	        no_ddl_flows_noto.append(dt_in_ms)
	        if byte_size < 100*1024:
		    short_flows_notimeouts.append(dt_in_ms)
		    no_ddl_short_flows_noto.append(dt_in_ms)
	        elif byte_size > 10*1024*1024:
		    large_flows_notimeouts.append(dt_in_ms)
		    no_ddl_large_flows_noto.append(dt_in_ms)
	        else:
		    median_flows_notimeouts.append(dt_in_ms)
		    no_ddl_median_flows_noto.append(dt_in_ms)

    fp.close()
	
    if args.all:
        print_stats()
        print_all_flow()
        print_short_flow()
        print_median_flow()
        print_large_flow()
	
    if args.small:
        print_short_flow()

    if args.median:
        print_median_flow()

    if args.large:
        print_large_flow()

    if args.deadline:
        print_stats()
