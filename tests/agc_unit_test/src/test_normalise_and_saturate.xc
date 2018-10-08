// Copyright (c) 2018, XMOS Ltd, All rights reserved
#include "agc_unit_tests.h"

void test_normalise_and_saturate(){

    printf("Testing normalise_and_saturate\n");
    unsigned r = 2;

    for(unsigned itt=0;itt<32;itt++){
        int32_t a = att_random_int32(r);
        int a_exp = sext(att_random_int32(r), 2) - 31;

        int32_t res;

        res = normalise_and_saturate(a, a_exp, -31);

        double a_fp = att_int32_to_double(a, a_exp);

        double res_expect_fp = 0;
        if(a_fp > 0.9999999999){
            res_expect_fp = 0.9999999999;
        } else if(a_fp < -0.9999999999){
            res_expect_fp = -0.9999999999;
        } else {
            res_expect_fp = a_fp;
        }

        int32_t res_expect = att_double_to_int32(res_expect_fp, -31);

        int diff = res- res_expect;
        if(diff < 0) diff = -diff;

        if(diff > 1){
            printf("\tError normalise_and_saturate\n");
            return;
        }
    }

    printf("\tSuccess normalise_and_saturate\n");
    return;
}
