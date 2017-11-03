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
#include "ns_agc.h"
#include "bs.h"
#include "beamsteering.h"
#include "noise_suppression.h"
#include "far_end_audio_server.h"

#define SYSTEM_FRAME_ADVANCE    256


on tile[3]: out port leds = XS1_PORT_8C;

on tile[2]: out port p_pdm_clk                 = PORT_PDM_CLK;
on tile[2]: in buffered port:32 p_pdm_mics     = PORT_PDM_DATA;
on tile[2]: in port p_mclk                     = PORT_PDM_MCLK;
on tile[2]: clock pdmclk                       = XS1_CLKBLK_1;
on tile[2]: clock pdmclk6                      = XS1_CLKBLK_2;

on tile[1]: out buffered port:32 p_i2s_dout[2] = {PORT_I2S_DAC0,PORT_I2S_DAC1};
on tile[1]: in port p_mclk_in1                 = PORT_MCLK_IN;
on tile[1]: out buffered port:32 p_bclk        = PORT_I2S_BCLK;
on tile[1]: out buffered port:32 p_lrclk       = PORT_I2S_LRCLK;
on tile[1]: port p_i2c                         = PORT_I2C_SCL_SDA; // C:1, D:2
on tile[1]: port p_rst_shared                  = PORT_DAC_RST_N;  
on tile[1]: clock mclk                         = XS1_CLKBLK_3;
on tile[1]: clock bclk                         = XS1_CLKBLK_4;

int data[MIC_ARRAY_NUM_MICS][THIRD_STAGE_COEFS_PER_STAGE*6];

#define NUM_I2S_BUFFERS   3   //Triple buffer needed for overlapping frames

typedef struct {
    int32_t data[SYSTEM_FRAME_ADVANCE];
} i2s_audio_block_t;

i2s_audio_block_t triple_i2s_buffer[NUM_I2S_BUFFERS];

interface bufget_i {
  void get_next_buf(i2s_audio_block_t * unsafe &buf);
};

#define DECIMATION_FACTOR   6
#define DECIMATOR_COUNT     2   //8 channels requires 2 decimators
#define FRAME_BUFFER_COUNT  2   //The minimum of 2 will suffice for this example

int sineWave24[24] = {
    0, 2588, 4999, 7071, 8660, 9659, 10000, 9659, 8660, 7071, 5000, 2588,
    0,-2588,-4999,-7071,-8660,-9659,-10000,-9659,-8660,-7071,-5000,-2588,
};

void get_pdm(chanend audio_out,
             streaming chanend c_ds_output[DECIMATOR_COUNT]){
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
        
        assert((1<<MIC_ARRAY_MAX_FRAME_SIZE_LOG2) == BS_FRAME_ADVANCE);
        assert(MIC_ARRAY_NUM_MICS >= BS_INPUT_CHANNELS);
        assert(BS_FRAME_ADVANCE == NS_FRAME_ADVANCE);
        
        mic_array_decimator_configure(c_ds_output, DECIMATOR_COUNT, dc);

        mic_array_init_time_domain_frame(c_ds_output, DECIMATOR_COUNT, buffer, audio, dc);
        int cnt = 0;
        unsigned int gain = 0x10000;

        while(1){
            mic_array_frame_time_domain *  current =
                               mic_array_get_next_time_domain_frame(c_ds_output, DECIMATOR_COUNT, buffer, audio, dc);
            
            // Copy the current sample to the delay buffer
            uint32_t mask = 0;
            for(unsigned j=0;j<BS_FRAME_ADVANCE;j++){
                cnt++;
                for(unsigned i=0;i<BS_INPUT_CHANNELS;i+=2){
// #define REPLACE_WITH_SINE_WAVE
#if REPLACE_WITH_SINE_WAVE
                    current->data[i+0][j] = sineWave24[(cnt+i+0)%24] * gain;
                    current->data[i+1][j] = sineWave24[(cnt+i+1)%24] * gain;
#endif
                    databuf[i>>1][j].re = current->data[i+0][j];
                    databuf[i>>1][j].im = current->data[i+1][j];
                }
                gain = (gain * 0x7FFA0000LL) >> 31;
                if (gain < 3000) gain = 65536;
            }

            // GET DATA FROM I2S.
            // Run Pharell Williams on tile[3]
            // Post data to I2S, then block and send on to AEC 
            // Change names
            
            dsp_bfp_tx_pairs(audio_out,
                             (databuf, dsp_complex_t[]),
                             BS_INPUT_CHANNELS, BS_FRAME_ADVANCE,
                             0);
        }
    }
}


src_os3_ctrl_t src;
int delays[SRC_FF3_OS3_N_COEFS/SRC_FF3_OS3_N_PHASES*4];

void upsampler(chanend c_in,
               chanend c_out) {
    int data[SYSTEM_FRAME_ADVANCE];
    unsafe {
        src.delay_base = delays;
        src_os3_init(&src);
        while(1) {
            for(unsigned i=0;i<SYSTEM_FRAME_ADVANCE;i++) {
                c_in :> data[i];
            }
            for(unsigned i=0;i<SYSTEM_FRAME_ADVANCE;i++) {
                src.in_data = data[i];
                src_os3_input(&src);
                src_os3_proc(&src);
                c_out <: src.out_data;
                src_os3_proc(&src);
                c_out <: src.out_data;
                src_os3_proc(&src);
                c_out <: src.out_data;
            }
        }
    }
}
    
void output_audio_dbuf_handler(server interface bufget_i input,
                               i2s_audio_block_t triple_buffer[NUM_I2S_BUFFERS],
                               chanend c_audio) {

    unsigned sample_idx = 0, buffer_full=0;
    //unsigned buffer_get_next_bufped_flag=1;
    int32_t sample;

    unsigned head = 0;          //Keeps track of index of proc_buffer

    unsafe {
        timer tmr;
        int t0 = 0, t1 = 0;
        while(1){
            // get_next_buf buffers
            select {
            case input.get_next_buf(i2s_audio_block_t * unsafe &buf):
                // pass ptr to previous buffer
                if(head==0) {
                    buf = &triple_buffer[NUM_I2S_BUFFERS-1];
                } else {
                    buf = &triple_buffer[head-1];
                }
                //buffer_get_next_bufped_flag = 1;
                buffer_full = 0;
                t1 = t0;
                tmr :> t0;
//                printf("= %d\n", t0-t1);
                break;

                // guarded select case will create back pressure.
                // I.e. c_audio will block until buffer is get_next_bufped
            case !buffer_full => c_audio :> sample:
                //if(sample_idx == 0 && !buffer_get_next_bufped_flag) {
                //printf("Buffer overflow\n");
                //};
                triple_buffer[head].data[sample_idx] = sample;
                sample_idx++;
                if(sample_idx >= SYSTEM_FRAME_ADVANCE) {
                    sample_idx = 0;
                    buffer_full = 1;
                    //Manage overlapping buffers
                    head++;
                    if(head == NUM_I2S_BUFFERS)
                        head = 0;
                }

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
        i2s_audio_block_t * unsafe buffer = 0; // invalid
        unsigned sample_idx=0;

        p_rst_shared <: 0xF;

        mabs_init_pll(i2c, SMART_MIC_BASE);

        i2c_regop_res_t res;
        int addr = 0x4A;

        uint8_t data = 1;
        res = i2c.write_reg(addr, 0x02, data); // Power down
        res = i2c.write_reg(addr+1, 0x02, data); // Power down

        // Setting MCLKDIV2 addrigh if using 24.576MHz.
        data = i2c.read_reg(addr, 0x03, res);
        data |= 1;
        res = i2c.write_reg(addr, 0x03, data);

        data = 0b01110000;
        res = i2c.write_reg(addr, 0x10, data);

        data = i2c.read_reg(addr, 0x02, res);
        data &= ~1;
        res = i2c.write_reg(addr, 0x02, data); // Power up

        addr++;
        // Setting MCLKDIV2 addrigh if using 24.576MHz.
        data = i2c.read_reg(addr, 0x03, res);
        data |= 1;
        res = i2c.write_reg(addr, 0x03, data);

        data = 0b01110000;
        res = i2c.write_reg(addr, 0x10, data);

        data = i2c.read_reg(addr, 0x02, res);
        data &= ~1;
        res = i2c.write_reg(addr, 0x02, data); // Power up

        while (1) {
            select {
                case i2s.init(i2s_config_t &?i2s_config, tdm_config_t &?tdm_config):
                    i2s_config.mode = I2S_MODE_LEFT_JUSTIFIED;
                    i2s_config.mclk_bclk_ratio = (MASTER_CLOCK_FREQUENCY/(3*OUTPUT_SAMPLE_RATE))/64;
                    break;

                case i2s.restart_check() -> i2s_restart_t restart:
                    restart = I2S_NO_RESTART;
                    break;

                case i2s.receive(size_t index, int32_t sample):
                    break;

                case i2s.send(size_t index) -> int32_t sample:
//                    xscope_int(CH0, index);
                    if(buffer) {
                        sample = buffer->data[sample_idx];
                        if (index == 0) xscope_int(CH0, sample);
                    } else { // buffer invalid
                        sample = 0;
                    }
                    if (index == 3) {
                        sample_idx++;
                        if(sample_idx>=SYSTEM_FRAME_ADVANCE) {
                            // end of buffer reached.
                            sample_idx = 0;
                            filler.get_next_buf(buffer);
                        }
                    }
                    break;
            }
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
    i2s_callback_if i_i2s_interfaces;
    i2c_master_if i_i2c[1];
    interface bufget_i bufget;
    chan c_agc_to_i2s, c_microphone_to_bs, c_bs_to_ns;
    chan c_tobuffer, c_button_vad, c_button_suppress;
    chan c_music_for_speaker;
    par{
        on tile[0]: {
            far_end_audio_server(c_music_for_speaker);
        }
        on tile[1]: {
          configure_clock_src(mclk, p_mclk_in1);
          start_clock(mclk);
          i2s_master(i_i2s_interfaces, p_i2s_dout, 2, null, 0, p_bclk, p_lrclk, bclk, mclk);
        }

        on tile[1]: [[distribute]] i2c_master_single_port(i_i2c, 1, p_i2c, 100, 0, 1, 0);
        on tile[1]: [[distribute]] i2s_handler(i_i2s_interfaces, i_i2c[0], bufget);
        on tile[1]:  output_audio_dbuf_handler(bufget, triple_i2s_buffer, c_tobuffer);
        on tile[1]:  upsampler(c_agc_to_i2s, c_tobuffer);

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

                get_pdm(c_microphone_to_bs, c_ds_output);
            }
        }
    }

    return 0;
}

