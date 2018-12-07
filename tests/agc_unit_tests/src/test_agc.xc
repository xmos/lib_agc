// Copyright (c) 2017-2018, XMOS Ltd, All rights reserved
#include "agc_unit_tests.h"

#define TEST_COUNT (1<<14)


void test_agc_init(){
    agc_state_t agc;
    agc_init(agc);

    for(unsigned i=0; i<AGC_CHANNELS; ++i){
        TEST_ASSERT_EQUAL_UINT32_MESSAGE(AGC_GAIN[i], vtb_denormalise_and_saturate_u32(agc.ch_state[i].gain, 0), "Incorrect channel gain");
    }
}

void test_agc_set_channel_gain(){
    srand((unsigned) 2);

    for(unsigned i=0;i<TEST_COUNT;i++){
        uint32_t expected_gain[AGC_CHANNELS] = {(uint32_t)rand(), (uint32_t)rand()};
        for(unsigned i=0; i<AGC_CHANNELS; ++i){
            if(expected_gain[i] == 0){
                expected_gain[i] = 1;
            }
        }

        agc_state_t agc;
        agc_init(agc);

        for(unsigned i=0; i<AGC_CHANNELS; ++i){
            agc_set_channel_gain(agc, i, expected_gain[i]);
        }

        for(unsigned i=0; i<AGC_CHANNELS; ++i){
            TEST_ASSERT_EQUAL_UINT32_MESSAGE(expected_gain[i], vtb_denormalise_and_saturate_u32(agc.ch_state[i].gain, 0), "Incorrect channel gain");
        }
    }
}

void test_agc_set_channel_gain_zero(){
    uint32_t set_gain = 0;

    agc_state_t agc;
    agc_init(agc);

    for(unsigned i=0; i<AGC_CHANNELS; ++i){
        agc_set_channel_gain(agc, i, set_gain);
    }

    uint32_t expected_gain = 1;
    for(unsigned i=0; i<AGC_CHANNELS; ++i){
        TEST_ASSERT_EQUAL_UINT32_MESSAGE(expected_gain, vtb_denormalise_and_saturate_u32(agc.ch_state[i].gain, 0), "Incorrect channel gain");
    }
}


void test_agc_process_frame(){
    int32_t test_vector[5] = {-1000, -1, 0, 1, 1000};
    for(int test_index=0; test_index<5; ++test_index){
        int32_t init_value = test_vector[test_index];
        dsp_complex_t frame_in_out[AGC_CHANNEL_PAIRS][AGC_FRAME_ADVANCE];
        for(int ch_pair=0; ch_pair<AGC_CHANNEL_PAIRS; ++ch_pair){
            for(int i=0; i<AGC_FRAME_ADVANCE; ++i){
                frame_in_out[ch_pair][i].re = init_value;
                frame_in_out[ch_pair][i].im = init_value;
            }
        }

        agc_state_t agc;
        agc_init(agc);
        agc_process_frame(agc, frame_in_out);

        for(int ch_pair=0; ch_pair<AGC_CHANNEL_PAIRS; ++ch_pair){
            for(int i=0; i<AGC_FRAME_ADVANCE; ++i){
                TEST_ASSERT_EQUAL_INT32_MESSAGE(AGC_GAIN[0] * init_value, frame_in_out[ch_pair][i].re, "Incorrect output sample");
                TEST_ASSERT_EQUAL_INT32_MESSAGE(AGC_GAIN[1] * init_value, frame_in_out[ch_pair][i].im, "Incorrect output sample");
            }
        }
    }
}
