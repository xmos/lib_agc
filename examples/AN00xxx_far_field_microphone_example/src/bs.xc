#include <platform.h>
#include <xs1.h>
#include <xclib.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdio.h>
#include <print.h>
#include <xscope.h>

#include "beamsteering.h"

void bs_task(chanend input_audio,
             chanend output_audio,
             chanend buttons) {
    int32_t x[BS_CHANNELS][BS_FRAME_LENGTH/2];
    int32_t output_frame[BS_FRAME_LENGTH/2];
    dsp_complex_t tdoa_out[BS_CHANNELS][BS_FRAME_LENGTH/2];
    int32_t x_shr;
    bs_state_t state;
    bs_error_t error;
    int adapt;

    bs_state_init(state);
    while(1){
        slave {
            for(unsigned i=0;i<BS_CHANNELS;i++){
                for(unsigned j=0;j<BS_FRAME_LENGTH/2;j++){
                    input_audio :> x[i][j];
                }
            }
            input_audio :> x_shr;
        }
        select {
            case buttons :> adapt: break;
            default: break;
        }
        bs_process_td_frame(state, x, x_shr, error, output_frame, tdoa_out);

        if (1) {
            output_audio <: 0;
            for(unsigned i=0;i<BS_FRAME_LENGTH/2;i++) {
                output_audio <: output_frame[i];
            }
        } if (1) {
            output_audio <: state.debug_frame_input_shr;
            for(unsigned i=0;i<BS_FRAME_LENGTH/2;i++) {
                output_audio <: state.debug_frame_input[0][i+BS_FRAME_LENGTH/4];
            }
        } else {
            output_audio <: x_shr;
            for(unsigned i=0;i<BS_FRAME_LENGTH/2;i++) {
                output_audio <: x[0][i];
            }
        }
            

        if (adapt > 0) {
            bs_frame_adapt(state, error);
        } else if (adapt < 0) {
            bs_reset(state);
        }
        
        bs_post_process_td_frame(state, x, x_shr);
    }
}
