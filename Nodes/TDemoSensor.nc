generic confirguration TDemoSensor(){
	provides interface Read<double>;
}
implementation
{
	components new VoltageC() as DemoChannel;
	
	Read = DemoChannel; //in un certo range di temperature
}