// Copyright (c) 2018, XMOS Ltd, All rights reserved
#include "agc_unit_tests.h"


//{uint32_t, int} absolute(int32_t a, int a_exp);

void test_absolute(){

    printf("Testing absolute\n");
    unsigned r = 2;

    for(unsigned itt=0;itt<32;itt++){
        int32_t a = att_random_int32(r);
        int a_exp = sext(att_random_int32(r), 4);

        int32_t res;
        int res_exp;

        {res, res_exp} = absolute(a, a_exp);

        double a_fp = att_int32_to_double(a, a_exp);

        double res_actual_fp = att_int32_to_double(res, res_exp);
        double res_expect_fp = fabs(a_fp);

        uint32_t res_expect = att_double_to_uint32(res_expect_fp, res_exp);

        int diff = res- res_expect;
        if(diff < 0) diff = -diff;

        if(diff > 1){
            printf("\tError absolute\n");
            return;
        }
    }

    printf("\tSuccess absolute\n");
    return;
}
