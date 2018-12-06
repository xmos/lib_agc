// Copyright (c) 2018, XMOS Ltd, All rights reserved
#ifndef AGC_UNIT_TESTS_H_
#define AGC_UNIT_TESTS_H_

#include "unity.h"

#ifdef __XC__

#include <xs1.h>
#include <string.h>
#include <math.h>

#include <xclib.h>

#include "audio_test_tools.h"
#include "voice_toolbox.h"

#include "agc.h"

#define TEST_ASM 1

#endif // __XC__

#endif /* AGC_UNIT_TESTS_H_ */
