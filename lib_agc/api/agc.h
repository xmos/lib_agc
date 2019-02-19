// Copyright (c) 2017-2019, XMOS Ltd, All rights reserved
#ifndef _agc_h_
#define _agc_h_

#include "dsp.h"
#include "vtb_q_format.h"
#include "agc_ch_state.h"


/**
 * Structure containing AGC state unique to each input channel.
 */
typedef struct {
    agc_ch_state_t ch_state[AGC_INPUT_CHANNELS];
} agc_state_t;


/**
 * Structure containing AGC configuration unique to each input channel.
 * Used to initialise AGC state.
 */
typedef struct {
    int adapt;                  /**< 0 for fixed gain, or 1 for AGC. */
    vtb_uq16_16_t init_gain;    /**< Initial channel gain. Linear UQ16_16. */
    vtb_uq16_16_t max_gain;     /**< Maximum channel gain. Linear UQ16_16. */
    int32_t desired_level;      /**< Desired output voice level [0, INT32_MAX]. */
} agc_config_t;


/** Initialise AGC state.
 *
 * \param[out] agc          AGC state to be initialised.
 *
 * \param[in] config        Array containing AGC configuration for each channel.
 *                          Must be of length AGC_INPUT_CHANNELS.
 */
void agc_init(agc_state_t &agc, agc_config_t config[AGC_INPUT_CHANNELS]);


/** Set AGC channel gain.
 *
 * \param[in,out] agc       AGC state.
 *
 * \param[in] channel       Channel index.
 *
 * \param[in] gain          Gain value in linear UQ16_16 format.
 */
void agc_set_channel_gain(agc_state_t &agc, unsigned channel,  vtb_uq16_16_t gain);


/** Get AGC channel gain.
 *
 * \param[in] agc           AGC state.
 *
 * \param[in] channel       Channel index.
 *
 * \returns                 Channel gain in linear UQ16_16 format.
 */
vtb_uq16_16_t agc_get_channel_gain(agc_state_t agc, unsigned channel);


/** Set AGC channel adapt flag.
 *
 * \param[in,out] agc       AGC state.
 *
 * \param[in] channel       Channel index.
 *
 * \param[in] adapt         AGC adapt flag: 0 for fixed gain, 1 for adapt.
 */
void agc_set_channel_adapt(agc_state_t &agc, unsigned channel,  uint32_t adapt);


/** Get AGC channel adapt flag.
 *
 * \param[in] agc           AGC state.
 *
 * \param[in] channel       Channel index.
 *
 * \returns                 0 for fixed gain, 1 for adapt.
 */
int agc_get_channel_adapt(agc_state_t agc, unsigned channel);


/** Function that processes a block of data.
 *
 * \param[in,out] agc           AGC state.
 *
 * \param[in,out] frame_in_out  On input this array contains the sample data.
 *                              On output this array contains the data with AGC
 *                              applied.
 *
 * \param[in] vad               VAD level for input sample data [0, 255].
 */
void agc_process_frame(agc_state_t &agc, dsp_complex_t frame_in_out[AGC_CHANNEL_PAIRS][AGC_FRAME_ADVANCE], uint8_t vad);


// void agc_test_task(chanend c_data_input, chanend c_data_output, chanend ?c_control);

#endif // _agc_h_
