#!/usr/bin/python

import os
TOSDIR = os.getenv("TOSDIR") #here the path of the TOS directory in the system. Change if problems arise

N_MOTES = 14 #14
SIM_TIME = 500 #500

DBG_CHANNELS = "error" #add to this string: <radio> to see radio activity, <internal> to see data sampling
TOPO_FILE = "linkgain.out"
NOISE_FILE = TOSDIR+"/lib/tossim/noise/meyer-heavy.txt"

from TOSSIM import *
from tinyos.tossim.TossimApp import *
from random import *
import sys

counter_root_prec = 1
max_v = 0
min_v = 2000
max_msg = 0
min_msg = 2000
somma_totale = 0
somma_parziale = 0
ricevuti_root = 0
ricevuti_tot = 0
counter_root= 0
collect_timer = 0

n = NescApp("EnvC", "app.xml")
vars = n.variables.variables()
t = Tossim(vars) #[]
r = t.radio()

t.randomSeed(1)

for channel in DBG_CHANNELS.split():
    t.addChannel(channel, sys.stdout)


#add gain links
f = open(TOPO_FILE, "r")
lines = f.readlines()

for line in lines:
    s = line.split()
    if (len(s) > 0):
        if s[0] == "gain":
            r.add(int(s[1]), int(s[2]), float(s[3]))
        elif s[0] == "noise":
            r.setNoise(int(s[1]), float(s[2]), float(s[3]))
	
#add noise trace
noise = open(NOISE_FILE, "r")
lines = noise.readlines()
for line in lines:
    str = line.strip()
    if (str != ""):
        val = int(float(str))
       	for i in range(0, N_MOTES):
            t.getNode(i).addNoiseTraceReading(val)


for i in range (0, N_MOTES):
    time=i * t.ticksPerSecond() / 100
    m=t.getNode(i)
    time=0
    m.bootAtTime(time)
    m.createNoiseModel()
    print "Booting ", i, " at ~ ", time*1000/t.ticksPerSecond(), "ms"

ma = t.getNode(0)
v = ma.getVariable("EnvC.counter")
va = ma.getVariable("EnvC.received_counter")

rc_list = list()
for i in range(0, N_MOTES):
            rc_list.append(t.getNode(i).getVariable("EnvC.tx_msgs"))

time = t.time()
lastTime = -1
while (time + SIM_TIME * t.ticksPerSecond() > t.time()):
    timeTemp = int(t.time()/(t.ticksPerSecond()*10))
    if( timeTemp > lastTime ): #stampa un segnale ogni 10 secondi... per leggere meglio il log
        lastTime = timeTemp
        print "----------------------------------SIMULATION: ~", lastTime*10, " s ----------------------"
    
    counter_root=v.getData()
    
    if (counter_root>counter_root_prec):
        counter_root_prec=counter_root
        ricevuti_root=va.getData()
        if (ricevuti_root > max_v):
            max_v = ricevuti_root
        if (ricevuti_root < min_v):
            min_v = ricevuti_root
        ricevuti_tot += ricevuti_root
        somma_parziale=0
        for vv in rc_list:
            somma_parziale += vv.getData()
        somma_parziale -= somma_totale #toglie l'accumulo
        somma_totale+=somma_parziale
        if (somma_parziale < min_msg):
            min_msg = somma_parziale
        if (somma_parziale > max_msg):
            max_msg = somma_parziale
        print "\n\nCollect #",counter_root-1," | Root received from:", ricevuti_root, "motes, Exchanged messages:", somma_parziale, "\n\n"
        

    t.runNextEvent()
print "----------------------------------END OF SIMULATION-------------------------------------"

avg=1.0*ricevuti_tot/(counter_root-1)
print "\n##### RESULTS ANALYSIS #####\n"
print "Simulation with 1 root mote and",N_MOTES-1, "scattered motes\n"

print "Max responding motes:\t\t", max_v, "\t","{0:.2f}".format((1.0*max_v/(N_MOTES-1))*100), "%"
print "Min responding motes:\t\t", min_v, "\t","{0:.2f}".format((1.0*min_v/(N_MOTES-1))*100), "%"
print "Average responding motes:\t", "{0:.2f}".format(avg), "\t","{0:.2f}".format((avg/(N_MOTES-1))*100), "%  <---"
print "Max exchanged messages:\t\t", max_msg
print "Min exchanged messages:\t\t", min_msg
print "Average exchanged messages:\t", "{0:.2f}".format((1.0*somma_totale/counter_root))
print "Total exchanged messages:\t", somma_totale,"\n"

if(max_v < N_MOTES-1):
    print "Root never received data from all the scattered motes\n"
else:
    print "At least once, root received data from all the scattered motes\n"
