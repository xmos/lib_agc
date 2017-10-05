// Copyright (c) 2016-2017, XMOS Ltd, All rights reserved

#include <platform.h>
#include <xs1.h>
#include <xclib.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <stdio.h>
#include <print.h>
#include <xscope.h>
#include "agc.h"

#define AGC_WINDOW_LENGTH 512

int sineWave[16] = {
    418934098,
    1193023376,
    1785485660,
    2106123937,
    2106123937,
    1785485660,
    1193023376,
    418934098,
    -418934098,
    -1193023376,
    -1785485660,
    -2106123937,
    -2106123937,
    -1785485660,
    -1193023376,
    -418934098,
};

int main(void) {
    int32_t input_data[AGC_WINDOW_LENGTH];
    int32_t compare_data[AGC_WINDOW_LENGTH];
    agc_state_t a;

    for(int i =0 ; i < AGC_WINDOW_LENGTH; i++) {
        input_data[i] = 0 ? i & 0 ? 0x80000000 : 0x7fffffff : sineWave[i&15];
        compare_data[i] = input_data[i];
    }
    agc_init_state(a, 10, -10, AGC_WINDOW_LENGTH);
    agc_set_wait_for_up_ms(a, 100);
    for(int i = 0; i < 12; i++) {
        for(int i =0 ; i < AGC_WINDOW_LENGTH; i++) {
            input_data[i] = compare_data[i];
        }
        agc_block(a, input_data, 0);
    }
    for(int i = 0; i < 48; i++) {
        for(int i =0 ; i < AGC_WINDOW_LENGTH; i++) {
            input_data[i] = compare_data[i];
        }
        agc_block(a, input_data, 2);
    }
    return 0;
    for(int i = 0; i < AGC_WINDOW_LENGTH; i++) {
        printf("%lld\n", 1000LL * input_data[i]/compare_data[i]);
    }
    return 0;
}
