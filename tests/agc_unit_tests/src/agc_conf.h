// Copyright 2017-2021 XMOS LIMITED.
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

#define AGC_CH0_LC_N_FRAME_NEAR     (10)
#define AGC_CH0_LC_N_FRAME_FAR      (20)
#define AGC_CH0_LC_NEAR_DELTA_FAR_ACT (0.11)
#define AGC_CH0_LC_NEAR_DELTA       (0.21)
#define AGC_CH0_LC_FAR_DELTA        (0.31)
#define AGC_CH0_LC_GAMMA_INC        (0.12)
#define AGC_CH0_LC_GAMMA_DEC        (0.22)
#define AGC_CH0_LC_BG_POWER_GAMMA   (0.32)
#define AGC_CH0_LC_CORR_THRESHOLD   (0.13)
#define AGC_CH0_LC_GAIN_MAX         (0.43)
#define AGC_CH0_LC_GAIN_DT          (0.33)
#define AGC_CH0_LC_GAIN_SILENCE     (0.23)
#define AGC_CH0_LC_GAIN_MIN         (0.13)

#define AGC_CH1_LC_N_FRAME_NEAR     (60)
#define AGC_CH1_LC_N_FRAME_FAR      (70)
#define AGC_CH1_LC_NEAR_DELTA_FAR_ACT (0.51)
#define AGC_CH1_LC_NEAR_DELTA       (0.61)
#define AGC_CH1_LC_FAR_DELTA        (0.71)
#define AGC_CH1_LC_GAMMA_INC        (0.52)
#define AGC_CH1_LC_GAMMA_DEC        (0.62)
#define AGC_CH1_LC_BG_POWER_GAMMA   (0.72)
#define AGC_CH1_LC_CORR_THRESHOLD   (0.53)
#define AGC_CH1_LC_GAIN_MAX         (0.83)
#define AGC_CH1_LC_GAIN_DT          (0.73)
#define AGC_CH1_LC_GAIN_SILENCE     (0.63)
#define AGC_CH1_LC_GAIN_MIN         (0.53)

#endif /* AGC_CONF_H_ */
