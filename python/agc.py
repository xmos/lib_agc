# Copyright (c) 2018-2019, XMOS Ltd, All rights reserved
from __future__ import division
from builtins import object
import numpy as np
from math import sqrt

class agc_ch(object):
    def __init__(self, adapt, init_gain, max_gain, upper_threshold, lower_threshold, gain_inc, gain_dec):
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
        
        self.gain_inc = gain_inc
        self.gain_dec = gain_dec

        self.threshold_upper = float(upper_threshold)
        self.threshold_lower = float(lower_threshold)

class agc(object):
    # Adaption coefficients, do not change
    ALPHA_SLOW_RISE = 0.8869
    ALPHA_SLOW_FALL = 0.9646
    ALPHA_FAST_RISE = 0.3814
    ALPHA_FAST_FALL = 0.8869
    ALPHA_PEAK_RISE = 0.5480
    ALPHA_PEAK_FALL = 0.9646


    def __init__(self, ch_init_config):
        self.ch_state = []
        for ch_idx in range(len(ch_init_config)):

            self.ch_state.append(agc_ch(**ch_init_config[ch_idx]))
            self.ch_state[ch_idx].x_slow = 0
            self.ch_state[ch_idx].x_fast = 0
            self.ch_state[ch_idx].x_peak = 0
    
    def process_frame(self, ch, input_frame, vad):
        if(self.ch_state[ch].adapt):
            peak_sample = np.absolute(input_frame).max() #Sample input from Ch0
            rising = peak_sample > abs(self.ch_state[ch].x_slow)

            alpha_slow = agc.ALPHA_SLOW_RISE if rising else agc.ALPHA_SLOW_FALL
            self.ch_state[ch].x_slow = (1 - alpha_slow) * peak_sample + alpha_slow * self.ch_state[ch].x_slow

            alpha_fast = agc.ALPHA_FAST_RISE if rising else agc.ALPHA_FAST_FALL
            self.ch_state[ch].x_fast = (1 - alpha_fast) * peak_sample + alpha_fast * self.ch_state[ch].x_fast

            exceed_desired_level = (peak_sample * self.ch_state[ch].gain) > self.ch_state[ch].threshold_upper

            if vad or exceed_desired_level:
                alpha_peak = agc.ALPHA_PEAK_RISE if self.ch_state[ch].x_fast > self.ch_state[ch].x_peak else agc.ALPHA_PEAK_FALL
                self.ch_state[ch].x_peak = (1 - alpha_peak) * self.ch_state[ch].x_fast + alpha_peak * self.ch_state[ch].x_peak

                g_mod = 1
                if self.ch_state[ch].x_peak * self.ch_state[ch].gain < self.ch_state[ch].threshold_lower:
                    g_mod = self.ch_state[ch].gain_inc 
                elif self.ch_state[ch].x_peak * self.ch_state[ch].gain > self.ch_state[ch].threshold_upper:
                    g_mod = self.ch_state[ch].gain_dec

                self.ch_state[ch].gain = min(g_mod * self.ch_state[ch].gain, self.ch_state[ch].max_gain)


        def limit_gain(x):
            NONLINEAR_POINT = 0.5
            return x if abs(x) < NONLINEAR_POINT else (np.sign(x) * 2 * NONLINEAR_POINT - NONLINEAR_POINT ** 2 / x)

        gained_input = self.ch_state[ch].gain * input_frame
        output_frame = [limit_gain(sample) for sample in gained_input]
        return output_frame
