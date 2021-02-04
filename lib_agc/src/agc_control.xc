// Copyright (c) 2017-2021, XMOS Ltd, All rights reserved
#include "agc_control.h"

void agc_command_handler(chanend c_command, agc_state_t &agc_state){
    uint8_t cmd;
    c_command :> cmd;
    switch(cmd){
        case agc_cmd_get_agc_gain:
            uint32_t vals[AGC_INPUT_CHANNELS];
            for(int i = 0; i < AGC_INPUT_CHANNELS; i ++) {
                vals[i] = (uint32_t)agc_get_ch_gain(agc_state, i);
            }
            vtb_control_handle_get_n_words(c_command, AGC_INPUT_CHANNELS, vals);
            break;
        case agc_cmd_set_agc_gain:
            uint32_t intructions[2];
            vtb_control_handle_set_n_words(c_command, 2, intructions);
            if (intructions[1] < AGC_INPUT_CHANNELS) {
                agc_set_ch_gain(agc_state, intructions[1], intructions[0]);
            }
            break;
        case agc_cmd_get_agc_max_gain:
            uint32_t vals[AGC_INPUT_CHANNELS];
            for(int i = 0; i < AGC_INPUT_CHANNELS; i ++) {
                vals[i] = (uint32_t)agc_get_ch_max_gain(agc_state, i);
            }
            vtb_control_handle_get_n_words(c_command, AGC_INPUT_CHANNELS, vals);
            break;
        case agc_cmd_set_agc_max_gain:
            uint32_t intructions[2];
            vtb_control_handle_set_n_words(c_command, 2, intructions);
            if (intructions[1] < AGC_INPUT_CHANNELS) {
                agc_set_ch_max_gain(agc_state, intructions[1], intructions[0]);
            }
            break;
        case agc_cmd_get_agc_adapt:
            uint32_t vals[AGC_INPUT_CHANNELS];
            for(int i = 0; i < AGC_INPUT_CHANNELS; i ++) {
                vals[i] = (uint32_t)agc_get_ch_adapt(agc_state, i);
            }
            vtb_control_handle_get_n_words(c_command, AGC_INPUT_CHANNELS, vals);
            break;
        case agc_cmd_set_agc_adapt:
            uint32_t intructions[2];
            vtb_control_handle_set_n_words(c_command, 2, intructions);
            if (intructions[1] < AGC_INPUT_CHANNELS) {
                agc_set_ch_adapt(agc_state, intructions[1], intructions[0]);
            }
            break;
        case agc_cmd_get_agc_lc_enabled:
            uint32_t vals[AGC_INPUT_CHANNELS];
            for(int i = 0; i < AGC_INPUT_CHANNELS; i ++) {
                vals[i] = (uint32_t)agc_get_ch_lc_enable(agc_state, i);
            }
            vtb_control_handle_get_n_words(c_command, AGC_INPUT_CHANNELS, vals);
            break;
        case agc_cmd_set_agc_lc_enabled:
            uint32_t intructions[2];
            vtb_control_handle_set_n_words(c_command, 2, intructions);
            if (intructions[1] < AGC_INPUT_CHANNELS) {
                agc_set_ch_lc_enable(agc_state, intructions[1], intructions[0]);
            }
            break;
        case agc_cmd_get_agc_desired_upper_threshold:
            uint32_t vals[AGC_INPUT_CHANNELS];
            for(int i = 0; i < AGC_INPUT_CHANNELS; i ++) {
                vals[i] = (uint32_t)agc_get_ch_upper_threshold(agc_state, i);
            }
            vtb_control_handle_get_n_words(c_command, AGC_INPUT_CHANNELS, vals);
            break;
        case agc_cmd_get_agc_desired_lower_threshold:
            uint32_t vals[AGC_INPUT_CHANNELS];
            for(int i = 0; i < AGC_INPUT_CHANNELS; i ++) {
                vals[i] = (uint32_t)agc_get_ch_lower_threshold(agc_state, i);
            }
            vtb_control_handle_get_n_words(c_command, AGC_INPUT_CHANNELS, vals);
            break;
        case agc_cmd_set_agc_desired_upper_threshold:
            uint32_t intructions[2];
            vtb_control_handle_set_n_words(c_command, 2, intructions);
            if (intructions[1] < AGC_INPUT_CHANNELS) {
                agc_set_ch_upper_threshold(agc_state, intructions[1], intructions[0]);
            }
            break;
        case agc_cmd_set_agc_desired_lower_threshold:
            uint32_t intructions[2];
            vtb_control_handle_set_n_words(c_command, 2, intructions);
            if (intructions[1] < AGC_INPUT_CHANNELS) {
                agc_set_ch_lower_threshold(agc_state, intructions[1], intructions[0]);
            }
            break;
        case agc_cmd_get_agc_gain_increment_stepsize:
            uint32_t vals[AGC_INPUT_CHANNELS];
            for(int i = 0; i < AGC_INPUT_CHANNELS; i ++) {
                vals[i] = (uint32_t)agc_get_ch_gain_inc(agc_state, i);
            }
            vtb_control_handle_get_n_words(c_command, AGC_INPUT_CHANNELS, vals);
            break;
        case agc_cmd_set_agc_gain_increment_stepsize:
            uint32_t intructions[2];
            vtb_control_handle_set_n_words(c_command, 2, intructions);
            if (intructions[1] < AGC_INPUT_CHANNELS) {
                agc_set_ch_gain_inc(agc_state, intructions[1], intructions[0]);
            }
            break;
        case agc_cmd_get_agc_gain_decrement_stepsize:
            uint32_t vals[AGC_INPUT_CHANNELS];
            for(int i = 0; i < AGC_INPUT_CHANNELS; i ++) {
                vals[i] = (uint32_t)agc_get_ch_gain_dec(agc_state, i);
            }
            vtb_control_handle_get_n_words(c_command, AGC_INPUT_CHANNELS, vals);
            break;
        case agc_cmd_set_agc_gain_decrement_stepsize:
            uint32_t intructions[2];
            vtb_control_handle_set_n_words(c_command, 2, intructions);
            if (intructions[1] < AGC_INPUT_CHANNELS) {
                agc_set_ch_gain_dec(agc_state, intructions[1], intructions[0]);
            }
            break;
        default:
            c_command :> unsigned; // Receive payload length
            c_command <: 0;
            break;
    }
}
