#include "environment.h"

configuration EnvAppC{}

implementation {
	
	components EnvC, ActiveMessageC, MainC, new TimerMilliC() as MyTimer;
	
	components CC2420ActiveMessageC as Radio;
	
	EnvC.Boot -> MainC.Boot;
	EnvC.Timer -> MyTimer;
	EnvC.RadioControl -> ActiveMessageC;
	EnvC.LowPowerListening -> Radio;
	
	components HDemoSensor, TDemoSensor;
	EnvC.Temperature -> TDemoSensor;
	EnvC.Humidity -> HDemoSensor;
	
	components DisseminationC;
	EnvC.DisseminationControl -> DisseminationC;
	
	components new DisseminatorC(collect_t, DIS_COLLECT);
	EnvC.CollectValue -> DisseminatorC;
	
	components CollectionC, new CollectionSenderC(COL_AVG) as AvgSender;
	EnvC.AvgRoot -> AvgSender;
	EnvC.CollectionControl -> CollectionC;
	
	
	
}