#include "Timer.h"
#include "RadioCountToLeds.h"

module RadioCountToLedsC @safe() {
	uses {
		interface Leds;
		interface Boot;
		interface Receive;
		interface AMSend;
		interface Timer<TMilli> as MilliTimer;
		interface Timer<TMilli> as CheckMilliTimer;
		interface SplitControl as AMControl;
		interface Packet;
	}
}

implementation {

	void trigger_timers_oneshot_event(uint16_t delay);

	message_t _packet;
	bool _locked;
	bool _cheking;
	uint16_t _led = LED0;
	uint16_t _elapsed_time = 0;

	event void Boot.booted() {		
			call AMControl.start();
	}

	event void AMControl.startDone(error_t err) {		
		if (err == SUCCESS) {
			if(TOS_NODE_ID == MASTER_RADIO_ID){
				call Leds.led0On();
				trigger_timers_oneshot_event(1);
			}
			call CheckMilliTimer.startPeriodic(CHECKING_INTERVAL);			
		}
		else {
			call AMControl.start();
		}
	}

	event void AMControl.stopDone(error_t err) {
		// do nothing
	}

	event void CheckMilliTimer.fired() {		
		_elapsed_time = _elapsed_time + CHECKING_INTERVAL;

		if(_elapsed_time >= INACTIVE_TIME_LIMIT){
			_cheking = TRUE;
			trigger_timers_oneshot_event(1);
		}
		else{
			_cheking = FALSE;
		}	
	}

	event void MilliTimer.fired() {		

		dbg("RadioCountToLedsC", "RadioCountToLedsC: timer fired		led is %hu.\n", _led);
		if (_locked) {
				if(!_cheking){
					trigger_timers_oneshot_event(RESEND_DELAY);
				}
				return;
		}
		else {
			JMES_t* rcm = (JMES_t*)call Packet.getPayload(&_packet, sizeof(JMES_t));
			
			if (rcm == NULL) {
				return;
			}

			if(TOS_NODE_ID == MASTER_RADIO_ID){
				rcm->next_node_id = SECONDARY_RADIO_ID;
			}
			else if(TOS_NODE_ID == SECONDARY_RADIO_ID){
				rcm->next_node_id = TERTIARY_RADIO_ID;
			}
			else{
				rcm->next_node_id = MASTER_RADIO_ID;
			}

			rcm->led_id = _led;

			if (call AMSend.send(AM_BROADCAST_ADDR, &_packet, sizeof(JMES_t)) == SUCCESS) {
				dbg("RadioCountToLedsC", "RadioCountToLedsC: _packet sent.\n", _led);	
				_locked = TRUE;
			}
		}
	}

	event message_t* Receive.receive(message_t* bufPtr,void* payload, uint8_t len) {
		dbg("RadioCountToLedsC", "Received _packet of length %hhu.\n", len);

		if (len != sizeof(JMES_t)) {
			return bufPtr;
		}
		else {			

			JMES_t* rcm = (JMES_t*)payload;

			_elapsed_time = 0;		

			if (rcm->next_node_id == TOS_NODE_ID) {

				if (rcm->next_node_id == MASTER_RADIO_ID) {
					_led++;
					if(_led & 0x4){
						_led = LED0;
					}
				}
				else{
					_led = rcm->led_id;
				}

				if (_led == LED0) {
					call Leds.led0On();
				}
				else if (_led == LED1) {
					call Leds.led1On();
				}
				else if (_led == LED2) {
					call Leds.led2On();
				}
				else if (_led == LEDS_TURNOFF){
					call Leds.led0Off();
					call Leds.led1Off();
					call Leds.led2Off();
				}

				trigger_timers_oneshot_event(SEND_DELAY);			

			}
			return bufPtr;
		}
	}

	event void AMSend.sendDone(message_t* bufPtr, error_t error) {
		if (&_packet == bufPtr) {
			_locked = FALSE;
		}
	}

	void trigger_timers_oneshot_event(uint16_t delay){
		call MilliTimer.startOneShot(delay);
	}
}




