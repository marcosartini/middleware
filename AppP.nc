#include "Timer.h"
#include "message.h"

module AppP
{
	uses interface Boot;
	uses interface Leds;
	uses interface Timer<TMilli>;
	uses interface Read<double> as Temperature;
	uses interface Read<double> as Humidity;
	uses interface Send;
	uses interface Receive;
	uses interface Packet;
	uses interface StdControl as RoutingControl;
	uses interface RootControl;
	
	provides interface AMSend;
}
implementation {
	

	
	double sumT = 0;
	uint16_t nT=0; //number of temperature reads
	double sumH = 0;
	uint16_t nH=0; //number of humidity reads
	
	double avgT = 0;
	double avgH = 0;
	
	message_t output;
	
event void Boot.booted(){
	// Initialize app here
	if(call RadioControl.start() != SUCCESS)
		call Leds.led0On();
	
	//Starting the timer
	call Timer.startPeriodic(TMILLI_PERIOD);
}

event void RadioControl.startDone(error_t err){
	if(err != SUCCESS)
		call Leds.led0On();
	
	//non necessario ma comunque qui ci va qualcosa per il nodo 0 che manderà le collect
	if(TOS_NODE_ID == 0)
		call Timer.startPeriodic(64);
}

//controllare che effettivamente temp e hum siano lete come conseguenti immediatamente, non proprio schedulate a caso
event void Timer.fired(){
		post readTemperature(); 
		post readHumidity();
}

task void readTemperature(){
	if(call Temperature.read() != SUCCESS)
		post readTemperature;
}
task void readHumidity(){
	if(call Humidity.read() != SUCCESS)
		post readHumidity;
}

event void Temperature.readDone(error_t err, double val){
	if(err == SUCCESS){
		sumT = sumT + val;
		nT++;
	}
}

event void Humidity.readDone(error_t err, double val){
	if(err == SUCCESS){
		sumH = sumH + val;
		nH++;
	}
}

event message_t * Receive(message_t * msg, void* payload, uint8_t len){
	
	am_addr_t from = call AMPacket.source(msg); //get the sender of the message
	sensor_reading_t* data = (sensor_reading_t*)payload; //serve?
	
	return msg; //ma serve davvero?
	
	
	
}

task void computeAverages(){
	avgT = sumT/nT; //controllare taglio divisione
	avgH = sumH/nH; //controllare taglio divisione
}

task void sendDataAverage(){
	
	sensor_reading_t * reading = (sensor_reading_t*) call Packet.getPayload(&output, sizeof(sensor_reading_t));
	
	reading -> avgTemperature = avgT;
	reading -> avgHumidity = avgH;
	
	if(call AMSend.send(AM_BROADCAST_ADDR, &output, sizeof(sensor_reading_t)) != SUCCESS)
		post sendDataAverage(); //if the radio is busy, it retries to send
}

event void AMSend.sendDone(message_t* msg, error_t err){
	if (err == SUCCESS){
		//prepare next packet, azzera la media e sistema tutto
	}
	else{
		post sendDataAverage(); //resend in case of failure
	}
	
}

event void RadioControl.startDone(error_t err){
	if(TOS_NODE_ID == 100)
		call RootControl.setRoot();
	call RoutingControl.start();
}

task void sendPacket(){
	result_t err call Send.send(&msg, size(MyMsg));
	
	...
}

}
