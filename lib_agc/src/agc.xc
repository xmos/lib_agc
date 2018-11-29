// Copyright (c) 2017-2018, XMOS Ltd, All rights reserved
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

#define ASSERT(x)    asm("ecallf %0" :: "r" (x))


/** Gain is a real number between 0 and 128. It is represented by a
 * multiplier which in unsigned 8.24 format, and a shift right value.
 */

static void agc_set_gain(vtb_u32_float_t &gain, int32_t db) {
    // First convert dB to log-base-2, in 10.22 format
    db = (db * 5573271LL) >> 27;
    gain.e = db >> 22;  // Now split in shift and fraction; offset shift
    db -= (gain.e << 22);   // remove shift from fraction
    db = (db * 11629080LL) >> 22; // convert back to base E
    gain.m = dsp_math_exp(db);      // And convert to multiplier
}

void agc_set_gain_db(agc_state_t &agc, unsigned channel, int32_t db) {
    ASSERT(db < 128 && db > -128);
    agc_set_gain(agc.channel_state[channel].gain, db << 24);
}


void agc_init(agc_state_t &agc){
    for(unsigned ch=0;ch<AGC_CHANNELS;ch++){
        agc_set_gain_db(agc, ch, 20);
    }
}

// void agc_init_channel(agc_state_t &agc, unsigned channel) {
//
//
//     agc.channel_state[channel].gain.m = 18;
//     agc.channel_state[channel].gain.e = 0;
//
//     // agc.channel_state[channel].gain_exp = 0;
// }


// int32_t normalise_and_saturate(int32_t gained_sample, int gained_sample_exp, int input_exponent){
//
//     int32_t v = gained_sample;
//     if(v<0) v=-v;
//     unsigned hr = clz(v)-1;
//
//     gained_sample_exp -= hr;
//     gained_sample <<= hr;
//
//     if(gained_sample_exp > input_exponent){
//         if(gained_sample > 0){
//             return INT_MAX;
//         } else {
//             return INT_MIN;
//         }
//     } else {
//         return gained_sample >> (input_exponent - gained_sample_exp);
//     }
// }

void agc_process_channel(agc_channel_state_t &agc,
                       dsp_complex_t samples[AGC_FRAME_ADVANCE], unsigned channel_number) {
    int imag_channel = channel_number&1;
    int input_exponent = -31;

#if AGC_DEBUG_PRINT
    printf("x[%u] = ", channel_number); att_print_python_td(samples, AGC_PROC_FRAME_LENGTH, input_exponent, imag_channel);
#endif

    vtb_u32_float_t frame_energy = vtb_get_td_frame_power(samples, input_exponent, AGC_FRAME_ADVANCE, imag_channel);
    vtb_u32_float_t sqrt_energy = vtb_sqrt_u32(frame_energy); //TODO frame_energy and sqrt_energy aren't used.

    const vtb_s32_float_t one = {INT_MAX, -31};
    const vtb_s32_float_t half = {INT_MAX, -31-1};
    const vtb_s32_float_t quarter = {INT_MAX, -31-2};

#if AGC_DEBUG_PRINT
    printf("sqrt_energy[%u] = %.22f\n", channel_number, att_uint32_to_double(sqrt_energy.m, sqrt_energy.e));
#endif

    for(unsigned n = 0; n < AGC_FRAME_ADVANCE; n++) {
        vtb_s32_float_t input_sample = {(samples[n], int32_t[2])[imag_channel], input_exponent};
        vtb_s32_float_t gained_sample = vtb_mul_s32_u32(input_sample, agc.gain);
#if AGC_DEBUG_PRINT
    printf("gained_sample[%u] = %.22f\n", channel_number, att_uint32_to_double(gained_sample.m, gained_sample.e));
#endif
        vtb_u32_float_t abs_gained_sample = vtb_abs_s32_to_u32(gained_sample);
        vtb_u32_float_t half_unsigned = vtb_abs_s32_to_u32(half); //TODO possible unsigned conversion issue?

        if(vtb_gte_u32_u32(abs_gained_sample, half_unsigned)){
            vtb_s32_float_t div_result = vtb_div_s32_u32(quarter, abs_gained_sample);
            vtb_s32_float_t nl_gain = vtb_sub_s32_s32(one, div_result);
            int32_t output_sample = vtb_denormalise_and_saturate_s32(nl_gain, input_exponent);

            if(input_sample.m < 0){
                output_sample =- output_sample;
            }

            (samples[n], int32_t[2])[imag_channel] = output_sample;

        } else {
            int32_t output_sample = vtb_denormalise_and_saturate_s32(gained_sample, input_exponent);
            (samples[n], int32_t[2])[imag_channel] = output_sample;
        }
    }
}

void agc_process_frame(agc_state_t &agc, dsp_complex_t frame[AGC_CHANNEL_PAIRS][AGC_FRAME_ADVANCE]){
#if AGC_DEBUG_PRINT
    printf("\n#%u\n", frame_counter++);
#endif
    for(unsigned ch=0;ch<AGC_CHANNELS;ch++){
        agc_process_channel(agc.channel_state[ch], frame[ch/2], ch);
    }

}
