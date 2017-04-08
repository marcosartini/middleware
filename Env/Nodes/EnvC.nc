#include "Timer.h"
#include "environment.h"

module EnvC{
	
	uses {
		
		interface Boot;
		interface Timer<TMilli>;
		interface Read<uint16_t> as Temperature;
		interface Read<uint16_t> as Humidity;

		
		interface AMSend;
		interface Receive;
		interface AMPacket;
		interface Packet;

		interface SplitControl as RadioControl;

		interface Timer<TMilli> as RootTimer;
		interface Timer<TMilli> as WaitTimer;
		
		interface Random;

	}
	
}

implementation{
	
	bool busy = FALSE;
	
//	collect_t collect;
//	message_t avgMsg;

	message_t pkt;

	uint16_t local_id=1;
	
	am_addr_t prec_node=0;
	uint16_t msg_counter=0;
	
	uint16_t sumT = 0;
	uint16_t nT=0; //number of temperature reads
	uint16_t sumH = 0;
	uint16_t nH=0; //number of humidity reads
	
	float avgT = 0;
	float avgH = 0;

	uint32_t counter = 0;
	uint16_t numberRnd=0;
	
task void readTemperature(){
	if(call Temperature.read() != SUCCESS)
		post readTemperature();
}
task void readHumidity(){
	if(call Humidity.read() != SUCCESS)
		post readHumidity();
}

task void sendDataAverage (){
	AvgMsg* avgpkt;

	//computes the averages
	
	avgT = sumT/nT; 
	avgH = sumH/nH; 
	dbg("default","%s | Node %d computed averages. AvgT = %d AvgH = %d\n", sim_time_string(), TOS_NODE_ID, avgT, avgH);

	
	if (!busy) {
		
      		avgpkt = 
			(AvgMsg*)(call Packet.getPayload(&pkt, sizeof(AvgMsg)));
      		if (avgpkt == NULL) return;
		local_id++;
		dbg("default", "Incremented local_id=%d\n", local_id);
      		avgpkt->node_id = TOS_NODE_ID;
      		avgpkt->humidity = avgH;
	  	avgpkt->temperature = avgT;
	  	avgpkt->local_id = local_id;
      		if (call AMSend.send(prec_node,
         			 &pkt, sizeof(AvgMsg)) == SUCCESS) {
        		busy = TRUE;
			dbg("default","%s | Sent AvgT = %d AvgH = %d from node %d\n", sim_time_string(), 
	    			avgH, avgT, TOS_NODE_ID);
      		
		sumH = 0;
		sumT = 0;
		avgH = 0;
		avgT = 0;
		nH = 0;
		nT = 0;

	}
		
    }
	
}

task void forwardCollect (){
	CollectMsg* cmpkt;

	if (!busy) {
      		cmpkt = 
			(CollectMsg*)(call Packet.getPayload(&pkt, sizeof(CollectMsg)));
      		if (cmpkt == NULL) return;
      		cmpkt->sender_id = TOS_NODE_ID;
	  
      		if (call AMSend.send(AM_BROADCAST_ADDR,
          			&pkt, sizeof(CollectMsg)) == SUCCESS) {
        		busy = TRUE;
			dbg("default","%s | Forwarded collect message from node %d to broacast\n", sim_time_string(), 
	    			TOS_NODE_ID);
      }
    }
	
}


task void forwardAverage(){
	uint32_t from_id;
	AvgMsg* avgpkt;

	if (!busy) {
       		avgpkt = 
			(AvgMsg*)(call Packet.getPayload(&pkt, sizeof(AvgMsg)));
      	if (avgpkt == NULL) return;
	from_id=avgpkt->node_id;
      	if (call AMSend.send(prec_node,
          		&pkt, sizeof(AvgMsg)) == SUCCESS) {
        	busy = TRUE;
		dbg("default","%s | Forwarded average message from node %d through node %d\n", sim_time_string(), 
	    		from_id, TOS_NODE_ID);
      }
    }
	
}

event void Boot.booted(){
	dbg("default","%s | Node %d started\n", sim_time_string(), TOS_NODE_ID);
	// Initialize app here
	if(call RadioControl.start() != SUCCESS){
		//call Leds.led0On();
	}
	
	//Starting the timer
	call Timer.startPeriodic(TMILLI_PERIOD);

	call RootTimer.startPeriodic(TMILLI_PERIOD * 3);
}

event void Timer.fired(){
		post readTemperature(); 
		post readHumidity();
}

event void RootTimer.fired(){
	CollectMsg* cmpkt;
	counter++;	

	if (!busy) {
      		cmpkt = 
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

event void Temperature.readDone(error_t err, uint16_t val){
	if(err == SUCCESS){
		sumT = sumT + val;
		nT++;
		dbg("default","%s | Node %d read temperature. Sum = %d. Number = %d\n", sim_time_string(), TOS_NODE_ID, sumT, nT);
	}
}

event void Humidity.readDone(error_t err, uint16_t val){
	if(err == SUCCESS){
		sumH = sumH + val;
		nH++;
		dbg("default","%s | Node %d read humidity. Sum = %d. Number = %d\n", sim_time_string(), TOS_NODE_ID, sumH, nH);
	}
}

event message_t * Receive.receive(message_t * msg, void* payload, uint8_t len){
	CollectMsg* cmpkt;
	AvgMsg* avgpkt;
	am_addr_t sourceAddr;
	uint16_t loc_id=-1;

	if(TOS_NODE_ID == 0){
	
		if (len == sizeof(AvgMsg)) {
     			avgpkt = (AvgMsg*)payload;
      			sourceAddr = call AMPacket.source(msg);
	  		avgH = avgpkt->humidity;
	  		avgT = avgpkt->temperature;
	  		loc_id = avgpkt->local_id;
      			dbg("default","%s | Received from %d, avgH = %d, avgT = %d, (local_id=%d)\n", sim_time_string(), 
	  			sourceAddr, avgH, avgT, loc_id);
    		}
    		return msg;
	}
	else{ 
		sourceAddr = call AMPacket.source(msg);
   		if (len == sizeof(CollectMsg)) {
      			cmpkt = (CollectMsg*)payload;
     			dbg("default","%s | Node %d: Received from %d, collect with id= %d\n", sim_time_string(), TOS_NODE_ID,  sourceAddr, cmpkt->msg_id);
	  
	  		//controlla se è successivo
	  		if(cmpkt -> msg_id > msg_counter){
		  		msg_counter = cmpkt -> msg_id;
		  		prec_node = sourceAddr;
	  			post forwardCollect();
				numberRnd = (call Random.rand16() % 100) + 1; 
				call WaitTimer.startOneShot(100+numberRnd);
	  			//dbg("default", "Random %d\n", numberRnd);
	  		}
    		}
		else if (len == sizeof(AvgMsg)) {
      			avgpkt = (AvgMsg*)payload;

      			dbg("default","%s | Node %d: Received from %d, avg to be forwarded to %d\n", sim_time_string(), sourceAddr, prec_node );
	  
	  		//se è indirizzato a lui 
	  		post forwardAverage();
    		}
    	return msg;

	}
	
}




event void AMSend.sendDone(message_t *msg, error_t ok){

//dbg("default","%s | Node %d AMSend.sendDone %s\n%s\n", sim_time_string(), TOS_NODE_ID, ;
	
	 if (&pkt == msg) busy = FALSE;
	 

	
}

 event void RadioControl.startDone(error_t ok) {
    if (ok == SUCCESS)
      {

	dbg("default","%s | Node %d RadioControl.startDone\n", sim_time_string(), TOS_NODE_ID);
      }
  }

  event void RadioControl.stopDone(error_t ok) { }

event void WaitTimer.fired(){
	post sendDataAverage();
}

}
