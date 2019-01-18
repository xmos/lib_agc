# Copyright (c) 2018, XMOS Ltd, All rights reserved
import os
import sys
from math import sqrt

package_dir = os.path.dirname(os.path.abspath(__file__))
path1 = os.path.join(package_dir,'../../audio_test_tools/python/')
path2 = os.path.join(package_dir,'../../lib_vad/python/')
sys.path.append(path1)
sys.path.append(path2)

import numpy as np
import scipy.io.wavfile
import audio_utils as au
import agc
import vad
import argparse

FRAME_ADVANCE = 240

ADAPT_DEFAULT = False
DESIRED_DB_DEFAULT = -20
MAX_GAIN_DEFAULT = 1000.0
INIT_GAIN_DEFAULT = 2.0


def parse_arguments():
    parser = argparse.ArgumentParser()
    parser.add_argument("input", help="input wav file")
    parser.add_argument("--adapt", type=bool, default = True, help="Adapt flag for Ch0")
    parser.add_argument("--desired_dBFS", type=int, default = DESIRED_DB_DEFAULT, help="Desired level (dBFS) for Ch0. Must be negative.")
    parser.add_argument("--max_gain", type=float, default = MAX_GAIN_DEFAULT, help="Max gain for Ch0")
    parser.add_argument("--init_gain", type=float, default = 40.0, help="Initial gain for Ch0")

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
    agcs.append(agc.agc(args.adapt, args.init_gain, args.max_gain, args.desired_dBFS))
    for ch in range(channel_count-1):
        agcs.append(agc.agc(ADAPT_DEFAULT, INIT_GAIN_DEFAULT, MAX_GAIN_DEFAULT, DESIRED_DB_DEFAULT))


    for frame_start in range(0, file_length-FRAME_ADVANCE, FRAME_ADVANCE):
        x = au.get_frame(wav_data, frame_start, FRAME_ADVANCE)
        vad_result = vad.run(x[0])

        for i in range(channel_count):
            output[i, frame_start: frame_start + FRAME_ADVANCE] = agcs[i].process_frame(x[i], True)

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
