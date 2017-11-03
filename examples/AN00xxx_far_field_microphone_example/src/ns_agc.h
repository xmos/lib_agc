#ifndef _DEMO_NS_AGC_H_
#define _DEMO_NS_AGC_H_

#if defined(__XC__)

void noise_suppression_automatic_gain_control_task(chanend audio_input,
                                                   chanend audio_output,
                                                   chanend from_buttons);

#endif

#endif // _DEMO_NS_AGC_H_
