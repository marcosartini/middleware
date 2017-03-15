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

AppP.Send -> CollectionC.Send[MY_MSG_ID];
AppP.Receive -> CollectionC.Receive[MY_MSG_ID];
AppP.Packet -> CollectionC;
}
