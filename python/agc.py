# Copyright (c) 2018-2019, XMOS Ltd, All rights reserved
from __future__ import division
from builtins import object
import numpy as np
from math import sqrt


class agc(object):
    # Adaption coefficients, do not change
    ALPHA_SLOW_RISE = 0.8869
    ALPHA_SLOW_FALL = 0.9646
    ALPHA_FAST_RISE = 0.3814
    ALPHA_FAST_FALL = 0.8869
    ALPHA_PEAK_RISE = 0.5480
    ALPHA_PEAK_FALL = 0.9646
    GAIN_INC = 1.0121
    GAIN_DEC = 1.0 / GAIN_INC


    def __init__(self, adapt, init_gain, max_gain, desired_level_dBFS):
        if init_gain < 0:
            raise Exception("init_gain must be greater than 0.")
        if max_gain < 0:
            raise Exception("max_gain must be greater than 0.")
        if desired_level_dBFS > 0:
            raise Exception("desired_level_dBFS must be less than or equal to 0.")

        self.adapt = adapt
        self.gain = init_gain
        self.max_gain = max_gain
        self.desired_level = (10 ** (float(desired_level_dBFS)/20))
        self.x_slow = 0
        self.x_fast = 0
        self.x_peak = 0


    def process_frame(self, input_frame, vad):
        if(self.adapt):
            peak_sample = np.absolute(input_frame).max() #Sample input from Ch0
            rising = peak_sample > abs(self.x_slow)

            alpha_slow = agc.ALPHA_SLOW_RISE if rising else agc.ALPHA_SLOW_FALL
            self.x_slow = (1 - alpha_slow) * peak_sample + alpha_slow * self.x_slow

            alpha_fast = agc.ALPHA_FAST_RISE if rising else agc.ALPHA_FAST_FALL
            self.x_fast = (1 - alpha_fast) * peak_sample + alpha_fast * self.x_fast

            exceed_desired_level = (peak_sample * self.gain) > self.desired_level

            if vad or exceed_desired_level:
                alpha_peak = agc.ALPHA_PEAK_RISE if self.x_fast > self.x_peak else agc.ALPHA_PEAK_FALL
                self.x_peak = (1 - alpha_peak) * self.x_fast + alpha_peak * self.x_peak

                g_mod = agc.GAIN_INC if self.x_peak * self.gain < self.desired_level else agc.GAIN_DEC
                self.gain = min(g_mod * self.gain, self.max_gain)


        def limit_gain(x):
            NONLINEAR_POINT = 0.5
            return x if abs(x) < NONLINEAR_POINT else (np.sign(x) * 2 * NONLINEAR_POINT - (NONLINEAR_POINT ** 2 / x))

        gained_input = self.gain * input_frame
        output_frame = [limit_gain(sample) for sample in gained_input]
        return output_frame
