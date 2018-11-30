// Copyright (c) 2017-2018, XMOS Ltd, All rights reserved
#ifndef _agc_h_
#define _agc_h_

#include "dsp.h"
#include "agc_state.h"


void agc_test_task(chanend c_data_input, chanend c_data_output, chanend ?c_control);


void agc_init(agc_state_t &agc);

void agc_set_channel_gain(agc_state_t &agc, unsigned channel,  uint32_t gain);

/** Function that processes a block of data.
 *
 * \param[in,out] agc     Gain controller structure
 * \param[in,out] samples On input this array contains the sample data.
 *                        On output this array contains the data with AGC
 *                        applied. Headroom has been reintroduced, and samples
 *                        have been clamped as appropriate.
 */
void agc_process_frame(agc_state_t &agc, dsp_complex_t frame_in_out[AGC_CHANNEL_PAIRS][AGC_FRAME_ADVANCE]);

#endif // _agc_h_
