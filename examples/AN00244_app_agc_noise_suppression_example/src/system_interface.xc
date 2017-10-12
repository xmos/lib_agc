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

#include "i2c.h"
#include "i2s.h"
#include "src.h"
#include "demo_ns_agc.h"

on tile[3]: out port leds = XS1_PORT_8C;
//on tile[0]:in port p_buttons =  XS1_PORT_4A;

on tile[2]: out port p_pdm_clk               = PORT_PDM_CLK;
on tile[2]: in buffered port:32 p_pdm_mics  = PORT_PDM_DATA;
on tile[2]: in port p_mclk                  = PORT_PDM_MCLK;
on tile[2]: clock pdmclk                    = XS1_CLKBLK_1;
on tile[2]: clock pdmclk6                   = XS1_CLKBLK_2;
on tile[2]: in port buttons                 = XS1_PORT_4A;

out buffered port:32 p_i2s_dout[1]  = on tile[1]: {XS1_PORT_1P};
in port p_mclk_in1                  = on tile[1]: XS1_PORT_1O;
out buffered port:32 p_bclk         = on tile[1]: XS1_PORT_1M;
out buffered port:32 p_lrclk        = on tile[1]: XS1_PORT_1N;
out port p_pll_sync                 = on tile[1]: XS1_PORT_4D;
port p_i2c                          = on tile[1]: XS1_PORT_4E; // Bit 0: SCLK, Bit 1: SDA
port p_rst_shared                   = on tile[1]: XS1_PORT_4F; // Bit 0: DAC_RST_N, Bit 1: ETH_RST_N
clock mclk                          = on tile[1]: XS1_CLKBLK_3;
clock bclk                          = on tile[1]: XS1_CLKBLK_4;

int data[8][THIRD_STAGE_COEFS_PER_STAGE*6];

#define DECIMATION_FACTOR   6
#define FFT_N (1<<MIC_ARRAY_MAX_FRAME_SIZE_LOG2)
#define NUM_OUTPUT_CHANNELS 2
#define NUM_FRAME_BUFFERS   3   //Triple buffer needed for overlapping frames

typedef struct {
    int32_t data[NUM_OUTPUT_CHANNELS][FFT_N/2]; // FFT_N/2 due to overlapping
} multichannel_audio_block_s;

multichannel_audio_block_s triple_buffer[3];

interface bufget_i {
  void get_next_buf(multichannel_audio_block_s * unsafe &buf);
};


#define FRAME_LENGTH (1<<MIC_ARRAY_MAX_FRAME_SIZE_LOG2)
#define DECIMATOR_COUNT     2   //8 channels requires 2 decimators
#define FRAME_BUFFER_COUNT  2   //The minimum of 2 will suffice for this example


int sineWave[16] = {
    0,
    5000,
    7071,
    8660,
    10000,
    7071,
    8660,
    5000,
    0,
    -5000,
    -7071,
    -8660,
    -10000,
    -8660,
    -7071,
    -5000
};

void get_wav(chanend to_ns,
             streaming chanend c_ds_output[DECIMATOR_COUNT]){
    unsafe{
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

        mic_array_decimator_configure(c_ds_output, DECIMATOR_COUNT, dc);

        mic_array_init_time_domain_frame(c_ds_output, DECIMATOR_COUNT, buffer, audio, dc);
        int cnt = 10;
        while(1){
            cnt++;
            mic_array_frame_time_domain *  current =
                               mic_array_get_next_time_domain_frame(c_ds_output, DECIMATOR_COUNT, buffer, audio, dc);
            int32_t data_buf[FRAME_LENGTH];
            
            // Copy the current sample to the delay buffer
            uint64_t energy = 0;
            uint32_t mask = 0;
            for(unsigned i=0;i<FRAME_LENGTH;i++) {
                data_buf[i] = current->data[0][i];
//                data_buf[i] = sineWave[i&15];
                if (data_buf[i] > 0) {
                    mask |= data_buf[i];
                } else {
                    mask |= -data_buf[i];
                }
                energy += (data_buf[i] * (int64_t) data_buf[i]) >> 10;
            }
            uint32_t headroom = clz(mask);
            if (headroom > 2) {
                headroom -= 2;
            } else {
                headroom = 0;
            }
            to_ns <: headroom;
            for(unsigned i=0;i<FRAME_LENGTH;i++) {
                to_ns <: (data_buf[i] << headroom);
            }
        }
    }
}


src_os3_ctrl_t src;
int delays[SRC_FF3_OS3_N_COEFS/SRC_FF3_OS3_N_PHASES];

void upsampler(chanend c_in,
               chanend c_out) {
    int data[FRAME_LENGTH/2];
    unsafe {
        src.delay_base = delays;
        src_os3_init(&src);
        while(1) {
            for(unsigned i=0;i<FRAME_LENGTH/2;i++) {
                c_in :> data[i];
            }
            for(unsigned i=0;i<FRAME_LENGTH/2;i++) {
                src.in_data = data[i];
                src_os3_input(&src);
                src_os3_proc(&src);
                c_out <: src.out_data;
                c_out <: src.out_data;
                src_os3_proc(&src);
                c_out <: src.out_data;
                c_out <: src.out_data;
                src_os3_proc(&src);
                c_out <: src.out_data;
                c_out <: src.out_data;
            }
        }
    }
}
    
void output_audio_dbuf_handler(server interface bufget_i input,
                               multichannel_audio_block_s triple_buffer[3],
                               chanend c_audio) {

    unsigned count = 0, sample_idx = 0, buffer_full=0;
    //unsigned buffer_get_next_bufped_flag=1;
    int32_t sample;

    unsigned head = 0;          //Keeps track of index of proc_buffer

    unsafe {
        while (1) {
            // get_next_buf buffers
            select {
            case input.get_next_buf(multichannel_audio_block_s * unsafe &buf):
                // pass ptr to previous buffer
                if(head==0) {
                    buf = &triple_buffer[NUM_FRAME_BUFFERS-1];
                } else {
                    buf = &triple_buffer[head-1];
                }
                //buffer_get_next_bufped_flag = 1;
                buffer_full = 0;
                break;

                // guarded select case will create back pressure.
                // I.e. c_audio will block until buffer is get_next_bufped
            case !buffer_full => c_audio :> sample:
                //if(sample_idx == 0 && !buffer_get_next_bufped_flag) {
                //printf("Buffer overflow\n");
                //};
                unsigned channel_idx = count & 1;
                triple_buffer[head].data[channel_idx][sample_idx] = sample;
                if(channel_idx==1) {
                    sample_idx++;
                }
                if(sample_idx>=FFT_N/2) {
                    sample_idx = 0;
                    buffer_full = 1;
                    //Manage overlapping buffers
                    head++;
                    if(head == NUM_FRAME_BUFFERS)
                        head = 0;
                }

                count++;
                break;
            }
        }
    }
}

#define MASTER_TO_PDM_CLOCK_DIVIDER 4
#define MASTER_CLOCK_FREQUENCY 24576000
#define PDM_CLOCK_FREQUENCY (MASTER_CLOCK_FREQUENCY/(2*MASTER_TO_PDM_CLOCK_DIVIDER))
#define OUTPUT_SAMPLE_RATE (PDM_CLOCK_FREQUENCY/(32*DECIMATION_FACTOR))

unsafe {
    [[distributable]] void i2s_handler(server i2s_callback_if i2s,
                         client i2c_master_if i2c, 
                         client interface bufget_i filler
        ) {
        multichannel_audio_block_s * unsafe buffer = 0; // invalid
        unsigned sample_idx=0;

        p_rst_shared <: 0xF;

        mabs_init_pll(i2c, ETH_MIC_ARRAY);
        mabs_init_pll(i2c, SMART_MIC_BASE);

        i2c_regop_res_t res;
        int i = 0x4A;

        uint8_t data = 1;
        res = i2c.write_reg(i, 0x02, data); // Power down
        res = i2c.write_reg(i+1, 0x02, data); // Power down

        data = 0x08;
        res = i2c.write_reg(i, 0x04, data); // Slave, I2S mode, up to 24-bit

        data = 0;
        res = i2c.write_reg(i, 0x03, data); // Disable Auto mode and MCLKDIV2

        data = 0x00;
        res = i2c.write_reg(i, 0x09, data); // Disable DSP

        data = 0;
        res = i2c.write_reg(i, 0x02, data); // Power up

        while (1) {
            select {
                case i2s.init(i2s_config_t &?i2s_config, tdm_config_t &?tdm_config):
                    i2s_config.mode = I2S_MODE_I2S;
                    i2s_config.mclk_bclk_ratio = (MASTER_CLOCK_FREQUENCY/(3*OUTPUT_SAMPLE_RATE))/64;
                    break;

                case i2s.restart_check() -> i2s_restart_t restart:
                    restart = I2S_NO_RESTART;
                    break;

                case i2s.receive(size_t index, int32_t sample):
                    break;

                case i2s.send(size_t index) -> int32_t sample:
                    if(buffer) {
                        sample = buffer->data[index][sample_idx];
                        //printf("I2S send sample %d on channel %d\n",sample_idx,index);
                    } else { // buffer invalid
                        sample = 0;
                    }
                    //xscope_int(index, sample);
                    if(index == 1) {
                        sample_idx++;
                    }
                    if(sample_idx>=FFT_N/2) {
                        // end of buffer reached.
                        sample_idx = 0;
                        filler.get_next_buf(buffer);
                        //printf("I2S got next buffer at 0x%x\n", buffer);
                    }
                    break;
            }
        }
    }
}

in port button = PORT_BUT_A_TO_D;

void buttoncheck(chanend adapt) {
    while(1) {
        int x;
        button :> x;
        if (x == 14) {
            adapt <: -1;
        } else {
            adapt <: (x != 15);
        }
    }
}


int main(){
    i2s_callback_if i_i2s;
    i2c_master_if i_i2c[1];
    interface bufget_i bufget;
    chan c_agc_to_i2s, c_microphone_to_nsagc;
    chan c_tobuffer;
    par{
        on tile[1]: {
          configure_clock_src(mclk, p_mclk_in1);
          start_clock(mclk);
          i2s_master(i_i2s, p_i2s_dout, 1, null, 0, p_bclk, p_lrclk, bclk, mclk);
        }

        on tile[1]:  i2c_master_single_port(i_i2c, 1, p_i2c, 100, 0, 1, 0);
        on tile[1]:  i2s_handler(i_i2s, i_i2c[0], bufget);
        on tile[1]:  output_audio_dbuf_handler(bufget, triple_buffer, c_tobuffer);
        on tile[1]:  upsampler(c_agc_to_i2s, c_tobuffer);

        on tile[1]: noise_suppression_automatic_gain_control_task(c_microphone_to_nsagc, c_agc_to_i2s);

        on tile[2]: {
            streaming chan c_4x_pdm_mic_0, c_4x_pdm_mic_1;
            streaming chan c_ds_output[2];

            interface mabs_led_button_if lb[1];
            mic_array_setup_sdr(pdmclk, p_mclk, p_pdm_clk, p_pdm_mics, 8);

//            configure_clock_src_divide(pdmclk, p_mclk, 4);
//            configure_port_clock_output(p_pdm_clk, pdmclk);
//            configure_in_port(p_pdm_mics, pdmclk);
//            start_clock(pdmclk);

            chan c_generator_to_beamformer;
            streaming chan c_internal_audio;
            par{
                mic_array_pdm_rx(p_pdm_mics, c_4x_pdm_mic_0, c_4x_pdm_mic_1);
                mic_array_decimate_to_pcm_4ch(c_4x_pdm_mic_0, c_ds_output[0], MIC_ARRAY_NO_INTERNAL_CHANS);
                mic_array_decimate_to_pcm_4ch(c_4x_pdm_mic_1, c_ds_output[1], MIC_ARRAY_NO_INTERNAL_CHANS);

                get_wav(c_microphone_to_nsagc, c_ds_output);
                
            }
        }
    }

    return 0;
}

