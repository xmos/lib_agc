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
#include <stdio.h>
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

static void agc_set_gain(int &shift, uint32_t &gain, int32_t db) {
    // First convert dB to log-base-2, in 10.22 format
    db = (db * 5573271LL) >> 27;
    shift = db >> 22;  // Now split in shift and fraction; offset shift
    db -= (shift << 22);   // remove shift from fraction
    db = (db * 11629080LL) >> 22; // convert back to base E
    gain = dsp_math_exp(db);      // And convert to multiplier
}

void agc_set_gain_db(agc_state_t &agc, unsigned channel, int32_t db) {
    ASSERT(db < 128 && db > -128);
    agc_set_gain(agc.channel_state[channel].gain_exp, agc.channel_state[channel].gain, db << 24);
}


void agc_init(agc_state_t &agc){
    for(unsigned ch=0;ch<AGC_CHANNELS;ch++){
        agc_init_channel(agc, ch);
    }
}
#include "audio_test_tools.h"
void agc_init_channel(agc_state_t &agc, unsigned channel) {
    agc_set_gain_db(agc, channel, 20);

    agc.channel_state[channel].gain = 18;
    agc.channel_state[channel].gain_exp = 0;
    printf("gain: %f\n", att_uint32_to_double( agc.channel_state[channel].gain,agc.channel_state[channel].gain_exp) );
}

{int32_t, int} multiply(int32_t a, int a_exp, uint32_t b, int b_exp){

    unsigned b_hr = clz(b);
    if(b_hr == 0){
        b_exp +=1;
        b>>=1;
    } else {
        b_exp -= (b_hr - 1);
        b <<= (b_hr - 1);
    }
    int32_t v = a;

    if (v<0) v=-v;

    unsigned a_hr = clz(v) - 1;

    a_exp -= a_hr;
    a <<= a_hr;

    int prod_exp = b_exp + a_exp + 31;

    int32_t prod = ((int64_t)a * (int64_t)b)>>31;

    return {prod, prod_exp};
}

{uint32_t, int} absolute(int32_t a, int a_exp){
    if(a > 0){
        return {a, a_exp};
    } else {
        return {-a, a_exp};
    }
}

int is_greater_than(uint32_t a, int a_exp, uint32_t b, int b_exp){

    unsigned a_hr = clz(a);
    unsigned b_hr = clz(b);

    a <<= a_hr;
    a_exp -= a_hr;
    b <<= b_hr;
    b_exp -= b_hr;

    if(a_exp > b_exp){
        return 1;
    } else if (a_exp == b_exp){
        return (a>b);
    } else {
        return 0;
    }
}

{uint32_t, int} subtract(uint32_t a, int a_exp, uint32_t b, int b_exp){
   if(is_greater_than(a, a_exp, b, b_exp)){
       uint32_t r = a - (b >> (a_exp - b_exp));
       return {r, a_exp};
   } else {
       uint32_t r = b - (a >> (b_exp - a_exp));
       return {r, b_exp};
   }
}

{uint32_t, int} divide(uint32_t a, int a_exp, uint32_t b, int b_exp){

    unsigned a_hr = clz(a);
    unsigned b_hr = clz(b);

    a <<= a_hr;
    a_exp -= a_hr;
    b <<= b_hr;
    b_exp -= b_hr;

    uint32_t numerator = a;
    int numerator_exp = a_exp;

    uint32_t denominator = b;
    int denominator_exp = b_exp;

    if (numerator > denominator){
        numerator >>=1;
        numerator_exp += 1;
    }

    uint64_t t = (((uint64_t) numerator)<<32);
    uint32_t result = t / denominator;
    int result_exp = numerator_exp - denominator_exp -32;

    return {result, result_exp};
}

int32_t normalise_and_saturate(int32_t gained_sample, int gained_sample_exp, int input_exponent){

    int32_t v = gained_sample;
    if(v<0) v=-v;
    unsigned hr = clz(v)-1;

    gained_sample_exp -= hr;
    gained_sample <<= hr;

    if(gained_sample_exp > input_exponent){
        if(gained_sample > 0){
            return INT_MAX;
        } else {
            return INT_MIN;
        }
    } else {
        return gained_sample >> (input_exponent - gained_sample_exp);
    }
}

void agc_process_channel(agc_channel_state_t &agc,
                       dsp_complex_t samples[AGC_FRAME_ADVANCE], unsigned channel_number) {
    int imag_channel = channel_number&1;
    int input_exponent = -31;
    
#if AGC_DEBUG_PRINT
    printf("x[%u] = ", channel_number); att_print_python_td(samples, AGC_PROC_FRAME_LENGTH, input_exponent, imag_channel);
#endif
    uint32_t frame_energy;
    int frame_energy_exp;
    {frame_energy, frame_energy_exp} = vtb_get_td_frame_power(samples, input_exponent, AGC_FRAME_ADVANCE, imag_channel);

    int sqrt_energy_exp = frame_energy_exp;
    uint32_t sqrt_energy = frame_energy;

    vtb_sqrt(sqrt_energy, sqrt_energy_exp, 0);

    const int32_t one = INT_MAX;
    const int one_exp = -31;
    const int32_t half = INT_MAX;
    const int half_exp = -31 - 1;
    const int32_t quater = INT_MAX;
    const int quater_exp = -31 -2;

#if AGC_DEBUG_PRINT
    printf("sqrt_energy[%u] = %.22f\n", channel_number, att_uint32_to_double(sqrt_energy, sqrt_energy_exp));
#endif

    for(unsigned n = 0; n < AGC_FRAME_ADVANCE; n++) {
        int32_t input_sample = (samples[n], int32_t[2])[imag_channel];

        int32_t gained_sample;
        int gained_sample_exp;

        {gained_sample, gained_sample_exp} = multiply(input_sample, input_exponent, agc.gain, agc.gain_exp);
#if AGC_DEBUG_PRINT
    printf("gained_sample[%u] = %.22f\n", channel_number, att_uint32_to_double(gained_sample, gained_sample_exp));
#endif
        uint32_t abs_gained_sample;
        int abs_gained_sample_exp;

        {abs_gained_sample, abs_gained_sample_exp} = absolute(gained_sample, gained_sample_exp);

        if(is_greater_than(abs_gained_sample, abs_gained_sample_exp, half, half_exp)){

            int32_t div_result, nl_gain;
            int div_result_exp, nl_gain_exp;
            {div_result, div_result_exp} = divide(quater, quater_exp, abs_gained_sample, abs_gained_sample_exp);

            {nl_gain, nl_gain_exp} = subtract(one, one_exp, div_result, div_result_exp);

            int32_t output_sample = normalise_and_saturate(nl_gain, nl_gain_exp, input_exponent);

            if(input_sample < 0)
                output_sample =- output_sample;

            (samples[n], int32_t[2])[imag_channel] = output_sample;
        } else {
            int32_t output_sample = normalise_and_saturate(gained_sample, gained_sample_exp, input_exponent);
            (samples[n], int32_t[2])[imag_channel] = output_sample;
        }
    }
}

void agc_process_frame(agc_state_t &agc,
        dsp_complex_t frame[AGC_CHANNEL_PAIRS][AGC_FRAME_ADVANCE]){
#if AGC_DEBUG_PRINT
    printf("\n#%u\n", frame_counter++);
#endif
    for(unsigned ch=0;ch<AGC_CHANNELS;ch++){
        agc_process_channel(agc.channel_state[ch], frame[ch/2], ch);
    }

}

