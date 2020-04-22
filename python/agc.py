# Copyright (c) 2018-2020, XMOS Ltd, All rights reserved
from __future__ import division
from builtins import object
import numpy as np
from math import sqrt, log

class agc_ch(object):
    def __init__(self, adapt, init_gain, max_gain, upper_threshold, lower_threshold, gain_inc, gain_dec, lc_enabled = False):
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
        
        
        self.lc_enabled = lc_enabled
        self.lc_gain = 1
        
        self.lc_near_bg_power_est = agc.LC_BG_POWER_EST_INIT
        self.lc_near_power_est = agc.LC_POWER_EST_INIT
        self.lc_far_bg_power_est = agc.LC_FAR_BG_POWER_EST_INIT
        self.lc_far_power_est = agc.LC_FAR_BG_POWER_EST_INIT
        
        self.lc_t_far = 0
        self.lc_t_near = 0
        
        self.corr_val = 0
        
        self.lc_gains = []
        self.t_nears = []
        self.t_fars = []
        self.powers = []
        self.near_powers = []
        self.near_bg_powers = []
        self.far_powers = []
        self.far_bg_powers = []
        self.ref_powers = []
        self.near_max = []
        self.corr_vals = []

    
    def process_channel(self, input_frame, ref_power, vad, aec_corr_factor):
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
        
        
        # Loss Control
        far_power_alpha = agc.LC_EST_ALPHA_INC
        if ref_power < self.lc_far_power_est:
            far_power_alpha = agc.LC_EST_ALPHA_DEC
        self.lc_far_power_est = (far_power_alpha) * self.lc_far_power_est + (1 - far_power_alpha) * ref_power
        
        self.lc_far_bg_power_est = min(agc.LC_BG_POWER_GAMMA * self.lc_far_bg_power_est, self.lc_far_power_est)
        
        frame_power = np.mean(input_frame**2.0)
        near_power_alpha = agc.LC_EST_ALPHA_INC
        if frame_power < self.lc_near_power_est:
            near_power_alpha = agc.LC_EST_ALPHA_DEC
        
        self.lc_near_power_est = (near_power_alpha) * self.lc_near_power_est + (1 - near_power_alpha) * frame_power
        
        if(self.lc_near_bg_power_est > self.lc_near_power_est):
            self.lc_near_bg_power_est = (agc.LC_BG_POWER_EST_ALPHA_DEC) * self.lc_near_bg_power_est + (1 - agc.LC_BG_POWER_EST_ALPHA_DEC) * self.lc_near_power_est
        else:
            self.lc_near_bg_power_est = agc.LC_BG_POWER_GAMMA * self.lc_near_bg_power_est
        
        
        gained_input = input_frame
        if(self.lc_enabled):
            
            if aec_corr_factor > self.corr_val:
                self.corr_val = aec_corr_factor
                self.corr_val_counter = agc.LC_CORR_PK_HOLD
            else:
                self.corr_val = 0.95 * self.corr_val + 0.05 * aec_corr_factor

            if(self.lc_far_power_est > agc.LC_FAR_DELTA * self.lc_far_bg_power_est):
                self.lc_t_far = agc.LC_N_FRAME_FAR
            else:
                self.lc_t_far = max(0, self.lc_t_far - 1)
            delta = agc.LC_DELTA
            if self.lc_t_far > 0:
                delta = agc.LC_DELTA_FAR_ACT
            
            # Update near-end-activity timer
            if(self.lc_near_power_est > (delta * self.lc_near_bg_power_est)):
                if self.lc_t_far == 0:
                    # Near speech only
                    self.lc_t_near = agc.LC_N_SAMPLE_NEAR
                elif self.lc_t_far > 0 and self.corr_val < agc.LC_CORR_THRESHOLD:
                    # Double talk
                    self.lc_t_near = agc.LC_N_SAMPLE_NEAR / 2
                elif self.lc_t_far > 0 and self.corr_val >= agc.LC_CORR_THRESHOLD:
                    # Far end speech only
                    self.lc_t_near = 0
                else:
                    raise Exception("Reached here!")
                
                # self.lc_t_near = agc.LC_N_SAMPLE_NEAR
            
            else:
                # Silence
                self.lc_t_near = max(0, self.lc_t_near - 1)
            
            # Adapt loss control gain
            if(self.lc_t_far <= 0 and self.lc_t_near > 0):
                # Near speech only
                target_gain = agc.LC_GAIN_MAX
            elif(self.lc_t_far <= 0 and self.lc_t_near <= 0):
                # Silence
                target_gain = agc.LC_GAIN_SILENCE
            elif(self.lc_t_far > 0 and self.lc_t_near <= 0):
                # Far end only
                target_gain = agc.LC_GAIN_MIN
            elif(self.lc_t_far > 0 and self.lc_t_near > 0):
                # Double talk
                target_gain = agc.LC_GAIN_DT
            
            
            if(self.lc_gain > target_gain):
                for i, sample in enumerate(input_frame):
                    self.lc_gain = max(target_gain, self.lc_gain * agc.LC_GAMMA_DEC)
                    gained_input[i] = (self.lc_gain * self.gain) * sample
            else:
                for i, sample in enumerate(input_frame):
                    self.lc_gain = min(target_gain, self.lc_gain * agc.LC_GAMMA_INC)
                    gained_input[i] = (self.lc_gain * self.gain) * sample
                    
            self.t_nears.append(self.lc_t_near)
            self.t_fars.append(self.lc_t_far)
            self.powers.append(frame_power)
            self.near_powers.append(self.lc_near_power_est)
            self.near_bg_powers.append(delta * self.lc_near_bg_power_est)
            self.far_powers.append(self.lc_far_power_est)
            self.far_bg_powers.append(agc.LC_FAR_DELTA * self.lc_far_bg_power_est)
            self.ref_powers.append(ref_power)
            self.near_max.append(max(input_frame**2.0))
            self.corr_vals.append(self.corr_val)
            self.lc_gains.append(20*log(self.lc_gain, 10))
            
        else:
            gained_input = self.gain * input_frame
            
        def limit_gain(x):
            NONLINEAR_POINT = 0.5
            return x if abs(x) < NONLINEAR_POINT else (np.sign(x) * 2 * NONLINEAR_POINT - NONLINEAR_POINT ** 2 / x)

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
    
    LC_N_SAMPLE_NEAR = 34 # 0.5s as recommended in "acoustic echo and noise control"
    LC_N_FRAME_FAR = 17 # 0.25 seconds, frame count
    
    # Alpha values for EWMA calcuations
    LC_EST_ALPHA_INC = 0.5480
    LC_EST_ALPHA_DEC = 0.6973
    LC_BG_POWER_EST_ALPHA_DEC = 0.5480
    
    # Gamma values are multipliers
    LC_GAMMA_INC = 1.005
    LC_GAMMA_DEC = 0.995
    LC_BG_POWER_GAMMA = 1.002 # bg power estimate small increase prevent local minima
    
    LC_DELTA = 50.0 # ratio of near end power to bg estimate to mark near end activity
    LC_FAR_DELTA = 50.0
    LC_DELTA_FAR_ACT = 500.0
    
    LC_CORR_THRESHOLD = 0.9
    LC_CORR_PK_HOLD = 1
    
    LC_GAIN_MAX = 1
    LC_GAIN_MIN = 0.0177 #-35dB
    LC_GAIN_DT = 0.2
    LC_GAIN_SILENCE = 0.1

    LC_POWER_EST_INIT = 0.00001
    LC_BG_POWER_EST_INIT = 0.01
    LC_FAR_BG_POWER_EST_INIT = 0.01
    
    

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
