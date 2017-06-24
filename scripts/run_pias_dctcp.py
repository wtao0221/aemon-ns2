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

if len(sys.argv) != 13:
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
meanFlowSize = 1138*1460 # in B
paretoShape = 1.05
flow_cdf = 'CDF_websearch.tcl'

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

switchAlg = 'PriorityQueue'
DCTCP_K = float(sys.argv[10]) 
drop_prio_ = 'true'
prio_scheme_ = 2
deque_prio_ = 'true'
keep_order_ = 'true'
num_queue_ = int(sys.argv[11])
ECN_scheme_ = 2 # per-port ECN marking
# Tao: here we simply copy the pias thresholds at this time
queue_thresh_ind = int(sys.argv[12])
queue_thresh_0 = [759*1460, 909*1460, 999*1460, 956*1460, 1059*1460]
queue_thresh_1 = [1132*1460, 1329*1460, 1305*1460, 1381*1460, 1412*1460]
queue_thresh_2 = [1456*1460, 1648*1460, 1564*1460, 1718*1460, 1643*1460]
queue_thresh_3 = [1737*1460, 1960*1460, 1763*1460, 2028*1460, 1869*1460]
queue_thresh_4 = [2010*1460, 2143*1460, 1956*1460, 2297*1460, 2008*1460]
queue_thresh_5 = [2199*1460, 2337*1460, 2149*1460, 2551*1460, 2115*1460]
queue_thresh_6 = [2325*1460, 2484*1460, 2309*1460, 2660*1460, 2184*1460]

topology_spt = 16
topology_tors = 9
topology_spines = 4
topology_x = 1

#newly added
pf_ddl_en = 0
early_detect = 0
pias_enable = 1
karuna_enable = 0
pfabric_enable = 0

#ns_path = '/usr/wtao/workspace/project-dct-build/ns-allinone-2.34/ns-2.34/ns'
ns_path = '/users/wtao0221/project-dct-build/ns-allinone-2.34/ns-2.34/ns'
#ns_path = '/home/wtao/project-dct-build/ns-allinone-2.34/ns-2.34/ns'
sim_script = 'spine_empirical_load.tcl'

# put commands to job queue
scheme = 'unknown'
if num_queue_ > 1 and sourceAlg == 'DCTCP-Sack':
    if karuna_enable == 1:
        scheme = 'karuna'
    elif pias_enable == 1:
        scheme = 'pias'
    else:
        if early_detect == 1:
            scheme = 'daed'
        else:
            scheme = 'da'

if scheme == 'unknown':
    print 'unknown scheme'
    sys.exit(0)

dir_name = 'websearch_%s_%d_%d_%d' % (scheme, int(num_queue_),\
        int(load_arr*100), int(ddl_load_arr*100))
dir_name = dir_name.lower()

tr_dir_prefix = 'flow-trace/web_%d_%d' % (int(load_arr*100), int(ddl_load_arr*100))

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
