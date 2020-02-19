// Copyright (c) 2017-2019, XMOS Ltd, All rights reserved
#ifndef _AGC_STATE_H_
#define _AGC_STATE_H_

#include <stdint.h>
#include "voice_toolbox.h"
#include "agc_conf.h"

#define AGC_ALPHA_SLOW_RISE VTB_UQ0_32(0.8869)
#define AGC_ALPHA_SLOW_FALL VTB_UQ0_32(0.9646)
#define AGC_ALPHA_FAST_RISE VTB_UQ0_32(0.3814)
#define AGC_ALPHA_FAST_FALL VTB_UQ0_32(0.8869)
#define AGC_ALPHA_PEAK_RISE VTB_UQ0_32(0.5480)
#define AGC_ALPHA_PEAK_FALL VTB_UQ0_32(0.9646)

#define LC_N_FRAME_NEAR (34)
#define LC_N_FRAME_FAR (17)
#define LC_ALPHA_INC VTB_UQ16_16(1.005)
#define LC_ALPHA_DEC VTB_UQ16_16(0.995)
    
#define LC_EST_GAMMA_INC VTB_UQ0_32(0.5480)
#define LC_EST_GAMMA_DEC VTB_UQ0_32(0.6973)
    
#define LC_BG_POWER_GAMMA VTB_UQ16_16(1.01) // bg power estimate small increase prevent local minima
#define LC_DELTA VTB_UQ16_16(8.0) // ratio of near end power to bg estimate to mark near end activity

#define LC_GAIN_MAX VTB_UQ16_16(1)
#define LC_GAIN_MIN VTB_UQ16_16(0.0056)
#define LC_GAIN_DT VTB_UQ16_16(0.1778)
#define LC_GAIN_SILENCE VTB_UQ16_16(0.0748)

#define LC_FAR_BG_POWER_EST_INIT VTB_UQ0_32(0.01)
#define LC_NEAR_POWER_EST VTB_UQ0_32(0.00001)
#define LC_BG_POWER_EST_INIT VTB_UQ0_32(0.00001)
#define LC_MIN_REF_POWER VTB_UQ0_32(0.00001)




/**
 * Structure to hold AGC state, only used internally.
 */
typedef struct {
    int adapt;
    vtb_u32_float_t gain;
    vtb_u32_float_t max_gain;
    vtb_u32_float_t upper_threshold;
    vtb_u32_float_t lower_threshold;
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
    int loss_control_enabled;
    vtb_u32_float_t lc_bg_power_gamma;
    int t_act_far;
    int t_act_near;
    vtb_u32_float_t lc_near_power_est;
    vtb_u32_float_t lc_bg_power_est;
    vtb_u32_float_t lc_gain;
    vtb_u32_float_t lc_far_bg_power_est;
    vtb_u32_float_t lc_min_ref_power;
    vtb_u32_float_t lc_delta;
    vtb_u32_float_t lc_gain_max;
    vtb_u32_float_t lc_gain_min;
    vtb_u32_float_t lc_gain_dt;
    vtb_u32_float_t lc_gain_silence;
    vtb_u32_float_t lc_gain_dec;
    vtb_u32_float_t lc_gain_inc;
} agc_ch_state_t;


#endif // _AGC_STATE_H_
