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

def parse_arguments():
    parser = argparse.ArgumentParser()
    parser.add_argument("input", help="inpout wav file")
    parser.add_argument("output", help="output wav file")
    parser.parse_args()
    args = parser.parse_args()
    return args

if __name__ == "__main__":
    args = parse_arguments()

    frame_advance = 240

    rate, mix_wav_file = scipy.io.wavfile.read(args.input, 'r')
    wav_data, channel_count, file_length = au.parse_audio(mix_wav_file)
    print "{} {} file length: {}".format(np.shape(wav_data), rate, file_length)

    frame_count = file_length/frame_advance

    output = np.zeros((channel_count, file_length))

    gc = agc(channel_count, frame_advance, gain_db = 20.0)

    for frame_start in range(0, file_length-frame_advance, frame_advance):
        x = au.get_frame(wav_data, frame_start, frame_advance)
        output[:, frame_start: frame_start + frame_advance] = gc.process_frame(x, verbose = False)

        # if frame_start/frame_advance == 4:
        #     break
    print "{}".format(np.shape(output))
    scipy.io.wavfile.write(args.output, rate, output.T)
