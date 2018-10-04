// Copyright (c) 2017, XMOS Ltd, All rights reserved
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

#define AGC_MANTISSA_UPPER_LIMIT (2U << 24)
#define AGC_MANTISSA_LOWER_LIMIT (1U << 24)

static uint32_t cls64(int64_t x) {
    if (x < 0) {
        x = ~x;
    }
    int bits = clz(x >> 32);
    if (x != 32) {
        return x;
    }
    bits = clz(x & 0xFFFFFFFF);
    return x + 32;
}

static void agc_set_gain(int &shift, uint32_t &gain, int32_t db) {
    // First convert dB to log-base-2, in 10.22 format
    db = (db * 5573271LL) >> 27;
    shift = db >> 22;  // Now split in shift and fraction; offset shift
    db -= (shift << 22);   // remove shift from fraction
    db = (db * 11629080LL) >> 22; // convert back to base E
    gain = dsp_math_exp(db);      // And convert to multiplier
}

static uint32_t agc_set_gain_no_shift(int32_t db) {
    int shl;
    uint32_t gain;
    agc_set_gain(shl, gain, db);
    if (shl < 0) {
        return gain >> -shl;
    } else {
        return gain << shl;
    }
}

static int32_t agc_get_gain_2(int shift, uint32_t gain) {
    int db = dsp_math_log(gain);
    db += (shift * 11629080LL);     // add ln(2^shift)
    db = (db * 72862523LL) >> 31;   // convert to 20*log(10) and into 16.16
    return db;
}

int32_t agc_get_gain(agc_state_t &agc, unsigned channel) {
    return agc_get_gain_2(agc.channel_state[channel].gain_exp, agc.channel_state[channel].gain);
}

void agc_set_gain_db(agc_state_t &agc, unsigned channel, int32_t db) {
    ASSERT(db < 128 && db > -128);
    agc_set_gain(agc.channel_state[channel].gain_exp, agc.channel_state[channel].gain, db << 24);
}

void agc_set_gain_max_db(agc_state_t &agc, unsigned channel, int32_t db) {
    ASSERT(db < 128 && db > -128);
    agc_set_gain(agc.channel_state[channel].max_gain_exp, agc.channel_state[channel].max_gain, db << 24);
}

void agc_set_gain_min_db(agc_state_t &agc, unsigned channel, int32_t db) {
    ASSERT(db < 128 && db > -128);
    agc_set_gain(agc.channel_state[channel].min_gain_exp, agc.channel_state[channel].min_gain, db << 24);
}

void agc_set_desired_db(agc_state_t &agc, unsigned channel, int32_t db) {
    agc.channel_state[channel].desired = agc_set_gain_no_shift(db << 24);
    agc.channel_state[channel].desired <<= 7;
    agc.channel_state[channel].desired_min = (agc.channel_state[channel].desired/3) * 2;
    agc.channel_state[channel].desired_max = (agc.channel_state[channel].desired>>1) * 3;
}

void agc_set_rate_up_dbps(agc_state_t &agc, unsigned channel, int32_t db) {
    ASSERT(db > 0);
    agc.channel_state[channel].up = agc_set_gain_no_shift(db * 1049);
}

void agc_set_rate_down_dbps(agc_state_t &agc, unsigned channel, int32_t db) {
    ASSERT(db < 0);
    agc.channel_state[channel].down = agc_set_gain_no_shift(db * 104900);
}

void agc_set_wait_for_up_ms(agc_state_t &agc, unsigned channel, uint32_t milliseconds) {
    agc.channel_state[channel].wait_for_up_samples = milliseconds * 16;
}

void agc_init(agc_state_t &agc){
    for(unsigned ch=0;ch<AGC_CHANNELS;ch++){
        agc_init_channel(agc, ch);
    }
}
void agc_init_channel(agc_state_t &agc, unsigned channel) {
    agc.channel_state[channel].state = AGC_STABLE;
    agc_set_gain_db(agc,channel, 0);
    agc_set_desired_db(agc,channel, -30);
    agc_set_gain_max_db(agc,channel, 127);
    agc_set_gain_min_db(agc,channel, -127);
    agc_set_rate_up_dbps(agc,channel, 7);
    agc_set_rate_down_dbps(agc,channel, -70);
    agc_set_wait_for_up_ms(agc,channel, 6000);
}

static void multiply_gain(agc_channel_state_t &agc, int mult) {

    agc.gain = (agc.gain * (uint64_t) mult) >> 24;

    if (agc.gain < AGC_MANTISSA_LOWER_LIMIT) {
        agc.gain <<= 1;
        agc.gain_exp--;
    } else if (agc.gain >= AGC_MANTISSA_UPPER_LIMIT) {
        agc.gain >>= 1;
        agc.gain_exp++;
    }
    uint32_t maxedout = (agc.gain_exp > agc.max_gain_exp ||
                         (agc.gain_exp == agc.max_gain_exp &&
                          agc.gain > agc.max_gain));
    if (maxedout) {
        agc.gain_exp = agc.max_gain_exp;
        agc.gain     = agc.max_gain;
    }
    uint32_t minedout = (agc.gain_exp < agc.min_gain_exp ||
                         (agc.gain_exp == agc.min_gain_exp &&
                          agc.gain < agc.min_gain));
    if (minedout) {
        agc.gain_exp = agc.min_gain_exp;
        agc.gain     = agc.min_gain;
    }
}

static int32_t clamp(int64_t sample) {
    if (sample >= 0x7FFFFFFFLL) {
        return 0x7FFFFFFF;
    }
    if (sample <= -0x80000000LL) {
        return 0x80000000;
    }
    return sample;
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

#if AGC_DEBUG_PRINT
    printf("sqrt_energy[%u] = %.22f\n", channel_number, att_uint32_to_double(sqrt_energy, sqrt_energy_exp));
#endif

    if (sizeof(agc.sqrt_energy_fifo)) {
        //TODO add sqrt_energy to sqrt_energy_fifo
        //TODO sqrt_energy =  average all energy in the sqrt_energy_fifo
    }
    
    //average_energy_buffer_energy_p
    uint64_t energy = (sqrt_energy * (uint64_t) agc.gain) >> (24 - agc.gain_exp);
    
    for(unsigned n = 0; n < AGC_FRAME_ADVANCE; n++) {
        switch(agc.state) {
        case AGC_STABLE:
            if (energy > agc.desired_max) {
                agc.state = AGC_DOWN;
            } else if (energy < agc.desired_min) {
                agc.state = AGC_WAIT;
                agc.wait_samples = agc.wait_for_up_samples;
            }
            break;
        case AGC_UP:
            multiply_gain(agc, agc.up);
            if (energy > agc.desired) {
                agc.state = AGC_STABLE;
            }
            break;
        case AGC_DOWN:
            multiply_gain(agc, agc.down);
            if (energy < agc.desired) {
                agc.state = AGC_STABLE;
            }
            break;
        case AGC_WAIT:
            if (energy > agc.desired_max) {
                agc.state = AGC_DOWN;
            } else if (energy < agc.desired_min) {
                if (agc.wait_samples == 0) {
                    agc.state = AGC_UP;
                } else {
                    agc.wait_samples--;
                }
            } else {
                agc.state = AGC_STABLE;
            }
            break;
        default:
            __builtin_unreachable();
            break;
        }
        energy = (sqrt_energy * (uint64_t) agc.gain) >> (24 - agc.gain_exp);

        int32_t input_sample;
        int32_t input_exp;
        if (agc.look_ahead_frames > 0) {
#if AGC_LOOK_AHEAD_FRAMES > 0
            input_sample = agc.sample_buffer[n];
            input_exp = agc.sample_buffer[AGC_PROC_FRAME_LENGTH];
            for(uint32_t k = 1; k < agc.look_ahead_frames; k++) {
                agc.sample_buffer[n+(k-1)*(AGC_PROC_FRAME_LENGTH+1)] =
                        agc.sample_buffer[n+k*(AGC_PROC_FRAME_LENGTH+1)];
            }
            agc.sample_buffer[n+(agc.look_ahead_frames-1)*(AGC_PROC_FRAME_LENGTH+1)] =
                    (samples[n], int32_t[2])[imag_channel];
#endif
        } else {
            input_sample = (samples[n], int32_t[2])[imag_channel];
            input_exp = input_exponent;
        }
        
        int64_t gained_sample = input_sample * (int64_t) agc.gain;
        int32_t gained_shift_r = 24 - agc.gain_exp;
        int32_t output_sample;
        if (gained_shift_r > 0) {
            gained_sample >>= gained_shift_r;
            output_sample = clamp(gained_sample);
        } else {
            gained_shift_r = -gained_shift_r;
            int headroom = cls64(gained_sample);
            if (headroom >= gained_shift_r) {
                gained_sample <<= gained_shift_r;
                output_sample = clamp(gained_sample);
            } else if(gained_sample < 0) {
                output_sample = 0x80000000;
            } else {
                output_sample = 0x7FFFFFFF;
            }
        }
        (samples[n], int32_t[2])[imag_channel] = output_sample;
    }
    if (agc.look_ahead_frames != 0) {
        const uint32_t n = AGC_PROC_FRAME_LENGTH;
        for(uint32_t k = 1; k < agc.look_ahead_frames; k++) {
            agc.sample_buffer[n+(k-1)*(AGC_PROC_FRAME_LENGTH+1)] =
                agc.sample_buffer[n+k*(AGC_PROC_FRAME_LENGTH+1)];
        }
        agc.sample_buffer[n+(agc.look_ahead_frames-1)*(AGC_PROC_FRAME_LENGTH+1)] =
            input_exponent;
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

