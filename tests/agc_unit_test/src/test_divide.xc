// Copyright (c) 2018, XMOS Ltd, All rights reserved
#include "agc_unit_tests.h"

void test_divide(){

    printf("Testing divide\n");
    unsigned r = 2;

    for(unsigned itt=0;itt<1<<13;itt++){
        uint32_t a = att_random_uint32(r);
        int a_exp = sext(att_random_int32(r), 4);
        uint32_t b = att_random_uint32(r);
        int b_exp = sext(att_random_int32(r), 4);

        double a_fp = att_uint32_to_double(a, a_exp);
        double b_fp = att_uint32_to_double(b, b_exp);

        uint32_t res;
        int res_exp;
        {res, res_exp} = divide(a, a_exp, b, b_exp);

        double res_actual_fp = att_uint32_to_double(res, res_exp);
        double res_expect_fp = a_fp/b_fp;
        uint32_t res_expect = att_double_to_uint32(a_fp/b_fp, res_exp);

        int diff = res- res_expect;
        if(diff < 0) diff = -diff;

        if(diff > 1){
            printf("\tError divide\n");
            return;
        }
    }

    printf("\tSuccess divide\n");
    return;
}
