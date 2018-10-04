// Copyright (c) 2018, XMOS Ltd, All rights reserved
#include "agc.h"
#include "voice_toolbox.h"
#include <string.h>

//This must be more than AGC_FRAME_ADVANCE to work around vtb_rx_tx doesnt support advance==length.
#define INPUT_FRAME_LENGTH 480

#define STATE_SIZE VTB_RX_STATE_UINT64_SIZE(AGC_CHANNEL_PAIRS*2, INPUT_FRAME_LENGTH, AGC_FRAME_ADVANCE, 0)

void agc_test_task(chanend c_data_input, chanend c_data_output,
                chanend ?c_control){
    uint64_t state[STATE_SIZE];
    agc_state_t [[aligned(8)]] agc_state;

    vtb_rx_state_init(state, AGC_CHANNEL_PAIRS*2, INPUT_FRAME_LENGTH, AGC_FRAME_ADVANCE, null, STATE_SIZE);

    agc_init(agc_state);

    while(1){
        dsp_complex_t [[aligned(8)]] frame[AGC_CHANNEL_PAIRS][480];

        vtb_rx_pairs(c_data_input, state, (dsp_complex_t *)frame);

        dsp_complex_t [[aligned(8)]] frame2[AGC_CHANNEL_PAIRS][AGC_PROC_FRAME_LENGTH];

        for(unsigned ch_pair = 0;ch_pair< AGC_CHANNEL_PAIRS;ch_pair++)
        memcpy(frame2[ch_pair], &frame[ch_pair][INPUT_FRAME_LENGTH - AGC_PROC_FRAME_LENGTH], sizeof(frame2[ch_pair]));

        agc_process_frame(agc_state, frame2);

        vtb_tx_pairs(c_data_output, (dsp_complex_t*)frame2,
                         2*AGC_CHANNEL_PAIRS,
                         AGC_FRAME_ADVANCE);
    }
}
