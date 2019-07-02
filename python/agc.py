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


    def __init__(self, adapt, init_gain, max_gain, upper_threshold, lower_threshold, gain_inc=1.0121, gain_dec=0.98804):
        if init_gain < 0:
            raise Exception("init_gain must be greater than 0.")
        if max_gain < 0:
            raise Exception("max_gain must be greater than 0.")
        if upper_threshold > 1.0:
            raise Exception("upper_threshold must be less than or equal to 1.")
        if lower_threshold > 1.0:
            raise Exception("lower_threshold must be less than or equal to 1.")

        self.adapt = adapt
        self.gain = init_gain
        self.max_gain = max_gain
        self.x_slow = 0
        self.x_fast = 0
        self.x_peak = 0
        
        self.gain_inc = gain_inc
        self.gain_dec = gain_dec

        self.threshold_upper = float(upper_threshold)
        self.threshold_lower = float(lower_threshold)


    def process_frame(self, input_frame, vad):
        if(self.adapt):
            peak_sample = np.absolute(input_frame).max() #Sample input from Ch0
            rising = peak_sample > abs(self.x_slow)

            alpha_slow = agc.ALPHA_SLOW_RISE if rising else agc.ALPHA_SLOW_FALL
            self.x_slow = (1 - alpha_slow) * peak_sample + alpha_slow * self.x_slow

            alpha_fast = agc.ALPHA_FAST_RISE if rising else agc.ALPHA_FAST_FALL
            self.x_fast = (1 - alpha_fast) * peak_sample + alpha_fast * self.x_fast

            exceed_desired_level = (peak_sample * self.gain) > self.threshold_upper

            if vad or exceed_desired_level:
                alpha_peak = agc.ALPHA_PEAK_RISE if self.x_fast > self.x_peak else agc.ALPHA_PEAK_FALL
                self.x_peak = (1 - alpha_peak) * self.x_fast + alpha_peak * self.x_peak

                g_mod = 1
                if self.x_peak * self.gain < self.threshold_lower:
                    g_mod = self.gain_inc 
                elif self.x_peak * self.gain > self.threshold_upper:
                    g_mod = self.gain_dec

                self.gain = min(g_mod * self.gain, self.max_gain)


        def limit_gain(x):
            NONLINEAR_POINT = 0.5
            return x if abs(x) < NONLINEAR_POINT else (np.sign(x) * 2 * NONLINEAR_POINT - NONLINEAR_POINT ** 2 / x)

        gained_input = self.gain * input_frame
        output_frame = [limit_gain(sample) for sample in gained_input]
        return output_frame
