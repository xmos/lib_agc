// Copyright (c) 2017-2019, XMOS Ltd, All rights reserved

#ifndef AGC_CONF_H_
#define AGC_CONF_H_

#define AGC_FRAME_ADVANCE           (240)
#define AGC_PROC_FRAME_LENGTH       (AGC_FRAME_ADVANCE)

#define AGC_INPUT_CHANNELS          (2)

#define AGC_CH0_ADAPT               (0)
#define AGC_CH0_GAIN                (2)
#define AGC_CH0_MAX_GAIN            (1000)
#define AGC_CH0_DESIRED_LEVEL_FS    (0.1)

#define AGC_CH1_ADAPT               (1)
#define AGC_CH1_GAIN                (30)
#define AGC_CH1_MAX_GAIN            (100)
#define AGC_CH1_DESIRED_LEVEL_FS    (0.001)

#define AGC_CH0_DESIRED_LEVEL       (AGC_CH0_DESIRED_LEVEL_FS * INT32_MAX)
#define AGC_CH1_DESIRED_LEVEL       (AGC_CH1_DESIRED_LEVEL_FS * INT32_MAX)

#endif /* AGC_CONF_H_ */
