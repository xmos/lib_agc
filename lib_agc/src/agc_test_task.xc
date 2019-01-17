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

    vtb_rx_state_init(state, AGC_CHANNEL_PAIRS*2, INPUT_FRAME_LENGTH, AGC_FRAME_ADVANCE, null, STATE_SIZE);

    agc_state_t [[aligned(8)]] agc_state;
    agc_config_t agc_config[AGC_INPUT_CHANNELS] = {
        {
            AGC_CH0_ADAPT,
            UQ16(AGC_CH0_GAIN),
            UQ16(AGC_CH0_MAX_GAIN),
            AGC_CH0_DESIRED_LEVEL
        },
        {
            AGC_CH1_ADAPT,
            UQ16(AGC_CH1_GAIN),
            UQ16(AGC_CH1_MAX_GAIN),
            AGC_CH1_DESIRED_LEVEL
        },
    };

    agc_init(agc_state, agc_config);

    while(1){
        dsp_complex_t [[aligned(8)]] frame1[AGC_CHANNEL_PAIRS][480];

        vtb_rx_pairs(c_data_input, state, (dsp_complex_t *)frame1);

        dsp_complex_t [[aligned(8)]] frame2[AGC_CHANNEL_PAIRS][AGC_PROC_FRAME_LENGTH];

        for(unsigned ch_pair = 0; ch_pair < AGC_CHANNEL_PAIRS; ch_pair++){
            memcpy(frame2[ch_pair], &frame1[ch_pair][INPUT_FRAME_LENGTH - AGC_PROC_FRAME_LENGTH], sizeof(frame2[ch_pair]));
        }

        uint8_t vad = 0xFF;
        agc_process_frame(agc_state, frame2, vad);

        vtb_tx_pairs(c_data_output, (dsp_complex_t*)frame2,
                         2*AGC_CHANNEL_PAIRS,
                         AGC_FRAME_ADVANCE);
    }
}
