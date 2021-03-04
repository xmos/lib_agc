// Copyright (c) 2020-2021, XMOS Ltd, All rights reserved
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
    {agc_cmd_get_lc_n_frame_far, AGC_INPUT_CHANNELS, vtb_ctrl_uint32},
    {agc_cmd_set_lc_n_frame_far, AGC_INPUT_CHANNELS, vtb_ctrl_uint32},
    {agc_cmd_get_lc_n_frame_near, AGC_INPUT_CHANNELS, vtb_ctrl_uint32},
    {agc_cmd_set_lc_n_frame_near, AGC_INPUT_CHANNELS, vtb_ctrl_uint32},
    {agc_cmd_get_lc_corr_threshold, AGC_INPUT_CHANNELS, vtb_ctrl_fixed_0_32},
    {agc_cmd_set_lc_corr_threshold, AGC_INPUT_CHANNELS, vtb_ctrl_fixed_0_32},
    {agc_cmd_get_lc_bg_power_gamma, AGC_INPUT_CHANNELS, vtb_ctrl_fixed_16_16},
    {agc_cmd_set_lc_bg_power_gamma, AGC_INPUT_CHANNELS, vtb_ctrl_fixed_16_16},
    {agc_cmd_get_lc_gamma_inc, AGC_INPUT_CHANNELS, vtb_ctrl_fixed_16_16},
    {agc_cmd_set_lc_gamma_inc, AGC_INPUT_CHANNELS, vtb_ctrl_fixed_16_16},
    {agc_cmd_get_lc_gamma_dec, AGC_INPUT_CHANNELS, vtb_ctrl_fixed_16_16},
    {agc_cmd_set_lc_gamma_dec, AGC_INPUT_CHANNELS, vtb_ctrl_fixed_16_16},
    {agc_cmd_get_lc_near_delta_far_act, AGC_INPUT_CHANNELS, vtb_ctrl_fixed_16_16},
    {agc_cmd_set_lc_near_delta_far_act, AGC_INPUT_CHANNELS, vtb_ctrl_fixed_16_16},
    {agc_cmd_get_lc_near_delta, AGC_INPUT_CHANNELS, vtb_ctrl_fixed_16_16},
    {agc_cmd_set_lc_near_delta, AGC_INPUT_CHANNELS, vtb_ctrl_fixed_16_16},
    {agc_cmd_get_lc_far_delta, AGC_INPUT_CHANNELS, vtb_ctrl_fixed_16_16},
    {agc_cmd_set_lc_far_delta, AGC_INPUT_CHANNELS, vtb_ctrl_fixed_16_16},
    {agc_cmd_get_lc_gain_max, AGC_INPUT_CHANNELS, vtb_ctrl_fixed_16_16},
    {agc_cmd_set_lc_gain_max, AGC_INPUT_CHANNELS, vtb_ctrl_fixed_16_16},
    {agc_cmd_get_lc_gain_dt, AGC_INPUT_CHANNELS, vtb_ctrl_fixed_16_16},
    {agc_cmd_set_lc_gain_dt, AGC_INPUT_CHANNELS, vtb_ctrl_fixed_16_16},
    {agc_cmd_get_lc_gain_silence, AGC_INPUT_CHANNELS, vtb_ctrl_fixed_16_16},
    {agc_cmd_set_lc_gain_silence, AGC_INPUT_CHANNELS, vtb_ctrl_fixed_16_16},
    {agc_cmd_get_lc_gain_min, AGC_INPUT_CHANNELS, vtb_ctrl_fixed_16_16},
    {agc_cmd_set_lc_gain_min, AGC_INPUT_CHANNELS, vtb_ctrl_fixed_16_16},
};
