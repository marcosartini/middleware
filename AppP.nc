#include "Timer.h"
#include "message.h"

module AppP
{
	uses interface Boot;
	uses interface Leds;
	uses interface Timer<TMilli>;
	uses interface Read<float> as Temperature;
	uses interface Read<float> as Humidity;
	uses interface AMSend as TheftSend;
	uses interface Receive as TheftReceive;
	uses interface LowPowerListening;
	interface StdControl as CollectionControl;
    interface StdControl as DisseminationControl;
	interface DisseminationValue<collect_t> as SettingsValue;
    interface Send as AlertRoot;
	
	uses interface AMPacket;
	uses interface Receive as ReceiveCollect;
	uses interface Receive as ReceiveAvg;
	uses interface Packet;
	uses interface SplitControl as RadioControl;
	uses interface StdControl as RoutingControl;
	uses interface RootControl;
	
	provides interface AMSend as AMSP;
}
implementation {
	

	
	float sumT = 0;
	uint16_t nT=0; //number of temperature reads
	float sumH = 0;
	uint16_t nH=0; //number of humidity reads
	
	float avgT = 0;
	float avgH = 0;
	
	message_t output;

task void readTemperature(){
	if(call Temperature.read() != SUCCESS)
		post readTemperature();
}
task void readHumidity(){
	if(call Humidity.read() != SUCCESS)
		post readHumidity();
}
	
event void Boot.booted(){
	dbg("default","%s | Node %d started\n", sim_time_string(), TOS_NODE_ID);
	// Initialize app here
	if(call RadioControl.start() != SUCCESS)
		call Leds.led0On();
	
	//Starting the timer
	call Timer.startPeriodic(TMILLI_PERIOD);
}

event void RadioControl.startDone(error_t err){
	if(err != SUCCESS){
		call Leds.led0On();
		call RadioControl.start();
	}
	
	//non necessario ma comunque qui ci va qualcosa per il nodo 0 che manderà le collect
	if(TOS_NODE_ID == 0)
		call Timer.startPeriodic(64); //un altro timer però
}

/****** ALTERNATIVA 
event void RadioControl.startDone(error_t err){
	if(TOS_NODE_ID == 0)
		call RootControl.setRoot();
		call RoutingControl.start();
}*****/
*/

event void RadioControl.stopDone(error_t err) { }

//controllare che effettivamente temp e hum siano lete come conseguenti immediatamente, non proprio schedulate a caso
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

event message_t * ReceiveAvg.receive(message_t * msg, void* payload, uint8_t len){
	
	am_addr_t from = call AMPacket.source(msg); //get the sender of the message
	//sensor_reading_t* data = (sensor_reading_t*)payload; //serve?
	
		
	//se è un messaggio di avg, e non lo ha già inoltrato, lo deve mandare al sink attraverso gli altri nodi, con il tree
	
	
	//comunque gli inoltri vanno fatti asincroni? forse sì, ma non per forza: posso schedulare task che lo facciano. 
	//da fare "asincrona" è la ricezione dei messaggi, ma forse lo è già se quando capisco il tipo ricevuto programmo un task che fa quel che deve
	
	//DA RISOLVERE: capire come inoltrare in multi-hop attraverso l'albero, e se inoltrare o scartare (id messaggio?)

	
	
	
}

event message_t * ReceiveCollect.receive(message_t * msg, void* payload, uint8_t len){
	
	am_addr_t from = call AMPacket.source(msg); //get the sender of the message
	//sensor_reading_t* data = (sensor_reading_t*)payload; //serve?
	
	//se è un messaggio di tipo collect, scatena eventi interni e comunque manda in broadcast il COLLECT agli altri nodi
	post forwardCollect();
	
	post computeAverages();
	post sendDataAverage();
	
	//DA RISOLVERE: capire come inoltrare in multi-hop attraverso l'albero, e se inoltrare o scartare (id messaggio?)
	
	//devo costruire il tree????
	
	
}

task void computeAverages(){
	avgT = sumT/nT; //controllare taglio divisione
	avgH = sumH/nH; //controllare taglio divisione
	dbg("default","%s | Node %d computed averages. AvgT = %f. AvgH = %f\n", sim_time_string(), TOS_NODE_ID, avgT, avgH);
}

task void sendDataAverage(){
	
	avg_msg_t * reading = (avg_msg_t*) call Packet.getPayload(&output, sizeof(avg_msg_t));
	
	reading -> temperature = avgT;
	reading -> humidity = avgH;
	reading -> node_id = TOS_NODE_ID;
	
	if(call AMSend.send(AM_BROADCAST_ADDR, &output, sizeof(avg_msg_t)) != SUCCESS)
		post sendDataAverage(); //if the radio is busy, it retries to send
	
	
}

event void AMSend.sendDone(message_t* msg, error_t err){
	if (err == SUCCESS){
		dbg("default","%s | Sent avgT=%f, avgH=%f from %d\n", sim_time_string(), avgT, avgH, TOS_NODE_ID);
		avgH = 0;
		avgT = 0;
		nT = 0;
		nH = 0;
		sumT = 0;
		sumH = 0;
		//prepare next packet, azzera la media e sistema tutto
	}
	else{
		post sendDataAverage(); //resend in case of failure
	}
	
}



task void sendPacket(){
	result_t err call Send.send(&msg, size(MyMsg));
	
	//...
}

}
