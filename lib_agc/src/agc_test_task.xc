// Copyright (c) 2018-2019, XMOS Ltd, All rights reserved
#include "agc.h"
#include "voice_toolbox.h"
#include "vad.h"
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
            VTB_UQ16_16(AGC_CH0_GAIN),
            VTB_UQ16_16(AGC_CH0_MAX_GAIN),
            AGC_CH0_DESIRED_LEVEL
        },
        {
            AGC_CH1_ADAPT,
            VTB_UQ16_16(AGC_CH1_GAIN),
            VTB_UQ16_16(AGC_CH1_MAX_GAIN),
            AGC_CH1_DESIRED_LEVEL
        },
    };

    int32_t vad_data_window[VAD_PROC_FRAME_LENGTH];
    for(int i = 0; i<VAD_PROC_FRAME_LENGTH; ++i){
        vad_data_window[i] = 0;
    }
    vad_state_t vad_state;
    vad_init_state(vad_state);
    agc_init(agc_state, agc_config);

    while(1){
        dsp_complex_t [[aligned(8)]] frame1[AGC_CHANNEL_PAIRS][480];

        vtb_rx_pairs(c_data_input, state, (dsp_complex_t *)frame1);

        dsp_complex_t [[aligned(8)]] frame2[AGC_CHANNEL_PAIRS][AGC_PROC_FRAME_LENGTH];

        for(unsigned ch_pair = 0; ch_pair < AGC_CHANNEL_PAIRS; ch_pair++){
            memcpy(frame2[ch_pair], &frame1[ch_pair][INPUT_FRAME_LENGTH - AGC_PROC_FRAME_LENGTH], sizeof(frame2[ch_pair]));
        }


        for(int s = VAD_PROC_FRAME_LENGTH - 1 - AGC_FRAME_ADVANCE;s >= 0;s--){
            vad_data_window[s + AGC_FRAME_ADVANCE] = vad_data_window[s];
        }
        for(unsigned s=0;s<AGC_FRAME_ADVANCE;s++){
            vad_data_window[s] = (frame2[0][s], int32_t[])[0];
        }
        int32_t vad_percentage = vad_percentage_voice(vad_data_window, vad_state);

        agc_process_frame(agc_state, frame2, vad_percentage);

        vtb_tx_pairs(c_data_output, (dsp_complex_t*)frame2,
                         2*AGC_CHANNEL_PAIRS,
                         AGC_FRAME_ADVANCE);
    }
}
