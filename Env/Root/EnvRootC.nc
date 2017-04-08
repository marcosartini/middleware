#include "Timer.h"
#include "../Nodes/environment.h"

module EnvRootC{
	
	uses {
		
		interface Boot;
		interface Timer<TMilli>;

		interface Receive;
		interface AMPacket;
		interface AMSend;
		interface Packet;
				
		interface SplitControl as RadioControl;

		
	}
}

implementation{
	
	uint32_t counter = 0;
	message_t pkt;
	bool busy = FALSE;
	
event void Boot.booted()
  {
    call RadioControl.start();
  }
  
event void RadioControl.startDone(error_t error) {
   
    if (error == SUCCESS)
      {
	//call RootControl.setRoot();
	call Timer.startPeriodic(TMILLI_PERIOD);
      }
  }
  
event void RadioControl.stopDone(error_t error) { }

event void Timer.fired(){
		counter++;
		if (!busy) {
      CollectMsg* cmpkt = 
	(CollectMsg*)(call Packet.getPayload(&pkt, sizeof(CollectMsg)));
      if (cmpkt == NULL) return;
      cmpkt->sender_id = TOS_NODE_ID;
      cmpkt->msg_id = counter;
	  
      if (call AMSend.send(AM_BROADCAST_ADDR,
          &pkt, sizeof(CollectMsg)) == SUCCESS) {
        busy = TRUE;
	dbg("default","%s | Sent collect message with id=%d from %d\n", sim_time_string(), 
	    counter, TOS_NODE_ID);
      }
    }

}

event message_t *Receive.receive(message_t* msg, void* payload, uint8_t len){
	
	am_addr_t sourceAddr;
	uint8_t avgH;
	uint8_t avgT;
	uint32_t local_id;

    if (len == sizeof(AvgMsg)) {
      AvgMsg* avgpkt = (AvgMsg*)payload;
      
      sourceAddr = call AMPacket.source(msg);
	  avgH = avgpkt->humidity;
	  avgT = avgpkt->temperature;
	  local_id = avgpkt->local_id;
      dbg("default","%s | Received from %d, avgH = %d, avgT = %d (local_id=%d)\n", sim_time_string(), 
	  sourceAddr, avgH, avgT, local_id);
    }
    return msg;
	
}


event void AMSend.sendDone(message_t* msg, error_t err) {
    if (&pkt == msg) busy = FALSE;
  }
	
}
