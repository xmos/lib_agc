// Copyright (c) 2017-2021, XMOS Ltd, All rights reserved
#include "agc_control.h"

void agc_command_handler(chanend c_command, agc_state_t &agc_state){
    uint8_t cmd;
    c_command :> cmd;
    switch(cmd){
        case agc_cmd_get_gain:
            uint32_t vals[AGC_INPUT_CHANNELS];
            for(int i = 0; i < AGC_INPUT_CHANNELS; i ++) {
                vals[i] = (uint32_t)agc_get_ch_gain(agc_state, i);
            }
            vtb_control_handle_get_n_words(c_command, AGC_INPUT_CHANNELS, vals);
            break;
        case agc_cmd_set_gain:
            uint32_t intructions[2];
            vtb_control_handle_set_n_words(c_command, 2, intructions);
            if (intructions[1] < AGC_INPUT_CHANNELS) {
                agc_set_ch_gain(agc_state, intructions[1], intructions[0]);
            }
            break;
        case agc_cmd_get_max_gain:
            uint32_t vals[AGC_INPUT_CHANNELS];
            for(int i = 0; i < AGC_INPUT_CHANNELS; i ++) {
                vals[i] = (uint32_t)agc_get_ch_max_gain(agc_state, i);
            }
            vtb_control_handle_get_n_words(c_command, AGC_INPUT_CHANNELS, vals);
            break;
        case agc_cmd_set_max_gain:
            uint32_t intructions[2];
            vtb_control_handle_set_n_words(c_command, 2, intructions);
            if (intructions[1] < AGC_INPUT_CHANNELS) {
                agc_set_ch_max_gain(agc_state, intructions[1], intructions[0]);
            }
            break;
       case agc_cmd_get_min_gain:
            uint32_t vals[AGC_INPUT_CHANNELS];
            for(int i = 0; i < AGC_INPUT_CHANNELS; i ++) {
                vals[i] = (uint32_t)agc_get_ch_min_gain(agc_state, i);
            }
            vtb_control_handle_get_n_words(c_command, AGC_INPUT_CHANNELS, vals);
            break;
        case agc_cmd_set_min_gain:
            uint32_t intructions[2];
            vtb_control_handle_set_n_words(c_command, 2, intructions);
            if (intructions[1] < AGC_INPUT_CHANNELS) {
                agc_set_ch_min_gain(agc_state, intructions[1], intructions[0]);
            }
            break;

        case agc_cmd_get_adapt:
            uint32_t vals[AGC_INPUT_CHANNELS];
            for(int i = 0; i < AGC_INPUT_CHANNELS; i ++) {
                vals[i] = (uint32_t)agc_get_ch_adapt(agc_state, i);
            }
            vtb_control_handle_get_n_words(c_command, AGC_INPUT_CHANNELS, vals);
            break;
        case agc_cmd_set_adapt:
            uint32_t intructions[2];
            vtb_control_handle_set_n_words(c_command, 2, intructions);
            if (intructions[1] < AGC_INPUT_CHANNELS) {
                agc_set_ch_adapt(agc_state, intructions[1], intructions[0]);
            }
            break;
        case agc_cmd_get_adapt_on_vad:
            uint32_t vals[AGC_INPUT_CHANNELS];
            for(int i = 0; i < AGC_INPUT_CHANNELS; i ++) {
                vals[i] = (uint32_t)agc_get_ch_adapt_on_vad(agc_state, i);
            }
            vtb_control_handle_get_n_words(c_command, AGC_INPUT_CHANNELS, vals);
            break;
        case agc_cmd_set_adapt_on_vad:
            uint32_t intructions[2];
            vtb_control_handle_set_n_words(c_command, 2, intructions);
            if (intructions[1] < AGC_INPUT_CHANNELS) {
                agc_set_ch_adapt_on_vad(agc_state, intructions[1], intructions[0]);
            }
            break;
        case agc_cmd_get_soft_clipping:
            uint32_t vals[AGC_INPUT_CHANNELS];
            for(int i = 0; i < AGC_INPUT_CHANNELS; i ++) {
                vals[i] = (uint32_t)agc_get_ch_soft_clipping(agc_state, i);
            }
            vtb_control_handle_get_n_words(c_command, AGC_INPUT_CHANNELS, vals);
            break;
        case agc_cmd_set_soft_clipping:
            uint32_t intructions[2];
            vtb_control_handle_set_n_words(c_command, 2, intructions);
            if (intructions[1] < AGC_INPUT_CHANNELS) {
                agc_set_ch_soft_clipping(agc_state, intructions[1], intructions[0]);
            }
            break;

        case agc_cmd_get_lc_enabled:
            uint32_t vals[AGC_INPUT_CHANNELS];
            for(int i = 0; i < AGC_INPUT_CHANNELS; i ++) {
                vals[i] = (uint32_t)agc_get_ch_lc_enable(agc_state, i);
            }
            vtb_control_handle_get_n_words(c_command, AGC_INPUT_CHANNELS, vals);
            break;
        case agc_cmd_set_lc_enabled:
            uint32_t intructions[2];
            vtb_control_handle_set_n_words(c_command, 2, intructions);
            if (intructions[1] < AGC_INPUT_CHANNELS) {
                agc_set_ch_lc_enable(agc_state, intructions[1], intructions[0]);
            }
            break;
        case agc_cmd_get_desired_upper_threshold:
            uint32_t vals[AGC_INPUT_CHANNELS];
            for(int i = 0; i < AGC_INPUT_CHANNELS; i ++) {
                vals[i] = (uint32_t)agc_get_ch_upper_threshold(agc_state, i);
            }
            vtb_control_handle_get_n_words(c_command, AGC_INPUT_CHANNELS, vals);
            break;
        case agc_cmd_get_desired_lower_threshold:
            uint32_t vals[AGC_INPUT_CHANNELS];
            for(int i = 0; i < AGC_INPUT_CHANNELS; i ++) {
                vals[i] = (uint32_t)agc_get_ch_lower_threshold(agc_state, i);
            }
            vtb_control_handle_get_n_words(c_command, AGC_INPUT_CHANNELS, vals);
            break;
        case agc_cmd_set_desired_upper_threshold:
            uint32_t intructions[2];
            vtb_control_handle_set_n_words(c_command, 2, intructions);
            if (intructions[1] < AGC_INPUT_CHANNELS) {
                agc_set_ch_upper_threshold(agc_state, intructions[1], intructions[0]);
            }
            break;
        case agc_cmd_set_desired_lower_threshold:
            uint32_t intructions[2];
            vtb_control_handle_set_n_words(c_command, 2, intructions);
            if (intructions[1] < AGC_INPUT_CHANNELS) {
                agc_set_ch_lower_threshold(agc_state, intructions[1], intructions[0]);
            }
            break;
        case agc_cmd_get_gain_increment_stepsize:
            uint32_t vals[AGC_INPUT_CHANNELS];
            for(int i = 0; i < AGC_INPUT_CHANNELS; i ++) {
                vals[i] = (uint32_t)agc_get_ch_gain_inc(agc_state, i);
            }
            vtb_control_handle_get_n_words(c_command, AGC_INPUT_CHANNELS, vals);
            break;
        case agc_cmd_set_gain_increment_stepsize:
            uint32_t intructions[2];
            vtb_control_handle_set_n_words(c_command, 2, intructions);
            if (intructions[1] < AGC_INPUT_CHANNELS) {
                agc_set_ch_gain_inc(agc_state, intructions[1], intructions[0]);
            }
            break;
        case agc_cmd_get_gain_decrement_stepsize:
            uint32_t vals[AGC_INPUT_CHANNELS];
            for(int i = 0; i < AGC_INPUT_CHANNELS; i ++) {
                vals[i] = (uint32_t)agc_get_ch_gain_dec(agc_state, i);
            }
            vtb_control_handle_get_n_words(c_command, AGC_INPUT_CHANNELS, vals);
            break;
        case agc_cmd_set_gain_decrement_stepsize:
            uint32_t intructions[2];
            vtb_control_handle_set_n_words(c_command, 2, intructions);
            if (intructions[1] < AGC_INPUT_CHANNELS) {
                agc_set_ch_gain_dec(agc_state, intructions[1], intructions[0]);
            }
            break;

        case agc_cmd_get_lc_corr_threshold:
            uint32_t vals[AGC_INPUT_CHANNELS];
            for(int i = 0; i < AGC_INPUT_CHANNELS; i ++) {
                vals[i] = (uint32_t)agc_get_ch_lc_corr_threshold(agc_state, i);
            }
            vtb_control_handle_get_n_words(c_command, AGC_INPUT_CHANNELS, vals);
            break;

        case agc_cmd_set_lc_corr_threshold:
            uint32_t intructions[2];
            vtb_control_handle_set_n_words(c_command, 2, intructions);
            if (intructions[1] < AGC_INPUT_CHANNELS) {
                agc_set_ch_lc_corr_threshold(agc_state, intructions[1], intructions[0]);
            }
            break;

        case agc_cmd_get_lc_near_delta_far_act:
            uint32_t vals[AGC_INPUT_CHANNELS];
            for(int i = 0; i < AGC_INPUT_CHANNELS; i ++) {
                vals[i] = (uint32_t)agc_get_ch_lc_near_delta_far_act(agc_state, i);
            }
            vtb_control_handle_get_n_words(c_command, AGC_INPUT_CHANNELS, vals);
            break;

        case agc_cmd_set_lc_near_delta_far_act:
            uint32_t intructions[2];
            vtb_control_handle_set_n_words(c_command, 2, intructions);
            if (intructions[1] < AGC_INPUT_CHANNELS) {
                agc_set_ch_lc_near_delta_far_act(agc_state, intructions[1], intructions[0]);
            }
            break;

        case agc_cmd_get_lc_near_delta:
            uint32_t vals[AGC_INPUT_CHANNELS];
            for(int i = 0; i < AGC_INPUT_CHANNELS; i ++) {
                vals[i] = (uint32_t)agc_get_ch_lc_near_delta(agc_state, i);
            }
            vtb_control_handle_get_n_words(c_command, AGC_INPUT_CHANNELS, vals);
            break;

        case agc_cmd_set_lc_near_delta:
            uint32_t intructions[2];
            vtb_control_handle_set_n_words(c_command, 2, intructions);
            if (intructions[1] < AGC_INPUT_CHANNELS) {
                agc_set_ch_lc_near_delta(agc_state, intructions[1], intructions[0]);
            }
            break;

        case agc_cmd_get_lc_far_delta:
            uint32_t vals[AGC_INPUT_CHANNELS];
            for(int i = 0; i < AGC_INPUT_CHANNELS; i ++) {
                vals[i] = (uint32_t)agc_get_ch_lc_far_delta(agc_state, i);
            }
            vtb_control_handle_get_n_words(c_command, AGC_INPUT_CHANNELS, vals);
            break;

        case agc_cmd_set_lc_far_delta:
            uint32_t intructions[2];
            vtb_control_handle_set_n_words(c_command, 2, intructions);
            if (intructions[1] < AGC_INPUT_CHANNELS) {
                agc_set_ch_lc_far_delta(agc_state, intructions[1], intructions[0]);
            }
            break;
        case agc_cmd_get_lc_gain_max:
            uint32_t vals[AGC_INPUT_CHANNELS];
            for(int i = 0; i < AGC_INPUT_CHANNELS; i ++) {
                vals[i] = (uint32_t)agc_get_ch_lc_gain_max(agc_state, i);
            }
            vtb_control_handle_get_n_words(c_command, AGC_INPUT_CHANNELS, vals);
            break;

        case agc_cmd_set_lc_gain_max:
            uint32_t intructions[2];
            vtb_control_handle_set_n_words(c_command, 2, intructions);
            if (intructions[1] < AGC_INPUT_CHANNELS) {
                agc_set_ch_lc_gain_max(agc_state, intructions[1], intructions[0]);
            }
            break;
        case agc_cmd_get_lc_gain_dt:
            uint32_t vals[AGC_INPUT_CHANNELS];
            for(int i = 0; i < AGC_INPUT_CHANNELS; i ++) {
                vals[i] = (uint32_t)agc_get_ch_lc_gain_dt(agc_state, i);
            }
            vtb_control_handle_get_n_words(c_command, AGC_INPUT_CHANNELS, vals);
            break;

        case agc_cmd_set_lc_gain_dt:
            uint32_t intructions[2];
            vtb_control_handle_set_n_words(c_command, 2, intructions);
            if (intructions[1] < AGC_INPUT_CHANNELS) {
                agc_set_ch_lc_gain_dt(agc_state, intructions[1], intructions[0]);
            }
            break;
        case agc_cmd_get_lc_gain_silence:
            uint32_t vals[AGC_INPUT_CHANNELS];
            for(int i = 0; i < AGC_INPUT_CHANNELS; i ++) {
                vals[i] = (uint32_t)agc_get_ch_lc_gain_silence(agc_state, i);
            }
            vtb_control_handle_get_n_words(c_command, AGC_INPUT_CHANNELS, vals);
            break;

        case agc_cmd_set_lc_gain_silence:
            uint32_t intructions[2];
            vtb_control_handle_set_n_words(c_command, 2, intructions);
            if (intructions[1] < AGC_INPUT_CHANNELS) {
                agc_set_ch_lc_gain_silence(agc_state, intructions[1], intructions[0]);
            }
            break;
        case agc_cmd_get_lc_gain_min:
            uint32_t vals[AGC_INPUT_CHANNELS];
            for(int i = 0; i < AGC_INPUT_CHANNELS; i ++) {
                vals[i] = (uint32_t)agc_get_ch_lc_gain_min(agc_state, i);
            }
            vtb_control_handle_get_n_words(c_command, AGC_INPUT_CHANNELS, vals);
            break;

        case agc_cmd_set_lc_gain_min:
            uint32_t intructions[2];
            vtb_control_handle_set_n_words(c_command, 2, intructions);
            if (intructions[1] < AGC_INPUT_CHANNELS) {
                agc_set_ch_lc_gain_min(agc_state, intructions[1], intructions[0]);
            }
            break;

        default:
            c_command :> unsigned; // Receive payload length
            c_command <: 0;
            break;
    }
}
