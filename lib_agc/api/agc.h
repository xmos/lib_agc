// Copyright (c) 2017-2019, XMOS Ltd, All rights reserved
#ifndef _agc_h_
#define _agc_h_

#include "dsp.h"
#include "vtb_q_format.h"
#include "agc_state.h"


typedef struct {
    int adapt;
    vtb_uq16_16_t init_gain;
    vtb_uq16_16_t max_gain;
    uint32_t desired_level;
} agc_config_t;


void agc_test_task(chanend c_data_input, chanend c_data_output, chanend ?c_control);

void agc_init(agc_state_t &agc, agc_config_t config[AGC_INPUT_CHANNELS]);

void agc_set_channel_gain(agc_state_t &agc, unsigned channel,  vtb_uq16_16_t gain);

vtb_uq16_16_t agc_get_channel_gain(agc_state_t &agc, unsigned channel);

void agc_set_channel_adapt(agc_state_t &agc, unsigned channel,  uint32_t adapt);

int agc_get_channel_adapt(agc_state_t &agc, unsigned channel);


/** Function that processes a block of data.
 *
 * \param[in,out] agc     Gain controller structure
 * \param[in,out] samples On input this array contains the sample data.
 *                        On output this array contains the data with AGC
 *                        applied. Headroom has been reintroduced, and samples
 *                        have been clamped as appropriate.
 */
void agc_process_frame(agc_state_t &agc, dsp_complex_t frame_in_out[AGC_CHANNEL_PAIRS][AGC_FRAME_ADVANCE], uint8_t vad);

#endif // _agc_h_
