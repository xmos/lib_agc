#!/usr/bin/env python

import numpy as np
import audio_utils as au

class agc:

    def __init__(self, 
            channel_count,
            frame_advance,
            automatic = False,
            gain_db = 20.0,
            desired_energy_db = -6.0,
            look_past_frames = 5,
            look_ahead_frames = 5,
            rate_down_dbps = -70.0,
            rate_up_dbps = 7.0,
            min_db = -127.0,
            max_db =  127.0,
            wait_for_up_ms = 6000.0,
            soft_clip_enabled = True
            ):
        self.channel_count = channel_count

        self.energy_buffer = np.zeros((channel_count, look_past_frames + look_ahead_frames + 1))
        self.frame_buffer = np.zeros((channel_count, look_ahead_frames + 1, frame_advance))

        self.frame_advance = frame_advance
        self.automatic = automatic
        self.gain = 10.0**(gain_db/20.0)
        self.desired_energy_db = desired_energy_db
        self.look_past_frames = look_past_frames
        self.look_ahead_frames = look_ahead_frames
        self.rate_down_dbps = rate_down_dbps
        self.rate_up_dbps = rate_up_dbps
        self.min_db = min_db
        self.max_db = max_db
        self.wait_for_up_ms = wait_for_up_ms
        self.soft_clip_enabled = soft_clip_enabled

        self.AGC_FIXED_LIMIT = 0.5 # this must be 0.5
        return

    def process_frame(self, input_frame, verbose = False):

        frame_energy = np.sum(input_frame**2, axis = 1)

        if verbose:
            for ch in range(self.channel_count):
                print 'x_p[' + str(ch) + '] = np.asarray(' + str(np.array2string(input_frame[ch], separator=',').replace('\n', '')) + ')'
                print "sqrt_energy_p[" +str(ch)+"] = " +str(np.sqrt(frame_energy[ch]))

        self.energy_buffer = np.roll(self.energy_buffer, 1, axis = 1)
        self.energy_buffer[:, 0] = np.sqrt(frame_energy)

        average_energy_buffer_energy = np.average(self.energy_buffer, axis = 1)

        if verbose:
            for ch in range(self.channel_count):
                print "average_energy_buffer_energy_p[" +str(ch)+"] = " +str(average_energy_buffer_energy[ch])

        if self.automatic:
            print "Error - only fixed gain control implemented"
        else:
            negative = input_frame < 0
            negative = - 2 * negative + 1
            output_frame = np.abs(input_frame)
            
            if self.soft_clip_enabled:
                linear = self.gain * output_frame
                linear_part = linear < self.AGC_FIXED_LIMIT
                nonlinear = 2 * self.AGC_FIXED_LIMIT - self.AGC_FIXED_LIMIT ** 2 / (self.gain * output_frame + 1e-38)
                output_frame = linear * linear_part + nonlinear * (1-linear_part)
            else:
                output_frame = self.gain * output_frame
                clips = output_frame > 1.0
                output_frame = output_frame * (1-clips) + 1.0 * clips
            output_frame = negative * output_frame
            # output16 = np.asarray(output_frame*np.iinfo(np.int16).max, dtype= np.int16)
        return output_frame

