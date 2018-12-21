# Copyright (c) 2018, XMOS Ltd, All rights reserved
import os
import sys

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

# AGC_GAIN_CH0 = 20
# AGC_GAIN_CH1 = 1

def parse_arguments():
    parser = argparse.ArgumentParser()
    parser.add_argument("input", help="input wav file")
    parser.add_argument("--headroom", type=int, default = 6)
    parser.add_argument("--max_gain", type=int, default = 40)
    parser.add_argument("--noise_floor", type=int, default = -40)

    parser.add_argument("output", help="output wav file")
    parser.add_argument('--plot', action='store_true')
    args = parser.parse_args()
    return args

if __name__ == "__main__":
    args = parse_arguments()

    rate, mix_wav_file = scipy.io.wavfile.read(args.input, 'r')
    wav_data, channel_count, file_length = au.parse_audio(mix_wav_file)

    frame_count = file_length/FRAME_ADVANCE

    output = np.zeros((channel_count, file_length))

    agc = agc.agc(channel_count, args.headroom, args.max_gain, args.noise_floor)


    peak_dB = []
    frame_gain = []

    for frame_start in range(0, file_length-FRAME_ADVANCE, FRAME_ADVANCE):
        x = au.get_frame(wav_data, frame_start, FRAME_ADVANCE)
        output[:, frame_start: frame_start + FRAME_ADVANCE] = agc.process_frame(x)

        peak_dB.append(agc.frame_peak_dB)
        frame_gain.append(agc.frame_gain)

    scipy.io.wavfile.write(args.output, rate, output.T)

    if args.plot:
        import matplotlib.pyplot as plt
        plt.figure(1)
        plt.plot(peak_dB)
        plt.title('Input Peaks')
        plt.xlabel('Frame Index')
        plt.ylabel('Peak (dB)')
        plt.grid()

        plt.figure(2)
        plt.plot(frame_gain)
        plt.title('Applied Gain')
        plt.xlabel('Frame Index')
        plt.ylabel('Gain (dB)')
        plt.grid()

        plt.figure(3)
        input = np.linspace(agc.MIN_INPUT_DB, 0, abs(agc.MIN_INPUT_DB) + 1)
        plt.plot(input, agc.gs_table)
        plt.title('Gain Curve')
        plt.xlabel('Input Peak (dB)')
        plt.ylabel('Gain (dB)')
        plt.grid()

        plt.show()
