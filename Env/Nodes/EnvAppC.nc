#include "environment.h"

configuration EnvAppC{}

implementation {
	
	components EnvC, ActiveMessageC, MainC, new TimerMilliC() as MyTimer;
	
	components ActiveMessageC as Radio;
	
	EnvC.Boot -> MainC.Boot;
	EnvC.Timer -> MyTimer;


	components new DemoSensorC() as TSensor;
	components new DemoSensorC() as HSensor;
	EnvC.Temperature -> TSensor;
	EnvC.Humidity -> HSensor;

	components new AMSenderC();
	components new AMReceiverC();
	
	EnvC.RadioControl -> ActiveMessageC;
	EnvC.AMPacket -> AMSenderC;
	EnvC.Receive -> AMReceiverC;
	EnvC.AMSend -> AMSenderC;
	EnvC.Packet -> AMSenderC;
	
	
	
}
