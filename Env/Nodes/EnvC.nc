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

	}
	
}

implementation{
	
	bool busy = FALSE;
	
	collect_t collect;
	message_t avgMsg;
	
	uint32_t local_id=0;
	
	am_addr_t prec_node;
	uint32_t msg_counter=0;
	
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

//DA TOGLIERE questo task
task void computeAverages(){
	avgT = sumT/nT; //controllare taglio divisione
	avgH = sumH/nH; //controllare taglio divisione
	dbg("default","%s | Node %d computed averages. AvgT = %f. AvgH = %f\n", sim_time_string(), TOS_NODE_ID, avgT, avgH);
}

task void sendDataAverage (){
	
	//computes the averages
	
	avgT = sumT/nT; //controllare taglio divisione
	avgH = sumH/nH; //controllare taglio divisione
	dbg("default","%s | Node %d computed averages. AvgT = %f. AvgH = %f\n", sim_time_string(), TOS_NODE_ID, avgT, avgH);

	
	if (!busy) {
      AvgMsg* avgpkt = 
	(AvgMsg*)(call Packet.getPayload(&pkt, sizeof(AvgMsg)));
      if (avgpkt == NULL) return;
      avgpkt->node_id = TOS_NODE_ID;
      avgpkt->humidity = avgH;
	  avgpkt->temperature = avgT;
	  local_id ++;
	  avgpkt->local_id = local_id;
      if (call AMSend.send(prec_node,
          &pkt, sizeof(AvgMsg)) == SUCCESS) {
        busy = TRUE;
	dbg("default","%s | Sent AvgT = %f. AvgH = %f from node %d\n", sim_time_string(), 
	    avgH, avgT, TOS_NODE_ID);
      }
    }
	
}

task void forwardCollect (){
	
	if (!busy) {
      CollectMsg* cmpkt = 
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


task void forwardAverage (){
	
	if (!busy) {
      AvgMsg* avgpkt = 
	(AvgMsg*)(call Packet.getPayload(&pkt, sizeof(AvgMsg)));
      if (avgpkt == NULL) return;
		uint32_t from_id=avgpkt->node_id;
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
}

event void Timer.fired(){
		post readTemperature(); 
		post readHumidity();
}

event void Temperature.readDone(error_t err, uint16_t val){
	if(err == SUCCESS){
		sumT = sumT + val;
		nT++;
		dbg("default","%s | Node %d read temperature. Sum = %f. Number = %d\n", sim_time_string(), TOS_NODE_ID, sumT, nT);
	}
}

event void Humidity.readDone(error_t err, uint16_t val){
	if(err == SUCCESS){
		sumH = sumH + val;
		nH++;
		dbg("default","%s | Node %d read humidity. Sum = %f. Number = %d\n", sim_time_string(), TOS_NODE_ID, sumH, nH);
	}
}

event message_t * ReceiveCollect.receive(message_t * msg, void* payload, uint8_t len){
	
	 am_addr_t sourceAddr;
    if (len == sizeof(CollectMsg)) {
      CollectMsg* cmpkt = (CollectMsg*)payload;

      sourceAddr = call AMPacket.source(msg);
      dbg("default","%s | Received from %d, setting Leds <- %d\n", sim_time_string(), 
	  sourceAddr, cmpkt->counter & 0x07);
	  
	  //controlla se è successivo
	  if(cmpkt -> msg_id > msg_counter){
		  msg_counter = cmpkt -> msg_id;
		  
		  prec_node = call AMPacket.source(msg);
		  
	  post forwardCollect();
	  //timeout di tot ms + random
	  //wait()
	  post sendDataAverage();
	  
	  }
    }
	else if (len == sizeof(AvgMsg)) {
      AvgMsg* avgpkt = (AvgMsg*)payload;

      dbg("default","%s | Received from %d, setting Leds <- %d\n", sim_time_string(), 
	  sourceAddr, cmpkt->counter & 0x07);
	  
	  //se è indirizzato a lui (magari se ne accorge da solo)
	  post forwardAvg();
    }
    return msg;
	
	am_addr_t from = call AMPacket.source(msg); //get the sender of the message
	//sensor_reading_t* data = (sensor_reading_t*)payload; //serve?
	
	/*
	//se è un messaggio di tipo collect, scatena eventi interni e comunque manda in broadcast il COLLECT agli altri nodi
	post forwardCollect();
	
	post computeAverages();
	post sendDataAverage();
	
	//DA RISOLVERE: capire come inoltrare in multi-hop attraverso l'albero, e se inoltrare o scartare (id messaggio?)
	
	//devo costruire il tree????
	
	*/
}



/*

event void CollectValue.changed(){
	avg_t *newAvg;
	const collect_t *newCollect = call CollectValue.get();
	
	if (newCollect->msg_id>collect.msg_id){ //forse
	collect = *newCollect;
	
	post computeAverages();

	newAvg = call AvgRoot.getPayload(&avgMsg, sizeof(avg_t));
	if (newAvg != NULL){
		newAvg -> temperature = avgT;
		newAvg -> humidity = avgH;
		newAvg -> node_id = TOS_NODE_ID;
		call AvgRoot.send(&avgMsg, sizeof *newAvg);
	}
	}
}
*/
event void AMSend.sendDone(message_t *msg, error_t ok){
	
	 if (&pkt == msg) busy = FALSE;
	 
	avgH = 0;
	avgT = 0;
	nH = 0;
	nT = 0;
	
}

 event void RadioControl.startDone(error_t ok) {
    if (ok == SUCCESS)
      {

	dbg("default","%s | Node %d RadioControl.startDone\n", sim_time_string(), TOS_NODE_ID);
      }
  }

  event void RadioControl.stopDone(error_t ok) { }



}
