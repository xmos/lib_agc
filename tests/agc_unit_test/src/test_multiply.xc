// Copyright (c) 2018, XMOS Ltd, All rights reserved
#include "agc_unit_tests.h"


//{int32_t, int} multiply(int32_t a, int a_exp, uint32_t b, int b_exp);

void test_multiply(){

    printf("Testing multiply\n");
    unsigned r = 2;

    for(unsigned itt=0;itt<1<<13;itt++){
        int32_t a = att_random_int32(r);
        int a_exp = sext(att_random_int32(r), 4);
        int32_t b = att_random_int32(r);
        int b_exp = sext(att_random_int32(r), 4);

        int32_t res;
        int res_exp;

        {res, res_exp} = multiply(a, a_exp, b, b_exp);

        double a_fp = att_int32_to_double(a, a_exp);
        double b_fp = att_uint32_to_double(b, b_exp);

        double res_actual_fp = att_int32_to_double(res, res_exp);
        double res_expect_fp = a_fp*b_fp;

        uint32_t res_expect = att_double_to_int32(res_expect_fp, res_exp);

        int diff = res- res_expect;
        if(diff < 0) diff = -diff;

        if(diff > 1){
            printf("\tError multiply\n");
            printf("%d\n", diff);
//            return;
        }
    }

    printf("\tSuccess multiply\n");
    return;
}
