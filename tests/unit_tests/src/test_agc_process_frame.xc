#include "agc_unit_tests.h"
#include "agc_conf.h"
#include "dsp_complex.h"

/** Function that processes a block of data.
*
* \param[in,out] agc     Gain controller structure
* \param[in,out] samples On input this array contains the sample data.
*                        On output this array contains the data with AGC
*                        applied. Headroom has been reintroduced, and samples
*                        have been clamped as appropriate.
*/

void test_gain_agc_process_frame() {

  printf("Testing if agc_process_frame changes the gain after AGC init. \n");
  agc_state_t agc;
  dsp_complex_t frame_in_out[AGC_CHANNEL_PAIRS][AGC_FRAME_ADVANCE];

  agc_init(agc);
  agc_process_frame(agc, frame_in_out);

  for(int i = 0; i<AGC_CHANNELS; i++){
    TEST_ASSERT_EQUAL_UINT32(AGC_GAIN, vtb_denormalise_and_saturate_u32(agc.ch_state[i].gain, 0));
  }
}


void test_2_init_gain_agc_process_frame() {

  printf("Testing if agc_process_frame changes the gain after AGC init (x2). \n");
  agc_state_t agc;
  dsp_complex_t frame_in_out[AGC_CHANNEL_PAIRS][AGC_FRAME_ADVANCE];

  agc_init(agc);
  agc_init(agc);
  agc_process_frame(agc, frame_in_out);

  for(int i = 0; i<AGC_CHANNELS; i++){
    TEST_ASSERT_EQUAL_UINT32(AGC_GAIN, vtb_denormalise_and_saturate_u32(agc.ch_state[i].gain, 0));
  }
}

void test_agc_process_frame_applied_gain() {

  printf("Testing if agc_process_frame applies the gain\n");
  agc_state_t agc;
  for(int a = -1000; a<1000; a++){
    dsp_complex_t frame_in_out[AGC_CHANNEL_PAIRS][AGC_FRAME_ADVANCE];
    for(int i = 0; i<AGC_CHANNEL_PAIRS; i++){
      for(int j = 0; j<AGC_FRAME_ADVANCE; j++){
        frame_in_out[i][j].re = a;
        frame_in_out[i][j].im = a;
      }
    }

    agc_init(agc);
    agc_process_frame(agc, frame_in_out);

    for(int i = 0; i<AGC_CHANNEL_PAIRS; i++){
      for(int j = 0; j<AGC_FRAME_ADVANCE; j++){
        TEST_ASSERT_EQUAL_UINT32(AGC_GAIN * a, frame_in_out[i][j].re);
        TEST_ASSERT_EQUAL_UINT32(AGC_GAIN * a, frame_in_out[i][j].im);
      }
    }
  }
}
