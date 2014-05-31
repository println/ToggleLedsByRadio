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
	bool _checking;
	bool _initialized;
	bool _checking_running;
	uint16_t _led = LED0;
	uint16_t _elapsed_time = 0;

	event void Boot.booted() {		
			call AMControl.start();
	}

	event void AMControl.startDone(error_t err) {		
		if (err == SUCCESS) {
			if(TOS_NODE_ID == MASTER_RADIO_ID){/*somente o master eh inicializado*/
				call Leds.led0On();/*led 0 liga neste momento*/
				call CheckMilliTimer.startOneShot(CHECKING_INTERVAL);/*servico de checagem eh ligado*/
				trigger_timers_oneshot_event(1);/*mensagem inicial eh enviada*/
				_initialized = TRUE;
				_checking_running = TRUE;
			}
		}
		else {
			call AMControl.start();
		}
	}

	event void AMControl.stopDone(error_t err) {
		// do nothing
	}

	event void CheckMilliTimer.fired() {/*servico de checagem*/
		atomic{
			_elapsed_time = _elapsed_time + CHECKING_INTERVAL;

			if(_elapsed_time >= INACTIVE_TIME_LIMIT){
				_elapsed_time = _elapsed_time - CHECKING_INTERVAL;
				_checking = TRUE;
				trigger_timers_oneshot_event(1);
				call CheckMilliTimer.startOneShot(_elapsed_time);
			}
			else{
				_checking = FALSE;
				call CheckMilliTimer.startOneShot(CHECKING_INTERVAL);
			}
		}
	}

	event void MilliTimer.fired() {/*envio de mensagem*/		

		dbg("RadioCountToLedsC", "RadioCountToLedsC: timer fired		led is %hu.\n", _led);
		if (_locked) {/*renviar mensagem se o radio estiver ocupado*/
				if(!_checking){/*nao reenvia se for uma mensagem de checagem*/
					trigger_timers_oneshot_event(RESEND_DELAY);
				}
				return;/*sai do evento*/
		}
		else {
			JMES_t* rcm = (JMES_t*)call Packet.getPayload(&_packet, sizeof(JMES_t));
			
			if (rcm == NULL) {
				return;
			}

			if(TOS_NODE_ID == MASTER_RADIO_ID){/*seletor de mote de destino pelo valor da id*/
				rcm->next_node_id = SECONDARY_RADIO_ID;
			}
			else if(TOS_NODE_ID == SECONDARY_RADIO_ID){
				rcm->next_node_id = TERTIARY_RADIO_ID;
			}
			else{
				rcm->next_node_id = MASTER_RADIO_ID;
			}

			rcm->led_id = _led;/*combinacao de leds que devem ser acionados*/

			if (call AMSend.send(AM_BROADCAST_ADDR, &_packet, sizeof(JMES_t)) == SUCCESS) {/*envio de mensagem*/
				dbg("RadioCountToLedsC", "RadioCountToLedsC: _packet sent.\n", _led);	
				_locked = TRUE;
			}
		}
	}

	event message_t* Receive.receive(message_t* bufPtr,void* payload, uint8_t len) {/*recebimento de mensagem*/
		dbg("RadioCountToLedsC", "Received _packet of length %hhu.\n", len);

		if (len != sizeof(JMES_t)) {
			return bufPtr;
		}
		else {			

			JMES_t* rcm = (JMES_t*)payload;

			_elapsed_time = 0;		

			if (rcm->next_node_id == TOS_NODE_ID) {

				if (rcm->next_node_id == MASTER_RADIO_ID) {/*master faz o chaveamento dos leds*/
					_led++;
					if(_led & 0x4){
						_led = LED0;
					}
				}
				else{/*os outros apenas realizam a atribuicao de leds*/
					_led = rcm->led_id;
					_initialized = TRUE;
				}

				if (_led == LED0) {/*um aceso*/
					call Leds.led0On();
					call Leds.led1Off();
					call Leds.led2Off();
				}
				else if (_led == LED1) {/*dois acesos*/
					call Leds.led0On();
					call Leds.led1On();
					call Leds.led2Off();
				}
				else if (_led == LED2) {/*tres acesos*/
					call Leds.led0On();
					call Leds.led1On();
					call Leds.led2On();
				}
				else if (_led == LEDS_TURNOFF){/*apagar todos*/
					call Leds.led0Off();
					call Leds.led1Off();
					call Leds.led2Off();
				}

				trigger_timers_oneshot_event(SEND_DELAY);/*envia mensagem*/

				if(_initialized && !_checking_running){/*ativacao do evento de checagem para nos sem ser o master*/
					call CheckMilliTimer.startOneShot(CHECKING_INTERVAL);
					_checking_running = TRUE;			
				}			

			}
			return bufPtr;
		}
	}

	event void AMSend.sendDone(message_t* bufPtr, error_t error) {/*envio com sucesso*/
		if (&_packet == bufPtr) {
			_locked = FALSE;
		}
	}

	void trigger_timers_oneshot_event(uint16_t delay){/*funcao para disparar o envio de mensagem, com delay*/
		call MilliTimer.startOneShot(delay);
	}
}




