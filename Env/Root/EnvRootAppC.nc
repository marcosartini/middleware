configuration EnvRootAppC{}

implementation{

	components EnvRootC, MainC, ActiveMessageC;
	components new TimerMilliC() as MyTimer;
	
	components ActiveMessageC;
	
	EnvRootC.Boot -> MainC;
	EnvRootC.RadioControl -> ActiveMessageC;

	EnvC.Timer -> MyTimer;

	components new AMSenderC();
	components new AMReceiverC();
	
	EnvC.RadioControl -> ActiveMessageC;
	EnvC.AMPacket -> AMSenderC;
	EnvC.Receive -> AMReceiverC;
	EnvC.AMSend -> AMSenderC;
	EnvC.Packet -> AMSenderC;
	
}