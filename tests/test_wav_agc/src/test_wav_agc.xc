// Copyright (c) 2017-2019, XMOS Ltd, All rights reserved
#include<platform.h>

#include "voice_toolbox.h"
#include "agc.h"
#include "audio_test_tools.h"
#include "vad.h"
#include <string.h>
#include "agc_init_config.h"


void app_control(chanend c_control_to_wav, chanend c_control_to_dsp){

    //Play for 5 seconds
    att_pw_play_until_sample_passes(c_control_to_wav, 16000*5);

    //command the DSP to do something
    //aec_...

    //Play the rest of the file
    att_pw_play(c_control_to_wav);
}


//This must be more than AGC_FRAME_ADVANCE to work around vtb_rx_tx doesnt support advance==length.
#define INPUT_FRAME_LENGTH 480

#define STATE_SIZE VTB_RX_STATE_UINT64_SIZE(AGC_CHANNEL_PAIRS*2, INPUT_FRAME_LENGTH, AGC_FRAME_ADVANCE, 0)

#define AGC_VAD_THRESHOLD (205)

void agc_test_task(chanend c_data_input, chanend c_data_output,
                chanend ?c_control){
    uint64_t state[STATE_SIZE];
    vtb_md_t md;
    vtb_md_init(md);

    vtb_rx_state_init(state, AGC_CHANNEL_PAIRS*2, INPUT_FRAME_LENGTH, AGC_FRAME_ADVANCE, null, STATE_SIZE);

    agc_state_t [[aligned(8)]] agc_state;
    int32_t vad_data_window[VAD_PROC_FRAME_LENGTH];
    for(int i = 0; i<VAD_PROC_FRAME_LENGTH; ++i){
        vad_data_window[i] = 0;
    }
    
    vtb_u32_float_t ref_power_est = {VTB_UQ0_32(0.00001), -32};
    vtb_normalise_u32(ref_power_est);

    
    vad_state_t vad_state;
    vad_init_state(vad_state);
    agc_init(agc_state, agc_init_config);

    while(1){
        vtb_ch_pair_t [[aligned(8)]] rec_frame[AGC_CHANNEL_PAIRS][480];

        vtb_rx_notification_and_data(c_data_input, state, (vtb_ch_pair_t *)rec_frame, md);

        vtb_ch_pair_t [[aligned(8)]] input_frame[AGC_CHANNEL_PAIRS][AGC_PROC_FRAME_LENGTH];        
        for(unsigned ch_pair = 0; ch_pair < AGC_CHANNEL_PAIRS; ch_pair++){
            memcpy(input_frame[ch_pair], &rec_frame[ch_pair][INPUT_FRAME_LENGTH - AGC_PROC_FRAME_LENGTH], sizeof(input_frame[ch_pair]));
        }
        
        // vtb_ch_pair_t [[aligned(8)]] ref_frame[1][AGC_PROC_FRAME_LENGTH];
        // memcpy(ref_frame[0], &rec_frame[1][INPUT_FRAME_LENGTH - AGC_PROC_FRAME_LENGTH], sizeof(input_frame[0]));
        // 
        // // Ref Power Estimate
        // int input_exp = -31; //This is convention to range the wav input to [-1.0, 1.0).
        // vtb_u32_float_t ref_power_est_0 = vtb_get_td_frame_power((vtb_ch_pair_t *)ref_frame[0],
        //                                         input_exp,
        //                                         AGC_PROC_FRAME_LENGTH,
        //                                         0);
        // vtb_u32_float_t ref_power_est_1 = vtb_get_td_frame_power((vtb_ch_pair_t *)ref_frame[0],
        //                                         input_exp,
        //                                         AGC_PROC_FRAME_LENGTH,
        //                                         1);
        // 
        // vtb_u32_float_t max_ref_power = ref_power_est_1;
        // if(vtb_gte_u32_u32(ref_power_est_0, ref_power_est_1)){
        //     max_ref_power = ref_power_est_0;
        // }
        // 
        // uint32_t alpha = VTB_UQ0_32(0.5480);
        // if(vtb_gte_u32_u32(ref_power_est, max_ref_power)){
        //     alpha = VTB_UQ0_32(0.6973);
        // }
        // 
        // vtb_exponential_average_u32(ref_power_est, max_ref_power, alpha);



        for(int s = VAD_PROC_FRAME_LENGTH - 1 - AGC_FRAME_ADVANCE;s >= 0;s--){
            vad_data_window[s + AGC_FRAME_ADVANCE] = vad_data_window[s];
        }
        for(unsigned s=0;s<AGC_FRAME_ADVANCE;s++){
            vad_data_window[s] = (input_frame[0][s], int32_t[])[0];
        }
        int32_t vad_percentage = vad_percentage_voice(vad_data_window, vad_state);

        agc_process_frame(agc_state, input_frame, ref_power_est, vad_percentage > AGC_VAD_THRESHOLD);

        vtb_tx_notification_and_data(c_data_output, (vtb_ch_pair_t*)input_frame,
                         2*AGC_CHANNEL_PAIRS,
                         AGC_FRAME_ADVANCE, md);
    }
}



int main(){
    chan app_to_dsp;
    chan dsp_to_app;
    chan c_control_to_dsp;
    chan c_control_to_wav;

    par {
        on tile[0]:{
            app_control(c_control_to_wav, c_control_to_dsp);
        }
        on tile[0]:{
            att_process_wav(app_to_dsp, dsp_to_app, c_control_to_wav);
            _Exit(0);
        }
        on tile[1]: agc_test_task(app_to_dsp, dsp_to_app, c_control_to_dsp);
    }
    return 0;
}
