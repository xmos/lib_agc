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

on tile[3]: out port leds = XS1_PORT_8C;

on tile[2]: out port p_pdm_clk              = PORT_PDM_CLK;
on tile[2]: in buffered port:32 p_pdm_mics  = PORT_PDM_DATA;
on tile[2]: in port p_mclk                  = PORT_PDM_MCLK;
on tile[2]: clock pdmclk                    = XS1_CLKBLK_1;
on tile[2]: clock pdmclk6                   = XS1_CLKBLK_2;

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
#define NUM_FRAME_BUFFERS   3   //Triple buffer needed for overlapping frames

typedef struct {
    int32_t data[FFT_N]; // FFT_N/2 due to overlapping
} multichannel_audio_block_s;

multichannel_audio_block_s triple_buffer[3];

interface bufget_i {
  void get_next_buf(multichannel_audio_block_s * unsafe &buf);
};


#define FRAME_LENGTH (1<<MIC_ARRAY_MAX_FRAME_SIZE_LOG2)
#define DECIMATOR_COUNT     2   //8 channels requires 2 decimators
#define FRAME_BUFFER_COUNT  2   //The minimum of 2 will suffice for this example

int sineWave48[48] = {
0,
1305,
2588,
3826,
4999,
6087,
7071,
7933,
8660,
9238,
9659,
9914,
10000,
9914,
9659,
9238,
8660,
7933,
7071,
6087,
5000,
3826,
2588,
1305,
0,
-1305,
-2588,
-3826,
-4999,
-6087,
-7071,
-7933,
-8660,
-9238,
-9659,
-9914,
-10000,
-9914,
-9659,
-9238,
-8660,
-7933,
-7071,
-6087,
-5000,
-3826,
-2588,
-1305,
};

int sineWave[16] = {
    0,
    5000,
    7071,
    8660,
    10000,
    8660,
    7071,
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

void get_pdm(chanend audio_out,
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
        
        assert((1<<MIC_ARRAY_MAX_FRAME_SIZE_LOG2) == BS_FRAME_LENGTH/2);
        assert(MIC_ARRAY_NUM_MICS >= BS_CHANNELS);
        assert(BS_FRAME_LENGTH/2 == DEMO_NS_AGC_FRAME_LENGTH);
        
        mic_array_decimator_configure(c_ds_output, DECIMATOR_COUNT, dc);

        mic_array_init_time_domain_frame(c_ds_output, DECIMATOR_COUNT, buffer, audio, dc);
        int cnt = 10;
        unsigned int gain = 0x10000;

        while(1){
            mic_array_frame_time_domain *  current =
                               mic_array_get_next_time_domain_frame(c_ds_output, DECIMATOR_COUNT, buffer, audio, dc);
            int32_t data_buf[FRAME_LENGTH];
            
            // Copy the current sample to the delay buffer
            uint32_t mask = 0;
            for(unsigned i=0;i<BS_CHANNELS;i++){
                for(unsigned j=0;j<BS_FRAME_LENGTH/2;j++){
                    int x = current->data[i][j];
                    if (x > 0) {
                        mask |= x;
                    } else {
                        mask |= -x;
                    }
                }
            }
            uint32_t headroom = clz(mask);
            if (headroom > 2) {
                headroom -= 2;
            } else {
                headroom = 0;
            }
            master {
                for(unsigned i=0;i<BS_CHANNELS;i++){
                    for(unsigned j=0;j<BS_FRAME_LENGTH/2;j++){
                        audio_out <: (current -> data[i][j] << headroom);
                    }
                }
                audio_out <: headroom;
            }
        }
    }
}


src_os3_ctrl_t src;
int delays[SRC_FF3_OS3_N_COEFS/SRC_FF3_OS3_N_PHASES*4];

void upsampler(chanend c_in,
               chanend c_out) {
    int data[FRAME_LENGTH];
    unsafe {
        src.delay_base = delays;
        src_os3_init(&src);
        while(1) {
            for(unsigned i=0;i<FRAME_LENGTH;i++) {
                c_in :> data[i];
            }
            for(unsigned i=0;i<FRAME_LENGTH;i++) {
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
                               multichannel_audio_block_s triple_buffer[3],
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
            case input.get_next_buf(multichannel_audio_block_s * unsafe &buf):
                // pass ptr to previous buffer
                if(head==0) {
                    buf = &triple_buffer[NUM_FRAME_BUFFERS-1];
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
                if(sample_idx>=FFT_N) {
                    sample_idx = 0;
                    buffer_full = 1;
                    //Manage overlapping buffers
                    head++;
                    if(head == NUM_FRAME_BUFFERS)
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
        multichannel_audio_block_s * unsafe buffer = 0; // invalid
        unsigned sample_idx=0;
        int left = 1;

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
                    if(buffer) {
                        sample = buffer->data[sample_idx];
                        if (left) xscope_int(CH0, sample);
                    } else { // buffer invalid
                        sample = 0;
                    }
                    left = !left;
                    if (left) {
                        sample_idx++;
                    }
                    if(sample_idx>=FFT_N) {
                        // end of buffer reached.
                        sample_idx = 0;
                        filler.get_next_buf(buffer);
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
        printf("Keepnoise: %d, apat_bs: %d\n", keep_noise, adapt_bs);
        suppress <: keep_noise;
        adapt <: adapt_bs;
    }
}


int main(){
    i2s_callback_if i_i2s;
    i2c_master_if i_i2c[1];
    interface bufget_i bufget;
    chan c_agc_to_i2s, c_microphone_to_bs, c_bs_to_ns;
    chan c_tobuffer, c_button_vad, c_button_suppress;
    par{
        on tile[1]: {
          configure_clock_src(mclk, p_mclk_in1);
          start_clock(mclk);
          i2s_master(i_i2s, p_i2s_dout, 1, null, 0, p_bclk, p_lrclk, bclk, mclk);
        }

        on tile[1]: [[distribute]] i2c_master_single_port(i_i2c, 1, p_i2c, 100, 0, 1, 0);
        on tile[1]: [[distribute]] i2s_handler(i_i2s, i_i2c[0], bufget);
        on tile[1]:  output_audio_dbuf_handler(bufget, triple_buffer, c_tobuffer);
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

