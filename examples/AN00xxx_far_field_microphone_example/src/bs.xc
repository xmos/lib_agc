#include <platform.h>
#include <xs1.h>
#include <xclib.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdio.h>
#include <print.h>
#include <xscope.h>
#include <dsp.h>

#include "beamsteering.h"

void bs_task(chanend input_audio,
             chanend output_audio,
             chanend buttons) {
    dsp_complex_t [[aligned(8)]] x[BS_INPUT_CHANNELS/2][BS_PROC_FRAME_LENGTH];
    int32_t output_frame[BS_FRAME_ADVANCE];
    dsp_complex_t tdoa_out[BS_INPUT_CHANNELS][BS_FRAME_ADVANCE];
    uint64_t rx_state[DSP_BFP_RX_STATE_UINT64_SIZE(BS_INPUT_CHANNELS, BS_PROC_FRAME_LENGTH, BS_FRAME_ADVANCE)];
    int32_t x_shr;
    bs_state_t state;
    bs_error_t error;
    int adapt = 0;
    timer tmr;
    int32_t t0, t1, t2, t3;
    int cnt = 0;

    bs_state_init(state);
    dsp_bfp_rx_state_init_xc(rx_state,DSP_BFP_RX_STATE_UINT64_SIZE(BS_INPUT_CHANNELS, BS_PROC_FRAME_LENGTH, BS_FRAME_ADVANCE)); 
    while(1){
        x_shr = dsp_bfp_rx_pairs(input_audio, rx_state, (x, dsp_complex_t[]),
                                 BS_INPUT_CHANNELS, BS_PROC_FRAME_LENGTH,
                                 BS_FRAME_ADVANCE, 1);
        select {
            case buttons :> adapt: break;
            default: break;
        }
        tmr :> t0;

        bs_process_td_frame(state, x, x_shr, error, output_frame, tdoa_out);
        tmr :> t1;
        
        dsp_bfp_tx_xc(output_audio,
                      output_frame,
                      BS_OUTPUT_CHANNELS, BS_FRAME_ADVANCE,
                      0);

        if (adapt > 0) {
            cnt++;
        tmr :> t2;
            bs_frame_adapt(state, x, x_shr, error);
        tmr :> t3;
            if ((cnt & 15) == 0) {
                printf("* %d %d\n", t1-t0, t3-t2);
            }

        } else if (adapt < 0) {
            bs_reset(state);
        }
    }
}