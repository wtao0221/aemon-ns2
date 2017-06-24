import threading
import os
import Queue
import sys

def worker():
	while True:
		try:
			j = q.get(block=0)
		except Queue.Empty:
			return
		os.system('mkdir '+j[1])
		os.system(j[0])

q = Queue.Queue()

if len(sys.argv) != 14:
    print len(sys.argv)
    print 'invalid arguments!'
    sys.exit(0)

sim_end = int(sys.argv[1])
link_rate = 10 # in Gpbs
mean_link_delay = float(sys.argv[2])
host_delay = float(sys.argv[3])
queueSize = float(sys.argv[4])
load_arr = float(sys.argv[5])
ddl_load_arr = float(sys.argv[6]) 
connections_per_pair = int(sys.argv[7])
meanFlowSize = 5117*1460 # in B
paretoShape = 1.05
flow_cdf = 'CDF_datamining.tcl'

enableMultiPath = 1
perflowMP = 0

#L2DCT-Sack
sourceAlg = 'DCTCP-Sack'
#the initwindow may be different in our setting
initWindow = int(sys.argv[8]) # in pkts
ackRatio = 1
slowstartrestart = 'true'
DCTCP_g = 0.0625
min_rto = float(sys.argv[9])
prob_cap_ = 5

switchAlg = 'EDFQueue'
DCTCP_K = int(sys.argv[10])
drop_prio_ = 'true'
prio_scheme_ = int(sys.argv[13])
deque_prio_ = 'true'
keep_order_ = 'true'
num_queue_ = int(sys.argv[11])
ECN_scheme_ = 2 # per-port ECN marking
# Tao: here we simply copy the pias thresholds at this time
queue_thresh_ind = int(sys.argv[12])
queue_thresh_0 = [750*1460, 745*1460, 907*1460, 840*1460, 805*1460]
queue_thresh_1 = [1083*1460, 1083*1460, 1301*1460, 1232*1460, 1106*1460]
queue_thresh_2 = [1416*1460, 1391*1460, 1619*1460, 1617*1460, 1401*1460]
queue_thresh_3 = [13705*1460, 13689*1460, 12166*1460, 11950*1460, 10693*1460]
queue_thresh_4 = [14952*1460, 14936*1460, 12915*1460, 12238*1460, 11970*1460]
queue_thresh_5 = [21125*1460, 21149*1460, 21313*1460, 21494*1460, 21162*1460]
queue_thresh_6 = [28253*1460, 27245*1460, 26374*1460, 25720*1460, 22272*1460]

topology_spt = 16
topology_tors = 9
topology_spines = 4
topology_x = 1

#newly added
pf_ddl_en = 0
early_detect = 0
pias_enable = 0
karuna_enable = 0
pfabric_enable = 1

#ns_path = '/usr/wtao/workspace/project-dct-build/ns-allinone-2.34/ns-2.34/ns'
ns_path = '/users/wtao0221/project-dct-build/ns-allinone-2.34/ns-2.34/ns'
#ns_path = '/home/wtao/project-dct-build/ns-allinone-2.34/ns-2.34/ns'
sim_script = 'spine_empirical_load.tcl'

# put commands to job queue
if prio_scheme_ == 2:
	scheme = 'edf_pfabric_remainsize'
elif prio_scheme_ == 3:
	scheme = 'edf_pfabric_sentsofar'
else:
	scheme = 'unknown'

if scheme == 'unknown':
    print 'unknown scheme'
    sys.exit(0)

dir_name = 'datamining_%s_%d_%d_%d' % (scheme, int(num_queue_),\
        int(load_arr*100), int(ddl_load_arr*100))
dir_name = dir_name.lower()

tr_dir_prefix = 'flow-trace/dm_%d_%d' % (int(load_arr*100), int(ddl_load_arr*100))

tr_dir_prefix.lower()

# simulation command
cmd = ns_path+' '+sim_script+' '\
        +str(sim_end)+' '\
        +str(link_rate)+' '\
        +str(mean_link_delay)+' '\
        +str(host_delay)+' '\
        +str(queueSize)+' '\
        +str(load_arr)+' '\
        +str(ddl_load_arr)+' '\
        +str(connections_per_pair)+' '\
        +str(meanFlowSize)+' '\
        +str(paretoShape)+' '\
        +str(flow_cdf)+' '\
        +str(enableMultiPath)+' '\
        +str(perflowMP)+' '\
        +str(sourceAlg)+' '\
        +str(initWindow)+' '\
        +str(ackRatio)+' '\
        +str(slowstartrestart)+' '\
        +str(DCTCP_g)+' '\
        +str(min_rto)+' '\
        +str(prob_cap_)+' '\
        +str(switchAlg)+' '\
        +str(DCTCP_K)+' '\
        +str(drop_prio_)+' '\
        +str(prio_scheme_)+' '\
        +str(deque_prio_)+' '\
        +str(keep_order_)+' '\
        +str(num_queue_)+' '\
        +str(ECN_scheme_)+' '\
        +str(queue_thresh_0[queue_thresh_ind])+' '\
        +str(queue_thresh_1[queue_thresh_ind])+' '\
        +str(queue_thresh_2[queue_thresh_ind])+' '\
        +str(queue_thresh_3[queue_thresh_ind])+' '\
        +str(queue_thresh_4[queue_thresh_ind])+' '\
        +str(queue_thresh_5[queue_thresh_ind])+' '\
        +str(queue_thresh_6[queue_thresh_ind])+' '\
        +str(topology_spt)+' '\
        +str(topology_tors)+' '\
        +str(topology_spines)+' '\
        +str(topology_x)+' '\
        +str('./'+dir_name+'/flow.tr')+' '\
        +str(pf_ddl_en)+' '\
        +str(early_detect)+' '\
        +str(pias_enable)+' '\
        +str(karuna_enable)+' '\
        +str(tr_dir_prefix)+' '\
		+str(dir_name)+' '\
        +str(pfabric_enable)+' >'\
        +str('./'+dir_name+'/log.tr')
print DCTCP_K
q.put([cmd, dir_name])

# create all worker threads
threads = []
number_worker_threads = 1

# start threads to process jobs
for i in range(number_worker_threads):
    t = threading.Thread(target = worker)
    threads.append(t)
    t.start()

# join all completed threads
for t in threads:
    t.join()
