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




void agc_set_channel_gain(agc_state_t &agc, unsigned channel, uint32_t gain) {
    agc.ch_state[channel].gain.m = gain;
    agc.ch_state[channel].gain.e = 0;

    if(agc.ch_state[channel].gain.m == 0){
        agc.ch_state[channel].gain.m = 1;
    }

    vtb_normalise_u32(agc.ch_state[channel].gain);
}

void agc_init(agc_state_t &agc){
    for(unsigned ch=0;ch<AGC_CHANNELS;ch++){
        agc_set_channel_gain(agc, ch, AGC_GAIN);
    }
}

static void agc_process_channel(agc_channel_state_t &agc_state, dsp_complex_t samples[AGC_FRAME_ADVANCE], unsigned ch_index) {
    // const vtb_s32_float_t one = {INT_MAX, -31};
    const vtb_u32_float_t AGC_LIMIT_POINT = {UINT_MAX, -32-1};
    const vtb_s32_float_t QUARTER = {INT_MAX, -31-2};
    const vtb_s32_float_t ONE = {INT_MAX, -31};

    // const vtb_s32_float_t quarter = {INT_MAX, -31-2};

    int input_exponent = -31;

    for(unsigned n = 0; n < AGC_FRAME_ADVANCE; n++) {
        vtb_s32_float_t input_sample = {(samples[n], int32_t[2])[ch_index&1], input_exponent};
        vtb_normalise_s32(input_sample);

        vtb_s32_float_t gained_sample = vtb_mul_s32_u32(input_sample, agc_state.gain);

        #if AGC_DEBUG_PRINT
            printf("input_sample[%u] = %d\n", ch_index, (samples[n], int32_t[2])[ch_index&1]);
            printf("input_sample[%u] = %.22f\n", ch_index, att_uint32_to_double(input_sample.m, input_sample.e));
            printf("gained_sample[%u] = %.22f\n", ch_index, att_uint32_to_double(gained_sample.m, gained_sample.e));
        #endif

        vtb_u32_float_t abs_gained_sample = vtb_abs_s32_to_u32(gained_sample);

        if(vtb_gte_u32_u32(abs_gained_sample, AGC_LIMIT_POINT)){
            vtb_s32_float_t div_result = vtb_div_s32_u32(QUARTER, abs_gained_sample);
            vtb_s32_float_t output_normalised = vtb_sub_s32_s32(ONE, div_result);
            int32_t output_sample = vtb_denormalise_and_saturate_s32(output_normalised, input_exponent);

            #if AGC_DEBUG_PRINT
                printf("output_normalised[%u] = %.22f\n", ch_index, att_uint32_to_double(output_normalised.m, output_normalised.e));
                printf("output_sample[%u] = %d\n", ch_index, output_sample);
            #endif

            if(input_sample.m < 0){
                output_sample =- output_sample;
            }
            (samples[n], int32_t[2])[ch_index&1] = output_sample;
        }
        else {
            int32_t output_sample = vtb_denormalise_and_saturate_s32(gained_sample, input_exponent);
            (samples[n], int32_t[2])[ch_index&1] = output_sample;
            #if AGC_DEBUG_PRINT
                printf("output_sample[%u] = %d\n", ch_index, output_sample);
            #endif
        }

    }
}

void agc_process_frame(agc_state_t &agc, dsp_complex_t frame[AGC_CHANNEL_PAIRS][AGC_FRAME_ADVANCE]){
    #if AGC_DEBUG_PRINT
        printf("\n#%u\n", frame_counter++);
    #endif
    for(unsigned ch=0;ch<AGC_CHANNELS;ch++){
        agc_process_channel(agc.ch_state[ch], frame[ch/2], ch);
    }

}
