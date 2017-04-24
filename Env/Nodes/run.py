#!/usr/bin/python

N_MOTES = 14 #14
DBG_CHANNELS = "default error"
SIM_TIME = 500 #500
TOPO_FILE = "linkgain.out"
#NOISE_FILE = "/opt/tinyos-2.1.0/tos/lib/tossim/noise/casino-lab.txt"
NOISE_FILE = "/home/marco/tinyos-release-tinyos-2_1_2/tos/lib/tossim/noise/meyer-heavy.txt"

from TOSSIM import *
from tinyos.tossim.TossimApp import *
from random import *
import sys

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

counter_root_prec = 1
max_v = 0
min_v = 100
somma_totale = 0
somma_parziale = 0
ricevuti_root = 0
ricevuti_tot = 0
counter_root= 0
collect_timer = 0

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

        print "\n\nCollect #",counter_root-1," | Root received from:", ricevuti_root, "motes, Exchanged messages:", somma_parziale, "\n\n"
        

    t.runNextEvent()
print "----------------------------------END OF SIMULATION-------------------------------------"

avg=1.0*ricevuti_tot/(counter_root-1)
print "\n##### RESULTS ANALYSIS #####\n"
print "Simulation with 1 root mote and",N_MOTES-1, "scattered motes\n"

print "Max responding motes:\t", max_v, "\t","{0:.2f}".format((1.0*max_v/(N_MOTES-1))*100), "%"
print "Min responding motes:\t", min_v, "\t","{0:.2f}".format((1.0*min_v/(N_MOTES-1))*100), "%"
print "In average responding:\t", avg, "\t","{0:.2f}".format((avg/(N_MOTES-1))*100), "%"
print "Total exchanged messages:\t", somma_totale
print "Average exchanged messages:\t", "{0:.2f}".format((1.0*somma_totale/counter_root)), "\n\n"
