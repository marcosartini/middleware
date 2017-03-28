#include "Timer.h"
#include "./Nodes/environment.h"

module EnvRootC{
	
	uses {
		
		interface Boot;
		interface Timer<TMilli>;
		interface DisseminationUpdate<collect_t> as CollectUpdate;
		
		interface StdControl as CollectionControl;
		interface StdControl as DisseminationControl;
		interface RootControl;
		interface Receive as AvgReceive;
		
		interface SplitControl as RadioControl;
		interface LowPowerListening;
		
	}
}

implementation{
	
	uint32_t counter = 0;
	
event void Boot.booted()
  {
    call RadioControl.start();
  }
  
event void RadioControl.startDone(error_t error) {
    /* Once the radio has started, we can setup low-power listening, and
       start the collection and dissemination services. Additionally, we
       set ourselves as the (sole) root for the avg dissemination
       tree */
    if (error == SUCCESS)
      {
	call LowPowerListening.setLocalWakeupInterval(512);
	call DisseminationControl.start();
	call CollectionControl.start();
	call RootControl.setRoot();
	call Timer.startPeriodic(TMILLI_PERIOD);
      }
  }
  
event void RadioControl.stopDone(error_t error) { }

event void Timer.fired(){
		counter++;
		collect_t *newCollect.msg_id = counter;
		call CollectUpdate.change(newCollect);
}

event message_t *AvgReceive.receive(message_t* msg, void* payload, uint8_t len){
	
	avg_t *newAvg = payload;
	
	if(len == sizeof(*newAvg){
	
	dbg("default","%s | Node %d recived this values:\nFrom: %d, T=%d, H=%d", sim_time_string(), TOS_NODE_ID, newAvg->node_id, newAvg -> temperature, newAvg -> humidity);
	
	}
}
	
}