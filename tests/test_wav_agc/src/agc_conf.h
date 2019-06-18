// Copyright (c) 2017-2019, XMOS Ltd, All rights reserved

#ifndef AGC_CONF_H_
#define AGC_CONF_H_

#define AGC_FRAME_ADVANCE           (240)
#define AGC_PROC_FRAME_LENGTH       (AGC_FRAME_ADVANCE)

#define AGC_INPUT_CHANNELS          (2)
#define AGC_CHANNEL_PAIRS           ((AGC_INPUT_CHANNELS+1)/2)

#define AGC_CH0_ADAPT               (1)
#define AGC_CH0_GAIN                (10)
#define AGC_CH0_MAX_GAIN            (100000)
#define AGC_CH0_UPPER_THRESHOLD     (0.7079 * INT32_MAX)
#define AGC_CH0_LOWER_THRESHOLD     (0.1905 * INT32_MAX)
#define AGC_CH0_GAIN_INC            (1.197)
#define AGC_CH0_GAIN_DEC            (0.87)

#define AGC_CH1_ADAPT               (1)
#define AGC_CH1_GAIN                (2)
#define AGC_CH1_MAX_GAIN            (100000)
#define AGC_CH1_UPPER_THRESHOLD     (0.316 * INT32_MAX)
#define AGC_CH1_LOWER_THRESHOLD     (0.316 * INT32_MAX)
#define AGC_CH1_GAIN_INC            (1.0121)
#define AGC_CH1_GAIN_DEC            (0.98804)

#endif /* AGC_CONF_H_ */
