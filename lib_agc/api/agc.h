// Copyright (c) 2017-2021, XMOS Ltd, All rights reserved
#ifndef _AGC_H_
#define _AGC_H_

#include "dsp.h"
#include "vtb_q_format.h"
#include "agc_ch_state.h"


/**
 * Structure containing AGC configuration unique to each input channel.
 * Used to initialise AGC channel state.
 */
typedef struct {
    int adapt;                      ///< 0 for fixed gain, or 1 for AGC.
    int adapt_on_vad;               ///< 0 if always adapt AGC, or 1 if adapt AGC only when voice is detection.
    int soft_clipping;              ///< 0 for no soft clipping, or 1 for soft clipping.
    vtb_uq16_16_t init_gain;        ///< Initial channel gain. Linear UQ16_16.
    vtb_uq16_16_t max_gain;         ///< Maximum channel gain. Linear UQ16_16.
    vtb_uq16_16_t min_gain;         ///< Minimum channel gain. Linear UQ16_16.
    vtb_uq1_31_t upper_threshold;   ///< Upper threshold for desired output voice level [0, INT32_MAX].
    vtb_uq1_31_t lower_threshold;   ///< Lower threshold for desired output voice level [0, INT32_MAX].
    vtb_uq16_16_t gain_inc;         ///< Step value to increment the channel gain.
    vtb_uq16_16_t gain_dec;         ///< Step value to decrement the channel gain.
    int lc_enabled;
} agc_ch_init_config_t;

/**
 * Structure containing AGC configuration
 * Used to initialise AGC state.
 */
typedef struct {
    agc_ch_init_config_t ch_init_config[AGC_INPUT_CHANNELS];
} agc_init_config_t;

/** Initialise AGC state given an initial configuration.
 *
 * \param[out] agc          AGC state to be initialised.
 *
 * \param[in] config        Array containing AGC configuration for each channel.
 *                          Must be of length AGC_INPUT_CHANNELS.
 */
void agc_init(agc_state_t &agc, agc_init_config_t config);

/** Process a multi-channel frame of time-domain sample data.
 *
 * \param[in,out] agc           AGC state.
 *
 * \param[in,out] frame_in_out  On input this array contains the sample data.
 *                              On output this array contains the data with AGC
 *                              applied.
 *
 * \param[in] far_power         Frame power of reference audio.
 *
 * \param[in] vad_flag          VAD flag for input sample data. Non-zero indicates
 *                              that the sample data contains voice activity.
 *
 * \param[in] aec_corr          AEC correlation value. A value close to 1 indicates
 *                              that the mic energy is dominated by reference audio.
 */
void agc_process_frame(agc_state_t &agc,
        vtb_ch_pair_t frame_in_out[AGC_CHANNEL_PAIRS][AGC_PROC_FRAME_LENGTH],
        vtb_u32_float_t far_power,
        int vad_flag,
        vtb_uq0_32_t aec_corr);


#endif // _AGC_H_
