// Copyright (c) 2019-2020, XMOS Ltd, All rights reserved
#include "agc_conf.h"
#include "agc_control_map.h"

unsigned agc_control_map[agc_num_commands][3] = {
    {agc_cmd_set_agc_gain,               AGC_INPUT_CHANNELS, vtb_ctrl_fixed_16_16},
    {agc_cmd_get_agc_gain,               AGC_INPUT_CHANNELS, vtb_ctrl_fixed_16_16},
    {agc_cmd_set_agc_max_gain,           AGC_INPUT_CHANNELS, vtb_ctrl_fixed_16_16},
    {agc_cmd_get_agc_max_gain,           AGC_INPUT_CHANNELS, vtb_ctrl_fixed_16_16},
    {agc_cmd_set_agc_adapt,              AGC_INPUT_CHANNELS, vtb_ctrl_uint32},
    {agc_cmd_get_agc_adapt,              AGC_INPUT_CHANNELS, vtb_ctrl_uint32},
    {agc_cmd_set_agc_lc_enabled,         AGC_INPUT_CHANNELS, vtb_ctrl_uint32},
    {agc_cmd_get_agc_lc_enabled,         AGC_INPUT_CHANNELS, vtb_ctrl_uint32},
    {agc_cmd_set_agc_desired_upper_threshold,      AGC_INPUT_CHANNELS, vtb_ctrl_fixed_1_31},
    {agc_cmd_set_agc_desired_lower_threshold,      AGC_INPUT_CHANNELS, vtb_ctrl_fixed_1_31},
    {agc_cmd_get_agc_desired_upper_threshold,      AGC_INPUT_CHANNELS, vtb_ctrl_fixed_1_31},
    {agc_cmd_get_agc_desired_lower_threshold,      AGC_INPUT_CHANNELS, vtb_ctrl_fixed_1_31},
    {agc_cmd_get_agc_gain_increment_stepsize, AGC_INPUT_CHANNELS, vtb_ctrl_fixed_16_16},
    {agc_cmd_get_agc_gain_decrement_stepsize, AGC_INPUT_CHANNELS, vtb_ctrl_fixed_16_16},
    {agc_cmd_set_agc_gain_increment_stepsize, AGC_INPUT_CHANNELS, vtb_ctrl_fixed_16_16},
    {agc_cmd_set_agc_gain_decrement_stepsize, AGC_INPUT_CHANNELS, vtb_ctrl_fixed_16_16},
};
