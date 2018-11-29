// Copyright (c) 2017-2018, XMOS Ltd, All rights reserved
#ifndef _agc_state_h_
#define _agc_state_h_

#include <stdint.h>
#include "voice_toolbox.h"
#include "agc_conf.h"

#ifndef AGC_LOOK_PAST_FRAMES
#define AGC_LOOK_PAST_FRAMES 0
#endif

#ifndef AGC_LOOK_AHEAD_FRAMES
#define AGC_LOOK_AHEAD_FRAMES 0
#endif

#define AGC_CHANNEL_PAIRS ((AGC_CHANNELS+1)/2)

/* AGC state machine, only used internally */

typedef enum {
    AGC_UP = 0,
    AGC_DOWN = 1,
    AGC_WAIT = 2,
    AGC_STABLE = 3
} agc_mode;

/* structure to hold AGC state, only used internally */
typedef struct {

    int32_t sample_buffer[(AGC_LOOK_AHEAD_FRAMES+1) * AGC_PROC_FRAME_LENGTH];
    uint32_t sqrt_energy_fifo[(AGC_LOOK_PAST_FRAMES + AGC_LOOK_AHEAD_FRAMES + 1)];
    agc_mode state;

    // uint32_t gain;
    // int gain_exp;
    vtb_u32_float_t gain;

    unsigned look_ahead_frames;
    unsigned look_past_frames;
} agc_channel_state_t;

typedef struct {
    agc_channel_state_t channel_state[AGC_CHANNELS];
} agc_state_t;


#endif // _agc_state_h_
