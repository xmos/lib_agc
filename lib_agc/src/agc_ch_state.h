// Copyright (c) 2017-2019, XMOS Ltd, All rights reserved
#ifndef _agc_state_h_
#define _agc_state_h_

#include <stdint.h>
#include "voice_toolbox.h"
#include "agc_conf.h"

#define AGC_CHANNEL_PAIRS ((AGC_INPUT_CHANNELS+1)/2)

#define AGC_ALPHA_SLOW_RISE VTB_UQ0_32(0.8869)
#define AGC_ALPHA_SLOW_FALL VTB_UQ0_32(0.9646)
#define AGC_ALPHA_FAST_RISE VTB_UQ0_32(0.3814)
#define AGC_ALPHA_FAST_FALL VTB_UQ0_32(0.8869)
#define AGC_ALPHA_PEAK_RISE VTB_UQ0_32(0.5480)
#define AGC_ALPHA_PEAK_FALL VTB_UQ0_32(0.9646)

#define AGC_GAIN_INC        VTB_UQ16_16(1.0121)
#define AGC_GAIN_DEC        VTB_UQ16_16(0.9880)


/* Structure to hold AGC state, only used internally */
typedef struct {
    int adapt;
    vtb_u32_float_t gain;
    vtb_u32_float_t max_gain;
    vtb_u32_float_t desired_level;
    vtb_u32_float_t x_slow;
    vtb_u32_float_t x_fast;
    vtb_u32_float_t x_peak;
    vtb_uq0_32_t alpha_sr;
    vtb_uq0_32_t alpha_sf;
    vtb_uq0_32_t alpha_fr;
    vtb_uq0_32_t alpha_ff;
    vtb_uq0_32_t alpha_pr;
    vtb_uq0_32_t alpha_pf;
    vtb_u32_float_t gain_inc;
    vtb_u32_float_t gain_dec;
} agc_ch_state_t;


#endif // _AGC_STATE_H_
