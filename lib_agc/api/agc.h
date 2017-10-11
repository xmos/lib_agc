// Copyright (c) 2017, XMOS Ltd, All rights reserved
#ifndef _agc_h_
#define _agc_h_

#include "agc_state.h"

/** Function that initialises an automatic gain controller. It needs to be
 * passed an AGC structure, and the initial gain setting in dB. The gain
 * controller is initialised with the following default values:
 *
 * - minimum gain:      -127 dB
 * - maximum gain:       127 dB
 * - rate of gain down:  -70 dB per second
 * - rate of gain up  :    7 dB per second
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
 * The important value that is set in this call is the desired energy
 * level. This is given in dB of the whole output scale. For example, a
 * value of -20 indicates that the energy should be 10x below whole scale.
 * If the input is a pure sine wave, then the energy is sqrt(1/2) times the
 * amplitude of the sine wave, hence at a setting of -20 dB the amplitude
 * of the output sine wave will be 10/sqrt(1/2) or 0.1414 of whole scale,
 * or +/- 303700050. The actual level of the sine wave will be slightly
 * higher or lower, since the AGC algorithm uses a hysteresis around the
 * desired energy level. Note that if the desired output is set to 0 dB
 * (meaning whole scale), the actual output of a sinewave will be
 * (10^(0/20))/sqrt(1/2) = 1.414 of whole scale, which will lead to
 * wide-spread clipping. Hence, in order to avoid clipping, keep the
 * desired output level at least a few dB below zero.
 *
 * The other important parameter is the initial gain setting. A good guess
 * for the initial setting enables the AGC to operate without warm-up. The
 * initial setting should compensate for the sensitivity of the microphones
 * and the gain applied by any previous stages in the voice pipeline. For
 * example, if the microphones have a low sensitivity then a higher initial
 * value should be picked than if microphones have a high sensitiviy.
 * 
 * \param agc[out]              gain controller structure, initialised on return
 *
 * \param initial_gain_db[in]   Initial gain in dB. The initial gain must be
 *                              in the range [-127..127]. If you are uncertain
 *                              estimate it on the high side; it will adjust
 *                              quickly down to the right value.
 *
 * \param desired_energy_db[in] desired energy in dB. -6 is a good number. The
 *                              desired energy must be in the range [-127..-1].
 *
 * \param frame_length[in]      Number of samples on which AGC operates.
 *
 * \param look_past_frames[in]  Number of frames to look in the past for energy
 *                              If this is larger than zero, than a buffer 
 *                              needs to be passed to agc_process_block()
 * 
 * \param look_ahead_frames[in] Number of frames to look ahead for energy
 *                              If this is larger than zero, than a buffer 
 *                              needs to be passed to agc_process_block()
 * 
 */
void agc_init_state(agc_state_t &agc,
                    int32_t initial_gain_db,
                    int32_t desired_energy_db,
                    uint32_t frame_length,
                    uint32_t look_past_frames,
                    uint32_t look_ahead_frames);

/** Function that sets the maximum gain allowed on the automatic gain
 * control. This value must be larger than or equal to the initial gain,
 * and larger than or equal to the minimum gain. The gain must be in the
 * range [-127..127]. This function is typically not used as the default
 * used by agc_init_state() will do the trick.
 *
 * \param agc[in,out] Gain controller structure
 * \param db[in]      Desired maximum gain in dB
 */
void agc_set_gain_max_db(agc_state_t &agc, int32_t db);

/** Function that sets the minimum gain allowed on the automatic gain
 * control. This value must be less than or equal to the initial gain, and
 * less than or equal to the maximum gain. The gain must be in the
 * range [-127..127]. This function is typically not used as the default
 * used by agc_init_state() will do the trick.
 *
 * \param agc[in,out] Gain controller structure
 * \param db[in]      Desired minimum gain in dB
 */
void agc_set_gain_min_db(agc_state_t &agc, int32_t db);

/** Function that sets the desired energy level of the output. Must be
 * negative in the range [-127..-1]. Values too close to zero will cause
 * clipping. This function can be used to change the volume of the output.
 * Note that changes will not happen immediately and are governed by the
 * delay, and the maximum up and down rates.
 *
 * \param agc[in,out] Gain controller structure
 * \param db[in]      Desired output energy in dB
 */
void agc_set_desired_db(agc_state_t &agc, int32_t db);

/** Function that sets the speed at which the gain controller adapts whilst
 * increasing gain. The value is expressed in dB per second, and must be
 * in the range [1..1023]
 *
 * \param agc[in,out] Gain controller structure
 * \param dbps[in]    Desired adaptation speed in dB per second
 */
void agc_set_rate_down_dbps(agc_state_t &agc, int32_t dbps);

/** Function that sets the speed at which the gain controller adapts whilst
 * decreasing gain. The value is expressed in dB per second, and must be
 * in the range [-1023..-1]
 *
 * \param agc[in,out] Gain controller structure
 * \param dbps[in]    Desired adaptation speed in dB per second
 */
void agc_set_rate_up_dbps(agc_state_t &agc, int32_t dbps);

/** Function that sets the grace period before the gain starts increasing
 *
 * \param agc[in,out]      Gain controller structure
 * \param milliseconds[in] Time between quiesence and gain increasing
 */
void agc_set_wait_for_up_ms(agc_state_t &agc, uint32_t milliseconds);

/** Function that processes a block of data.
 *
 * \param agc[in,out]     Gain controller structure
 * \param samples[in,out] On input this array contains the sample data.
 *                        If headroom has been removed, then the shr parameter
 *                        should be set to the amount of headroom that has been
 *                        removed. 
 *                        On output this array contains the data with AGC
 *                        applied. Headroom has been reintroduced, and samples
 *                        have been clamped as appropriate. 
 * \param shr[in]         Number of bits that samples have been shifted left by
 * 
 * \param sample_buffer[in,out] Buffer that holds historic samples. Must be an
 *                        array of at least (LOOK_AHEAD_FRAMES+1) * FRAME_SIZE
 *                        words, where LOOK_AHEAD_FRAMES is the number of frames
 *                        that shall be looked ahead for energy, and FRAME_SIZE
 *                        is the number of samples per frame. If
 *                        LOOK_AHEAD_FRAMES is zero then null can be passed in.
 *
 * \param energy_buffer[in,out] Buffer that holds historic energy samples.
 *                        Must be an array of at least (LOOK_PAST_FRAMES +
 *                        LOOK_AHEAD_FRAMES + 1) words which is the number
 *                        of past frames to use for energy estimation. If
 *                        LOOK_PAST_FRAMES and LOOK_AHEAD_FRAMES are 0 then
 *                        null can be used for this parameter.
 */
void agc_block(agc_state_t &agc,
               int32_t samples[],
               int32_t shr,
               int32_t (&?sample_buffer)[],
               uint32_t (&?energy_buffer)[]);

/** Function that gets the current gain.
 * \param agc[in] Gain controller structure
 * \returns       gain in dB, multiplied by 2^16. Ie, 0x0001 0000 = 1 dB.
 */
int32_t agc_get_gain(agc_state_t &agc);


#endif // _agc_h_
