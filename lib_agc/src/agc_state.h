// Copyright (c) 2017, XMOS Ltd, All rights reserved
#ifndef _agc_state_h_
#define _agc_state_h_

#include <stdint.h>

#include "agc_conf.h"

/* AGC state machine, only used internally */

typedef enum {
    AGC_UP = 0,
    AGC_DOWN = 1,
    AGC_WAIT = 2,
    AGC_STABLE = 3
} agc_mode;

/* structure to hold AGC state, only used internally */
typedef struct {
    agc_mode state;
    uint32_t frame_length;

    uint32_t desired;
    uint32_t desired_min;
    uint32_t desired_max;
    
    uint32_t gain;
    int32_t gain_shl;
    
    uint32_t max_gain;
    int32_t max_gain_shl;
    
    uint32_t min_gain;
    int32_t min_gain_shl;
    
    uint32_t down, up;
    
    uint32_t wait_samples;
    uint32_t wait_for_up_samples;

    uint32_t look_past_frames;
    uint32_t look_ahead_frames;

} agc_channel_state_t;

typedef struct {
    agc_channel_state_t channel_state[AGC_CHANNELS];
} agc_state_t;


#endif // _agc_state_h_
