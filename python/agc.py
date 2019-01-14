# Copyright (c) 2018, XMOS Ltd, All rights reserved
import numpy as np
from math import sqrt


class agc:
    # Adaption coefficients, do not change
    SIGMA_SLOW_RISE = 0.8869
    SIGMA_SLOW_FALL = 0.9646
    SIGMA_FAST_RISE = 0.3814
    SIGMA_FAST_FALL = 0.8869
    SIGMA_PEAK_RISE = 0.5480
    SIGMA_PEAK_FALL = 0.9646
    GAIN_INC = 1.0121
    GAIN_DEC = 1.0 / GAIN_INC


    def __init__(self, init_gain, max_gain, desired_level_dBFS, input_channels = 2, active_channels = 1):
        if active_channels > input_channels:
            raise Exception("active_channels greater than input_channels.")
        if init_gain < 0:
            raise Exception("init_gain must be greater than 0.")
        if max_gain < 0:
            raise Exception("max_gain must be greater than 0.")
        if desired_level_dBFS > 0:
            raise Exception("desired_level_dBFS must be less than 0.")

        self.input_channels = input_channels
        self.active_channels = min(self.input_channels, active_channels)
        self.gain = init_gain
        self.max_gain = max_gain
        self.desired_level = (10 ** (float(desired_level_dBFS)/20))

        self.x_slow = 0
        self.x_fast = 0
        self.x_peak = 0


    def process_frame(self, input_frame, vad):
        peak_sample = 0
        if self.input_channels > 1:
            peak_sample = np.absolute(input_frame[0,]).max() #Sample input from Ch0
        else:
            peak_sample = np.absolute(input_frame).max()

        rising = peak_sample > abs(self.x_slow)

        sigma_slow = agc.SIGMA_SLOW_RISE if rising else agc.SIGMA_SLOW_FALL
        self.x_slow = (1 - sigma_slow) * peak_sample + sigma_slow * self.x_slow

        sigma_fast = agc.SIGMA_FAST_RISE if rising else agc.SIGMA_FAST_FALL
        self.x_fast = (1 - sigma_fast) * peak_sample + sigma_fast * self.x_fast

        exceed_desired_level = (peak_sample * self.gain) > self.desired_level

        if vad or exceed_desired_level:
            sigma_peak = agc.SIGMA_PEAK_RISE if self.x_fast > self.x_peak else agc.SIGMA_PEAK_FALL
            self.x_peak = (1 - sigma_peak) * self.x_fast + sigma_peak * self.x_peak

            g_mod = agc.GAIN_INC if self.x_peak * self.gain < self.desired_level else agc.GAIN_DEC
            self.gain = min(g_mod * self.gain, self.max_gain)

        def limit_gain(x):
            NONLINEAR_POINT = 0.5
            return x if abs(x) < NONLINEAR_POINT else (np.sign(x) * 2 * NONLINEAR_POINT - NONLINEAR_POINT ** 2 / x)

        gained_input = self.gain * input_frame[:self.active_channels,:]
        limited_gained_input = [[limit_gain(sample) for sample in ch] for ch in gained_input]

        output_frame = limited_gained_input
        if self.active_channels < self.input_channels:
            output_frame = np.concatenate((limited_gained_input, input_frame[self.active_channels:,:]))

        return output_frame
