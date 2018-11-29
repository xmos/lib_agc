// Copyright (c) 2017-2018, XMOS Ltd, All rights reserved
#ifndef _agc_h_
#define _agc_h_

#include "dsp.h"
#include "agc_state.h"


int32_t normalise_and_saturate(int32_t gained_sample, int gained_sample_exp, int input_exponent);


void agc_test_task(chanend c_data_input, chanend c_data_output,
                chanend ?c_control);

/** Function that initialises an automatic gain controller. It needs to be
 * passed an AGC structure, and the initial gain setting in dB. The gain
 * controller is initialised with the following default values:
 *
 * - initial gain:         0 dB
 * - desired energy:     -30 dB
 * - minimum gain:      -127 dB
 * - maximum gain:       127 dB
 * - rate of gain down:  -70 dB per second
 * - rate of gain up  :    7 dB per second
 * - grace period before up 6s      THIS SHOULD BE 4?
 * - lookahead frames:     0
 * - lookpast frames:      0
 *
 * All of these can be changed using the access functions below.
 *
 * The processing function that performs the actual AGC inputs a block in
 * block-floating-point format, and outputs a block of integers. The input
 * can represent a very large dynamic range, whereas the output is
 * represented in a small dynamic range of integers in the range
 * [-2^31..2^31-1]. The AGCs purpose is to perform this range reduction in
 * a meaningful way.
 *
 * The initial gain setting and the desired energy level may have to be set
 * using one of the setters below before starting the AGC. A good guess
 * for the initial setting enables the AGC to operate without warm-up. The
 * initial setting should compensate for the sensitivity of the microphones
 * and the gain applied by any previous stages in the voice pipeline. For
 * example, if the microphones have a low sensitivity then a higher initial
 * value should be picked than if microphones have a high sensitivity.
 *
 * \param[out] agc              gain controller structure, initialised on return
 *
 */
void agc_init(agc_state_t &agc);


/** Function that processes a block of data.
 *
 * \param[in,out] agc     Gain controller structure
 * \param[in,out] samples On input this array contains the sample data.
 *                        On output this array contains the data with AGC
 *                        applied. Headroom has been reintroduced, and samples
 *                        have been clamped as appropriate.
 */
void agc_process_frame(agc_state_t &agc,
                       dsp_complex_t frame_in_out[AGC_CHANNEL_PAIRS][AGC_FRAME_ADVANCE]);

#endif // _agc_h_
