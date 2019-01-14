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
import agc_hansler as agc
import vad
import argparse

FRAME_ADVANCE = 240

# AGC_GAIN_CH0 = 20
# AGC_GAIN_CH1 = 1

def parse_arguments():
    parser = argparse.ArgumentParser()
    parser.add_argument("input", help="input wav file")
    parser.add_argument("--desired_level", type=int, default = -6)
    parser.add_argument("--max_gain", type=int, default = 40)
    parser.add_argument("--noise_floor", type=int, default = -40)
    parser.add_argument("--init_gain", type=int, default = 20)

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

    # agc = agc.agc(channel_count, args.headroom, args.max_gain, args.noise_floor)
    agc = agc.agc(args.init_gain, args.noise_floor, args.desired_level)

    vad = vad.vad()

    x_slow = []
    x_fast = []
    x_peak = []
    frame_gain = []
    vad1 = []
    vad2 = []
    noise_floor = []

    for frame_start in range(0, file_length-FRAME_ADVANCE, FRAME_ADVANCE):
        x = au.get_frame(wav_data, frame_start, FRAME_ADVANCE)
        vad_result = vad.run(x[0])
        output[:, frame_start: frame_start + FRAME_ADVANCE] = agc.process_frame(x, vad_result > 0.4)

        x_slow.append(20.0 * np.log10(agc.x_slow))
        x_fast.append(20.0 * np.log10(agc.x_fast))
        x_peak.append(20.0 * np.log10(agc.x_peak))
        frame_gain.append(20.0 * np.log10(agc.gain))
        vad1.append(1 if agc.vad else 0)
        noise_floor.append(20.0 * np.log10(sqrt(agc.noise.b_power)))
        vad2.append(vad_result)

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
        plt.plot(frame_gain)
        plt.title('Applied Gain')
        plt.xlabel('Frame Index')
        plt.ylabel('Gain (dB)')
        plt.grid()

        plt.figure(3)
        plt.plot(vad1, label = "Psuedo VAD")
        plt.plot(vad2, label = "VAD")
        plt.title('VAD')
        plt.xlabel('Frame Index')
        plt.ylabel('Output')
        plt.grid()

        plt.figure(4)
        plt.plot(noise_floor)
        plt.title('Noise Floor')
        plt.xlabel('Frame Index')
        plt.ylabel('Power (dB)')
        plt.grid()

        plt.show()
