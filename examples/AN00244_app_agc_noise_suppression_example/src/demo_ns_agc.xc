// Copyright (c) 2016-2017, XMOS Ltd, All rights reserved

#include <xs1.h>
#include <stdint.h>
#include <stdio.h>

#include "agc.h"
#include "demo_ns_agc.h"

#define AGC_FRAME_LENGTH 128

void noise_suppression_automatic_gain_control_task(chanend audio_input,
                                                   chanend audio_output) {
    timer tmr;
    int32_t t0, t1, t2;
    agc_state_t agc;
//    ns_state_t ns;
    int32_t samples[AGC_FRAME_LENGTH];
    int32_t headroom;
    uint32_t cnt = 0;
    
    agc_init_state(agc, 10, -12, AGC_FRAME_LENGTH, 0, 0);
//    ns_init_state(ns, AGC_FRAME_LENGTH);
    
    while(1) {
        cnt++;
        audio_input :> headroom;
        for(int i = 0; i < AGC_FRAME_LENGTH; i++) {
            audio_input :> samples[i];
        }
        
        tmr :> t0;
//        ns_block(ns, samples, headroom);
        tmr :> t1;
        agc_block(agc, samples, headroom, null, null);
        tmr :> t2;
        if ((cnt & 15) == 0) {
            printf("%6d %3d\n", agc_get_gain(agc) >> 24);
        }
        
        for(int i = 0; i < AGC_FRAME_LENGTH; i++) {
            audio_output <: samples[i];
        }
    }
}
