# Copyright (c) 2018-2019, XMOS Ltd, All rights reserved
from __future__ import division
from builtins import object
import numpy as np
from math import sqrt

class agc_ch(object):
    def __init__(self, adapt, init_gain, max_gain, upper_threshold, lower_threshold, gain_inc, gain_dec, loss_control_enabled = False):
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
        
        
        self.loss_control_enabled = loss_control_enabled
        self.loss_control_gain = 1
        
        self.near_bg_power_est = 0.0001**2
        self.near_power_est = 0
        self.far_bg_power_est = 10**float(-40/20)
        
        self.t_act_far = 0
        self.t_act_near = 0
        
        self.lc_gain = []
        self.lc_t_far_end = []
        self.lc_t_n_end = []
        self.f_power = []
        self.n_power = []
        self.bg_power = []
        


class agc(object):
    # Adaption coefficients, do not change
    ALPHA_SLOW_RISE = 0.8869
    ALPHA_SLOW_FALL = 0.9646
    ALPHA_FAST_RISE = 0.3814
    ALPHA_FAST_FALL = 0.8869
    ALPHA_PEAK_RISE = 0.5480
    ALPHA_PEAK_FALL = 0.9646
    
    LC_N_SAMPLE_NEAR = 17 # 0.25 second, frame count
    LC_N_FRAME_FAR = 17 # 0.25 seconds, frame count
    LC_ALPHA_INC = 1.005
    LC_ALPHA_DEC = 0.995
    
    LC_EST_GAMMA_INC = 0.5480
    LC_EST_GAMMA_DEC = 0.6973
    
    LC_BG_POWER_GAMMA = 1.002 #bg power estimate small increase prevent local minima
    LC_DELTA = 8.0 # ratio of near end power to bg estimate to mark near end activity
    
    LC_GAIN_MAX = 1
    LC_GAIN_MIN = 0.0056
    LC_GAIN_DT = 0.1778 #sqrt(0.0316)
    LC_GAIN_SILENCE = 0.0748 #sqrt(0.0056)


    def __init__(self, ch_init_config):
        self.ch_state = []
        for ch_idx in range(len(ch_init_config)):
            self.ch_state.append(agc_ch(**ch_init_config[ch_idx]))
            self.ch_state[ch_idx].x_slow = 0
            self.ch_state[ch_idx].x_fast = 0
            self.ch_state[ch_idx].x_peak = 0



    def process_frame(self, ch, input_frame, ref_power_est, vad):
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

        
        gained_input = input_frame
        
        # BG and near-end-speech power estimations
        if(self.ch_state[ch].loss_control_enabled):

            self.ch_state[ch].far_bg_power_est = min(agc.LC_BG_POWER_GAMMA * self.ch_state[ch].far_bg_power_est, ref_power_est)
            # Update far-end-activity timer
            if(ref_power_est > agc.LC_DELTA * self.ch_state[ch].far_bg_power_est):
                self.ch_state[ch].t_act_far = agc.LC_N_FRAME_FAR
            else:
                self.ch_state[ch].t_act_far = max(0, self.ch_state[ch].t_act_far - 1)
            
            frame_power = np.mean(input_frame**2.0)
            gamma = agc.LC_EST_GAMMA_INC
            if frame_power < self.ch_state[ch].near_power_est:
                gamma = agc.LC_EST_GAMMA_DEC
            
            self.ch_state[ch].near_power_est = (gamma) * self.ch_state[ch].near_power_est + (1 - gamma) * frame_power
            self.ch_state[ch].near_bg_power_est = min(agc.LC_BG_POWER_GAMMA * self.ch_state[ch].near_bg_power_est, self.ch_state[ch].near_power_est)
            
            # Update near-end-activity timer
            if(self.ch_state[ch].near_power_est > (agc.LC_DELTA * self.ch_state[ch].near_bg_power_est)):
                self.ch_state[ch].t_act_near = agc.LC_N_SAMPLE_NEAR
            else:
                self.ch_state[ch].t_act_near = max(0, self.ch_state[ch].t_act_near - 1)
                
                
            # Adapt loss control gain
            if(self.ch_state[ch].t_act_far <= 0 and self.ch_state[ch].t_act_near > 0):
                # Near speech only
                target_gain = agc.LC_GAIN_MAX
            elif(self.ch_state[ch].t_act_far <= 0 and self.ch_state[ch].t_act_near <= 0):
                # Silence
                target_gain = agc.LC_GAIN_SILENCE
            elif(self.ch_state[ch].t_act_far > 0 and self.ch_state[ch].t_act_near <= 0):
                # Far end only
                target_gain = agc.LC_GAIN_MIN
            elif(self.ch_state[ch].t_act_far > 0 and self.ch_state[ch].t_act_near > 0):
                # Both near and far speech
                target_gain = agc.LC_GAIN_DT

            for i, sample in enumerate(input_frame):
                if(self.ch_state[ch].loss_control_gain > target_gain):
                    self.ch_state[ch].loss_control_gain = max(target_gain, self.ch_state[ch].loss_control_gain*agc.LC_ALPHA_DEC)
                else:
                    self.ch_state[ch].loss_control_gain = min(target_gain, self.ch_state[ch].loss_control_gain*agc.LC_ALPHA_INC)
                # Apply the loss control
                gained_input[i] = (self.ch_state[ch].loss_control_gain * self.ch_state[ch].gain) * sample
            
                # self.ch_state[ch].lc_gain.append(self.ch_state[ch].loss_control_gain)
                # self.ch_state[ch].lc_t_far_end.append(self.ch_state[ch].t_act_far)
                # self.ch_state[ch].lc_t_n_end.append(self.ch_state[ch].t_act_near)
                # self.ch_state[ch].f_power.append(ref_power_est)
                # self.ch_state[ch].n_power.append(self.ch_state[ch].near_power_est)
                # self.ch_state[ch].bg_power.append(self.ch_state[ch].bg_power_est)

            
        
        else:
            gained_input = self.ch_state[ch].gain * input_frame
            
        def limit_gain(x):
            NONLINEAR_POINT = 0.5
            return x if abs(x) < NONLINEAR_POINT else (np.sign(x) * 2 * NONLINEAR_POINT - NONLINEAR_POINT ** 2 / x)

        output_frame = [limit_gain(sample) for sample in gained_input]
        return output_frame
