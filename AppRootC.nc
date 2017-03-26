
module AppRootC
{
  uses
  {
    interface Boot;
    interface SplitControl as SerialControl;
    interface SplitControl as RadioControl;
    interface LowPowerListening;

    interface DisseminationUpdate<collect_msg_t> as SettingsUpdate;
    interface Receive as SettingsReceive;

    interface StdControl as CollectionControl;
    interface StdControl as DisseminationControl;
    interface RootControl;
    interface Receive as AvgsReceive;
    interface AMSend as AvgsForward;

    interface Leds;
  }
}
implementation
{
  /* Start the radio and serial ports when booting */
  event void Boot.booted()
  {
    call SerialControl.start();
    call RadioControl.start();
  }

  event void SerialControl.startDone(error_t error) { }
  event void SerialControl.stopDone(error_t error) { }

  event void RadioControl.startDone(error_t error) {
    /* Once the radio has started, we can setup low-power listening, and
       start the collection and dissemination services. Additionally, we
       set ourselves as the (sole) root for the theft alert dissemination
       tree */
    if (error == SUCCESS)
      {
	call LowPowerListening.setLocalWakeupInterval(512);
	call DisseminationControl.start();
	call CollectionControl.start();
	call RootControl.setRoot();
      }
  }
  event void RadioControl.stopDone(error_t error) { }

  /* When we receive new settings from the serial port, we disseminate
     them by calling the change command */
  event message_t *SettingsReceive.receive(message_t* msg, void* payload, uint8_t len)
  {
    collect_msg_t *newCollect = payload;

    if (len == sizeof(*newCollect))
      {
	call Leds.led2Toggle();
	call SettingsUpdate.change(newCollect);
      }
    return msg;
  }

  message_t fwdMsg;
  bool fwdBusy;

  /* When we (as root of the collection tree) receive a new theft alert,
     we forward it to the PC via the serial port */
  event message_t *AvgsReceive.receive(message_t* msg, void* payload, 
					 uint8_t len)
  {
    agv_msg_t *newAvg = payload;

    call Leds.led0Toggle();

    if (len == sizeof(*newAvg) && !fwdBusy)
      {
	/* Copy payload (newAvg) from collection system to our serial
	   message buffer (fwdAvg), then send our serial message */
	avg_msg_t *fwdAlert = call AvgForward.getPayload(&fwdMsg, sizeof(avg_msg_t));
	if (fwdAlert != NULL) {
	  *fwdAvg = *newAvg;
	  if (call AvgsForward.send(AM_BROADCAST_ADDR, &fwdMsg, sizeof *fwdAvg) == SUCCESS)
	    fwdBusy = TRUE;
	}
      }
    return msg;
  }

  event void AvgsForward.sendDone(message_t *msg, error_t error) {
    if (msg == &fwdMsg)
      fwdBusy = FALSE;
  }

}
