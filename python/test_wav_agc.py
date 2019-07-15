# Copyright (c) 2018-2019, XMOS Ltd, All rights reserved
from builtins import range
from math import sqrt

import numpy as np
import scipy.io.wavfile
import audio_utils as au
import agc
import vad
import argparse

FRAME_ADVANCE = 240

ADAPT_DEFAULT = False
DESIRED_LEVEL_DEFAULT = 0.1 #-20 dB
MAX_GAIN_DEFAULT = 100000.0
INIT_GAIN_DEFAULT = 10.0


def parse_arguments():
    parser = argparse.ArgumentParser()
    parser.add_argument("input", help="input wav file")
    parser.add_argument("--adapt", type=bool, default = True, help="Adapt flag for Ch0")
    parser.add_argument("--upper_threshold", type=float, default = DESIRED_LEVEL_DEFAULT, help="Upper threshold for desired level for Ch0. Must be less than 1.")
    parser.add_argument("--lower_threshold", type=float, default = DESIRED_LEVEL_DEFAULT, help="Lower threshold for desired level for Ch0. Must be less than 1.")
    parser.add_argument("--max_gain", type=float, default = MAX_GAIN_DEFAULT, help="Max gain for Ch0")
    parser.add_argument("--init_gain", type=float, default = INIT_GAIN_DEFAULT, help="Initial gain for Ch0")
    parser.add_argument("--gain_inc", type=float, default = 1.0121, help="Gain increment for Ch0")
    parser.add_argument("--gain_dec", type=float, default = 0.98804, help="Gain decrement for Ch0")


    parser.add_argument("output", help="output wav file")
    parser.add_argument('--plot', action='store_true')
    args = parser.parse_args()
    return args

if __name__ == "__main__":
    args = parse_arguments()

    rate, mix_wav_file = scipy.io.wavfile.read(args.input, 'r')
    wav_data, channel_count, file_length = au.parse_audio(mix_wav_file)

    vad = vad.vad()

    x_slow = []
    x_fast = []
    x_peak = []
    frame_gain_dB = []
    vad_results = []

    output = np.zeros((channel_count, file_length))

    agcs = []
    agcs.append(agc.agc(args.adapt, args.init_gain, args.max_gain, args.upper_threshold, args.lower_threshold, args.gain_inc, args.gain_dec))
    for ch in range(channel_count-1):
        agcs.append(agc.agc(ADAPT_DEFAULT, INIT_GAIN_DEFAULT, MAX_GAIN_DEFAULT, DESIRED_LEVEL_DEFAULT, DESIRED_LEVEL_DEFAULT))


    for frame_start in range(0, file_length-FRAME_ADVANCE, FRAME_ADVANCE):
        x = au.get_frame(wav_data, frame_start, FRAME_ADVANCE)
        vad_result = vad.run(x[0])

        for i in range(channel_count):
            output[i, frame_start: frame_start + FRAME_ADVANCE] = agcs[i].process_frame(x[i], vad_result)

        x_slow.append(20.0 * np.log10(agcs[0].x_slow))
        x_fast.append(20.0 * np.log10(agcs[0].x_fast))
        x_peak.append(20.0 * np.log10(agcs[0].x_peak) if agcs[0].x_peak > 0 else np.NaN)
        frame_gain_dB.append(20.0 * np.log10(agcs[0].gain))
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
