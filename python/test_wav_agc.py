# Copyright (c) 2018, XMOS Ltd, All rights reserved
import os
import sys

package_dir = os.path.dirname(os.path.abspath(__file__))
path1 = os.path.join(package_dir,'../../audio_test_tools/python/')
sys.path.append(path1)

import numpy as np
import scipy.io.wavfile
import audio_utils as au
from agc import agc
import argparse

FRAME_ADVANCE = 240

AGC_GAIN_CH0 = 20
AGC_GAIN_CH1 = 1

def parse_arguments():
    parser = argparse.ArgumentParser()
    parser.add_argument("input", help="inpout wav file")
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

    gc = agc(channel_count, FRAME_ADVANCE)
    gc.set_channel_gain(0, AGC_GAIN_CH0)
    gc.set_channel_gain(1, AGC_GAIN_CH1)


    for frame_start in range(0, file_length-FRAME_ADVANCE, FRAME_ADVANCE):
        x = au.get_frame(wav_data, frame_start, FRAME_ADVANCE)
        output[:, frame_start: frame_start + FRAME_ADVANCE] = gc.process_frame(x, verbose = False)

    scipy.io.wavfile.write(args.output, rate, output.T)
