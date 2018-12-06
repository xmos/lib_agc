# Copyright (c) 2018, XMOS Ltd, All rights reserved

import numpy as np

class agc:

    INIT_GAIN = 1
    FIXED_LIMIT = 0.5

    def __init__(self,
            channel_count,
            frame_advance):
        self.channel_count = channel_count
        self.frame_advance = frame_advance
        self.gain = [agc.INIT_GAIN] * channel_count
        return

    def set_channel_gain(self, ch_index, gain_db):
        self.gain[ch_index] = gain_db
        if self.gain[ch_index] < 1:
            self.gain[ch_index] = 1
        return

    def process_frame(self, input_frame, verbose = False):
        def limit_gain(x):
            return x if abs(x) < agc.FIXED_LIMIT else (np.sign(x) * 2 * agc.FIXED_LIMIT - agc.FIXED_LIMIT ** 2 / x)

        output = np.empty(np.shape(input_frame))
        for i, ch in enumerate(input_frame):
            gained_input = self.gain[i] * ch
            output[i] = [limit_gain(x) for x in gained_input]
        return output
