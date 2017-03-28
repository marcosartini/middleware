#include "Timer.h"
#include "environment.h"

module EnvC{
	
	uses {
		
		interface Boot;
		interface Timer<TMilli>;
		interface Read<float> as Temperature;
		interface Read<float> as Humidity;
		interface DisseminationValue<collect_t> as CollectValue;
		
		interface Send as AvgRoot;
		interface StdControl as CollectionControl;
		interface StdControl as DisseminationControl;
		interface SplitControl as RadioControl;
		interface LowPowerListening;
	}
	
}

implementation{
	
	collect_t collect;
	message_t avgMsg;
	
	float sumT = 0;
	uint16_t nT=0; //number of temperature reads
	float sumH = 0;
	uint16_t nH=0; //number of humidity reads
	
	float avgT = 0;
	float avgH = 0;
	
task void readTemperature(){
	if(call Temperature.read() != SUCCESS)
		post readTemperature();
}
task void readHumidity(){
	if(call Humidity.read() != SUCCESS)
		post readHumidity();
}

task void computeAverages(){
	avgT = sumT/nT; //controllare taglio divisione
	avgH = sumH/nH; //controllare taglio divisione
	dbg("default","%s | Node %d computed averages. AvgT = %f. AvgH = %f\n", sim_time_string(), TOS_NODE_ID, avgT, avgH);
}

event void Boot.booted(){
	dbg("default","%s | Node %d started\n", sim_time_string(), TOS_NODE_ID);
	// Initialize app here
	if(call RadioControl.start() != SUCCESS){
		//call Leds.led0On();
	}
	
	//Starting the timer
	call Timer.startPeriodic(TMILLI_PERIOD);
}

event void Timer.fired(){
		post readTemperature(); 
		post readHumidity();
}

event void Temperature.readDone(error_t err, float val){
	if(err == SUCCESS){
		sumT = sumT + val;
		nT++;
		dbg("default","%s | Node %d read temperature. Sum = %f. Number = %d\n", sim_time_string(), TOS_NODE_ID, sumT, nT);
	}
}

event void Humidity.readDone(error_t err, float val){
	if(err == SUCCESS){
		sumH = sumH + val;
		nH++;
		dbg("default","%s | Node %d read humidity. Sum = %f. Number = %d\n", sim_time_string(), TOS_NODE_ID, sumH, nH);
	}
}

event void CollectValue.changed(){
	const collect_t *newCollect = call CollectValue.get();
	
	if (*newCollect.msg_id>collect.msg_id){ //forse
	collect = *newCollect;
	
	post computeAverages();
	avg_t *newAvg = call AvgRoot.getPayload(&avgMsg, sizeof(avg_t));
	if (newAvg != NULL){
		newAvg -> temperature = avgT;
		newAvg -> humidity = avgH;
		newAvg -> node_id = TOS_NODE_ID;
		check(call AvgRoot.send(&avgMsg, sizeof *newAvg));
	}
	}
}

event void AvgRoot.sendDone(message_t *msg, error_t ok){
	
	avgH = 0;
	avgT = 0;
	nH = 0;
	nT = 0;
	
}

 event void RadioControl.startDone(error_t ok) {
    if (ok == SUCCESS)
      {
	call DisseminationControl.start();
	call CollectionControl.start();
	call LowPowerListening.setLocalWakeupInterval(512);
	dbg("default","%s | Node %d RadioControl.startDone\n", sim_time_string(), TOS_NODE_ID);
      }
  }

  event void RadioControl.stopDone(error_t ok) { }



}