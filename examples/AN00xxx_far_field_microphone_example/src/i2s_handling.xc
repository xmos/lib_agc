#include <xs1.h>
#include <xscope.h>
#include "mic_array_board_support.h"

#include "i2s.h"
#include "i2c.h"
#include "src.h"
#include "system_defines.h"

#define MASTER_CLOCK_FREQUENCY 24576000
#define OUTPUT_SAMPLE_RATE        16000

#define IN_CHANNELS 2

int32_t buffer_out[2][SYSTEM_FRAME_ADVANCE];
int32_t buffer_in [2][SYSTEM_FRAME_ADVANCE][IN_CHANNELS];

[[distributable]] static void i2s_handler_no_buffer(server i2s_callback_if i2s,
                                             client i2c_master_if i2c, 
                                             chanend need_more,
                                             out port p_rst
    ) {
    p_rst <: 0xF;
    mabs_init_pll(i2c, SMART_MIC_BASE);
    for(int addr = 0x4A; addr < 0x4C; addr++) {
        i2c_regop_res_t res;
        uint8_t data = 1;
        res = i2c.write_reg(addr, 0x02, data); // Power down
        data = i2c.read_reg(addr, 0x03, res);
        data |= 1;
        res = i2c.write_reg(addr, 0x03, data);
        data = 0b01110000;
        res = i2c.write_reg(addr, 0x10, data);
        data = 0;
        res = i2c.write_reg(addr, 0x02, data); // Power up
    }
    static int32_t [[aligned(8)]] us_data[24] = {0};
    static int32_t [[aligned(8)]] ds_data[IN_CHANNELS][SRC_FF3V_FIR_NUM_PHASES][SRC_FF3V_FIR_TAPS_PER_PHASE];
    unsigned in_buff = 0, in_cnt = 0;
    unsigned out_buff = 0, out_cnt = 0;
    int thesample = 0;
    int us_sub_sample = 0;
    int ds_sub_sample = 0;
    uint64_t sum[IN_CHANNELS] = {0};

    while (1) {
        select {
        case i2s.init(i2s_config_t &?i2s_config, tdm_config_t &?tdm_config):
            i2s_config.mode = I2S_MODE_LEFT_JUSTIFIED;
            i2s_config.mclk_bclk_ratio = (MASTER_CLOCK_FREQUENCY/(3*OUTPUT_SAMPLE_RATE))/64;
            break;

        case i2s.restart_check() -> i2s_restart_t restart:
            restart = I2S_NO_RESTART;
            break;

        case i2s.receive(size_t ch, int32_t sample):
            // Capture stereo reference signal
#if 1
            if (ds_sub_sample == 0) {
                sum[ch] = src_ds3_voice_add_sample(sum[ch],
                                                   ds_data[ch][0],
                                                   src_ff3v_fir_coefs[0],
                                                   sample);
                ds_sub_sample = 1;
            } else if (ds_sub_sample == 1) {
                sum[ch] = src_ds3_voice_add_sample(sum[ch],
                                                   ds_data[ch][1],
                                                   src_ff3v_fir_coefs[1],
                                                   sample);
                ds_sub_sample = 2;
            } else if (ds_sub_sample == 2) {
                sum[ch] = src_ds3_voice_add_final_sample(sum[ch],
                                                         ds_data[ch][2],
                                                         src_ff3v_fir_coefs[2],
                                                         sample);
                ds_sub_sample = 0;
                buffer_in[in_buff][in_cnt][ch] = sum[ch] >> 31;
                sum[ch] = 0;
                if (ch == 1) {
                    in_cnt++;
                    if (in_cnt == SYSTEM_FRAME_ADVANCE) {
                        in_buff = !in_buff;
                        in_cnt = 0;
                        // swap buffers within a 1 us window
                    }
                }
            }
#endif
            break;

        case i2s.send(size_t index) -> int32_t sample:
            if (index == 0) {
                if (us_sub_sample == 0) {
                    int s = buffer_out[out_buff][out_cnt];
                    thesample = sample = src_us3_voice_input_sample(us_data, src_ff3v_fir_coefs[2], s);
//            xscope_int(CH0, sample);
                    us_sub_sample = 1;
                } else if (us_sub_sample == 1) {
                    thesample = sample = src_us3_voice_get_next_sample(us_data, src_ff3v_fir_coefs[1]);
                    us_sub_sample = 2;
                } else if (us_sub_sample == 2) {
                    thesample = sample = src_us3_voice_get_next_sample(us_data, src_ff3v_fir_coefs[0]);
                    us_sub_sample = 0;
                }
            } else {
                sample = thesample;
                if (us_sub_sample == 0) {
                    out_cnt++;
                    if (out_cnt == SYSTEM_FRAME_ADVANCE) {
                        need_more <: out_buff;
                        out_buff = !out_buff;
                        out_cnt = 0;
                    }
                }
            }
            break;
        }
    }
}

on tile[1]: out buffered port:32 p_i2s_dout[1] = {PORT_I2S_DAC0};
on tile[1]: in buffered port:32 p_i2s_din[1]   = {XS1_PORT_1A};
on tile[1]: in port p_mclk_in1                 = PORT_MCLK_IN;
on tile[1]: out buffered port:32 p_bclk        = PORT_I2S_BCLK;
on tile[1]: out buffered port:32 p_lrclk       = PORT_I2S_LRCLK;
on tile[1]: port p_i2c                         = PORT_I2C_SCL_SDA; // C:1, D:2
on tile[1]: port p_rst_shared                  = PORT_DAC_RST_N;  
on tile[1]: clock mclk                         = XS1_CLKBLK_3;
on tile[1]: clock bclk                         = XS1_CLKBLK_4;

void i2s_main(chanend c_agc_to_i2s) {
    i2s_callback_if i_i2s_interfaces;
    i2c_master_if i_i2c[1];
    
    configure_clock_src(mclk, p_mclk_in1);
    start_clock(mclk);
    par {
        i2s_master(i_i2s_interfaces,
                   p_i2s_dout, 1,
                   p_i2s_din, 1,
                   p_bclk, p_lrclk, bclk, mclk);
        [[distribute]] i2c_master_single_port(i_i2c, 1, p_i2c, 100, 0, 1, 0);
        [[distribute]] i2s_handler_no_buffer(i_i2s_interfaces, i_i2c[0],
                                             c_agc_to_i2s, p_rst_shared);
    }
}
