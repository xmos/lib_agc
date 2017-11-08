// Copyright (c) 2016-2017, XMOS Ltd, All rights reserved

#include <platform.h>
#include <xs1.h>
#include <xclib.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <stdio.h>
#include <print.h>
#include <xscope.h>

#include "mic_array.h"
#include "mic_array_board_support.h"

#include "i2s_handling.h"
#include "ns_agc.h"
#include "bs.h"
#include "beamsteering.h"
#include "noise_suppression.h"
#include "far_end_audio_server.h"


on tile[3]: out port leds = XS1_PORT_8C;

on tile[2]: out port p_pdm_clk                 = PORT_PDM_CLK;
on tile[2]: in buffered port:32 p_pdm_mics     = PORT_PDM_DATA;
on tile[2]: in port p_mclk                     = PORT_PDM_MCLK;
on tile[2]: clock pdmclk                       = XS1_CLKBLK_1;
on tile[2]: clock pdmclk6                      = XS1_CLKBLK_2;

//on tile[1]: out buffered port:32 p_i2s_dout[2] = {PORT_I2S_DAC0,PORT_I2S_DAC1};

int data[MIC_ARRAY_NUM_MICS][THIRD_STAGE_COEFS_PER_STAGE*6];


#define DECIMATION_FACTOR   6
#define DECIMATOR_COUNT     2   //8 channels requires 2 decimators
#define FRAME_BUFFER_COUNT  2   //The minimum of 2 will suffice for this example

int sineWave24[24] = {
    0, 2588, 4999, 7071, 8660, 9659, 10000, 9659, 8660, 7071, 5000, 2588,
    0,-2588,-4999,-7071,-8660,-9659,-10000,-9659,-8660,-7071,-5000,-2588,
};

void get_pdm(chanend audio_out,
             streaming chanend c_ds_output[DECIMATOR_COUNT],
             chanend far_end_audio){
    unsafe{
        dsp_complex_t databuf[BS_INPUT_CHANNELS][BS_FRAME_ADVANCE];
        unsigned buffer;
        memset(data, 0, 8*THIRD_STAGE_COEFS_PER_STAGE*DECIMATION_FACTOR*sizeof(int));

        mic_array_frame_time_domain audio[FRAME_BUFFER_COUNT];

        mic_array_decimator_conf_common_t dcc = {MIC_ARRAY_MAX_FRAME_SIZE_LOG2,
                                                 1, 0, 0, DECIMATION_FACTOR,
                                                 g_third_stage_div_6_fir, 0, FIR_COMPENSATOR_DIV_6,
                                                 DECIMATOR_NO_FRAME_OVERLAP, FRAME_BUFFER_COUNT};
        mic_array_decimator_config_t dc[2] = {
          {&dcc, data[0], {INT_MAX, INT_MAX, INT_MAX, INT_MAX}, 4},
          {&dcc, data[4], {INT_MAX, INT_MAX, INT_MAX, INT_MAX}, 4}
        };
        
        assert(MIC_ARRAY_NUM_MICS >= BS_INPUT_CHANNELS);
        assert(BS_FRAME_ADVANCE == NS_FRAME_ADVANCE);
        
        mic_array_decimator_configure(c_ds_output, DECIMATOR_COUNT, dc);

        mic_array_init_time_domain_frame(c_ds_output, DECIMATOR_COUNT, buffer, audio, dc);
        int cnt = 0;
        unsigned int gain = 0x10000;
        unsigned mic_samples =(1<<MIC_ARRAY_MAX_FRAME_SIZE_LOG2);
        int wait_for_sync = 3;
        while(1){
            int collected = 0;
            while (collected < BS_FRAME_ADVANCE) {
                mic_array_frame_time_domain *  current =
                    mic_array_get_next_time_domain_frame(c_ds_output, DECIMATOR_COUNT, buffer, audio, dc);
                
                // Copy the current sample to the delay buffer
                uint32_t mask = 0;
                for(unsigned j=0;j<mic_samples;j++){
                    cnt++;
                    for(unsigned i=0;i<BS_INPUT_CHANNELS;i+=2){
//#define REPLACE_WITH_SINE_WAVE
#ifdef REPLACE_WITH_SINE_WAVE
                        current->data[i+0][j] = sineWave24[(cnt+i+0)%24] * gain;
                        current->data[i+1][j] = sineWave24[(cnt+i+1)%24] * gain;
#endif
                        databuf[i>>1][collected].re = current->data[i+0][j];
                        databuf[i>>1][collected].im = current->data[i+1][j];
                    }
                    collected++;
                    gain = (gain * 0x7FFA0000LL) >> 31;
                    if (gain < 3000) gain = 65536;
                }
            }
            if (wait_for_sync) {
                wait_for_sync--;
                if (wait_for_sync == 0) {
                    outct(far_end_audio, 1);
                }
            } else {
                int in_buff = inuchar(far_end_audio);
                chkct(far_end_audio, 1);
            }
            // GET DATA FROM I2S.
            // Run Pharell Williams on tile[3]
            // Post data to I2S, then block and send on to AEC 
            
            dsp_bfp_tx_pairs(audio_out,
                             (databuf, dsp_complex_t[]),
                             BS_INPUT_CHANNELS, BS_FRAME_ADVANCE,
                             0);
//            timer tmr; int t; tmr :> t;
//            for(int i = 0; i < BS_FRAME_ADVANCE; i++) {
//                xscope_int(CH1, databuf[0][i].re);
//                tmr when timerafter(t += 5000) :> void;
//            }
        }
    }
}


in port button = PORT_BUT_A_TO_D;

void buttoncheck(chanend suppress, chanend adapt) {
    int butval = 0;
    while(1) {
        button when pinsneq(butval) :> butval;
        int keep_noise = (butval & 8) ? 1 : 0;
        int adapt_bs = (butval & 4) ? (butval & 1) ? 0 : -1 : 1;
        printf("Keepnoise: %d, adapt_bs: %d\n", keep_noise, adapt_bs);
        suppress <: keep_noise;
        adapt <: adapt_bs;
    }
}

int main(){
    chan c_agc_to_i2s, c_microphone_to_bs, c_bs_to_ns;
    chan c_button_vad, c_button_suppress;
    chan c_music_for_speaker, c_far_end_audio;
    par{
        on tile[0]: far_end_audio_server(c_music_for_speaker);
        on tile[1]: i2s_main(c_agc_to_i2s, c_far_end_audio);
        on tile[1]: noise_suppression_automatic_gain_control_task(c_bs_to_ns, c_agc_to_i2s, c_button_suppress);

        on tile[2]: bs_task(c_microphone_to_bs, c_bs_to_ns, c_button_vad);
        on tile[3]: buttoncheck(c_button_suppress, c_button_vad);
        on tile[2]: {
            streaming chan c_4x_pdm_mic_0, c_4x_pdm_mic_1;
            streaming chan c_ds_output[2];

            mic_array_setup_sdr(pdmclk, p_mclk, p_pdm_clk, p_pdm_mics, 8);

            chan c_generator_to_beamformer;
            streaming chan c_internal_audio;
            par{
                mic_array_pdm_rx(p_pdm_mics, c_4x_pdm_mic_0, c_4x_pdm_mic_1);
                mic_array_decimate_to_pcm_4ch(c_4x_pdm_mic_0, c_ds_output[0], MIC_ARRAY_NO_INTERNAL_CHANS);
                mic_array_decimate_to_pcm_4ch(c_4x_pdm_mic_1, c_ds_output[1], MIC_ARRAY_NO_INTERNAL_CHANS);

                get_pdm(c_microphone_to_bs, c_ds_output, c_far_end_audio);
            }
        }
    }

    return 0;
}

