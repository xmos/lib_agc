// Copyright (c) 2017, XMOS Ltd, All rights reserved
#ifndef _agc_h_
#define _agc_h_

#include "agc_state.h"

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
 * \param[in] frame_length      Number of samples on which AGC operates.
 */
void agc_init(agc_state_t &agc, uint32_t frame_length);


/** Function that sets the maximum gain allowed on the automatic gain
 * control. This value must be larger than or equal to the initial gain,
 * and larger than or equal to the minimum gain. The gain must be in the
 * range [-127..127]. This function is typically not used as the default
 * used by agc_init_state() will do the trick.
 *
 * \param[in,out] agc Gain controller structure
 * \param[in] db      Desired maximum gain in dB
 */
void agc_set_gain_max_db(agc_state_t &agc, int32_t db);

/** Function that sets the minimum gain allowed on the automatic gain
 * control. This value must be less than or equal to the initial gain, and
 * less than or equal to the maximum gain. The gain must be in the
 * range [-127..127]. This function is typically not used as the default
 * used by agc_init_state() will do the trick.
 *
 * \param[in,out] agc Gain controller structure
 * \param[in] db      Desired minimum gain in dB
 */
void agc_set_gain_min_db(agc_state_t &agc, int32_t db);

/** Function that sets the desired energy level of the output. Must be
 * negative in the range [-127..-1]. Values too close to zero will cause
 * clipping. This function can be used to change the volume of the output.
 * Note that changes will not happen immediately and are governed by the
 * delay, and the maximum up and down rates.
 *
 * For example, a value of -20 indicates that the energy should be 10x
 * below whole scale. If the input is a pure sine wave, then the energy is
 * sqrt(1/2) times the amplitude of the sine wave, hence at a setting of
 * -20 dB the amplitude of the output sine wave will be 10/sqrt(1/2) or
 * 0.1414 of whole scale, or +/- 303700050. The actual level of the sine
 * wave will be slightly higher or lower, since the AGC algorithm uses a
 * hysteresis around the desired energy level. Note that if the desired
 * output is set to 0 dB (meaning whole scale), the actual output of a
 * sine-wave will be (10^(0/20))/sqrt(1/2) = 1.414 of whole scale, which
 * will lead to wide-spread clipping. Hence, in order to avoid clipping,
 * keep the desired output level at least a few dB below zero.

 *
 * \param[in,out] agc Gain controller structure
 * \param[in] db      Desired output energy in dB
 */
void agc_set_desired_db(agc_state_t &agc, int32_t db);

/** Function that sets the speed at which the gain controller adapts whilst
 * increasing gain. The value is expressed in dB per second, and must be
 * in the range [1..1023]
 *
 * \param[in,out] agc Gain controller structure
 * \param[in] dbps    Desired adaptation speed in dB per second
 */
void agc_set_rate_down_dbps(agc_state_t &agc, int32_t dbps);

/** Function that sets the speed at which the gain controller adapts whilst
 * decreasing gain. The value is expressed in dB per second, and must be
 * in the range [-1023..-1]
 *
 * \param[in,out] agc Gain controller structure
 * \param[in] dbps    Desired adaptation speed in dB per 10 milliseconds
 */
void agc_set_rate_up_dbps(agc_state_t &agc, int32_t dbps);

/** Function that sets the grace period before the gain starts increasing
 *
 * \param[in,out] agc      Gain controller structure
 * \param[in] milliseconds Time between quiescence and gain increasing
 */
void agc_set_wait_for_up_ms(agc_state_t &agc, uint32_t milliseconds);

/** Function that sets the number of frames to look in the past.
 *
 * \param[in] look_past_frames  Number of frames to look in the past for energy
 *                              If this is larger than zero, than a buffer 
 *                              needs to be passed to agc_process_frame()
 */
extern void agc_set_look_past_frames(agc_state_t &agc, uint32_t look_past_frames);

/** Function that sets the number of frames to look in the future. If this
 * is set, then the data signal will be delayed by as many frames.
 *
 * \param[in] look_ahead_frames Number of frames to look ahead for energy
 *                              If this is larger than zero, than a buffer 
 *                              needs to be passed to agc_process_frame()
 */

extern void agc_set_look_ahead_frames(agc_state_t &agc, uint32_t look_ahead_frames);


/** Function that processes a block of data.
 *
 * \param[in,out] agc     Gain controller structure
 * \param[in,out] samples On input this array contains the sample data.
 *                        If headroom has been removed, then the shr parameter
 *                        should be set to the amount of headroom that has been
 *                        removed. 
 *                        On output this array contains the data with AGC
 *                        applied. Headroom has been reintroduced, and samples
 *                        have been clamped as appropriate. 
 * \param[in] shr         Number of bits that samples have been shifted left by
 * 
 * \param[in,out] sample_buffer Buffer that holds historic samples. Must be an
 *                        array of at least (LOOK_AHEAD_FRAMES+1) * FRAME_SIZE
 *                        words, where LOOK_AHEAD_FRAMES is the number of frames
 *                        that shall be looked ahead for energy, and FRAME_SIZE
 *                        is the number of samples per frame. If
 *                        LOOK_AHEAD_FRAMES is zero then null can be passed in.
 *
 * \param[in,out] energy_buffer Buffer that holds historic energy samples.
 *                        Must be an array of at least (LOOK_PAST_FRAMES +
 *                        LOOK_AHEAD_FRAMES + 1) words which is the number
 *                        of past frames to use for energy estimation. If
 *                        LOOK_PAST_FRAMES and LOOK_AHEAD_FRAMES are 0 then
 *                        null can be used for this parameter.
 */
void agc_process_frame(agc_state_t &agc,
                       int32_t samples[],
                       int32_t shr,
                       int32_t (&?sample_buffer)[],
                       uint32_t (&?energy_buffer)[]);

/** Function that gets the current gain.
 * \param[in] agc Gain controller structure
 * \returns       gain in dB, multiplied by 2^16. Ie, 0x0001 0000 = 1 dB.
 */
int32_t agc_get_gain(agc_state_t &agc);


#endif // _agc_h_
