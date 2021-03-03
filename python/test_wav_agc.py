# Copyright (c) 2018-2021, XMOS Ltd, All rights reserved
# This software is available under the terms provided in LICENSE.txt.
from builtins import range
from math import sqrt

import numpy as np
import scipy.io.wavfile
import audio_wav_utils as awu
from json_utils import json_to_dict
from agc import agc
import vad
import argparse

FRAME_ADVANCE = 240


ADAPT_DEFAULT = False
DESIRED_LEVEL_DEFAULT = 0.1 #-20 dB
MAX_GAIN_DEFAULT = 100000.0
INIT_GAIN_DEFAULT = 10.0

VAD_THRESHOLD = 0.8

def parse_arguments():
    parser = argparse.ArgumentParser()
    parser.add_argument("input", help="input wav file")
    parser.add_argument("output", help="output wav file")
    parser.add_argument("--config-file", help="json config file", default="../lib_agc/config/agc_2ch.json")
    parser.add_argument('--plot', action='store_true')
    args = parser.parse_args()
    return args

if __name__ == "__main__":
    args = parse_arguments()
    agc_parameters = json_to_dict(args.config_file)
    rate, mix_wav_file = scipy.io.wavfile.read(args.input, 'r')
    wav_data, channel_count, file_length = awu.parse_audio(mix_wav_file)

    vad = vad.vad()

    x_slow = []
    x_fast = []
    x_peak = []
    frame_gain_dB = []
    vad_results = []


    # treat the key-value pairs of the dictionary as additional named arguments to the constructor.
    agc = agc(**agc_parameters["agc_init_config"])
    output = np.zeros((len(agc.ch_state), file_length))
    
    for frame_start in range(0, file_length-FRAME_ADVANCE, FRAME_ADVANCE):
        x = awu.get_frame(wav_data, frame_start, FRAME_ADVANCE)
        vad_result = vad.run(x[0])
        ref_power = 0

        output[:, frame_start: frame_start + FRAME_ADVANCE] = agc.process_frame(x, ref_power, vad_result > VAD_THRESHOLD)

        x_slow.append(20.0 * np.log10(agc.ch_state[0].x_slow))
        x_fast.append(20.0 * np.log10(agc.ch_state[0].x_fast))
        x_peak.append(20.0 * np.log10(agc.ch_state[0].x_peak) if agc.ch_state[0].x_peak > 0 else np.NaN)
        frame_gain_dB.append(20.0 * np.log10(agc.ch_state[0].gain))
        vad_results.append(vad_result)


    scipy.io.wavfile.write(args.output, rate, output.T)

    if args.plot:
        import matplotlib.pyplot as plt
        plt.figure(1)
        plt.plot(x_slow, label = 'Slow')
        plt.plot(x_fast, label = 'Fast')
        plt.plot(x_peak, label = 'Peak')
        plt.title('Envelope Trackers')
        plt.xlabel('Frame Index')
        plt.ylabel('Level')
        plt.legend()
        plt.grid()

        plt.figure(2)
        plt.plot(frame_gain_dB)
        plt.title('Applied Gain')
        plt.xlabel('Frame Index')
        plt.ylabel('Gain (dB)')
        plt.grid()

        plt.figure(3)
        plt.plot(vad_results, label = "VAD")
        plt.title('VAD')
        plt.xlabel('Frame Index')
        plt.ylabel('Output')
        plt.grid()


        plt.show()
