// Copyright (c) 2017-2021, XMOS Ltd, All rights reserved
// This software is available under the terms provided in LICENSE.txt.
#ifndef AGC_CONTROL_H_
#define AGC_CONTROL_H_

#include <xccompat.h>
#include "vtb_control.h"
#include "agc_ch_state.h"
#include "agc_control_map.h"

void agc_command_handler(chanend c_command, agc_state_t &state);

/** Set AGC channel gain.
 *
 * \param[in,out] agc       AGC state.
 *
 * \param[in] ch_index      Channel index. Must be less than AGC_INPUT_CHANNELS.
 *
 * \param[in] gain          Gain value in linear UQ16_16 format.
 */
void agc_set_ch_gain(REFERENCE_PARAM(agc_state_t, agc), unsigned ch_index, vtb_uq16_16_t gain);


/** Get AGC channel gain.
 *
 * \param[in] agc           AGC state.
 *
 * \param[in] ch_index      Channel index. Must be less than AGC_INPUT_CHANNELS.
 *
 * \returns                 Channel gain in linear UQ16_16 format.
 */
vtb_uq16_16_t agc_get_ch_gain(agc_state_t agc, unsigned ch_index);


/** Set AGC channel gain increase value.
 *
 * \param[in,out] agc       AGC state.
 *
 * \param[in] ch_index      Channel index. Must be less than AGC_INPUT_CHANNELS.
 *
 * \param[in] gain_inc      Gain increase value in linear UQ16_16 format.
 *                          Must be greater than 1.
 */
void agc_set_ch_gain_inc(REFERENCE_PARAM(agc_state_t, agc), unsigned ch_index, vtb_uq16_16_t gain_inc);


/** Get AGC channel gain increase value.
 *
 * \param[in] agc           AGC state.
 *
 * \param[in] ch_index      Channel index. Must be less than AGC_INPUT_CHANNELS.
 *
 * \returns                 Channel gain_inc in linear UQ16_16 format.
 */
vtb_uq16_16_t agc_get_ch_gain_inc(agc_state_t agc, unsigned ch_index);


/** Set AGC channel gain decrease value.
 *
 * \param[in,out] agc       AGC state.
 *
 * \param[in] ch_index      Channel index. Must be less than AGC_INPUT_CHANNELS.
 *
 * \param[in] gain_dec      Gain decrease value in linear UQ16_16 format.
 *                          Must be between 0 and 1.
 */
void agc_set_ch_gain_dec(REFERENCE_PARAM(agc_state_t, agc), unsigned ch_index, vtb_uq16_16_t gain_dec);


/** Get AGC channel gain decrease value.
 *
 * \param[in] agc           AGC state.
 *
 * \param[in] ch_index      Channel index. Must be less than AGC_INPUT_CHANNELS.
 *
 * \returns                 Channel gain_dec in linear UQ16_16 format.
 */
vtb_uq16_16_t agc_get_ch_gain_dec(agc_state_t agc, unsigned ch_index);


/** Set AGC channel max gain.
 *
 * \param[in,out] agc       AGC state.
 *
 * \param[in] ch_index      Channel index. Must be less than AGC_INPUT_CHANNELS.
 *
 * \param[in] max_gain      Max gain value in linear UQ16_16 format.
 */
void agc_set_ch_max_gain(REFERENCE_PARAM(agc_state_t, agc), unsigned ch_index,
        vtb_uq16_16_t max_gain);


/** Get AGC channel max gain.
 *
 * \param[in] agc           AGC state.
 *
 * \param[in] ch_index      Channel index. Must be less than AGC_INPUT_CHANNELS.
 *
 * \returns                 Channel max gain in linear UQ16_16 format.
 */
vtb_uq16_16_t agc_get_ch_max_gain(agc_state_t agc, unsigned ch_index);


/** Set AGC channel min gain.
 *
 * \param[in,out] agc       AGC state.
 *
 * \param[in] ch_index      Channel index. Must be less than AGC_INPUT_CHANNELS.
 *
 * \param[in] min_gain      Min gain value in linear UQ16_16 format.
 */
void agc_set_ch_min_gain(REFERENCE_PARAM(agc_state_t, agc), unsigned ch_index,
        vtb_uq16_16_t min_gain);


/** Get AGC channel min gain.
 *
 * \param[in] agc           AGC state.
 *
 * \param[in] ch_index      Channel index. Must be less than AGC_INPUT_CHANNELS.
 *
 * \returns                 Channel min gain in linear UQ16_16 format.
 */
vtb_uq16_16_t agc_get_ch_min_gain(agc_state_t agc, unsigned ch_index);


/** Set AGC channel adapt flag.
 *
 * \param[in,out] agc       AGC state.
 *
 * \param[in] ch_index      Channel index. Must be less than AGC_INPUT_CHANNELS.
 *
 * \param[in] adapt         AGC adapt flag: 0 for fixed gain, 1 for adapt.
 */
void agc_set_ch_adapt(REFERENCE_PARAM(agc_state_t, agc), unsigned ch_index,  uint32_t adapt);


/** Get AGC channel adapt flag.
 *
 * \param[in] agc           AGC state.
 *
 * \param[in] ch_index      Channel index. Must be less than AGC_INPUT_CHANNELS.
 *
 * \returns                 0 for fixed gain, 1 for adapt.
 */
int agc_get_ch_adapt(agc_state_t agc, unsigned ch_index);



/** Set AGC channel adapt on VAD flag.
 *
 * \param[in,out] agc       AGC state.
 *
 * \param[in] ch_index      Channel index. Must be less than AGC_INPUT_CHANNELS.
 *
 * \param[in] adapt         AGC on VAD adapt flag: 0 for adapting when voice is detected, 1 if always adapting.
 */
void agc_set_ch_adapt_on_vad(REFERENCE_PARAM(agc_state_t, agc), unsigned ch_index,  uint32_t adapt);


/** Get AGC channel adapt on VAD flag.
 *
 * \param[in] agc           AGC state.
 *
 * \param[in] ch_index      Channel index. Must be less than AGC_INPUT_CHANNELS.
 *
 * \returns                 0 for adapting when voice is detected, 1 if always adapting.
 */
int agc_get_ch_adapt_on_vad(agc_state_t agc, unsigned ch_index);

/** Set AGC channel soft clipping flag.
 *
 * \param[in,out] agc       AGC state.
 *
 * \param[in] ch_index      Channel index. Must be less than AGC_INPUT_CHANNELS.
 *
 * \param[in] soft_clipping AGC soft clipping flag: 0 for soft clipping disabled, 1 for for soft clipping enabled.
 */
void agc_set_ch_soft_clipping(REFERENCE_PARAM(agc_state_t, agc), unsigned ch_index,  uint32_t soft_clipping);


/** Get AGC channel soft clipping  flag.
 *
 * \param[in] agc           AGC state.
 *
 * \param[in] ch_index      Channel index. Must be less than AGC_INPUT_CHANNELS.
 *
 * \returns                 0 for soft clipping disabled, 1 for for soft clipping enabled.
 */
int agc_get_ch_soft_clipping(agc_state_t agc, unsigned soft_clipping);


/** Set AGC channel loss control enabled flag.
 *
 * \param[in,out] agc       AGC state.
 *
 * \param[in] ch_index      Channel index. Must be less than AGC_INPUT_CHANNELS.
 *
 * \param[in] enable        AGC LC enable flag: 0 for disabled, 1 for enabled.
 */
void agc_set_ch_lc_enable(REFERENCE_PARAM(agc_state_t, agc), unsigned ch_index,  uint32_t enable);


/** Get AGC channel loss control enabled flag.
 *
 * \param[in] agc           AGC state.
 *
 * \param[in] ch_index      Channel index. Must be less than AGC_INPUT_CHANNELS.
 *
 * \returns                 0 for disabled, 1 for enabled.
 */
int agc_get_ch_lc_enable(agc_state_t agc, unsigned ch_index);


/** Set upper threshold of desired output voice level for AGC channel.
 *
 * \param[in,out] agc           AGC state.
 *
 * \param[in] ch_index          Channel index. Must be less than
 *                              AGC_INPUT_CHANNELS.
 *
 * \param[in] upper_threshold   Upper threshold of desired output voice level
 *                              [0, INT32_MAX].
 */
void agc_set_ch_upper_threshold(REFERENCE_PARAM(agc_state_t, agc), unsigned ch_index,
        int32_t upper_threshold);


/** Set lower threshold of desired output voice level for AGC channel.
 *
 * \param[in,out] agc           AGC state.
 *
 * \param[in] ch_index          Channel index. Must be less than
 *                              AGC_INPUT_CHANNELS.
 *
 * \param[in] lower_threshold   Lower threshold of desired output voice level
 *                              [0, INT32_MAX].
 */
void agc_set_ch_lower_threshold(REFERENCE_PARAM(agc_state_t, agc), unsigned ch_index,
        int32_t lower_threshold);


/** Get upper threshold of desired output voice level for AGC channel.
 *
 * \param[in] agc           AGC state.
 *
 * \param[in] ch_index      Channel index. Must be less than AGC_INPUT_CHANNELS.
 *
 * \returns                 Lower threshold of esired output voice level for AGC channel.
 */
int32_t agc_get_ch_upper_threshold(agc_state_t agc, unsigned ch_index);


/** Get lower threshold of desired output voice level for AGC channel.
 *
 * \param[in] agc           AGC state.
 *
 * \param[in] ch_index      Channel index. Must be less than AGC_INPUT_CHANNELS.
 *
 * \returns                 Lower threshold of desired output voice level for AGC channel.
 */
int32_t agc_get_ch_lower_threshold(agc_state_t agc, unsigned ch_index);

#endif /* AGC_CONTROL_H_ */
