// Copyright (c) 2017-2019, XMOS Ltd, All rights reserved
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

#define VTB_UQ16_16_EXP -16

const vtb_s32_float_t ONE = {INT_MAX, -31};
const vtb_u32_float_t HALF = {UINT_MAX, -32-1};
const vtb_s32_float_t QUARTER = {INT_MAX, -31-2};


static void agc_process_channel(agc_ch_state_t &agc_state, vtb_ch_pair_t samples[AGC_PROC_FRAME_LENGTH], unsigned ch_index, int vad_flag);


void agc_init(agc_state_t &agc, agc_init_config_t config[AGC_INPUT_CHANNELS]){
    for(unsigned ch = 0; ch < AGC_INPUT_CHANNELS; ch++){
        agc.ch_state[ch].adapt = config[ch].adapt;

        agc.ch_state[ch].gain.m = config[ch].init_gain;
        agc.ch_state[ch].gain.e = VTB_UQ16_16_EXP;
        vtb_normalise_u32(agc.ch_state[ch].gain);

        agc.ch_state[ch].max_gain.m = config[ch].max_gain;
        agc.ch_state[ch].max_gain.e = VTB_UQ16_16_EXP;
        vtb_normalise_u32(agc.ch_state[ch].max_gain);

        agc.ch_state[ch].desired_level.m = (uint32_t)config[ch].desired_level;
        agc.ch_state[ch].desired_level.e = 0;
        vtb_normalise_u32(agc.ch_state[ch].desired_level);

        vtb_u32_float_t vtb_float_u32_zero = VTB_FLOAT_U32_ZERO;
        agc.ch_state[ch].x_slow = vtb_float_u32_zero;
        agc.ch_state[ch].x_fast = vtb_float_u32_zero;
        agc.ch_state[ch].x_peak = vtb_float_u32_zero;

        agc.ch_state[ch].alpha_sr = AGC_ALPHA_SLOW_RISE;
        agc.ch_state[ch].alpha_sf = AGC_ALPHA_SLOW_FALL;
        agc.ch_state[ch].alpha_fr = AGC_ALPHA_FAST_RISE;
        agc.ch_state[ch].alpha_ff = AGC_ALPHA_FAST_FALL;
        agc.ch_state[ch].alpha_pr = AGC_ALPHA_PEAK_RISE;
        agc.ch_state[ch].alpha_pf = AGC_ALPHA_PEAK_FALL;

        agc.ch_state[ch].gain_inc.m = AGC_GAIN_INC;
        agc.ch_state[ch].gain_inc.e = VTB_UQ16_16_EXP;
        vtb_normalise_u32(agc.ch_state[ch].gain_inc);

        agc.ch_state[ch].gain_dec.m = AGC_GAIN_DEC;
        agc.ch_state[ch].gain_dec.e = VTB_UQ16_16_EXP;
        vtb_normalise_u32(agc.ch_state[ch].gain_dec);
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


void agc_set_ch_desired_level(agc_state_t &agc, unsigned ch_index, int32_t desired_level){
    if(ch_index < AGC_INPUT_CHANNELS){
        int32_t abs_input = desired_level;
        if (abs_input < 0) abs_input = -abs_input;

        agc.ch_state[ch_index].desired_level.m = (uint32_t)abs_input;
        agc.ch_state[ch_index].desired_level.e = 0;
        vtb_normalise_u32(agc.ch_state[ch_index].desired_level);
    }
}


int32_t agc_get_ch_desired_level(agc_state_t agc, unsigned ch_index){
    if(ch_index >= AGC_INPUT_CHANNELS) return 0;
    uint32_t desired_level = vtb_denormalise_and_saturate_u32(agc.ch_state[ch_index].desired_level, 0);
    return (int32_t)desired_level;
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


void agc_process_frame(agc_state_t &agc, vtb_ch_pair_t frame[AGC_CHANNEL_PAIRS][AGC_PROC_FRAME_LENGTH], uint8_t vad){
    #if AGC_DEBUG_PRINT
        printf("\n#%u\n", frame_counter++);
    #endif
    int vad_flag = (vad > AGC_VAD_THRESHOLD);
    for(unsigned ch=0;ch<AGC_INPUT_CHANNELS;ch++){
        agc_process_channel(agc.ch_state[ch], frame[ch/2], ch, vad_flag);
    }
}


static void agc_process_channel(agc_ch_state_t &agc_state, vtb_ch_pair_t samples[AGC_PROC_FRAME_LENGTH], unsigned ch_index, int vad_flag){
    const vtb_u32_float_t agc_limit_point = HALF;
    const int s32_exponent = -31;

    if(agc_state.adapt){
        uint32_t max_sample = get_max_abs_sample(samples, ch_index);
        vtb_u32_float_t max_abs_value = {max_sample, 0};
        vtb_normalise_u32(max_abs_value);

        int rising = vtb_gte_u32_u32(max_abs_value, agc_state.x_slow);

        if(rising){
            vtb_exponential_average_u32(agc_state.x_slow, max_abs_value, agc_state.alpha_sr);
            vtb_exponential_average_u32(agc_state.x_fast, max_abs_value, agc_state.alpha_fr);
        } else{
            vtb_exponential_average_u32(agc_state.x_slow, max_abs_value, agc_state.alpha_sf);
            vtb_exponential_average_u32(agc_state.x_fast, max_abs_value, agc_state.alpha_ff);
        }

        vtb_u32_float_t gained_max_abs_value = vtb_mul_u32_u32(max_abs_value, agc_state.gain);
        int exceed_desired_level = vtb_gte_u32_u32(gained_max_abs_value, agc_state.desired_level);

        if(exceed_desired_level || vad_flag){
            int peak_rising = vtb_gte_u32_u32(agc_state.x_fast, agc_state.x_peak);
            if(peak_rising){
                vtb_exponential_average_u32(agc_state.x_peak, agc_state.x_fast, agc_state.alpha_pr);
            } else{
                vtb_exponential_average_u32(agc_state.x_peak, agc_state.x_fast, agc_state.alpha_pf);
            }

            vtb_u32_float_t gained_pk = vtb_mul_u32_u32(agc_state.x_peak, agc_state.gain);
            int pk_exceed_desired_level = vtb_gte_u32_u32(gained_pk, agc_state.desired_level);

            vtb_u32_float_t gain_factor;
            if(pk_exceed_desired_level){
                gain_factor = agc_state.gain_dec;
            } else{
                gain_factor = agc_state.gain_inc;
            }

            agc_state.gain = vtb_mul_u32_u32(gain_factor, agc_state.gain);

            int exceed_max_gain = vtb_gte_u32_u32(agc_state.gain, agc_state.max_gain);
            if(exceed_max_gain){
                agc_state.gain = agc_state.max_gain;
            }
        }
    }

    for(unsigned n = 0; n < AGC_PROC_FRAME_LENGTH; n++){
        vtb_s32_float_t input_sample = {(samples[n], int32_t[2])[ch_index&1], s32_exponent};
        vtb_normalise_s32(input_sample);

        vtb_s32_float_t gained_sample = vtb_mul_s32_u32(input_sample, agc_state.gain);

        #if AGC_DEBUG_PRINT
            printf("input_sample[%u] = %d\n", ch_index, (samples[n], int32_t[2])[ch_index&1]);
            printf("input_sample_float[%u] = %.22f\n", ch_index, att_uint32_to_double(input_sample.m, input_sample.e));
            printf("gained_sample[%u] = %.22f\n", ch_index, att_uint32_to_double(gained_sample.m, gained_sample.e));
        #endif

        vtb_u32_float_t abs_gained_sample = vtb_abs_s32_to_u32(gained_sample);

        if(vtb_gte_u32_u32(abs_gained_sample, agc_limit_point)){
            vtb_s32_float_t div_result = vtb_div_s32_u32(QUARTER, abs_gained_sample);
            vtb_s32_float_t output_normalised = vtb_sub_s32_s32(ONE, div_result);
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
