// Copyright (c) 2016-2017, XMOS Ltd, All rights reserved

#include <xs1.h>
#include <stdint.h>
#include <stdio.h>

#include "agc.h"
#include "noise_suppression.h"
#include "demo_ns_agc.h"

void noise_suppression_automatic_gain_control_task(chanend audio_input,
                                                   chanend audio_output) {
    timer tmr;
    int32_t t0, t1, t2;
    agc_state_t agc;
    ns_state_t ns;
    ns_tuning_params_t ns_tune;
    int32_t samples[DEMO_NS_AGC_FRAME_LENGTH];
    int32_t samples_out[DEMO_NS_AGC_FRAME_LENGTH];
    int32_t headroom;
    int headroom_out;
    uint32_t cnt = 0;
    
    agc_init_state(agc, 10, -12, DEMO_NS_AGC_FRAME_LENGTH, 0, 0);
    ns_init_state(ns);
    ns_init_params(ns_tune);
    
    while(1) {
        cnt++;
        audio_input :> headroom;
        for(int i = 0; i < DEMO_NS_AGC_FRAME_LENGTH; i++) {
            audio_input :> samples[i];
        }
        
        tmr :> t0;
        ns_process_frame(samples, headroom, ns, ns_tune, samples_out, headroom_out);
        tmr :> t1;
        agc_block(agc, samples, headroom, null, null);
        tmr :> t2;
        if ((cnt & 15) == 0) {
            printf("%6d %3d\n", agc_get_gain(agc) >> 24);
        }
        
        for(int i = 0; i < DEMO_NS_AGC_FRAME_LENGTH; i++) {
            audio_output <: samples[i];
        }
    }
}
