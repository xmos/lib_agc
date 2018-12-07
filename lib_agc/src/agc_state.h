// Copyright (c) 2017-2018, XMOS Ltd, All rights reserved
#ifndef _agc_state_h_
#define _agc_state_h_

#include <stdint.h>
#include "voice_toolbox.h"
#include "agc_conf.h"

#define AGC_CHANNEL_PAIRS ((AGC_CHANNELS+1)/2)

/* structure to hold AGC state, only used internally */
typedef struct {
    vtb_u32_float_t gain;
} agc_channel_state_t;

typedef struct {
    agc_channel_state_t ch_state[AGC_CHANNELS];
} agc_state_t;


#endif // _AGC_STATE_H_
