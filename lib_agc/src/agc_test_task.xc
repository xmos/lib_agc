// Copyright (c) 2018, XMOS Ltd, All rights reserved
#include <platform.h>
#include <xs1.h>
#include <xclib.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdio.h>
#include <print.h>
#include <xscope.h>
#include <dsp.h>

#include "agc.h"
#include "voice_toolbox.h"

#define STATE_SIZE VTB_RX_STATE_UINT64_SIZE(AGC_CHANNEL_PAIRS*2, AGC_PROC_FRAME_LENGTH, AGC_FRAME_ADVANCE, 0)

void agc_test_task(chanend c_data_input, chanend c_data_output,
                chanend ?c_control){
    uint64_t state[STATE_SIZE];
    aec_state_t [[aligned(8)]] data;
    int Error_exp[AEC_CHANNEL_PAIRS*2];

    unsigned x_channel_phase_counts[AEC_X_CHANNELS];
    unsigned x_channels[AEC_X_CHANNELS];

    for (int i=0; i<AEC_X_CHANNELS; i++) {
        x_channel_phase_counts[i] = AEC_PHASES / AEC_X_CHANNELS;
        x_channels[i] = AEC_Y_CHANNELS + i;
    }

    vtb_rx_state_init(state, AEC_CHANNEL_PAIRS*2, AEC_PROC_FRAME_LENGTH, AEC_FRAME_ADVANCE, null, STATE_SIZE);

//    aec_init(data, sch, x_channels, x_channel_phase_counts);

//    aec_dump_paramters(state);

//    int channel_hr[AEC_CHANNEL_PAIRS*2] = {0};

    while(1){
        dsp_complex_t [[aligned(8)]] frame[AEC_CHANNEL_PAIRS][AEC_PROC_FRAME_LENGTH];

        vtb_rx_pairs(c_data_input, state, (dsp_complex_t *)frame);

//        for(unsigned ch_pair=0;ch_pair<AEC_CHANNEL_PAIRS;ch_pair++){
//            channel_hr[ch_pair*2 + 0] = vtb_get_channel_hr(frame[ch_pair], AEC_PROC_FRAME_LENGTH, 0);
//            channel_hr[ch_pair*2 + 1] = vtb_get_channel_hr(frame[ch_pair], AEC_PROC_FRAME_LENGTH, 1);
//        }
//
//        aec_process_td_frame(data, frame, channel_hr, Error_exp);
//
//        vtb_tx_pairs(c_data_output, (dsp_complex_t*)data.output,
//                         2*AEC_CHANNEL_PAIRS,
//                         AEC_FRAME_ADVANCE);
//        aec_frame_adapt(data, frame, Error_exp);

    }
}
