// Copyright (c) 2016-2017, XMOS Ltd, All rights reserved

#include <xs1.h>
#include <stdint.h>
#include <stdio.h>
#include <print.h>
#include <xscope.h>

#include "agc.h"
#include "noise_suppression_new.h"
#include "ns_agc.h"

void noise_suppression_automatic_gain_control_task(chanend audio_input,
                                                   chanend audio_output,
                                                   chanend from_buttons) {
    timer tmr;
    int32_t t0, t1, t2;
    agc_state_t agc;
    ns_state_t ns;
    uint64_t ns_data[NS_PERSISTENT_ARRAY_SIZE(DEMO_NS_AGC_FRAME_LENGTH)];
    int32_t samples[DEMO_NS_AGC_FRAME_LENGTH*2];
    int32_t samples_out[DEMO_NS_AGC_FRAME_LENGTH];
    int32_t debug_input[DEMO_NS_AGC_FRAME_LENGTH];
    int32_t headroom;
    int headroom_out;
    uint32_t cnt = 0;
    int keep_noise = 1;
    agc_init_state(agc, 0, -40, DEMO_NS_AGC_FRAME_LENGTH, 0, 0);
    ns_init_state(ns, ns_data, DEMO_NS_AGC_FRAME_LENGTH);

    while(1) {
        cnt++;
        audio_input :> headroom;
        for(int i = 0; i < DEMO_NS_AGC_FRAME_LENGTH; i++) {
            int32_t sample;
            samples[i] = samples[i + DEMO_NS_AGC_FRAME_LENGTH];
            audio_input :> sample;
            samples[i + DEMO_NS_AGC_FRAME_LENGTH] = sample;
            debug_input[i] = sample;
        }

        tmr :> t0;
        select {
            case from_buttons:> keep_noise: break;
            default: break;
        }
        if (!keep_noise) {
            ns_process_frame(samples_out, headroom_out, ns, samples, headroom);
        } else {
            for(int i = 0; i < DEMO_NS_AGC_FRAME_LENGTH; i++) {
                samples_out[i] = samples[i+DEMO_NS_AGC_FRAME_LENGTH];
            }
            headroom_out = headroom+1;
        }
        if (headroom_out < 0) headroom_out = 0;

        tmr :> t1;
        agc_process_frame(agc, samples_out, headroom_out, null, null);
        tmr :> t2;
        if ((cnt & 15) == 0) {
            printf("%d %d  %d\n", t1-t0, t2-t1, agc_get_gain(agc) >> 16);
        }
        
        if(1) {
            for(int i = 0; i < DEMO_NS_AGC_FRAME_LENGTH; i++) {
                audio_output <: samples_out[i];
            }
        } else {
            for(int i = 0; i < DEMO_NS_AGC_FRAME_LENGTH; i++) {
                audio_output <: debug_input[i];
            }
        }
    }
}
