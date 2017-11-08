// Copyright (c) 2015-2016, XMOS Ltd, All rights reserved
#ifndef MIC_ARRAY_CONF_H_
#define MIC_ARRAY_CONF_H_

#include "system_defines.h"

#define MIC_ARRAY_WORD_LENGTH_SHORT    0 // 32 bit samples
#define MIC_ARRAY_MAX_FRAME_SIZE_LOG2  4 // TODO: hmm.
#define MIC_ARRAY_NUM_MICS             (SYSTEM_MICROPHONE_CHANNELS)

// TODO: make rest of the code accept 4.

#undef MIC_ARRAY_NUM_MICS
#define MIC_ARRAY_NUM_MICS             8

#endif /* MIC_ARRAY_CONF_H_ */
