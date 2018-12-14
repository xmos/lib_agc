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
    parser.add_argument("input", help="inpout wav file")
    parser.add_argument("--gain0", type=int, default=20)
    parser.add_argument("--gain1", type=int, default=1)
    parser.add_argument("output", help="output wav file")
    parser.parse_args()
    args = parser.parse_args()
    return args

if __name__ == "__main__":
    args = parse_arguments()

    rate, mix_wav_file = scipy.io.wavfile.read(args.input, 'r')
    wav_data, channel_count, file_length = au.parse_audio(mix_wav_file)

    frame_count = file_length/FRAME_ADVANCE

    output = np.zeros((channel_count, file_length))

    agc = agc.agc(channel_count, -10, 6, FRAME_ADVANCE)
    agc.set_channel_gain(0, args.gain0)
    agc.set_channel_gain(1, args.gain1)

    vad = vad.vad()

    print agc.gain[0]
    energy = []
    gain0 = []
    gain1 = []
    vad_results = []
    for frame_start in range(0, file_length-FRAME_ADVANCE, FRAME_ADVANCE):
        x = au.get_frame(wav_data, frame_start, FRAME_ADVANCE)
        vad_frame = vad.run(x[0])
        vad_results.append(vad_frame)
        output[:, frame_start: frame_start + FRAME_ADVANCE] = agc.process_frame(x, vad_frame > 0.4, verbose = False)
        gain0.append(agc.gain[0])
        gain1.append(agc.gain[1])
        energy.append(np.mean(agc.frame_energy))

    import matplotlib.pyplot as plt

    scipy.io.wavfile.write(args.output, rate, output.T)

    x_axis = [x * 240.0/16000.0 for x in range(len(vad_results))]
    plt.figure(1)
    ax1 = plt.subplot(411)
    ax1.set_title("Frame Energy")
    plt.plot(x_axis, energy)
    ax2 = plt.subplot(412)
    ax2.set_title("VAD Output")
    plt.plot(x_axis, vad_results)
    ax3 = plt.subplot(413)
    ax3.set_title("Gain Ch0")
    # realgain = [x * round(vad_results[i]) for i, x in enumerate(gain)]
    plt.plot(x_axis, gain0)
    ax3 = plt.subplot(414)
    ax3.set_title("Gain Ch1")
    plt.plot(x_axis, gain1)
    plt.show()
