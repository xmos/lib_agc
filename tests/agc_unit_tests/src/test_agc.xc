// Copyright (c) 2017-2019, XMOS Ltd, All rights reserved
#include "agc_unit_tests.h"

#define TEST_COUNT (1<<14)

void test_agc_init(){
    int expected_adapt[AGC_INPUT_CHANNELS] = {AGC_CH0_ADAPT, AGC_CH1_ADAPT};
    vtb_uq16_16_t expected_init_gain[AGC_INPUT_CHANNELS] = {VTB_UQ16_16(AGC_CH0_GAIN), VTB_UQ16_16(AGC_CH1_GAIN)};
    vtb_uq16_16_t expected_max_gain[AGC_INPUT_CHANNELS] = {VTB_UQ16_16(AGC_CH0_MAX_GAIN), VTB_UQ16_16(AGC_CH1_MAX_GAIN)};
    uint32_t expected_desired_level[AGC_INPUT_CHANNELS] = {AGC_CH0_DESIRED_LEVEL, AGC_CH1_DESIRED_LEVEL};

    agc_state_t agc;
    agc_config_t config[AGC_INPUT_CHANNELS] = {
        {
            expected_adapt[0],
            expected_init_gain[0],
            expected_max_gain[0],
            expected_desired_level[0],
        },
        {
            expected_adapt[1],
            expected_init_gain[1],
            expected_max_gain[1],
            expected_desired_level[1],
        }
    };

    agc_init(agc, config);

    for(unsigned i=0; i<AGC_INPUT_CHANNELS; ++i){
        TEST_ASSERT_EQUAL_INT_MESSAGE(expected_adapt[i], agc.ch_state[i].adapt, "Incorrect adapt flag");
        TEST_ASSERT_EQUAL_UINT32_MESSAGE(expected_init_gain[i], vtb_denormalise_and_saturate_u32(agc.ch_state[i].gain, -16), "Incorrect init gain");
        TEST_ASSERT_EQUAL_UINT32_MESSAGE(expected_max_gain[i], vtb_denormalise_and_saturate_u32(agc.ch_state[i].max_gain, -16), "Incorrect max gain");
        TEST_ASSERT_EQUAL_UINT32_MESSAGE(expected_desired_level[i], vtb_denormalise_and_saturate_u32(agc.ch_state[i].desired_level, 0), "Incorrect desired level");

        TEST_ASSERT_EQUAL_UINT32_MESSAGE(AGC_GAIN_INC, vtb_denormalise_and_saturate_u32(agc.ch_state[i].gain_inc, -16), "Incorrect gain inc");
        TEST_ASSERT_EQUAL_UINT32_MESSAGE(AGC_GAIN_DEC, vtb_denormalise_and_saturate_u32(agc.ch_state[i].gain_dec, -16), "Incorrect gain inc");

    }
}

void test_agc_set_channel_gain(){
    srand((unsigned) 2);

    agc_config_t config[AGC_INPUT_CHANNELS] = {
        {
            AGC_CH0_ADAPT,
            VTB_UQ16_16(AGC_CH0_GAIN),
            VTB_UQ16_16(AGC_CH0_MAX_GAIN),
            AGC_CH0_DESIRED_LEVEL,
        },
        {
            AGC_CH1_ADAPT,
            VTB_UQ16_16(AGC_CH1_GAIN),
            VTB_UQ16_16(AGC_CH1_MAX_GAIN),
            AGC_CH1_DESIRED_LEVEL,
        }
    };

    for(unsigned i=0;i<TEST_COUNT;i++){
        vtb_uq16_16_t expected_gain[AGC_INPUT_CHANNELS] = {(vtb_uq16_16_t)rand(), (vtb_uq16_16_t)rand()};
        for(unsigned i=0; i<AGC_INPUT_CHANNELS; ++i){
            if(expected_gain[i] == 0){
                expected_gain[i] = 1;
            }
        }

        agc_state_t agc;
        agc_init(agc, config);

        for(unsigned i=0; i<AGC_INPUT_CHANNELS; ++i){
            agc_set_channel_gain(agc, i, expected_gain[i]);
        }

        for(unsigned i=0; i<AGC_INPUT_CHANNELS; ++i){
            vtb_uq16_16_t actual_gain = agc_get_channel_gain(agc, i);
            TEST_ASSERT_EQUAL_INT32_MESSAGE(expected_gain[i], actual_gain, "Incorrect channel gain");
        }
    }
}

void test_agc_set_channel_gain_zero(){
    vtb_uq16_16_t expected_gain = 0;

    agc_config_t config[AGC_INPUT_CHANNELS] = {
        {
            AGC_CH0_ADAPT,
            VTB_UQ16_16(AGC_CH0_GAIN),
            VTB_UQ16_16(AGC_CH0_MAX_GAIN),
            AGC_CH0_DESIRED_LEVEL,
        },
        {
            AGC_CH1_ADAPT,
            VTB_UQ16_16(AGC_CH1_GAIN),
            VTB_UQ16_16(AGC_CH1_MAX_GAIN),
            AGC_CH1_DESIRED_LEVEL,
        }
    };

    agc_state_t agc;
    agc_init(agc, config);

    for(unsigned i=0; i<AGC_INPUT_CHANNELS; ++i){
        agc_set_channel_gain(agc, i, expected_gain);
    }

    for(unsigned i=0; i<AGC_INPUT_CHANNELS; ++i){
        TEST_ASSERT_EQUAL_UINT32_MESSAGE(expected_gain, vtb_denormalise_and_saturate_u32(agc.ch_state[i].gain, 0), "Incorrect channel gain");
    }
}


void test_agc_process_frame(){
    srand((unsigned) 2);
    const int gain_range = 64;

    agc_config_t config[AGC_INPUT_CHANNELS] = {
        {
            0,
            VTB_UQ16_16(AGC_CH0_GAIN),
            VTB_UQ16_16(AGC_CH0_MAX_GAIN),
            AGC_CH0_DESIRED_LEVEL,
        },
        {
            0,
            VTB_UQ16_16(AGC_CH1_GAIN),
            VTB_UQ16_16(AGC_CH1_MAX_GAIN),
            AGC_CH1_DESIRED_LEVEL,
        }
    };

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
        agc_init(agc, config);
        uint32_t gain =((uint32_t)rand()) % gain_range;

        for(unsigned i=0; i<AGC_INPUT_CHANNELS; ++i){
            agc_set_channel_gain(agc, i, VTB_UQ16_16((double)gain));
        }
        int vad = 1;
        agc_process_frame(agc, frame_in_out, vad);

        for(int ch_pair=0; ch_pair<AGC_CHANNEL_PAIRS; ++ch_pair){
            for(int i=0; i<AGC_FRAME_ADVANCE; ++i){
                TEST_ASSERT_INT32_WITHIN_MESSAGE(1<<16, gain * init_value, frame_in_out[ch_pair][i].re, "Incorrect output sample");
                TEST_ASSERT_INT32_WITHIN_MESSAGE(1<<16, gain * init_value, frame_in_out[ch_pair][i].im, "Incorrect output sample");
            }
        }
    }
}
