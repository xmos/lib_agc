// Copyright 2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.
#include "agc_control.h"
#include "print.h"
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
        case agc_cmd_get_lc_n_frames:
            uint32_t vals[AGC_INPUT_CHANNELS*2];
            for(int i = 0; i < AGC_INPUT_CHANNELS; i ++) {
                { vals[2*i], vals[2*i+1] } = agc_get_ch_lc_n_frames(agc_state, i);
            }
            vtb_control_handle_get_n_words(c_command, AGC_INPUT_CHANNELS*2, vals);
            break;
        case agc_cmd_set_lc_n_frames:
            uint32_t instructions[3];
            vtb_control_handle_set_n_words(c_command, 3, instructions);
            if (instructions[2] < AGC_INPUT_CHANNELS) {
                uint32_t vals[2];
                vals[0] =  instructions[0];
                vals[1] =  instructions[1];

                agc_set_ch_lc_n_frames(agc_state, instructions[2], vals);
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

        case agc_cmd_get_lc_gammas:
            uint32_t vals[AGC_INPUT_CHANNELS*3];
            for(int i = 0; i < AGC_INPUT_CHANNELS; i ++) {
                { vals[3*i], vals[3*i+1], vals[3*i+2] } = agc_get_ch_lc_gammas(agc_state, i);
            }
            vtb_control_handle_get_n_words(c_command, AGC_INPUT_CHANNELS*3, vals);
            break;

        case agc_cmd_set_lc_gammas:
            uint32_t instructions[4];
            vtb_control_handle_set_n_words(c_command, 4, instructions);
            if (instructions[3] < AGC_INPUT_CHANNELS) {
                uint32_t vals[3];
                vals[0] =  instructions[0];
                vals[1] =  instructions[1];
                vals[2] =  instructions[2];

                agc_set_ch_lc_gammas(agc_state, instructions[3], vals);
            }
            break;

        case agc_cmd_get_lc_deltas:
            uint32_t vals[AGC_INPUT_CHANNELS*3];
            for(int i = 0; i < AGC_INPUT_CHANNELS; i ++) {
                { vals[3*i], vals[3*i+1], vals[3*i+2] } = agc_get_ch_lc_deltas(agc_state, i);
            }
            vtb_control_handle_get_n_words(c_command, AGC_INPUT_CHANNELS*3, vals);
            break;

        case agc_cmd_set_lc_deltas:
            uint32_t instructions[4];
            vtb_control_handle_set_n_words(c_command, 4, instructions);
            if (instructions[3] < AGC_INPUT_CHANNELS) {
                uint32_t vals[3];
                vals[0] =  instructions[0];
                vals[1] =  instructions[1];
                vals[2] =  instructions[2];

                agc_set_ch_lc_deltas(agc_state, instructions[3], vals);
            }
            break;


         case agc_cmd_get_lc_gains:
            uint32_t vals[AGC_INPUT_CHANNELS*4];
            for(int i = 0; i < AGC_INPUT_CHANNELS; i ++) {
                { vals[4*i], vals[4*i+1], vals[4*i+2], vals[4*i+3] } = agc_get_ch_lc_gains(agc_state, i);
            }
            vtb_control_handle_get_n_words(c_command, AGC_INPUT_CHANNELS*4, vals);
            break;

        case agc_cmd_set_lc_gains:
            uint32_t instructions[5];
            vtb_control_handle_set_n_words(c_command, 5, instructions);
            if (instructions[4] < AGC_INPUT_CHANNELS) {
                uint32_t vals[4];
                vals[0] =  instructions[0];
                vals[1] =  instructions[1];
                vals[2] =  instructions[2];
                vals[3] =  instructions[3];

                agc_set_ch_lc_gains(agc_state, instructions[4], vals);
            }
            break;

        default:
            c_command :> unsigned; // Receive payload length
            c_command <: 0;
            break;
    }
}
