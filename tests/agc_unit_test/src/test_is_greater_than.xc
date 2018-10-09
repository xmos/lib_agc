// Copyright (c) 2018, XMOS Ltd, All rights reserved
#include "agc_unit_tests.h"


//int is_greater_than(uint32_t a, int a_exp, uint32_t b, int b_exp);

void test_is_greater_than(){

    printf("Testing is_greater_than\n");
    unsigned r = 2;

    for(unsigned itt=0;itt<1<<13;itt++){
        uint32_t a = att_random_uint32(r);
        int a_exp = sext(att_random_int32(r), 4);
        uint32_t b = att_random_uint32(r);
        int b_exp = sext(att_random_int32(r), 4);

        uint32_t res;
        int res_exp;

        int res_actual = is_greater_than(a, a_exp, b, b_exp);

        double a_fp = att_uint32_to_double(a, a_exp);
        double b_fp = att_uint32_to_double(b, b_exp);

        int res_expect = a_fp>b_fp;

        if(res_expect != res_actual){
            printf("\tError is_greater_than\n");
            return;
        }
    }

    printf("\tSuccess is_greater_than\n");
    return;
}
