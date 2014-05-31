#ifndef RADIO_COUNT_TO_LEDS_H
#define RADIO_COUNT_TO_LEDS_H

enum {
  AM_RADIO_COUNT_MSG = 6,
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

typedef nx_struct JMES {
  nx_uint16_t next_node_id; /* next node id */
  nx_uint16_t led_id; /* led id */
} JMES_t;
#endif
