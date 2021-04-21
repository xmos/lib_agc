// Copyright 2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#ifndef AGC_CONTROL_MAP_H_
#define AGC_CONTROL_MAP_H_
#include "vtb_control.h"

#define LC_N_FRAMES_NUM 2
#define LC_GAMMAS_NUM 3
#define LC_DELTAS_NUM 3
#define LC_GAINS_NUM 4

typedef enum {
    // get: MSB == 1
    agc_cmd_get_gain = 0x80,
    agc_cmd_get_max_gain,
    agc_cmd_get_adapt,
    agc_cmd_get_desired_upper_threshold,
    agc_cmd_get_desired_lower_threshold,
    agc_cmd_get_gain_increment_stepsize,
    agc_cmd_get_gain_decrement_stepsize,
    agc_cmd_get_lc_enabled,
    agc_cmd_get_adapt_on_vad,
    agc_cmd_get_soft_clipping,
    agc_cmd_get_min_gain,
    agc_cmd_get_lc_n_frames,
    agc_cmd_get_lc_corr_threshold,
    agc_cmd_get_lc_deltas,
    agc_cmd_get_lc_gains,
    agc_cmd_get_lc_gammas,
    agc_num_get_commands,

    // set: MSB == 0
    agc_cmd_set_gain = 0,
    agc_cmd_set_max_gain,
    agc_cmd_set_adapt,
    agc_cmd_set_desired_upper_threshold,
    agc_cmd_set_desired_lower_threshold,
    agc_cmd_set_gain_increment_stepsize,
    agc_cmd_set_gain_decrement_stepsize,
    agc_cmd_set_lc_enabled,
    agc_cmd_set_adapt_on_vad,
    agc_cmd_set_soft_clipping,
    agc_cmd_set_min_gain,
    agc_cmd_set_lc_n_frames,
    agc_cmd_set_lc_corr_threshold,
    agc_cmd_set_lc_deltas,
    agc_cmd_set_lc_gains,
    agc_cmd_set_lc_gammas,
    agc_num_set_commands,
} agc_control_commands;

#define agc_num_commands ((agc_num_get_commands - 0x80) + agc_num_set_commands)
extern unsigned agc_control_map[agc_num_commands][3];

#endif // agc_CONTROL_MAP_H
