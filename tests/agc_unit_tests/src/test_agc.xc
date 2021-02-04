// Copyright (c) 2017-2021, XMOS Ltd, All rights reserved
#include "agc_unit_tests.h"

#define TEST_COUNT (1<<10)

void test_agc_init(){
    int expected_adapt[AGC_INPUT_CHANNELS] = {AGC_CH0_ADAPT, AGC_CH1_ADAPT};
    int expected_adapt_on_vad[AGC_INPUT_CHANNELS] = {AGC_CH0_ADAPT_ON_VAD, AGC_CH1_ADAPT_ON_VAD};
    int expected_soft_clipping[AGC_INPUT_CHANNELS] = {AGC_CH0_SOFT_CLIPPING, AGC_CH1_SOFT_CLIPPING};

    vtb_uq16_16_t expected_init_gain[AGC_INPUT_CHANNELS] = {VTB_UQ16_16(AGC_CH0_GAIN), VTB_UQ16_16(AGC_CH1_GAIN)};
    vtb_uq16_16_t expected_max_gain[AGC_INPUT_CHANNELS] = {VTB_UQ16_16(AGC_CH0_MAX_GAIN), VTB_UQ16_16(AGC_CH1_MAX_GAIN)};
    vtb_uq16_16_t expected_min_gain[AGC_INPUT_CHANNELS] = {VTB_UQ16_16(AGC_CH0_MIN_GAIN), VTB_UQ16_16(AGC_CH1_MIN_GAIN)};

    uint32_t expected_upper_threshold[AGC_INPUT_CHANNELS] = {VTB_UQ1_31(AGC_CH0_UPPER_THRESHOLD), VTB_UQ1_31(AGC_CH1_UPPER_THRESHOLD)};
    uint32_t expected_lower_threshold[AGC_INPUT_CHANNELS] = {VTB_UQ1_31(AGC_CH0_LOWER_THRESHOLD), VTB_UQ1_31(AGC_CH1_LOWER_THRESHOLD)};
    vtb_uq16_16_t expected_gain_inc[AGC_INPUT_CHANNELS] = {VTB_UQ16_16(AGC_CH0_GAIN_INC), VTB_UQ16_16(AGC_CH1_GAIN_INC)};
    vtb_uq16_16_t expected_gain_dec[AGC_INPUT_CHANNELS] = {VTB_UQ16_16(AGC_CH0_GAIN_DEC), VTB_UQ16_16(AGC_CH1_GAIN_DEC)};
    int expected_lc_enabled[AGC_INPUT_CHANNELS] = {AGC_CH0_LC_ENABLED, AGC_CH1_LC_ENABLED};

    agc_state_t agc;
    agc_init_config_t config = {
        {
            {
                expected_adapt[0],
                expected_adapt_on_vad[0],
                expected_soft_clipping[0],
                expected_init_gain[0],
                expected_max_gain[0],
                expected_min_gain[0],
                expected_upper_threshold[0],
                expected_lower_threshold[0],
                expected_gain_inc[0],
                expected_gain_dec[0],
                expected_lc_enabled[0]
            },
            {
                expected_adapt[1],
                expected_adapt_on_vad[1],
                expected_soft_clipping[1],
                expected_init_gain[1],
                expected_max_gain[1],
                expected_min_gain[1],
                expected_upper_threshold[1],
                expected_lower_threshold[1],
                expected_gain_inc[1],
                expected_gain_dec[1],
                expected_lc_enabled[1]
            }
        }
    };

    agc_init(agc, config);

    for(unsigned ch = 0; ch < AGC_INPUT_CHANNELS; ++ch){
        TEST_ASSERT_EQUAL_INT_MESSAGE(expected_adapt[ch], agc.ch_state[ch].adapt, "Incorrect adapt flag");
        TEST_ASSERT_EQUAL_INT_MESSAGE(expected_adapt_on_vad[ch], agc.ch_state[ch].adapt_on_vad, "Incorrect adapt on vad flag");
        TEST_ASSERT_EQUAL_INT_MESSAGE(expected_soft_clipping[ch], agc.ch_state[ch].soft_clipping, "Incorrect soft clipping flag");

        TEST_ASSERT_EQUAL_UINT32_MESSAGE(expected_init_gain[ch], vtb_denormalise_and_saturate_u32(agc.ch_state[ch].gain, -16), "Incorrect init gain");
        TEST_ASSERT_EQUAL_UINT32_MESSAGE(expected_max_gain[ch], vtb_denormalise_and_saturate_u32(agc.ch_state[ch].max_gain, -16), "Incorrect max gain");
        TEST_ASSERT_EQUAL_UINT32_MESSAGE(expected_min_gain[ch], vtb_denormalise_and_saturate_u32(agc.ch_state[ch].min_gain, -16), "Incorrect min gain");

        TEST_ASSERT_EQUAL_UINT32_MESSAGE(expected_upper_threshold[ch], vtb_denormalise_and_saturate_u32(agc.ch_state[ch].upper_threshold, 0), "Incorrect threshold upper");
        TEST_ASSERT_EQUAL_UINT32_MESSAGE(expected_lower_threshold[ch], vtb_denormalise_and_saturate_u32(agc.ch_state[ch].lower_threshold, 0), "Incorrect threshold lower");

        vtb_u32_float_t vtb_float_u32_zero = VTB_FLOAT_U32_ZERO;
        TEST_ASSERT_EQUAL_UINT32_MESSAGE(vtb_float_u32_zero.m, agc.ch_state[ch].x_slow.m, "Incorrect x_slow m");
        TEST_ASSERT_EQUAL_INT32_MESSAGE(vtb_float_u32_zero.e, agc.ch_state[ch].x_slow.e, "Incorrect x_slow e");
        TEST_ASSERT_EQUAL_UINT32_MESSAGE(vtb_float_u32_zero.m, agc.ch_state[ch].x_fast.m, "Incorrect x_fast m");
        TEST_ASSERT_EQUAL_INT32_MESSAGE(vtb_float_u32_zero.e, agc.ch_state[ch].x_fast.e, "Incorrect x_fast e");
        TEST_ASSERT_EQUAL_UINT32_MESSAGE(vtb_float_u32_zero.m, agc.ch_state[ch].x_peak.m, "Incorrect x_peak m");
        TEST_ASSERT_EQUAL_INT32_MESSAGE(vtb_float_u32_zero.e, agc.ch_state[ch].x_peak.e, "Incorrect x_peak e");

        TEST_ASSERT_EQUAL_UINT32_MESSAGE(expected_gain_inc[ch], vtb_denormalise_and_saturate_u32(agc.ch_state[ch].gain_inc, -16), "Incorrect gain inc");
        TEST_ASSERT_EQUAL_UINT32_MESSAGE(expected_gain_dec[ch], vtb_denormalise_and_saturate_u32(agc.ch_state[ch].gain_dec, -16), "Incorrect gain inc");
    }
}

void test_agc_set_get_ch_adapt(){
    srand((unsigned) 2);

    agc_init_config_t config;
    memset(&config, 0xFF, sizeof(agc_init_config_t));

    agc_state_t agc;
    agc_init(agc, config);


    uint32_t expected_adapt = 0;
    for(unsigned i=0; i<AGC_INPUT_CHANNELS; ++i){
        agc_set_ch_adapt(agc, i, expected_adapt);
    }

    for(unsigned i=0; i<AGC_INPUT_CHANNELS; ++i){
        TEST_ASSERT_EQUAL_INT32_MESSAGE(expected_adapt, agc_get_ch_adapt(agc, i), "Incorrect AGC adapt");
    }

    expected_adapt = 1;
    for(unsigned i=0; i<AGC_INPUT_CHANNELS; ++i){
        agc_set_ch_adapt(agc, i, expected_adapt);
    }

    for(unsigned i=0; i<AGC_INPUT_CHANNELS; ++i){
        TEST_ASSERT_EQUAL_INT32_MESSAGE(expected_adapt, agc_get_ch_adapt(agc, i), "Incorrect AGC adapt");
    }
}

void test_agc_set_get_ch_adapt_on_vad(){
    srand((unsigned) 2);

    agc_init_config_t config;
    memset(&config, 0xFF, sizeof(agc_init_config_t));

    agc_state_t agc;
    agc_init(agc, config);


    uint32_t expected_adapt_on_vad = 0;
    for(unsigned i=0; i<AGC_INPUT_CHANNELS; ++i){
        agc_set_ch_adapt_on_vad(agc, i, expected_adapt_on_vad);
    }

    for(unsigned i=0; i<AGC_INPUT_CHANNELS; ++i){
        TEST_ASSERT_EQUAL_INT32_MESSAGE(expected_adapt_on_vad, agc_get_ch_adapt_on_vad(agc, i), "Incorrect AGC adapt on vad");
    }

    expected_adapt_on_vad = 1;
    for(unsigned i=0; i<AGC_INPUT_CHANNELS; ++i){
        agc_set_ch_adapt_on_vad(agc, i, expected_adapt_on_vad);
    }

    for(unsigned i=0; i<AGC_INPUT_CHANNELS; ++i){
        TEST_ASSERT_EQUAL_INT32_MESSAGE(expected_adapt_on_vad, agc_get_ch_adapt_on_vad(agc, i), "Incorrect AGC adapt on vad");
    }
}

void test_agc_set_get_ch_soft_clipping(){
    srand((unsigned) 2);

    agc_init_config_t config;
    memset(&config, 0xFF, sizeof(agc_init_config_t));

    agc_state_t agc;
    agc_init(agc, config);


    uint32_t expected_soft_clipping = 0;
    for(unsigned i=0; i<AGC_INPUT_CHANNELS; ++i){
        agc_set_ch_soft_clipping(agc, i, expected_soft_clipping);
    }

    for(unsigned i=0; i<AGC_INPUT_CHANNELS; ++i){
        TEST_ASSERT_EQUAL_INT32_MESSAGE(expected_soft_clipping, agc_get_ch_soft_clipping(agc, i), "Incorrect AGC soft clipping");
    }

    expected_soft_clipping = 1;
    for(unsigned i=0; i<AGC_INPUT_CHANNELS; ++i){
        agc_set_ch_soft_clipping(agc, i, expected_soft_clipping);
    }

    for(unsigned i=0; i<AGC_INPUT_CHANNELS; ++i){
        TEST_ASSERT_EQUAL_INT32_MESSAGE(expected_soft_clipping, agc_get_ch_soft_clipping(agc, i), "Incorrect AGC soft clipping");
    }
}

void test_agc_set_get_lc_enable(){
    srand((unsigned) 2);

    agc_init_config_t config;
    memset(&config, 0xFF, sizeof(agc_init_config_t));

    agc_state_t agc;
    agc_init(agc, config);


    uint32_t expected_lc_enabled = 0;
    for(unsigned i=0; i<AGC_INPUT_CHANNELS; ++i){
        agc_set_ch_lc_enable(agc, i, expected_lc_enabled);
    }

    for(unsigned i=0; i<AGC_INPUT_CHANNELS; ++i){
        TEST_ASSERT_EQUAL_INT32_MESSAGE(expected_lc_enabled, agc_get_ch_lc_enable(agc, i), "Incorrect AGC LC enabled");
    }

    expected_lc_enabled = 1;
    for(unsigned i=0; i<AGC_INPUT_CHANNELS; ++i){
        agc_set_ch_lc_enable(agc, i, expected_lc_enabled);
    }

    for(unsigned i=0; i<AGC_INPUT_CHANNELS; ++i){
        TEST_ASSERT_EQUAL_INT32_MESSAGE(expected_lc_enabled, agc_get_ch_lc_enable(agc, i), "Incorrect AGC LC enabled");
    }
}


void test_agc_set_get_ch_gain(){
    srand((unsigned) 2);

    agc_init_config_t config;
    memset(&config, 0xFF, sizeof(agc_init_config_t));

    for(unsigned i=0;i<TEST_COUNT;i++){
        vtb_uq16_16_t expected_gain[AGC_INPUT_CHANNELS];
        for(unsigned i=0; i<AGC_INPUT_CHANNELS; ++i){
            expected_gain[i] = ((vtb_uq16_16_t)rand() << 16);
            if(expected_gain[i] == 0){
                expected_gain[i] = 1;
            }
            expected_gain[i] += ((uint16_t)rand());
        }

        agc_state_t agc;
        agc_init(agc, config);

        for(unsigned i=0; i<AGC_INPUT_CHANNELS; ++i){
            agc_set_ch_gain(agc, i, expected_gain[i]);
        }

        for(unsigned i=0; i<AGC_INPUT_CHANNELS; ++i){
            vtb_uq16_16_t actual_gain = agc_get_ch_gain(agc, i);
            TEST_ASSERT_EQUAL_INT32_MESSAGE(expected_gain[i], actual_gain, "Incorrect channel gain");
        }
    }
}


void test_agc_set_get_ch_gain_inc(){
    srand((unsigned) 2);
    vtb_uq16_16_t initial_gain_inc[AGC_INPUT_CHANNELS] = {VTB_UQ16_16(AGC_CH0_GAIN_INC), VTB_UQ16_16(AGC_CH1_GAIN_INC)};

    agc_init_config_t config;
    memset(&config, 0xFF, sizeof(agc_init_config_t));
    config.ch_init_config[0].gain_inc = initial_gain_inc[0];
    config.ch_init_config[1].gain_inc = initial_gain_inc[1];

    for(unsigned i=0;i<TEST_COUNT;i++){
        vtb_uq16_16_t expected_gain_inc[AGC_INPUT_CHANNELS];
        for(unsigned i=0; i<AGC_INPUT_CHANNELS; ++i){
            expected_gain_inc[i] = ((vtb_uq16_16_t)rand() << 16);
            expected_gain_inc[i] += ((uint16_t)rand());
        }

        agc_state_t agc;
        agc_init(agc, config);

        for(unsigned i=0; i<AGC_INPUT_CHANNELS; ++i){
            agc_set_ch_gain_inc(agc, i, expected_gain_inc[i]);
        }

        for(unsigned i=0; i<AGC_INPUT_CHANNELS; ++i){
            vtb_uq16_16_t actual_gain = agc_get_ch_gain_inc(agc, i);
            if(expected_gain_inc[i] >> 16){
                TEST_ASSERT_EQUAL_INT32_MESSAGE(expected_gain_inc[i], actual_gain, "Incorrect channel gain_inc");
            }
            else {
                TEST_ASSERT_EQUAL_INT32_MESSAGE(initial_gain_inc[i], actual_gain, "Incorrect channel gain_inc");
            }
        }
    }
}


void test_agc_set_get_ch_gain_dec(){
    srand((unsigned) 2);
    vtb_uq16_16_t initial_gain_dec[AGC_INPUT_CHANNELS] = {VTB_UQ16_16(AGC_CH0_GAIN_DEC), VTB_UQ16_16(AGC_CH1_GAIN_DEC)};

    agc_init_config_t config;
    memset(&config, 0xFF, sizeof(agc_init_config_t));
    config.ch_init_config[0].gain_dec = initial_gain_dec[0];
    config.ch_init_config[1].gain_dec = initial_gain_dec[1];

    for(unsigned i=0;i<TEST_COUNT;i++){
        vtb_uq16_16_t expected_gain_dec[AGC_INPUT_CHANNELS];
        for(unsigned i=0; i<AGC_INPUT_CHANNELS; ++i){
            expected_gain_dec[i] = ((vtb_uq16_16_t)rand() << 16);
            expected_gain_dec[i] += ((uint16_t)rand());
        }

        agc_state_t agc;
        agc_init(agc, config);

        for(unsigned i=0; i<AGC_INPUT_CHANNELS; ++i){
            agc_set_ch_gain_dec(agc, i, expected_gain_dec[i]);
        }

        for(unsigned i=0; i<AGC_INPUT_CHANNELS; ++i){
            vtb_uq16_16_t actual_gain = agc_get_ch_gain_dec(agc, i);
            if(expected_gain_dec[i] >> 16){
                TEST_ASSERT_EQUAL_INT32_MESSAGE(initial_gain_dec[i], actual_gain, "Incorrect channel gain_dec");
            }
            else {
                TEST_ASSERT_EQUAL_INT32_MESSAGE(expected_gain_dec[i], actual_gain, "Incorrect channel gain_dec");
            }
        }
    }
}



void test_agc_set_get_ch_max_gain(){
    srand((unsigned) 1);

    agc_init_config_t config;
    memset(&config, 0xFF, sizeof(agc_init_config_t));

    for(unsigned i=0;i<TEST_COUNT;i++){
        vtb_uq16_16_t expected_max_gain[AGC_INPUT_CHANNELS];
        for(unsigned i=0; i<AGC_INPUT_CHANNELS; ++i){
            expected_max_gain[i] = ((vtb_uq16_16_t)rand() << 16);
            if(expected_max_gain[i] == 0){
                expected_max_gain[i] = 1;
            }
            expected_max_gain[i] += ((uint16_t)rand());
        }

        agc_state_t agc;
        agc_init(agc, config);

        for(unsigned i=0; i<AGC_INPUT_CHANNELS; ++i){
            agc_set_ch_max_gain(agc, i, expected_max_gain[i]);
        }

        for(unsigned i=0; i<AGC_INPUT_CHANNELS; ++i){
            vtb_uq16_16_t actual_max_gain = agc_get_ch_max_gain(agc, i);
            TEST_ASSERT_EQUAL_INT32_MESSAGE(expected_max_gain[i], actual_max_gain, "Incorrect channel max gain");
        }
    }
}


void test_agc_set_get_ch_min_gain(){
    srand((unsigned) 1);

    agc_init_config_t config;
    memset(&config, 0xFF, sizeof(agc_init_config_t));

    for(unsigned i=0;i<TEST_COUNT;i++){
        vtb_uq16_16_t expected_min_gain[AGC_INPUT_CHANNELS];
        for(unsigned i=0; i<AGC_INPUT_CHANNELS; ++i){
            expected_min_gain[i] = ((vtb_uq16_16_t)rand() << 16);
            if(expected_min_gain[i] == 0){
                expected_min_gain[i] = 1;
            }
            expected_min_gain[i] += ((uint16_t)rand());
        }

        agc_state_t agc;
        agc_init(agc, config);

        for(unsigned i=0; i<AGC_INPUT_CHANNELS; ++i){
            agc_set_ch_min_gain(agc, i, expected_min_gain[i]);
        }

        for(unsigned i=0; i<AGC_INPUT_CHANNELS; ++i){
            vtb_uq16_16_t actual_min_gain = agc_get_ch_min_gain(agc, i);
            TEST_ASSERT_EQUAL_INT32_MESSAGE(expected_min_gain[i], actual_min_gain, "Incorrect channel min gain");
        }
    }
}


void test_agc_set_get_ch_upper_threshold(){
    srand((unsigned) 1);

    agc_init_config_t config;
    memset(&config, 0xFF, sizeof(agc_init_config_t));

    for(unsigned i=0;i<TEST_COUNT;i++){
        int32_t upper_thresholds[AGC_INPUT_CHANNELS];
        for(unsigned i=0; i<AGC_INPUT_CHANNELS; ++i){
            upper_thresholds[i] = ((int32_t)rand() << 16);
            if(upper_thresholds[i] == 0){
                upper_thresholds[i] = 1;
            }
            upper_thresholds[i] += ((uint16_t)rand());
        }

        agc_state_t agc;
        agc_init(agc, config);

        for(unsigned i=0; i<AGC_INPUT_CHANNELS; ++i){
            agc_set_ch_upper_threshold(agc, i, upper_thresholds[i]);
        }

        for(unsigned i=0; i<AGC_INPUT_CHANNELS; ++i){
            int32_t actual = agc_get_ch_upper_threshold(agc, i);

            int32_t expected = abs(upper_thresholds[i]);
            if (expected < config.ch_init_config[i].lower_threshold){
                expected = config.ch_init_config[i].lower_threshold;
            }

            TEST_ASSERT_EQUAL_INT32_MESSAGE(expected, actual, "Incorrect upper threshold");
        }
    }
}


void test_agc_set_get_ch_lower_threshold(){
    srand((unsigned) 1);

    agc_init_config_t config;
    memset(&config, 0xFF, sizeof(agc_init_config_t));

    for(unsigned i=0;i<TEST_COUNT;i++){
        int32_t lower_threshold[AGC_INPUT_CHANNELS];
        for(unsigned i=0; i<AGC_INPUT_CHANNELS; ++i){
            lower_threshold[i] = ((int32_t)rand() << 16);
            if(lower_threshold[i] == 0){
                lower_threshold[i] = 1;
            }
            lower_threshold[i] += ((uint16_t)rand());
        }

        agc_state_t agc;
        agc_init(agc, config);

        for(unsigned i=0; i<AGC_INPUT_CHANNELS; ++i){
            agc_set_ch_lower_threshold(agc, i, lower_threshold[i]);
        }

        for(unsigned i=0; i<AGC_INPUT_CHANNELS; ++i){
            int32_t actual = agc_get_ch_lower_threshold(agc, i);

            int32_t expected = abs(lower_threshold[i]);
            if (expected > config.ch_init_config[i].upper_threshold){
                expected = config.ch_init_config[i].upper_threshold;
            }

            TEST_ASSERT_EQUAL_INT32_MESSAGE(expected, actual, "Incorrect upper threshold");
        }
    }
}



void test_agc_set_get_ch_gain_zero(){
    vtb_uq16_16_t expected_gain = 0;

    agc_init_config_t config;
    memset(&config, 0xFF, sizeof(agc_init_config_t));

    agc_state_t agc;
    agc_init(agc, config);

    for(unsigned i=0; i<AGC_INPUT_CHANNELS; ++i){
        agc_set_ch_gain(agc, i, expected_gain);
    }

    for(unsigned i=0; i<AGC_INPUT_CHANNELS; ++i){
        TEST_ASSERT_EQUAL_UINT32_MESSAGE(expected_gain, vtb_denormalise_and_saturate_u32(agc.ch_state[i].gain, 0), "Incorrect channel gain");
    }
}

void test_set_get_wrong_ch_index(){
    srand((unsigned) 1);

    agc_init_config_t config = {
        {
            {
                0,
                1,
                1,
                VTB_UQ16_16(AGC_CH0_GAIN),
                VTB_UQ16_16(AGC_CH0_MAX_GAIN),
                VTB_UQ16_16(AGC_CH0_MIN_GAIN),
                VTB_UQ1_31(AGC_CH0_UPPER_THRESHOLD),
                VTB_UQ1_31(AGC_CH0_LOWER_THRESHOLD),
                AGC_CH0_GAIN_INC,
                AGC_CH0_GAIN_DEC
            },
            {
                0,
                1,
                1,
                VTB_UQ16_16(AGC_CH1_GAIN),
                VTB_UQ16_16(AGC_CH1_MAX_GAIN),
                VTB_UQ16_16(AGC_CH1_MIN_GAIN),
                VTB_UQ1_31(AGC_CH1_UPPER_THRESHOLD),
                VTB_UQ1_31(AGC_CH1_LOWER_THRESHOLD),
                AGC_CH1_GAIN_INC,
                AGC_CH1_GAIN_DEC
            }
        }
    };

    agc_state_t agc;
    agc_init(agc, config);


    for(unsigned i = AGC_INPUT_CHANNELS; i < (100 * AGC_INPUT_CHANNELS); ++i){
        agc_set_ch_adapt(agc, i, 1);
        agc_set_ch_gain(agc, i, ((vtb_uq16_16_t)rand() << 16));
        agc_set_ch_max_gain(agc, i, ((vtb_uq16_16_t)rand() << 16));
        agc_set_ch_upper_threshold(agc, i, ((int32_t)rand() << 16));
        agc_set_ch_lower_threshold(agc, i, ((int32_t)rand() << 16));

        agc_set_ch_adapt(agc, -i, 1);
        agc_set_ch_gain(agc, -i, ((vtb_uq16_16_t)rand() << 16));
        agc_set_ch_max_gain(agc, -i, ((vtb_uq16_16_t)rand() << 16));
        agc_set_ch_upper_threshold(agc, -i, ((int32_t)rand() << 16));
        agc_set_ch_lower_threshold(agc, -i, ((int32_t)rand() << 16));


        int inv_adapt = agc_get_ch_adapt(agc, i);
        vtb_uq16_16_t inv_gain = agc_get_ch_gain(agc, i);
        vtb_uq16_16_t inv_max_gain = agc_get_ch_max_gain(agc, i);
        int32_t invalid_dlvl = agc_get_ch_upper_threshold(agc, i);

        TEST_ASSERT_EQUAL_INT32_MESSAGE(0, inv_adapt, "inv_adapt not 0.");
        TEST_ASSERT_EQUAL_INT32_MESSAGE(0, invalid_dlvl, "invalid_dlvl not 0.");
        TEST_ASSERT_EQUAL_UINT32_MESSAGE(0, inv_gain, "inv_gain not 0.");
        TEST_ASSERT_EQUAL_UINT32_MESSAGE(0, inv_max_gain, "inv_max_gain not 0.");

        TEST_ASSERT_EQUAL_INT32_MESSAGE(0, agc_get_ch_adapt(agc, 0), "Incorrect ch0 adapt");
        TEST_ASSERT_EQUAL_INT32_MESSAGE(0, agc_get_ch_adapt(agc, 1), "Incorrect ch1 adapt");

        TEST_ASSERT_EQUAL_INT32_MESSAGE(VTB_UQ1_31(AGC_CH0_UPPER_THRESHOLD), agc_get_ch_upper_threshold(agc, 0), "Incorrect ch0 desired level");
        TEST_ASSERT_EQUAL_INT32_MESSAGE(VTB_UQ1_31(AGC_CH1_UPPER_THRESHOLD), agc_get_ch_upper_threshold(agc, 1), "Incorrect ch1 desired level");

        TEST_ASSERT_EQUAL_INT32_MESSAGE(VTB_UQ1_31(AGC_CH0_LOWER_THRESHOLD), agc_get_ch_lower_threshold(agc, 0), "Incorrect ch0 desired level");
        TEST_ASSERT_EQUAL_INT32_MESSAGE(VTB_UQ1_31(AGC_CH1_LOWER_THRESHOLD), agc_get_ch_lower_threshold(agc, 1), "Incorrect ch1 desired level");

        TEST_ASSERT_EQUAL_UINT32_MESSAGE(VTB_UQ16_16(AGC_CH0_GAIN), agc_get_ch_gain(agc, 0), "Incorrect ch0 gain");
        TEST_ASSERT_EQUAL_UINT32_MESSAGE(VTB_UQ16_16(AGC_CH1_GAIN), agc_get_ch_gain(agc, 1), "Incorrect ch1 gain");

        TEST_ASSERT_EQUAL_UINT32_MESSAGE(VTB_UQ16_16(AGC_CH0_MAX_GAIN), agc_get_ch_max_gain(agc, 0), "Incorrect ch0 max gain");
        TEST_ASSERT_EQUAL_UINT32_MESSAGE(VTB_UQ16_16(AGC_CH1_MAX_GAIN), agc_get_ch_max_gain(agc, 1), "Incorrect ch1 max gain");
    }
}


void test_agc_process_frame(){
    srand((unsigned) 2);
    const int gain_range = 64;

    agc_init_config_t config = {
        {
            {
                0,
                1,
                1,
                VTB_UQ16_16(AGC_CH0_GAIN),
                VTB_UQ16_16(AGC_CH0_MAX_GAIN),
                VTB_UQ16_16(AGC_CH0_MIN_GAIN),
                VTB_UQ1_31(AGC_CH0_UPPER_THRESHOLD),
                VTB_UQ1_31(AGC_CH0_LOWER_THRESHOLD),
                AGC_CH0_GAIN_INC,
                AGC_CH0_GAIN_DEC
            },
            {
                0,
                1,
                1,
                VTB_UQ16_16(AGC_CH1_GAIN),
                VTB_UQ16_16(AGC_CH1_MAX_GAIN),
                VTB_UQ16_16(AGC_CH1_MIN_GAIN),
                VTB_UQ1_31(AGC_CH1_UPPER_THRESHOLD),
                VTB_UQ1_31(AGC_CH1_LOWER_THRESHOLD),
                AGC_CH1_GAIN_INC,
                AGC_CH1_GAIN_DEC
            }
        }
    };

    for(unsigned i=0;i<TEST_COUNT;i++){
        vtb_ch_pair_t frame_in_out[AGC_CHANNEL_PAIRS][AGC_PROC_FRAME_LENGTH];
        int32_t init_value = ((int32_t)rand()) >> 7;

        for(int ch_pair=0; ch_pair<AGC_CHANNEL_PAIRS; ++ch_pair){
            for(int i=0; i<AGC_PROC_FRAME_LENGTH; ++i){
                frame_in_out[ch_pair][i].ch_a = init_value;
                frame_in_out[ch_pair][i].ch_b = init_value;
            }
        }

        agc_state_t agc;
        agc_init(agc, config);
        uint32_t gain =((uint32_t)rand()) % gain_range;

        for(unsigned i=0; i<AGC_INPUT_CHANNELS; ++i){
            agc_set_ch_gain(agc, i, VTB_UQ16_16((double)gain));
        }
        int vad = 0;
        vtb_u32_float_t ref_power = VTB_FLOAT_U32_ZERO;
        agc_process_frame(agc, frame_in_out, ref_power, vad, 0);

        for(int ch_pair=0; ch_pair<AGC_CHANNEL_PAIRS; ++ch_pair){
            for(int i=0; i<AGC_PROC_FRAME_LENGTH; ++i){
                TEST_ASSERT_INT32_WITHIN_MESSAGE(1<<16, gain * init_value, frame_in_out[ch_pair][i].ch_a, "Incorrect output sample");
                TEST_ASSERT_INT32_WITHIN_MESSAGE(1<<16, gain * init_value, frame_in_out[ch_pair][i].ch_b, "Incorrect output sample");
            }
        }
    }
}
