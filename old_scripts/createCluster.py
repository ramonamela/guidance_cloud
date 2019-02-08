#!/usr/bin/env python

import subprocess
import inspect, os


script_directory = os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))

amountOfNodes = subprocess.check_output("cat " + script_directory + "/configure.sh | grep amountOfNodes | tr -d \\\" | tr \"=\" \"\t\" | awk \'{ print $2 }\'", shell=True)
amountOfNodes = int(amountOfNodes.split()[0])

command_to_run = script_directory + "/removeCluster.sh"
subprocess.call(command_to_run)

procs = []

for i in xrange(1, amountOfNodes + 1):
    command_to_run = script_directory + "/createClusterNode.sh " + str(i)
    procs.append(subprocess.Popen(command_to_run.split()))

outputs = []
for i in xrange(amountOfNodes):
    outputs.append(procs[i].communicate())

print(outputs)
#print(int(amountOfNodes.split()[0]))
#print(int(amountOfNodes.split()[0]))