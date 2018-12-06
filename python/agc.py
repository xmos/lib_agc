# Copyright (c) 2018, XMOS Ltd, All rights reserved

import numpy as np

class agc:

    def __init__(self,
            channel_count,
            frame_advance,
            gain_db):
        self.channel_count = channel_count
        self.frame_advance = frame_advance
        self.gain = 10.0**(gain_db/20.0)
        self.AGC_FIXED_LIMIT = 0.5 # this must be 0.5
        return

    def process_frame(self, input_frame, verbose = False):
        def limit_gain(x):
            return x if abs(x) < self.AGC_FIXED_LIMIT else (np.sign(x) * 2 * self.AGC_FIXED_LIMIT - self.AGC_FIXED_LIMIT ** 2 / x)

        gained_input = self.gain * input_frame
        output = [[limit_gain(x) for x in y] for y in gained_input]
        return output
