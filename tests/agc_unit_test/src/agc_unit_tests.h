#ifndef AGC_UNIT_TESTS_H_
#define AGC_UNIT_TESTS_H_
#include <xs1.h>
#include <string.h>
#include <stdio.h>
#include <math.h>

#include <xclib.h>

#include "audio_test_tools.h"
#include "voice_toolbox.h"

#define TEST_ASM 1



{int32_t, int} multiply(int32_t a, int a_exp, uint32_t b, int b_exp);
{uint32_t, int} absolute(int32_t a, int a_exp);
int is_greater_than(uint32_t a, int a_exp, uint32_t b, int b_exp);
{uint32_t, int} subtract(uint32_t a, int a_exp, uint32_t b, int b_exp);
{uint32_t, int} divide(uint32_t a, int a_exp, uint32_t b, int b_exp);
int32_t normalise_and_saturate(int32_t gained_sample, int gained_sample_exp, int input_exponent);

void test_multiply();
void test_absolute();
void test_is_greater_than();
void test_subtract();
void test_divide();
void test_normalise_and_saturate();


#endif /* AGC_UNIT_TESTS_H_ */
