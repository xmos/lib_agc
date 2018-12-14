# Copyright (c) 2018, XMOS Ltd, All rights reserved
from math import sqrt
import numpy as np

def get_factor(dBps):
    return float(10 ** (dBps*0.015/20))

def get_frame_energy(frame):
    energy = np.iinfo(np.int32).max * np.power(frame, 2).sum()
    return energy

def dBFS_to_int32(dBFS):
    return np.iinfo(np.int32).max * (10 ** (float(min(dBFS, agc.DBFS_MAX))/20))


class agc:

    INIT_GAIN = 1
    FIXED_LIMIT = 0.5
    WAIT_COUNT = 0 #66 * 0.3
    DBFS_MAX = 0
    MAX_GAIN = 10 ** float(127/20)
    MIN_GAIN = 10 ** float(-127/20)
    AGC_LOOK_AHEAD_FRAMES = 0

    def __init__(self, channel_count, desired_dBFS, desired_Error, frame_advance):
        self.channel_count = channel_count
        self.frame_advance = frame_advance
        self.gain = [agc.INIT_GAIN] * channel_count
        self.state = ['STABLE'] * channel_count
        self.up_factor = get_factor(10)
        self.down_factor = get_factor(-20)
        self.wait_count = [agc.WAIT_COUNT] * channel_count
        self.desired = dBFS_to_int32(desired_dBFS)
        self.desired_max = dBFS_to_int32(desired_dBFS + desired_Error)
        self.desired_min = dBFS_to_int32(desired_dBFS - desired_Error)

        self.frame_energy = np.zeros((1 + agc.AGC_LOOK_AHEAD_FRAMES,))
        self.sample_buffer = np.zeros((channel_count, self.frame_advance * (1 + agc.AGC_LOOK_AHEAD_FRAMES)))

        print "desired: {} (/{})".format(self.desired, np.finfo(np.float64).max)
        print "up_factor: {}".format(self.up_factor)
        print "down_factor: {}".format(self.down_factor)

        return


    def set_channel_gain(self, ch_index, gain):
        self.gain[ch_index] = gain
        if self.gain[ch_index] < 1:
            self.gain[ch_index] = 1
        return


    def multiply_gain(self, factor):
        self.gain = self.gain * factor


    def adapt(self, input_frame, ch_index, frame_energy):
        energy = self.gain[ch_index] * frame_energy
        if self.state[ch_index] == 'STABLE':
            if energy > self.desired_max:
                self.state[ch_index] = 'DOWN'
            elif energy < self.desired_min:
                self.state[ch_index] = 'WAIT'

        elif self.state[ch_index] == 'UP':
            self.gain[ch_index] = min(agc.MAX_GAIN, self.gain[ch_index] * self.up_factor)
            if energy > self.desired:
                self.state[ch_index] = 'STABLE'

        elif self.state[ch_index] == 'DOWN':
            self.gain[ch_index] = max(agc.MIN_GAIN, self.gain[ch_index] * self.down_factor)
            if energy < self.desired:
                self.state[ch_index] = 'STABLE'

        elif self.state[ch_index] == 'WAIT':
            if energy > self.desired_max:
                self.state[ch_index] = 'DOWN'
            elif energy < self.desired_min:
                if (self.wait_count[ch_index] <= 0):
                    self.wait_count[ch_index] = agc.WAIT_COUNT
                    self.state[ch_index] = 'UP'
                else:
                    self.wait_count[ch_index] -= 1
            else:
                self.state[ch_index] = 'STABLE'
        else:
            print "ERROR Unknown state: {}".format(self.state[ch_index])


    def process_frame(self, input_frame, vad = False, verbose = False):

        def limit_gain(x):
            return x if abs(x) < agc.FIXED_LIMIT else (np.sign(x) * 2 * agc.FIXED_LIMIT - agc.FIXED_LIMIT ** 2 / x)

        # print np.shape(input_frame)
        # print np.shape(self.sample_buffer)

        # Push new frame energy to the back
        self.frame_energy[:-1] = self.frame_energy[1:]
        self.frame_energy[-1] = get_frame_energy(input_frame[0])

        # Push new frame to the back of sample buffer
        for ch in range(self.channel_count):
            for n in range(len(self.sample_buffer[0, ]) - self.frame_advance):
                self.sample_buffer[ch, n] = self.sample_buffer[ch, n + self.frame_advance]

            for n in range(self.frame_advance):
                self.sample_buffer[ch,-self.frame_advance + n] = input_frame[ch, n]

        output = np.empty(np.shape(input_frame))
        if vad == True:
            for i, input_ch_frame in enumerate(input_frame):
                self.adapt(input_frame, i, np.mean(self.frame_energy)) # Adapt on average of look-ahead frame energies

        for ch in range(self.channel_count):
            for n in range(self.frame_advance):
                gained_sample = self.gain[ch] * self.sample_buffer[ch, n]
                output[ch, n] = limit_gain(gained_sample)

        return output
