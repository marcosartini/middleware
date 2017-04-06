configuration EnvRootAppC{}

implementation{

	components EnvRootAppC MainC, ActiveMessageC;
	
	components CC2420ActiveMessageC as Radio;
	
	EnvRootC.Boot -> MainC;
	EnvRootC.RadioControl -> ActiveMessageC;
	EnvRootC.LowPowerListening -> Radio;
	
	components DisseminationC;
	EnvRootC.DisseminationControl -> DisseminationC;
	
	components new DisseminatorC (collect_t, DIS_COLLECT);
	EnvRootC.CollectUpdate -> DisseminatorC;
	
	components CollectionC;
	EnvRootC.CollectionControl -> CollectionC;
	EnvRootC.RootControl -> CollectionC;
	EnvRootC.AvgReceive -> CollectionC.Receive[COL_AVG];

}