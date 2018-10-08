// Copyright (c) 2017-2018, XMOS Ltd, All rights reserved
#include<platform.h>

#include "voice_toolbox.h"
#include "agc.h"
#include "audio_test_tools.h"


#include "agc_unit_tests.h"

int main(){
    test_normalise_and_saturate();
    test_multiply();
    test_absolute();
    test_is_greater_than();
    test_divide();
    test_subtract();
    return 0;
}
