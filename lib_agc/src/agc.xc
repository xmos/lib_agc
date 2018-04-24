// Copyright (c) 2017, XMOS Ltd, All rights reserved
#include <stdio.h>
#include <stdint.h>
#include <dsp.h>
#include <xclib.h>
#include <xs1.h>
#include "agc.h"

#define ASSERT(x)    asm("ecallf %0" :: "r" (x))

/** Gain is a real number between 0 and 128. It is represented by a
 * multiplier which in unsigned 8.24 format, and a shift right value.
 */

#define AGC_MANTISSA_UPPER_LIMIT (2U << 24)
#define AGC_MANTISSA_LOWER_LIMIT (1U << 24)

#define LOG_AGC_WINDOW_LENGTH   7
#define AGC_WINDOW_LENGTH   (1<<LOG_AGC_WINDOW_LENGTH)


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

static void agc_set_gain(int32_t &shift, uint32_t &gain, int32_t db) {
    // First convert dB to log-base-2, in 10.22 format
    db = (db * 5573271LL) >> 27;
    shift = db >> 22;  // Now split in shift and fraction; offset shift
    db -= (shift << 22);   // remove shift from fraction
    db = (db * 11629080LL) >> 22; // convert back to base E
    gain = dsp_math_exp(db);      // And convert to multiplier
}

static uint32_t agc_set_gain_no_shift(int32_t db) {
    int32_t shl;
    uint32_t gain;
    agc_set_gain(shl, gain, db);
    if (shl < 0) {
        return gain >> -shl;
    } else {
        return gain << shl;
    }
}

static int32_t agc_get_gain_2(uint32_t shift, uint32_t gain) {
    int db = dsp_math_log(gain);
    db += (shift * 11629080LL);     // add ln(2^shift)
    db = (db * 72862523LL) >> 31;   // convert to 20*log(10) and into 16.16
    return db;
}

int32_t agc_get_gain(agc_state_t &agc) {
    return agc_get_gain_2(agc.gain_shl, agc.gain);
}

void agc_set_gain_db(agc_state_t &agc, int32_t db) {
    ASSERT(db < 128 && db > -128);
    agc_set_gain(agc.gain_shl, agc.gain, db << 24);
}

void agc_set_gain_max_db(agc_state_t &agc, int32_t db) {
    ASSERT(db < 128 && db > -128);
    agc_set_gain(agc.max_gain_shl, agc.max_gain, db << 24);
}

void agc_set_gain_min_db(agc_state_t &agc, int32_t db) {
    ASSERT(db < 128 && db > -128);
    agc_set_gain(agc.min_gain_shl, agc.min_gain, db << 24);
}

void agc_set_desired_db(agc_state_t &agc, int32_t db) {
    agc.desired = agc_set_gain_no_shift(db << 24);
    agc.desired <<= 7;
    agc.desired_min = (agc.desired/3) * 2;
    agc.desired_max = (agc.desired>>1) * 3;
}

void agc_set_rate_up_dbps(agc_state_t &agc, int32_t db) {
    ASSERT(db > 0);
    agc.up = agc_set_gain_no_shift(db * 1049);
}

void agc_set_rate_down_dbps(agc_state_t &agc, int32_t db) {
    ASSERT(db < 0);
    agc.down = agc_set_gain_no_shift(db * 104900);
}

void agc_set_wait_for_up_ms(agc_state_t &agc, uint32_t milliseconds) {
    agc.wait_for_up_samples = milliseconds * 16;
}

void agc_set_look_past_frames(agc_state_t &agc, uint32_t look_past_frames) {
    agc.look_past_frames = look_past_frames;
}

void agc_set_look_ahead_frames(agc_state_t &agc, uint32_t look_ahead_frames) {
    agc.look_ahead_frames = look_ahead_frames;
}

void agc_init(agc_state_t &agc, uint32_t frame_length) {
    agc.state = AGC_STABLE;
    agc.look_past_frames = 0;
    agc.look_ahead_frames = 0;
    agc_set_gain_db(agc, 0);
    agc_set_desired_db(agc, -30);
    agc_set_gain_max_db(agc, 127);
    agc_set_gain_min_db(agc, -127);
    agc_set_rate_up_dbps(agc, 7);
    agc_set_rate_down_dbps(agc, -70);
    agc_set_wait_for_up_ms(agc, 6000);
    agc.frame_length = frame_length;
}

static void multiply_gain(agc_state_t &agc, int mult) {
    agc.gain = (agc.gain * (uint64_t) mult) >> 24;

    if (agc.gain < AGC_MANTISSA_LOWER_LIMIT) {
        agc.gain <<= 1;
        agc.gain_shl--;
    } else if (agc.gain >= AGC_MANTISSA_UPPER_LIMIT) {
        agc.gain >>= 1;
        agc.gain_shl++;
    }
    uint32_t maxedout = (agc.gain_shl > agc.max_gain_shl ||
                         (agc.gain_shl == agc.max_gain_shl &&
                          agc.gain > agc.max_gain));
    if (maxedout) {
        agc.gain_shl = agc.max_gain_shl;
        agc.gain     = agc.max_gain;
    }
    uint32_t minedout = (agc.gain_shl < agc.min_gain_shl ||
                         (agc.gain_shl == agc.min_gain_shl &&
                          agc.gain < agc.min_gain));
    if (minedout) {
        agc.gain_shl = agc.min_gain_shl;
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

void agc_process_frame(agc_state_t &agc,
                       int32_t samples[],
                       int32_t shr,
                       int32_t (&?sample_buffer)[],
                       uint32_t (&?energy_buffer)[]) {
    
    uint64_t sss = 0; // Sum of Square Signals
    int logN = 31 - clz(agc.frame_length);
    for(uint32_t n = 0; n < agc.frame_length; n++) {
        sss += (samples[n] * (int64_t) samples[n]) >> logN;
    }
    sss = sss >> (shr * 2);
    uint32_t sqrt_energy = dsp_math_int_sqrt64(sss);

    if (!isnull(energy_buffer)) {
        uint32_t energy_nitems =  agc.look_ahead_frames + agc.look_past_frames + 1;
        for(uint32_t i = 1; i < energy_nitems; i++) {
            energy_buffer[i-1] = energy_buffer[i];
        }
        energy_buffer[energy_nitems-1] = sqrt_energy;
        uint64_t total_energy = 0;
        for(uint32_t i = 0; i < energy_nitems; i++) {
            total_energy += energy_buffer[i];
        }
        sqrt_energy = total_energy / energy_nitems;
    }
    
    uint64_t energy = (sqrt_energy * (uint64_t) agc.gain) >> (24 - agc.gain_shl);

//    printf("Actual energy %u  postgain %lld desired %d\n", sqrt_energy, energy, agc.desired);
//    printf("[%d..%d]  %d\n", agc.desired_min, agc.desired_max, agc.state);
    
    for(uint32_t n = 0; n < agc.frame_length; n++) {
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
        energy = (sqrt_energy * (uint64_t) agc.gain) >> (24 - agc.gain_shl);

        int32_t input_sample;
        int32_t input_shr;
        if (agc.look_ahead_frames != 0) {
            input_sample = sample_buffer[n];
            input_shr = sample_buffer[agc.frame_length];
            for(uint32_t k = 1; k < agc.look_ahead_frames; k++) {
                sample_buffer[n+(k-1)*(agc.frame_length+1)] = 
                    sample_buffer[n+k*(agc.frame_length+1)];
            }
            sample_buffer[n+(agc.look_ahead_frames-1)*(agc.frame_length+1)] =
                samples[n];
        } else {
            input_sample = samples[n];
            input_shr = shr;
        }
        
        int64_t gained_sample = input_sample * (int64_t) agc.gain;
        int32_t gained_shift_r = 24 - agc.gain_shl + input_shr;
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
//        printf("%08x -> %016llx -> %08x %2d %08x\n", samples[n], gained_sample, output_sample, agc.gain_shl, agc.gain);
        samples[n] = output_sample;
    }
    if (agc.look_ahead_frames != 0) {
        const uint32_t n = agc.frame_length;
        for(uint32_t k = 1; k < agc.look_ahead_frames; k++) {
            sample_buffer[n+(k-1)*(agc.frame_length+1)] = 
                sample_buffer[n+k*(agc.frame_length+1)];
        }
        sample_buffer[n+(agc.look_ahead_frames-1)*(agc.frame_length+1)] =
            shr;
    }
}

