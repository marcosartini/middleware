#include "Timer.h"

module AppP
{
	uses interface Boot;
	uses interface Timer<TMilli>;
	uses interface Read<uint16_t> as Temperature;
	uses interface Read<uint16_t> as Humidity;
}
implementation {
	
	TMilli period = 1024;
	
	uint16_t sumT = 0;
	uint16_t nT=0; //number of temperature reads
	uint16_t sumH = 0;
	uint16_t nH=0; //number of humidity reads
	
event void Boot.booted(){
	// Initialize app here
	
	//Starting the timer
	call Timer.startPeriodic(period);
}

event void Timer.fired(){
		call Temperature.read();
		call Humidity.read();
}

event void Temperature.readDone(error_t err, uint16_t val){
	if(err == SUCCESS){
		sumT = sumT + val;
		nT++;
	}
}

event void Humidity.readDone(error_t err, uint16_t val){
	if(err == SUCCESS){
		sumH = sumH + val;
		nH++;
	}
}

}
