// Copyright (c) 2017-2018, XMOS Ltd, All rights reserved
#include "agc_unit_tests.h"

#define TEST_COUNT (1<<14)


void test_agc_init(){
    agc_state_t agc;
    agc_init(agc);

    for(unsigned i=0; i<AGC_CHANNELS; ++i){
        TEST_ASSERT_EQUAL_UINT32_MESSAGE(UQ16(AGC_GAIN[i]), vtb_denormalise_and_saturate_u32(agc.ch_state[i].gain, -16), "Incorrect channel gain");
    }
}

void test_agc_set_channel_gain_linear(){
    srand((unsigned) 2);

    for(unsigned i=0;i<TEST_COUNT;i++){
        uq16_16 expected_gain[AGC_CHANNELS] = {(uq16_16)rand(), (uq16_16)rand()};
        for(unsigned i=0; i<AGC_CHANNELS; ++i){
            if(expected_gain[i] == 0){
                expected_gain[i] = 1;
            }
        }

        agc_state_t agc;
        agc_init(agc);

        for(unsigned i=0; i<AGC_CHANNELS; ++i){
            agc_set_channel_gain_linear(agc, i, expected_gain[i]);
        }

        for(unsigned i=0; i<AGC_CHANNELS; ++i){
            uq16_16 actual_gain = agc_get_channel_gain_linear(agc, i);
            TEST_ASSERT_EQUAL_INT32_MESSAGE(expected_gain[i], actual_gain, "Incorrect channel gain");
        }
    }
}

void test_agc_set_channel_gain_zero(){
    uq16_16 set_gain = 0;

    agc_state_t agc;
    agc_init(agc);

    for(unsigned i=0; i<AGC_CHANNELS; ++i){
        agc_set_channel_gain_linear(agc, i, set_gain);
    }

    uq16_16 expected_gain = 0;
    for(unsigned i=0; i<AGC_CHANNELS; ++i){
        TEST_ASSERT_EQUAL_UINT32_MESSAGE(expected_gain, vtb_denormalise_and_saturate_u32(agc.ch_state[i].gain, 0), "Incorrect channel gain");
    }
}


void test_agc_process_frame(){
    srand((unsigned) 2);
    const int gain_range = 64;

    for(unsigned i=0;i<TEST_COUNT;i++){
        dsp_complex_t frame_in_out[AGC_CHANNEL_PAIRS][AGC_FRAME_ADVANCE];
        int32_t init_value = ((int32_t)rand()) >> 7;

        for(int ch_pair=0; ch_pair<AGC_CHANNEL_PAIRS; ++ch_pair){
            for(int i=0; i<AGC_FRAME_ADVANCE; ++i){
                frame_in_out[ch_pair][i].re = init_value;
                frame_in_out[ch_pair][i].im = init_value;
            }
        }

        agc_state_t agc;
        agc_init(agc);
        uint32_t gain =((uint32_t)rand()) % gain_range;

        for(unsigned i=0; i<AGC_CHANNELS; ++i){
            agc_set_channel_gain_linear(agc, i, UQ16((double)gain));
        }

        agc_process_frame(agc, frame_in_out);

        for(int ch_pair=0; ch_pair<AGC_CHANNEL_PAIRS; ++ch_pair){
            for(int i=0; i<AGC_FRAME_ADVANCE; ++i){
                TEST_ASSERT_INT32_WITHIN_MESSAGE(1<<16, gain * init_value, frame_in_out[ch_pair][i].re, "Incorrect output sample");
                TEST_ASSERT_INT32_WITHIN_MESSAGE(1<<16, gain * init_value, frame_in_out[ch_pair][i].im, "Incorrect output sample");
            }
        }
    }
}
