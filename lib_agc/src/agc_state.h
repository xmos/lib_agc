// Copyright (c) 2017-2019, XMOS Ltd, All rights reserved
#ifndef _agc_state_h_
#define _agc_state_h_

#include <stdint.h>
#include "voice_toolbox.h"
#include "agc_conf.h"

#define AGC_CHANNEL_PAIRS ((AGC_INPUT_CHANNELS+1)/2)

#define AGC_ALPHA_SLOW_RISE UQ32(0.8869)
#define AGC_ALPHA_SLOW_FALL UQ32(0.9646)
#define AGC_ALPHA_FAST_RISE UQ32(0.3814)
#define AGC_ALPHA_FAST_FALL UQ32(0.8869)
#define AGC_ALPHA_PEAK_RISE UQ32(0.5480)
#define AGC_ALPHA_PEAK_FALL UQ32(0.9646)

#define AGC_GAIN_INC        UQ16(1.0121)
#define AGC_GAIN_DEC        UQ16(0.9880)


/* Structure to hold AGC state, only used internally */
typedef struct {
    int adapt;
    vtb_u32_float_t gain;
    vtb_u32_float_t max_gain;
    vtb_u32_float_t desired_level;
    vtb_u32_float_t x_slow;
    vtb_u32_float_t x_fast;
    vtb_u32_float_t x_peak;
    uint32_t alpha_sr;
    uint32_t alpha_sf;
    uint32_t alpha_fr;
    uint32_t alpha_ff;
    uint32_t alpha_pr;
    uint32_t alpha_pf;
    vtb_u32_float_t gain_inc;
    vtb_u32_float_t gain_dec;
} agc_channel_state_t;

typedef struct {
    agc_channel_state_t ch_state[AGC_INPUT_CHANNELS];
} agc_state_t;


#endif // _AGC_STATE_H_
