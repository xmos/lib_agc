// Copyright (c) 2017-2019, XMOS Ltd, All rights reserved
#include<platform.h>

#include "voice_toolbox.h"
#include "agc.h"
#include "audio_test_tools.h"

void app_control(chanend c_control_to_wav, chanend c_control_to_dsp){

    //Play for 5 seconds
    att_pw_play_until_sample_passes(c_control_to_wav, 16000*5);

    //command the DSP to do something
    //aec_...

    //Play the rest of the file
    att_pw_play(c_control_to_wav);
}

int main(){
    chan app_to_dsp;
    chan dsp_to_app;
    chan c_control_to_dsp;
    chan c_control_to_wav;

    par {
        on tile[0]:{
            app_control(c_control_to_wav, c_control_to_dsp);
        }
        on tile[0]:{
            att_process_wav(app_to_dsp, dsp_to_app, c_control_to_wav);
            _Exit(0);
        }
        on tile[1]: agc_test_task(app_to_dsp, dsp_to_app, c_control_to_dsp);
    }
    return 0;
}
