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
		interface Timer<TMilli> as ForwardTimer;
		interface Timer<TMilli> as ForwardAvgTimer;
		
		interface Random;

	}
	
}

implementation{
	
	bool busy = FALSE;
	
//	collect_t collect;
//	message_t avgMsg;

	message_t pkt;
//	AvgMsg* avgpkt;
//	CollectMsg* cmpkt;
	CollectMsg collectpkt;
	AvgMsg avgmsgpkt;

	uint16_t local_id=0;
	
	am_addr_t prec_node=0;
	uint16_t msg_counter=0;
	
	uint16_t sumT = 0;
	uint16_t nT=0; //number of temperature reads
	uint16_t sumH = 0;
	uint16_t nH=0; //number of humidity reads
	
	uint16_t avgT = 0;
	uint16_t avgH = 0;

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
	dbg("default","%s | Node %d computed averages.\tAvgT = %d\tAvgH = %d\n", sim_time_string(), TOS_NODE_ID, avgT, avgH);

	
	if (!busy) {
		
      		avgpkt = 
			(AvgMsg*)(call Packet.getPayload(&pkt, sizeof(AvgMsg)));
      		if (avgpkt == NULL) return;
		local_id++;
      		avgpkt->node_id = TOS_NODE_ID;
      		avgpkt->humidity = avgH;
	  	avgpkt->temperature = avgT;
	  	avgpkt->local_id = local_id;
      		if (call AMSend.send(prec_node,
         			 &pkt, sizeof(AvgMsg)) == SUCCESS) {
        		busy = TRUE;
			dbg("default","%s | Node %d sent avgmsg local_id=%d to node %d.\tAvgT = %d\tAvgH = %d\n", sim_time_string(),  TOS_NODE_ID,avgpkt->local_id,prec_node,
	    			avgpkt->humidity, avgpkt->temperature);
      		
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
	  	cmpkt->msg_id = collectpkt.msg_id; 
      		if (call AMSend.send(AM_BROADCAST_ADDR,
          			&pkt, sizeof(CollectMsg)) == SUCCESS) {
        		busy = TRUE;
			dbg("default","%s | Node %d forwards collect message (id=%d) to broacast\n", sim_time_string(), 
	    			TOS_NODE_ID, cmpkt -> msg_id);
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
		from_id=avgmsgpkt.node_id;
	avgpkt->temperature=avgmsgpkt.temperature;
	avgpkt->humidity=avgmsgpkt.humidity;
	avgpkt->local_id=avgmsgpkt.local_id;
	avgpkt->node_id=avgmsgpkt.node_id;
	
      	if (call AMSend.send(prec_node,
          		&pkt, sizeof(AvgMsg)) == SUCCESS) {
        	busy = TRUE;
		dbg("default","%s | Node %d forwards average message from %d to node %d\n", sim_time_string(), 
	    		TOS_NODE_ID, avgpkt->node_id, prec_node);
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

	call RootTimer.startPeriodic(TMILLI_COLLECT);
	
}

event void Timer.fired(){
		post readTemperature(); 
		post readHumidity();
}

event void RootTimer.fired(){

	CollectMsg* cmpkt;

	if(TOS_NODE_ID==0){

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
				dbg("default","%s | ROOT sent collect message with id=%d\n", sim_time_string(), 
		    			cmpkt->msg_id);
	      }
	    }
	}
}

event void Temperature.readDone(error_t err, uint16_t val){
	if(err == SUCCESS){
		sumT = sumT + (val%12+1);
		nT++;
	//	dbg("default","%s | Node %d read temperature.\tSum = %d\tNumber = %d\n", sim_time_string(), TOS_NODE_ID, sumT, nT);
	}
}

event void Humidity.readDone(error_t err, uint16_t val){
	if(err == SUCCESS){
		sumH = sumH + (val%12+1);
		nH++;
	//	dbg("default","%s | Node %d read humidity.\tSum = %d\tNumber = %d\n", sim_time_string(), TOS_NODE_ID, sumH, nH);
	}
}

event message_t * Receive.receive(message_t * msg, void* payload, uint8_t len){
	CollectMsg* cmpkt;
	AvgMsg* avgpkt;
	am_addr_t sourceAddr;
	am_addr_t destAddr;
	sourceAddr = call AMPacket.source(msg);
	destAddr=call AMPacket.destination(msg);

	if(TOS_NODE_ID == 0){
	
		if (len == sizeof(AvgMsg)) {
     			avgpkt = (AvgMsg*)payload;
      			

      			dbg("default","%s | ROOT Received from %d, about node %d,\tavgH = %d,\tavgT = %d,\t(local_id=%d)\n", sim_time_string(), 
	  			sourceAddr, avgpkt->node_id, avgpkt->humidity, avgpkt->temperature, avgpkt->local_id);
    		}
    		return msg;
	}
	else{ 
		
   		if (len == sizeof(CollectMsg)) {
      			cmpkt = (CollectMsg*)payload;
     			dbg("default","%s | Node %d: Received from %d, collect with id= %d\n", sim_time_string(), TOS_NODE_ID,  sourceAddr, cmpkt->msg_id);
	  
	  		//controlla se è successivo
	  		if(cmpkt -> msg_id > msg_counter){
				prec_node = sourceAddr;
		  		msg_counter = cmpkt -> msg_id;
		  		collectpkt = *cmpkt;

				//post forwardCollect();
				//numberRnd = (call Random.rand16() % 100) + 1; 
				//call ForwardTimer.startOneShot(300+numberRnd); 
				call ForwardTimer.startOneShot(50+TOS_NODE_ID*15);
				//post sendDataAverage();
				//numberRnd = (call Random.rand16() % 177) + 1; 
				//call WaitTimer.startOneShot(2000+numberRnd);
				call WaitTimer.startOneShot(1300+TOS_NODE_ID*237);
	  			//dbg("default", "Random %d\n", numberRnd);
	  		}
    		}
		else if (len == sizeof(AvgMsg)) {
      			avgpkt = (AvgMsg*)payload;
			avgmsgpkt=*avgpkt;
      			dbg("default","%s | Node %d: Received from %d, avg about %d to be forwarded to %d\n", sim_time_string(), TOS_NODE_ID, sourceAddr, avgpkt->node_id, prec_node );
			
			if(destAddr == TOS_NODE_ID){
		  		//numberRnd = (call Random.rand16() % 177) + 1; 
				//call ForwardAvgTimer.startOneShot(1000+numberRnd);
				call ForwardAvgTimer.startOneShot(50);
		  		//se è indirizzato a lui 
		  		//post forwardAverage();
			}
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

event void ForwardTimer.fired(){
	post forwardCollect();
}
event void ForwardAvgTimer.fired(){
	post forwardAverage();
}

}
