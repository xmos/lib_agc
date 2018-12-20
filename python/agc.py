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

def get_peak_dB(input_frame_ch):
    return 20.0 * np.log10(input_frame_ch.max())


def get_gain_curve(headroom, max_gain, noise_floor):

    Graw = np.linspace(-agc.MIN_INPUT_DB, 0, abs(agc.MIN_INPUT_DB) + 1)
    Grawh = Graw - headroom
    Grawh_clipped = np.clip(Grawh, None, max_gain)

    Gs = np.array(Grawh_clipped)
    Gs[np.where((Gs < 0))[0]] = 0
    for i in range(noise_floor - agc.MIN_INPUT_DB):
        Gs[i] = agc.NOISE_GAIN

    return Gs

def get_linear_gain_curve(headroom, max_gain, noise_floor):
    m = float(max_gain)/(noise_floor+headroom)
    b = m*headroom

    Gs = np.empty(abs(agc.MIN_INPUT_DB) + 1)

    for i in range(len(Gs)):
        Gs[i] = m * (i - abs(agc.MIN_INPUT_DB)) + b

    Gs[np.where((Gs < 0))[0]] = 0
    Gs[np.where((Gs > max_gain))[0]] = np.float(max_gain)

    return Gs

class agc:
    FRAME_ADVANCE = 240
    LOOK_AHEAD_FRAMES = 1
    NOISE_GAIN = 10
    GAIN_LOOKUP_SIZE = 256
    MIN_INPUT_DB = -80
    # GS_TABLE = np.empty(GAIN_LOOKUP_SIZE)

    def __init__(self, channel_count, headroom, max_gain, noise_floor):
        self.max_gain = max_gain
        self.noise_floor = noise_floor
        self.headroom = headroom


        self.gs_table = get_linear_gain_curve(self.headroom, self.max_gain, self.noise_floor)
        self.channel_count = channel_count
        self.frame_advance = agc.FRAME_ADVANCE
        self.sample_buffer = np.zeros((self.channel_count, self.frame_advance * (1 + agc.LOOK_AHEAD_FRAMES)))

        self.frame_peak_dB = 0
        self.frame_gain = 0
        # import matplotlib.pyplot as plt
        # input = np.linspace(agc.MIN_INPUT_DB, 0, abs(agc.MIN_INPUT_DB) + 1)
        # output_Gs = input + self.gs_table
        # plt.plot(input, self.gs_table, label = 'gs_table')
        #
        # plt.legend()
        # plt.grid()
        # plt.show()

        # self.channel_count = channel_count
        # self.state = ['STABLE'] * channel_count
        # self.up_factor = get_factor(6)
        # self.down_factor = get_factor(-20)
        # self.wait_count = [agc.WAIT_COUNT] * channel_count
        # self.desired = dBFS_to_int32(desired_dBFS)
        # self.desired_max = dBFS_to_int32(desired_dBFS_max)
        # self.desired_min = dBFS_to_int32(desired_dBFS_min)
        # self.error = 0
        #
        #
        # self.gain = []
        # for i in range(self.channel_count):
        #     self.gain.append(ch_gains[i])
        #
        #
        # self.frame_energy = np.empty((agc.AGC_VOICE_FRAME_ENERGY_BUFFER,))
        # self.frame_energy.fill(float(self.desired)/self.gain[0])
        #
        # print "desired: {} (/{})".format(self.desired, np.finfo(np.float64).max)
        # print "up_factor: {}".format(self.up_factor)
        # print "down_factor: {}".format(self.down_factor)
        #
        # print "frame_energy: {}".format(self.frame_energy[0])
        # print "frame_energy: {}".format(self.frame_energy[1])
        return



    def process_frame(self, input_frame, vad):


        # Push new frame to the back of sample buffer
        for ch in range(self.channel_count):
            for n in range(len(self.sample_buffer[0, ]) - self.frame_advance):
                self.sample_buffer[ch, n] = self.sample_buffer[ch, n + self.frame_advance]

            for n in range(self.frame_advance):
                self.sample_buffer[ch,-self.frame_advance + n] = input_frame[ch, n]

        self.frame_peak_dB = get_peak_dB(self.sample_buffer[0, :])

        if self.frame_peak_dB < agc.MIN_INPUT_DB:
            self.frame_peak_dB = agc.MIN_INPUT_DB

        Gain_new = 0
        if vad == True:
            Gain_new = self.gs_table[np.int(self.frame_peak_dB) - agc.MIN_INPUT_DB]
        else:
            Gain_new = self.frame_gain#agc.NOISE_GAIN

        # Incremental change
        self.frame_gain = float(3*self.frame_gain + Gain_new)/4

        gain_linear = 10 ** (float(self.frame_gain)/20.0)
        output = np.empty(np.shape(input_frame))
        for ch in range(self.channel_count):
            for n in range(self.frame_advance):
                output[ch, n] = gain_linear * self.sample_buffer[ch, n]

        return output
