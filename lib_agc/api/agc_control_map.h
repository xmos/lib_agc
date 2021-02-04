// Copyright (c) 2020-2021, XMOS Ltd, All rights reserved
#ifndef AGC_CONTROL_MAP_H_
#define AGC_CONTROL_MAP_H_
#include "vtb_control.h"

typedef enum {
    // get: MSB == 1
    agc_cmd_get_agc_gain = 0x80,
    agc_cmd_get_agc_max_gain,
    agc_cmd_get_agc_adapt,
    agc_cmd_get_agc_desired_upper_threshold,
    agc_cmd_get_agc_desired_lower_threshold,
    agc_cmd_get_agc_gain_increment_stepsize,
    agc_cmd_get_agc_gain_decrement_stepsize,
    agc_cmd_get_agc_lc_enabled,
    agc_cmd_get_agc_adapt_on_vad,
    agc_cmd_get_agc_soft_clipping,
    agc_cmd_get_agc_min_gain,
    agc_num_get_commands,

    // set: MSB == 0
    agc_cmd_set_agc_gain = 0,
    agc_cmd_set_agc_max_gain,
    agc_cmd_set_agc_adapt,
    agc_cmd_set_agc_desired_upper_threshold,
    agc_cmd_set_agc_desired_lower_threshold,
    agc_cmd_set_agc_gain_increment_stepsize,
    agc_cmd_set_agc_gain_decrement_stepsize,
    agc_cmd_set_agc_lc_enabled,
    agc_cmd_set_agc_adapt_on_vad,
    agc_cmd_set_agc_soft_clipping,
    agc_cmd_set_agc_min_gain,
    agc_num_set_commands,
} agc_control_commands;

#define agc_num_commands ((agc_num_get_commands - 0x80) + agc_num_set_commands)
extern unsigned agc_control_map[agc_num_commands][3];

#endif // agc_CONTROL_MAP_H
