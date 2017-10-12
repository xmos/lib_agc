#ifndef _DEMO_NS_AGC_H_
#define _DEMO_NS_AGC_H_

#define AGC_FRAME_LENGTH 128

void noise_suppression_automatic_gain_control_task(chanend audio_input,
                                                   chanend audio_output);

#endif // _DEMO_NS_AGC_H_
