#ifndef _DEMO_NS_AGC_H_
#define _DEMO_NS_AGC_H_

//#include "noise_suppression.h"
#define NS_FD_FRAME_SIZE 512
#define NS_FD_FRAME_SIZE_LOG2 9

#define DEMO_NS_AGC_FRAME_LENGTH      (NS_FD_FRAME_SIZE)
#define DEMO_NS_AGC_FRAME_LENGTH_LOG2 (NS_FD_FRAME_SIZE_LOG2)

#if defined(__XC__)

void noise_suppression_automatic_gain_control_task(chanend audio_input,
                                                   chanend audio_output);

#endif

#endif // _DEMO_NS_AGC_H_
