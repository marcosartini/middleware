#include "message.h"

configuration AppC{
}
implementation{
components AppP;
components MainC;
components ActiveMessageC;
components CollectionC;


AppP.Boot -> MainC;
AppP.RoutingControl -> CollectionC;
AppP.RootControl -> CollectionC;

AppP.Send -> CollectionC.Send[AM_COLLECT_MSG];
AppP.Receive -> CollectionC.Receive[AM_AVG_MSG];
AppP.Send -> CollectionC.Send[AM_AVG_MSG];
AppP.Receive -> CollectionC.Receive[AM_COLLECT_MSG];
AppP.Packet -> CollectionC;
}
