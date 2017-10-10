// Copyright (c) 2017, XMOS Ltd, All rights reserved
#include <math.h>

#include "agc.h"

#if 0
#include <math.h>
#include <stdio.h>
#include <fftw3.h>

#define WAIT_FOR_DECAY_FRAMES 500
#define MAX_GAIN  (8*65536*2)
#define INIT_GAIN  (MAX_GAIN)

#define FRAME_LENGTH 128

typedef struct {
    double re, im;
    double phase;
    double mag;
    double mm;
} lib_dsp_fft_complex_t;

fftw_plan p, pi;
fftw_complex *in, *out;

double window[FRAME_LENGTH];

static void fft_in() {
#define N FRAME_LENGTH
    in = (fftw_complex*) fftw_malloc(sizeof(fftw_complex) * N);
    out = (fftw_complex*) fftw_malloc(sizeof(fftw_complex) * N);
    p = fftw_plan_dft_1d(N, in, out, FFTW_FORWARD, FFTW_ESTIMATE);
    pi = fftw_plan_dft_1d(N, in, out, FFTW_BACKWARD, FFTW_ESTIMATE);
    for(int i = 0; i < FRAME_LENGTH; i++) {
        window[i] = sqrt(0.5 * (1-cos(i/(double)(FRAME_LENGTH-1) * 3.1415926536 * 2)));
    }
}

void fft(lib_dsp_fft_complex_t pts[],
                         int inp[]) {
    for(int i = 0; i < FRAME_LENGTH; i++) {
        in[i][0]     = inp[i] * window[i];
        in[i][1]     = 0;
//        printf("%3d %f %d %f\n", i, in[i][0], inp[i], window[i]);
    }
         
    fftw_execute(p);
    
    for(int i = 0; i < FRAME_LENGTH; i++) {
        pts[i].re = out[i][0];
        pts[i].im = out[i][1];
//        printf("%3d %f %f\n", i, out[i][0], out[i][1]);
    }
}

void fft_inverse(double outp[],lib_dsp_fft_complex_t inp[]) {
    for(int i = 0; i < FRAME_LENGTH; i++) {
        in[i][0]     = inp[i].re;//*window[i];
        in[i][1]     = inp[i].im;//*window[i];
//        printf("%3d %f %d %f\n", i, in[i][0], inp[i], window[i]);
    }
         
    fftw_execute(pi);
    
    for(int i = 0; i < FRAME_LENGTH; i++) {
        outp[i] = out[i][0]/FRAME_LENGTH;
//        printf("%3d %f %f\n", i, out[i][0], out[i][1]);
    }
}


int past[7][FRAME_LENGTH];

int read_sample(FILE *fd) {
    unsigned c0 = getc(fd);
    unsigned c1 = getc(fd);
    short i = c0 | c1 << 8;
    return i;
}

void write_sample(FILE *fd, short i) {
    unsigned c0 = i & 0xff;
    unsigned c1 = (i >> 8) & 0xff;
    putc(c0, fd);
    putc(c1, fd);
}


double wavelength[FRAME_LENGTH/2];
lib_dsp_fft_complex_t spectre[FRAME_LENGTH];
lib_dsp_fft_complex_t avgspectre[FRAME_LENGTH];
double output[FRAME_LENGTH];
double real_output[FRAME_LENGTH];
int past[7][FRAME_LENGTH];

int clip(double v) {
    if (v > 0x7fff) return 0x7fff;
    if (v < -0x8000) return -0x8000;
    return v;
}
int main(int argc, char *argv[]) {
    FILE *fd = fopen(argv[1], "rb");
    fft_in();
    FILE *ofd = fopen(argv[2], "wb");
    for(int i = 0; i < 44; i++) {
        unsigned c = getc(fd);
        putc(c, ofd);
    }

    int mode = AGC_STABLE;
    int wait_frames = 100;
    double gain = INIT_GAIN;
    double maxfactor = 0.0625;
    double factors[FRAME_LENGTH/2];
    double is_noise[FRAME_LENGTH/2];
    double last_mag[FRAME_LENGTH/2];
    
    for(int n = 0; n < FRAME_LENGTH/2; n++) {
        factors[n] = maxfactor;
        is_noise[n] = 1.0;
        last_mag[n] = 0;
    }
    while(!feof(fd)) {
        for(int n = 0; n < FRAME_LENGTH/2; n++) {
            for(int i = 0; i < 7; i++) {
                past[i][n] = past[i][n+FRAME_LENGTH/2];
            }
            real_output[n] = real_output[n+FRAME_LENGTH/2];
            real_output[n+FRAME_LENGTH/2] = 0;
        }
        for(int n = 0; n < FRAME_LENGTH/2; n++) {
            for(int i = 0; i < 7; i++) {
                past[i][n+FRAME_LENGTH/2] = read_sample(fd);
            }
        }
        fft(spectre, past[1]);
        spectre[0].re = 0;
        spectre[1].re = 0;
        spectre[FRAME_LENGTH-1].re = 0;
        spectre[0].im = 0;
        spectre[1].im = 0;
        spectre[FRAME_LENGTH-1].im = 0;
        double energy = 0.0;
        double sum = 0;
        for(int n = 0; n < FRAME_LENGTH/2; n++) {
            double mag = hypot(spectre[n].im, spectre[n].re);
            sum += mag;
        }
        for(int n = 0; n < FRAME_LENGTH/2; n++) {
            double mag = hypot(spectre[n].im, spectre[n].re);
            avgspectre[n].mag = 0.99 * avgspectre[n].mag + 0.01 * mag;
//            printf("%.0f,", mag);
#if 0
            double f;
            avgspectre[n].mag = 900 + 500 * n / 64.0;
            double newfactor;
            if (mag > 1.5 * avgspectre[n].mag) {
                newfactor = 1;
            } else {
                newfactor = maxfactor;
            }
            factors[n] = factors[n] * 0.9 + newfactor * 0.1;
            f = factors[n];
#endif
#if 1
            double f;
            double avg = 550 + 500 * n / 64.0;
            double stddev = 300;
            double lower_limit = avg + 0*stddev;
            double upper_limit = avg + 2*stddev;
            if (is_noise[n]) {
                if (last_mag[n] + mag > 2  * upper_limit) {
                    is_noise[n] = 0;
                }
            } else {
                if (last_mag[n] + mag < 2  * lower_limit) {
                    is_noise[n] = 1;
                }
            }
            last_mag[n] = mag;
            f = is_noise[n] ? 0.0625 : 1.000 ;
#endif
//            f = (1/(1+exp(-mag/120.0+10.0)));
//            if (f < maxfactor)  f = maxfactor;
//            f = 1/((2000.0/mag)+1);
            spectre[n].im *= f;
            spectre[n].re *= f;
            spectre[FRAME_LENGTH - n].im *= f;
            spectre[FRAME_LENGTH - n].re *= f;
            energy += f * mag;
        }
        fft_inverse(output, spectre);
        for(int n = 0; n < FRAME_LENGTH; n++) {
            real_output[n] += output[n] * window[n];
        }
        
        double desired_max = 2000000.0*65536.0 * 0.7;
        double desired_mid = 2000000.0*32768.0;
        double desired_min = 2000000.0*16384.0 * 1.4;
//        printf("Energy %f gain %f\n", energy, gain);
        energy *= gain;
        
        switch(mode) {
        case AGC_STABLE:
            if (energy > desired_max) {
                mode = AGC_DOWN;
            } else if (energy < desired_min) {
                mode = WAIT_FOR_DECAY;
                wait_frames = WAIT_FOR_DECAY_FRAMES;
            }
            break;
        case AGC_UP:
            if (energy > desired_mid) {
                mode = AGC_STABLE;
            }
            break;
        case AGC_DOWN:
            if (energy < desired_mid) {
                mode = AGC_STABLE;
            }
            break;
        case WAIT_FOR_DECAY:
            if (energy > desired_max) {
                mode = AGC_DOWN;
            } else if (energy < desired_min) {
                wait_frames--;
                if (wait_frames <= 0) {
                    mode = AGC_UP;
                }
            } else {
                mode = AGC_STABLE;
            }
            break;
        }
        for(int n = 0; n < FRAME_LENGTH/2; n++) {
            gained_sample[n] = clip(real_output[n]*gain/65536);
            switch(mode) {
            case AGC_UP:
                gain = gain * 1.0001;
                break;
            case AGC_DOWN:
                gain = gain * 0.999;
                break;
            }
            if (gain > MAX_GAIN) gain = MAX_GAIN;
            if (gain < 1) gain = 1;
        }
    }
}
#endif

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
    db += (shift * 11629080LL); // add ln(2^shift)
    db = (db * 72862523LL) >> 31;      // convert to 20*log(10) and into 16.16
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
    agc.down = agc_set_gain_no_shift(db * 1049);
}

void agc_set_wait_for_up_ms(agc_state_t &agc, uint32_t milliseconds) {
    agc.wait_for_up_samples = milliseconds * 16;
}

void agc_init_state(agc_state_t &agc,
                    int32_t initial_gain_db,
                    int32_t desired_energy_db,
                    uint32_t frame_length,
                    uint32_t look_ahead_frames,
                    uint32_t look_past_frames) {
    agc.frame_length = frame_length;
    agc.look_ahead_frames = look_ahead_frames;
    agc.look_past_frames = look_past_frames;
    agc.state = AGC_STABLE;
    agc_set_gain_db(agc, initial_gain_db);
    agc_set_desired_db(agc, desired_energy_db);
    agc_set_gain_max_db(agc, 127);
    agc_set_gain_min_db(agc, -127);
    agc_set_rate_up_dbps(agc, 7);
    agc_set_rate_down_dbps(agc, -70);
    agc_set_wait_for_up_ms(agc, 4000);
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

void agc_block(agc_state_t &agc,
               int32_t samples[],
               int32_t shr,
               int32_t (&?sample_buffer)[],
               int32_t (&?energy_buffer)[]) {
    
    uint64_t sss = 0; // Sum of Square Signals
    int logN = 31 - clz(agc.frame_length);
    for(int n = 0; n < agc.frame_length; n++) {
        sss += (samples[n] * (int64_t) samples[n]) >> logN;
    }
    sss = sss >> (shr * 2);
    uint32_t sqrt_energy = dsp_math_int_sqrt64(sss);
    
    uint64_t energy = (sqrt_energy * (uint64_t) agc.gain) >> (24 - agc.gain_shl);

//    printf("Actual energy %u  postgain %lld desired %d\n", sqrt_energy, energy, agc.desired);
//    printf("[%d..%d]  %d\n", agc.desired_min, agc.desired_max, agc.state);
    
    for(int n = 0; n < agc.frame_length; n++) {
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
        }
        energy = (sqrt_energy * (uint64_t) agc.gain) >> (24 - agc.gain_shl);
        int64_t gained_sample = samples[n] * (int64_t) agc.gain;
        int32_t gained_shift_r = 24 - agc.gain_shl + shr;
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
}

