#include "message.h"

configuration AppC{
}
implementation{
components AppP;
components MainC;
components LedsC;
components ActiveMessageC;
components CollectionC;
components new TimerMilliC() as Timer0;
components HDemoSensor;
components TDemoSensor;


AppP.Boot -> MainC;
AppP.Timer -> Timer0;
AppP.Leds -> LedsC;
AppP.RoutingControl -> CollectionC;
AppP.RootControl -> CollectionC;
AppP.Temperature -> TDemoSensor;
AppP.Humidity -> HDemoSensor;

AppP.Send -> CollectionC.Send[AM_COLLECT_MSG];
#AppP.ReceiveAvg -> CollectionC.Receive[AM_AVG_MSG];
AppP.Send -> CollectionC.Send[AM_AVG_MSG];
AppP.ReceiveCollect -> CollectionC.Receive[AM_COLLECT_MSG];
AppP.Packet -> CollectionC;

components new AMReceiverC(AM_AVG_MSG) as ReceiveAverage;
AppP.ReceiveAvg -> ReceiveAverage;

  App.Packet -> AMSenderC;
  App.AMPacket -> AMSenderC;
  App.RadioControl -> ActiveMessageC;
  App.AMSend -> AMSenderC;
  App.Receive -> AMReceiverC;
}
