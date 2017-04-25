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
	
	message_t pkt;
	collect_t collectpkt;
	avg_t avg_tpkt;

	uint16_t received_counter = 0;
	
	uint16_t tx_msgs = 0;

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
	avg_t* avgpkt;

	//computes the averages
	
	avgT = sumT/nT; 
	avgH = sumH/nH; 
	dbg("internal","%s | Node %d computed averages.\tAvgT = %d\tAvgH = %d\n", sim_time_string(), TOS_NODE_ID, avgT, avgH);

	
	if (!busy) {
		
      		avgpkt = 
			(avg_t*)(call Packet.getPayload(&pkt, sizeof(avg_t)));
      		if (avgpkt == NULL) return;
		local_id++;
      		avgpkt->node_id = TOS_NODE_ID;
      		avgpkt->humidity = avgH;
	  	avgpkt->temperature = avgT;
	  	avgpkt->local_id = local_id;
      		if (call AMSend.send(prec_node,
         			 &pkt, sizeof(avg_t)) == SUCCESS) {
        		busy = TRUE;
			dbg("radio","%s | Node %d sent avg_t local_id=%d to node %d.\tAvgT = %d\tAvgH = %d\n", sim_time_string(),  TOS_NODE_ID,avgpkt->local_id,prec_node,
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
	collect_t* cmpkt;

	if (!busy) {
      		cmpkt = 
			(collect_t*)(call Packet.getPayload(&pkt, sizeof(collect_t)));
      		if (cmpkt == NULL) return;
      		cmpkt->sender_id = TOS_NODE_ID;
	  	cmpkt->msg_id = collectpkt.msg_id; 
      		if (call AMSend.send(AM_BROADCAST_ADDR,
          			&pkt, sizeof(collect_t)) == SUCCESS) {
        		busy = TRUE;
			dbg("radio","%s | Node %d forwards collect message (id=%d) to broacast\n", sim_time_string(), 
	    			TOS_NODE_ID, cmpkt -> msg_id);
      }
    }
	
}


task void forwardAverage(){
	
	avg_t* avgpkt;

	if (!busy) {
       		avgpkt = 
			(avg_t*)(call Packet.getPayload(&pkt, sizeof(avg_t)));
      	if (avgpkt == NULL) return;
		
	avgpkt->temperature=avg_tpkt.temperature;
	avgpkt->humidity=avg_tpkt.humidity;
	avgpkt->local_id=avg_tpkt.local_id;
	avgpkt->node_id=avg_tpkt.node_id;
	
      	if (call AMSend.send(prec_node,
          		&pkt, sizeof(avg_t)) == SUCCESS) {
        	busy = TRUE;
		dbg("radio","%s | Node %d forwards average message from %d to node %d\n", sim_time_string(), 
	    		TOS_NODE_ID, avgpkt->node_id, prec_node);
      }
    }
	
}

event void Boot.booted(){
	dbg("internal","%s | Node %d started\n", sim_time_string(), TOS_NODE_ID);
	// Initialize app here
	if(call RadioControl.start() != SUCCESS){
		dbgerror("error", "Error in booting");
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

	collect_t* cmpkt;

	if(TOS_NODE_ID==0){

		counter++;		

		if (!busy) {
	      		cmpkt = 
				(collect_t*)(call Packet.getPayload(&pkt, sizeof(collect_t)));
	      		if (cmpkt == NULL) return;
	      		cmpkt->sender_id = TOS_NODE_ID;
	      		cmpkt->msg_id = counter;
		  
	      		if (call AMSend.send(AM_BROADCAST_ADDR,
		  			&pkt, sizeof(collect_t)) == SUCCESS) {
				busy = TRUE;

				dbg("radio","%s | ROOT sent collect message with id=%d\n", sim_time_string(), 
		    			cmpkt->msg_id);
				
	      }
	    }
	}
}

event void Temperature.readDone(error_t err, uint16_t val){
	if(err == SUCCESS){
		sumT = sumT + (val%12+1);
		nT++;
		dbg("internal","%s | Node %d read temperature.\tSum = %d\tNumber = %d\n", sim_time_string(), TOS_NODE_ID, sumT, nT);
	}
}

event void Humidity.readDone(error_t err, uint16_t val){
	if(err == SUCCESS){
		sumH = sumH + (val%12+1);
		nH++;
		dbg("internal","%s | Node %d read humidity.\tSum = %d\tNumber = %d\n", sim_time_string(), TOS_NODE_ID, sumH, nH);
	}
}

event message_t * Receive.receive(message_t * msg, void* payload, uint8_t len){
	collect_t* cmpkt;
	avg_t* avgpkt;
	am_addr_t sourceAddr;
	am_addr_t destAddr;
	sourceAddr = call AMPacket.source(msg);
	destAddr=call AMPacket.destination(msg);

	if(TOS_NODE_ID == 0){
	
		if (len == sizeof(avg_t)) {
     			avgpkt = (avg_t*)payload;
      			
      			received_counter++;
      			dbg("radio","%s | ROOT Received from %d, about node %d,\tavgH = %d,\tavgT = %d,\t(local_id=%d)\n", sim_time_string(), 
	  			sourceAddr, avgpkt->node_id, avgpkt->humidity, avgpkt->temperature, avgpkt->local_id);
    		}
    		return msg;
	}
	else{ 
		
   		if (len == sizeof(collect_t)) {
      			cmpkt = (collect_t*)payload;
     			dbg("radio","%s | Node %d: Received from %d, collect with id= %d\n", sim_time_string(), TOS_NODE_ID,  sourceAddr, cmpkt->msg_id);
	  
	  		//checks if the received message is a new message
	  		if(cmpkt -> msg_id > msg_counter){
				prec_node = sourceAddr;
		  		msg_counter = cmpkt -> msg_id;
		  		collectpkt = *cmpkt;

				//numberRnd = (call Random.rand16() % 100) + 1; 
				//call ForwardTimer.startOneShot(300+numberRnd); 
				call ForwardTimer.startOneShot(80+TOS_NODE_ID*15);
			
				//numberRnd = (call Random.rand16() % 177) + 1; 
				//call WaitTimer.startOneShot(2000+numberRnd);
				//call WaitTimer.startOneShot(1300+TOS_NODE_ID*237);
				//call WaitTimer.startOneShot(1300+TOS_NODE_ID*257+200/1.0*prec_node);
				call WaitTimer.startOneShot(1300+TOS_NODE_ID*250);
				//call WaitTimer.startOneShot(500+TOS_NODE_ID*250);
	  		}
    		}
		else if (len == sizeof(avg_t)) {
      			avgpkt = (avg_t*)payload;
			avg_tpkt=*avgpkt;
      			dbg("radio","%s | Node %d: Received from %d, avg about %d to be forwarded to %d\n", sim_time_string(), TOS_NODE_ID, sourceAddr, avgpkt->node_id, prec_node );
			
			if(destAddr == TOS_NODE_ID){
		  		//numberRnd = (call Random.rand16() % 177) + 1; 
				//call ForwardAvgTimer.startOneShot(1000+numberRnd);
				call ForwardAvgTimer.startOneShot(50);
			}
    		}
    	return msg;
	}
	
}




event void AMSend.sendDone(message_t *msg, error_t ok){

dbg("internal","%s | Node %d AMSend.sendDone\n", sim_time_string(), TOS_NODE_ID);
	
	 if (&pkt == msg){
		tx_msgs ++;
		received_counter = 0;
		busy = FALSE;
	}

	
}

 event void RadioControl.startDone(error_t ok) {
    if (ok == SUCCESS)
      {
	dbg("internal","%s | Node %d RadioControl.startDone\n", sim_time_string(), TOS_NODE_ID);
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
