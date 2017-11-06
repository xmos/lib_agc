// Copyright (c) 2016-2017, XMOS Ltd, All rights reserved

#include <xs1.h>
#include <stdint.h>
#include <stdio.h>
#include <print.h>
#include <xscope.h>

#include "agc.h"
#include "noise_suppression.h"
#include "ns_agc.h"

extern int32_t buffer_out[2][SYSTEM_FRAME_ADVANCE];

void noise_suppression_automatic_gain_control_task(chanend audio_input,
                                                   chanend audio_output,
                                                   chanend from_buttons) {
    timer tmr;
    int32_t t0, t1, t2;
    agc_state_t [[aligned(8)]] agc;
    ns_state_t ns;
    int32_t samples[NS_PROC_FRAME_LENGTH];
    int32_t samples_out[NS_FRAME_ADVANCE];
    uint64_t rx_state[DSP_BFP_RX_STATE_UINT64_SIZE(1, NS_PROC_FRAME_LENGTH, NS_FRAME_ADVANCE)];
    int32_t headroom;
    int headroom_out;
    uint32_t cnt = 0;
    int keep_noise = 1;
    agc_init_state(agc, 0, -40, NS_FRAME_ADVANCE, 0, 0);
    ns_init_state(ns);
    dsp_bfp_rx_state_init_xc(rx_state,DSP_BFP_RX_STATE_UINT64_SIZE(1, NS_PROC_FRAME_LENGTH, NS_FRAME_ADVANCE)); 
    int out_buff = 0;
    
    while(1) {
        cnt++;
        headroom = dsp_bfp_rx_xc(audio_input, rx_state, samples,
                                 NS_CHANNELS, NS_PROC_FRAME_LENGTH,
                                 NS_FRAME_ADVANCE, 1);

        tmr :> t0;
        select {
            case from_buttons:> keep_noise: break;
            default: break;
        }
        if (!keep_noise) {
            ns_process_frame(samples_out, headroom_out, ns, samples, headroom);
        } else {
            for(int i = 0; i < NS_FRAME_ADVANCE; i++) {
                samples_out[i] = samples[i+NS_PROC_FRAME_LENGTH-NS_FRAME_ADVANCE];
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

        for(int i = 0; i < NS_FRAME_ADVANCE; i++) {
            uint32_t x;
            asm("ldaw %0,dp[buffer_out]" : "=r" (x));
            asm("stw %0, %1[%2]" :: "r" (samples_out[i]), "r" (x), "r" ((out_buff * SYSTEM_FRAME_ADVANCE) + i));
            
        }
        audio_output :> out_buff;
    }
}
