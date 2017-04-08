#include "Timer.h"
#include "../Nodes/environment.h"

configuration EnvRootAppC{}

implementation{

	components EnvRootC, MainC, ActiveMessageC;
	components new TimerMilliC() as MyTimer;
	
	
	EnvRootC.Boot -> MainC;
	EnvRootC.RadioControl -> ActiveMessageC;

	EnvRootC.Timer -> MyTimer;

	components new AMSenderC(AM_ENV);
	components new AMReceiverC(AM_ENV);
	
	EnvRootC.RadioControl -> ActiveMessageC;
	EnvRootC.AMPacket -> AMSenderC;
	EnvRootC.Receive -> AMReceiverC;
	EnvRootC.AMSend -> AMSenderC;
	EnvRootC.Packet -> AMSenderC;
	
}
