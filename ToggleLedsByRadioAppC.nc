#include "ToggleLedsByRadio.h"

configuration ToggleLedsByRadioAppC {}
implementation {
  components MainC, ToggleLedsByRadioC as App, LedsC;
  components new AMSenderC(RADIO_CHANNEL);
  components new AMReceiverC(RADIO_CHANNEL);
  components new TimerMilliC();
  components new TimerMilliC() as TimerMilliC2;
  components ActiveMessageC;
  components RandomC;
  
  App.Boot -> MainC.Boot;
  
  App.Receive -> AMReceiverC;
  App.AMSend -> AMSenderC;
  App.AMControl -> ActiveMessageC;
  App.Leds -> LedsC;
  App.CheckMilliTimer -> TimerMilliC2;
  App.MilliTimer -> TimerMilliC;
  App.Packet -> AMSenderC;
  App.Random -> RandomC;
}


