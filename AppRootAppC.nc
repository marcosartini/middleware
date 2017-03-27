
#include "message.h"

configuration AntiTheftRootAppC { }
implementation
{
  /* First wire the low-level services (booting, serial port, radio).
     There is no standard name for the actual radio component, so we use
     #ifdef to get the right one for the current platform. */
  components AntiTheftRootC, MainC, LedsC, ActiveMessageC, SerialActiveMessageC;
#if defined(PLATFORM_MICA2)
  components CC1000CsmaRadioC as Radio;
#elif defined(PLATFORM_MICAZ)
  components CC2420ActiveMessageC as Radio;
#elif defined(PLATFORM_IRIS)
  components ActiveMessageC as Radio;
#else
#error "The AntiTheft application is only supported for mica2, micaz and iris nodes"
#endif

  AntiTheftRootC.Boot -> MainC;
  AntiTheftRootC.SerialControl -> SerialActiveMessageC;
  AntiTheftRootC.RadioControl -> ActiveMessageC;
  AntiTheftRootC.LowPowerListening -> Radio;
  AntiTheftRootC.Leds -> LedsC;

  components DisseminationC;
  AntiTheftRootC.DisseminationControl -> DisseminationC;
  /* Next, instantiate and wire a disseminator (to send settings) and a
     serial receiver (to receive settings from the PC) */
  components new DisseminatorC(collect_msg_t, DIS_COLLECT);
 //   new SerialAMReceiverC(AM_COLLECT_MSG) as SettingsReceiver; //NON C'E' QUESTO, MA VIENE AUTOMATICO DA TIMER

//  AntiTheftRootC.SettingsReceive -> SettingsReceiver; //NON C'E' QUESTO, MA VIENE AUTOMATICO
  AntiTheftRootC.CollectUpdate -> DisseminatorC;

  /* Finally, instantiate and wire a collector (to receive theft alerts) and
     a serial sender (to send the alerts to the PC) */
  components CollectionC, new SerialAMSenderC(AM_AVG) as AvgsForwarder;

  AntiTheftRootC.CollectionControl -> CollectionC;
  AntiTheftRootC.RootControl -> CollectionC;
  AntiTheftRootC.AvgsReceive -> CollectionC.Receive[COL_AVG];
  AntiTheftRootC.AvgsForward -> AvgsForwarder;

}

