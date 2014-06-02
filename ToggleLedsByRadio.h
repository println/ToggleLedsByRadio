#ifndef TOGGLE_LEDS_BY_RADIO_H
#define TOGGLE_LEDS_BY_RADIO_H

enum {
  RADIO_CHANNEL = 6,
  MASTER_RADIO_ID = 1,
  SECONDARY_RADIO_ID = 2,
  TERTIARY_RADIO_ID = 3,
  LED0 = 0,
  LED1 = 1,
  LED2 = 2,
  LEDS_TURNOFF = 3,
  SEND_DELAY = 1000, /*milliseconds*/
  RESEND_DELAY = 50,
  CHECKING_INTERVAL = 1000,
  INACTIVE_TIME_LIMIT = 6000,
};

typedef nx_struct AM_MESSAGE {
  nx_uint8_t next_node_id; /* next node id */
  nx_uint8_t led_id; /* led id */
  nx_uint16_t token;
} AM_MESSAGE_t;
#endif
