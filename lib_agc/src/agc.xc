// Copyright (c) 2017-2020, XMOS Ltd, All rights reserved
#include <xclib.h>
#include "agc.h"
#include "voice_toolbox.h"

/*
 * AGC_DEBUG_MODE       Will enable all self checking, it will make it
 *                      MUCH slower however.
 * AGC_DEBUG_PRINT      Will enable printing of internal state to be
 *                      compared to higher models.
 * AGC_WARNING_PRINT    This enables warnings (events that might be bad
 *                      but not catastrophic).
 */
#ifndef AGC_DEBUG_MODE
#define AGC_DEBUG_MODE 0
#endif

#ifndef AGC_DEBUG_PRINT
#define AGC_DEBUG_PRINT 0
#endif

#ifndef AGC_WARNING_PRINT
#define AGC_WARNING_PRINT 0
#endif

#if AGC_DEBUG_MODE | AGC_DEBUG_PRINT | AGC_WARNING_PRINT
#include <stdio.h>
#include "audio_test_tools.h"
#endif

#if AGC_DEBUG_PRINT
static int frame_counter = 0;
#endif

#define VTB_UQ16_16_EXP (-16)
#define VTB_UQ0_32_EXP (-32)

const vtb_s32_float_t S_ONE = {INT_MAX, -31};
const vtb_u32_float_t U_ONE = {UINT_MAX, -32};
const vtb_u32_float_t U_HALF = {UINT_MAX, -32-1};
const vtb_s32_float_t S_QUARTER = {INT_MAX, -31-2};


static void agc_process_channel(agc_ch_state_t &agc_state, vtb_ch_pair_t samples[AGC_PROC_FRAME_LENGTH], unsigned ch_index, vtb_u32_float_t far_power, int vad_flag);


void agc_init(agc_state_t &agc, agc_init_config_t config){
    for(unsigned ch = 0; ch < AGC_INPUT_CHANNELS; ch++){
        agc.ch_state[ch].adapt = config.ch_init_config[ch].adapt;

        agc.ch_state[ch].gain.m = config.ch_init_config[ch].init_gain;
        agc.ch_state[ch].gain.e = VTB_UQ16_16_EXP;
        vtb_normalise_u32(agc.ch_state[ch].gain);

        agc.ch_state[ch].max_gain.m = config.ch_init_config[ch].max_gain;
        agc.ch_state[ch].max_gain.e = VTB_UQ16_16_EXP;
        vtb_normalise_u32(agc.ch_state[ch].max_gain);

        agc.ch_state[ch].upper_threshold.m = (uint32_t)config.ch_init_config[ch].upper_threshold;
        agc.ch_state[ch].upper_threshold.e = 0;
        vtb_normalise_u32(agc.ch_state[ch].upper_threshold);

        agc.ch_state[ch].lower_threshold.m = (uint32_t)config.ch_init_config[ch].lower_threshold;
        agc.ch_state[ch].lower_threshold.e = 0;
        vtb_normalise_u32(agc.ch_state[ch].lower_threshold);

        vtb_u32_float_t vtb_float_u32_zero = VTB_FLOAT_U32_ZERO;
        agc.ch_state[ch].x_slow = vtb_float_u32_zero;
        agc.ch_state[ch].x_fast = vtb_float_u32_zero;
        agc.ch_state[ch].x_peak = vtb_float_u32_zero;

        agc.ch_state[ch].gain_inc.m = config.ch_init_config[ch].gain_inc;
        agc.ch_state[ch].gain_inc.e = VTB_UQ16_16_EXP;
        vtb_normalise_u32(agc.ch_state[ch].gain_inc);

        agc.ch_state[ch].gain_dec.m = config.ch_init_config[ch].gain_dec;
        agc.ch_state[ch].gain_dec.e = VTB_UQ16_16_EXP;
        vtb_normalise_u32(agc.ch_state[ch].gain_dec);
        
        agc.ch_state[ch].lc_enabled = config.ch_init_config[ch].lc_enabled;
        
        agc.ch_state[ch].lc_near_power_est.m = AGC_LC_NEAR_POWER_EST;
        agc.ch_state[ch].lc_near_power_est.e = VTB_UQ0_32_EXP;
        vtb_normalise_u32(agc.ch_state[ch].lc_near_power_est);
        

        agc.ch_state[ch].lc_far_power_est.m = AGC_LC_MIN_FAR_POWER;
        agc.ch_state[ch].lc_far_power_est.e = VTB_UQ0_32_EXP;
        vtb_normalise_u32(agc.ch_state[ch].lc_far_power_est);
        
        agc.ch_state[ch].lc_gain = U_ONE;
        
        agc.ch_state[ch].lc_bg_power_est.m = AGC_LC_BG_POWER_EST_INIT;
        agc.ch_state[ch].lc_bg_power_est.e = VTB_UQ0_32_EXP;
        vtb_normalise_u32(agc.ch_state[ch].lc_bg_power_est);
        
        agc.ch_state[ch].lc_far_bg_power_est.m = AGC_LC_FAR_BG_POWER_EST_INIT; 
        agc.ch_state[ch].lc_far_bg_power_est.e = VTB_UQ0_32_EXP;
        vtb_normalise_u32(agc.ch_state[ch].lc_far_bg_power_est);
        
        agc.ch_state[ch].lc_min_far_power.m = AGC_LC_MIN_FAR_POWER;
        agc.ch_state[ch].lc_min_far_power.e = VTB_UQ0_32_EXP;
        vtb_normalise_u32(agc.ch_state[ch].lc_min_far_power);
        
        agc.ch_state[ch].lc_bg_power_gamma.m = AGC_LC_BG_POWER_GAMMA;
        agc.ch_state[ch].lc_bg_power_gamma.e = VTB_UQ16_16_EXP;
        vtb_normalise_u32(agc.ch_state[ch].lc_bg_power_gamma);
        
        agc.ch_state[ch].lc_delta_far.m = AGC_LC_DELTA_FAR;
        agc.ch_state[ch].lc_delta_far.e = VTB_UQ16_16_EXP;
        vtb_normalise_u32(agc.ch_state[ch].lc_delta_far);
        
        agc.ch_state[ch].lc_delta.m = AGC_LC_DELTA;
        agc.ch_state[ch].lc_delta.e = VTB_UQ16_16_EXP;
        vtb_normalise_u32(agc.ch_state[ch].lc_delta);
        
        agc.ch_state[ch].lc_gain_max.m = AGC_LC_GAIN_MAX;
        agc.ch_state[ch].lc_gain_max.e = VTB_UQ16_16_EXP;
        vtb_normalise_u32(agc.ch_state[ch].lc_gain_max);
        
        agc.ch_state[ch].lc_gain_min.m = AGC_LC_GAIN_MIN;
        agc.ch_state[ch].lc_gain_min.e = VTB_UQ16_16_EXP;
        vtb_normalise_u32(agc.ch_state[ch].lc_gain_min);
        
        agc.ch_state[ch].lc_gain_dt.m = AGC_LC_GAIN_DT;
        agc.ch_state[ch].lc_gain_dt.e = VTB_UQ16_16_EXP;
        vtb_normalise_u32(agc.ch_state[ch].lc_gain_dt);
        
        agc.ch_state[ch].lc_gain_silence.m = AGC_LC_GAIN_SILENCE;
        agc.ch_state[ch].lc_gain_silence.e = VTB_UQ16_16_EXP;
        vtb_normalise_u32(agc.ch_state[ch].lc_gain_silence);
        
        agc.ch_state[ch].lc_gain_inc.m = AGC_LC_GAMMA_INC;
        agc.ch_state[ch].lc_gain_inc.e = VTB_UQ16_16_EXP;
        vtb_normalise_u32(agc.ch_state[ch].lc_gain_inc);
        agc.ch_state[ch].lc_gain_dec.m = AGC_LC_GAMMA_DEC;
        agc.ch_state[ch].lc_gain_dec.e = VTB_UQ16_16_EXP;
        vtb_normalise_u32(agc.ch_state[ch].lc_gain_dec);
        
        agc.ch_state[ch].lc_t_far = 0;
        agc.ch_state[ch].lc_t_near = 0;
    }
}


void agc_set_ch_gain(agc_state_t &agc, unsigned ch_index, vtb_uq16_16_t gain){
    if(ch_index < AGC_INPUT_CHANNELS){
        agc.ch_state[ch_index].gain.m = gain;
        agc.ch_state[ch_index].gain.e = VTB_UQ16_16_EXP;
        vtb_normalise_u32(agc.ch_state[ch_index].gain);
    }
}


vtb_uq16_16_t agc_get_ch_gain(agc_state_t agc, unsigned ch_index){
    if(ch_index >= AGC_INPUT_CHANNELS) return 0;
    return vtb_denormalise_and_saturate_u32(agc.ch_state[ch_index].gain, VTB_UQ16_16_EXP);
}


void agc_set_ch_gain_inc(agc_state_t &agc, unsigned ch_index, vtb_uq16_16_t gain_inc){
    if(ch_index < AGC_INPUT_CHANNELS){
        vtb_u32_float_t new_gain_inc;
        new_gain_inc.m = gain_inc;
        new_gain_inc.e = VTB_UQ16_16_EXP;
        vtb_normalise_u32(new_gain_inc);
        if(vtb_gte_u32_u32(new_gain_inc, U_ONE)){
            agc.ch_state[ch_index].gain_inc.m = new_gain_inc.m;
            agc.ch_state[ch_index].gain_inc.e = new_gain_inc.e;
        }
    }
}


vtb_uq16_16_t agc_get_ch_gain_inc(agc_state_t agc, unsigned ch_index){
    if(ch_index >= AGC_INPUT_CHANNELS) return 0;
    return vtb_denormalise_and_saturate_u32(agc.ch_state[ch_index].gain_inc, VTB_UQ16_16_EXP);
}


void agc_set_ch_gain_dec(agc_state_t &agc, unsigned ch_index, vtb_uq16_16_t gain_dec){
    if(ch_index < AGC_INPUT_CHANNELS){
        vtb_u32_float_t new_gain_dec;
        new_gain_dec.m = gain_dec;
        new_gain_dec.e = VTB_UQ16_16_EXP;
        vtb_normalise_u32(new_gain_dec);
        if(!vtb_gte_u32_u32(new_gain_dec, U_ONE)){
            agc.ch_state[ch_index].gain_dec.m = new_gain_dec.m;
            agc.ch_state[ch_index].gain_dec.e = new_gain_dec.e;
        }
    }
}

vtb_uq16_16_t agc_get_ch_gain_dec(agc_state_t agc, unsigned ch_index){
    if(ch_index >= AGC_INPUT_CHANNELS) return 0;
    return vtb_denormalise_and_saturate_u32(agc.ch_state[ch_index].gain_dec, VTB_UQ16_16_EXP);
}


void agc_set_ch_max_gain(agc_state_t &agc, unsigned ch_index, vtb_uq16_16_t max_gain){
    if(ch_index < AGC_INPUT_CHANNELS){
        agc.ch_state[ch_index].max_gain.m = max_gain;
        agc.ch_state[ch_index].max_gain.e = VTB_UQ16_16_EXP;
        vtb_normalise_u32(agc.ch_state[ch_index].max_gain);
    }
}


vtb_uq16_16_t agc_get_ch_max_gain(agc_state_t agc, unsigned ch_index){
    if(ch_index >= AGC_INPUT_CHANNELS) return 0;
    return vtb_denormalise_and_saturate_u32(agc.ch_state[ch_index].max_gain, VTB_UQ16_16_EXP);
}


void agc_set_ch_adapt(agc_state_t &agc, unsigned ch_index, uint32_t adapt){
    if(ch_index < AGC_INPUT_CHANNELS){
        agc.ch_state[ch_index].adapt = (int)(adapt > 0);
    }
}


int agc_get_ch_adapt(agc_state_t agc, unsigned ch_index){
    if(ch_index >= AGC_INPUT_CHANNELS) return 0;
    return agc.ch_state[ch_index].adapt;
}


void agc_set_ch_lc_enable(agc_state_t &agc, unsigned ch_index, uint32_t adapt){
    if(ch_index < AGC_INPUT_CHANNELS){
        agc.ch_state[ch_index].lc_enabled = (int)(adapt > 0);
    }
}


int agc_get_ch_lc_enable(agc_state_t agc, unsigned ch_index){
    if(ch_index >= AGC_INPUT_CHANNELS) return 0;
    return agc.ch_state[ch_index].lc_enabled;
}


void agc_set_ch_upper_threshold(agc_state_t &agc, unsigned ch_index, int32_t upper_threshold){
    if(ch_index < AGC_INPUT_CHANNELS){
        int32_t abs_input = upper_threshold;
        if (abs_input < 0) abs_input = -abs_input;

        agc.ch_state[ch_index].upper_threshold.m = (uint32_t)abs_input;
        agc.ch_state[ch_index].upper_threshold.e = 0;
        vtb_normalise_u32(agc.ch_state[ch_index].upper_threshold);
        
        if (vtb_gte_u32_u32(agc.ch_state[ch_index].lower_threshold, agc.ch_state[ch_index].upper_threshold)){
            agc.ch_state[ch_index].upper_threshold = agc.ch_state[ch_index].lower_threshold;
        }
    }
}


void agc_set_ch_lower_threshold(agc_state_t &agc, unsigned ch_index, int32_t lower_threshold){
    if(ch_index < AGC_INPUT_CHANNELS){
        int32_t abs_input = lower_threshold;
        if (abs_input < 0) abs_input = -abs_input;

        agc.ch_state[ch_index].lower_threshold.m = (uint32_t)abs_input;
        agc.ch_state[ch_index].lower_threshold.e = 0;
        vtb_normalise_u32(agc.ch_state[ch_index].lower_threshold);
        
        if (vtb_gte_u32_u32(agc.ch_state[ch_index].lower_threshold, agc.ch_state[ch_index].upper_threshold)){
            agc.ch_state[ch_index].lower_threshold = agc.ch_state[ch_index].upper_threshold;
        }
    }
}


int32_t agc_get_ch_upper_threshold(agc_state_t agc, unsigned ch_index){
    if(ch_index >= AGC_INPUT_CHANNELS) return 0;
    uint32_t upper_threshold = vtb_denormalise_and_saturate_u32(agc.ch_state[ch_index].upper_threshold, 0);
    return (int32_t)upper_threshold;
}


int32_t agc_get_ch_lower_threshold(agc_state_t agc, unsigned ch_index){
    if(ch_index >= AGC_INPUT_CHANNELS) return 0;
    uint32_t lower_threshold = vtb_denormalise_and_saturate_u32(agc.ch_state[ch_index].lower_threshold, 0);
    return (int32_t)lower_threshold;
}


uint32_t get_max_abs_sample(vtb_ch_pair_t samples[AGC_PROC_FRAME_LENGTH], unsigned ch_index){
    uint32_t max_abs_value = 0;
    for(unsigned n = 0; n < AGC_PROC_FRAME_LENGTH; n++){
        int32_t sample = (samples[n], int32_t[2])[ch_index&1];
        uint32_t abs_sample = 0;
        if(sample < 0){
            abs_sample = (uint32_t)(-sample);
        } else {
            abs_sample = (uint32_t)sample;
        }

        if(abs_sample > max_abs_value){
            max_abs_value = abs_sample;
        }
    }
    return max_abs_value;
}


void agc_process_frame(agc_state_t &agc, vtb_ch_pair_t frame[AGC_CHANNEL_PAIRS][AGC_PROC_FRAME_LENGTH], vtb_u32_float_t far_power, int vad_flag){
    #if AGC_DEBUG_PRINT
        printf("\n#%u\n", frame_counter++);
    #endif
    for(unsigned ch=0;ch<AGC_INPUT_CHANNELS;ch++){
        agc_process_channel(agc.ch_state[ch], frame[ch/2], ch, far_power, vad_flag);
    }
}


static void agc_process_channel(agc_ch_state_t &state, vtb_ch_pair_t samples[AGC_PROC_FRAME_LENGTH], unsigned ch_index, vtb_u32_float_t far_power, int vad_flag){
    const vtb_u32_float_t agc_limit_point = U_HALF;
    const int s32_exponent = -31;

    if(state.adapt){
        uint32_t max_sample = get_max_abs_sample(samples, ch_index);
        vtb_u32_float_t max_abs_value = {max_sample, 0};
        vtb_normalise_u32(max_abs_value);

        int rising = vtb_gte_u32_u32(max_abs_value, state.x_slow);

        if(rising){
            vtb_exponential_average_u32(state.x_slow, max_abs_value, AGC_ALPHA_SLOW_RISE);
            vtb_exponential_average_u32(state.x_fast, max_abs_value, AGC_ALPHA_FAST_RISE);
        } else{
            vtb_exponential_average_u32(state.x_slow, max_abs_value, AGC_ALPHA_SLOW_FALL);
            vtb_exponential_average_u32(state.x_fast, max_abs_value, AGC_ALPHA_FAST_FALL);
        }


        vtb_u32_float_t gained_max_abs_value = vtb_mul_u32_u32(max_abs_value, state.gain);
        int exceed_threshold = vtb_gte_u32_u32(gained_max_abs_value, state.upper_threshold);

        if(exceed_threshold || vad_flag){
            int peak_rising = vtb_gte_u32_u32(state.x_fast, state.x_peak);
            if(peak_rising){
                vtb_exponential_average_u32(state.x_peak, state.x_fast, AGC_ALPHA_PEAK_RISE);
            } else{
                vtb_exponential_average_u32(state.x_peak, state.x_fast, AGC_ALPHA_PEAK_FALL);
            }

            vtb_u32_float_t gained_pk = vtb_mul_u32_u32(state.x_peak, state.gain);

            if(vtb_gte_u32_u32(gained_pk, state.upper_threshold)){
                state.gain = vtb_mul_u32_u32(state.gain_dec, state.gain);
            } else if(vtb_gte_u32_u32(state.lower_threshold, gained_pk) && (!state.lc_enabled || state.lc_t_far == 0)){
                state.gain = vtb_mul_u32_u32(state.gain_inc, state.gain);
            }
            
            if(vtb_gte_u32_u32(state.gain, state.max_gain)){
                state.gain = state.max_gain;
            }
        }
    }
    
    
    // Loss Control 
    vtb_uq0_32_t far_power_alpha = AGC_LC_EST_ALPHA_INC;
    if(vtb_gte_u32_u32(state.lc_far_power_est, far_power)){
        far_power_alpha = AGC_LC_EST_ALPHA_DEC;
    }
    vtb_exponential_average_u32(state.lc_far_power_est, far_power, far_power_alpha);
    
    vtb_u32_float_t limited_far_power_est = state.lc_far_power_est;
    if(vtb_gte_u32_u32(state.lc_min_far_power, limited_far_power_est)){
        limited_far_power_est = state.lc_min_far_power;
    }
    
    vtb_u32_float_t far_bg_power_est = vtb_mul_u32_u32(state.lc_far_bg_power_est, state.lc_bg_power_gamma);
    if(vtb_gte_u32_u32(far_bg_power_est, limited_far_power_est)){
        state.lc_far_bg_power_est = limited_far_power_est;
    }
    else{
        state.lc_far_bg_power_est = far_bg_power_est;
    }
    
    // Get frame power of input channel
    vtb_u32_float_t input_power = vtb_get_td_frame_power((vtb_ch_pair_t *)samples, s32_exponent, AGC_PROC_FRAME_LENGTH, ch_index);

    vtb_uq0_32_t near_power_alpha = AGC_LC_EST_ALPHA_INC;
    if(vtb_gte_u32_u32(state.lc_near_power_est, input_power)){
        near_power_alpha = AGC_LC_EST_ALPHA_DEC;
    }
    vtb_exponential_average_u32(state.lc_near_power_est, input_power, near_power_alpha);
    
    if(vtb_gte_u32_u32(state.lc_bg_power_est, state.lc_near_power_est)){
        vtb_exponential_average_u32(state.lc_bg_power_est, state.lc_near_power_est, AGC_LC_BG_POWER_EST_ALPHA_DEC);
    }
    else{
        state.lc_bg_power_est = vtb_mul_u32_u32(state.lc_bg_power_est, state.lc_bg_power_gamma);
    }
        
    vtb_u32_float_t lc_target_gain;
    if(state.lc_enabled){
        // Update activity timers
        if(vtb_gte_u32_u32(limited_far_power_est, vtb_mul_u32_u32(state.lc_delta, state.lc_far_bg_power_est))){
            state.lc_t_far = AGC_LC_N_FRAME_FAR;
        }
        else{
            state.lc_t_far = state.lc_t_far - 1;
            if (state.lc_t_far < 0) state.lc_t_far = 0;
        }
        
        vtb_u32_float_t delta = state.lc_delta;
        if(state.lc_t_far){
            delta = state.lc_delta_far;
        }
        if(vtb_gte_u32_u32(state.lc_near_power_est, vtb_mul_u32_u32(delta, state.lc_bg_power_est))){
            state.lc_t_near = AGC_LC_N_FRAME_NEAR;
        }
        else{
            state.lc_t_near = state.lc_t_near - 1;
            if (state.lc_t_near < 0) state.lc_t_near = 0;
        }
        
        // Adapt loss control gain
        if(state.lc_t_far == 0 && state.lc_t_near){
            // Near speech only
            lc_target_gain = state.lc_gain_max;
        }
        else if(state.lc_t_far && state.lc_t_near == 0){
            // Far end only
            lc_target_gain = state.lc_gain_min;
        }
        else if(state.lc_t_far && state.lc_t_near){
            // Both near-end and far -end
            lc_target_gain = state.lc_gain_dt;
        }
        else{
            // Silence
            lc_target_gain = state.lc_gain_silence;
        }
    }
    

    for(unsigned n = 0; n < AGC_PROC_FRAME_LENGTH; n++){
        vtb_s32_float_t input_sample = {(samples[n], int32_t[2])[ch_index&1], s32_exponent};
        vtb_normalise_s32(input_sample);

        vtb_s32_float_t gained_sample;
        if(state.lc_enabled){
            if(vtb_gte_u32_u32(state.lc_gain, lc_target_gain)){
                state.lc_gain = vtb_mul_u32_u32(state.lc_gain, state.lc_gain_dec);
                // TODO hold lc_gain if equal?
            }
            else{
                state.lc_gain = vtb_mul_u32_u32(state.lc_gain, state.lc_gain_inc);
            }
            
            gained_sample = vtb_mul_s32_u32(input_sample, vtb_mul_u32_u32(state.lc_gain, state.gain));
        }
        else{
            gained_sample = vtb_mul_s32_u32(input_sample, state.gain);
        }

        #if AGC_DEBUG_PRINT
            printf("input_sample[%u] = %d\n", ch_index, (samples[n], int32_t[2])[ch_index&1]);
            printf("input_sample_float[%u] = %.22f\n", ch_index, att_uint32_to_double(input_sample.m, input_sample.e));
            printf("gained_sample[%u] = %.22f\n", ch_index, att_uint32_to_double(gained_sample.m, gained_sample.e));
        #endif

        vtb_u32_float_t abs_gained_sample = vtb_abs_s32_to_u32(gained_sample);

        if(vtb_gte_u32_u32(abs_gained_sample, agc_limit_point)){
            vtb_s32_float_t div_result = vtb_div_s32_u32(S_QUARTER, abs_gained_sample);
            vtb_s32_float_t output_normalised = vtb_sub_s32_s32(S_ONE, div_result);
            int32_t output_sample = vtb_denormalise_and_saturate_s32(output_normalised, s32_exponent);

            #if AGC_DEBUG_PRINT
                printf("output_sample_float[%u] = %.22f\n", ch_index, att_uint32_to_double(output_normalised.m, output_normalised.e));
                printf("output_sample[%u] = %d\n", ch_index, output_sample);
            #endif

            if(input_sample.m < 0){
                output_sample =- output_sample;
            }
            (samples[n], int32_t[2])[ch_index&1] = output_sample;

        } else{
            int32_t output_sample = vtb_denormalise_and_saturate_s32(gained_sample, s32_exponent);
            (samples[n], int32_t[2])[ch_index&1] = output_sample;

            #if AGC_DEBUG_PRINT
                printf("output_sample_float[%u] = %.22f\n", ch_index, att_uint32_to_double(gained_sample.m, s32_exponent));
                printf("output_sample[%u] = %d\n", ch_index, output_sample);
            #endif
        }
    }
}
