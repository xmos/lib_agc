// Copyright (c) 2017-2019, XMOS Ltd, All rights reserved

#ifndef AGC_CONF_H_
#define AGC_CONF_H_

#define AGC_FRAME_ADVANCE           (240)
#define AGC_PROC_FRAME_LENGTH       (AGC_FRAME_ADVANCE)

#define AGC_INPUT_CHANNELS          (2)
#define AGC_CHANNEL_PAIRS           ((AGC_INPUT_CHANNELS+1)/2)


#define AGC_CH0_ADAPT               (0)
#define AGC_CH0_GAIN                (2)
#define AGC_CH0_MAX_GAIN            (1000)
#define AGC_CH0_DESIRED_LEVEL_FS    (0.1)

#define AGC_CH0_GAIN_INC            VTB_UQ16_16(1.0121)
#define AGC_CH0_GAIN_DEC            VTB_UQ16_16(0.9880)

#define AGC_CH1_GAIN_INC            VTB_UQ16_16(1.0121)
#define AGC_CH1_GAIN_DEC            VTB_UQ16_16(0.9880)

#define AGC_CH1_ADAPT               (1)
#define AGC_CH1_GAIN                (30)
#define AGC_CH1_MAX_GAIN            (100)
#define AGC_CH1_DESIRED_LEVEL_FS    (0.001)

#define AGC_CH0_DESIRED_LEVEL       (AGC_CH0_DESIRED_LEVEL_FS * INT32_MAX)
#define AGC_CH1_DESIRED_LEVEL       (AGC_CH1_DESIRED_LEVEL_FS * INT32_MAX)

#define AGC_CH0_UPPER_THRESHOLD     (0.002 * INT32_MAX)
#define AGC_CH0_LOWER_THRESHOLD     (0.0001 * INT32_MAX)

#define AGC_CH1_UPPER_THRESHOLD     (0.002 * INT32_MAX)
#define AGC_CH1_LOWER_THRESHOLD     (0.0001 * INT32_MAX)

#endif /* AGC_CONF_H_ */
