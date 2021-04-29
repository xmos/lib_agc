# Copyright 2018-2021 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.
from __future__ import division
from builtins import object
import numpy as np
from math import sqrt

class agc_ch(object):
    def __init__(self, adapt, adapt_on_vad, soft_clipping, init_gain,
                 max_gain, min_gain, upper_threshold, lower_threshold,
                 gain_inc, gain_dec, lc_enabled,
                 lc_n_frame_near, lc_n_frame_far,
                 lc_corr_threshold,
                 lc_gamma_inc, lc_gamma_dec, lc_bg_power_gamma,
                 lc_near_delta_far_act, lc_near_delta, lc_far_delta,
                 lc_gain_max, lc_gain_dt, lc_gain_silence, lc_gain_min):
        if init_gain < 0:
            raise Exception("init_gain must be greater than 0.")
        if max_gain < 0:
            raise Exception("max_gain must be greater than 0.")
        if upper_threshold > 1.0:
            raise Exception("upper_threshold must be less than or equal to 1.")
        if lower_threshold > 1.0:
            raise Exception("lower_threshold must be less than or equal to 1.")
        self.adapt = adapt
        self.adapt_on_vad = adapt_on_vad
        self.soft_clipping = soft_clipping

        self.gain = init_gain
        self.max_gain = max_gain
        self.min_gain = min_gain

        self.gain_inc = gain_inc
        self.gain_dec = gain_dec

        self.threshold_upper = float(upper_threshold)
        self.threshold_lower = float(lower_threshold)

        self.lc_enabled = lc_enabled
        self.lc_gain = 1

        self.lc_n_frame_near = lc_n_frame_near
        self.lc_n_frame_far = lc_n_frame_far
        self.lc_corr_threshold = lc_corr_threshold
        self.lc_gamma_inc = lc_gamma_inc
        self.lc_gamma_dec = lc_gamma_dec
        self.lc_bg_power_gamma = lc_bg_power_gamma
        self.lc_near_delta_far_act = lc_near_delta_far_act
        self.lc_near_delta = lc_near_delta
        self.lc_far_delta = lc_far_delta
        self.lc_gain_max = lc_gain_max
        self.lc_gain_dt = lc_gain_dt
        self.lc_gain_silence = lc_gain_silence
        self.lc_gain_min = lc_gain_min

        self.lc_near_bg_power_est = agc.LC_BG_POWER_EST_INIT
        self.lc_near_power_est = agc.LC_POWER_EST_INIT
        self.lc_far_bg_power_est = agc.LC_FAR_BG_POWER_EST_INIT
        self.lc_far_power_est = agc.LC_FAR_BG_POWER_EST_INIT

        self.lc_t_far = 0
        self.lc_t_near = 0
        self.corr_val = 0



    def process_channel(self, input_frame, ref_power, vad, aec_corr_factor):
        if self.adapt_on_vad == 0:
            vad = True
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
                near_only = (self.lc_t_far == 0) and (self.lc_t_near > 0)
                if (self.x_peak * self.gain < self.threshold_lower) and (not self.lc_enabled or near_only):
                    g_mod = self.gain_inc
                elif self.x_peak * self.gain > self.threshold_upper:
                    g_mod = self.gain_dec

                self.gain = min(g_mod * self.gain, self.max_gain)
                self.gain = max(g_mod * self.gain, self.min_gain)


        # Loss Control
        far_power_alpha = agc.LC_EST_ALPHA_INC
        if ref_power < self.lc_far_power_est:
            far_power_alpha = agc.LC_EST_ALPHA_DEC
        self.lc_far_power_est = (far_power_alpha) * self.lc_far_power_est + (1 - far_power_alpha) * ref_power

        self.lc_far_bg_power_est = min(self.lc_bg_power_gamma * self.lc_far_bg_power_est, self.lc_far_power_est)
        self.lc_far_bg_power_est = max(self.lc_far_bg_power_est, agc.LC_FAR_BG_POWER_EST_MIN)

        frame_power = np.mean(input_frame**2.0)
        near_power_alpha = agc.LC_EST_ALPHA_INC
        if frame_power < self.lc_near_power_est:
            near_power_alpha = agc.LC_EST_ALPHA_DEC

        self.lc_near_power_est = (near_power_alpha) * self.lc_near_power_est + (1 - near_power_alpha) * frame_power

        if(self.lc_near_bg_power_est > self.lc_near_power_est):
            self.lc_near_bg_power_est = (agc.LC_BG_POWER_EST_ALPHA_DEC) * self.lc_near_bg_power_est + (1 - agc.LC_BG_POWER_EST_ALPHA_DEC) * self.lc_near_power_est
        else:
            self.lc_near_bg_power_est = self.lc_bg_power_gamma * self.lc_near_bg_power_est


        gained_input = input_frame
        if(self.lc_enabled):

            if aec_corr_factor > self.corr_val:
                self.corr_val = aec_corr_factor
            else:
                self.corr_val = 0.98 * self.corr_val + 0.02 * aec_corr_factor

            # Update far-end activity timer
            if(self.lc_far_power_est > self.lc_far_delta * self.lc_far_bg_power_est):
                self.lc_t_far = self.lc_n_frame_far
            else:
                self.lc_t_far = max(0, self.lc_t_far - 1)
            delta = self.lc_near_delta
            if self.lc_t_far > 0:
                delta = self.lc_near_delta_far_act

            # Update near-end activity timer
            if(self.lc_near_power_est > (delta * self.lc_near_bg_power_est)):
                if self.lc_t_far == 0 or (self.lc_t_far > 0 and self.corr_val < self.lc_corr_threshold):
                    # Near speech only or Double talk
                    self.lc_t_near = self.lc_n_frame_near
                elif self.lc_t_far > 0 and self.corr_val >= self.lc_corr_threshold:
                    # Far end speech only
                    # Do nothing
                    pass
                else:
                    raise Exception("Reached here!")

            else:
                # Silence
                self.lc_t_near = max(0, self.lc_t_near - 1)

            # Adapt loss control gain
            if(self.lc_t_far <= 0 and self.lc_t_near > 0):
                # Near speech only
                target_gain = self.lc_gain_max
            elif(self.lc_t_far <= 0 and self.lc_t_near <= 0):
                # Silence
                target_gain = self.lc_gain_silence
            elif(self.lc_t_far > 0 and self.lc_t_near <= 0):
                # Far end only
                target_gain = self.lc_gain_min
            elif(self.lc_t_far > 0 and self.lc_t_near > 0):
                # Double talk
                target_gain = self.lc_gain_dt


            if(self.lc_gain > target_gain):
                for i, sample in enumerate(input_frame):
                    self.lc_gain = max(target_gain, self.lc_gain * self.lc_gamma_dec)
                    gained_input[i] = (self.lc_gain * self.gain) * sample
            else:
                for i, sample in enumerate(input_frame):
                    self.lc_gain = min(target_gain, self.lc_gain * self.lc_gamma_inc)
                    gained_input[i] = (self.lc_gain * self.gain) * sample

        else:
            gained_input = self.gain * input_frame

        def limit_gain(x):
            NONLINEAR_POINT = 0.5
            return x if (self.soft_clipping == 0 or abs(x) < NONLINEAR_POINT) else (np.sign(x) * 2 * NONLINEAR_POINT - NONLINEAR_POINT ** 2 / x)

        output_frame = [limit_gain(sample) for sample in gained_input]
        return output_frame


class agc(object):
    # Adaption coefficients, do not change
    ALPHA_SLOW_RISE = 0.8869
    ALPHA_SLOW_FALL = 0.9646
    ALPHA_FAST_RISE = 0.3814
    ALPHA_FAST_FALL = 0.8869
    ALPHA_PEAK_RISE = 0.5480
    ALPHA_PEAK_FALL = 0.9646

    # Alpha values for EWMA calcuations
    LC_EST_ALPHA_INC = 0.5480
    LC_EST_ALPHA_DEC = 0.6973
    LC_BG_POWER_EST_ALPHA_DEC = 0.5480

    LC_CORR_PK_HOLD = 1

    LC_POWER_EST_INIT = 0.00001
    LC_BG_POWER_EST_INIT = 0.01
    LC_FAR_BG_POWER_EST_INIT = 0.01
    LC_FAR_BG_POWER_EST_MIN = 0.00001



    def __init__(self, ch_init_config):
        self.ch_state = []
        self.input_ch_count = len(ch_init_config)
        for ch_idx in range(self.input_ch_count):
            self.ch_state.append(agc_ch(**ch_init_config[ch_idx]))
            self.ch_state[ch_idx].x_slow = 0
            self.ch_state[ch_idx].x_fast = 0
            self.ch_state[ch_idx].x_peak = 0


    def process_frame(self, input_frame, ref_power_est, vad, aec_corr_factor):
        output = np.zeros((self.input_ch_count, len(input_frame[0])))
        for i in range(self.input_ch_count):
            output[i] = self.ch_state[i].process_channel(input_frame[i], ref_power_est, vad, aec_corr_factor)

        return output
