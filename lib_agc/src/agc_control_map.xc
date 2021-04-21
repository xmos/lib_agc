// Copyright 2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#include "agc_conf.h"
#include "agc_control_map.h"

unsigned agc_control_map[agc_num_commands][3] = {
    {agc_cmd_set_gain,               AGC_INPUT_CHANNELS, vtb_ctrl_fixed_16_16},
    {agc_cmd_get_gain,               AGC_INPUT_CHANNELS, vtb_ctrl_fixed_16_16},
    {agc_cmd_set_max_gain,           AGC_INPUT_CHANNELS, vtb_ctrl_fixed_16_16},
    {agc_cmd_get_max_gain,           AGC_INPUT_CHANNELS, vtb_ctrl_fixed_16_16},
    {agc_cmd_set_min_gain,           AGC_INPUT_CHANNELS, vtb_ctrl_fixed_16_16},
    {agc_cmd_get_min_gain,           AGC_INPUT_CHANNELS, vtb_ctrl_fixed_16_16},
    {agc_cmd_set_adapt,              AGC_INPUT_CHANNELS, vtb_ctrl_uint32},
    {agc_cmd_get_adapt,              AGC_INPUT_CHANNELS, vtb_ctrl_uint32},
    {agc_cmd_set_adapt_on_vad,       AGC_INPUT_CHANNELS, vtb_ctrl_uint32},
    {agc_cmd_get_adapt_on_vad,       AGC_INPUT_CHANNELS, vtb_ctrl_uint32},
    {agc_cmd_set_soft_clipping,      AGC_INPUT_CHANNELS, vtb_ctrl_uint32},
    {agc_cmd_get_soft_clipping,      AGC_INPUT_CHANNELS, vtb_ctrl_uint32},
    {agc_cmd_set_lc_enabled,         AGC_INPUT_CHANNELS, vtb_ctrl_uint32},
    {agc_cmd_get_lc_enabled,         AGC_INPUT_CHANNELS, vtb_ctrl_uint32},
    {agc_cmd_set_desired_upper_threshold,      AGC_INPUT_CHANNELS, vtb_ctrl_fixed_1_31},
    {agc_cmd_set_desired_lower_threshold,      AGC_INPUT_CHANNELS, vtb_ctrl_fixed_1_31},
    {agc_cmd_get_desired_upper_threshold,      AGC_INPUT_CHANNELS, vtb_ctrl_fixed_1_31},
    {agc_cmd_get_desired_lower_threshold,      AGC_INPUT_CHANNELS, vtb_ctrl_fixed_1_31},
    {agc_cmd_get_gain_increment_stepsize, AGC_INPUT_CHANNELS, vtb_ctrl_fixed_16_16},
    {agc_cmd_get_gain_decrement_stepsize, AGC_INPUT_CHANNELS, vtb_ctrl_fixed_16_16},
    {agc_cmd_set_gain_increment_stepsize, AGC_INPUT_CHANNELS, vtb_ctrl_fixed_16_16},
    {agc_cmd_set_gain_decrement_stepsize, AGC_INPUT_CHANNELS, vtb_ctrl_fixed_16_16},
    {agc_cmd_get_lc_n_frames, 2*AGC_INPUT_CHANNELS, vtb_ctrl_uint32},
    {agc_cmd_set_lc_n_frames, 2+1, vtb_ctrl_uint32},
    {agc_cmd_get_lc_corr_threshold, 1*AGC_INPUT_CHANNELS, vtb_ctrl_fixed_0_32},
    {agc_cmd_set_lc_corr_threshold, 1+1, vtb_ctrl_fixed_0_32},
    {agc_cmd_get_lc_gammas, 3*AGC_INPUT_CHANNELS, vtb_ctrl_fixed_16_16},
    {agc_cmd_set_lc_gammas, 1+3, vtb_ctrl_fixed_16_16},
    {agc_cmd_get_lc_deltas, 3*AGC_INPUT_CHANNELS, vtb_ctrl_fixed_16_16},
    {agc_cmd_set_lc_deltas, 1+3, vtb_ctrl_fixed_16_16},
    {agc_cmd_get_lc_gains, 4*AGC_INPUT_CHANNELS, vtb_ctrl_fixed_16_16},
    {agc_cmd_set_lc_gains, 1+4, vtb_ctrl_fixed_16_16},
};
