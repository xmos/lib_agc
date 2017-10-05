// Copyright (c) 2017, XMOS Ltd, All rights reserved
#ifndef _agc_h_
#define _agc_h_

#include <stdint.h>

typedef enum {
    AGC_UP = 0,
    AGC_DOWN = 1,
    AGC_WAIT = 2,
    AGC_STABLE = 3
} agc_mode;

typedef struct {
    agc_mode state;
    uint32_t frame_length;

    uint32_t desired;
    uint32_t desired_min;
    uint32_t desired_max;
    
    uint32_t gain;
    int32_t gain_shl;
    
    uint32_t max_gain;
    int32_t max_gain_shl;
    
    uint32_t min_gain;
    int32_t min_gain_shl;
    
    uint32_t down, up;
    
    uint32_t wait_samples;
    uint32_t wait_for_up_samples;
} agc_state_t;

/** Function that initialises an automatic gain controller. It needs to be
 * passed an AGC structure, and the initial gain setting in dB. The gain
 * controller is initialised with the following default values:
 *
 * - minimum gain:      -48 dB
 * - maximum gain:       12 dB
 * - rate of gain down: -70 dB per second
 * - rate of gain up  :   7 dB per second
 *
 * All of these can be changed using the access functions below.
 * 
 * \param agc[out]              gain controller structure, initialised on return
 * \param initial_gain_db[in]   Initial gain in dB. 12 is a good number. The
 *                              initial gain must be in the range [-127..127].
 * \param desired_energy_db[in] desired energy in dB. -12 is a good number. The
 *                              desired energy must be in the range [-127..-1].
 * \param frame_length[in]      Number of samples on which AGC operates.
 */
void agc_init_state(agc_state_t &agc,
                    int32_t initial_gain_db,
                    int32_t desired_energy_db,
                    uint32_t frame_length);

/** Function that sets the maximum gain allowed on the automatic gain
 * control. This value must be larger than or equal to the initial gain,
 * and larger than or equal to the minimum gain. The gain should be in the
 * range [-127..127].
 *
 * \param agc[in,out] Gain controller structure
 * \param db[in]      Desired maximum gain in dB
 */
void agc_set_gain_max_db(agc_state_t &agc, int32_t db);

/** Function that sets the minimum gain allowed on the automatic gain
 * control. This value must be less than or equal to the initial gain, and
 * less than or equal to the maximum gain. The gain should be in the
 * range [-127..127].
 *
 * \param agc[in,out] Gain controller structure
 * \param db[in]      Desired minimum gain in dB
 */
void agc_set_gain_min_db(agc_state_t &agc, int32_t db);

/** Function that sets the desired energy level of the output. Should be
 * negative in the range [-127..-1]. A good value is -6 dB.
 *
 * \param agc[in,out] Gain controller structure
 * \param db[in]      Desired output energy in dB
 */
void agc_set_desired_db(agc_state_t &agc, int32_t db);

/** Function that sets the speed at which the gain controller adapts whilst
 * increasing gain. The value is expressed in dB per second, and must be
 * in the range [1..1000]
 *
 * \param agc[in,out] Gain controller structure
 * \param dbps[in]    Desired adaptation speed in dB per second
 */
void agc_set_rate_down_dbps(agc_state_t &agc, int32_t dbps);

/** Function that sets the speed at which the gain controller adapts whilst
 * decreasing gain. The value is expressed in dB per second, and must be
 * in the range [-1000..-1]
 *
 * \param agc[in,out] Gain controller structure
 * \param dbps[in]    Desired adaptation speed in dB per second
 */
void agc_set_rate_up_dbps(agc_state_t &agc, int32_t dbps);

/** Function that sets the time before the gain starts to increase
 *
 * \param agc[in,out]      Gain controller structure
 * \param milliseconds[in] Time between quiesence and gain increasing
 */
void agc_set_wait_for_up_ms(agc_state_t &agc, int32_t milliseconds);

/** Function that processes a block of data.
 *
 * \param agc[in,out]     Gain controller structure
 * \param samples[in,out] On input this array contains the sample data.
 *                        If headroom has been removed, then the shr parameter
 *                        should be set to the amount of headroom that has been
 *                        removed. 
 *                        On output this array contains the data with AGC
 *                        applied. Headroom has been reintroduced, and samples
 *                        have been clamped as appropriate. 
 * \param shr[in]         Number of bits that samples have been shifted left by
 */
void agc_block(agc_state_t &agc,
               int32_t samples[],
               int32_t shr);

/** Function that gets the current gain.
 * \param agc[in] Gain controller structure
 * \returns       gain in dB, multiplied by 2^24. Ie, 0x1000000 = 1 dB.
 */
int32_t agc_get_gain(agc_state_t &agc);


#endif // _agc_h_
