// Copyright 2018-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#ifndef AGC_CONF_H_
#define AGC_CONF_H_

#define AGC_FRAME_ADVANCE           (240)
#define AGC_PROC_FRAME_LENGTH       (AGC_FRAME_ADVANCE)

#define AGC_INPUT_CHANNELS          (2)
#define AGC_CHANNEL_PAIRS           ((AGC_INPUT_CHANNELS+1)/2)


#define AGC_CH0_ADAPT               (0)
#define AGC_CH0_ADAPT_ON_VAD        (0)
#define AGC_CH0_SOFT_CLIPPING       (0)
#define AGC_CH0_LC_ENABLED          (0)


#define AGC_CH0_GAIN                (2)
#define AGC_CH0_MAX_GAIN            (1000)
#define AGC_CH0_MIN_GAIN            (100)
#define AGC_CH0_DESIRED_LEVEL_FS    (0.1)

#define AGC_CH0_GAIN_INC            VTB_UQ16_16(1.0121)
#define AGC_CH0_GAIN_DEC            VTB_UQ16_16(0.9880)

#define AGC_CH1_GAIN_INC            VTB_UQ16_16(1.0121)
#define AGC_CH1_GAIN_DEC            VTB_UQ16_16(0.9880)

#define AGC_CH1_ADAPT               (1)
#define AGC_CH1_ADAPT_ON_VAD        (1)
#define AGC_CH1_SOFT_CLIPPING       (1)
#define AGC_CH1_LC_ENABLED          (1)

#define AGC_CH1_GAIN                (30)
#define AGC_CH1_MAX_GAIN            (100)
#define AGC_CH1_MIN_GAIN            (0)

#define AGC_CH1_DESIRED_LEVEL_FS    (0.001)

#define AGC_CH0_UPPER_THRESHOLD     (0.002)
#define AGC_CH0_LOWER_THRESHOLD     (0.0001)

#define AGC_CH1_UPPER_THRESHOLD     (0.002)
#define AGC_CH1_LOWER_THRESHOLD     (0.0001)

#endif /* AGC_CONF_H_ */
