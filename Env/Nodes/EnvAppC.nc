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

	components new AMSenderC(AM_ENV);
	components new AMReceiverC(AM_ENV);
	
	EnvC.RadioControl -> ActiveMessageC;
	EnvC.AMPacket -> AMSenderC;
	EnvC.Receive -> AMReceiverC;
	EnvC.AMSend -> AMSenderC;
	EnvC.Packet -> AMSenderC;
	

	components new TimerMilliC() as RootTimer;
	EnvC.RootTimer -> RootTimer;

	components new TimerMilliC() as WaitTimer;
	EnvC.WaitTimer -> WaitTimer;

	components RandomC;
	EnvC.Random -> RandomC;
	
	
}
