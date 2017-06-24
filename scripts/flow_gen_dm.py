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

if len(sys.argv) != 5:
    print 'invalid arguments!'
    sys.exit(0)



nflows = 100000
link_rate = 10 # in Gpbs
#load_arr = [0.9, 0.8, 0.7, 0.6, 0.5]
load_arr = [0.9, 0.85, 0.8, 0.75]
ddl_load_arr = [0.75]
#ddl_load_arr = [0.85, 1.2]
connections_per_pair = 1
meanFlowSize = 5117*1460 # in B
flow_cdf = 'CDF_datamining.tcl'

topology_spt = 16
topology_tors = 9
topology_spines = 4

#ns_path = '/usr/wtao/workspace/project-dct-build/ns-allinone-2.34/ns-2.34/ns'
ns_path = '/users/wtao0221/project-dct-build/ns-allinone-2.34/ns-2.34/ns'
#ns_path = '/home/wtao/project-dct-build/ns-allinone-2.34/ns-2.34/ns'
sim_script = 'traffic-generator.tcl'


endtime = 61
gen_type = 0 # 0 is for sim_end, 1 is for endtime 
pf_gen = 0 # 0 is karuna way, 1 is pfabric way
mean_ddl = 100 # only effective when pf_gen is set to 1

initcwnd = int(sys.argv[1])
maxcwnd = int(sys.argv[2])
mean_link_delay = float(sys.argv[3])
host_delay = float(sys.argv[4])


# put commands to job queue
for i in range(len(load_arr)):
    for j in range(len(ddl_load_arr)):

        #if ddl_load_arr[j] > load_arr[i]:
        #    continue

        dir_name = 'flow-trace/dm_%d_%d' % (int(load_arr[i]*100), int(ddl_load_arr[j]*100))

        dir_name = dir_name.lower()

        # simulation command
        cmd = ns_path+' '+sim_script+' '\
		+str(nflows)+' '\
                +str(meanFlowSize)+' '\
                +str(flow_cdf)+' '\
                +str(link_rate)+' '\
                +str(load_arr[i])+' '\
		+str(ddl_load_arr[j])+' '\
                +str(topology_spt)+' '\
                +str(topology_tors)+' '\
                +str(dir_name)+' '\
		+str(connections_per_pair)+' '\
                +str('./'+dir_name+'/sumflow.tr')+' '\
                +str(endtime)+' '\
                +str(gen_type)+' '\
                +str(topology_spines)+' '\
                +str(pf_gen)+' '\
                +str(mean_ddl)+' '\
                +str(initcwnd)+' '\
                +str(maxcwnd)+' '\
                +str(mean_link_delay)+' '\
                +str(host_delay)+' >'\
                +str('./'+dir_name+'/log.tr')
        
        q.put([cmd, dir_name])

# create all worker threads
threads = []
number_worker_threads = 3

# start threads to process jobs
for i in range(number_worker_threads):
    t = threading.Thread(target = worker)
    threads.append(t)
    t.start()

# join all completed threads
for t in threads:
    t.join()
