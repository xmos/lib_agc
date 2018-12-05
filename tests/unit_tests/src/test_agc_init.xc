#include "agc_unit_tests.h"
#include "agc_conf.h"
/** Function that initialises an automatic gain controller. It needs to be
* passed an AGC structure, and the initial gain setting in dB. The gain
* controller is initialised with the following default values:
*
* - initial gain:         0 dB
* - desired energy:     -30 dB
* - minimum gain:      -127 dB
* - maximum gain:       127 dB
* - rate of gain down:  -70 dB per second
* - rate of gain up  :    7 dB per second
* - grace period before up 6s      THIS SHOULD BE 4?
* - lookahead frames:     0
* - lookpast frames:      0
*
* All of these can be changed using the access functions below.
*
* The processing function that performs the actual AGC inputs a block in
* block-floating-point format, and outputs a block of integers. The input
* can represent a very large dynamic range, whereas the output is
* represented in a small dynamic range of integers in the range
* [-2^31..2^31-1]. The AGCs purpose is to perform this range reduction in
* a meaningful way.
*
* The initial gain setting and the desired energy level may have to be set
* using one of the setters below before starting the AGC. A good guess
* for the initial setting enables the AGC to operate without warm-up. The
* initial setting should compensate for the sensitivity of the microphones
* and the gain applied by any previous stages in the voice pipeline. For
* example, if the microphones have a low sensitivity then a higher initial
* value should be picked than if microphones have a high sensitivity.
*
* \param[out] agc              gain controller structure, initialised on return
*
* \param[in] frame_length      Number of samples on which AGC operates.
*/

void test_agc_init() {

  printf("Testing agc_init\n");
  agc_state_t agc;
  agc_init(agc);

  for(int i = 0; i<AGC_CHANNELS; i++){
    TEST_ASSERT_EQUAL_UINT32(AGC_GAIN, vtb_denormalise_and_saturate_u32(agc.ch_state[i].gain, 0));
  }
}

void test_agc_init_2_times() {

  printf("Testing agc_init ten times over and over\n");
  agc_state_t agc;
  agc_init(agc);
  agc_init(agc);

  for(int i = 0; i<AGC_CHANNELS; i++){
    TEST_ASSERT_EQUAL_UINT32(AGC_GAIN, vtb_denormalise_and_saturate_u32(agc.ch_state[i].gain, 0));
  }
}
