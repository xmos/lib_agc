# Copyright (c) 2018, XMOS Ltd, All rights reserved
import numpy as np
from math import sqrt


def dBFS_to_int32(dBFS):
    return np.iinfo(np.int32).max * (10 ** (float(dBFS)/20))


class agc:
    FRAME_ADVANCE = 240
    def __init__(self, init_gain,  noise_floor, desired_level):
        self.sigma_slow_rise = sqrt(0.999)
        self.sigma_slow_fall = sqrt(0.9997)
        self.sigma_fast_rise = sqrt(0.992)
        self.sigma_fast_fall = sqrt(0.9990)
        self.sigma_peak_rise = sqrt(0.995)
        self.sigma_peak_fall = sqrt(0.9997)

        self.gain_inc = sqrt(1.0001)
        self.gain_dec = 1.0 / self.gain_inc

        self.noise_floor = 0#(10 ** (float(noise_floor)/20))

        self.x_slow = 0
        self.x_fast = 0
        self.x_peak = 0

        self.vad = False

        self.gain = init_gain

        self.desired_level = (10 ** (float(desired_level)/20))

        self.noise = noise_estimator(noise_floor)

        print self.noise_floor
        print self.desired_level


    def process_frame(self, input_frame, vad_flag):
        output_frame = np.empty(np.shape(input_frame))

        for i, sample in enumerate(input_frame[0,]):
            sample_abs = abs(sample)
            rising = sample_abs > abs(self.x_slow)

            # sigma_slow = self.sigma_slow_rise if rising else self.sigma_slow_fall
            # self.x_slow = (1 - sigma_slow) * sample_abs + sigma_slow * self.x_slow

            sigma_fast = self.sigma_fast_rise if rising else self.sigma_fast_fall
            self.x_fast = (1 - sigma_fast) * sample_abs + sigma_fast * self.x_fast

            # self.noise.process_sample(sample)
            #
            # self.vad = self.x_fast > max(self.x_slow, sqrt(self.noise.b_power) * 1.5)

            if vad_flag:
                sigma_peak = self.sigma_peak_rise if self.x_fast > self.x_peak else self.sigma_peak_fall
                self.x_peak = (1 - sigma_peak) * self.x_fast + sigma_peak * self.x_peak

                g_mod = self.gain_inc if self.x_peak * self.gain < self.desired_level else self.gain_dec
                self.gain = g_mod * self.gain
            # else values unchanged

            output_frame[:,i] = self.gain * input_frame[:,i]


        return output_frame


class noise_estimator:
    def __init__(self, init_noise_floor):
        self.b_power = pow(10 ** (float(init_noise_floor)/20.0), 2)
        self.x_power = self.b_power

        self.sigma_rising = sqrt(0.993)
        self.sigma_falling = sqrt(0.997)

        self.epsilon = 0.00001


    def process_sample(self, sample):
        x_power_new = pow(sample,2)

        sigma = self.sigma_rising if x_power_new > self.x_power else self.sigma_falling
        self.x_power = (1 - sigma) * x_power_new + sigma * self.x_power

        self.b_power = min(self.x_power, self.b_power) * (1.0 + self.epsilon)
